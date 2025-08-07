
//Clone of: codeunit 6085645 "CDC Document File Service"
codeunit 63068 "DCADV Document File Service"
{
    // C/SIDE
    // revision:32


    trigger OnRun()
    begin
    end;

    var
        ContiniaCompanySetup: Record "CDC Continia Company Setup";
        DCSetup: Record "CDC Document Capture Setup";
        FileServiceMgt: Codeunit "DCADV File Service Management";
        CurrentCompanyName: Text[50];
        GotContiniaCompanySetup: Boolean;
        GotDCSetup: Boolean;

    internal procedure HasTiffFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetTiffServerFileName(Document)));
    end;

    internal procedure HasPdfFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetPdfServerFileName(Document)));
    end;

    internal procedure HasMiscFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetMiscServerFileName(Document)));
    end;

    internal procedure HasEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetEMailServerFileName(Document, EmailGuid)));
    end;

    internal procedure HasXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetXmlServerFileName(Document)));
    end;

    internal procedure HasCleanXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetCleanXmlServerFileName(Document)));
    end;

    internal procedure HasPngFile(var "Page": Record "CDC Document Page"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetPngServerFileName(Page)));
    end;

    internal procedure HasDocumentPngFile(var Document: Record "CDC Document"; var "Page": Record "CDC Document Page"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetDocumentPngServerFileName(Document, Page)));
    end;

    internal procedure HasHtmlFile(var Document: Record "CDC Document"): Boolean
    begin
        EXIT(FileServiceMgt.HasFile(GetHtmlServerFileName(Document)));
    end;

    internal procedure ClearTiffFile(var Document: Record "CDC Document"): Boolean
    begin
        IF HasTiffFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetTiffServerFileName(Document)));
    end;

    internal procedure ClearPdfFile(var Document: Record "CDC Document"): Boolean
    begin
        IF HasPdfFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetPdfServerFileName(Document)));
    end;

    internal procedure ClearMiscFile(var Document: Record "CDC Document"): Boolean
    begin
        IF HasMiscFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetMiscServerFileName(Document)));
    end;

    /*DCADV hide due to protection:
    internal procedure ClearEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid): Boolean
    begin
        IF NOT EmailHasMoreDocuments(GetEMailServerFileName(Document, EmailGuid), Document, EmailGuid) THEN
            IF HasEmailFile(Document, EmailGuid) THEN
                EXIT(FileServiceMgt.ClearFile(GetEMailServerFileName(Document, EmailGuid)));
    end;
    */

    internal procedure ClearXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        ClearCleanXmlFile(Document); // We delete the XML File without Namespaces also
        IF HasXmlFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetXmlServerFileName(Document)));
    end;

    internal procedure ClearCleanXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        IF HasCleanXmlFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetCleanXmlServerFileName(Document)));
    end;

    internal procedure ClearPngFile(var "Page": Record "CDC Document Page"): Boolean
    begin
        IF HasPngFile(Page) THEN
            EXIT(FileServiceMgt.ClearFile(GetPngServerFileName(Page)));
    end;

    internal procedure ClearDocumentPngFile(var Document: Record "CDC Document"; var "Page": Record "CDC Document Page"): Boolean
    begin
        IF HasDocumentPngFile(Document, Page) THEN
            EXIT(FileServiceMgt.ClearFile(GetDocumentPngServerFileName(Document, Page)));
    end;

    internal procedure ClearHtmlFile(var Document: Record "CDC Document"): Boolean
    begin
        IF HasHtmlFile(Document) THEN
            EXIT(FileServiceMgt.ClearFile(GetHtmlServerFileName(Document)));
    end;

    internal procedure GetTiffFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetTiffServerFileName(Document), TempFile));
    end;

    internal procedure GetPdfFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetPdfServerFileName(Document), TempFile));
    end;

    internal procedure GetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetMiscServerFileName(Document), TempFile));
    end;

    internal procedure GetEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetEMailServerFileName(Document, EmailGuid), TempFile));
    end;

    internal procedure GetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetXmlServerFileName(Document), TempFile));
    end;

    internal procedure GetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetCleanXmlServerFileName(Document), TempFile));
    end;

    internal procedure GetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetPngServerFileName(Page), TempFile));
    end;

    internal procedure GetDocumentPngFile(var Document: Record "CDC Document"; var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetDocumentPngServerFileName(Document, Page), TempFile));
    end;

    internal procedure GetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetHtmlServerFileName(Document), TempFile));
    end;

    internal procedure SetTiffFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetTiffServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetPdfFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetPdfServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetMiscServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetEmailFile(var Document: Record "CDC Document"; EmailGuid: Guid; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetEMailServerFileName(Document, EmailGuid);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetXmlServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetCleanXmlServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetPngServerFileName(Page);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    internal procedure SetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        FileName: Text;
    begin
        FileName := GetHtmlServerFileName(Document);

        IF FileServiceMgt.HasFile(FileName) THEN
            FileServiceMgt.ClearFile(FileName);

        FileServiceMgt.SetFile(FileName, TempFile);
        EXIT(TRUE);
    end;

    local procedure GetTiffServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'tiff');
    end;

    local procedure GetPdfServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'pdf');
    end;

    local procedure GetEMailServerFileName(var Document: Record "CDC Document"; EmailGuid: Guid) FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");

        FullFilename := STRSUBSTNO('%1/%2%3.%4', DCSetup."Archive File Path", GetDocSubDir(Document), GetEmailGUIDAsText(EmailGuid), 'eml');
    end;

    local procedure GetMiscServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Miscellaneous File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Miscellaneous File Path", Document."File Extension");
    end;

    local procedure GetXmlServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'xml');
    end;

    local procedure GetCleanXmlServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetCleanXmlServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'xml');
    end;

    local procedure GetPngServerFileName(var "Page": Record "CDC Document Page") FullFilename: Text[1024]
    var
        Document: Record "CDC Document";
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        //DCADV Change due to permission Document.SetDCSetup(DCSetup);
        Document.SetCurrentCompany(CurrentCompanyName);
        Document.GET(Page."Document No.");
        FullFilename := GetPageServerFilePath(Document, Page."Page No.", Document."No.", DCSetup."Archive File Path", 'png');
    end;

    local procedure GetDocumentPngServerFileName(var Document: Record "CDC Document"; var "Page": Record "CDC Document Page") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetPageServerFilePath(Document, Page."Page No.", Document."No.", DCSetup."Archive File Path", 'png');
    end;

    internal procedure GetHtmlServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'html');
    end;

    /*DCADV hide due to protection:
    local procedure EmailHasMoreDocuments(EmailFilePath: Text[1024]; var Document: Record "CDC Document"; EmailGuid: Guid): Boolean
    var
        Document2: Record "CDC Document";
        DocumentPage: Record "CDC Document Page";
        Email: Record "CDC E-mail";
        FileSysMgt: Codeunit "CDC File System Management";
        EmptyGuid: Guid;
    begin
        IF CurrentCompanyName <> '' THEN BEGIN
            Document2.SetCurrentCompany(CurrentCompanyName);
            DocumentPage.SetCurrentCompany(CurrentCompanyName);
            Email.SetCurrentCompany(CurrentCompanyName);
        END;

        Email.SetLoadFields(GUID);
        IF Email.GET(EmailGuid) THEN
            IF Email.HasMoreDocuments THEN
                EXIT(TRUE);

        Document2.SETCURRENTKEY("E-Mail GUID");
        Document2.SETRANGE("E-Mail GUID", EmailGuid);
        Document2.SETFILTER("No.", '<>%1', Document."No.");
        IF Document2.FINDSET THEN
            REPEAT
                IF (EmailFilePath = GetEMailServerFileName(Document2, EmailGuid)) AND
                  (HasTiffFile(Document2))
                THEN
                    EXIT(TRUE);
            UNTIL Document2.NEXT = 0;

        DocumentPage.SETCURRENTKEY("E-Mail GUID");
        DocumentPage.SETRANGE("E-Mail GUID", EmailGuid);
        DocumentPage.SETFILTER("Document No.", '<>%1', Document."No.");
        IF DocumentPage.FINDSET THEN
            REPEAT
                Document2.GET(DocumentPage."Document No.");
                IF (EmailFilePath = GetEMailServerFileName(Document2, EmailGuid)) AND
                  FileServiceMgt.HasFile(EmailFilePath)
                THEN
                    EXIT(TRUE);
            UNTIL DocumentPage.NEXT = 0;
    end;
    */
    local procedure GetEmailGUIDAsText(EmailGUID: Guid): Text[50]
    begin
        EXIT(COPYSTR(FORMAT(EmailGUID), 2, 36));
    end;

    local procedure GetServerFilePath(var Document: Record "CDC Document"; Identifier: Text[50]; Path: Text[200]; Extension: Text[10]) FullFilename: Text[250]
    begin
        IF Identifier = '' THEN
            EXIT;

        IF Document."Document ID" <> '' THEN
            Identifier += '-' + Document."Document ID";

        FullFilename := STRSUBSTNO('%1%2%3.%4', Path, GetDocSubDir(Document), Identifier, Extension);
    end;

    local procedure GetCleanXmlServerFilePath(var Document: Record "CDC Document"; Identifier: Text[50]; Path: Text[200]; Extension: Text[10]) FullFilename: Text[250]
    begin
        IF Identifier = '' THEN
            EXIT;

        IF Document."Document ID" <> '' THEN
            Identifier += '-' + Document."Document ID";

        // Path to XML file with No Namespaces, therefore "_NN" (No Namespaces)
        FullFilename := STRSUBSTNO('%1%2%3_NN.%4', Path, GetDocSubDir(Document), Identifier, Extension);
    end;

    local procedure GetPageServerFilePath(var Document: Record "CDC Document"; PageNo: Integer; Identifier: Text[50]; Path: Text[200]; Extension: Text[10]) FullFilename: Text[250]
    begin
        IF Identifier = '' THEN
            EXIT;

        IF Document."Document ID" <> '' THEN
            Identifier += '-' + Document."Document ID";

        FullFilename := STRSUBSTNO('%1%2%3_%4.%5', Path, GetDocSubDir(Document), Identifier, PageNo, Extension);
    end;

    local procedure GetDocSubDir(Document: Record "CDC Document"): Text[1024]
    begin
        GetContiniaCompanySetup;
        IF NOT GetDCSetup THEN
            EXIT;

        WITH DCSetup DO
            EXIT(GetSubDir(Document, "Disk File Directory Structure", "Company Code in Archive", "Category Code in Archive",
              ContiniaCompanySetup."Company Code", Document."Document Category Code"));
    end;

    local procedure GetSubDir(Document: Record "CDC Document"; Structure: Integer; CompanyCodeInArchive: Boolean; DocCatCodeInArchive: Boolean; CompanyCode: Code[10]; CategoryCode: Code[100]): Text[1024]
    var
        Month: Code[2];
        Day: Code[2];
        Path: Text[1024];
    begin
        IF Document."Import Month" < 10 THEN
            Month := '0' + FORMAT(Document."Import Month")
        ELSE
            Month := FORMAT(Document."Import Month");

        IF Document."Import Day" < 10 THEN
            Day := '0' + FORMAT(Document."Import Day")
        ELSE
            Day := FORMAT(Document."Import Day");

        IF CompanyCodeInArchive AND (CompanyCode <> '') THEN
            Path := CompanyCode + '\';

        IF DocCatCodeInArchive AND (CategoryCode <> '') THEN
            Path := Path + CategoryCode + '\';

        CASE Structure OF
            DCSetup."Disk File Directory Structure"::"One Directory":
                EXIT(Path);
            DCSetup."Disk File Directory Structure"::"Year\Month":
                EXIT(Path + STRSUBSTNO('%1\%2\', Document."Import Year", Month));
            DCSetup."Disk File Directory Structure"::"Year\Month\Day":
                EXIT(Path + STRSUBSTNO('%1\%2\%3\', Document."Import Year", Month, Day));
        END;
    end;

    local procedure GetContiniaCompanySetup()
    begin
        IF NOT GotContiniaCompanySetup THEN
            GotContiniaCompanySetup := ContiniaCompanySetup.GET;
    end;

    local procedure GetDCSetup(): Boolean
    begin
        IF GotDCSetup THEN
            EXIT(TRUE);

        GotDCSetup := DCSetup.GET;
        EXIT(GotDCSetup);
    end;

    internal procedure SetCurrentCompany(NewCompanyName: Text[50])
    begin
        CurrentCompanyName := NewCompanyName;
        ContiniaCompanySetup.CHANGECOMPANY(CurrentCompanyName);
        FileServiceMgt.SetCurrentCompany(CurrentCompanyName);
    end;

    internal procedure SetDCSetup(var NewDCSetup: Record "CDC Document Capture Setup")
    var
        AboutDocumentCapture: Codeunit "CDC About Document Capture";
    begin
        DCSetup := NewDCSetup;
        GotDCSetup := TRUE;
        //DCADV Change: FileServiceMgt.SetProductCode(AboutDocumentCapture.ProductCode);
        FileServiceMgt.SetProductCode('CDC');
    end;

    internal procedure SetShowErrorDialog(NewShowError: Boolean)
    begin
        FileServiceMgt.SetShowErrorDialog(NewShowError);
    end;
}