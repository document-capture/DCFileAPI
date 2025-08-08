codeunit 63069 "DCADV Api Management"
{
    var
        Convert: Codeunit "Base64 Convert";
        RequestBody: JsonObject;
        ResponseObject: JsonObject;
        InputFiles: JsonArray;
        OutputFiles: JsonArray;
        ProcesingTime: Integer;

    // --- Pflichtfeld inputFiles ---
    internal procedure AddInputFile(Base64EncodedFile: Text)
    begin
        if StrLen(Base64EncodedFile) > 0 then
            InputFiles.Add(Base64EncodedFile);
    end;

    internal procedure AddInputFile(var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        InStr: InStream;
        Base64EncodedFile: Text;
    begin
        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);
        InputFiles.Add(Convert.ToBase64(InStr));
        exit(true);
    end;

    // --- Zusätzliche Felder ---
    internal procedure AddText(JsonKey: Text; TextValue: Text)
    begin
        RequestBody.Add(JsonKey, TextValue);
    end;

    internal procedure AddDecimal(JsonKey: Text; NumberValue: Decimal)
    begin
        RequestBody.Add(JsonKey, NumberValue);
    end;

    internal procedure AddInteger(JsonKey: Text; NumberValue: Integer)
    begin
        RequestBody.Add(JsonKey, NumberValue);
    end;

    internal procedure AddTextArray(JsonKey: Text; Values: List of [Text])
    var
        Arr: JsonArray;
        Val: Text;
    begin
        foreach Val in Values do
            Arr.Add(Val);
        RequestBody.Add(JsonKey, Arr);
    end;

    internal procedure AddIntArray(JsonKey: Text; Values: List of [Integer])
    var
        Arr: JsonArray;
        Val: Integer;
    begin
        foreach Val in Values do
            Arr.Add(Val);
        RequestBody.Add(JsonKey, Arr);
    end;

    // --- Body erzeugen ---
    internal procedure GetRequestJsonBody() Body: JsonObject
    begin
        Body := RequestBody;
        Body.Add('inputFiles', InputFiles); // immer anhängen
        exit(Body);
    end;

    internal procedure GetRequestJsonBodyAsText() Body: Text
    begin
        RequestBody.Add('inputFiles', InputFiles); // immer anhängen
        RequestBody.WriteTo(Body);
    end;

    // --- Reset ---
    internal procedure ClearAll()
    begin
        Clear(RequestBody);
        Clear(InputFiles);
    end;

    // --- Beispiel für die Verwendung ---
    internal procedure Send(UriEndpoint: text; Method: Text): Boolean
    var
        HttpMgt: Codeunit "DCADV Http Management";

        JsonTempToken: JsonToken;
        Base64PDF: Text;
    begin
        if not HttpMgt.SendHttpRequest(ResponseObject, GetRequestJsonBodyAsText(), UriEndpoint, Method) then
            exit(false);

        if ResponseObject.Get('processingTimeMs', JsonTempToken) then begin
            // Save the processing time
            ProcesingTime := JsonTempToken.AsValue().AsInteger();

            // Get the base64 encoded file array from the response
            if ResponseObject.Get('outputFiles', JsonTempToken) then
                if JsonTempToken.IsArray then
                    OutputFiles := JsonTempToken.AsArray();
        end;

        exit(ProcesingTime > 0);
    end;

    internal procedure GetProcessingTime(): Integer
    begin
        exit(ProcesingTime);
    end;

    internal procedure GetOutputFile(FileNumber: Integer; Base64EncodedText: Text): Boolean
    var
        OutputFile: JsonToken;
    begin
        if OutputFiles.Get(FileNumber, OutputFile) then begin
            if OutputFile.IsValue then
                Base64EncodedText := OutputFile.AsValue().AsText();

            exit(StrLen(Base64EncodedText) > 0);
        end;
    end;

    internal procedure GetOutputFile(FileNumber: Integer; var TempFile: Record "CDC Temp File" temporary): Boolean
    var
        OutputFile: JsonToken;
        Base64EncodedText: Text;
        OutStr: OutStream;
    begin
        if OutputFiles.Get(FileNumber, OutputFile) then begin
            if OutputFile.IsValue then begin
                Base64EncodedText := OutputFile.AsValue().AsText();
                if StrLen(Base64EncodedText) = 0 then
                    exit(false);
                TempFile.Data.CreateOutStream(OutStr);
                Convert.FromBase64(Base64EncodedText, OutStr);
                exit(TempFile.Data.Length > 0);
            end;
        end;
    end;

    internal procedure GetOutputFilesQty(): Integer
    begin
        exit(OutputFiles.Count);
    end;
}
