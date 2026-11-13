import QtQuick

// A module inside a pill: icon/text with padding 0 9, font 15, hover = primary @ 15%, radius 8.
// Emits clicked/middleClicked/rightClicked/scrolled like waybar's on-click handlers.
Item {
    id: btn
    property string text: ""
    property int fontSize: 15
    property bool bold: false
    property color textColor: Theme.text
    property int hpad: 9
    property bool hoverFill: true
    property color hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
    property color hoverTextColor: textColor
    property int hoverRadius: 8
    property string tooltip: ""
    property Component tooltipContent: null
    property int minWidth: 0
    property int glyphWidth: 0       // icon-only buttons: fixed glyph cell (waybar used 9px at 15px)
    readonly property bool hovered: ma.containsMouse
    signal clicked()
    signal middleClicked()
    signal rightClicked()
    signal scrolled(int delta)       // +1 up, -1 down

    implicitWidth: Math.max(minWidth, (glyphWidth > 0 ? glyphWidth : label.implicitWidth) + hpad * 2)
    implicitHeight: BarCfg.height
    height: parent ? parent.height : implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: btn.hoverRadius
        color: btn.hoverColor
        visible: btn.hoverFill && ma.containsMouse
    }
    Text {
        id: label
        // GTK draws icon glyphs from the left of their cell, and centers text inside a min-width
        x: btn.glyphWidth > 0 ? btn.hpad : Math.max(btn.hpad, (btn.width - implicitWidth) / 2)
        anchors.verticalCenter: parent.verticalCenter
        text: btn.text
        font.family: Theme.font
        font.pixelSize: btn.fontSize
        font.weight: btn.bold ? Font.Bold : Font.Normal
        color: ma.containsMouse ? btn.hoverTextColor : btn.textColor
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => m.button === Qt.MiddleButton ? btn.middleClicked() : m.button === Qt.RightButton ? btn.rightClicked() : btn.clicked()
        onWheel: w => { if (w.angleDelta.y !== 0) btn.scrolled(w.angleDelta.y > 0 ? 1 : -1); }
    }
    BarTooltip { target: btn; text: btn.tooltip; content: btn.tooltipContent; hovered: ma.containsMouse }
}
