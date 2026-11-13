import QtQuick

Text {
    property bool dim: false
    font.family: Theme.font
    font.pixelSize: 14
    color: dim ? Theme.subtext : Theme.text
    elide: Text.ElideRight
}
