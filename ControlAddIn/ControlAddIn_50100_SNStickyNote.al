namespace DefaultPublisher.StickyNoteNotes;

controladdin "SN Sticky Note"
{
    StartupScript = 'ControlAddIn/startup.js';
    StyleSheets = 'ControlAddIn/StickyNote.css';

    // Zero-height iframe — all rendering is injected into the parent BC page.
    // The iframe exists only to host the JS runtime.
    RequestedHeight = 0;
    MinimumHeight = 0;
    MaximumHeight = 0;
    HorizontalStretch = true;

    /// <summary>
    /// Called from AL to pass a JSON array of Note objects to the add-in.
    /// The add-in renders them as sticky notes and resizes the container accordingly.
    /// </summary>
    procedure ShowNotes(NotesJson: Text);

    /// <summary>
    /// Fired when the add-in has initialised and is ready to receive data.
    /// </summary>
    event ControlAddInReady();

    /// <summary>
    /// Fired when the user clicks the dismiss (X) button on a sticky note.
    /// entryNo is the Note Entry No. — no persistent dismissal is stored;
    /// the note will reappear the next time the page is opened.
    /// </summary>
    event OnDismissed(EntryNo: Integer);
}
