namespace DefaultPublisher.StickyNoteNotes;

table 50103 "SN Note"
{
    Caption = 'Sticky Note';
    DataClassification = CustomerContent;
    LookupPageId = "SN Note List";
    DrillDownPageId = "SN Note List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Target Table ID"; Integer)
        {
            Caption = 'Target Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Target System ID"; Guid)
        {
            Caption = 'Target System ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Target Record Description"; Text[250])
        {
            Caption = 'Target';
        }
        field(5; Message; Text[2048])
        {
            Caption = 'Message';
        }
        field(6; Color; Enum "SN Note Color")
        {
            Caption = 'Color';
        }
        field(7; "Scheduled From"; DateTime)
        {
            Caption = 'Scheduled From';
        }
        field(8; "Expires At"; DateTime)
        {
            Caption = 'Expires At';
        }
        field(9; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; Active; Boolean)
        {
            Caption = 'Active';
            InitValue = true;
        }
        field(12; Style; Enum "SN Note Style")
        {
            Caption = 'Position';
            InitValue = Popup;
        }
        field(13; "Target Table"; Enum "SN Target Table")
        {
            Caption = 'Target Type';
        }
        field(14; "Record No."; Code[20])
        {
            Caption = 'Record No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByRecord; "Target Table ID", "Target System ID")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec."Created By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Created By"));
        Rec."Created At" := CurrentDateTime();
        Rec.Active := true;
    end;
}
