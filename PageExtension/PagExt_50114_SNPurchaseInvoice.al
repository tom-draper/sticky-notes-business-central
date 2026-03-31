namespace DefaultPublisher.StickyNoteNotes;

using Microsoft.Purchases.Document;

pageextension 50114 "SN Purchase Invoice Ext" extends "Purchase Invoice"
{
    layout
    {
        addLast(content)
        {
            group(GrpStickyNotes)
            {
                ShowCaption = false;

                usercontrol(StickyNoteAddIn; "SN Sticky Note")
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady()
                    begin
                        LoadNotes();
                    end;

                    trigger OnDismissed(EntryNo: Integer)
                    begin
                    end;
                }
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            group(StickyNotes)
            {
                Caption = 'Sticky Notes';
                Image = Note;

                action(NewStickyNote)
                {
                    Caption = 'New Sticky Note';
                    ApplicationArea = All;
                    Image = "Invoicing-MDL-New";
                    ToolTip = 'Create a new sticky note for this purchase invoice.';

                    trigger OnAction()
                    var
                        NewNote: Record "SN Note";
                        NoteCard: Page "SN Note Card";
                    begin
                        NewNote.Init();
                        NewNote."Target Table ID" := Database::"Purchase Header";
                        NewNote."Target System ID" := Rec.SystemId;
                        NewNote."Target Table" := Enum::"SN Target Table"::"Purchase Invoice";
                        NewNote."Target Record Description" := CopyStr('Purchase Invoice ' + Rec."No." + ' - ' + Rec."Buy-from Vendor Name", 1, MaxStrLen(NewNote."Target Record Description"));
                        NewNote."Record No." := Rec."No.";
                        NewNote.Insert(true);
                        Commit();
                        NoteCard.SetRecord(NewNote);
                        NoteCard.RunModal();
                        LoadNotes();
                    end;
                }
                action(ViewStickyNotes)
                {
                    Caption = 'Sticky Notes';
                    ApplicationArea = All;
                    Image = Note;
                    ToolTip = 'View all sticky notes for this purchase invoice.';

                    trigger OnAction()
                    var
                        NoteList: Page "SN Note List";
                        Note: Record "SN Note";
                        NoteManager: Codeunit "SN Note Manager";
                    begin
                        Note.SetRange("Target Table ID", Database::"Purchase Header");
                        Note.SetRange("Target System ID", Rec.SystemId);
                        NoteList.SetTableView(Note);
                        NoteList.RunModal();
                        NoteManager.ShowMainNotes(Database::"Purchase Header", Rec.SystemId, SentNotificationIds);
                        LoadNotes();
                    end;
                }
            }
        }
    }

    var
        SentNotificationIds: List of [Guid];

    trigger OnAfterGetRecord()
    var
        NoteManager: Codeunit "SN Note Manager";
    begin
        NoteManager.ShowMainNotes(Database::"Purchase Header", Rec.SystemId, SentNotificationIds);
        LoadNotes();
    end;

    local procedure LoadNotes()
    var
        NoteManager: Codeunit "SN Note Manager";
        NotesJson: Text;
    begin
        NotesJson := NoteManager.GetActiveNotesJson(Database::"Purchase Header", Rec.SystemId);
        CurrPage.StickyNoteAddIn.ShowNotes(NotesJson);
    end;
}
