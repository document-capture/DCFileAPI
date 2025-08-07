
//Clone of codeunit 6085638 "CDC Document Blob Storage Mgt."
codeunit 63066 "DCADV Doc. Blob Storage Mgt."
{
    // C/SIDE
    // revision:75


    trigger OnRun()
    begin
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
}