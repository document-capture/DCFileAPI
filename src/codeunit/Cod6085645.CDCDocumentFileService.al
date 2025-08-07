
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
        GotContiniaCompanySetup: Boolean;
        GotDCSetup: Boolean;

    internal procedure GetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    begin
        EXIT(FileServiceMgt.GetFile(GetCleanXmlServerFileName(Document), TempFile));
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

    internal procedure GetHtmlServerFileName(var Document: Record "CDC Document") FullFilename: Text[1024]
    begin
        IF NOT GetDCSetup THEN
            EXIT;

        DCSetup.TESTFIELD("Archive File Path");
        FullFilename := GetServerFilePath(Document, Document."No.", DCSetup."Archive File Path", 'html');
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

    local procedure GetDocSubDir(Document: Record "CDC Document"): Text[1024]
    begin
        GetContiniaCompanySetup;
        IF NOT GetDCSetup THEN
            EXIT;


        EXIT(GetSubDir(Document, DCSetup."Disk File Directory Structure", DCSetup."Company Code in Archive", DCSetup."Category Code in Archive",
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

    internal procedure SetDCSetup(var NewDCSetup: Record "CDC Document Capture Setup")
    var
        AboutDocumentCapture: Codeunit "CDC About Document Capture";
    begin
        DCSetup := NewDCSetup;
        GotDCSetup := TRUE;
        //DCADV Change: FileServiceMgt.SetProductCode(AboutDocumentCapture.ProductCode);
        FileServiceMgt.SetProductCode('CDC');
    end;
}