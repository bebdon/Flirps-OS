//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Layouts
import Quickshell

// Settings app. Launch with:  qs -n -c settings
ShellRoot {
    FloatingWindow {
        id: win
        title: "Settings"
        implicitWidth: 1100
        implicitHeight: 720
        color: Theme.surface
        onVisibleChanged: if (!visible) Qt.quit()

        property string page: Quickshell.env("QS_SETTINGS_PAGE") || "home"
        property var expanded: ({ appearance: true })
        property string query: ""

        readonly property var nav: [
            { id: "home", label: "Welcome", icon: 0xF02DC, keys: "home quick toggles power" },
            { id: "appearance", label: "Appearance", icon: 0xF03D8, children: [
                { id: "wallpaper", label: "Wallpaper", icon: 0xF02E9, keys: "matugen theme scheme dark light" },
                { id: "windows", label: "Windows", icon: 0xF05AF, keys: "gaps rounding blur opacity shadow border hyprland" }
            ] },
            { id: "display", label: "Display", icon: 0xF0379, keys: "scale night light hyprsunset power profile" },
            { id: "input", label: "Input", icon: 0xF037D, keys: "mouse touchpad scroll acceleration" },
            { id: "bar", label: "Bar", icon: 0xF056E, keys: "waybar height position margin" },
            { id: "dock", label: "Dock", icon: 0xF003B, keys: "nwg autohide icon size" },
            { id: "notifications", label: "Notifications", icon: 0xF009A, keys: "popups dnd do not disturb sound timeout" },
            { id: "idle", label: "Idle", icon: 0xF04B2, keys: "hypridle lock suspend dim timeout caffeine" },
            { id: "widgets", label: "Widgets & Tools", icon: 0xF0D6D, keys: "desktop clock weather notes calculator timer stopwatch" },
            { id: "about", label: "About " + Brand.name, icon: 0xF02FC, keys: "about version system info credits flirps" }
        ]

        readonly property var pages: ({
            home: "PageHome.qml", wallpaper: "PageWallpaper.qml", windows: "PageWindows.qml",
            display: "PageDisplay.qml", input: "PageInput.qml", bar: "PageBar.qml",
            dock: "PageDock.qml", notifications: "PageNotifications.qml", idle: "PageIdle.qml", widgets: "PageWidgets.qml", about: "PageAbout.qml"
        })

        function matches(item) {
            if (query === "") return true;
            const q = query.toLowerCase();
            return (item.label + " " + (item.keys || "")).toLowerCase().includes(q)
                || (item.children || []).some(c => matches(c));
        }
        function toggleGroup(id) {
            const e = Object.assign({}, expanded);
            e[id] = !e[id];
            expanded = e;
        }
        function titleFor(id) {
            for (const n of nav) {
                if (n.id === id) return n.label;
                for (const c of (n.children || [])) if (c.id === id) return c.label;
            }
            return "";
        }

        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        Shortcut { sequence: "Ctrl+F"; onActivated: { search.visible = true; searchInput.forceActiveFocus(); } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // ---- sidebar ---------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                radius: 24
                color: Theme.surfaceLow

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        Row {
                            visible: !search.visible
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Logo { size: 40; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                SText { text: Brand.name; font.pixelSize: 18; font.weight: Font.Bold }
                                SText { text: "Settings"; dim: true; font.pixelSize: 12 }
                            }
                        }
                        Rectangle {
                            id: search
                            visible: false
                            anchors.left: parent.left; anchors.right: searchBtn.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 42; radius: 21
                            color: Theme.surfaceHigh
                            TextInput {
                                id: searchInput
                                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme.font; font.pixelSize: 14
                                color: Theme.text
                                selectionColor: Theme.primary
                                clip: true
                                onTextChanged: win.query = text
                                Keys.onEscapePressed: { text = ""; search.visible = false; }
                                SText { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: "Search…"; dim: true }
                            }
                        }
                        Rectangle {
                            id: searchBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42; height: 42; radius: 21
                            color: sm.containsMouse ? Theme.surfaceHigh : "transparent"
                            Icon { anchors.centerIn: parent; code: search.visible ? 0xF0156 : 0xF0349; size: 20 }
                            MouseArea {
                                id: sm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    search.visible = !search.visible;
                                    if (search.visible) searchInput.forceActiveFocus(); else searchInput.text = "";
                                }
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: navCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: navCol
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: win.nav
                                Column {
                                    id: group
                                    required property var modelData
                                    readonly property bool hasKids: !!modelData.children
                                    readonly property bool open: hasKids && (win.expanded[modelData.id] || win.query !== "")
                                    visible: win.matches(modelData)
                                    width: navCol.width
                                    spacing: 4

                                    NavItem {
                                        width: parent.width
                                        label: group.modelData.label
                                        icon: group.modelData.icon
                                        expandable: group.hasKids
                                        expanded: group.open
                                        selected: win.page === group.modelData.id
                                        onClicked: group.hasKids ? win.toggleGroup(group.modelData.id) : win.page = group.modelData.id
                                    }

                                    Item {
                                        visible: group.open
                                        width: parent.width
                                        height: kids.implicitHeight
                                        Rectangle {   // tree line
                                            x: 30; width: 2; height: parent.height - 8; y: 4
                                            color: Theme.outlineVariant
                                        }
                                        Column {
                                            id: kids
                                            x: 42; width: parent.width - 42
                                            spacing: 4
                                            Repeater {
                                                model: group.modelData.children || []
                                                NavItem {
                                                    required property var modelData
                                                    visible: win.matches(modelData) || win.matches({ label: group.modelData.label })
                                                    width: kids.width
                                                    child: true
                                                    label: modelData.label
                                                    icon: modelData.icon
                                                    selected: win.page === modelData.id
                                                    onClicked: win.page = modelData.id
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- content ---------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                SText {
                    visible: win.page !== "home" && win.page !== "wallpaper"
                    Layout.leftMargin: 12
                    Layout.topMargin: 8
                    Layout.bottomMargin: 4
                    text: win.titleFor(win.page)
                    font.pixelSize: 24; font.weight: Font.Bold
                }

                Loader {
                    id: loader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: Backend.ready
                    source: win.pages[win.page]
                    opacity: status === Loader.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }

                SText {
                    visible: !Backend.ready
                    Layout.alignment: Qt.AlignCenter
                    text: "Reading your config…"; dim: true
                }
            }
        }
    }
}
