import QtQuick

// Nerd Font (Material Design) glyph, given by code point.
Text {
    property int code: 0xF0493
    property int size: 18
    text: String.fromCodePoint(code)
    font.family: Theme.font
    font.pixelSize: size
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
