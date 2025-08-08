codeunit 63060 "DCADV File API Management"
{
    var
        DCSetup: Record "CDC Document Capture Setup";

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
        DCSetup.Get();
        DCSetup.TestField("API Url");

        Headers := Client.DefaultRequestHeaders;
        Headers.Add('Accept', '*/*');

        if Client.Get(DCSetup."API Url", Response) then
            Message('Connection successfully established')
        else
            Error('Connection not successful:\%1 - %2', Response.HttpStatusCode, Response.ReasonPhrase);

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
        Convert: Codeunit "Base64 Convert";
        ApiMgt: Codeunit "DCADV Json Management";
        i: Integer;
        TiffInStr: InStream;
    begin
        Document.CalcFields("No. of Pages");

        if not Document.GetTiffFile(TempFile) then
            exit(false);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(TiffInStr);

        ApiMgt.AddInputFile(Convert.ToBase64(TiffInStr));
        ApiMgt.AddInteger('dpi', GetDocumentCategoryResolution(Document."Document Category Code"));
        ApiMgt.AddInteger('colorMode', GetDocumentCategoryColorMode(Document."Document Category Code").AsInteger());

        if not ApiMgt.Send('ConvertTiffToPng', 'Post') then
            exit(false);

        while i < ApiMgt.GetOutputFilesQty() do begin
            DocumentPage.SetRange("Document No.", Document."No.");
            DocumentPage.SetRange("Page No.", i + 1);
            // Try to find the document page record or insert a new one
            if not DocumentPage.FindFirst() then begin
                DocumentPage.Init();
                DocumentPage."Document No." := Document."No.";
                DocumentPage."Page No." := i;
                DocumentPage.Insert();
            end;

            // Convert the base64 string to an Outstream and save it via the DocumentPage record to the central storage
            Clear(TempFile);
            if ApiMgt.GetOutputFile(i, TempFile) then
                if not DocumentPage.SetPngFile(TempFile) then
                    exit(false);
            i += 1;
        end;
    end;

    internal procedure CreateCleanXMLFile(Document: Record "CDC Document"; var XmlTempFile: Record "CDC Temp File" temporary): Boolean
    var
        StylesheetFile: Record "CDC Temp File" temporary;
        CleanXmlFile: Record "CDC Temp File" temporary;
        FileInterface: Codeunit "DCADV Document File Interface";
    begin
        // Get the stylesheet file content for the XML transformation to a clean XML without namespaces
        WriteAsText(StylesheetFile, GetRemoveNamespacesXSLTText_Clone());

        if TransformFromStream(StylesheetFile, XmlTempFile, 'RemoveNamespace.xsl', CleanXmlFile, true) then
            Fileinterface.SetCleanXmlFile(Document, CleanXmlFile);
    end;

    /// <summary>
    /// Creates an HTML preview file from a XML file
    /// </summary>
    /// <param name="Document">CDC Document of type XML</param>
    /// <returns>True if transformation was successful</returns>
    internal procedure CreateDocumentHtml(var Document: Record "CDC Document"): Boolean
    var
        Template: Record "CDC Template";
        StylesheetFile: Record "CDC Temp File" temporary;
        XmlFile: Record "CDC Temp File" temporary;
        HtmlFile: Record "CDC Temp File" temporary;
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

    /// <summary>
    /// Retrieves the stylesheet content from the document's master template.
    /// Here we use a hack to prevent DC from executing the default CreateHtml procedure and run into timeout issues.
    /// Therefore we copy  the "XML Stylesheet File" from CDC Document into "XML Stylesheet File Copy" and use this one going forward.
    /// Finally the original stylesheet content is deleted from the "XML Stylesheet File" field.
    /// </summary>
    /// <param name="TempFile">Temp. file to transport the result stylesheet content for later processing</param>
    /// <param name="Template">Template record to use</param>
    /// <returns></returns>
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

    /// <summary>
    /// Transforms an XML file using a stylesheet file and returns the result in an output file.
    /// </summary>
    /// <param name="StylesheetFile">The stylesheet file as temp. file</param>
    /// <param name="XmlFile">The original XML file</param>
    /// <param name="MainStylesheetFilename">The name of the XML stylesheet file</param>
    /// <param name="OutputFile">The response as styled xml/html temp. file document</param>
    /// <param name="SuppressError"></param>
    /// <returns></returns>
    internal procedure TransformFromStream(StylesheetFile: Record "CDC Temp File" temporary; var XmlFile: Record "CDC Temp File" temporary; MainStylesheetFilename: Text[1024]; var OutputFile: Record "CDC Temp File" temporary; SuppressError: Boolean) Success: Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
        //DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        Convert: Codeunit "Base64 Convert";
        RequestJsonObject: JsonObject;
        ResponseJsonObject: JsonObject;
        RequestJsonBody: Text;
        DocumentJsonToken: JsonToken;
        DocumentOutStr: OutStream;
        //Document: Record "CDC Document";
        Base64Document: Text;

    begin
        ApiMgt.ClearAll();
        if ApiMgt.AddFile('xmlFile', XmlFile) then
            if ApiMgt.AddFile('stylesheetFile', StylesheetFile) then begin
                ApiMgt.AddText('mainStyleSheetName', MainStylesheetFilename);


                // Send request and process response
                if ApiMgt.Send('TransformXml', 'Post') then begin
                    exit(ApiMgt.GetOutputFile(0, OutputFile));
                end;
            end;
    end;

    local procedure WriteAsText(var TempFile: Record "CDC Temp File" temporary; Content: Text[1024])
    var
        OutStr: OutStream;
    begin

        CLEAR(TempFile.Data);
        IF Content = '' THEN
            EXIT;
        TempFile.Data.CREATEOUTSTREAM(OutStr);
        OutStr.WRITETEXT(Content);
    end;

    /// <summary>
    /// Procedure creates a XSLT stylesheet file content to remove namespaces from an XML file.
    /// </summary>
    /// <returns></returns>
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

    /// <summary>
    /// Returns the resolution of the document category. The resolution is used to convert a tiff file into a png file.
    /// </summary>
    /// <param name="DocCategory">Document Category Code</param>
    /// <returns>Integer value of document categorie's resolution</returns>
    internal procedure GetDocumentCategoryResolution(DocCategory: Code[10]): Integer
    var
        CDCDocumentCategory: Record "CDC Document Category";
    begin
        if not CDCDocumentCategory.Get(DocCategory) then
            exit(-1);

        exit(CDCDocumentCategory."TIFF Image Resolution");
    end;

    /// <summary>
    /// Returns the color mode of the document category. The color mode is used to convert a tiff file into a png file.
    /// </summary>
    /// <param name="Doccategory">Document Capture - Document Category Code as each category can have different settings</param>
    /// <returns></returns>
    internal procedure GetDocumentCategoryColorMode(Doccategory: Code[10]): enum "DCADV Color Mode"
    var
        CDCDocumentCategory: Record "CDC Document Category";
    begin
        if CDCDocumentCategory.Get(DocCategory) then
            case CDCDocumentCategory."TIFF Image Colour Mode" of
                CDCDocumentCategory."TIFF Image Colour Mode"::Colour:
                    exit("DCADV Color Mode"::Color);
                CDCDocumentCategory."TIFF Image Colour Mode"::Gray:
                    exit("DCADV Color Mode"::Grayscale);
                CDCDocumentCategory."TIFF Image Colour Mode"::"Black & White":
                    exit("DCADV Color Mode"::Monochrome);
            end;

        //Fall back to color mode if the document category is not found
        exit("DCADV Color Mode"::Color);
    end;
    // Local helper procedures <<<
}
