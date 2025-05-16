page 63060 "DCADV Split and Merge local"
{
    // C/SIDE
    // revision:41

    Caption = 'Split and Merge Documents';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    Permissions = TableData 6085599 = imd;
    SourceTable = "CDC Temp. Document Page";
    //ContextSensitiveHelpPage = 'DC-80';
    AboutTitle = 'About split and merge ';
    AboutText = 'You can **split** and **merge** document files. Furthermore, you can *move*, *rotate*, and *delete* individual document pages.';

    layout
    {
        area(content)
        {
            group(Group1)
            {
                Caption = '';

            }
            repeater(Group2)
            {
                Caption = '';
                field("Display Document No."; Rec."Display Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the document.';
                }
                field(SourceID; SourceID)
                {
                    ApplicationArea = All;
                    CaptionClass = GetSourceIDCaption;
                    Caption = 'Source ID';
                    ToolTip = 'Specifies the primary key of the record this document belong. For purchase related documents this will show the number of the vendor.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    CaptionClass = GetSourceNameCaption;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record this document belong. For purchase related documents this will show the name of the vendor.';
                }
                field("Original Filename"; Rec."Original Filename")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("From Email"; FromEmail)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Recipient Date Time"; RepDateTime)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Subject; Subject)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(CaptureUI; "CDC Document Page Client Addin")
            {
                ApplicationArea = All;
                Caption = 'Page';
                SubPageLink = "Document No." = FIELD("Document No."),
                              "Page No." = FIELD(Page);
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                action("Move Up")
                {
                    ApplicationArea = All;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+U';
                    ToolTip = 'Move the selected page up in the document.';

                    trigger OnAction()
                    begin
                        MovePages(TRUE);
                    end;
                }
                action("Move Down")
                {
                    ApplicationArea = All;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+O';
                    ToolTip = 'Move the selected page down in the document.';

                    trigger OnAction()
                    begin
                        MovePages(FALSE);
                    end;
                }
                action(Split)
                {
                    ApplicationArea = All;
                    Caption = '&Split';
                    Image = Splitlines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+Ctrl+Alt+S';
                    ToolTip = 'Split the document at the selected page and create a new document with the remaining pages.';
                    AboutTitle = 'Split the PDF file';
                    AboutText = 'If a *vendor* sends you a *PDF file* containing multiple *invoices*, you can easily **split** the PDF file into individual *documents*.';

                    trigger OnAction()
                    var
                        TempDocPage2: Record "CDC Temp. Document Page" temporary;
                        NewDocNo: array[150] of Code[20];
                        NewDocCount: Integer;
                        PageNo: Integer;
                        EntryNo: Integer;
                        i: Integer;
                    begin
                        EntryNo := Rec."Entry No.";
                        CLEAR(TempDocPage);
                        CurrPage.SETSELECTIONFILTER(TempDocPage);
                        NewDocCount := SplitPages(TempDocPage, TempDocPage2, NewDocNo);

                        TempDocPage2.FINDSET;
                        REPEAT
                            i += 1;
                            PageNo := 0;
                            Rec.ASCENDING(FALSE);
                            Rec.SETRANGE("Document No.", TempDocPage2."Document No.");
                            Rec.FINDSET(TRUE);
                            REPEAT
                                IF Rec.Page >= TempDocPage2.Page THEN BEGIN
                                    PageNo += 1;
                                    Rec."Document No." := NewDocNo[NewDocCount];
                                    Rec.Page := PageNo;
                                    IF PageNo = 1 THEN
                                        Rec."Display Document No." := NewDocNo[NewDocCount];
                                    Rec."Source ID" := '';
                                    Rec.Name := '';
                                    Rec.MODIFY;

                                    TempDocPage := Rec;
                                    TempDocPage.MODIFY;
                                END;
                            UNTIL Rec.NEXT = 0;
                            NewDocCount -= 1;
                        UNTIL TempDocPage2.NEXT = 0;
                        Rec.ASCENDING(TRUE);
                        Rec.SETRANGE("Document No.");
                        Rec.GET(EntryNo);

                        Rec.SETCURRENTKEY("Document No.");
                    end;
                }
                action(Merge)
                {
                    ApplicationArea = All;
                    Caption = 'Merge';
                    Image = Trace;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+M';
                    ToolTip = 'Merge two or more documents. Even if only one page from a document is selected, the full document is merged.';
                    AboutTitle = 'Bring documents together';
                    AboutText = 'If you are receiving multiple separate *PDF files* that belong together, you can easily **merge** these into one PDF file. To do this, mark the *documents* that are arranged in sequence and select **Merge**.';

                    trigger OnAction()
                    var
                        TempDocPage2: Record "CDC Temp. Document Page" temporary;
                        FirstDocNo: Code[20];
                        PageNo: Integer;
                        EntryNo: Integer;
                        SourceID1: Text[250];
                        SourceID2: Text[250];
                        SourceName1: Text[250];
                        SourceName2: Text[250];
                        SeveralSourceID: Boolean;
                    begin
                        EntryNo := Rec."Entry No.";
                        CLEAR(TempDocPage);
                        CurrPage.SETSELECTIONFILTER(TempDocPage);
                        PageNo := MergePages(TempDocPage, TempDocPage2);
                        TempDocPage2.FINDSET;
                        FirstDocNo := TempDocPage2."Document No.";

                        SourceID1 := TempDocPage2."Source ID";
                        SourceName1 := TempDocPage2.Name;
                        TempDocPage2.NEXT;
                        REPEAT
                            Rec.SETRANGE("Document No.", TempDocPage2."Document No.");
                            Rec.FINDSET(TRUE);
                            REPEAT
                                IF (SourceID1 = '') OR (SourceID2 = '') THEN BEGIN
                                    SourceID2 := Rec."Source ID";
                                    SourceName2 := Rec.Name;
                                    IF SourceID2 <> '' THEN BEGIN
                                        IF SourceID1 = '' THEN BEGIN
                                            SourceID1 := SourceID2;
                                            SourceName1 := SourceName2;
                                            SourceID2 := '';
                                            SourceName2 := '';
                                        END ELSE
                                            IF SourceID1 <> SourceID2 THEN
                                                SeveralSourceID := TRUE
                                            ELSE
                                                SourceID2 := '';
                                    END;
                                END;

                                PageNo += 1;
                                Rec."Document No." := FirstDocNo;
                                Rec.Page := PageNo;
                                Rec."Display Document No." := '';
                                Rec."Source ID" := '';
                                Rec.Name := '';
                                Rec.MODIFY;

                                TempDocPage := Rec;
                                TempDocPage.MODIFY;
                            UNTIL Rec.NEXT = 0;
                        UNTIL TempDocPage2.NEXT = 0;

                        IF SeveralSourceID THEN BEGIN
                            Rec.SETRANGE("Document No.", FirstDocNo);
                            IF Rec.FINDFIRST THEN BEGIN
                                Rec."Source ID" := '';
                                Rec.MODIFY;
                            END;
                        END ELSE
                            IF SourceID1 <> '' THEN BEGIN
                                Rec.SETRANGE("Document No.", FirstDocNo);
                                IF Rec.FINDFIRST THEN
                                    IF Rec."Source ID" = '' THEN BEGIN
                                        Rec."Source ID" := SourceID1;
                                        Rec.Name := SourceName1;
                                        Rec.MODIFY;
                                    END;
                            END;

                        Rec.SETRANGE("Document No.");

                        Rec.GET(EntryNo);
                        UpdateImage;

                        Rec.SETCURRENTKEY("Document No.");
                    end;
                }
                // action(Rotate)
                // {
                //     ApplicationArea = All;
                //     Caption = 'Rotate';
                //     Image = Delegate;
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     ShortCutKey = 'Ctrl+R';
                //     ToolTip = 'Rotate the current page 90 degrees in clockwise direction.';

                //     trigger OnAction()
                //     var
                //         DocModMgt: Codeunit "CDC Document Modification Mgt.";
                //     begin
                //         CLEAR(TempDocPage);
                //         CurrPage.SETSELECTIONFILTER(TempDocPage);
                //         DocModMgt.RotatePages(TempDocPage);
                //         UpdateImage;
                //     end;
                // }
                // action(Delete)
                // {
                //     ApplicationArea = All;
                //     Caption = 'Delete';
                //     Enabled = DeleteEnabled;
                //     Image = Reject;
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     ShortCutKey = 'Ctrl+Delete';
                //     ToolTip = 'Delete the selected page from the document.';

                //     trigger OnAction()
                //     var
                //         TempDocPage2: Record "CDC Temp. Document Page" temporary;
                //         DocModMgt: Codeunit "CDC Document Modification Mgt.";
                //         PrevDocNo: Code[20];
                //         EntryNo: Integer;
                //         "Count": Integer;
                //         SecureArchiveManagement: Codeunit "CDC Secure Archive Management";
                //         Document: Record "CDC Document";
                //     begin
                //         EntryNo := "Entry No.";
                //         CLEAR(TempDocPage);
                //         CurrPage.SETSELECTIONFILTER(TempDocPage);
                //         IF NOT DocModMgt.DeletePages(TempDocPage, TempDocPage2) THEN
                //             EXIT;

                //         TempDocPage2.FINDSET;
                //         REPEAT
                //             IF PrevDocNo <> TempDocPage2."Document No." THEN BEGIN
                //                 PrevDocNo := TempDocPage2."Document No.";
                //                 Count := 0;
                //             END ELSE
                //                 Count += 1;

                //             GET(TempDocPage2."Entry No.");
                //             DELETE;
                //             TempDocPage.GET(TempDocPage2."Entry No.");
                //             TempDocPage.DELETE;

                //             SETRANGE("Document No.", TempDocPage2."Document No.");
                //             IF FINDSET(TRUE) THEN
                //                 REPEAT
                //                     IF Page >= TempDocPage2.Page - Count THEN BEGIN
                //                         Page -= 1;
                //                         "Display Document No." := '';
                //                         IF Page = 1 THEN
                //                             "Display Document No." := "Document No.";
                //                         MODIFY;

                //                         TempDocPage := Rec;
                //                         TempDocPage.MODIFY;
                //                     END;
                //                 UNTIL NEXT = 0;
                //             SecureArchiveManagement.LogDocumentPageDelete(TempDocPage2);
                //             IF SecureArchiveManagement.SecureArchiveEnabled THEN
                //                 IF Document.GET("Document No.") THEN
                //                     SecureArchiveManagement.CalculateAndAssignFileHash(Document);
                //         UNTIL TempDocPage2.NEXT = 0;

                //         SETRANGE("Document No.");
                //         SETFILTER("Entry No.", '>=%1', EntryNo);
                //         IF NOT FINDFIRST THEN BEGIN
                //             SETRANGE("Entry No.");
                //             IF FINDLAST THEN;
                //         END ELSE
                //             SETRANGE("Entry No.");

                //         UpdateImage;
                //     end;
                // }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DocumentPage: Record "CDC Document Page";
        Email: Record "CDC E-mail";
        EmptyGUID: Guid;
    begin
        IF Rec.Page = 1 THEN BEGIN
            IF Rec."Source ID" <> '' THEN BEGIN
                SourceID := Rec."Source ID";
                Description := Rec.Name;
            END ELSE BEGIN
                SourceID := PageText001;
                Description := ' - ' + PageText002 + ' ' + FORMAT(Rec.Page);
            END;
        END ELSE BEGIN
            SourceID := '';
            Description := ' - ' + PageText002 + ' ' + FORMAT(Rec.Page);
        END;

        IF DocumentPage.GET(Rec."Document No.", Rec.Page) THEN
            IF DocumentPage."E-Mail GUID" <> EmptyGUID THEN
                IF Email.GET(DocumentPage."E-Mail GUID") THEN BEGIN
                    FromEmail := Email."From E-Mail Address";
                    RepDateTime := Email."E-Mail Date";
                    Subject := Email."E-Mail Subject";
                END
                ELSE BEGIN
                    FromEmail := '';
                    RepDateTime := 0DT;
                    Subject := '';
                END;
    end;

    trigger OnOpenPage()
    var
        DocCat: Record "CDC Document Category";
        Channel: Code[50];
    begin
        UpdateList;

        IF FirstDocument."No." <> '' THEN BEGIN
            Rec.SETCURRENTKEY("Document No.");
            Rec.SETRANGE("Document No.", FirstDocument."No.");
            IF Rec.FINDFIRST THEN;
            Rec.SETRANGE("Document No.");
            Rec.SETCURRENTKEY("Entry No.");
        END;

        DeleteEnabled := TRUE;
        IF DocCat.GET(DocCatCode) THEN
            DeleteEnabled := DocCat."Allow Deleting Documents";

        Channel := CREATEGUID;
        EventNotifierSource.ADDTEXT(Channel);

        // CurrPage.CaptureUI.PAGE.SetConfig('', '', Channel);
        // CurrPage.CaptureUI.PAGE.SetParentPage(CurrPage.OBJECTID(FALSE));
    end;

    var
        TempDocPage: Record "CDC Temp. Document Page" temporary;
        Document: Record "CDC Document";
        FirstDocument: Record "CDC Document";
        DocCatCode: Code[10];
        SourceID: Text[250];
        Description: Text[250];
        EventNotifierSource: BigText;
        PageText001: Label '[NONE]';
        PageText002: Label 'Page';
        SourceIDText: Label 'Source ID';
        SourceNameText: Label 'Source Name';
        NoMovedPages: Label 'You cannot move documents up and down, only pages within a document can move up and down.';
        DeleteEnabled: Boolean;
        FromEmail: Text[200];
        RepDateTime: DateTime;
        Subject: Text[200];


        Text001: Label 'Please select pages of multiple documents ordered in sequence.';
        Text002: Label 'You cannot select pages from single-page documents nor pages that are the first page in a document.';
        Text004: Label 'Splitting pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
        Window: Dialog;
        PDFMgt: Codeunit "CDC PDF Management";
        TIFFMgt: Codeunit "CDC TIFF Management";
        HideWindow: Boolean;
        Text005: Label 'Merging pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
        Text007: Label '%1 of %2';
        Text011: Label 'Moving pages\#1####################\@2@@@@@@@@@@@@@@@@@@@@';
        NoOfPagesToSplitExceedsErr: Label 'You can only select %1 pages for splitting at a time.\If you need to split more pages, run the process repeatedly.';
        HideError: Boolean;



    internal procedure HandleSimpleCommand(Command: Text[1024])
    begin
        CASE Command OF
            'UPDATEDOCUMENT',
          'UPDATEHEADER':
                //  CurrPage.UPDATE(FALSE); // May be necessary in 2009 and 2009 SP1
                ;
        END;
    end;

    internal procedure UpdateList()
    begin
        TempDocPage.BuildTableLocal(DocCatCode, Document);
        Rec.DELETEALL;
        IF TempDocPage.FINDSET THEN
            REPEAT
                Rec := TempDocPage;
                Rec.INSERT;
            UNTIL TempDocPage.NEXT = 0;
        IF Rec.FINDFIRST THEN;
        CurrPage.UPDATE(FALSE);
    end;

    internal procedure UpdateImage()
    begin
        // CurrPage.CaptureUI.PAGE.SetForceUpdate(TRUE);
        // CurrPage.CaptureUI.PAGE.UpdatePage;
        CurrPage.UPDATE(FALSE);
    end;

    procedure SetParam(NewDocCatCode: Code[10]; var Document: Record "CDC Document")
    begin
        DocCatCode := NewDocCatCode;
        FirstDocument := Document;
    end;

    internal procedure MovePages(MoveUp: Boolean)
    var
        EntryNo: Integer;
    begin
        EntryNo := Rec."Entry No.";
        CurrPage.SETSELECTIONFILTER(TempDocPage);
        IF NOT MovePages(TempDocPage, MoveUp) THEN BEGIN
            MESSAGE(NoMovedPages);
            EXIT;
        END;

        IF MoveUp THEN BEGIN
            Rec.SETFILTER("Entry No.", '<%1', EntryNo);
            Rec.FINDLAST;
            Rec.SETRANGE("Entry No.");
        END ELSE
            Rec.NEXT;

        UpdateImage;
        // SecureArchiveManagement.LogDocumentPageReorder(Document);
        // IF Document2.GET(Rec."Document No.") THEN
        //     IF SecureArchiveManagement.SecureArchiveEnabled THEN
        //         SecureArchiveManagement.CalculateAndAssignFileHash(Document2);
    end;

    internal procedure GetSourceIDCaption() Caption: Text[250]
    var
        DocCat: Record "CDC Document Category";
        AllObjWithCaption: Record AllObjWithCaption;
        RecIDMgt: Codeunit "CDC Record ID Mgt.";
    begin
        Caption := SourceIDText;
        IF DocCat.GET(DocCatCode) THEN
            IF DocCat."Source Table No." <> 0 THEN
                Caption := RecIDMgt.GetObjectCaption(AllObjWithCaption."Object Type"::Table, DocCat."Source Table No.");
    end;

    internal procedure GetSourceNameCaption() Caption: Text[250]
    var
        DocCat: Record "CDC Document Category";
        RecIDMgt: Codeunit "CDC Record ID Mgt.";
    begin
        Caption := SourceNameText;
        IF DocCat.GET(DocCatCode) THEN
            IF (DocCat."Source Table No." <> 0) AND (DocCat."Source Field No. (Name)" <> 0) THEN
                Caption := RecIDMgt.GetFieldCaption(DocCat."Source Table No.", DocCat."Source Field No. (Name)");
    end;


















    internal procedure SplitPages(var SelectedPages: Record "CDC Temp. Document Page"; var PagesToSplit: Record "CDC Temp. Document Page"; var NewDocNo: array[150] of Code[20]) NewDocCount: Integer
    var
        Document: Record "CDC Document";
        Document2: Record "CDC Document";
        TelemetryLogger: Codeunit "CSC Telemetry Management";
        TelemetryDimensions: Codeunit "CSC Telemetry Dictionary";
        TelemetryFormatMgt: Codeunit "CSC Telemetry Format Mgt.";
        PlatformTargetManagement: Codeunit "CDC Platform Target Management";
        DocNo: Code[20];
        TotalPages: Integer;
        PageNo: array[150] of Integer;
        "Count": Integer;
    begin
        TelemetryLogger.StartLogProcedure;

        SelectedPages.FINDSET;
        REPEAT
            IF DocNo <> SelectedPages."Document No." THEN BEGIN
                DocNo := SelectedPages."Document No.";

                Document.GET(DocNo);
                InvalidateDocumentAIData(Document);
                Document.CALCFIELDS("No. of Pages");
                IF (Document."No. of Pages" < 2) OR (SelectedPages.Page < 2) THEN
                    ERROR(Text002);
            END;

            TotalPages += 1;
            IF TotalPages > ARRAYLEN(PageNo) THEN
                ERROR(NoOfPagesToSplitExceedsErr, ARRAYLEN(PageNo));

            PageNo[TotalPages] := SelectedPages.Page;
        UNTIL SelectedPages.NEXT = 0;

        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            Window.OPEN(Text004);
            NewDocCount := TotalPages;
        END;

        CreateNewDoc(SelectedPages."Document No.", TotalPages, NewDocNo);

        DocNo := '';
        SelectedPages.ASCENDING(FALSE);
        IF SelectedPages.FINDFIRST THEN
            REPEAT
                Count += 1;
                IF GUIALLOWED AND NOT HideWindow THEN BEGIN
                    Window.UPDATE(1, STRSUBSTNO(Text007, Count, NewDocCount));
                    Window.UPDATE(2, (Count / NewDocCount * 10000) DIV 1);
                END;

                SplitPage(SelectedPages."Document No.", PageNo[TotalPages], NewDocNo[TotalPages]);
                //SecureArchiveManagement.LogDocumentSplit(SelectedPages."Document No.", NewDocNo[TotalPages]);
                IF Document2.GET(NewDocNo[TotalPages]) THEN
                    CalculateAndAssignFileHash(Document2);
                TotalPages -= 1;

                IF DocNo <> SelectedPages."Document No." THEN BEGIN
                    Document.GET(SelectedPages."Document No.");
                    Document.DeleteComments(-2);
                    Document.Version += 1;
                    Document.MODIFY;
                    DocNo := SelectedPages."Document No.";
                    CalculateAndAssignFileHash(Document);
                END;

                PagesToSplit := SelectedPages;
                PagesToSplit."Entry No." := Count;
                PagesToSplit.INSERT;
            UNTIL SelectedPages.NEXT = 0;

        TelemetryDimensions.Add('NumberOfDocuments', TelemetryFormatMgt.Integer2Text(NewDocCount));
        TelemetryDimensions.Add('UseOnlineService', TelemetryFormatMgt.Boolean2Text(NOT PlatformTargetManagement.IsOnPremInstalled));
        TelemetryLogger.EndLogProcedure('0082', 'Split pages', DocAndTemplate, TelemetryDimensions);

        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;

        SelectedPages.ASCENDING(TRUE);
        EXIT(NewDocCount);
    end;

    internal procedure SplitPage(DocNo: Code[20]; PageNo: Integer; NewDocNo: Code[20])
    var
        DocToSplit: Record "CDC Document";
        NewDoc: Record "CDC Document";
        DocPage: Record "CDC Document Page";
        TempTiffFile: Record "CDC Temp File" temporary;
        TempPdfFile: Record "CDC Temp File" temporary;
        TempDocToSplitTiffFile: Record "CDC Temp File" temporary;
        TempDocToSplitPdfFile: Record "CDC Temp File" temporary;
        TempNewTiffFile: Record "CDC Temp File" temporary;
        TempNewPdfFile: Record "CDC Temp File" temporary;
        NewPageNo: Integer;
    begin
        DocToSplit.GET(DocNo);

        NewDoc.GET(NewDocNo);
        NewDoc."OCR Reprocessing Needed" := DocToSplit."OCR Reprocessing Needed";
        NewDoc.MODIFY;
        NewPageNo := 0;
        DocPage.SETRANGE("Document No.", DocToSplit."No.");
        DocPage.SETFILTER("Page No.", '>=%1', PageNo);
        DocPage.FINDSET;

        REPEAT
            NewPageNo += 1;
            MovePage(DocPage."Document No.", DocPage."Page No.", NewDoc."No.", NewPageNo);
        UNTIL DocPage.NEXT = 0;

        TempTiffFile.CreateTemp('tiff');
        TempPdfFile.CreateTemp('pdf');
        TempNewTiffFile.CreateTemp('tiff');
        TempNewPdfFile.CreateTemp('pdf');

        DocToSplit.GetTiffFile(TempDocToSplitTiffFile);
        DocToSplit.GetPdfFile(TempDocToSplitPdfFile);

        TIFFSplit(TempDocToSplitTiffFile,
          TempTiffFile,
          TempNewTiffFile,
          PageNo - 1,
          HideError);

        PDFSplit(TempDocToSplitPdfFile,
          TempPdfFile,
          TempNewPdfFile,
          PageNo - 1,
          HideError);

        DocToSplit.SetTiffFile(TempTiffFile);
        DocToSplit.SetPdfFile(TempPdfFile);
        NewDoc.SetTiffFile(TempNewTiffFile);
        NewDoc.SetPdfFile(TempNewPdfFile);

        TempFileStorageClear();

        COMMIT;
    end;

    internal procedure MergePages(var SelectedPages: Record "CDC Temp. Document Page"; var FirstPages: Record "CDC Temp. Document Page") LastPageNo: Integer
    var
        Document: Record "CDC Document";
        TelemetryLogger: Codeunit "CSC Telemetry Management";
        TelemetryDimensions: Codeunit "CSC Telemetry Dictionary";
        TelemetryFormatMgt: Codeunit "CSC Telemetry Format Mgt.";
        PlatformTargetManagement: Codeunit "CDC Platform Target Management";
        FirstDocNo: Code[20];
        CurrDocNo: Code[20];
        TotalPages: Integer;
        "Count": Integer;
        SourceID1: Text[250];
        SourceID2: Text[250];
        Document2: Record "CDC Document";
        SeveralSourceID: Boolean;
        Document3: Record "CDC Document";
    begin
        TelemetryLogger.StartLogProcedure;
        SelectedPages.FINDSET;
        REPEAT
            SelectedPages.MARK(TRUE);
        UNTIL SelectedPages.NEXT = 0;

        SelectedPages.FINDSET;
        REPEAT
            IF SelectedPages."Document No." <> CurrDocNo THEN BEGIN
                Document.GET(SelectedPages."Document No.");
                Document.CALCFIELDS("No. of Pages");

                IF LastPageNo = 0 THEN BEGIN
                    LastPageNo := Document."No. of Pages";
                    Document.VALIDATE("Template No.", '');
                    SourceID1 := Document.GetSourceID;
                    Document."Source Record ID Tree ID" := 0;
                    Document."Source Record Table ID" := 0;
                    Document."Source Record No." := '';
                    Document."Source Record Name" := '';
                    Document.Version += 1;
                    Document.MODIFY;
                    FirstDocNo := Document."No.";
                END;

                CurrDocNo := SelectedPages."Document No.";
                FirstPages := SelectedPages;
                FirstPages.INSERT;
            END;
        UNTIL SelectedPages.NEXT = 0;

        IF FirstPages.COUNT < 2 THEN
            ERROR(Text001);

        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            TotalPages := FirstPages.COUNT;
            Window.OPEN(Text005);
        END;

        FirstPages.FINDSET;
        REPEAT
            IF GUIALLOWED AND NOT HideWindow THEN BEGIN
                Count += 1;
                Window.UPDATE(1, STRSUBSTNO(Text007, Count, TotalPages));
                Window.UPDATE(2, (Count / TotalPages * 10000) DIV 1);
            END;

            IF (SourceID1 = '') OR (SourceID2 = '') THEN BEGIN
                Document2.GET(FirstPages."Document No.");
                SourceID2 := Document2.GetSourceID;
                IF SourceID2 <> '' THEN BEGIN
                    IF SourceID1 = '' THEN BEGIN
                        SourceID1 := SourceID2;
                        SourceID2 := '';
                    END ELSE
                        IF SourceID1 <> SourceID2 THEN
                            SeveralSourceID := TRUE
                        ELSE
                            SourceID2 := '';
                END;
            END;

            IF FirstDocNo <> FirstPages."Document No." THEN BEGIN
                MergePage(FirstPages."Document No.", FirstDocNo);
                //SecureArchiveManagement.LogDocumentMerge(FirstPages."Document No.", FirstDocNo);
                IF Document3.GET(FirstDocNo) THEN
                    CalculateAndAssignFileHash(Document3);
            END;
        UNTIL FirstPages.NEXT = 0;

        IF NOT SeveralSourceID AND (SourceID1 <> '') THEN BEGIN
            Document2.GET(FirstDocNo);
            Document2.SetSourceID(SourceID1);
        END;

        TelemetryDimensions.Add('NumberOfPages', TelemetryFormatMgt.Integer2Text(TotalPages));
        TelemetryDimensions.Add('UseOnlineService', TelemetryFormatMgt.Boolean2Text(NOT PlatformTargetManagement.IsOnPremInstalled));
        TelemetryLogger.EndLogProcedure('0081', 'Merge pages', DocAndTemplate, TelemetryDimensions);
        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;
    end;

    internal procedure MergePage(var MergeDocNo: Code[20]; FirstDocNo: Code[20])
    var
        FirstDoc: Record "CDC Document";
        Document: Record "CDC Document";
        DocPage: Record "CDC Document Page";
        TempTiffFile: Record "CDC Temp File" temporary;
        TempPdfFile: Record "CDC Temp File" temporary;
        TempDocFile: Record "CDC Temp File" temporary;
        TempFirstDocFile: Record "CDC Temp File" temporary;
        PageNo: Integer;
    begin
        FirstDoc.GET(FirstDocNo);
        FirstDoc.CALCFIELDS("No. of Pages");
        //FirstDoc.InvalidateAIData;
        InvalidateDocumentAIData(FirstDoc);

        PageNo := FirstDoc."No. of Pages";

        Document.GET(MergeDocNo);

        IF Document."OCR Reprocessing Needed" THEN BEGIN
            FirstDoc."OCR Reprocessing Needed" := TRUE;
            FirstDoc.MODIFY;
        END;

        DocPage.SETRANGE("Document No.", Document."No.");
        IF DocPage.FINDSET THEN
            REPEAT
                PageNo += 1;
                MovePage(DocPage."Document No.", DocPage."Page No.", FirstDoc."No.", PageNo);
            UNTIL DocPage.NEXT = 0;

        TempTiffFile.CreateTemp('tiff');
        TempPdfFile.CreateTemp('pdf');

        FirstDoc.GetTiffFile(TempFirstDocFile);
        Document.GetTiffFile(TempDocFile);
        TiffCombine(TempFirstDocFile, TempDocFile, TempTiffFile, HideError);

        FirstDoc.GetPdfFile(TempFirstDocFile);
        Document.GetPdfFile(TempDocFile);
        PDFCombine(TempFirstDocFile, TempDocFile, TempPdfFile, HideError);

        Document.SuspendDeleteCheck(TRUE);
        Document.DELETE(TRUE);
        Document.SuspendDeleteCheck(FALSE);

        FirstDoc.SetTiffFile(TempTiffFile);
        FirstDoc.SetPdfFile(TempPdfFile);

        TempFileStorageClear;

        COMMIT;
    end;


    procedure InvalidateDocumentAIData(var Document: Record "CDC Document")
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

    internal procedure MovePages(var SelectedPages: Record "CDC Temp. Document Page"; MoveUp: Boolean) PagesMoved: Boolean
    var
        Document: Record "CDC Document";
        TempTiffFile: Record "CDC Temp File" temporary;
        TempPdfFile: Record "CDC Temp File" temporary;
        MoveThisPage: Boolean;
        MoveToPage: Integer;
        TotalPages: Integer;
        "Count": Integer;
    begin
        IF GUIALLOWED AND NOT HideWindow THEN BEGIN
            Window.OPEN(Text011);
            TotalPages := SelectedPages.COUNT;
        END;

        SelectedPages.FINDSET;
        REPEAT
            IF GUIALLOWED AND NOT HideWindow THEN BEGIN
                Count += 1;
                Window.UPDATE(1, STRSUBSTNO(Text007, Count, TotalPages));
                Window.UPDATE(2, (Count / TotalPages * 10000) DIV 1);
            END;

            IF Document."No." <> SelectedPages."Document No." THEN
                Document.GET(SelectedPages."Document No.");

            IF NOT MoveUp THEN BEGIN
                Document.CALCFIELDS(Document."No. of Pages");
                MoveThisPage := SelectedPages.Page < Document."No. of Pages";
            END ELSE
                MoveThisPage := SelectedPages.Page > 1;

            IF MoveThisPage THEN BEGIN
                IF MoveUp THEN
                    MoveToPage := SelectedPages.Page - 1
                ELSE
                    MoveToPage := SelectedPages.Page + 1;

                MovePage(SelectedPages."Document No.", SelectedPages.Page, SelectedPages."Document No.", 0);
                MovePage(SelectedPages."Document No.", MoveToPage, SelectedPages."Document No.", SelectedPages.Page);
                MovePage(SelectedPages."Document No.", 0, SelectedPages."Document No.", MoveToPage);

                Document.GetTiffFile(TempTiffFile);
                Document.GetPdfFile(TempPdfFile);

                TIFFMgt.MovePage(TempTiffFile, SelectedPages.Page, MoveToPage, HideError);
                PDFMgt.MovePage(TempPdfFile, SelectedPages.Page, MoveToPage, HideError);

                Document.SetTiffFile(TempTiffFile);
                Document.SetPdfFile(TempPdfFile);

                Document.Version += 1;
                Document.MODIFY;

                COMMIT;

                PagesMoved := TRUE;
                MoveThisPage := FALSE;
            END;
        UNTIL SelectedPages.NEXT = 0;

        IF GUIALLOWED AND NOT HideWindow THEN
            Window.CLOSE;
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

    internal procedure CreateNewDoc(DocNo: Code[20]; SplitCount: Integer; var NewDocNo: array[150] of Code[20])
    var
        DocToSplit: Record "CDC Document";
        NewDoc: Record "CDC Document";
        i: Integer;
    begin
        DocToSplit.GET(DocNo);
        FOR i := 1 TO SplitCount DO BEGIN
            NewDoc.TRANSFERFIELDS(DocToSplit);
            NewDoc."No." := '';
            NewDoc.INSERT(TRUE);
            NewDoc.VALIDATE("Source Record ID Tree ID", 0);
            NewDoc."Temp Page No." := 0;
            NewDoc."Document ID" := GetDocumentFileId;
            NewDoc.MODIFY(TRUE);
            NewDocNo[i] := NewDoc."No.";
        END;
    end;

    internal procedure GetDocumentFileId(): Text[50]
    var
        UUIDManagement: Codeunit "CSC UUID Management";
        Length: Integer;
        Handled: Boolean;
        DocumentID: Text;
    begin
        Handled := FALSE;

        IF Handled THEN
            EXIT(DocumentID);

        Length := 10;
        EXIT(UUIDManagement.GetShortUUID(Length));
    end;

    internal procedure CalculateAndAssignFileHash(var Document: Record "CDC Document")
    var
        ExistingHash: Text[50];
    begin
        ExistingHash := Document."File Hash";
        CASE TRUE OF
            Document.HasPdfFile:
                BEGIN
                    Document."File Hash" := CalcHashForPdfFile(Document);
                    Document.MODIFY(FALSE);
                END;
            Document.HasXmlFile:
                BEGIN
                    Document."File Hash" := CalcHashForXmlFile(Document);
                    Document.MODIFY(FALSE);
                END;
            Document.HasMiscFile:
                BEGIN
                    Document."File Hash" := CalcHashForMiscFile(Document);
                    Document.MODIFY(FALSE);
                END;
        END;
        IF (ExistingHash <> '') AND (Document."File Hash" <> ExistingHash) THEN
            LogDocumentHashRecalculated(Document, ExistingHash);
    end;

    local procedure CalcHashForPdfFile(Document: Record "CDC Document"): Text[50]
    var
        PDFTempFile: Record "CDC Temp File" temporary;
        ReadStream: InStream;
        CryptographyManagement: Codeunit "CDC Cryptography Management";
    begin
        IF Document.HasPdfFile THEN BEGIN
            Document.GetPdfFile(PDFTempFile);
            PDFTempFile.GetDataStream(ReadStream);
            EXIT(CryptographyManagement.GetFileSHA1Hash2(ReadStream));
        END;
    end;

    local procedure CalcHashForMiscFile(Document: Record "CDC Document"): Text[50]
    var
        MiscTempFile: Record "CDC Temp File" temporary;
        ReadStream: InStream;
        CryptographyManagement: Codeunit "CDC Cryptography Management";
    begin
        IF Document.HasMiscFile THEN BEGIN
            Document.GetMiscFile(MiscTempFile);
            MiscTempFile.GetDataStream(ReadStream);
            EXIT(CryptographyManagement.GetFileSHA1Hash2(ReadStream));
        END;
    end;

    local procedure CalcHashForXmlFile(Document: Record "CDC Document"): Text[50]
    var
        XmlTempFile: Record "CDC Temp File" temporary;
        ReadStream: InStream;
        CryptographyManagement: Codeunit "CDC Cryptography Management";
    begin
        IF Document.HasXmlFile THEN BEGIN
            Document.GetXmlFile(XmlTempFile);
            XmlTempFile.GetDataStream(ReadStream);
            EXIT(CryptographyManagement.GetFileSHA1Hash2(ReadStream));
        END;
    end;

    internal procedure LogDocumentHashRecalculated(Document: Record "CDC Document"; OldHash: Text[50])
    begin
        // IF DocumentLoggingEnabled THEN BEGIN
        //     AddDocumentLogEntry(Document."No.", '', '', STRSUBSTNO(DocHashUpdated, OldHash, Document."File Hash"), DocumentLogEntryTypes.GetEntryTypeCode(DocumentLogEntryTypes."Entry Type"::HashRecalc), 0, 0, '');
    END;


    internal procedure DocAndTemplate(): Text[80]
    begin
        EXIT('Document and Templates');
    end;

    internal procedure TempFileStorageClear()
    var
        TempFileSystem: Record "CDC Temp File" temporary;
        DeleteProhibited: Boolean;
    begin
        IF DeleteProhibited THEN
            EXIT;

        TempFileSystem.RESET;
        TempFileSystem.DELETEALL(TRUE);
    end;

    procedure TiffSplit(var TempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer; HideError: Boolean) Success: Boolean
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
        if not DCADVFileAPIJsonOBj.SplitTiff_Request(jsonObject, TempFile, Rec."Document Category Code") then
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


    procedure PDFSplit(var TempFile: Record "CDC Temp File" temporary; var TempNewFile1: Record "CDC Temp File" temporary; var TempNewFile2: Record "CDC Temp File" temporary; SplitAtPageNo: Integer; HideError: Boolean) Succes: Boolean
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
        if not DCADVFileAPIJsonOBj.SplitPDF_Request(jsonObject, TempFile, Rec."Document Category Code") then
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



    procedure TiffCombine(var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
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
        if not DCADVFileAPIJsonOBj.MergeTiff_Request(jsonObject, TempFile1, TempFile2, Rec."Document Category Code") then
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


    procedure PDFCombine(var TempFile1: Record "CDC Temp File" temporary; var TempFile2: Record "CDC Temp File" temporary; var TempNewFile: Record "CDC Temp File" temporary; HideError: Boolean) Success: Boolean
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
        if not DCADVFileAPIJsonOBj.MergePDF_Request(jsonObject, TempFile1, TempFile2, Rec."Document Category Code") then
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