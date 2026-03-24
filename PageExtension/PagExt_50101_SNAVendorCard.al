namespace DefaultPublisher.StickyNoteNotes;

using Microsoft.Purchases.Vendor;

pageextension 50101 "SNA Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addLast(content)
        {
            group(GrpStickyNotes)
            {
                ShowCaption = false;

                usercontrol(StickyNoteAddIn; "SNA Sticky Note")
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
                    ToolTip = 'Create a new sticky note for this vendor.';

                    trigger OnAction()
                    var
                        NewNote: Record "SNA Note";
                        NoteCard: Page "SNA Note Card";
                        NoteManager: Codeunit "SNA Note Manager";
                    begin
                        NewNote.Init();
                        NewNote."Target Table ID" := Database::Vendor;
                        NewNote."Target System ID" := Rec.SystemId;
                        NewNote."Target Table" := NoteManager.TableIdToTargetTableEnum(Database::Vendor);
                        NewNote."Target Record Description" := CopyStr(Rec."No." + ' - ' + Rec.Name, 1, MaxStrLen(NewNote."Target Record Description"));
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
                    ToolTip = 'View all sticky notes for this vendor.';

                    trigger OnAction()
                    var
                        NoteList: Page "SNA Note List";
                        Note: Record "SNA Note";
                        NoteManager: Codeunit "SNA Note Manager";
                    begin
                        Note.SetRange("Target Table ID", Database::Vendor);
                        Note.SetRange("Target System ID", Rec.SystemId);
                        NoteList.SetTableView(Note);
                        NoteList.RunModal();
                        NoteManager.ShowMainNotes(Database::Vendor, Rec.SystemId, SentNotificationIds);
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
        NoteManager: Codeunit "SNA Note Manager";
    begin
        NoteManager.ShowMainNotes(Database::Vendor, Rec.SystemId, SentNotificationIds);
        LoadNotes();
    end;

    local procedure LoadNotes()
    var
        NoteManager: Codeunit "SNA Note Manager";
        NotesJson: Text;
    begin
        NotesJson := NoteManager.GetActiveNotesJson(Database::Vendor, Rec.SystemId);
        CurrPage.StickyNoteAddIn.ShowNotes(NotesJson);
    end;
}
