pageextension 63061 "DCADV Doc.Capt. Setup Card Ext" extends "CDC Document Capture Setup"
{
    layout
    {
        addafter("Purch: Amount Valid. on Post.")
        {

            field("API Url"; Rec."API Url")
            {
                ApplicationArea = All;
                ToolTip = 'The URL to the DC File API Webservice.';
            }
            field("Save requests"; Rec."Debug requests")
            {
                ApplicationArea = All;
                ToolTip = 'If this field is checked, the request to the DC File API will be saved and downloaded to the users client.';
            }
        }
    }
    actions
    {
        addbefore(ContiniaHub)
        {
            action(DCFileAPITestConnection)
            {
                ApplicationArea = All;
                Image = LinkWeb;
                Promoted = true;
                PromotedCategory = Category5;

                trigger OnAction()
                var
                    ApiMgt: codeunit "DCADV File API Management";
                begin
                    ApiMgt.TestConnection_Request();
                end;
            }
        }
    }
}
