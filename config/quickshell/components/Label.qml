import QtQuick
import qs.common

// The only text primitive. Instrument Sans, Medium, slight tracking.
Text {
    color: Theme.soft
    font.family: Theme.font
    font.pixelSize: Theme.fsSm
    font.weight: Font.Medium
    font.letterSpacing: 0.25
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
