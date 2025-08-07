codeunit 63064 "DCADV Doc. Modification Mgt."
{
    var
        HideError: Boolean;
        HideWindow: Boolean;
        Window: Dialog;
        RotatingPagesProgressWindowLbl: Label 'Rotating pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
        RotatingPagesProgressCounterLbl: Label '%1 of %2';
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        HttpMgt: codeunit "DCADV Http Management";
        TempFileStorage: Codeunit "CDC Temp File Storage";


    internal procedure DeletePages(var SelectedPages: Record "CDC Temp. Document Page"; var PagesToDelete: Record "CDC Temp. Document Page"): Boolean
    var
        Document: Record "CDC Document";
        PagesToDeleteList: List of [Integer];
        CurrDocumentNo: Code[20];
        TotalPages: Integer;
        PageNo: Integer;
        DeleteSelectedPagesQst: Label 'Do you want to delete the selected %1 pages?';
        DeleteSelectedPageQst: Label 'Do you want to delete the selected page?';
        DeletingPagesProgress: Label 'Deleting pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
    begin
        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            IF NOT SelectedPages.FINDSET THEN
                EXIT(FALSE);

            IF SelectedPages.COUNT > 1 THEN BEGIN
                IF NOT CONFIRM(DeleteSelectedPagesQst, false, SelectedPages.Count) THEN
                    EXIT(FALSE);
            END ELSE BEGIN
                IF NOT CONFIRM(DeleteSelectedPageQst) THEN
                    EXIT(FALSE);
            END;

            Window.OPEN(DeletingPagesProgress);
            TotalPages := SelectedPages.COUNT;
        END;

        SelectedPages.ASCENDING(FALSE);
        IF SelectedPages.FINDFIRST THEN
            REPEAT
                IF GUIALLOWED AND NOT HideWindow THEN BEGIN
                    PageNo += 1;
                    Window.UPDATE(1, STRSUBSTNO(RotatingPagesProgressCounterLbl, PageNo, TotalPages));
                    Window.UPDATE(2, (PageNo / TotalPages * 10000) DIV 1);
                END;

                if (SelectedPages."Document No." <> CurrDocumentNo) then begin
                    // Delete the pages of the previous document and reset the array
                    if (CurrDocumentNo <> '') then begin
                        DeletePagesFromDoc(PagesToDeleteList, CurrDocumentNo);
                        Clear(PagesToDeleteList);
                    end;

                    // Get the current document
                    CurrDocumentNo := SelectedPages."Document No.";
                end;

                PagesToDeleteList.Add(SelectedPages.Page);

                PagesToDelete.SETRANGE("Document No.", SelectedPages."Document No.");
                IF Document."No." <> SelectedPages."Document No." THEN BEGIN
                    IF Document.GET(SelectedPages."Document No.") THEN BEGIN
                        Document.Version += 1;
                        Document.MODIFY;
                    END;
                END;

                PagesToDelete := SelectedPages;
                PagesToDelete.INSERT;
            UNTIL SelectedPages.NEXT = 0;

        DeletePagesFromDoc(PagesToDeleteList, CurrDocumentNo);

        PagesToDelete.SETRANGE("Document No.");

        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;

        SelectedPages.ASCENDING(TRUE);

        EXIT(TRUE);
    end;

    local procedure DeletePagesFromDoc(PagesToDeleteList: List of [Integer]; DocumentNo: Code[20]): Boolean
    var
        Document: Record "CDC Document";
        DocPage: Record "CDC Document Page";
        TempNewPdfFile: Record "CDC Temp File" temporary;
        TempNewTiffFile: Record "CDC Temp File" temporary;
        PagesToDeleteJsonArray: JsonArray;
        intValue: Integer;
    begin
        Document.GET(DocumentNo);
        Document.CALCFIELDS("No. of Pages");
        if Document."No. of Pages" < 2 then
            Document.DELETE(TRUE)
        else begin

            InvalidateDocumentAIData_Cloned(Document);

            PagesToDeleteList.Reverse();
            foreach intValue in PagesToDeleteList do begin
                PagesToDeleteJsonArray.Add(IntValue);

                //#TODO Document.InvalidateAIData;

                DocPage.GET(DocumentNo, intValue);
                DocPage.DELETE(TRUE);

                DocPage.SETRANGE("Document No.", DocumentNo);
                DocPage.SETFILTER("Page No.", '>%1', intValue);
                IF DocPage.FINDSET THEN
                    REPEAT
                        MovePage(DocPage."Document No.", DocPage."Page No.", DocPage."Document No.", DocPage."Page No." - 1);
                    UNTIL DocPage.NEXT = 0;
            end;

            if not DeletePagesFromPdf(PagesToDeleteJsonArray, Document, TempNewPdfFile) then
                error('Error deleting pages from PDF file.');

            if not DeletePagesFromTiff(PagesToDeleteJsonArray, Document, TempNewTiffFile) then
                error('Error deleting pages from Tiff file.');

            if not Document.SetPdfFile(TempNewPdfFile) then
                error('Error setting new PDF file for document %1.', Document."No.");

            if not Document.SetTiffFile(TempNewTiffFile) then
                Error('Error setting new Tiff file for document %1.', Document."No.");

            Commit();
            exit(true);
        end;
    end;

    internal procedure DeletePagesFromPdf(PagesToDeleteJsonArray: JsonArray; Document: Record "CDC Document"; var TempNewPdfFile: Record "CDC Temp File" temporary): Boolean
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonReturnObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64PDF: Text;
        Convert: Codeunit "Base64 Convert";
        PDFOutStr: OutStream;
    begin
        //Page.GET(DocNo, DeletePageNo);

        if not DCADVFileAPIJsonOBj.DeleteFromPDF_Request(jsonObject, PagesToDeleteJsonArray, Document) then
            error('Error in creating json object for DeleteFromPDF_Request');

        // Create json body from request object
        jsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonReturnObject, JsonBody, 'DeleteFromPDF', 'Post') then begin
            if JsonReturnObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64PDF := JsonPageDataToken.AsValue().AsText();

                    if StrLen(Base64PDF) = 0 then
                        exit(false);

                    TempNewPdfFile.Data.CreateOutStream(PDFOutStr);
                    Convert.FromBase64(Base64PDF, PDFOutStr);
                    exit(true);
                end;
            end;
        end;
    end;

    internal procedure DeletePagesFromTiff(PagesToDeleteJsonArray: JsonArray; Document: Record "CDC Document"; var TempNewTiffFile: Record "CDC Temp File" temporary): Boolean
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonReturnObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Tiff: Text;
        Convert: Codeunit "Base64 Convert";
        TiffOutStr: OutStream;
    begin
        //Page.GET(DocNo, DeletePageNo);

        if not DCADVFileAPIJsonOBj.DeleteFromTiff_Request(jsonObject, PagesToDeleteJsonArray, Document) then
            error('Error in creating json object for DeleteFromPDF_Request');

        // Create json body from request object
        jsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonReturnObject, JsonBody, 'DeleteFromTiff', 'Post') then begin

            if JsonReturnObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64Tiff := JsonPageDataToken.AsValue().AsText();

                    if StrLen(Base64Tiff) = 0 then
                        exit(false);

                    TempNewTiffFile.Data.CreateOutStream(TiffOutStr);
                    Convert.FromBase64(Base64Tiff, TiffOutStr);
                    exit(true);
                end;
            end;
        end;
    end;

    /// <summary>
    /// Central procedure to rotate pages of all document related files (Pdf, Tiff, Png). 
    /// </summary>
    /// <param name="PagesToRotate">Temp. Page record that holds the selected pages including document no.</param>
    /// <param name="RotationAngle">Angle the pages have to be rotated</param>
    internal procedure RotatePages(var PagesToRotate: Record "CDC Temp. Document Page"; RotationAngle: Integer)
    var
        Document: Record "CDC Document";
        PagesToRotateList: JsonArray;
        TotalPages: Integer;
        PageNo: Integer;
    begin
        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            Window.OPEN(RotatingPagesProgressWindowLbl);
            TotalPages := PagesToRotate.COUNT;
        END;
        PagesToRotate.FINDSET;
        REPEAT
            IF GUIALLOWED AND NOT HideWindow THEN BEGIN
                PageNo += 1;
                Window.UPDATE(1, STRSUBSTNO(RotatingPagesProgressCounterLbl, PageNo, TotalPages));
                Window.UPDATE(2, (PageNo / TotalPages * 10000) DIV 1);
            END;

            if Document."No." <> PagesToRotate."Document No." then begin
                if Document."No." <> '' then begin
                    RotateDocumentPages(PagesToRotateList, RotationAngle, Document);
                    Clear(PagesToRotateList);
                end;
                Document.GET(PagesToRotate."Document No.");
            END;
            PagesToRotateList.Add(PagesToRotate.Page);
        UNTIL PagesToRotate.NEXT = 0;

        RotateDocumentPages(PagesToRotateList, RotationAngle, Document);

        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;

        //RotatePage(PagesToRotate."Document No.", PagesToRotate.Page);
        // TODO Clarify secure archive management
        //IF SecureArchiveManagement.SecureArchiveEnabled THEN
        //    SecureArchiveManagement.CalculateAndAssignFileHash(Document);
    end;

    local procedure RotateDocumentPages(PagesToRotateJsonArray: JsonArray; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        FileApiMgt: Codeunit "DCADV File API Management";
        NewPdfTempFile: Record "CDC Temp File" temporary;
        NewTiffTempFile: Record "CDC Temp File" temporary;
        PageNo: Integer;
    begin
        Document.Version += 1;
        Document.MODIFY;


        if not RotatePdfPages(NewPdfTempFile, PagesToRotateJsonArray, RotationAngle, Document) then
            error('Error rotating pages in Pdf file.');

        if not RotateTiffPages(NewTiffTempFile, PagesToRotateJsonArray, RotationAngle, Document) then
            error('Error rotating pages in Tiff file.');

        if not Document.SetPdfFile(NewPdfTempFile) then
            error('Error setting new PDF file for document %1.', Document."No.");

        if not Document.SetTiffFile(NewTiffTempFile) then
            Error('Error setting new Tiff file for document %1.', Document."No.");

        // Convert new Tiff file to Png if necessary
        FileApiMgt.CreatePngFromTiffViaFileAPI(Document);

        Commit();

        InvalidateDocumentAIData_Cloned(Document);

        exit(true);
    end;

    local procedure RotatePdfPages(var NewPdfTempFile: Record "CDC Temp File" temporary; PagesToRotateJsonArray: JsonArray; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonReturnObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64PDF: Text;
        Convert: Codeunit "Base64 Convert";
        PDFOutStr: OutStream;
    begin
        //Page.GET(DocNo, DeletePageNo);

        if not DCADVFileAPIJsonOBj.RotatePdfPages_Request(JsonObject, PagesToRotateJsonArray, RotationAngle, Document) then
            error('Error in creating json object for RotatePdfPages_Request');

        // Create json body from request object
        jsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonReturnObject, JsonBody, 'RotatePdfPages', 'Post') then begin
            if JsonReturnObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64PDF := JsonPageDataToken.AsValue().AsText();

                    if StrLen(Base64PDF) = 0 then
                        exit(false);

                    NewPdfTempFile.Data.CreateOutStream(PDFOutStr);
                    Convert.FromBase64(Base64PDF, PDFOutStr);
                    exit(true);
                end;
            end;
        end;
    end;

    local procedure RotateTiffPages(var NewTiffTempFile: Record "CDC Temp File" temporary; PagesToRotateJsonArray: JsonArray; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonReturnObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Tiff: Text;
        Convert: Codeunit "Base64 Convert";
        TiffOutStr: OutStream;
    begin
        //Page.GET(DocNo, DeletePageNo);

        if not DCADVFileAPIJsonOBj.RotateTiffPages_Request(JsonObject, PagesToRotateJsonArray, RotationAngle, Document) then
            error('Error in creating json object for RotatePdfPages_Request');

        // Create json body from request object
        jsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonReturnObject, JsonBody, 'RotateTiffPages', 'Post') then begin
            if JsonReturnObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64Tiff := JsonPageDataToken.AsValue().AsText();

                    if StrLen(Base64Tiff) = 0 then
                        exit(false);

                    NewTiffTempFile.Data.CreateOutStream(TiffOutStr);
                    Convert.FromBase64(Base64Tiff, TiffOutStr);
                    exit(true);
                end;
            end;
        end;
    end;

    /*internal procedure RotatePage(DocNo: Code[20]; PageNo: Integer)
    var
        Document: Record "CDC Document";
        "Page": Record "CDC Document Page";
        TempPdfFile: Record "CDC Temp File" temporary;
        TempTiffFile: Record "CDC Temp File" temporary;
        TempPngFile: Record "CDC Temp File" temporary;
    begin
        Document.GET(DocNo);
        //Page.GET(DocNo, PageNo);
        Document.GetPngFile(TempPngFile, PageNo);
        Document.GetTiffFile(TempTiffFile);
        Document.GetPdfFile(TempPdfFile);
        InvalidateDocumentAIData_Cloned(Document);
        ;

        //TODO 
        RotateTiffPage(TempTiffFile, PageNo, Document."Document Category Code");
        //TODO RoatePdfPage;
        //TODO RoatePngPage;

        Document.SetTiffFile(TempTiffFile);
        Document.SetPdfFile(TempPdfFile);

        //TODO TempFileStorage.Clear;

        COMMIT;
    end;
*/
    /* local procedure RotateTiffPages(var TempFile: Record "CDC Temp File" temporary; RotateAtPageNo: Integer; DocCategoryCode: Code[10]) Success: Boolean
     var
         JsonBody: Text;
         jsonObject: JsonObject;
         DCADVFileAPIJsonObj: Codeunit "DCADV File API JsonObjects";
         i: Integer;
         JsonToken: JsonToken;
         JsonPngObject: JsonObject;
         JsonPageDataToken: JsonToken;
         Base64Tiff: Text;
         Convert: Codeunit "Base64 Convert";
         PNGOutStr: OutStream;

         HttpMgt: codeunit "DCADV Http Management";
         JsonArray: JsonArray;
     begin
         // Create json request object for conversion
         if not DCADVFileAPIJsonObj.RotateTiff_Request(jsonObject, TempFile, DocCategoryCode) then
             error('Error in creating RotateTiff_Request');

         // Create json body from request object
         jsonObject.WriteTo(jsonBody);

         // Build and send the request and get the response as json object        
         if HttpMgt.SendHttpRequest(JsonArray, JsonBody, 'RotateFromTiff?PageNo=' + format(RotateAtPageNo), 'Post') then begin
             for i := 1 to JsonArray.Count() do begin
                 JsonArray.Get(i - 1, JsonPngToken);
                 if JsonPngToken.IsObject then begin
                     JsonPngObject := JsonPngToken.AsObject();
                     if JsonPngObject.Get('data', JsonPageDataToken) then begin
                         if not JsonPageDataToken.AsValue().IsNull then begin
                             Base64Tiff := JsonPageDataToken.AsValue().AsText();

                             if i = 1 then
                                 if not TempNewFile1.Data.HasValue then begin
                                     TempNewFile1.Data.CreateOutStream(PNGOutStr);
                                     Convert.FromBase64(Base64Tiff, PNGOutStr);
                                 end;

                         end;
                     end;
                 end;
             end;
         end;
     end;
 */
    internal procedure TiffSplit(TempDocumentPage: record "CDC Temp. Document Page"; var TempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer; HideError: Boolean) Success: Boolean
    var

        JsonBody: Text;
        jsonObject: JsonObject;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        i: Integer;
        JsonPngToken: JsonToken;
        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64EncodedDoc: Text;
        Convert: Codeunit "Base64 Convert";
        PNGOutStr: OutStream;

        HttpMgt: codeunit "DCADV Http Management";
        JsonArray: JsonArray;
    begin
        // Create json request object for conversion
        if not DCADVFileAPIJsonOBj.SplitTiff_Request(jsonObject, TempFile, TempDocumentPage."Document Category Code") then
            error('Error in SplitTiff_Request');

        // Create json body from request object
        jsonObject.WriteTo(jsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonArray, JsonBody, 'SplitTiff?PageNo=' + format(SplitAtPageNo), 'Post') then begin
            for i := 1 to JsonArray.Count() do begin
                JsonArray.Get(i - 1, JsonPngToken);
                if JsonPngToken.IsObject then begin
                    JsonPngObject := JsonPngToken.AsObject();
                    if JsonPngObject.Get('data', JsonPageDataToken) then begin
                        if not JsonPageDataToken.AsValue().IsNull then begin
                            Base64EncodedDoc := JsonPageDataToken.AsValue().AsText();

                            if i = 1 then
                                if not TempNewFile1.Data.HasValue then begin
                                    TempNewFile1.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64EncodedDoc, PNGOutStr);
                                end;
                            if i = 2 then
                                if not TempNewFile2.Data.HasValue then begin
                                    TempNewFile2.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64EncodedDoc, PNGOutStr);
                                end;
                        end;
                    end;
                end;
            end;
        end;
    end;

    internal procedure PDFSplit(TempDocumentPage: Record "CDC Temp. Document Page"; var TempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer; HideError: Boolean) Succes: Boolean
    var
        JsonBody: Text;
        jsonObject: JsonObject;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        HttpMgt: Codeunit "DCADV Http Management";
        JsonArrayValue: JsonArray;
        i: Integer;
        JsonPngToken: JsonToken;
        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64EncodedDoc: Text;
        Convert: Codeunit "Base64 Convert";
        PNGOutStr: OutStream;
    begin
        // Create json request object for conversion
        if not DCADVFileAPIJsonOBj.SplitPDF_Request(jsonObject, TempFile, TempDocumentPage."Document Category Code") then
            Error('Error in SplitPDF_Request');

        // Create json body from request object
        jsonObject.WriteTo(jsonBody);

        // Build and send the request and get the response as json object
        if HttpMgt.SendHttpRequest(JsonArrayValue, JsonBody, 'SplitPDF?PageNo=' + format(SplitAtPageNo), 'Post') then begin
            for i := 1 to JsonarrayValue.Count() do begin
                JsonarrayValue.Get(i - 1, JsonPngToken);
                if JsonPngToken.IsObject then begin
                    JsonPngObject := JsonPngToken.AsObject();
                    if JsonPngObject.Get('data', JsonPageDataToken) then begin  //TODO Claus => missing serizalization in C# Code
                        if not JsonPageDataToken.AsValue().IsNull then begin
                            Base64EncodedDoc := JsonPageDataToken.AsValue().AsText();
                            if StrLen(Base64EncodedDoc) = 0 then
                                error('The returned document (Part %1) is empty. Please check the source document and contact support if the issue persists.', i);

                            if i = 1 then
                                if not TempNewFile1.Data.HasValue then begin
                                    TempNewFile1.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64EncodedDoc, PNGOutStr);
                                end;
                            if i = 2 then
                                if not TempNewFile2.Data.HasValue then begin
                                    TempNewFile2.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64EncodedDoc, PNGOutStr);
                                end;
                        end;
                    end;
                end;
            end;
        end;
    end;

    procedure TiffCombine(TempDocumentPage: Record "CDC Temp. Document Page"; var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
    var

        JsonBody: Text;
        jsonObject: JsonObject;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";

        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Tiff: Text;
        Convert: Codeunit "Base64 Convert";
        PNGOutStr: OutStream;

        HttpMgt: Codeunit "DCADV Http Management";
    begin
        // Create json request object for conversion
        if not DCADVFileAPIJsonOBj.MergeTiff_Request(jsonObject, TempFile1, TempFile2, TempDocumentPage."Document Category Code") then
            error('Error in MergeTiff_Request');

        // Create json body from request object
        jsonObject.WriteTo(jsonBody);

        // Build and send the request and get the response as json object
        if HttpMgt.SendHttpRequest(JsonPngObject, JsonBody, 'MergeTiff', 'Post') then begin
            if JsonPngObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64Tiff := JsonPageDataToken.AsValue().AsText();

                    if not TempNewFile.Data.HasValue then begin
                        TempNewFile.Data.CreateOutStream(PNGOutStr);
                        Convert.FromBase64(Base64Tiff, PNGOutStr);
                    end;

                end;
            end;
        end;
    end;

    procedure PDFCombine(TempDocumentPage: Record "CDC Temp. Document Page"; var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
    var
        JsonBody: Text;
        jsonObject: JsonObject;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";

        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Tiff: Text;
        Convert: Codeunit "Base64 Convert";
        PNGOutStr: OutStream;

        HttpMgt: Codeunit "DCADV Http Management";
    begin
        // Create json request object for conversion
        if not DCADVFileAPIJsonOBj.MergePDF_Request(jsonObject, TempFile1, TempFile2, TempDocumentPage."Document Category Code") then
            Error('Error in MergePDF_Request');

        // Create json body from request object
        jsonObject.WriteTo(jsonBody);

        // Build and send the request and get the response as json object
        if HttpMgt.SendHttpRequest(JsonPngObject, JsonBody, 'MergePDF', 'Post') then begin
            if JsonPngObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64Tiff := JsonPageDataToken.AsValue().AsText();

                    if not TempNewFile.Data.HasValue then begin
                        TempNewFile.Data.CreateOutStream(PNGOutStr);
                        Convert.FromBase64(Base64Tiff, PNGOutStr);
                    end;

                end;
            end;
        end;
    end;

    internal procedure MovePage(FromDocNo: Code[20]; FromPageNo: Integer; ToDocNo: Code[20]; ToPageNo: Integer)
    var
        DocPage: Record "CDC Document Page";
        NewDocPage: Record "CDC Document Page";
        DocWord: Record "CDC Document Word";
        NewDocWord: Record "CDC Document Word";
        TempFile: Record "CDC Temp File";
    begin
        DocPage.GET(FromDocNo, FromPageNo);

        NewDocPage := DocPage;
        NewDocPage."Document No." := ToDocNo;
        NewDocPage."Page No." := ToPageNo;
        IF DocPage.GetPngFile(TempFile) THEN
            NewDocPage.SetPngFile(TempFile);
        NewDocPage.INSERT;

        DocWord.SETRANGE("Document No.", FromDocNo);
        DocWord.SETRANGE("Page No.", DocPage."Page No.");
        IF DocWord.FINDSET THEN
            REPEAT
                IF DocWord.Data.HASVALUE THEN
                    DocWord.CALCFIELDS(Data);
                NewDocWord := DocWord;
                NewDocWord."Document No." := ToDocNo;
                NewDocWord."Page No." := ToPageNo;
                NewDocWord.INSERT;
            UNTIL DocWord.NEXT = 0;

        DocPage.DELETE(TRUE);
    end;

    internal procedure InvalidateDocumentAIData_Cloned(var Document: Record "CDC Document")
    var
        AIField: Record "CDC AI Field";
        AIFieldValuePart: Record "CDC AI Field Value Part";
        AIKeyValuePair: Record "CDC AI Key/Value Pair";
        AIDocumentLine: Record "CDC AI Document Line";
    begin
        IF Document."No." = '' THEN
            EXIT;

        AIField.SETRANGE("Document No.", Document."No.");
        AIKeyValuePair.SETRANGE("Document No.", Document."No.");
        AIDocumentLine.SETRANGE("Document No.", Document."No.");
        AIFieldValuePart.SETRANGE("Document No.", Document."No.");

        IF AIField.ISEMPTY THEN
            EXIT;

        AIField.DELETEALL(TRUE);
        AIKeyValuePair.DELETEALL(TRUE);
        AIDocumentLine.DELETEALL(TRUE);
        AIFieldValuePart.DELETEALL(TRUE);

        Document."OCR Reprocessing Needed" := TRUE;
        Document.MODIFY;
    end;
}
