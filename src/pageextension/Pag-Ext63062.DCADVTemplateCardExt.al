pageextension 63062 "DCADV Template Card Ext" extends "CDC Template Card"
{
    layout
    {
        addafter("Show Embedded PDF as Default")
        {
            field("XML Stylesheet File Copy"; Rec."XML Stylesheet File Copy".HasValue)
            {
                ApplicationArea = All;
                Caption = 'DC File API Stylesheet';
                Editable = false;
                Visible = DCFileAPIEnabled;
            }
        }
    }

    actions
    {
        addafter(Xml)
        {
            group(DcFileAPIXml)
            {
                Caption = 'DC File API';
                Enabled = IsMasterTemplate;
                action(CopyDCFileAPIXslt)
                {
                    ApplicationArea = All;
                    Caption = 'Copy Stylesheet';
                    Image = Copy;
                    ToolTip = 'Copy DC File API Stylesheet to this template';
                    Visible = ShowXMLFields AND IsMasterTemplate;

                    trigger OnAction()
                    begin
                        CopyDCFileAPIStylesheet;
                    end;
                }
            }
        }
    }

    var
        IsMasterTemplate: Boolean;
        ShowXMLFields: Boolean;
        DCFileAPIEnabled: Boolean;

    trigger OnOpenPage()
    var
        DCSetup: Record "CDC Document Capture Setup";
    begin
        if DCSetup.Get() then
            DCFileAPIEnabled := DCSetup."API Url" <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        IsMasterTemplate := Rec.Type = Rec.Type::Master;
        ShowXMLFields := Rec."Data Type" = Rec."Data Type"::XML;
    end;

    internal procedure CopyDCFileAPIStylesheet()
    var
        Template: Record "CDC Template";
        TemplateList: Page "CDC Template List Lookup";
        WriteStream: OutStream;
        ReadStream: InStream;
        NoStylesheetInTemplat: Label 'The selected template does not have a DC File API stylesheet file.';
    begin
        // Allow user to select a master XML template to copy the stylesheet from, excluding the current template
        Template.SetRange(Type, Template.Type::Master);
        Template.SetRange("Data Type", Template."Data Type"::XML);
        Template.SetFilter("No.", '<>%1', Rec."No.");
        TemplateList.SetTableView(Template);
        TemplateList.LookupMode(true);
        if TemplateList.RunModal() = ACTION::LookupOK then begin
            TemplateList.GetRecord(Template);
            Template.CalcFields("XML Stylesheet File Copy");
            // Ensure the selected template has a stylesheet file to copy
            if NOT Template."XML Stylesheet File Copy".HASVALUE then begin
                Message(NoStylesheetInTemplat);
                exit;
            end;
            // Copy the stylesheet file from the selected template to the current template
            Rec."XML Stylesheet File Copy".CreateOutStream(WriteStream);
            Template."XML Stylesheet File Copy".CreateInStream(ReadStream);
            CopyStream(WriteStream, ReadStream);
            Rec."XML Stylesheet File Extension" := Template."XML Stylesheet File Extension";
            Rec."XML Stylesheet Main Filename" := Template."XML Stylesheet Main Filename";
            Rec."XML Stylesheet Main Filename C" := Template."XML Stylesheet Main Filename C";
            Rec.Modify(true);
            CurrPage.Update();
        end;
    end;
}
