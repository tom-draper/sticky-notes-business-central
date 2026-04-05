namespace DefaultPublisher.StickyNoteNotes;

using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Item;
using Microsoft.CRM.Contact;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.HumanResources.Employee;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Project.Job;
using Microsoft.Inventory.Transfer;
using Microsoft.Service.Document;
using Microsoft.Inventory.Location;

codeunit 61500 "SN Note Manager"
{
    /// <summary>
    /// Returns a JSON array of active, visible Notes for the given record.
    /// Filters by: Active = true, ScheduledFrom &lt;= NOW, ExpiresAt blank or &gt; NOW.
    /// </summary>
    procedure GetActiveNotesJson(TableId: Integer; SystemId: Guid): Text
    var
        Note: Record "SN Note";
        NoteArray: JsonArray;
        NoteObj: JsonObject;
        ResultText: Text;
        NowDT: DateTime;
    begin
        NowDT := CurrentDateTime();
        Note.SetRange("Target Table ID", TableId);
        Note.SetRange("Target System ID", SystemId);
        Note.SetRange(Active, true);

        if Note.FindSet() then
            repeat
                if IsNoteVisible(Note, NowDT) and (Note.Style <> Note.Style::Banner) and IsVisibleToCurrentUser(Note."Entry No.") then begin
                    Clear(NoteObj);
                    NoteObj.Add('entryNo', Note."Entry No.");
                    NoteObj.Add('message', Note.Message);
                    NoteObj.Add('color', Note.Color.AsInteger());
                    NoteObj.Add('createdBy', Note."Created By");
                    NoteObj.Add('createdAt', Format(Note."Created At", 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>'));
                    NoteObj.Add('style', Note.Style.AsInteger());
                    NoteArray.Add(NoteObj);
                end;
            until Note.Next() = 0;

        NoteArray.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Shows native BC page notifications for Main-style Notes on the current page.
    /// Recalls previously sent notifications before sending new ones.
    /// </summary>
    procedure ShowMainNotes(TableId: Integer; SystemId: Guid; var SentIds: List of [Guid])
    var
        Note: Record "SN Note";
        Notif: Notification;
        NowDT: DateTime;
        NotifId: Guid;
    begin
        foreach NotifId in SentIds do begin
            Notif.Id := NotifId;
            Notif.Recall();
        end;
        Clear(SentIds);

        NowDT := CurrentDateTime();
        Note.SetRange("Target Table ID", TableId);
        Note.SetRange("Target System ID", SystemId);
        Note.SetRange(Active, true);
        Note.SetRange(Style, Note.Style::Banner);

        if Note.FindSet() then
            repeat
                if IsNoteVisible(Note, NowDT) and IsVisibleToCurrentUser(Note."Entry No.") then begin
                    Clear(Notif);
                    Notif.Id := Note.SystemId;
                    Notif.Message(Note.Message);
                    Notif.Scope := NotificationScope::LocalScope;
                    Notif.Send();
                    SentIds.Add(Note.SystemId);
                end;
            until Note.Next() = 0;
    end;

    local procedure IsVisibleToCurrentUser(NoteEntryNo: Integer): Boolean
    var
        Audience: Record "SN Note Audience";
    begin
        Audience.SetRange("Note Entry No.", NoteEntryNo);
        if Audience.IsEmpty() then
            exit(true);
        Audience.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(Audience."User ID")));
        exit(not Audience.IsEmpty());
    end;

    local procedure IsNoteVisible(Note: Record "SN Note"; NowDT: DateTime): Boolean
    begin
        if (Note."Scheduled From" <> 0DT) and (NowDT < Note."Scheduled From") then
            exit(false);
        if (Note."Expires At" <> 0DT) and (NowDT > Note."Expires At") then
            exit(false);
        exit(true);
    end;

    /// <summary>
    /// Resolves the SN Target Table enum from a table ID.
    /// </summary>
    procedure TableIdToTargetTableEnum(TableId: Integer): Enum "SN Target Table"
    begin
        case TableId of
            Database::Customer:
                exit(Enum::"SN Target Table"::Customer);
            Database::Vendor:
                exit(Enum::"SN Target Table"::Vendor);
            Database::Item:
                exit(Enum::"SN Target Table"::Item);
            Database::Contact:
                exit(Enum::"SN Target Table"::Contact);
            Database::"Sales Header":
                exit(Enum::"SN Target Table"::"Sales Order");
            Database::"Purchase Header":
                exit(Enum::"SN Target Table"::"Purchase Order");
            Database::"Bank Account":
                exit(Enum::"SN Target Table"::"Bank Account");
            Database::Employee:
                exit(Enum::"SN Target Table"::Employee);
            Database::"Fixed Asset":
                exit(Enum::"SN Target Table"::"Fixed Asset");
            Database::"G/L Account":
                exit(Enum::"SN Target Table"::"G/L Account");
            Database::Resource:
                exit(Enum::"SN Target Table"::Resource);
            Database::Job:
                exit(Enum::"SN Target Table"::Job);
            Database::"Transfer Header":
                exit(Enum::"SN Target Table"::"Transfer Order");
            Database::"Service Header":
                exit(Enum::"SN Target Table"::"Service Order");
            Database::Location:
                exit(Enum::"SN Target Table"::Location);
        end;
        exit(Enum::"SN Target Table"::" ");
    end;
}
