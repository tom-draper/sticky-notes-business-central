namespace DefaultPublisher.StickyNoteNotes;

using Microsoft.Inventory.Transfer;

pageextension 50115 "SN Transfer Order Ext" extends "Transfer Order"
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
                    ToolTip = 'Create a new sticky note for this transfer order.';

                    trigger OnAction()
                    var
                        NewNote: Record "SN Note";
                        NoteCard: Page "SN Note Card";
                        NoteManager: Codeunit "SN Note Manager";
                    begin
                        NewNote.Init();
                        NewNote."Target Table ID" := Database::"Transfer Header";
                        NewNote."Target System ID" := Rec.SystemId;
                        NewNote."Target Table" := NoteManager.TableIdToTargetTableEnum(Database::"Transfer Header");
                        NewNote."Target Record Description" := CopyStr('Transfer ' + Rec."No." + ' - ' + Rec."Transfer-from Code" + ' → ' + Rec."Transfer-to Code", 1, MaxStrLen(NewNote."Target Record Description"));
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
                    ToolTip = 'View all sticky notes for this transfer order.';

                    trigger OnAction()
                    var
                        NoteList: Page "SN Note List";
                        Note: Record "SN Note";
                        NoteManager: Codeunit "SN Note Manager";
                    begin
                        Note.SetRange("Target Table ID", Database::"Transfer Header");
                        Note.SetRange("Target System ID", Rec.SystemId);
                        NoteList.SetTableView(Note);
                        NoteList.RunModal();
                        NoteManager.ShowMainNotes(Database::"Transfer Header", Rec.SystemId, SentNotificationIds);
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
        NoteManager.ShowMainNotes(Database::"Transfer Header", Rec.SystemId, SentNotificationIds);
        LoadNotes();
    end;

    local procedure LoadNotes()
    var
        NoteManager: Codeunit "SN Note Manager";
        NotesJson: Text;
    begin
        NotesJson := NoteManager.GetActiveNotesJson(Database::"Transfer Header", Rec.SystemId);
        CurrPage.StickyNoteAddIn.ShowNotes(NotesJson);
    end;
}
