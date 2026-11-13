import QtQuick

// Flirps OS mark: a squircle in the wallpaper's colours with a bold "F" and a dot.
Item {
    id: root
    property real size: 40
    width: size; height: size

    Rectangle {
        anchors.fill: parent
        radius: root.size * 0.32
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Theme.primary }
            GradientStop { position: 1; color: Theme.tertiary }
        }
    }
    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -root.size * 0.06
        text: "F"
        font.family: Theme.font
        font.pixelSize: root.size * 0.62
        font.weight: Font.Black
        color: Theme.fgPrimary
    }
    Rectangle {
        width: root.size * 0.16; height: width; radius: width / 2
        x: root.size * 0.66; y: root.size * 0.62
        color: Theme.fgPrimary
    }
}
