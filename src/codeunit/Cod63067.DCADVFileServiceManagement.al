
codeunit 63067 "DCADV File Service Management"
{
    // C/SIDE
    // revision:49
    // clode of codeunit 6085644 "CDC File Service Management"

    trigger OnRun()
    begin
    end;

    var
        FileServiceSetup: Record "CSC File Service Setup";
        FileServiceMgt: Codeunit "CSC File Service Mgt.";
        FileMgt: Codeunit "File Management";
        ContainerName: Text[50];
        FileType: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";
        ShowError: Boolean;
        UploadFSOperationNotSuccessfulErr: Label 'It was not possible to upload the file (%1).\\The following error occurred during the upload: %2', Comment = '%1 = File name, %2 = GetLastErrorText';
        ProductCode: Text;

    internal procedure HasFile(FileName: Text[1024]): Boolean
    begin
        Setup(TRUE);
        EXIT(FileServiceMgt.Exist(FileName));
    end;

    internal procedure ClearFile(FileName: Text[1024]): Boolean
    begin
        Setup(TRUE);
        EXIT(FileServiceMgt.Delete(FileName));
    end;

    internal procedure GetFile(FileName: Text[1024]; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        TempBlob: Record "CSC Temp Blob" temporary;
    begin
        Setup(TRUE);
        Success := FileServiceMgt.Get(TempBlob, FileName);
        TempFile.Name := FileMgt.GetFileName(FileName);
        TempFile.Path := FileMgt.GetDirectoryName(FileName);
        TempFile."File Location" := TempFile."File Location"::"File Service";
        TempFile.Data := TempBlob.Blob;
    end;

    internal procedure SetFile(FileName: Text[1024]; var TempFile: Record "CDC Temp File" temporary) Success: Boolean
    var
        TempBlob: Record "CSC Temp Blob" temporary;
        CustomDimension: Codeunit "CTS-SYS Telemetry Dictionary";
    begin
        Setup(TRUE);
        //DCADV Original: TempFile.LoadData;
        TempBlob.Blob := TempFile.Data;
        Success := FileServiceMgt.Put(TempBlob, FileName);

        CustomDimension.Add('Filename', FileName);
        CustomDimension.Add('Container', ContainerName);
        //DCADV Original: FeatureTelemetry.LogUptake('0183', GetFeatureTelemetryName, FeatureUptakeStatus.Used, FunctionalAreaMgt.Platform);

        IF NOT Success THEN
            IF ShowError THEN BEGIN
                //DCADV Original: TelemetryManagement.LogError2('0164', 'Error upload file - File Service', FunctionalAreaMgt.DocAndTemplate,
                //DCADV Original:   FileServiceMgt.GetLastErrorText, CustomDimension);
                ERROR(STRSUBSTNO(UploadFSOperationNotSuccessfulErr, FileName, FileServiceMgt.GetLastErrorText));
            END;

        //FeatureTelemetry.LogUsage2('0184', GetFeatureTelemetryName, 'Saving file', CustomDimension, FunctionalAreaMgt.Platform);
    end;

    internal procedure DCADV_GetCompanyCodeInCompany(ShowError: Boolean; Company: Text[50]): Code[10]
    var
        ContiniaCompanySetup: Record "CDC Continia Company Setup";
    begin
        ContiniaCompanySetup.CHANGECOMPANY(Company);
        ContiniaCompanySetup.GET;

        IF ShowError THEN
            ContiniaCompanySetup.TESTFIELD("Company Code");

        EXIT(ContiniaCompanySetup."Company Code");
    end;

    local procedure Setup(WithError: Boolean): Boolean
    begin
        IF ProductCode = '' THEN
            FileServiceSetup.GET('CDC') //FileServiceSetup.GET(AboutDocumentCapture.ProductCode)
        ELSE
            FileServiceSetup.GET(ProductCode);
        FileServiceMgt.Setup(FileServiceSetup);
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
        FileExtension: Text[10];
    begin
        FileExtension := GetFileExtension(FileType);
        IF FileType = XmlTrimmedFileType THEN
            EXIT(STRSUBSTNO('%1-NN.%2', Document."No.", FileExtension))
        ELSE
            IF FileType = MiscFileType THEN
                EXIT(STRSUBSTNO('%1.%2', Document."No.", Document."File Extension"))
            ELSE
                IF FileType = EmailFileType THEN
                    EXIT(STRSUBSTNO('%1.%2', DCADV_GetEmailGUIDAsText(Document), FileExtension))
                ELSE
                    EXIT(STRSUBSTNO('%1.%2', Document."No.", FileExtension));
    end;

    local procedure DCADV_GetEmailGUIDAsText(Document: Record "CDC Document"): Text[50]
    begin
        EXIT(COPYSTR(FORMAT(Document."E-Mail GUID"), 2, 36));
    end;

    internal procedure SetProductCode(NewProductCode: Text)
    begin
        ProductCode := NewProductCode;
    end;
}