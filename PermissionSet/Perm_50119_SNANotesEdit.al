namespace DefaultPublisher.StickyNoteNotes;

permissionset 50119 "SNA NOTES, EDIT"
{
    Assignable = true;
    Caption = 'Sticky Notes, Edit';
    Permissions =
        tabledata "SNA Note" = RIMD,
        page "SNA Note List" = X,
        page "SNA Note Card" = X,
        codeunit "SNA Note Manager" = X;
}
