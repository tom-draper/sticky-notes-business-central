namespace DefaultPublisher.StickyNoteNotes;

using System.Utilities;

page 50100 "SN Note List"
{
    Caption = 'Sticky Notes';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "SN Note";
    Editable = false;
    CardPageId = "SN Note Card";

    layout
    {
        area(Content)
        {
            repeater(Notes)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Note entry number.';
                }
                field("Target Table"; Rec."Target Table")
                {
                    ApplicationArea = All;
                    Caption = 'Target Type';
                    ToolTip = 'Specifies what kind of record this Note is for.';
                }
                field("Record No."; Rec."Record No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the record number this Note is attached to.';
                }
                field("Target Record Description"; Rec."Target Record Description")
                {
                    ApplicationArea = All;
                    Caption = 'Target';
                    ToolTip = 'Specifies which record this Note is attached to.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Note message text.';
                }
                field(Color; Rec.Color)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the colour of the sticky note.';
                }
                field(Style; Rec.Style)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies where the sticky note is displayed. Banner shows as a native notification at the top of the page. Pop Up floats in the top-right corner.';
                }
                field("Scheduled From"; Rec."Scheduled From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the Note becomes visible. Leave blank to show immediately.';
                }
                field("Expires At"; Rec."Expires At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the Note automatically stops showing. Leave blank for no expiry.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the Note is active.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the Note.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the Note was created.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteNote)
            {
                Caption = 'Delete';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Delete the selected sticky note Note.';

                trigger OnAction()
                begin
                    if Confirm('Delete the selected Note?', false) then
                        Rec.Delete(true);
                end;
            }
            action(ToggleActive)
            {
                Caption = 'Toggle Active';
                ApplicationArea = All;
                Image = ToggleBreakpoint;
                ToolTip = 'Activate or deactivate the selected Note.';

                trigger OnAction()
                begin
                    Rec.Active := not Rec.Active;
                    Rec.Modify(true);
                end;
            }
            action(ExportToCSV)
            {
                Caption = 'Export to CSV';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Export all visible sticky notes to a CSV file.';

                trigger OnAction()
                var
                    Note: Record "SN Note";
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    InStream: InStream;
                    CsvLine: Text;
                    FileName: Text;
                    CrChar: Char;
                    LfChar: Char;
                    CrLf: Text;
                begin
                    CrChar := 13;
                    LfChar := 10;
                    CrLf := Format(CrChar) + Format(LfChar);

                    TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);

                    OutStream.WriteText('Entry No.,Target Type,Record No.,Target,Message,Color,Style,Scheduled From,Expires At,Active,Created By,Created At' + CrLf);

                    Note.CopyFilters(Rec);
                    if Note.FindSet() then
                        repeat
                            CsvLine :=
                                Format(Note."Entry No.") + ',' +
                                CsvField(Format(Note."Target Table")) + ',' +
                                CsvField(Note."Record No.") + ',' +
                                CsvField(Note."Target Record Description") + ',' +
                                CsvField(Note.Message) + ',' +
                                CsvField(Format(Note.Color)) + ',' +
                                CsvField(Format(Note.Style)) + ',' +
                                Format(Note."Scheduled From") + ',' +
                                Format(Note."Expires At") + ',' +
                                Format(Note.Active) + ',' +
                                CsvField(Note."Created By") + ',' +
                                Format(Note."Created At");
                            OutStream.WriteText(CsvLine + CrLf);
                        until Note.Next() = 0;

                    TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
                    FileName := 'StickyNotes.csv';
                    DownloadFromStream(InStream, '', '', 'CSV Files (*.csv)|*.csv', FileName);
                end;
            }
        }
        area(Promoted)
        {
            // actionref(NewStickyNote_Promoted; NewStickyNote) { }
            // actionref(EditStickyNote_Promoted; EditStickyNote) { }
            actionref(DeleteNote_Promoted; DeleteNote) { }
            actionref(ToggleActive_Promoted; ToggleActive) { }
            actionref(ExportToCSV_Promoted; ExportToCSV) { }
        }
    }

    local procedure CsvField(Value: Text): Text
    begin
        exit('"' + Value.Replace('"', '""') + '"');
    end;
}
