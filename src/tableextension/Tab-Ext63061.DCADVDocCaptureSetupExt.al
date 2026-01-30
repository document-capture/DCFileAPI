tableextension 63061 "DCADV Doc.Capture Setup Ext" extends "CDC Document Capture Setup"
{
    fields
    {
        field(63060; "API Url"; Text[250])
        {
            Caption = 'API Url';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                WrongStorageType: Label 'API Url can only be set if Document Storage Type is %1 or %2', Comment = '%1 = File Service, %2 = Database';
            begin
                // Make sure that Document Storage Type is File Service or Database when setting up the API Url
                if Rec."API Url" <> '' then
                    if not (Rec."Document Storage Type" in [Rec."Document Storage Type"::"File Service", Rec."Document Storage Type"::Database]) then
                        Error(WrongStorageType, Rec."Document Storage Type"::"File Service", Rec."Document Storage Type"::Database);
            end;
        }

        field(63062; "Debug requests"; Boolean)
        {
            Caption = 'Debug requests';
            DataClassification = CustomerContent;
        }
    }
    trigger OnBeforeModify()
    var
        EmptyFileApiUrl: Label 'The field value of %1 must be empty when you set the Document Storage Type to %2 or %3', Comment = '%1 = API Url, %2 = File Service, %3 = Database';
    begin
        // Make sure that API Url is only set when Document Storage Type is File Service or Database
        if Rec."Document Storage Type" <> xRec."Document Storage Type" then begin
            if not (Rec."Document Storage Type" in [Rec."Document Storage Type"::"File Service", Rec."Document Storage Type"::Database]) then
                Error(EmptyFileApiUrl, Rec.FieldCaption("API Url"), Rec."Document Storage Type"::"File Service", Rec."Document Storage Type"::Database);
        end;
    end;

}
