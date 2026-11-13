import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Scrollable column that every settings page lives in.
Flickable {
    id: root
    default property alias content: col.data
    contentHeight: col.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    ColumnLayout {
        id: col
        x: 4
        width: root.width - 8
        spacing: 10
    }
}
