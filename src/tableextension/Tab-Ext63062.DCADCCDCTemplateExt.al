tableextension 63062 "DCADC CDC Template Ext." extends "CDC Template"
{
    fields
    {
        field(63060; "XML Stylesheet File Copy"; BLOB)
        {
            Caption = 'XML Stylesheet File Clone';
            Description = 'This field is used to store a copy of the XML stylesheet file from default table.';
            DataClassification = CustomerContent;
        }
    }
}
