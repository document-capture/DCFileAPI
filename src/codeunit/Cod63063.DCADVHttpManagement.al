codeunit 63063 "DCADV Http Management"
{
    var
        DCSetup: Record "CDC Document Capture Setup";


    /// <summary>
    /// Saves the request content to a file in the local file system and downloads it from the stream.
    /// </summary>
    /// <param name="RequestContent">Content as Text that should be save for debugging purposes</param>
    /// <param name="ApiService">Parameter/Uri of the DC File API - e.g. ConvertTiffToPng - used for filename</param>
    internal procedure SaveHttpContentToFileRequest(Request: Text; Response: Text; ApiService: Text[100])
    var
        FileOutStr: OutStream;
        FileInStr: InStream;
        TempBlob: Codeunit "Temp Blob";
        Filename: Text[250];
        DebugJsonObject: JsonObject;
        RequestJsonToken: JsonToken;
        //ResponseJsonObject: JsonObject;
        ResponseJsonToken: JsonToken;
        ResponseJsonArray: JsonArray;
        JsonContent: Text;
    begin
        // Process request data
        if RequestJsonToken.ReadFrom(Request) then begin
            if RequestJsonToken.IsObject then
                DebugJsonObject.Add('Request', RequestJsonToken.AsObject());
            if RequestJsonToken.IsArray then
                DebugJsonObject.Add('Request', RequestJsonToken.AsArray());
        end;

        // Process response data
        if ResponseJsonToken.ReadFrom(Response) then begin
            if ResponseJsonToken.IsObject then
                DebugJsonObject.Add('Response', ResponseJsonToken.AsObject());
            if ResponseJsonToken.IsArray then
                DebugJsonObject.Add('Response', ResponseJsonToken.AsArray());

        end;

        TempBlob.CreateOutStream(FileOutStr);
        DebugJsonObject.WriteTo(JsonContent);
        FileOutStr.WriteText(JsonContent);

        TempBlob.CreateInStream(FileInStr);
        Filename := RemoveInvalidFileNameChars(StrSubstNo('%1-%2.json', Format(CurrentDateTime, 0, '<Year4><Month><Day>-<Hours24><Minutes><Seconds><Thousands>'), ApiService));

        DownloadFromStream(FileInStr, '', '', '', Filename);
    end;

    local procedure RemoveInvalidFileNameChars(FileName: Text): Text
    var
        InvalidChars: Text;
        i: Integer;
    begin
        InvalidChars := '<>:"/\|?*='; // Standard invalid characters for filenames

        for i := 1 to StrLen(InvalidChars) do
            FileName := DelChr(FileName, '=', InvalidChars[i]);

        exit(FileName);
    end;
    /// <summary>
    /// Sends a request to the File API and returns the response as a JsonObject.
    /// </summary>
    /// <param name="JsonObject">returned variable of HttpResponse parsed as JsonObject </param>
    /// <param name="HttpContentContent">Http Content as application/json content type</param>
    /// <param name="ApiService">Parameter/Uri of the DC File API - e.g. ConvertTiffToPng</param>
    /// <param name="Method">Http Methods like GET, POST, PUT</param>
    /// <returns>True if the request have been send successfully and a json object has been retrieved from the response</returns>
    internal procedure SendHttpRequest(var JsonObject: JsonObject; HttpContentContent: Text; ApiService: Text[100]; Method: Text[10]): Boolean
    var
        HttpResponse: HttpResponseMessage;
        JsonResponse: JsonToken;
        ResponseInStr: InStream;
    begin
        if not SendHttpRequest(HttpResponse, HttpContentContent, ApiService, Method) then
            exit(false);

        HttpResponse.Content.ReadAs(ResponseInStr);

        if JsonResponse.ReadFrom(ResponseInStr) then begin
            if JsonResponse.IsObject then begin
                JsonObject := JsonResponse.AsObject();
                exit(true);
            end;
        end;
    end;

    /// <summary>
    /// Sends a request to the File API and returns the response as a JsonArray.
    /// </summary>
    /// <param name="JsonArray">returned variable of HttpResponse parsed as JsonArray </param>
    /// <param name="HttpContentContent">Http Content as application/json content type</param>
    /// <param name="ApiService">Parameter/Uri of the DC File API - e.g. ConvertTiffToPng</param>
    /// <param name="Method">Http Methods like GET, POST, PUT</param>
    /// <returns>True if the request have been send successfully and a json object has been retrieved from the response</returns>
    internal procedure SendHttpRequest(var JsonArray: JsonArray; HttpContentContent: Text; ApiService: Text[100]; Method: Text[10]): Boolean
    var
        HttpResponse: HttpResponseMessage;
        JsonResponse: JsonToken;
        ResponseInStr: InStream;
    begin
        if not SendHttpRequest(HttpResponse, HttpContentContent, ApiService, Method) then
            exit(false);

        HttpResponse.Content.ReadAs(ResponseInStr);

        if JsonResponse.ReadFrom(ResponseInStr) then begin
            if JsonResponse.IsArray then begin
                JsonArray := JsonResponse.AsArray();
                exit(true);
            end;
        end;
    end;

    /// <summary>
    /// Sends a request to the File API and returns the response as a JsonObject.
    /// </summary>
    /// <param name="HttpResponse">Returned HttpResponse</param>
    /// <param name="HttpContentContent">Http Content as application/json content type</param>
    /// <param name="ApiService">Parameter/Uri of the DC File API - e.g. ConvertTiffToPng</param>
    /// <param name="Method">Http Methods like GET, POST, PUT</param>
    /// <returns>True if the request have been send successfully and a json object has been retrieved from the response</returns>
    internal procedure SendHttpRequest(var HttpResponse: HttpResponseMessage; HttpContentContent: Text; ApiService: Text[100]; Method: Text[10]): Boolean
    var
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequestMessage: HttpRequestMessage;
        HttpClient: HttpClient;
        ResponseText: Text;

        TxtBuilder: TextBuilder;
        Filename: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        DCSetup.Get();
        DCSetup.TestField("API Url");

        HttpRequestMessage.SetRequestUri(DCSetup."API Url" + ApiService);
        HttpRequestMessage.Method := Method;
        //HttpRequestMessage.GetHeaders(RequestHeaders);
        //RequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        HttpContent.WriteFrom(HttpContentContent);
        HttpContent.GetHeaders(ContentHeaders);

        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        //HttpContent.GetHeaders(ContentHeaders);
        HttpRequestMessage.Content(HttpContent);

        // Read the response as a string and save request and response as file to the user if Debug is enabled 
        if HttpClient.Send(HttpRequestMessage, HttpResponse) then begin
            if DCSetup."Debug requests" then begin
                HttpResponse.Content.ReadAs(ResponseText);
                SaveHttpContentToFileRequest(HttpContentContent, ResponseText, ApiService);
            end;
            if not HttpResponse.IsSuccessStatusCode then
                Error('Error during DC File API Conversion:\API Service:%1\Status Code:%2\Reason:%3',
                    ApiService, HttpResponse.HttpStatusCode, HttpResponse.ReasonPhrase)
            else
                exit(true);
        end;
    end;

}
