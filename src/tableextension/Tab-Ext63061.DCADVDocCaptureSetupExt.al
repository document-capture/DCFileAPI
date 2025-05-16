tableextension 63061 "DCADV Doc.Capture Setup Ext" extends "CDC Document Capture Setup"
{
    fields
    {
        field(63060; "API Url"; Text[250])
        {
            Caption = 'API Url';
            DataClassification = CustomerContent;
        }

        field(63062; "Debug requests"; Boolean)
        {
            Caption = 'Debug requests';
            DataClassification = CustomerContent;
        }
    }
}
