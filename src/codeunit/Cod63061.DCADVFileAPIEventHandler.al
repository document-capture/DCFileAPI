codeunit 63061 "DCADV File API Event Handler"
{
    var
        DCADVFileInterface: Codeunit "DCADV Document File Interface";
    /// <summary>
    /// Event handler for the CDC Document File API. This event is triggered when a file is requested from the CDC Document File API.
    /// </summary>
    /// <param name="FileName">Filename of the requested file</param>
    /// <param name="Company">Company name</param>
    /// <param name="DocumentNo">The Document Capture document no.</param>
    /// <param name="FileType">File type: Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)"</param>
    /// <param name="TempFile">Temporary record that holds the file data</param>
    /// <param name="Result">Referenced var that is True if the file has been found and loaded into the TempFile record.</param>
    /// <param name="Handled">Referenced var that is True if further processing should be avoided.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnGetFile', '', false, false)]
    local procedure DocFileEvents_OnGetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    var
        Document: Record "CDC Document";
        DocumentPage: Record "CDC Document Page";
        APIMgt: Codeunit "DCADV File API Management";
        HttpMgt: Codeunit "DCADV File API Management";
        PageNo: Integer;
    begin
        case FileType of
            FileTypes::"Document Page":
                begin
                    if APIMgt.GetPageFromFileName(DocumentNo, FileName, PageNo) then
                        if DocumentPage.Get(DocumentNo, PageNo) then
                            if not DocumentPage.HasPngFile() then
                                if Document.Get(DocumentNo) then
                                    if HttpMgt.CreatePngFromTiffViaFileAPI(Document) then;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", OnSetFile, '', false, false)]
    local procedure DocFileEvents_OnSetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    var
        Document: Record "CDC Document";
        APIMgt: Codeunit "DCADV File API Management";
        fileinterface: Codeunit "CDC Document File Interface";
        TempDocumentId: Text;
    begin
        case FileType of
            FileTypes::"Xml (Original)":
                begin
                    if not DCSetup.Get() then
                        exit;

                    if DCSetup."API Url" = '' then
                        exit;

                    if not Document.Get(DocumentNo) then
                        exit;

                    // Check if the XML file is already available 
                    if Document.HasXmlFile() then
                        exit;

                    // Get document ID from the filename if it's not set yet on the document
                    if Document."Document ID" = '' then
                        Document."Document ID" := APIMgt.GetDocumentIdFromFilename(FileName);
                    // XML file is not available, so we need can create the Cleaned XML file via the File API
                    // 1. Set the XML file to the TempFile record
                    // 2. Remove the namespaces from the XML file
                    // 3. Create the html preview file

                    //if APIMgt.RemoveNamespaces(TempFile, TempFile, true) then begin
                    // 1. SetXml to FileService or BlobStorage
                    // 2. Create CleanXML and write to FileService or BlobStorage
                    // 3. Create Html and write to FileService or BlobStorage
                    //Document.Status = Document.
                    DCADVFileInterface.SetXmlFile(Document, TempFile);

                    Result := APIMgt.CreateCleanXMLFile(Document, TempFile);

                    //muss noch warten oder doch nicht?! DCADVFileInterface.SetHtmlFile(Document, TempFile);
                    Handled := Result;
                end;
        end;
    end;
    //DocFileEvents.OnHasFile(GetFileName(Document, XmlTrimmedFileType), CurrentCompany, Document."No.", XmlTrimmedFileType, Result, Handled);


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Capture Engine", OnBeforeAutoDelegateDocument, '', false, false)]
    local procedure CaptureEngine_OnBeforeAutoDelegateDocument(var Document: Record "CDC Document"; var IsHandled: Boolean)
    var
        APIMgt: Codeunit "DCADV File API Management";
    begin
        if Document."File Type" <> Document."File Type"::XML then
            exit;

        if not DCSetup.Get() then
            exit;

        if DCSetup."API Url" = '' then
            exit;

        if not Document.HasXmlFile() then
            exit;

        if Document."XML Document Type" = Document."XML Document Type"::" " then
            exit;

        if not Document.HasHtmlFile() then
            IsHandled := ApiMgt.CreateDocumentHtml(Document);
    end;

    /* [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", OnHasFile, '', false, false)]
     local procedure DocFileEvents_OnHasFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var Result: Boolean; var Handled: Boolean)
     var
         Document: Record "CDC Document";
         APIMgt: Codeunit "DCADV File API Management";
     begin
         case FileType of
             Filetypes::Html:
                 begin
                     if not DCSetup.Get() then
                         exit;

                     if DCSetup."API Url" = '' then
                         exit;

                     if not Document.Get(DocumentNo) then
                         exit;

                     if not Document.HasXmlFile() then
                         exit;

                     if Document."XML Document Type" = Document."XML Document Type"::" " then
                         exit;

                     Result := ApiMgt.CreateDocumentHtml(Document);
                     Handled := Result;
                 end;
         end;
     end;*/

    var
        DCSetup: Record "CDC Document Capture Setup";
        FileTypes: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";
}
