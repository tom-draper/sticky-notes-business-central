namespace DefaultPublisher.StickyNoteNotes;

table 61504 "SN Note Audience"
{
    Caption = 'Sticky Note Audience';
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "Note Entry No."; Integer)
        {
            Caption = 'Note Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "SN Note"."Entry No.";
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Note Entry No.", "User ID")
        {
            Clustered = true;
        }
    }
}
