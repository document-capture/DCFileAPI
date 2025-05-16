pageextension 63060 "DCADV Doc List with Image Ext" extends "CDC Document List With Image"
{
    layout
    {
        addafter("No. of Pages")
        {
            field(HasPngData; DocumentHasPngFile(Rec."No."))
            {
                ApplicationArea = All;
                Caption = 'Has Png Data';
                ToolTip = 'Shows if the Document has png data';
                Visible = false;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter("Split and Merge")
        {
            action(CreatePngFromTiffViaFileAPI)
            {
                ApplicationArea = All;
                Caption = 'Create Png via API';
                ToolTip = 'Create png preview files for selected document through the DC File API.';
                Visible = false;
                Enabled = NeedsLocalServices;
                Image = New;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    DCFileApiMgt.CreatePngFromTiffViaFileAPI(Rec);
                end;
            }

            action("Split and Merge local")
            {
                ApplicationArea = All;
                Caption = 'Split and Merge (local)';
                ToolTip = 'Open the Split and Merge Documents page to delete, rotate, or change the order of individual pages in the PDF file.', Comment = 'Translation note: Please use the Search TM function to find the right term for "Split and Merge Documents".';
                Visible = NeedsLocalServices;
                Enabled = NeedsLocalServices;
                Image = Splitlines;
                Promoted = true;
                PromotedCategory = Category5;

                trigger OnAction()
                var
                    WebClientMgt: Codeunit "CDC Web Client Management";
                    SplitAndMerge: Page "DCADV Split and Merge local";
                begin
                    SplitAndMerge.SetParam(CurrentDocCategory, Rec);
                    IF WebClientMgt.IsWebClient THEN
                        SplitAndMerge.RUN
                    ELSE
                        SplitAndMerge.RUNMODAL;

                    IF NOT WebClientMgt.IsWebClient THEN BEGIN
                        CurrPage.UPDATE(FALSE);
                        IF Rec.FIND('=') THEN
                            CurrPage.CaptureUI.PAGE.UpdatePage;
                    END;
                end;
            }
        }
        modify("Split and Merge")
        {
            Enabled = not NeedsLocalServices;
            Visible = not NeedsLocalServices;
        }
    }

    var
        DCFileApiMgt: Codeunit "DCADV File API Management";

    trigger OnOpenPage()
    var

        DCSetup: Record "CDC Document Capture Setup";


    begin
        if DCSetup.Get() then begin
            NeedsLocalServices := DCSetup."API Url" <> '';

        end;

        Rec.FILTERGROUP := 2;
        IF Rec.GETFILTER(Rec."Document Category Code") <> '' THEN
            CurrentDocCategory := Rec.GETRANGEMAX("Document Category Code");
        Rec.FILTERGROUP := 0;
    end;

    local procedure DocumentHasPngFile(DocumentNo: Code[20]): Boolean
    var
        DocumentPage: Record "CDC Document Page";
    begin
        if not DocumentPage.Get(DocumentNo, 1) then
            exit;

        exit(DocumentPage.HasPngFile());
    end;

    var
        NeedsLocalServices: Boolean;

        CurrentDocCategory: Text;
}
