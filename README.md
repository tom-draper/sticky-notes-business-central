# Sticky Notes for Business Central

**Annotate Microsoft Dynamics 365 Business Central** with sticky notes shared across all users. Notes are attached to individual records/pages to share information and alert other users.

Notes appear as draggable pop-up cards or native banner notifications, with support for colours, scheduling, and expiry.

<img width="1431" height="913" alt="Customer-Card-40000-∙-Alpine-Ski-House-03-31-2026_09_47_AM" src="https://github.com/user-attachments/assets/433adb36-4c8d-41a1-bcf0-542bd98768a0" />

<br></br>

<img width="1425" height="390" alt="image" src="https://github.com/user-attachments/assets/a40e80d5-4b85-4950-9d24-dc6f4fd8a667" />

## Features

- **Two display styles**
  - **Pop Up** - floating card in the top-right corner of the page, draggable and dismissible per session
  - **Banner** - native BC notification bar at the top of the page
- **Five colours** - Yellow, Red, Blue, Green, Pink
- **Scheduling** - set a Scheduled From date/time so a note only appears from a certain point
- **Expiry** - set an *Expires At* date/time to automatically hide a note after a deadline
- **Active toggle** - quickly enable or disable a note without deleting it
- **Audit fields** - every note records who created it and when

## Supported Pages

Sticky notes can be created and viewed on the following record cards:

| Area | Pages |
|---|---|
| Sales | Customer Card, Sales Order, Sales Quote, Sales Invoice |
| Purchasing | Vendor Card, Purchase Order, Purchase Invoice |
| Inventory | Item Card, Transfer Order, Location Card |
| Finance | Bank Account Card, G/L Account Card |
| HR & Assets | Employee Card, Fixed Asset Card |
| Projects | Resource Card, Project Card |
| CRM | Contact Card |
| Service | Service Order |

## Requirements

- Business Central 2025 Wave 1 (platform 27.x) or later

## Installation

1. Download the `.app` file from the releases page.
2. In Business Central, go to **Extension Management** and upload the `.app` file, or publish it via the AL extension in VS Code.

## Usage

On any supported record card:

1. Open the **Processing** action menu and find the **Sticky Notes** group.
2. Click **New Sticky Note** to create a note for the current record.
3. Set the message, colour, position (Pop Up or Banner), and optional schedule/expiry.
4. Click **OK** - the note appears immediately on the page.
5. Click **Sticky Notes** to view, toggle, or delete existing notes for the record.

A global list of all notes is available by searching for **Sticky Notes** in the BC search bar (Tell Me).

## Development

Built with AL for Business Central. No external dependencies.

```
Publisher:  Tom Draper
Version:    1.0.0.0
ID range:   50100–50149
Runtime:    16.0
```

To build locally, open the workspace in VS Code with the AL Language extension installed and press `F5` to publish to a sandbox.
