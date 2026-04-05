namespace DefaultPublisher.StickyNoteNotes;

using System.Security.User;
using System.Security.AccessControl;

page 61502 "SN Note Audience"
{
    Caption = 'Show Only To';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "SN Note Audience";

    layout
    {
        area(Content)
        {
            repeater(AudienceList)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a user who can see this sticky note.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                    begin
                        if Page.RunModal(Page::"User Lookup", User) = Action::LookupOK then begin
                            Rec."User ID" := User."User Name";
                            Text := User."User Name";
                            exit(true);
                        end;
                    end;
                }
            }
        }
    }
}
