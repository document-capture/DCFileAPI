//Clone of codeunit 6085635 "CDC Document File Interface"
codeunit 63065 "DCADV Document File Interface"
{
    // C/SIDE
    // revision:94


    trigger OnRun()
    begin
    end;

    var
        DocBlobStorageMgt: Codeunit "DCADV Doc. Blob Storage Mgt.";
        DocFileServiceMgt: Codeunit "DCADV Document File Service";
        DCSetup: Record "CDC Document Capture Setup";
        CurrentCompany: Text[50];
        GotDCSetup: Boolean;
        FileType: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";

    internal procedure GetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, XmlTrimmedFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetCleanXmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetCleanXmlFile(Document, TempFile));
        END;
    end;

    internal procedure SetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(FALSE);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetCleanXmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetCleanXmlFile(Document, TempFile));
        END;
    end;

    internal procedure SetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(FALSE);
        //etErrorDialogHandling;

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetXmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                begin
                    EXIT(DocFileServiceMgt.SetXmlFile(Document, TempFile));

                end;
        END;
    end;

    internal procedure SetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(FALSE);
        //SetErrorDialogHandling;

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetHtmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetHtmlFile(Document, TempFile));
        END;
    end;

    local procedure GetDCSetup(Migration: Boolean): Boolean
    begin
        IF DCADV_MigrationIsInProgress(CurrentCompany) THEN BEGIN
            IF NOT DCSetup.GET THEN
                EXIT(FALSE);
            IF Migration THEN
                DCADV_GetMigrationSetup(DCSetup);
            GotDCSetup := FALSE;
        END ELSE BEGIN
            IF GotDCSetup THEN
                EXIT(TRUE);

            IF NOT DCSetup.GET THEN
                EXIT(FALSE);

            GotDCSetup := TRUE;
        END;

        //DCADV IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"File System" THEN
        //DCADV     DocFileSystem.SetDCSetup(DCSetup);

        //DCADV IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"Azure Blob Storage" THEN
        //DCADV     DocAzureBlobStorMgt.SetDCSetup(DCSetup);

        IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"File Service" THEN
            DocFileServiceMgt.SetDCSetup(DCSetup);

        EXIT(TRUE);
    end;


    local procedure GetFileName(var Document: Record "CDC Document"; FileType: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)"): Text[1024]
    var
        SingleInstanceStorage: Codeunit "CDC Single Instance Storage";
        FileName: Text;
        FileExtension: Text[10];
    begin
        //DCADV changed SingleInstanceStorage.SetDocument(Document);
        FileName := Document."No.";
        IF Document."Document ID" <> '' THEN
            FileName += '-' + Document."Document ID";

        FileExtension := GetFileExtension(FileType);
        IF FileType = XmlTrimmedFileType THEN
            EXIT(STRSUBSTNO('%1-NN.%2', FileName, FileExtension))
        ELSE
            IF FileType = MiscFileType THEN
                EXIT(STRSUBSTNO('%1.%2', FileName, Document."File Extension"))
            ELSE
                IF FileType = EmailFileType THEN
                    error('DCFileAPI not supported: 63065 GetFileName for email')// EXIT(STRSUBSTNO('%1.%2', GetEmailGUIDAsText, FileExtension))
                ELSE
                    EXIT(STRSUBSTNO('%1.%2', FileName, FileExtension));
    end;

    local procedure GetFileExtension(FileType: Integer): Text[1024]
    begin
        CASE FileType OF
            XmlOriginalFileType, XmlTrimmedFileType:
                EXIT('xml');
            EmailFileType:
                EXIT('eml');
            TiffFileType:
                EXIT('tiff');
            PdfFileType:
                EXIT('pdf');
            PageFileType:
                EXIT('png');
            HtmlFileType:
                EXIT('html');
        END;
    end;

    internal procedure TiffFileType(): Integer
    begin
        EXIT(FileType::Tiff)
    end;

    internal procedure PdfFileType(): Integer
    begin
        EXIT(FileType::Pdf)
    end;

    internal procedure MiscFileType(): Integer
    begin
        EXIT(FileType::Miscellaneous)
    end;

    internal procedure PageFileType(): Integer
    begin
        EXIT(FileType::"Document Page")
    end;

    internal procedure EmailFileType(): Integer
    begin
        EXIT(FileType::"E-Mail")
    end;

    internal procedure HtmlFileType(): Integer
    begin
        EXIT(FileType::Html)
    end;

    internal procedure XmlOriginalFileType(): Integer
    begin
        EXIT(FileType::"Xml (Original)")
    end;

    internal procedure XmlTrimmedFileType(): Integer
    begin
        EXIT(FileType::"Xml (Trimmed)")
    end;

    internal procedure DCADV_MigrationIsInProgress(SpecificCompanyName: Text[30]): Boolean
    var
        StorageMigrationSetup: Record "CDC Storage Migration Setup";
    begin
        StorageMigrationSetup.CHANGECOMPANY(SpecificCompanyName);
        EXIT(StorageMigrationSetup.GET);
        if StorageMigrationSetup.Get() then
            Error('Storage migration is in progress for company %1 but not supported by DCFileAPI app', SpecificCompanyName);
    end;

    internal procedure DCADV_GetMigrationSetup(var DCSetup: Record "CDC Document Capture Setup")
    var
        StorageMigrationSetup: Record "CDC Storage Migration Setup";
    begin
        //StorageMigrationSetup.CHANGECOMPANY(CurrentCompanyName);
        StorageMigrationSetup.GET;
        DCSetup.TRANSFERFIELDS(StorageMigrationSetup);
    end;
}