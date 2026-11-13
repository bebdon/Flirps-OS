import QtQuick
import QtQuick.Effects

// Image clipped to rounded corners.
Item {
    id: root
    property alias source: img.source
    property alias status: img.status
    property int radius: Theme.radius
    property size sourceSize: Qt.size(0, 0)

    Image {
        id: img
        anchors.fill: parent
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize: root.sourceSize.width > 0 ? root.sourceSize : undefined
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
