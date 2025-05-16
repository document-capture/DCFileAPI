tableextension 63060 "DCADV CDCTempDocumentPage Ext." extends "CDC Temp. Document Page"
{
    internal procedure BuildTableLocal(DocCatCode: Code[10]; var Document: Record "CDC Document")
    var
        i: Integer;
        DocumentPage: Record "CDC Document Page";
    begin
        RESET;
        DELETEALL;
        Document.SETCURRENTKEY("Document Category Code", Status);
        IF DocCatCode <> '' THEN
            Document.SETRANGE("Document Category Code", DocCatCode);
        Document.SETRANGE(Status, Document.Status::Open);
        Document.SETFILTER("File Type", STRSUBSTNO('%1|%2', Document."File Type"::XML, Document."File Type"::OCR));
        IF Document.FINDSET THEN
            REPEAT
                "Display Document No." := Document."No.";
                "Source ID" := Document.GetSourceID;
                Name := Document.GetSourceName;

                Document.CALCFIELDS("No. of Pages");
                FOR i := 1 TO Document."No. of Pages" DO BEGIN
                    "Entry No." := "Entry No." + 10000;
                    "Document No." := Document."No.";
                    Page := i;
                    "Document Category Code" := Document."Document Category Code";
                    IF DocumentPage.GET("Document No.", Page) THEN
                        "Original Filename" := COPYSTR(DocumentPage."Original Filename", 1, MAXSTRLEN("Original Filename"));
                    INSERT;
                    "Display Document No." := '';
                END;
            UNTIL Document.NEXT = 0;

        IF ("Entry No." <> 0) AND (Page = 0) THEN
            DELETE;

        IF FINDFIRST THEN;
    end;
}
