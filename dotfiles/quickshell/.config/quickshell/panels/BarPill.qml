import QtQuick

// One floating pill on the bar: surface_container @ 75%, radius 10.
// padding 0 12 by default; groups (menu, status, workspaces) use 0 4.
Rectangle {
    id: pill
    default property alias items: row.data
    property int padding: 12
    property int spacing: 0
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: BarCfg.height
    radius: 10
    color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.75)

    Row {
        id: row
        x: pill.padding
        height: parent.height
        spacing: pill.spacing
    }
}
