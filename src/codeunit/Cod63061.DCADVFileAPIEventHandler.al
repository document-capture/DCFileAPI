codeunit 63061 "DCADV File API Event Handler"
{
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

    var
        FileTypes: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";
}
