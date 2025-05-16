//https://simplanova.com/blog/the-building-blocks-of-als-http-integration-in-dynamics-365-bc/
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
}
