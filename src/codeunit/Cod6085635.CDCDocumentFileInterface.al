//Clone of codeunit 6085635 "CDC Document File Interface"
//GetCleanXmlFile
//SetCleanXmlFile
//SetHtmlFile
//SetXmlFile
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
        StorageMigrationMgt: Codeunit "CDC Storage Migration Mgt.";
        ShowErrorDialog: Boolean;

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
    /*
        internal procedure HasTiffFile(var Document: Record "CDC Document") Result: Boolean
        var
            Handled: Boolean;
        begin
            IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
                EXIT(FALSE);

            CASE DCSetup."Document Storage Type" OF
                DCSetup."Document Storage Type"::Database:
                    EXIT(DocBlobStorageMgt.HasTiffFile(Document));
                DCSetup."Document Storage Type"::"File Service":
                    EXIT(DocFileServiceMgt.HasTiffFile(Document));

            END;
        end;

        internal procedure HasPdfFile(var Document: Record "CDC Document") Result: Boolean
        var
            Handled: Boolean;
        begin
            IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
                EXIT(FALSE);

            CASE DCSetup."Document Storage Type" OF
                DCSetup."Document Storage Type"::Database:
                    EXIT(DocBlobStorageMgt.HasPdfFile(Document));
                DCSetup."Document Storage Type"::"File Service":
                    EXIT(DocFileServiceMgt.HasPdfFile(Document));
            END;
        end;

        internal procedure HasMiscFile(var Document: Record "CDC Document") Result: Boolean
        var
            Handled: Boolean;
        begin
            IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
                EXIT(FALSE);

            CASE DCSetup."Document Storage Type" OF
                DCSetup."Document Storage Type"::Database:
                    EXIT(DocBlobStorageMgt.HasMiscFile(Document));
                DCSetup."Document Storage Type"::"File Service":
                    EXIT(DocFileServiceMgt.HasMiscFile(Document));
            END;
        end;

        internal procedure HasEmailFile(var Document: Record "CDC Document"; EmailGUID: Guid) Result: Boolean
        var
            Handled: Boolean;
        begin
            exit(false) //DCADV not implemented
            /*
            IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
                EXIT(FALSE);

            CASE DCSetup."Document Storage Type" OF
                DCSetup."Document Storage Type"::Database:
                    EXIT(DocBlobStorageMgt.HasEmailFile(EmailGUID));
                DCSetup."Document Storage Type"::"File Service":
                    EXIT(DocFileServiceMgt.HasEmailFile(Document, EmailGUID));
            END;
            */
    /*end;

    internal procedure HasXmlFile(var Document: Record "CDC Document") Result: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.HasXmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.HasXmlFile(Document));
        END;
    end;

    internal procedure HasCleanXmlFile(var Document: Record "CDC Document") Result: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.HasCleanXmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.HasCleanXmlFile(Document));
        END;
    end;

    internal procedure HasPngFile(var "Page": Record "CDC Document Page") Result: Boolean
    var
        Document: Record "CDC Document";
        Handled: Boolean;
    begin
        Document.CHANGECOMPANY(CurrentCompany);
        Document.GET(Page."Document No.");
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.HasPngFile(Page));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.HasPngFile(Page));
        END;
    end;

    internal procedure HasHtmlFile(var Document: Record "CDC Document") Result: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.HasHtmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.HasHtmlFile(Document));
        END;
    end;

    internal procedure ClearTiffFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearTiffFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearTiffFile(Document));
        END;
    end;

    internal procedure ClearPdfFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearPdfFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearPdfFile(Document));
        END;
    end;

    internal procedure ClearMiscFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearMiscFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearMiscFile(Document));
        END;
    end;

    internal procedure ClearEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid) Success: Boolean
    var
        Handled: Boolean;
    begin
        exit(false); //DCADV not implemented
        /*IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::"File System":
                EXIT(DocFileSystem.ClearEmailFile(Document, EmailGuid));
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearEmailFile(Document, EmailGuid));
            DCSetup."Document Storage Type"::"Azure Blob Storage":
                EXIT(DocAzureBlobStorMgt.ClearEmailFile(Document, EmailGuid));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearEmailFile(Document, EmailGuid));
        END;
        */
    /*end;

    internal procedure ClearXmlFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        ClearCleanXmlFile(Document); // We delete the XML File without Namespaces also
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearXmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearXmlFile(Document));
        END;
    end;

    internal procedure ClearCleanXmlFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearCleanXmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearCleanXmlFile(Document));
        END;
    end;

    internal procedure ClearPngFile(var "Page": Record "CDC Document Page") Success: Boolean
    var
        Document: Record "CDC Document";
        Handled: Boolean;
    begin
        Document.CHANGECOMPANY(CurrentCompany);
        Document.GET(Page."Document No.");
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearPngFile(Page));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearPngFile(Page));
        END;
    end;

    internal procedure ClearHtmlFile(var Document: Record "CDC Document") Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.ClearHtmlFile(Document));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.ClearHtmlFile(Document));
        END;
    end;

    internal procedure GetTiffFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, TiffFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetTiffFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetTiffFile(Document, TempFile));
        END;
    end;

    internal procedure GetPdfFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, PdfFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetPdfFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetPdfFile(Document, TempFile));
        END;
    end;

    internal procedure GetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, MiscFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetMiscFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetMiscFile(Document, TempFile));
        END;
    end;

    internal procedure GetEmailFile(var Document: Record "CDC Document"; EmailGUID: Guid; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        exit(false); //DCADV not implemented
        /*
        IF NOT GetDCSetup(Document."Storage Migration Pending") THEN
            EXIT(FALSE);

        TempFile.INIT;
        TempFile.Name := GetEmailFileName(EmailGUID);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetEmailFile(EmailGUID, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetEmailFile(Document, EmailGUID, TempFile));
        END;
        */
    /*end;

    internal procedure GetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, XmlOriginalFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetXmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetXmlFile(Document, TempFile));
        END;
    end;

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

    internal procedure GetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
        Document: Record "CDC Document";
    begin
        Document.CHANGECOMPANY(CurrentCompany);
        Document.GET(Page."Document No.");
        GetDCSetup(Document."Storage Migration Pending");

        TempFile.INIT;
        TempFile.Name := GetPageFileName(Page, Document);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetPngFile(Page, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetPngFile(Page, TempFile));
        END;
    end;

    internal procedure GetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        GetDCSetup(Document."Storage Migration Pending");

        TempFile.INIT;
        TempFile.Name := GetFileName(Document, HtmlFileType);

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetHtmlFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.GetHtmlFile(Document, TempFile));
        END;
    end;

    internal procedure SetTiffFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(FALSE) THEN
            EXIT(FALSE);
        SetErrorDialogHandling;

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetTiffFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetTiffFile(Document, TempFile));
        END;
    end;

    internal procedure SetPdfFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(FALSE) THEN
            EXIT(FALSE);
        SetErrorDialogHandling;


        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetPdfFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetPdfFile(Document, TempFile));
        END;
    end;

    internal procedure SetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(FALSE) THEN
            EXIT(FALSE);
        SetErrorDialogHandling;

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetMiscFile(Document, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetMiscFile(Document, TempFile));
        END;
    end;

    internal procedure SetEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Handled: Boolean;
    begin
        IF NOT GetDCSetup(FALSE) THEN
            EXIT(FALSE);
        SetErrorDialogHandling;

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetEmailFile(EmailGuid, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetEmailFile(Document, EmailGuid, TempFile));
        END;
    end;





    internal procedure SetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        Document: Record "CDC Document";
        Handled: Boolean;
    begin
        GetDCSetup(FALSE);
        SetErrorDialogHandling;
        Document.CHANGECOMPANY(CurrentCompany);
        Document.GET(Page."Document No.");

        CASE DCSetup."Document Storage Type" OF
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.SetPngFile(Page, TempFile));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(DocFileServiceMgt.SetPngFile(Page, TempFile));
        END;
    end;



    internal procedure GetStorageLocation() StorageLocation: Text[1024]
    begin
        IF NOT GetDCSetup(FALSE) THEN
            EXIT('');

        CASE DCSetup."Document Storage Type" OF
            //DCSetup."Document Storage Type"::"File System":
            //    EXIT(DocFileSystem.GetStorageLocation);
            DCSetup."Document Storage Type"::Database:
                EXIT(DocBlobStorageMgt.GetStorageLocation);
            DCSetup."Document Storage Type"::"Azure Blob Storage":
                EXIT(FORMAT(DCSetup."Document Storage Type"::"Azure Blob Storage"));
            DCSetup."Document Storage Type"::"File Service":
                EXIT(FORMAT(DCSetup."Document Storage Type"::"File Service"));
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

    internal procedure SetDCSetup(NewDCSetup: Record "CDC Document Capture Setup")
    begin
        DCSetup := NewDCSetup;

        /*DCADV Change
        IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"File System" THEN
            DocFileSystem.SetDCSetup(DCSetup);

        IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"Azure Blob Storage" THEN
            DocAzureBlobStorMgt.SetDCSetup(DCSetup);
        */
    /*IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"File Service" THEN
        DocFileServiceMgt.SetDCSetup(DCSetup);

    GotDCSetup := TRUE;
end;

internal procedure SetCurrentCompany(NewCompanyName: Text[50])
begin
    IF NewCompanyName <> '' THEN
        IF DCADV_MigrationIsInProgress(NewCompanyName) THEN
            exit; //StorageMigrationSetup.SetCurrentCompany(NewCompanyName);

    IF NOT GotDCSetup THEN BEGIN
        DCSetup.CHANGECOMPANY(NewCompanyName);
        GetDCSetup(FALSE);
    END;

    DocBlobStorageMgt.SetCurrentCompany(NewCompanyName);
    //DocFileSystem.SetCurrentCompany(NewCompanyName);
    //DocAzureBlobStorMgt.SetCurrentCompany(NewCompanyName);
    DocFileServiceMgt.SetCurrentCompany(NewCompanyName);
    CurrentCompany := NewCompanyName;
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

local procedure GetPageFileName(var "Page": Record "CDC Document Page"; Document: Record "CDC Document"): Text[1024]
begin
    IF Document."Document ID" <> '' THEN
        EXIT(STRSUBSTNO('%1-%2.png', Page."Document No." + '-' + Document."Document ID", Page."Page No."))
    ELSE
        EXIT(STRSUBSTNO('%1-%2.png', Page."Document No.", Page."Page No."));
end;

local procedure GetEmailFileName(EmailGUID: Guid): Text[1024]
begin
    EXIT(STRSUBSTNO('%1.eml', COPYSTR(FORMAT(EmailGUID), 2, 36)));
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

internal procedure SetShowErrorDialog(NewShowErrorDialog: Boolean)
begin
    ShowErrorDialog := NewShowErrorDialog;
end;

local procedure SetErrorDialogHandling()
begin
    CASE DCSetup."Document Storage Type" OF
        DCSetup."Document Storage Type"::"File Service":
            DocFileServiceMgt.SetShowErrorDialog(ShowErrorDialog);
    END;
end;
*/
}