namespace DefaultPublisher.StickyNoteNotes;

permissionset 61519 "SN NOTES - EDIT"
{
    Assignable = true;
    Caption = 'SN NOTES - EDIT';
    Permissions =
        tabledata "SN Note" = RIMD,
        tabledata "SN Note Audience" = RIMD,
        page "SN Note List" = X,
        page "SN Note Card" = X,
        page "SN Note Audience" = X,
        codeunit "SN Note Manager" = X;
}
