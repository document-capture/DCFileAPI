
codeunit 63062 "DCADV File API JsonObjects"
{

    internal procedure CreateConvertFileJson(var JsonObject: JsonObject; DataBase64: Text; ColorMode: Enum "DCADV Color Mode"; Resolution: Integer): Boolean
    begin
        JsonObject.Add('Data', DataBase64);

        JsonObject.Add('ColorMode', ColorMode.AsInteger());

        JsonObject.Add('Resolution', Resolution);

        exit(true);
    end;

    internal procedure CreateDeleteFromFileJson(var JsonObject: JsonObject; DataBase64: Text; PagesToDeleteJsonArray: JsonArray): Boolean
    begin
        JsonObject.Add('Data', DataBase64);

        JsonObject.Add('pages', PagesToDeleteJsonArray);
        exit(true);
    end;

    internal procedure CreateRotateFileJson(var JsonObject: JsonObject; DataBase64: Text; PagesToDeleteJsonArray: JsonArray; rotationAngle: Integer): Boolean
    begin
        JsonObject.Add('data', DataBase64);
        JsonObject.Add('pages', PagesToDeleteJsonArray);
        JsonObject.Add('rotationAngle', rotationAngle);
        exit(true);
    end;

    internal procedure CreateTransformXmlFileJson(var JsonObject: JsonObject; StylesheetFileBase64: Text; XmlFileBase64: Text; StyleSheetName: Text): Boolean
    begin
        JsonObject.Add('stylesheetFile', StylesheetFileBase64);
        //TODO JsonObject.Add('stylesheetFileExtension', StylesheetFileExtension);
        JsonObject.Add('xmlFile', XmlFileBase64);
        JsonObject.Add('mainStyleSheetName', StyleSheetName);
        exit(true);
    end;

    internal procedure DeleteFromPDF_Request(var RequestObject: JsonObject; PagesToDeleteJsonArray: JsonArray; CDCDocument: Record "CDC Document"): Boolean
    var
        TempFile: Record "CDC Temp File";
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        CDCDocument.GetPdfFile(TempFile);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateDeleteFromFileJson(RequestObject, Convert.ToBase64(InStr), PagesToDeleteJsonArray));

    end;

    internal procedure DeleteFromTiff_Request(var RequestObject: JsonObject; PagesToDeleteJsonArray: JsonArray; CDCDocument: Record "CDC Document"): Boolean
    var
        TempFile: Record "CDC Temp File";
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        CDCDocument.GetTiffFile(TempFile);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateDeleteFromFileJson(RequestObject, Convert.ToBase64(InStr), PagesToDeleteJsonArray));
    end;

    internal procedure RotatePdfPages_Request(var RequestObject: JsonObject; PagesToDeleteJsonArray: JsonArray; RotationAngle: Integer; CDCDocument: Record "CDC Document"): Boolean
    var
        TempFile: Record "CDC Temp File";
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        CDCDocument.GetPdfFile(TempFile);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateRotateFileJson(RequestObject, Convert.ToBase64(InStr), PagesToDeleteJsonArray, RotationAngle));
    end;

    internal procedure RotateTiffPages_Request(var RequestObject: JsonObject; PagesToDeleteJsonArray: JsonArray; RotationAngle: Integer; CDCDocument: Record "CDC Document"): Boolean
    var
        TempFile: Record "CDC Temp File";
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        CDCDocument.GetTiffFile(TempFile);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateRotateFileJson(RequestObject, Convert.ToBase64(InStr), PagesToDeleteJsonArray, RotationAngle));
    end;

    /*

    internal procedure RotateTiff_Request(var RequestObject: JsonObject; TempFile: Record "CDC Temp File" temporary; DocumentCategory: Code[10]): Boolean
    var
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateConvertFileJson(RequestObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory)));
    end;
*/
    /// <summary>
    /// Creates JsonObject request to convert a Tiff document from a given CDC document record into a png file
    /// {
    ///   "data": "string",
    ///   "colorMode": 0,
    ///   "resolution": 0
    /// }
    /// </summary>
    /// <param name="RequestObject">Passed Jsonobject that holds the request content</param>
    /// <param name="CDCDocument">CDC Document that should be converted</param>
    /// <returns>True if the request have been build successfully</returns>
    internal procedure ConvertTiffToPng_Request(var RequestObject: JsonObject; CDCDocument: Record "CDC Document"): Boolean
    var
        TempFile: Record "CDC Temp File";
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        CDCDocument.GetTiffFile(TempFile);

        if not TempFile.Data.HasValue then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateConvertFileJson(RequestObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(CDCDocument."Document Category Code"), GetDocumentCategoryResolution(CDCDocument."Document Category Code")));
    end;


    /// <summary>
    /// Creates a JsonObject request to split a Tiff document
    /// {
    ///   "data": "string",
    ///   "colorMode": 0,
    ///   "resolution": 0
    /// }
    /// </summary>
    /// <param name="RequestObject">Passed Jsonobject that holds the request content</param>
    /// <param name="TempFile">Temp. file record that holds data of the file that should be splitted</param>
    /// <returns>True if the request have been build successfully</returns>
    internal procedure SplitTiff_Request(var RequestObject: JsonObject; TempFile: Record "CDC Temp File" temporary; DocumentCategory: Code[10]): Boolean
    var
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        if (not TempFile.Data.HasValue) then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateConvertFileJson(RequestObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory)));
    end;

    /// <summary>
    /// Creates JsonObject request to split a PDF document
    /// {
    ///   "data": "string",
    ///   "colorMode": 0,
    ///   "resolution": 0
    /// }
    /// </summary>
    /// <param name="RequestObject">Passed Jsonobject that holds the request content</param>
    /// <param name="TempFile">Temp. file record that holds data of the file that should be splitted</param>
    /// <returns>True if the request have been build successfully</returns>
    internal procedure SplitPDF_Request(var RequestObject: JsonObject; TempFile: Record "CDC Temp File" temporary; DocumentCategory: Code[10]): Boolean
    var

        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        if (not TempFile.Data.HasValue) then
            exit(false);

        TempFile.Data.CreateInStream(InStr);

        exit(CreateConvertFileJson(RequestObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory)));
    end;

    /// <summary>
    /// Creates JsonObject request to merge two Tiff documents
    /// {
    ///        "data": "string",
    ///        "colorMode": 0,
    ///        "resolution": 0
    ///}
    /// </summary>
    /// <param name="RequestObject">Passed Jsonobject that holds the request content</param>
    /// <param name="TempFile1">Temp. file record that holds data of first file</param>
    /// <param name="TempFile2">Temp. file record that holds data of second file</param>
    /// <returns>True if the request have been build successfully</returns>
    internal procedure MergeTiff_Request(var RequestObject: JsonObject; TempFile1: Record "CDC Temp File" temporary; TempFile2: Record "CDC Temp File" temporary; DocumentCategory: Code[10]): Boolean
    var

        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        RequestArray: JsonArray;
        TempJsonObject: JsonObject;
    begin
        // Check if the first file is empty and the second file is not empty and exit if so
        if (not TempFile1.Data.HasValue) or (not TempFile2.Data.HasValue) then
            exit(false);

        // Build the request object for the first file
        TempFile1.Data.CreateInStream(InStr);
        CreateConvertFileJson(TempJsonObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory));
        RequestArray.Add(TempJsonObject);
        clear(TempJsonObject);

        // Build the request object for the second file
        TempFile2.Data.CreateInStream(InStr);
        CreateConvertFileJson(TempJsonObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory));
        RequestArray.Add(TempJsonObject);

        exit(RequestObject.Add('convertFiles', RequestArray));
    end;

    /// <summary>
    /// Creates JsonObject request to merge two PDF documents
    /// {
    ///        "data": "string",
    ///        "colorMode": 0,
    ///        "resolution": 0
    /// }
    /// </summary>
    /// <param name="TempFile1">Temp. file record that holds data of first file</param>
    /// <param name="TempFile2">Temp. file record that holds data of second file</param>
    /// <returns>True if the request have been build successfully</returns>
    /// <returns></returns>
    internal procedure MergePDF_Request(var RequestObject: JsonObject; TempFile1: Record "CDC Temp File" temporary; TempFile2: Record "CDC Temp File" temporary; DocumentCategory: Code[10]): Boolean
    var
        Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        RequestArray: JsonArray;
        TempJsonObject: JsonObject;
    begin
        if (not TempFile1.Data.HasValue) or (not TempFile2.Data.HasValue) then
            exit(false);

        // Build the request object for the first file
        TempFile1.Data.CreateInStream(InStr);
        CreateConvertFileJson(TempJsonObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory));
        RequestArray.Add(TempJsonObject);

        clear(TempJsonObject);

        // Build the request object for the second file
        TempFile2.Data.CreateInStream(InStr);
        CreateConvertFileJson(TempJsonObject, Convert.ToBase64(InStr), GetDocumentCategoryColorMode(DocumentCategory), GetDocumentCategoryResolution(DocumentCategory));
        RequestArray.Add(TempJsonObject);

        exit(RequestObject.Add('convertFiles', RequestArray));
    end;

    internal procedure TransformXml_Request(var RequestObject: JsonObject; XmlFile: Record "CDC Temp File" temporary; StylesheetFile: Record "CDC Temp File" temporary; StylesheetName: Text): Boolean
    var
        Convert: Codeunit "Base64 Convert";
        XmlFileInStr: InStream;
        StylesheetFileInStr: InStream;
    begin
        if (not XmlFile.Data.HasValue) or (not StylesheetFile.Data.HasValue) then
            exit(false);

        XmlFile.Data.CreateInStream(XmlFileInStr);
        StylesheetFile.Data.CreateInStream(StylesheetFileInStr);

        exit(CreateTransformXmlFileJson(RequestObject, Convert.ToBase64(StylesheetFileInStr), Convert.ToBase64(XmlFileInStr), StylesheetName));
    end;

    local procedure GetDocumentCategoryResolution(DocCategory: Code[10]): Integer
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
    local procedure GetDocumentCategoryColorMode(Doccategory: Code[10]): enum "DCADV Color Mode"
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
}