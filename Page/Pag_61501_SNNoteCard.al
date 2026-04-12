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

page 61501 "SN Note Card"
{
    Caption = 'Sticky Note';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "SN Note";
    DataCaptionExpression = NotePageCaption;

    layout
    {
        area(Content)
        {
            group(GrpTarget)
            {
                Caption = 'Target';

                // Step 1: pick a type — hidden when opened from a page action
                field(TargetTypeField; Rec."Target Table")
                {
                    ApplicationArea = All;
                    Caption = 'Target Type';
                    ToolTip = 'Specifies what kind of record this Note is for.';
                    Visible = not IsTargetPreset;

                    trigger OnValidate()
                    begin
                        ClearTargetRecord();
                        ShowRecordLookup := Rec."Target Table" <> Enum::"SN Target Table"::" ";
                        CurrPage.Update(true);
                    end;
                }

                // Step 2: pick the specific record — always visible once a type is chosen
                field(RecordNoField; Rec."Record No.")
                {
                    ApplicationArea = All;
                    Caption = 'Record No.';
                    ToolTip = 'Enter or look up the specific record to attach this Note to.';
                    Visible = not IsTargetPreset;
                    Editable = ShowRecordLookup;

                    trigger OnValidate()
                    begin
                        ValidateRecordNo();
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupRecord(Text));
                    end;
                }

                // Read-only confirmation of the chosen record
                field(TargetDescriptionField; TargetDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Target Record';
                    Editable = false;
                    ToolTip = 'Shows the record this Note is attached to.';
                }
            }

            group(GrpDetails)
            {
                Caption = 'Note Details';

                field(MessageField; Rec.Message)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Specifies the Note message shown on the sticky note.';
                }
                field(ColorField; Rec.Color)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the colour of the sticky note.';
                }
                field(StyleField; Rec.Style)
                {
                    ApplicationArea = All;
                    ToolTip = 'Banner shows as a native notification at the top of the page. Pop Up floats in the top-right corner of the screen.';
                }
                field(ScheduledFromField; Rec."Scheduled From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the Note becomes visible. Leave blank to show immediately.';
                }
                field(ExpiresAtField; Rec."Expires At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the Note automatically stops showing. Leave blank for no expiry.';
                }
                field(ActiveField; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the Note is currently active.';
                }
            }

            group(GrpAudience)
            {
                Caption = 'Show Only To';

                part(AudiencePart; "SN Note Audience")
                {
                    ApplicationArea = All;
                    SubPageLink = "Note Entry No." = field("Entry No.");
                    ToolTip = 'Add users to restrict who can see this note. Leave empty to show to all users.';
                }
            }

            group(GrpAudit)
            {
                Caption = 'Created';

                field(CreatedByField; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created this Note.';
                }
                field(CreatedAtField; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this Note was created.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // action(ToggleActive)
            // {
            //     Caption = 'Toggle Active';
            //     ApplicationArea = All;
            //     Image = ToggleBreakpoint;
            //     ToolTip = 'Activate or deactivate this Note.';

            //     trigger OnAction()
            //     begin
            //         Rec.Active := not Rec.Active;
            //         Rec.Modify(true);
            //     end;
            // }
        }
        area(Promoted)
        {
            // actionref(ToggleActive_Promoted; ToggleActive) { }
        }
    }

    var
        IsTargetPreset: Boolean;
        ShowRecordLookup: Boolean;
        NotePageCaption: Text;
        TargetDescription: Text[250];
        PresetTableId: Integer;
        PresetSystemId: Guid;
        PresetDescription: Text[250];

    /// <summary>
    /// Called by page extensions to pre-populate the target before RunModal.
    /// Hides the type/record selectors — the user goes straight to the Note details.
    /// </summary>
    procedure SetTargetRecord(TableId: Integer; SystemId: Guid; Description: Text[250])
    begin
        IsTargetPreset := true;
        ShowRecordLookup := false;
        PresetTableId := TableId;
        PresetSystemId := SystemId;
        PresetDescription := Description;
        NotePageCaption := Description;
        TargetDescription := Description;
    end;

    local procedure SetTargetFromRecord(TableId: Integer; SystemId: Guid; RecNo: Code[20]; Description: Text[250])
    var
        NoteManager: Codeunit "SN Note Manager";
    begin
        Rec."Target Table ID" := TableId;
        Rec."Target System ID" := SystemId;
        Rec."Target Record Description" := CopyStr(Description, 1, MaxStrLen(Rec."Target Record Description"));
        Rec."Target Table" := NoteManager.TableIdToTargetTableEnum(TableId);
        Rec."Record No." := RecNo;
        NotePageCaption := Description;
        TargetDescription := CopyStr(Description, 1, MaxStrLen(TargetDescription));
    end;

    trigger OnOpenPage()
    begin
        if IsTargetPreset then
            Rec.SetFilter("Entry No.", '%1', 0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        NoteManager: Codeunit "SN Note Manager";
    begin
        if IsTargetPreset then begin
            Rec."Target Table ID" := PresetTableId;
            Rec."Target System ID" := PresetSystemId;
            Rec."Target Record Description" := PresetDescription;
            Rec."Target Table" := NoteManager.TableIdToTargetTableEnum(PresetTableId);
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Entry No." <> 0 then begin
            TargetDescription := Rec."Target Record Description";
            NotePageCaption := Rec."Target Record Description";
            ShowRecordLookup := Rec."Target Table" <> Enum::"SN Target Table"::" ";
        end;
    end;

    local procedure ClearTargetRecord()
    begin
        Clear(Rec."Record No.");
        Clear(Rec."Target Table ID");
        Clear(Rec."Target System ID");
        Clear(Rec."Target Record Description");
        Clear(NotePageCaption);
        Clear(TargetDescription);
    end;

    local procedure ValidateRecordNo()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        BankAccount: Record "Bank Account";
        Empl: Record Employee;
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        Res: Record Resource;
        Job: Record Job;
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        Location: Record Location;
    begin
        case Rec."Target Table" of
            Enum::"SN Target Table"::Customer:
                begin
                    Customer.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Customer, Customer.SystemId, Customer."No.",
                        Customer."No." + ' - ' + Customer.Name);
                end;
            Enum::"SN Target Table"::Vendor:
                begin
                    Vendor.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Vendor, Vendor.SystemId, Vendor."No.",
                        Vendor."No." + ' - ' + Vendor.Name);
                end;
            Enum::"SN Target Table"::Item:
                begin
                    Item.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Item, Item.SystemId, Item."No.",
                        Item."No." + ' - ' + Item.Description);
                end;
            Enum::"SN Target Table"::Contact:
                begin
                    Contact.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Contact, Contact.SystemId, Contact."No.",
                        Contact."No." + ' - ' + Contact.Name);
                end;
            Enum::"SN Target Table"::"Sales Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Record No.");
                    SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                        'Sales Order ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                end;
            Enum::"SN Target Table"::"Purchase Order":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Record No.");
                    SetTargetFromRecord(Database::"Purchase Header", PurchaseHeader.SystemId, PurchaseHeader."No.",
                        'Purchase Order ' + PurchaseHeader."No." + ' - ' + PurchaseHeader."Buy-from Vendor Name");
                end;
            Enum::"SN Target Table"::"Bank Account":
                begin
                    BankAccount.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::"Bank Account", BankAccount.SystemId, BankAccount."No.",
                        BankAccount."No." + ' - ' + BankAccount.Name);
                end;
            Enum::"SN Target Table"::Employee:
                begin
                    Empl.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Employee, Empl.SystemId, Empl."No.",
                        Empl."No." + ' - ' + Empl."First Name" + ' ' + Empl."Last Name");
                end;
            Enum::"SN Target Table"::"Fixed Asset":
                begin
                    FixedAsset.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::"Fixed Asset", FixedAsset.SystemId, FixedAsset."No.",
                        FixedAsset."No." + ' - ' + FixedAsset.Description);
                end;
            Enum::"SN Target Table"::"G/L Account":
                begin
                    GLAccount.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::"G/L Account", GLAccount.SystemId, GLAccount."No.",
                        GLAccount."No." + ' - ' + GLAccount.Name);
                end;
            Enum::"SN Target Table"::Resource:
                begin
                    Res.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Resource, Res.SystemId, Res."No.",
                        Res."No." + ' - ' + Res.Name);
                end;
            Enum::"SN Target Table"::Job:
                begin
                    Job.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Job, Job.SystemId, Job."No.",
                        Job."No." + ' - ' + Job.Description);
                end;
            Enum::"SN Target Table"::"Sales Quote":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Quote, Rec."Record No.");
                    SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                        'Sales Quote ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                end;
            Enum::"SN Target Table"::"Sales Invoice":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Record No.");
                    SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                        'Sales Invoice ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                end;
            Enum::"SN Target Table"::"Purchase Invoice":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, Rec."Record No.");
                    SetTargetFromRecord(Database::"Purchase Header", PurchaseHeader.SystemId, PurchaseHeader."No.",
                        'Purchase Invoice ' + PurchaseHeader."No." + ' - ' + PurchaseHeader."Buy-from Vendor Name");
                end;
            Enum::"SN Target Table"::"Transfer Order":
                begin
                    TransferHeader.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::"Transfer Header", TransferHeader.SystemId, TransferHeader."No.",
                        'Transfer ' + TransferHeader."No." + ' - ' + TransferHeader."Transfer-from Code" + ' → ' + TransferHeader."Transfer-to Code");
                end;
            Enum::"SN Target Table"::"Service Order":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Order, Rec."Record No.");
                    SetTargetFromRecord(Database::"Service Header", ServiceHeader.SystemId, ServiceHeader."No.",
                        'Service Order ' + ServiceHeader."No." + ' - ' + ServiceHeader.Name);
                end;
            Enum::"SN Target Table"::Location:
                begin
                    Location.Get(Rec."Record No.");
                    SetTargetFromRecord(Database::Location, Location.SystemId, Location.Code,
                        Location.Code + ' - ' + Location.Name);
                end;
        end;
    end;

    local procedure LookupRecord(var Text: Text): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        BankAccount: Record "Bank Account";
        Empl: Record Employee;
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        Res: Record Resource;
        Job: Record Job;
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        Location: Record Location;
    begin
        case Rec."Target Table" of
            Enum::"SN Target Table"::Customer:
                if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then begin
                    Rec."Record No." := Customer."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Customer, Customer.SystemId, Customer."No.",
                        Customer."No." + ' - ' + Customer.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::Vendor:
                if Page.RunModal(Page::"Vendor List", Vendor) = Action::LookupOK then begin
                    Rec."Record No." := Vendor."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Vendor, Vendor.SystemId, Vendor."No.",
                        Vendor."No." + ' - ' + Vendor.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::Item:
                if Page.RunModal(Page::"Item List", Item) = Action::LookupOK then begin
                    Rec."Record No." := Item."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Item, Item.SystemId, Item."No.",
                        Item."No." + ' - ' + Item.Description);
                    exit(true);
                end;
            Enum::"SN Target Table"::Contact:
                if Page.RunModal(Page::"Contact List", Contact) = Action::LookupOK then begin
                    Rec."Record No." := Contact."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Contact, Contact.SystemId, Contact."No.",
                        Contact."No." + ' - ' + Contact.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::"Sales Order":
                begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                    if Page.RunModal(Page::"Sales Order List", SalesHeader) = Action::LookupOK then begin
                        Rec."Record No." := SalesHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                            'Sales Order ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::"Purchase Order":
                begin
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                    if Page.RunModal(Page::"Purchase Order List", PurchaseHeader) = Action::LookupOK then begin
                        Rec."Record No." := PurchaseHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Purchase Header", PurchaseHeader.SystemId, PurchaseHeader."No.",
                            'Purchase Order ' + PurchaseHeader."No." + ' - ' + PurchaseHeader."Buy-from Vendor Name");
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::"Bank Account":
                if Page.RunModal(Page::"Bank Account List", BankAccount) = Action::LookupOK then begin
                    Rec."Record No." := BankAccount."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::"Bank Account", BankAccount.SystemId, BankAccount."No.",
                        BankAccount."No." + ' - ' + BankAccount.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::Employee:
                if Page.RunModal(Page::"Employee List", Empl) = Action::LookupOK then begin
                    Rec."Record No." := Empl."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Employee, Empl.SystemId, Empl."No.",
                        Empl."No." + ' - ' + Empl."First Name" + ' ' + Empl."Last Name");
                    exit(true);
                end;
            Enum::"SN Target Table"::"Fixed Asset":
                if Page.RunModal(Page::"Fixed Asset List", FixedAsset) = Action::LookupOK then begin
                    Rec."Record No." := FixedAsset."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::"Fixed Asset", FixedAsset.SystemId, FixedAsset."No.",
                        FixedAsset."No." + ' - ' + FixedAsset.Description);
                    exit(true);
                end;
            Enum::"SN Target Table"::"G/L Account":
                if Page.RunModal(Page::"Chart of Accounts", GLAccount) = Action::LookupOK then begin
                    Rec."Record No." := GLAccount."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::"G/L Account", GLAccount.SystemId, GLAccount."No.",
                        GLAccount."No." + ' - ' + GLAccount.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::Resource:
                if Page.RunModal(Page::"Resource List", Res) = Action::LookupOK then begin
                    Rec."Record No." := Res."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Resource, Res.SystemId, Res."No.",
                        Res."No." + ' - ' + Res.Name);
                    exit(true);
                end;
            Enum::"SN Target Table"::Job:
                if Page.RunModal(Page::"Job List", Job) = Action::LookupOK then begin
                    Rec."Record No." := Job."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Job, Job.SystemId, Job."No.",
                        Job."No." + ' - ' + Job.Description);
                    exit(true);
                end;
            Enum::"SN Target Table"::"Sales Quote":
                begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                    if Page.RunModal(Page::"Sales Quotes", SalesHeader) = Action::LookupOK then begin
                        Rec."Record No." := SalesHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                            'Sales Quote ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::"Sales Invoice":
                begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    if Page.RunModal(Page::"Sales Invoice List", SalesHeader) = Action::LookupOK then begin
                        Rec."Record No." := SalesHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Sales Header", SalesHeader.SystemId, SalesHeader."No.",
                            'Sales Invoice ' + SalesHeader."No." + ' - ' + SalesHeader."Sell-to Customer Name");
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::"Purchase Invoice":
                begin
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
                    if Page.RunModal(Page::"Purchase Invoices", PurchaseHeader) = Action::LookupOK then begin
                        Rec."Record No." := PurchaseHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Purchase Header", PurchaseHeader.SystemId, PurchaseHeader."No.",
                            'Purchase Invoice ' + PurchaseHeader."No." + ' - ' + PurchaseHeader."Buy-from Vendor Name");
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::"Transfer Order":
                if Page.RunModal(Page::"Transfer Orders", TransferHeader) = Action::LookupOK then begin
                    Rec."Record No." := TransferHeader."No.";
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::"Transfer Header", TransferHeader.SystemId, TransferHeader."No.",
                        'Transfer ' + TransferHeader."No." + ' - ' + TransferHeader."Transfer-from Code" + ' → ' + TransferHeader."Transfer-to Code");
                    exit(true);
                end;
            Enum::"SN Target Table"::"Service Order":
                begin
                    ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
                    if Page.RunModal(Page::"Service Orders", ServiceHeader) = Action::LookupOK then begin
                        Rec."Record No." := ServiceHeader."No.";
                        Text := Rec."Record No.";
                        SetTargetFromRecord(Database::"Service Header", ServiceHeader.SystemId, ServiceHeader."No.",
                            'Service Order ' + ServiceHeader."No." + ' - ' + ServiceHeader.Name);
                        exit(true);
                    end;
                end;
            Enum::"SN Target Table"::Location:
                if Page.RunModal(Page::"Location List", Location) = Action::LookupOK then begin
                    Rec."Record No." := Location.Code;
                    Text := Rec."Record No.";
                    SetTargetFromRecord(Database::Location, Location.SystemId, Location.Code,
                        Location.Code + ' - ' + Location.Name);
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
