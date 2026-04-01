namespace DefaultPublisher.StickyNoteNotes;

permissionset 61518 "SN NOTES - VIEW"
{
    Assignable = true;
    Caption = 'SN NOTES - VIEW';
    Permissions =
        tabledata "SN Note" = R,
        page "SN Note List" = X,
        page "SN Note Card" = X,
        codeunit "SN Note Manager" = X;
}
