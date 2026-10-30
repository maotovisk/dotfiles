pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All capture state lives here, in global (desktop, logical px) coordinates.
// Every monitor's overlay renders the same state through its own offset, so a
// selection or a stroke can cross monitors freely.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("SNIP_DIR") || ""
    readonly property string outPath: Quickshell.env("SNIP_OUT") || ""
    readonly property bool testing: (Quickshell.env("SNIP_TEST") || "") !== ""

    // ── desktop ─────────────────────────────────────────────────────────
    readonly property var screens: Quickshell.screens.map(s => ({
        name: s.name, x: s.x, y: s.y, w: s.width, h: s.height,
        scale: s.devicePixelRatio || 1,
        src: "file://" + dir + "/" + s.name + ".png"
    }))
    readonly property rect desktop: {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
        for (const s of screens) {
            x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
            x1 = Math.max(x1, s.x + s.w); y1 = Math.max(y1, s.y + s.h)
        }
        return screens.length ? Qt.rect(x0, y0, x1 - x0, y1 - y0) : Qt.rect(0, 0, 0, 0)
    }

    // windows on visible workspaces, most recently focused first (launcher writes it)
    property var windows: []
    FileView {
        path: root.dir + "/windows.json"
        onLoaded: { try { root.windows = JSON.parse(text()) } catch (e) { root.windows = [] } }
    }

    function screenAt(x, y) {
        for (const s of screens)
            if (x >= s.x && x < s.x + s.w && y >= s.y && y < s.y + s.h) return s
        return null
    }
    function windowAt(x, y) {
        for (const w of windows)
            if (x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) return w
        return null
    }

    // ── tools ───────────────────────────────────────────────────────────
    readonly property var tools: [
        { id: "select",    icon: "crop",        key: Qt.Key_S, label: "Select (S)" },
        { id: "pen",       icon: "pencil",      key: Qt.Key_P, label: "Pen (P)" },
        { id: "line",      icon: "line",        key: Qt.Key_L, label: "Line (L)" },
        { id: "arrow",     icon: "arrow",       key: Qt.Key_A, label: "Arrow (A)" },
        { id: "rect",      icon: "square",      key: Qt.Key_R, label: "Rectangle (R)" },
        { id: "ellipse",   icon: "circle",      key: Qt.Key_E, label: "Ellipse (E)" },
        { id: "highlight", icon: "highlighter", key: Qt.Key_H, label: "Highlighter (H)" },
        { id: "text",      icon: "type",        key: Qt.Key_T, label: "Text (T)" },
        { id: "counter",   icon: "counter",     key: Qt.Key_N, label: "Number (N)" },
        { id: "pixelate",  icon: "grid",        key: Qt.Key_B, label: "Pixelate (B)" }
    ]
    readonly property var palette: ["#FF4D4D", "#FF9E3D", "#FFD43B", "#4ADE80", "#4DA3FF", "#C084FC", "#FFFFFF", "#111111"]
    readonly property var sizes: [{ label: "S", stroke: 2 }, { label: "M", stroke: 4 }, { label: "L", stroke: 8 }]

    property string tool: "select"
    property color color: palette[0]
    property int sizeIndex: 1
    readonly property real stroke: sizes[sizeIndex].stroke

    // restyle the text being typed when colour/size change mid-edit
    onColorChanged: if (editingText && draft) draft = Object.assign({}, draft, { color: String(color) })
    onSizeIndexChanged: if (editingText && draft) draft = Object.assign({}, draft, { size: sizeIndex })

    function setTool(t) {
        commitText()
        tool = t
    }

    // ── selection ───────────────────────────────────────────────────────
    property bool hasSelection: false
    property rect selection: Qt.rect(0, 0, 0, 0)

    function setSelection(x0, y0, x1, y1) {
        const d = desktop
        const l = Math.round(Math.max(d.x, Math.min(x0, x1)))
        const t = Math.round(Math.max(d.y, Math.min(y0, y1)))
        const r = Math.round(Math.min(d.x + d.width, Math.max(x0, x1)))
        const b = Math.round(Math.min(d.y + d.height, Math.max(y0, y1)))
        selection = Qt.rect(l, t, Math.max(1, r - l), Math.max(1, b - t))
        hasSelection = true
    }
    function selectRect(r) { setSelection(r.x, r.y, r.x + r.width, r.y + r.height) }
    function selectScreenAt(x, y) {
        const s = screenAt(x, y) || screens[0]
        if (s) setSelection(s.x, s.y, s.x + s.w, s.y + s.h)
    }

    // ── pointer (global) ────────────────────────────────────────────────
    property point cursor: Qt.point(-1, -1)
    property var hoverWindow: null
    // none | new | move | resize | draw
    property string mode: "none"
    property string handle: ""          // resize edge set, e.g. "tl", "r"
    property point anchor: Qt.point(0, 0)
    property rect anchorSel: Qt.rect(0, 0, 0, 0)
    property bool pendingClick: false

    readonly property int handleSlop: 10

    function hitHandle(x, y) {
        if (!hasSelection) return ""
        const s = selection, k = handleSlop
        const nearL = Math.abs(x - s.x) <= k, nearR = Math.abs(x - (s.x + s.width)) <= k
        const nearT = Math.abs(y - s.y) <= k, nearB = Math.abs(y - (s.y + s.height)) <= k
        const inX = x > s.x - k && x < s.x + s.width + k
        const inY = y > s.y - k && y < s.y + s.height + k
        let h = ""
        if (nearT && inX) h += "t"; else if (nearB && inX) h += "b"
        if (nearL && inY) h += "l"; else if (nearR && inY) h += "r"
        return h
    }
    function inSelection(x, y) {
        const s = selection
        return hasSelection && x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height
    }

    function cursorShapeAt(x, y) {
        if (tool === "text") return Qt.IBeamCursor
        if (tool !== "select") return Qt.CrossCursor
        if (mode === "move") return Qt.ClosedHandCursor
        const h = mode === "resize" ? handle : hitHandle(x, y)
        if (h === "tl" || h === "br") return Qt.SizeFDiagCursor
        if (h === "tr" || h === "bl") return Qt.SizeBDiagCursor
        if (h === "t" || h === "b") return Qt.SizeVerCursor
        if (h === "l" || h === "r") return Qt.SizeHorCursor
        if (inSelection(x, y)) return Qt.OpenHandCursor
        return Qt.CrossCursor
    }

    function press(x, y, button, mods) {
        cursor = Qt.point(x, y)
        if (button === Qt.RightButton) {
            if (editingText) { draft = null; editingText = false }
            else if (mode === "draw") { draft = null; mode = "none" }
            else if (hasSelection) { hasSelection = false; mode = "none" }
            else cancel()
            return
        }
        commitText()
        anchor = Qt.point(x, y)
        anchorSel = selection

        if (tool === "select") {
            const h = hitHandle(x, y)
            if (h !== "") { mode = "resize"; handle = h }
            else if (inSelection(x, y)) mode = "move"
            else { mode = "new"; pendingClick = true }
            return
        }

        if (tool === "text") {
            draft = { kind: "text", x: x, y: y, color: String(color), size: sizeIndex, text: "" }
            editingText = true
            return
        }
        if (tool === "counter") {
            commit({ kind: "counter", x: x, y: y, color: String(color), size: sizeIndex, n: nextCounter() })
            return
        }
        mode = "draw"
        if (tool === "pen" || tool === "highlight")
            draft = { kind: tool, color: String(color), stroke: stroke, points: [{ x: x, y: y }] }
        else
            draft = { kind: tool, color: String(color), stroke: stroke, size: sizeIndex, x0: x, y0: y, x1: x, y1: y }
    }

    function move(x, y, mods) {
        cursor = Qt.point(x, y)
        const shift = mods & Qt.ShiftModifier
        const dx = x - anchor.x, dy = y - anchor.y
        switch (mode) {
        case "none":
            hoverWindow = (tool === "select" && !hasSelection) ? windowAt(x, y) : null
            return
        case "new":
            if (pendingClick && Math.abs(dx) + Math.abs(dy) < 4) return
            pendingClick = false
            setSelection(anchor.x, anchor.y, x, y)
            return
        case "move": {
            const d = desktop, s = anchorSel
            const nx = Math.max(d.x, Math.min(s.x + dx, d.x + d.width - s.width))
            const ny = Math.max(d.y, Math.min(s.y + dy, d.y + d.height - s.height))
            selection = Qt.rect(Math.round(nx), Math.round(ny), s.width, s.height)
            return
        }
        case "resize": {
            const s = anchorSel
            let l = s.x, t = s.y, r = s.x + s.width, b = s.y + s.height
            if (handle.includes("l")) l += dx
            if (handle.includes("r")) r += dx
            if (handle.includes("t")) t += dy
            if (handle.includes("b")) b += dy
            setSelection(l, t, r, b)
            return
        }
        case "draw": {
            const d = Object.assign({}, draft)
            if (d.points) {
                d.points = d.points.concat([{ x: x, y: y }])
                if (shift && d.points.length > 1) d.points = [d.points[0], { x: x, y: y }]
            } else {
                let ex = x, ey = y
                if (shift) {
                    if (d.kind === "line" || d.kind === "arrow") {
                        // snap to 45°
                        const a = Math.round(Math.atan2(y - d.y0, x - d.x0) / (Math.PI / 4)) * Math.PI / 4
                        const len = Math.hypot(x - d.x0, y - d.y0)
                        ex = d.x0 + Math.cos(a) * len; ey = d.y0 + Math.sin(a) * len
                    } else {
                        const m = Math.max(Math.abs(x - d.x0), Math.abs(y - d.y0))
                        ex = d.x0 + Math.sign(x - d.x0 || 1) * m; ey = d.y0 + Math.sign(y - d.y0 || 1) * m
                    }
                }
                d.x1 = ex; d.y1 = ey
            }
            draft = d
            return
        }
        }
    }

    function release(x, y) {
        if (mode === "new" && pendingClick) {
            // plain click: take the window under the pointer, else its monitor
            const w = windowAt(x, y)
            if (w) selectRect(Qt.rect(w.x, w.y, w.w, w.h))
            else selectScreenAt(x, y)
        } else if (mode === "draw" && draft) {
            const d = draft
            const tiny = d.points ? d.points.length < 2
                : Math.abs(d.x1 - d.x0) < 2 && Math.abs(d.y1 - d.y0) < 2
            if (!tiny) commit(d)
            draft = null
        }
        pendingClick = false
        mode = "none"
        hoverWindow = null
    }

    function doubleClick(x, y) {
        if (tool === "select" && inSelection(x, y)) accept("upload")
    }

    // ── annotations ─────────────────────────────────────────────────────
    property var items: []
    property var redoStack: []
    property var draft: null
    property bool editingText: false

    function commit(a) {
        items = items.concat([a])
        redoStack = []
    }
    function undo() {
        if (editingText) { draft = null; editingText = false; return }
        if (!items.length) return
        redoStack = redoStack.concat([items[items.length - 1]])
        items = items.slice(0, -1)
    }
    function redo() {
        if (!redoStack.length) return
        items = items.concat([redoStack[redoStack.length - 1]])
        redoStack = redoStack.slice(0, -1)
    }
    function nextCounter() {
        return items.filter(a => a.kind === "counter").length + 1
    }
    function commitText() {
        if (!editingText) return
        if (draft && draft.text.trim() !== "") commit(draft)
        draft = null
        editingText = false
    }
    function typeText(s) {
        const d = Object.assign({}, draft)
        d.text = s
        draft = d
    }

    // ── keyboard ────────────────────────────────────────────────────────
    function key(ev) {
        const ctrl = ev.modifiers & Qt.ControlModifier
        const shift = ev.modifiers & Qt.ShiftModifier

        if (editingText) {
            if (ev.key === Qt.Key_Escape) { draft = null; editingText = false }
            else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && !shift) commitText()
            else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) typeText(draft.text + "\n")
            else if (ev.key === Qt.Key_Backspace) typeText(draft.text.slice(0, -1))
            else if (ctrl && ev.key === Qt.Key_Z) undo()
            else if (ev.text !== "" && !ctrl && ev.text.charCodeAt(0) >= 32) typeText(draft.text + ev.text)
            ev.accepted = true
            return
        }

        ev.accepted = true
        if (ev.key === Qt.Key_Escape) cancel()
        else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) accept("upload")
        else if (ctrl && ev.key === Qt.Key_C) accept("copy")
        else if (ctrl && ev.key === Qt.Key_S) accept("save")
        else if (ctrl && (ev.key === Qt.Key_Y || (shift && ev.key === Qt.Key_Z))) redo()
        else if (ctrl && ev.key === Qt.Key_Z) undo()
        else if (ctrl && ev.key === Qt.Key_A) selectRect(desktop)
        else if (ev.key === Qt.Key_F) selectScreenAt(cursor.x, cursor.y)
        else if (ev.key === Qt.Key_BracketLeft) sizeIndex = Math.max(0, sizeIndex - 1)
        else if (ev.key === Qt.Key_BracketRight) sizeIndex = Math.min(sizes.length - 1, sizeIndex + 1)
        else if (ev.key >= Qt.Key_1 && ev.key < Qt.Key_1 + palette.length) color = palette[ev.key - Qt.Key_1]
        else {
            const t = tools.find(t => t.key === ev.key && !ctrl)
            if (t) setTool(t.id)
            else ev.accepted = false
        }
    }

    // ── finish ──────────────────────────────────────────────────────────
    // The launcher reads the chosen action from $SNIP_DIR/action (qs doesn't
    // reliably forward Qt.exit codes). No file → cancelled.
    property string exporting: ""       // action being exported; overlays load the Exporter

    FileView {
        id: actionFile
        path: root.dir + "/action"
        blockWrites: true
        printErrors: false
    }

    function accept(action) {
        if (exporting !== "") return
        commitText()
        if (!hasSelection) selectScreenAt(cursor.x, cursor.y)
        mode = "none"
        exporting = action
    }
    function finish(ok) {
        if (ok) actionFile.setText(exporting)
        Qt.quit()
    }
    function cancel() {
        Qt.quit()
    }

    // ── toolbar placement (global) ──────────────────────────────────────
    property size toolbarSize: Qt.size(0, 0)
    readonly property point toolbarPos: {
        if (!hasSelection) return Qt.point(-1e6, -1e6)
        const s = selection, w = toolbarSize.width, h = toolbarSize.height, gap = 10
        const cx = s.x + s.width / 2
        const fits = (x, y) => {
            const sc = screenAt(x, y)
            return sc && x + w <= sc.x + sc.w && y + h <= sc.y + sc.h && sc === screenAt(x + w - 1, y + h - 1)
        }
        const candidates = [s.y + s.height + gap, s.y - gap - h, s.y + s.height - gap - h]
        for (const y of candidates) {
            const sc = screenAt(cx, y) || screenAt(cx, y + h)
            if (!sc) continue
            const x = Math.max(sc.x + gap, Math.min(cx - w / 2, sc.x + sc.w - w - gap))
            if (y >= sc.y && fits(x, y)) return Qt.point(Math.round(x), Math.round(y))
        }
        const sc = screenAt(cx, s.y + s.height / 2) || screens[0]
        return Qt.point(Math.round(sc.x + (sc.w - w) / 2), Math.round(sc.y + sc.h - h - gap))
    }
}
