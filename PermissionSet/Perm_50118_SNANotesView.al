namespace DefaultPublisher.StickyNoteNotes;

permissionset 50118 "SNA NOTES, VIEW"
{
    Assignable = true;
    Caption = 'Sticky Notes, View';
    Permissions =
        tabledata "SNA Note" = R,
        page "SNA Note List" = X,
        page "SNA Note Card" = X,
        codeunit "SNA Note Manager" = X;
}
