.pragma library

// Lucide icon bodies (ISC license) used by the snip toolbar. "line" and
// "counter" are drawn in the same style; Lucide has no exact match.

var paths = {
 "crop": "<path d=\"M6 2v14a2 2 0 0 0 2 2h14\" /> <path d=\"M18 22V8a2 2 0 0 0-2-2H2\" />",
 "pencil": "<path d=\"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z\" /> <path d=\"m15 5 4 4\" />",
 "line": "<path d=\"M5 19 19 5\" />",
 "arrow": "<path d=\"M13 5h6v6\" /> <path d=\"M19 5 5 19\" />",
 "square": "<rect width=\"18\" height=\"18\" x=\"3\" y=\"3\" rx=\"2\" />",
 "circle": "<circle cx=\"12\" cy=\"12\" r=\"10\" />",
 "highlighter": "<path d=\"m9 11-6 6v3h9l3-3\" /> <path d=\"m22 12-4.6 4.6a2 2 0 0 1-2.8 0l-5.2-5.2a2 2 0 0 1 0-2.8L14 4\" />",
 "type": "<path d=\"M12 4v16\" /> <path d=\"M4 7V5a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v2\" /> <path d=\"M9 20h6\" />",
 "counter": "<circle cx=\"12\" cy=\"12\" r=\"10\" /> <path d=\"M10.5 9.5 12.5 8v8\" />",
 "grid": "<rect width=\"18\" height=\"18\" x=\"3\" y=\"3\" rx=\"2\" /> <path d=\"M3 9h18\" /> <path d=\"M3 15h18\" /> <path d=\"M9 3v18\" /> <path d=\"M15 3v18\" />",
 "undo": "<path d=\"M9 14 4 9l5-5\" /> <path d=\"M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11\" />",
 "redo": "<path d=\"m15 14 5-5-5-5\" /> <path d=\"M20 9H9.5A5.5 5.5 0 0 0 4 14.5A5.5 5.5 0 0 0 9.5 20H13\" />",
 "copy": "<rect width=\"14\" height=\"14\" x=\"8\" y=\"8\" rx=\"2\" ry=\"2\" /> <path d=\"M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2\" />",
 "download": "<path d=\"M12 15V3\" /> <path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\" /> <path d=\"m7 10 5 5 5-5\" />",
 "upload": "<path d=\"M12 13v8\" /> <path d=\"M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242\" /> <path d=\"m8 17 4-4 4 4\" />",
 "x": "<path d=\"M18 6 6 18\" /> <path d=\"m6 6 12 12\" />"
}

function svg(name, color, stroke) {
    var body = paths[name] || paths["x"]
    return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + color + "\" stroke-width=\"" + stroke + "\" stroke-linecap=\"round\" stroke-linejoin=\"round\">" + body + "</svg>"
}
