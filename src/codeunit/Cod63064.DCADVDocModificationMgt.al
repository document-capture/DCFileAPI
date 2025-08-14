codeunit 63064 "DCADV Doc. Modification Mgt."
{
    var
        HideWindow: Boolean;
        Window: Dialog;
        RotatingPagesProgressCounterLbl: Label '%1 of %2';
        RotatingPagesProgressWindowLbl: Label 'Rotating pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';


    internal procedure DeletePages(var SelectedPages: Record "CDC Temp. Document Page"; var PagesToDelete: Record "CDC Temp. Document Page"): Boolean
    var
        Document: Record "CDC Document";
        CurrDocumentNo: Code[20];
        PageNo: Integer;
        TotalPages: Integer;
        DeleteSelectedPageQst: Label 'Do you want to delete the selected page?';
        DeleteSelectedPagesQst: Label 'Do you want to delete the selected %1 pages?';
        DeletingPagesProgress: Label 'Deleting pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
        PagesToDeleteList: List of [Integer];
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
        intValue: Integer;
        deletedPages: Integer;
    begin
        Document.GET(DocumentNo);
        Document.CALCFIELDS("No. of Pages");
        if Document."No. of Pages" < 2 then
            Document.DELETE(TRUE)
        else begin
            InvalidateDocumentAIData_Cloned(Document);

            PagesToDeleteList.Reverse();

            //HERE
            if not DeletePagesFromPdf(PagesToDeleteList, Document, TempNewPdfFile) then
                error('Error deleting pages from PDF file.');

            if not DeletePagesFromTiff(PagesToDeleteList, Document, TempNewTiffFile) then
                error('Error deleting pages from Tiff file.');

            if not Document.SetPdfFile(TempNewPdfFile) then
                error('Error setting new PDF file for document %1.', Document."No.");

            if not Document.SetTiffFile(TempNewTiffFile) then
                Error('Error setting new Tiff file for document %1.', Document."No.");

            PagesToDeleteList.Reverse();

            // Reorder pages in the document   
            foreach intValue in PagesToDeleteList do begin

                DocPage.GET(DocumentNo, intValue);
                DocPage.DELETE(TRUE);

                DocPage.SETRANGE("Document No.", DocumentNo);
                DocPage.SETFILTER("Page No.", '>%1', intValue);
                IF DocPage.FINDSET THEN
                    REPEAT
                        MovePage(DocPage."Document No.", DocPage."Page No.", DocPage."Document No.", DocPage."Page No." - 1);
                    UNTIL DocPage.NEXT = 0;
            end;

            Commit();
            exit(true);
        end;
    end;

    internal procedure DeletePagesFromPdf(PagesToDeleteList: List of [Integer]; Document: Record "CDC Document"; var TempNewPdfFile: Record "CDC Temp File" temporary): Boolean
    var
        TempFile: Record "CDC Temp File";
        ApiMgt: Codeunit "DCADV Json Management";
    begin
        if not Document.GetPdfFile(TempFile) then
            exit(false);

        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile);
        ApiMgt.AddIntArray('pagesToDelete', PagesToDeleteList);

        // Send request and process response
        if ApiMgt.Send('DeleteFromPDF', 'Post') then
            exit(ApiMgt.GetOutputFile(0, TempNewPdfFile));
    end;

    /// <summary>DONE
    /// Deletes the specified pages from a Tiff document.
    /// </summary>
    /// <param name="PagesToDeleteJsonArray">JsonArray of the page numbers that should be deleted</param>
    /// <param name="Document">Document record</param>
    /// <param name="TempNewTiffFile">Temp. tiff file after deleting the documents</param>
    /// <returns></returns>
    internal procedure DeletePagesFromTiff(PagesToDeleteList: List of [Integer]; Document: Record "CDC Document"; var TempNewTiffFile: Record "CDC Temp File" temporary): Boolean
    var
        TempFile: Record "CDC Temp File";
        ApiMgt: Codeunit "DCADV Json Management";
    begin
        if not Document.GetTiffFile(TempFile) then
            exit(false);

        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile);
        ApiMgt.AddIntArray('framesToDelete', PagesToDeleteList);

        // Send request and process response
        if ApiMgt.Send('DeleteFromTiff', 'Post') then
            exit(ApiMgt.GetOutputFile(0, TempNewTiffFile));
    end;

    /// <summary>DONe
    /// Central procedure to rotate pages of all document related files (Pdf, Tiff, Png). 
    /// </summary>
    /// <param name="PagesToRotate">Temp. Page record that holds the selected pages including document no.</param>
    /// <param name="RotationAngle">Angle the pages have to be rotated</param>
    internal procedure RotatePages(var PagesToRotate: Record "CDC Temp. Document Page"; RotationAngle: Integer)
    var
        Document: Record "CDC Document";
        PageNo: Integer;
        TotalPages: Integer;
        PagesToRotateList: List of [Integer];
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

        // TODO Clarify secure archive management
        //IF SecureArchiveManagement.SecureArchiveEnabled THEN
        //    SecureArchiveManagement.CalculateAndAssignFileHash(Document);
    end;

    local procedure RotateDocumentPages(PagesToRotateList: List of [Integer]; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        NewPdfTempFile: Record "CDC Temp File" temporary;
        NewTiffTempFile: Record "CDC Temp File" temporary;
        FileApiMgt: Codeunit "DCADV File API Management";
    begin
        Document.Version += 1;
        Document.MODIFY;

        if not RotatePdfPages(NewPdfTempFile, PagesToRotateList, RotationAngle, Document) then
            error('Error rotating pages in Pdf file.');

        if not RotateTiffPages(NewTiffTempFile, PagesToRotateList, RotationAngle, Document) then
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

    local procedure RotatePdfPages(var NewPdfTempFile: Record "CDC Temp File" temporary; PagesToRotateList: List of [Integer]; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
        TempFile: Record "CDC Temp File";
    begin
        if not Document.GetPdfFile(TempFile) then
            exit(false);

        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile);
        ApiMgt.AddIntArray('pagesToRotate', PagesToRotateList);
        ApiMgt.AddInteger('rotationDirection', RotationAngle);

        // Send request and process response
        if ApiMgt.Send('RotatePdfPages', 'Post') then
            exit(ApiMgt.GetOutputFile(0, NewPdfTempFile));
    end;

    /// <summary>
    /// Returns the file type as a string based on the provided FileType enum value.
    /// </summary>
    /// <param name="NewTiffTempFile"></param>
    /// <param name="PagesToRotateJsonArray"></param>
    /// <param name="RotationAngle"></param>
    /// <param name="Document"></param>
    /// <returns></returns>
    local procedure RotateTiffPages(var NewTiffTempFile: Record "CDC Temp File" temporary; PagesToRotateList: List of [Integer]; RotationAngle: Integer; Document: Record "CDC Document"): Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
        TempFile: Record "CDC Temp File";
    begin
        if not Document.GetTiffFile(TempFile) then
            exit(false);

        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile);
        ApiMgt.AddIntArray('pagesToRotate', PagesToRotateList);
        ApiMgt.AddInteger('rotationDirection', RotationAngle);

        // Send request and process response
        if ApiMgt.Send('RotateTiffPages', 'Post') then
            exit(ApiMgt.GetOutputFile(0, NewTiffTempFile));
    end;

    /// <summary>
    /// Splits a Tiff document into two parts at the specified page number.
    /// </summary>
    /// <param name="DocumentCategory">Current documents document category code</param>
    /// <param name="TempFile">Source Tiff that should be splitted</param>
    /// <param name="TempNewFile1">Temp.  file - split part 1</param>
    /// <param name="TempNewFile2">Temp.  file - split part 2</param>
    /// <param name="SplitAtPageNo">Page position to splut</param>
    /// <returns>True if split was successful</returns>
    internal procedure TiffSplit(DocumentCategory: Code[10]; var TiffTempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer) Success: Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
    begin
        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TiffTempFile);
        ApiMgt.AddInteger('splitAfterPages', SplitAtPageNo);

        // Send request and process response
        if ApiMgt.Send('SplitTiff', 'Post') then begin
            if (ApiMgt.GetOutputFile(0, TempNewFile1)) then
                exit(ApiMgt.GetOutputFile(1, TempNewFile2));
        end;
    end;

    /// <summary>
    /// Splits a PDF document into two parts at the specified page number.
    /// </summary>
    /// <param name="DocumentCategory">Current documents document category code</param>
    /// <param name="TempFile">Source PDF that should be splitted</param>
    /// <param name="TempNewFile1">Temp.  file - split part 1</param>
    /// <param name="TempNewFile2">Temp.  file - split part 2</param>
    /// <param name="SplitAtPageNo">Page position to splut</param>
    /// <returns>True if split was successful</returns>
    internal procedure PDFSplit(DocumentCategory: Code[10]; var PdfTempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer) Succes: Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
    begin
        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(PdfTempFile);
        ApiMgt.AddInteger('splitAfterPages', SplitAtPageNo);

        // Send request and process response
        if ApiMgt.Send('SplitPdf', 'Post') then begin
            if (ApiMgt.GetOutputFile(0, TempNewFile1)) then
                exit(ApiMgt.GetOutputFile(1, TempNewFile2));
        end;
    end;

    procedure TiffCombine(TempDocumentPage: Record "CDC Temp. Document Page"; var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
        FileApiMgt: Codeunit "DCADV File API Management";
    begin
        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile1);
        ApiMgt.AddInputFile(TempFile2);
        ApiMgt.AddInteger('dpi', FileApiMgt.GetDocumentCategoryResolution(TempDocumentPage."Document Category Code"));
        ApiMgt.AddInteger('color', FileApiMgt.GetDocumentCategoryColorMode(TempDocumentPage."Document Category Code").AsInteger());

        // Send request and process response
        if ApiMgt.Send('MergeTiff', 'Post') then begin
            exit(ApiMgt.GetOutputFile(0, TempNewFile));
        end;
    end;

    procedure PDFCombine(TempDocumentPage: Record "CDC Temp. Document Page"; var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
    var
        ApiMgt: Codeunit "DCADV Json Management";
        FileApiMgt: Codeunit "DCADV File API Management";
    begin
        // Create the request body for the API call
        ApiMgt.ClearAll();
        ApiMgt.AddInputFile(TempFile1);
        ApiMgt.AddInputFile(TempFile2);
        ApiMgt.AddInteger('dpi', FileApiMgt.GetDocumentCategoryResolution(TempDocumentPage."Document Category Code"));
        ApiMgt.AddInteger('color', FileApiMgt.GetDocumentCategoryColorMode(TempDocumentPage."Document Category Code").AsInteger());

        // Send request and process response
        if ApiMgt.Send('MergePdf', 'Post') then begin
            exit(ApiMgt.GetOutputFile(0, TempNewFile));
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
        AIDocumentLine: Record "CDC AI Document Line";
        AIField: Record "CDC AI Field";
        AIFieldValuePart: Record "CDC AI Field Value Part";
        AIKeyValuePair: Record "CDC AI Key/Value Pair";
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
