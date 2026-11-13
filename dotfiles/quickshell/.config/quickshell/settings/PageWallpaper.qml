import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

Page {
    id: page
    property bool picking: false
    readonly property string current: Backend.get("wallpaper", "current", "")
    readonly property string fileName: current.split("/").pop()

    // ---- banner ----------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 340

        RoundedImage {
            anchors.fill: parent
            radius: 24
            source: page.current ? "file://" + page.current : ""
            sourceSize: Qt.size(1600, 900)
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 120; radius: 24
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }
        Row {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 20
            spacing: 10
            PillButton { text: page.picking ? "Close picker" : "Select wallpaper"; icon: 0xF02E9; onClicked: page.picking = !page.picking }
            PillButton { text: "Random"; icon: 0xF049D; filled: false; onClicked: Backend.set("wallpaper", "random", "1") }
        }
        Column {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 22
            SText { anchors.right: parent.right; text: page.fileName; color: "white"; font.weight: Font.Bold; font.pixelSize: 13 }
            SText { anchors.right: parent.right; text: page.current.replace(Backend.home, "~"); color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 11 }
        }
    }

    // ---- picker grid -----------------------------------------------------
    Rectangle {
        visible: page.picking
        Layout.fillWidth: true
        Layout.preferredHeight: grid.contentHeight + 24
        radius: Theme.radius
        color: Theme.surfaceLow

        GridView {
            id: grid
            anchors.fill: parent; anchors.margins: 12
            interactive: false
            cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 200)))
            cellHeight: cellWidth * 0.625
            model: FolderListModel {
                folder: "file://" + Backend.home + "/Pictures/Wallpapers"
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
                showDirs: false
                sortField: FolderListModel.Name
            }
            delegate: Item {
                id: cell
                required property string fileName
                required property string filePath
                readonly property bool active: filePath === page.current
                width: grid.cellWidth; height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent; anchors.margins: 5
                    radius: 16
                    color: cell.active ? Theme.primary : "transparent"
                    RoundedImage {
                        id: thumb
                        anchors.fill: parent; anchors.margins: cell.active ? 4 : 0
                        radius: 14
                        source: "file://" + Backend.home + "/.cache/wallpaper/thumbs/" + cell.fileName + ".jpg"
                        onStatusChanged: if (status === Image.Error) { sourceSize = Qt.size(400, 250); source = "file://" + cell.filePath; }
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 16
                        color: "white"; opacity: ma.containsMouse ? 0.12 : 0
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Backend.set("wallpaper", "file", cell.filePath)
                    }
                }
            }
        }
        Component.onCompleted: Quickshell.execDetached([Backend.home + "/.local/bin/wallpaper-thumbs"])
    }

    // ---- colours ---------------------------------------------------------
    SectionTitle { text: "Colors" }

    OptionRow {
        icon: 0xF03D8
        title: "Color scheme"
        description: "How matugen turns the wallpaper into a palette"
        Dropdown {
            value: Backend.get("wallpaper", "scheme", "scheme-tonal-spot")
            options: [
                { label: "Tonal spot", value: "scheme-tonal-spot" },
                { label: "Content", value: "scheme-content" },
                { label: "Expressive", value: "scheme-expressive" },
                { label: "Fidelity", value: "scheme-fidelity" },
                { label: "Fruit salad", value: "scheme-fruit-salad" },
                { label: "Rainbow", value: "scheme-rainbow" },
                { label: "Neutral", value: "scheme-neutral" },
                { label: "Monochrome", value: "scheme-monochrome" }
            ]
            onPicked: v => Backend.set("wallpaper", "scheme", v)
        }
    }

    OptionRow {
        icon: 0xF050E
        title: "Mode"
        description: "Applies to bar, dock, notifications, GTK, Qt, kitty"
        Dropdown {
            value: Backend.get("wallpaper", "mode", "dark")
            options: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]
            onPicked: v => Backend.set("wallpaper", "mode", v)
        }
    }

    // ---- rotation ----
    SectionTitle { text: "Rotation" }

    OptionRow {
        icon: 0xF0450
        title: "Rotate wallpapers"
        description: "Change the wallpaper (and colours) automatically"
        Toggle { checked: Backend.get("wallpaper", "rotate", false); onToggled: v => Backend.set("wallpaper", "rotate", v) }
    }
    OptionRow {
        visible: Backend.get("wallpaper", "rotate", false)
        icon: 0xF051B
        title: "Every"
        Dropdown {
            value: Backend.get("wallpaper", "rotate_min", 30)
            options: [
                { label: "5 minutes", value: 5 }, { label: "10 minutes", value: 10 }, { label: "15 minutes", value: 15 },
                { label: "30 minutes", value: 30 }, { label: "1 hour", value: 60 }, { label: "2 hours", value: 120 },
                { label: "6 hours", value: 360 }, { label: "Once a day", value: 1440 }
            ]
            onPicked: v => Backend.set("wallpaper", "rotate_min", v)
        }
    }
    OptionRow {
        visible: Backend.get("wallpaper", "rotate", false)
        icon: 0xF049D
        title: "Order"
        Dropdown {
            value: Backend.get("wallpaper", "rotate_order", "random")
            options: [{ label: "Shuffle", value: "random" }, { label: "In order (A → Z)", value: "next" }]
            onPicked: v => Backend.set("wallpaper", "rotate_order", v)
        }
    }
    OptionRow {
        visible: Backend.get("wallpaper", "rotate", false)
        icon: 0xF02E9
        title: "Use"
        description: "Which wallpapers rotation picks from"
        Dropdown {
            value: Backend.get("wallpaper", "rotate_pool", "all")
            options: [{ label: "All wallpapers", value: "all" }, { label: "Anime only", value: "anime" }]
            onPicked: v => Backend.set("wallpaper", "rotate_pool", v)
        }
    }
    OptionRow {
        visible: Backend.get("wallpaper", "rotate", false)
        icon: 0xF04AD
        title: "Skip to the next one now"
        PillButton { text: "Next"; icon: 0xF04AD; onClicked: Backend.set("wallpaper", "rotate_now", "1") }
    }
}
