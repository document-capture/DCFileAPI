codeunit 63064 "DCADV Doc. Modification Mgt."
{
    var
        HideError: Boolean;
        HideWindow: Boolean;
        Window: Dialog;
        Text007: Label '%1 of %2';
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        HttpMgt: codeunit "DCADV Http Management";


    internal procedure DeletePages(var SelectedPages: Record "CDC Temp. Document Page"; var PagesToDelete: Record "CDC Temp. Document Page"): Boolean
    var
        Document: Record "CDC Document";
        DocPage: Record "CDC Document Page";
        TotalPages: Integer;
        PageNo: Integer;
        DeletePageNo: Integer;
        DeleteSelectedPagesQst: Label 'Do you want to delete the selected pages?';
        DeleteSelectedPageQst: Label 'Do you want to delete the selected page?';
        DeletingPagesProgress: Label 'Deleting pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
    begin
        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            IF NOT SelectedPages.FINDSET THEN
                EXIT(FALSE);

            IF SelectedPages.COUNT > 1 THEN BEGIN
                IF NOT CONFIRM(DeleteSelectedPagesQst) THEN
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
                    Window.UPDATE(1, STRSUBSTNO(Text007, PageNo, TotalPages));
                    Window.UPDATE(2, (PageNo / TotalPages * 10000) DIV 1);
                END;

                PagesToDelete.SETRANGE("Document No.", SelectedPages."Document No.");
                DeletePage(SelectedPages."Document No.", SelectedPages.Page);

                IF Document."No." <> SelectedPages."Document No." THEN BEGIN
                    IF Document.GET(SelectedPages."Document No.") THEN BEGIN
                        Document.Version += 1;
                        Document.MODIFY;
                    END;
                END;

                PagesToDelete := SelectedPages;
                PagesToDelete.INSERT;
            UNTIL SelectedPages.NEXT = 0;

        PagesToDelete.SETRANGE("Document No.");

        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;

        SelectedPages.ASCENDING(TRUE);
        EXIT(TRUE);
    end;

    internal procedure DeletePage(DocNo: Code[20]; DeletePageNo: Integer): Boolean
    var
        Document: Record "CDC Document";
        "Page": Record "CDC Document Page";
        JsonBody: Text;
        JsonObject: JsonObject;
        JsonReturnObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64PDF: Text;
        Convert: Codeunit "Base64 Convert";
        PDFOutStr: OutStream;
        TempTiffFile: Record "CDC Temp File" temporary;
        TempPdfFile: Record "CDC Temp File" temporary;
    begin
        Document.GET(DocNo);

        Page.GET(DocNo, DeletePageNo);

        if not DCADVFileAPIJsonOBj.DeleteFromPDF_Request(jsonObject, Document) then
            error('Error in creating json object for DeleteFromPDF_Request');

        // Create json body from request object
        jsonObject.WriteTo(JsonBody);

        // Build and send the request and get the response as json object        
        if HttpMgt.SendHttpRequest(JsonReturnObject, JsonBody, 'DeleteFromPDF?PageNo=' + format(DeletePageNo), 'Post') then begin

            if JsonReturnObject.Get('Data', JsonPageDataToken) then begin
                if not JsonPageDataToken.AsValue().IsNull then begin
                    Base64PDF := JsonPageDataToken.AsValue().AsText();

                    if StrLen(Base64PDF) = 0 then
                        exit(false);

                    TempPdfFile.Data.CreateOutStream(PDFOutStr);
                    //#todo wie bekomme ich die Datei zurück ins Dokument?
                    Convert.FromBase64(Base64PDF, PDFOutStr);
                end;

            end;
        end;
    end;


    // internal procedure RotatePages(var PagesToRotate: Record "CDC Temp. Document Page")
    // var
    //     Document: Record "CDC Document";
    //     TotalPages: Integer;
    //     PageNo: Integer;
    // begin
    //     PagesToRotate.FINDSET;
    //     REPEAT
    //         IF GUIALLOWED AND NOT HideWindow THEN BEGIN
    //             PageNo += 1;
    //             Window.UPDATE(1, STRSUBSTNO(Text007, PageNo, TotalPages));
    //             Window.UPDATE(2, (PageNo / TotalPages * 10000) DIV 1);
    //         END;

    //         RotatePage(PagesToRotate."Document No.", PagesToRotate.Page);

    //         IF Document."No." <> PagesToRotate."Document No." THEN BEGIN
    //             Document.GET(PagesToRotate."Document No.");
    //             Document.Version += 1;
    //             Document.MODIFY;
    //         END;
    //     UNTIL PagesToRotate.NEXT = 0;

    //     // TODO Clarify secure archive management
    //     //IF SecureArchiveManagement.SecureArchiveEnabled THEN
    //     //    SecureArchiveManagement.CalculateAndAssignFileHash(Document);

    //     IF GUIALLOWED AND NOT HideWindow THEN
    //         Window.CLOSE;
    // end;

    // internal procedure RotatePage(DocNo: Code[20]; PageNo: Integer)
    // var
    //     Document: Record "CDC Document";
    //     "Page": Record "CDC Document Page";
    //     TempTiffFile: Record "CDC Temp File" temporary;
    //     TempPdfFile: Record "CDC Temp File" temporary;
    // begin
    //     Document.GET(DocNo);

    //     Page.GET(DocNo, PageNo);
    //     //TODO Page.Rotate(90);

    //     Document.GetTiffFile(TempTiffFile);
    //     Document.GetPdfFile(TempPdfFile);
    //     //TODO Document.InvalidateAIData;

    //     //TODO 
    //     TIFFRotatePage(TempTiffFile, PageNo, Document."Document Category Code", HideError);
    //     //TODO PDFMgt.RotatePage(TempPdfFile, PageNo, 90, HideError);

    //     // SetxxxFile is not needed when running classic since rotate is performed directly on archive file
    //     IF TempTiffFile."File Location" <> TempTiffFile."File Location"::"Client File System" THEN
    //         Document.SetTiffFile(TempTiffFile);

    //     // SetxxxFile is not needed when running classic since rotate is performed directly on archive file
    //     IF TempPdfFile."File Location" <> TempPdfFile."File Location"::"Client File System" THEN
    //         Document.SetPdfFile(TempPdfFile);

    //     //TODO TempFileStorage.Clear;

    //     COMMIT;
    // end;

    // local TIFFRotatePage(var TempFile: Record "CDC Temp File" temporary; RotateAtPageNo: Integer; DocCategoryCode: Code[10]; HideError: Boolean) Success: Boolean
    // var

    //     JsonBody: Text;
    //     jsonObject: JsonObject;
    //     DCADVFileAPIJsonObj: Codeunit "DCADV File API JsonObjects";
    //     i: Integer;
    //     JsonPngToken: JsonToken;
    //     JsonPngObject: JsonObject;
    //     JsonPageDataToken: JsonToken;
    //     Base64Tiff: Text;
    //     Convert: Codeunit "Base64 Convert";
    //     PNGOutStr: OutStream;

    //     HttpMgt: codeunit "DCADV Http Management";
    //     JsonArray: JsonArray;
    // begin
    //     // Create json request object for conversion
    //     if not DCADVFileAPIJsonObj.TIFFRotatePage_Request(jsonObject, TempFile, DocCategoryCode) then
    //         error('Error in SplitTiff_Request');

    //     // Create json body from request object
    //     jsonObject.WriteTo(jsonBody);

    //     // Build and send the request and get the response as json object        
    //     if HttpMgt.SendHttpRequest(JsonArray, JsonBody, 'RotateFromTiff?PageNo=' + format(RotateAtPageNo), 'Post') then begin
    //         for i := 1 to JsonArray.Count() do begin
    //             JsonArray.Get(i - 1, JsonPngToken);
    //             if JsonPngToken.IsObject then begin
    //                 JsonPngObject := JsonPngToken.AsObject();
    //                 if JsonPngObject.Get('data', JsonPageDataToken) then begin
    //                     if not JsonPageDataToken.AsValue().IsNull then begin
    //                         Base64Tiff := JsonPageDataToken.AsValue().AsText();

    //                         if i = 1 then
    //                             if not TempNewFile1.Data.HasValue then begin
    //                                 TempNewFile1.Data.CreateOutStream(PNGOutStr);
    //                                 Convert.FromBase64(Base64Tiff, PNGOutStr);
    //                             end;

    //                     end;
    //                 end;
    //             end;
    //         end;
    //     end;
    // end;

    internal procedure TiffSplit(TempDocumentPage: record "CDC Temp. Document Page"; var TempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer; HideError: Boolean) Success: Boolean
    var

        JsonBody: Text;
        jsonObject: JsonObject;
        DCADVFileAPIJsonOBj: Codeunit "DCADV File API JsonObjects";
        i: Integer;
        JsonPngToken: JsonToken;
        JsonPngObject: JsonObject;
        JsonPageDataToken: JsonToken;
        Base64Tiff: Text;
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
                            Base64Tiff := JsonPageDataToken.AsValue().AsText();

                            if i = 1 then
                                if not TempNewFile1.Data.HasValue then begin
                                    TempNewFile1.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64Tiff, PNGOutStr);
                                end;
                            if i = 2 then
                                if not TempNewFile2.Data.HasValue then begin
                                    TempNewFile2.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64Tiff, PNGOutStr);
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
        Base64Tiff: Text;
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
                            Base64Tiff := JsonPageDataToken.AsValue().AsText();

                            if i = 1 then
                                if not TempNewFile1.Data.HasValue then begin
                                    TempNewFile1.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64Tiff, PNGOutStr);
                                end;
                            if i = 2 then
                                if not TempNewFile2.Data.HasValue then begin
                                    TempNewFile2.Data.CreateOutStream(PNGOutStr);
                                    Convert.FromBase64(Base64Tiff, PNGOutStr);
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
}
