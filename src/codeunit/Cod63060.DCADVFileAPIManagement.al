codeunit 63060 "DCADV File API Management"
{
    var
        DCSetup: Record "CDC Document Capture Setup";
        HttpMgt: Codeunit "DCADV Http Management";
        UrlParam: text;

    /// <summary>
    /// Test the connection to the Document Capture File API.
    /// </summary>
    /// <returns>True if the connection was successfull</returns>
    internal procedure TestConnection_Request(): Boolean
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
    begin
        GetFileApiSetup();
        Headers := Client.DefaultRequestHeaders;
        Headers.Add('Accept', '*/*');

        if Client.Get(DCSetup."API Url", Response) then
            Message('Connection successfully established')
        else
            Error('Connection not successful:\%1 - %2', Response.HttpStatusCode, Response.ReasonPhrase);

    end;

    local procedure GetFileApiSetup(): Boolean
    begin
        if not DCSetup.Get() then
            exit;

        DCSetup.TestField("API Url");

        exit(true);
    end;

    local procedure GetUrl(UrlParam: text): Text
    begin
        if not GetFileApiSetup() then
            exit('');

        exit(StrSubstNo('%1/%2', DCSetup."API Url", UrlParam));
    end;

    /// <summary>
    /// Function to retrieve the page number of a document from the file name like e.g. D000013-686243238F_2.png
    /// </summary>
    /// <param name="DocumentNo">Document Capture Document No.</param>
    /// <param name="FileName">Filename that is used to exstract the page number from</param>
    /// <param name="PageNo">Page number that is returned</param>
    /// <returns>True if the page number could be extracted</returns>
    internal procedure GetPageFromFileName(DocumentNo: Code[20]; FileName: Text[1024]; var PageNo: Integer): Boolean
    var
        Document: Record "CDC Document";
    begin
        // Get the current document
        if not Document.Get(DocumentNo) then
            exit(false);

        // Remove the Document no and Documen ID first
        if Document."Document ID" <> '' then
            Filename := DelStr(FileName, 1, StrLen(Document."No." + '-' + Document."Document ID"))
        else
            Filename := DelStr(FileName, 1, StrLen(Document."No."));

        // remove file ending
        Filename := DelStr(FileName, StrPos(FileName, '.png'));

        // try to evaluate the page no
        exit(Evaluate(PageNo, DelChr(FileName, '=', '-')));
    end;

    /// <summary>
    /// Creates a PNG file from a TIFF file using the DC File API.
    /// </summary>
    /// <param name="Document">Document Capture Document record whose pages are to be converted to PNG</param>
    /// <returns>True if conversion was successfull</returns>
    internal procedure CreatePngFromTiffViaFileAPI(Document: Record "CDC Document"): Boolean
    var
        DocumentPage: Record "CDC Document Page";
        TempFile: Record "CDC Temp File" temporary;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        Convert: Codeunit "Base64 Convert";

        i: Integer;
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonPagesToken: JsonToken;
        JsonArrayValue: JsonArray;

        JsonPngToken: JsonToken;
        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Png: Text;
        PNGOutStr: OutStream;
    begin
        Document.CalcFields("No. of Pages");

        // Create json request object for conversion
        if not DCADVFileAPIJsonOBj.ConvertTiffToPng_Request(JsonObject, Document) then
            error('Error creating request object for Tiff to Png conversion.');

        // Create json body from request object
        JsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object
        if HttpMgt.SendHttpRequest(JsonObject, JsonBody, 'ConvertTiffToPng', 'Post') then begin
            JsonObject.Get('pages', JsonPagesToken);
            if JsonPagesToken.IsArray then begin
                JsonArrayValue := JsonPagesToken.AsArray();

                // Iterate through the pages array
                if (JsonarrayValue.Count() <> Document."No. of Pages") then
                    error('The number of pages in the response (%1) does not match the number of pages in the document %2.', JsonarrayValue.Count(), Document."No.");

                for i := 1 to JsonarrayValue.Count() do begin
                    JsonarrayValue.Get(i - 1, JsonPngToken);
                    if JsonPngToken.IsObject then begin
                        JsonPngObject := JsonPngToken.AsObject();
                        // Get the page data
                        if JsonPngObject.Get('pageData', JsonPageDataToken) then begin
                            if not JsonPageDataToken.AsValue().IsNull then begin
                                Base64Png := JsonPageDataToken.AsValue().AsText();

                                DocumentPage.SetRange("Document No.", Document."No.");
                                DocumentPage.SetRange("Page No.", i);
                                // Try to find the document page record or insert a new one
                                if not DocumentPage.FindFirst() then begin
                                    DocumentPage.Init();
                                    DocumentPage."Document No." := Document."No.";
                                    DocumentPage."Page No." := i;
                                    DocumentPage.Insert();
                                end;

                                // Convert the base64 string to an Outstream and save it via the DocumentPage record to the central storage
                                Clear(TempFile);
                                TempFile.Data.CreateOutStream(PNGOutStr);
                                Convert.FromBase64(Base64Png, PNGOutStr);
                                if not DocumentPage.SetPngFile(TempFile) then
                                    exit(false);
                            end;
                        end;
                    end;
                end;
                // Return true if all pages have been processed successfully
                exit((i = Document."No. of Pages"));
            end;
        end;
    end;

    internal procedure CreateCleanXMLFile(Document: Record "CDC Document"; var XmlTempFile: Record "CDC Temp File" temporary): Boolean
    var
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        CleanXmlFile: Record "CDC Temp File" temporary;
        FileInterface: Codeunit "DCADV Document File Interface";
    begin
        if RemoveNamespaces(XmlTempFile, CleanXmlFile, true) then
            Fileinterface.SetCleanXmlFile(Document, CleanXmlFile);
    end;

    internal procedure RemoveNamespaces(var XmlFile: Record "CDC Temp File" temporary; var CleanXmlFile: Record "CDC Temp File" temporary; SuppressError: Boolean): Boolean
    var
        StylesheetFile: Record "CDC Temp File" temporary;
        ErrorMessage: Text[1024];
        TempText: Text[1024];
        Result: Boolean;
    begin
        WriteAsText(StylesheetFile, GetRemoveNamespacesXSLTText_Clone());

        exit(TransformFromStream(StylesheetFile, XmlFile, 'RemoveNamespace.xsl', CleanXmlFile, true));
    end;

    internal procedure CreateDocumentHtml(var Document: Record "CDC Document"): Boolean
    var
        Template: Record "CDC Template";
        StylesheetFile: Record "CDC Temp File" temporary;
        XmlFile: Record "CDC Temp File" temporary;
        HtmlFile: Record "CDC Temp File" temporary;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        MainStylesheetFilename: Text[1024];
        FileInterface: Codeunit "DCADV Document File Interface";
        FileMgt: Codeunit "File Management";
    begin
        IF NOT Template.GET(Document."XML Master Template No.") THEN BEGIN
            Template.SETRANGE(Type, Template.Type::Master);
            Template.SETRANGE("Data Type", Template."Data Type"::XML);
            Template.SETRANGE("XML Ident. Template No.", Document."XML Ident. Template No.");
            IF NOT Template.FINDFIRST THEN
                EXIT(FALSE);
        END;

        //DCADV Not needed:
        //IF Template."Header eDoc. Table No." <> 0 THEN
        //    EXIT(CreateHTMLFileFromXMLStructure(Document, ''));

        IF NOT GetStylesheetFile_Clone(StylesheetFile, Template) THEN
            EXIT(FALSE);

        IF NOT Document.GetXmlFile(XmlFile) THEN
            EXIT(FALSE);

        IF Document."XML Document Type" = Document."XML Document Type"::CreditMemo THEN
            MainStylesheetFilename := Template."XML Stylesheet Main Filename C"
        ELSE
            MainStylesheetFilename := Template."XML Stylesheet Main Filename";

        IF STRPOS(Document."XML Master Template No.", 'FACTURAE') > 0 THEN BEGIN
            IF NOT FileInterface.GetCleanXmlFile(Document, XmlFile) THEN
                EXIT(FALSE);

            if not TransformFromStream(StylesheetFile, XmlFile, MainStylesheetFilename, HtmlFile, True) then
                EXIT(FALSE);
        END ELSE
            IF STRPOS(Document."XML Master Template No.", 'XRECH') > 0 THEN BEGIN
                if not TransformFromStream(StylesheetFile, XmlFile, MainStylesheetFilename, HtmlFile, True) then
                    EXIT(FALSE);


                HtmlFile.Name := FileMgt.GetFileNameWithoutExtension(HtmlFile.Name) + '.xml';
                IF NOT TransformFromStream(StylesheetFile, HtmlFile, 'xrechnung-html.xsl', HtmlFile, TRUE) THEN
                    EXIT(FALSE);
            END ELSE
                if not TransformFromStream(StylesheetFile, XmlFile, MainStylesheetFilename, HtmlFile, True) then
                    EXIT(FALSE);

        exit(FileInterface.SetHtmlFile(Document, HtmlFile));
    end;

    local procedure GetStylesheetFile_Clone(var TempFile: Record "CDC Temp File" temporary; Template: Record "CDC Template"): Boolean
    var
        ReadStream: InStream;
        SourceInS: InStream;
        TargetOutS: OutStream;
    begin
        Template.CALCFIELDS("XML Stylesheet File");
        if Template."XML Stylesheet File".HASVALUE then begin
            // Copy the "XML Stylesheet File" blob  to the TempFile "XML Stylesheet File Copy" blob to use this one going forward
            Template."XML Stylesheet File".CreateInStream(SourceInS);
            Template."XML Stylesheet File Copy".CreateOutStream(TargetOutS);
            CopyStream(TargetOutS, SourceInS);

            // Delete the original "XML Stylesheet File" blob
            Clear(Template."XML Stylesheet File");
            Template.Modify();
        end;

        Template.CALCFIELDS("XML Stylesheet File Copy");
        if not Template."XML Stylesheet File Copy".HASVALUE then
            exit(false); // no stylesheet file available    

        Template."XML Stylesheet File Copy".CREATEINSTREAM(ReadStream);
        TempFile.CreateFromStream(STRSUBSTNO('%1.%2', Template."No.", Template."XML Stylesheet File Extension"), ReadStream);

        EXIT(TRUE);
    end;

    procedure TransformFromStream(StylesheetFile: Record "CDC Temp File" temporary; var XmlFile: Record "CDC Temp File" temporary; MainStylesheetFilename: Text[1024]; var OutputFile: Record "CDC Temp File" temporary; SuppressError: Boolean) Success: Boolean
    var
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        XmlTransformService: Codeunit "CDC Xml Transformer SaaS";
        Convert: Codeunit "Base64 Convert";
        RequestJsonObject: JsonObject;
        ResponseJsonObject: JsonObject;
        RequestJsonBody: Text;
        DocumentJsonToken: JsonToken;
        DocumentOutStr: OutStream;
        //Document: Record "CDC Document";
        Base64Document: Text;

    begin
        if not DCADVFileAPIJsonOBj.TransformXml_Request(RequestJsonObject, XmlFile, StylesheetFile, MainStylesheetFilename) then begin
            if (GuiAllowed) and (not SuppressError) then
                Error('Error creating request object for XML transformation.');
            exit(false);
        end;

        // Create json body from request object
        RequestJsonObject.WriteTo(RequestJsonBody);

        // Build and send the request and get the response as json object
        if HttpMgt.SendHttpRequest(ResponseJsonObject, RequestJsonBody, 'TransformXml', 'Post') then begin
            if ResponseJsonObject.Get('Data', DocumentJsonToken) then begin
                if not DocumentJsonToken.AsValue().IsNull then begin
                    Base64Document := DocumentJsonToken.AsValue().AsText();

                    if StrLen(Base64Document) = 0 then
                        exit(false);

                    OutputFile.Data.CreateOutStream(DocumentOutStr);
                    Convert.FromBase64(Base64Document, DocumentOutStr);
                    exit(true);
                end;
            end;
        end;
    end;

    internal procedure WriteAsText(var TempFile: Record "CDC Temp File" temporary; Content: Text[1024])
    var
        OutStr: OutStream;
    begin
        WITH TempFile DO BEGIN
            CLEAR(Data);
            IF Content = '' THEN
                EXIT;
            Data.CREATEOUTSTREAM(OutStr);
            OutStr.WRITETEXT(Content);
        END;
    end;

    local procedure GetRemoveNamespacesXSLTText_Clone(): Text[1024]
    begin
        EXIT(
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
          '<xsl:output method="xml" encoding="UTF-8" />' +
          '<xsl:template match="/">' +
          '<xsl:copy>' +
          '<xsl:apply-templates />' +
          '</xsl:copy>' +
          '</xsl:template>' +
          '<xsl:template match="*">' +
          '<xsl:element name="{local-name()}">' +
          '<xsl:apply-templates select="@* | node()" />' +
          '</xsl:element>' +
          '</xsl:template>' +
          '<xsl:template match="@*">' +
          '<xsl:attribute name="{local-name()}"><xsl:value-of select="."/></xsl:attribute>' +
          '</xsl:template>' +
          '<xsl:template match="text() | processing-instruction() | comment()">' +
          '<xsl:copy />' +
          '</xsl:template>' +
          '</xsl:stylesheet>');
    end;

    internal procedure GetDocumentIdFromFilename(FileName: Text) DocumentID: Text
    var
        Filehandling: Codeunit "File Management";
        DashPos: Integer;
        EndPos: Integer;
    begin
        // remove extension first
        Filename := Filehandling.GetFileNameWithoutExtension(FileName);

        // get the positions of '-' and '_'
        DashPos := StrPos(FileName, '-');
        if DashPos = 0 then
            exit(''); // no dash means there is no document ID in the filename

        // Find the position of the underscore after the dash
        EndPos := StrPos(FileName, '_');

        // Wenn kein gültiges Ende gefunden wurde → Abbruch
        if (EndPos = 0) then
            DocumentId := CopyStr(FileName, DashPos + 1)
        else
            DocumentId := CopyStr(FileName, DashPos + 1, EndPos - DashPos - 1);
    end;
}
