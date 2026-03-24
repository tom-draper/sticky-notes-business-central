(function () {
    'use strict';

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------

    var _Notes        = [];
    var _dismissed     = {};   // entryNo → true  (session-only)
    var _rendered      = {};   // entryNo → DOM element
    var _firstLoadDone = false;
    var _parentDoc     = null;
    var _removalObserver = null;
    var _cleanupTimer    = null;

    var STYLE_POPUP   = 1;

    var COLOURS = {
        0: { bg: '#FFFDE7', border: '#F9A825', header: '#FFF9C4' },
        1: { bg: '#FFEBEE', border: '#C62828', header: '#FFCDD2' },
        2: { bg: '#E3F2FD', border: '#1565C0', header: '#BBDEFB' },
        3: { bg: '#E8F5E9', border: '#2E7D32', header: '#C8E6C9' },
        4: { bg: '#FCE4EC', border: '#880E4F', header: '#F8BBD0' }
    };

    // -----------------------------------------------------------------------
    // CSS
    // -----------------------------------------------------------------------

    var INJECTED_CSS = [
        '/* === SNA Sticky Notes === */',
        '#sna-popup-root {',
        '  position:fixed; top:16px; right:16px; z-index:999999;',
        '  display:flex; flex-direction:column; align-items:flex-end; gap:10px;',
        '  pointer-events:none;',
        '  font-family:"Segoe UI",Tahoma,sans-serif; font-size:13px;',
        '}',
        '#sna-popup-root:empty { display:none; }',
        '.sna-card {',
        '  pointer-events:auto;',
        '  box-shadow:0 4px 14px rgba(0,0,0,0.16),0 1px 4px rgba(0,0,0,0.08);',
        '  opacity:0; transform:translateX(40px);',
        '  transition:transform 0.35s cubic-bezier(0.22,1,0.36,1),opacity 0.3s ease;',
        '  font-family:"Segoe UI",Tahoma,sans-serif; font-size:13px;',
        '}',
        '.sna-card--popup {',
        '  width:320px; max-width:90vw;',
        '  box-shadow:0 8px 32px rgba(0,0,0,0.22),0 2px 8px rgba(0,0,0,0.12);',
        '  transform:translateX(calc(100% + 24px));',
        '  transition:transform 0.4s cubic-bezier(0.22,1,0.36,1),opacity 0.35s ease;',
        '}',
        '.sna-card.sna-visible { transform:translateX(0); opacity:1; }',
        '.sna-card.sna-hiding  { transform:translateX(40px); opacity:0; }',
        '.sna-card--popup.sna-visible { transform:translateX(0); opacity:1; }',
        '.sna-card--popup.sna-hiding  { transform:translateX(calc(100% + 24px)); opacity:0; }',
        '.sna-card-header {',
        '  display:flex; align-items:center; gap:8px;',
        '  padding:6px 8px 6px 10px;',
        '  border-radius:4px 4px 0 0;',
        '}',
        '.sna-card-title { font-weight:600; font-size:12px; text-transform:uppercase; letter-spacing:0.5px; color:#333; white-space:nowrap; }',
        '.sna-card-meta  { font-size:11px; color:#555; flex:1; text-align:right; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }',
        '.sna-card-dismiss {',
        '  flex-shrink:0; background:none; border:1px solid transparent; border-radius:4px;',
        '  cursor:pointer; font-size:14px; font-weight:700; line-height:1;',
        '  color:#555; padding:2px 5px; font-family:inherit;',
        '  transition:background 0.15s,color 0.15s;',
        '}',
        '.sna-card-dismiss:hover { background:rgba(0,0,0,0.10); color:#111; }',
        '.sna-card-body {',
        '  padding:8px 12px; font-size:13px; line-height:1.5; color:#222;',
        '  white-space:pre-wrap; word-break:break-word; max-height:100px; overflow-y:auto;',
        '}',
        '.sna-card--popup .sna-card-header { cursor:grab; }',
        '.sna-card--popup .sna-card-header:active { cursor:grabbing; }'
    ].join('\n');

    // -----------------------------------------------------------------------
    // Public API
    // -----------------------------------------------------------------------

    window.ShowNotes = function (NotesJson) {
        try { _Notes = JSON.parse(NotesJson) || []; }
        catch (e) { _Notes = []; }

        var visible = _Notes.filter(function (a) { return !_dismissed[a.entryNo]; });

        if (!_firstLoadDone) {
            // Delay first render — gives BC's SPA transition time to settle
            // so our containers are not wiped by BC's page re-render
            setTimeout(function () {
                reconcile(visible);
                _firstLoadDone = true;
            }, 400);
        } else {
            reconcile(visible);
        }
    };

    // -----------------------------------------------------------------------
    // Reconcile
    // -----------------------------------------------------------------------

    function reconcile(visible) {
        // Always re-resolve containers — BC's SPA may have removed them
        var containers = ensureContainers();
        if (!containers) return;

        var visibleIds = {};
        var animDelay  = 0;

        visible.forEach(function (Note) {
            visibleIds[Note.entryNo] = true;

            // If already rendered AND still in the DOM, skip
            if (_rendered[Note.entryNo] && _rendered[Note.entryNo].isConnected) return;

            // Either new or was removed — (re-)create
            delete _rendered[Note.entryNo];

            var container = containerFor(Note.style, containers);
            if (!container) return;

            var isPopup = (Note.style === STYLE_POPUP);
            var noteEl  = buildCard(Note, isPopup);
            container.appendChild(noteEl);
            _rendered[Note.entryNo] = noteEl;

            // Stagger animation on first load; appear instantly for subsequent adds
            if (!_firstLoadDone) {
                setTimeout((function (el) {
                    return function () { el.classList.add('sna-visible'); };
                }(noteEl)), animDelay);
                animDelay += 130;
            } else {
                noteEl.classList.add('sna-visible');
            }
        });

        // Remove notes no longer in the dataset
        Object.keys(_rendered).forEach(function (id) {
            if (!visibleIds[id]) {
                var el = _rendered[id];
                if (el) {
                    if (el._snaCleanupDrag) el._snaCleanupDrag();
                    if (el.parentNode) el.parentNode.removeChild(el);
                }
                delete _rendered[id];
            }
        });
    }

    function containerFor(style, containers) {
        if (style === STYLE_POPUP) return containers.popup;
        return null;
    }

    // -----------------------------------------------------------------------
    // Build card
    // -----------------------------------------------------------------------

    function buildCard(Note, isPopup) {
        var c   = COLOURS[Note.color] || COLOURS[0];
        var doc = _parentDoc || document;

        var note = doc.createElement('div');
        note.className = 'sna-card' + (isPopup ? ' sna-card--popup' : '');
        note.style.backgroundColor = c.bg;
        note.style.borderLeftColor = c.border;

        var header = doc.createElement('div');
        header.className = 'sna-card-header';
        header.style.backgroundColor  = c.header;
        header.style.borderBottomColor = c.border;

        var title = doc.createElement('span');
        title.className   = 'sna-card-title';

        var meta = doc.createElement('span');
        meta.className   = 'sna-card-meta';
        meta.textContent = Note.createdBy + '  \u00B7  ' + Note.createdAt;

        var btn = doc.createElement('button');
        btn.className = 'sna-card-dismiss';
        btn.title     = 'Dismiss';
        btn.innerHTML = '&#x2715;';
        btn.onclick   = function () { dismissNote(Note.entryNo, note); };

        header.appendChild(title);
        header.appendChild(meta);
        header.appendChild(btn);

        var body = doc.createElement('div');
        body.className   = 'sna-card-body';
        body.textContent = Note.message;

        note.appendChild(header);
        note.appendChild(body);

        if (isPopup) makeDraggable(note, header);

        return note;
    }

    // -----------------------------------------------------------------------
    // Drag (popup notes only)
    // -----------------------------------------------------------------------

    function makeDraggable(noteEl, headerEl) {
        var doc      = _parentDoc || document;
        var win      = doc.defaultView || window;
        var dragging = false;
        var startX, startY, startLeft, startTop;

        function onMouseDown(e) {
            if (e.target.classList.contains('sna-card-dismiss')) return;
            e.preventDefault();

            if (!noteEl._snaDragged) {
                var rect = noteEl.getBoundingClientRect();
                doc.body.appendChild(noteEl);
                noteEl.style.position = 'fixed';
                noteEl.style.left     = rect.left + 'px';
                noteEl.style.top      = rect.top  + 'px';
                noteEl.style.margin   = '0';
                noteEl.style.width    = rect.width + 'px';
                noteEl._snaDragged    = true;
            }

            noteEl.style.transition = 'none';
            noteEl.style.zIndex     = '9999999';
            headerEl.style.cursor   = 'grabbing';

            dragging  = true;
            startX    = e.clientX;
            startY    = e.clientY;
            startLeft = parseFloat(noteEl.style.left);
            startTop  = parseFloat(noteEl.style.top);
        }

        function onMouseMove(e) {
            if (!dragging) return;
            var newLeft = Math.max(0, Math.min(startLeft + (e.clientX - startX), win.innerWidth  - noteEl.offsetWidth));
            var newTop  = Math.max(0, Math.min(startTop  + (e.clientY - startY), win.innerHeight - noteEl.offsetHeight));
            noteEl.style.left = newLeft + 'px';
            noteEl.style.top  = newTop  + 'px';
        }

        function onMouseUp() {
            if (!dragging) return;
            dragging = false;
            headerEl.style.cursor   = 'grab';
            noteEl.style.transition = '';
        }

        function onResize() {
            if (!noteEl._snaDragged || !noteEl.isConnected) {
                win.removeEventListener('resize', onResize);
                return;
            }
            var newLeft = Math.max(0, Math.min(parseFloat(noteEl.style.left), win.innerWidth  - noteEl.offsetWidth));
            var newTop  = Math.max(0, Math.min(parseFloat(noteEl.style.top),  win.innerHeight - noteEl.offsetHeight));
            noteEl.style.left = newLeft + 'px';
            noteEl.style.top  = newTop  + 'px';
        }

        headerEl.addEventListener('mousedown', onMouseDown);
        doc.addEventListener('mousemove', onMouseMove);
        doc.addEventListener('mouseup', onMouseUp);
        win.addEventListener('resize', onResize);

        // Clean up doc-level listeners when the note is dismissed/removed
        noteEl._snaCleanupDrag = function () {
            headerEl.removeEventListener('mousedown', onMouseDown);
            doc.removeEventListener('mousemove', onMouseMove);
            doc.removeEventListener('mouseup', onMouseUp);
            win.removeEventListener('resize', onResize);
        };
    }

    // -----------------------------------------------------------------------
    // Dismiss
    // -----------------------------------------------------------------------

    function dismissNote(entryNo, noteEl) {
        _dismissed[entryNo] = true;
        if (noteEl._snaCleanupDrag) noteEl._snaCleanupDrag();
        noteEl.classList.remove('sna-visible');
        noteEl.classList.add('sna-hiding');
        setTimeout(function () {
            if (noteEl.parentNode) noteEl.parentNode.removeChild(noteEl);
            delete _rendered[entryNo];
        }, 400);
    }

    // -----------------------------------------------------------------------
    // Containers — re-evaluated on every reconcile call
    // -----------------------------------------------------------------------

    function ensureContainers() {
        try { _parentDoc = window.parent.document; }
        catch (e) { _parentDoc = document; }

        // Inject CSS once (or re-inject if it was removed)
        if (!_parentDoc.getElementById('sna-injected-styles')) {
            var styleEl = _parentDoc.createElement('style');
            styleEl.id = 'sna-injected-styles';
            styleEl.textContent = INJECTED_CSS;
            _parentDoc.head.appendChild(styleEl);
        }

        return {
            popup: getOrCreate('sna-popup-root')
        };
    }

    function getOrCreate(id) {
        var el = _parentDoc.getElementById(id);
        if (!el) {
            el    = _parentDoc.createElement('div');
            el.id = id;
            _parentDoc.body.appendChild(el);
        }
        return el;
    }

    // -----------------------------------------------------------------------
    // Cleanup
    // -----------------------------------------------------------------------

    function cleanup() {
        if (_cleanupTimer) { clearTimeout(_cleanupTimer); _cleanupTimer = null; }
        try {
            // Remove containers
            ['sna-popup-root', 'sna-injected-styles']
                .forEach(function (id) {
                    var el = _parentDoc && _parentDoc.getElementById(id);
                    if (el && el.parentNode) el.parentNode.removeChild(el);
                });
            // Remove dragged notes that were moved to body
            if (_parentDoc) {
                var dragged = _parentDoc.querySelectorAll('.sna-card--popup');
                for (var i = 0; i < dragged.length; i++) {
                    if (dragged[i].parentNode) dragged[i].parentNode.removeChild(dragged[i]);
                }
            }
        } catch (e) { /* ignore */ }

        if (_removalObserver) {
            _removalObserver.disconnect();
            _removalObserver = null;
        }
    }

    // Watch for our iframe being removed from the parent DOM (covers back button)
    function watchForRemoval() {
        if (_removalObserver) return; // already watching
        try {
            var frameEl = window.frameElement;
            if (!frameEl || !_parentDoc) return;

            _removalObserver = new MutationObserver(function () {
                if (frameEl.isConnected) {
                    // Frame reconnected (BC SPA same-type navigation) — cancel pending cleanup
                    if (_cleanupTimer) { clearTimeout(_cleanupTimer); _cleanupTimer = null; }
                    return;
                }
                // Frame disconnected — hide notes immediately for good UX
                Object.keys(_rendered).forEach(function (id) {
                    var el = _rendered[id];
                    if (el && el.isConnected) {
                        el.classList.remove('sna-visible');
                        el.classList.add('sna-hiding');
                    }
                });
                // Schedule full DOM cleanup — long enough for BC to finish any SPA transition
                if (!_cleanupTimer) {
                    _cleanupTimer = setTimeout(function () {
                        _cleanupTimer = null;
                        if (!frameEl.isConnected) cleanup();
                    }, 1500);
                }
            });
            _removalObserver.observe(_parentDoc.body, { childList: true, subtree: true });
        } catch (e) { /* cross-origin or not supported */ }
    }

    // Belt-and-suspenders fallbacks
    window.addEventListener('beforeunload', cleanup);
    window.addEventListener('pagehide',     cleanup);
    window.addEventListener('unload',       cleanup);

    // -----------------------------------------------------------------------
    // Init
    // -----------------------------------------------------------------------

    function init() {
        try {
            _parentDoc = window.parent.document;
            // Clear stale notes left by a previous page's add-in
            var oldRoot = _parentDoc.getElementById('sna-popup-root');
            if (oldRoot) oldRoot.innerHTML = '';
            var stale = _parentDoc.querySelectorAll('.sna-card--popup');
            for (var i = 0; i < stale.length; i++) {
                if (stale[i].parentNode) stale[i].parentNode.removeChild(stale[i]);
            }
            watchForRemoval();
        } catch (e) { /* ignore */ }

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

}());
