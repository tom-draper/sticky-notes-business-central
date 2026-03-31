namespace DefaultPublisher.StickyNoteNotes;

permissionset 61519 "SN NOTES, EDIT"
{
    Assignable = true;
    Caption = 'Sticky Notes, Edit';
    Permissions =
        tabledata "SN Note" = RIMD,
        page "SN Note List" = X,
        page "SN Note Card" = X,
        codeunit "SN Note Manager" = X;
}
