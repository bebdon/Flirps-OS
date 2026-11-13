import QtQuick
import QtQuick.Controls

// Slider that only reports a value when you let go (so configs aren't rewritten 60x a second).
Row {
    id: root
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property int decimals: 0
    property string suffix: ""
    signal committed(real value)

    spacing: 12

    Slider {
        id: s
        width: 220
        anchors.verticalCenter: parent.verticalCenter
        from: root.from; to: root.to; stepSize: root.stepSize
        snapMode: Slider.SnapAlways
        value: root.value
        onPressedChanged: if (!pressed) root.committed(Number(value.toFixed(root.decimals)))

        background: Rectangle {
            x: s.leftPadding; y: s.topPadding + s.availableHeight / 2 - height / 2
            width: s.availableWidth; height: 6; radius: 3
            color: Theme.surfaceHighest
            Rectangle { width: s.visualPosition * parent.width; height: parent.height; radius: 3; color: Theme.primary }
        }
        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 6; height: 26; radius: 3
            color: Theme.primary
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 72; height: 34; radius: 17
        color: Theme.surfaceHigh
        SText {
            anchors.centerIn: parent
            text: s.value.toFixed(root.decimals) + root.suffix
            font.pixelSize: 13
        }
    }
}
