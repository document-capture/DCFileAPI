
//Clone of codeunit 6085638 "CDC Document Blob Storage Mgt."
codeunit 63066 "DCADV Doc. Blob Storage Mgt."
{
    // C/SIDE
    // revision:75


    trigger OnRun()
    begin
    end;

    var
        CurrentCompanyName: Text[50];
        Text0001: Label 'Database';

    internal procedure HasTiffFile(var Document: Record "CDC Document"): Boolean
    begin
        Document.CALCFIELDS("TIFF Image File");
        EXIT(Document."TIFF Image File".HASVALUE);
    end;

    internal procedure HasPdfFile(var Document: Record "CDC Document"): Boolean
    begin
        Document.CALCFIELDS("PDF File");
        EXIT(Document."PDF File".HASVALUE);
    end;

    internal procedure HasMiscFile(var Document: Record "CDC Document"): Boolean
    begin
        IF Document."File Extension" = '' THEN
            EXIT(FALSE);

        Document.CALCFIELDS("Misc. File");
        EXIT(Document."Misc. File".HASVALUE);
    end;

    /*TODO Disabled due to inaccessable 
    internal procedure HasEmailFile(EmailGUID: Guid): Boolean
    var
        Email: Record "CDC E-mail";
    begin
        IF CurrentCompanyName <> '' THEN
            Email.SetCurrentCompany(CurrentCompanyName);

        IF Email.GET(EmailGUID) THEN
            EXIT(Email."E-Mail File".HASVALUE);
    end;
    */

    internal procedure HasXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        Document.CALCFIELDS("XML File");
        EXIT(Document."XML File".HASVALUE);
    end;

    internal procedure HasCleanXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        Document.CALCFIELDS("Clean XML File");
        EXIT(Document."Clean XML File".HASVALUE);
    end;

    internal procedure HasPngFile(var "Page": Record "CDC Document Page"): Boolean
    begin
        Page.CALCFIELDS("PNG Data");
        EXIT(Page."PNG Data".HASVALUE);
    end;

    internal procedure HasHtmlFile(var Document: Record "CDC Document"): Boolean
    begin
        Document.CALCFIELDS("HTML File");
        EXIT(Document."HTML File".HASVALUE);
    end;

    internal procedure ClearTiffFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."TIFF Image File");
        Document.MODIFY;
    end;

    internal procedure ClearPdfFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."PDF File");
        Document.MODIFY;
    end;

    internal procedure ClearMiscFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."Misc. File");
        Document.MODIFY;
    end;

    /*TODO Disabled due to inaccessable 
    internal procedure ClearEmailFile(var Document: Record "CDC Document"; EmailGUID: Guid): Boolean
    var
        EMail: Record "CDC E-mail";
    begin
        IF CurrentCompanyName <> '' THEN
            EMail.SetCurrentCompany(CurrentCompanyName);

        IF EMail.GET(EmailGUID) THEN
            IF NOT EMail.HasMoreDocuments THEN BEGIN
                CLEAR(EMail."E-Mail File"); // Remove email blob from table
                EMail.MODIFY;
            END;
    end;
    */
    internal procedure ClearXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."XML File");
        Document.MODIFY;
        ClearCleanXmlFile(Document);
    end;

    internal procedure ClearCleanXmlFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."Clean XML File");
        Document.MODIFY;
    end;

    internal procedure ClearPngFile(var "Page": Record "CDC Document Page"): Boolean
    begin
        CLEAR(Page."PNG Data");
        Page.MODIFY;
    end;

    internal procedure ClearHtmlFile(var Document: Record "CDC Document"): Boolean
    begin
        CLEAR(Document."HTML File");
        Document.MODIFY;
    end;

    internal procedure GetTiffFile(var Document: Record "CDC Document"; var File: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("TIFF Image File");

        Document."TIFF Image File".CREATEINSTREAM(ReadStream);
        File.CreateFromStream(Document."No." + '.tiff', ReadStream);
        EXIT(Document."TIFF Image File".HASVALUE);
    end;

    internal procedure GetPdfFile(var Document: Record "CDC Document"; var File: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("PDF File");

        Document."PDF File".CREATEINSTREAM(ReadStream);
        File.CreateFromStream(Document."No." + '.pdf', ReadStream);
        EXIT(Document."PDF File".HASVALUE);
    end;

    internal procedure GetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("Misc. File");

        Document."Misc. File".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(Document.Description + '.' + Document."File Extension", ReadStream);

        EXIT(Document."Misc. File".HASVALUE);
    end;

    /*TODO Disabled due to inaccessable 
    internal procedure GetEmailFile(EmailGUID: Guid; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        EMail: Record "CDC E-mail";
        ReadStream: InStream;
    begin
        IF CurrentCompanyName <> '' THEN
            EMail.CHANGECOMPANY(CurrentCompanyName);

        IF EMail.GET(EmailGUID) THEN BEGIN
            IF EMail."E-Mail File".HASVALUE THEN BEGIN
                EMail.CALCFIELDS("E-Mail File");
                EMail."E-Mail File".CREATEINSTREAM(ReadStream);
                TempFile.CreateFromStream(EMail.GetEmailGUIDAsText + '.eml', ReadStream);
            END;
            EXIT(EMail."E-Mail File".HASVALUE);
        END;
    end;
    */
    internal procedure GetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("XML File");

        Document."XML File".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(Document."No." + '.' + Document."File Extension", ReadStream);

        EXIT(Document."XML File".HASVALUE);
    end;

    internal procedure GetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("Clean XML File");

        Document."Clean XML File".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(Document."No." + '_NN' + '.' + Document."File Extension", ReadStream);

        EXIT(Document."Clean XML File".HASVALUE);
    end;

    internal procedure GetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Page.CALCFIELDS("PNG Data");

        Page."PNG Data".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(STRSUBSTNO('%1_%2.%3', Page."Document No.", Page."Page No.", 'png'), ReadStream);

        EXIT(Page."PNG Data".HASVALUE);
    end;

    internal procedure GetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
    begin
        Document.CALCFIELDS("HTML File");

        Document."HTML File".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(Document."No." + '.html', ReadStream);

        EXIT(Document."HTML File".HASVALUE);
    end;

    internal procedure SetTiffFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        CLEAR(Document."TIFF Image File");

        Document."TIFF Image File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure SetPdfFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        CLEAR(Document."PDF File");

        Document."PDF File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure SetMiscFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        CLEAR(Document."Misc. File");

        Document."Misc. File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure SetEmailFile(var EmailGUID: Guid; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        EMail: Record "CDC E-mail";
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        IF CurrentCompanyName <> '' THEN
            EMail.CHANGECOMPANY(CurrentCompanyName);

        IF EMail.GET(EmailGUID) THEN BEGIN
            CLEAR(EMail."E-Mail File");
            EMail."E-Mail File".CREATEOUTSTREAM(WriteStream);
            TempFile.Data.CREATEINSTREAM(ReadStream);
            COPYSTREAM(WriteStream, ReadStream);
            EXIT(EMail.MODIFY);
        END ELSE BEGIN
            EMail.INIT;
            EMail.GUID := EmailGUID;
            EMail."E-Mail File".CREATEOUTSTREAM(WriteStream);
            TempFile.Data.CREATEINSTREAM(ReadStream);
            COPYSTREAM(WriteStream, ReadStream);
            EXIT(EMail.INSERT);
        END;
    end;

    internal procedure SetXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        Document."XML File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure SetCleanXmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        Document."Clean XML File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure SetPngFile(var "Page": Record "CDC Document Page"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        Page."PNG Data".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Page.MODIFY);
    end;

    internal procedure SetHtmlFile(var Document: Record "CDC Document"; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        ReadStream: InStream;
        WriteStream: OutStream;
    begin
        Document."HTML File".CREATEOUTSTREAM(WriteStream);
        TempFile.GetDataStream(ReadStream);
        COPYSTREAM(WriteStream, ReadStream);
        EXIT(Document.MODIFY);
    end;

    internal procedure GetTiffFileSize(var Document: Record "CDC Document"): Integer
    var
        File: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("TIFF Image File");
        EXIT(Document."TIFF Image File".LENGTH);
    end;

    internal procedure GetPdfFileSize(var Document: Record "CDC Document"): Integer
    var
        File: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("PDF File");
        EXIT(Document."PDF File".LENGTH);
    end;

    internal procedure GetMiscFileSize(var Document: Record "CDC Document"): Integer
    var
        TempFile: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("Misc. File");
        EXIT(Document."Misc. File".LENGTH);
    end;

    internal procedure GetEmailFileSize(EmailGUID: Guid): Integer
    var
        EMail: Record "CDC E-mail";
        TempFile: Record "CDC Temp File" temporary;
    begin
        IF CurrentCompanyName <> '' THEN
            EMail.CHANGECOMPANY(CurrentCompanyName);

        IF EMail.GET(EmailGUID) THEN BEGIN
            IF EMail."E-Mail File".HASVALUE THEN BEGIN
                EMail.CALCFIELDS("E-Mail File");
            END;
            EXIT(EMail."E-Mail File".LENGTH);
        END;
    end;

    internal procedure GetXmlFileSize(var Document: Record "CDC Document"): Integer
    var
        TempFile: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("XML File");
        EXIT(Document."XML File".LENGTH);
    end;

    internal procedure GetCleanXmlFileSize(var Document: Record "CDC Document"): Integer
    var
        TempFile: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("Clean XML File");
        EXIT(Document."Clean XML File".LENGTH);
    end;

    internal procedure GetPngFileSize(var "Page": Record "CDC Document Page"): Integer
    var
        TempFile: Record "CDC Temp File" temporary;
    begin
        Page.CALCFIELDS("PNG Data");
        EXIT(Page."PNG Data".LENGTH);
    end;

    internal procedure GetHtmlFileSize(var Document: Record "CDC Document"): Integer
    var
        TempFile: Record "CDC Temp File" temporary;
    begin
        Document.CALCFIELDS("HTML File");
        EXIT(Document."HTML File".LENGTH);
    end;

    internal procedure GetStorageLocation(): Text[1024]
    var
        Document: Record "CDC Document";
    begin
        EXIT(Text0001);
    end;

    internal procedure SetCurrentCompany(NewCompanyName: Text[50])
    begin
        CurrentCompanyName := NewCompanyName;
    end;
}

