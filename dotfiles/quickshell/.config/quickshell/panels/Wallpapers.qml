// Wallpaper picker (SUPER+W): skewed card carousel with colour filters.
//
// Layout, skew/carousel maths and the filter bar are adapted from Serpantinum's
// WallpaperPicker.qml by ilyamiro — https://github.com/ilyamiro/serpantinum
// Serpantinum is licensed under the GNU AGPL-3.0, and so is this adapted file.
//
// Keys: ←/→ (or scroll) to browse · Enter to apply · type to search · Ctrl+R random · Esc to close
import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-wallpapers"

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: home + "/Pictures/Wallpapers"
    readonly property string thumbDir: home + "/.cache/wallpaper/thumbs"

    // ---- sizing (Serpantinum's numbers, scaled to this screen) -------------
    function s(v) { return v * Math.min(width / 1920, height / 1080) * 1.15; }
    readonly property real itemWidth: s(400)
    readonly property real itemHeight: s(420)
    readonly property real borderWidth: s(3)
    readonly property real skewFactor: -0.35
    readonly property real selectedCenterOffset: (skewFactor * itemHeight) / 2
    readonly property real cardRadius: s(18)

    // ---- state -------------------------------------------------------------
    property string currentWall: ""
    property var colors: ({})
    property var items: []            // [{ fileName, filePath, bucket, hex }]
    property string query: ""
    property bool applying: false
    property bool ready: false

    readonly property var filterData: [
        { name: "Red", hex: "#FF4500" },
        { name: "Orange", hex: "#FFA500" },
        { name: "Yellow", hex: "#FFD700" },
        { name: "Green", hex: "#32CD32" },
        { name: "Blue", hex: "#1E90FF" },
        { name: "Purple", hex: "#8A2BE2" },
        { name: "Pink", hex: "#FF69B4" },
        { name: "Monochrome", hex: "#A9A9A9" }
    ]
    readonly property var bucketOrder: ({ Red: 1, Orange: 2, Yellow: 3, Green: 4, Blue: 5, Purple: 6, Pink: 7, Monochrome: 8 })

    readonly property var shown: {
        const q = query.trim().toLowerCase();
        return q ? items.filter(i => i.fileName.toLowerCase().includes(q)) : items;
    }
    readonly property string currentBucket: (view.currentIndex >= 0 && view.currentIndex < shown.length)
        ? shown[view.currentIndex].bucket : ""

    // ---- open / close ------------------------------------------------------
    function open() {
        query = "";
        applying = false;
        ready = false;
        visible = true;
        keyCatcher.forceActiveFocus();
        currentFile.reload();
        thumbs.running = true;          // make thumbnails, then colours, then rebuild
    }
    function close() { visible = false; searchInput.text = ""; }
    function toggle() { visible ? close() : open(); }

    function apply(path) {
        if (applying) return;
        applying = true;
        close();
        Quickshell.execDetached([home + "/.local/bin/wallpaper", "set", path]);
    }
    function random() {
        close();
        Quickshell.execDetached([home + "/.local/bin/wallpaper", "random"]);
    }

    function rebuild() {
        const list = [];
        for (let i = 0; i < folder.count; i++) {
            const fn = String(folder.get(i, "fileName"));
            const c = colors[fn] || { bucket: "Monochrome", hex: "#808080" };
            list.push({ fileName: fn, filePath: String(folder.get(i, "filePath")), bucket: c.bucket, hex: c.hex });
        }
        list.sort((a, b) => (bucketOrder[a.bucket] || 9) - (bucketOrder[b.bucket] || 9) || a.fileName.localeCompare(b.fileName));
        if (JSON.stringify(list) !== JSON.stringify(items)) items = list;
        focusTimer.restart();
    }
    function focusCurrent() {
        const i = shown.findIndex(x => x.filePath === currentWall);
        view.currentIndex = Math.max(0, i);
        view.positionViewAtIndex(view.currentIndex, ListView.Center);
    }
    function jumpToBucket(name) {
        query = ""; searchInput.text = "";
        const i = shown.findIndex(x => x.bucket === name);
        if (i >= 0) view.currentIndex = i;
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: { root.focusCurrent(); root.ready = true; }
    }

    // ---- data sources ------------------------------------------------------
    FileView {
        id: currentFile
        path: root.home + "/.cache/wallpaper/current"
        onLoaded: root.currentWall = text().trim()
    }
    FolderListModel {
        id: folder
        folder: "file://" + root.wallDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready && root.visible && !thumbs.running && !colorProc.running) root.rebuild()
    }
    Process {
        id: thumbs
        command: [root.home + "/.local/bin/wallpaper-thumbs"]
        onExited: colorProc.running = true
    }
    Process {
        id: colorProc
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/wall-colors.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.colors = JSON.parse(this.text); } catch (e) {}
                if (folder.status === FolderListModel.Ready) root.rebuild();
            }
        }
    }

    // ---- backdrop ----------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.28) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.15) }
        }
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    // ---- keyboard ----------------------------------------------------------
    Item {
        id: keyCatcher
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: view.decrementCurrentIndex()
        Keys.onRightPressed: view.incrementCurrentIndex()
        Keys.onTabPressed: view.incrementCurrentIndex()
        Keys.onBacktabPressed: view.decrementCurrentIndex()
        Keys.onReturnPressed: if (root.shown.length) root.apply(root.shown[view.currentIndex].filePath)
        Keys.onEnterPressed: if (root.shown.length) root.apply(root.shown[view.currentIndex].filePath)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) { root.random(); event.accepted = true; return; }
            if (event.text.length === 1 && event.text >= " " && !(event.modifiers & Qt.ControlModifier)) {
                searchInput.text = event.text;
                searchInput.forceActiveFocus();
                event.accepted = true;
            }
        }
    }

    // ---- carousel ----------------------------------------------------------
    ListView {
        id: view
        anchors.left: parent.left; anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.s(40)
        height: root.itemHeight + root.s(60)
        orientation: ListView.Horizontal
        spacing: 0
        clip: false
        cacheBuffer: root.itemWidth * 3
        model: root.shown

        opacity: root.visible && root.ready ? 1 : 0
        scale: root.visible && root.ready ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((root.itemWidth * 1.5 + root.s(4)) / 2) + root.selectedCenterOffset
        preferredHighlightEnd: (width / 2) + ((root.itemWidth * 1.5 + root.s(4)) / 2) + root.selectedCenterOffset
        highlightMoveDuration: 400

        // one wheel notch = one card
        property real wheelAccum: 0
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                view.wheelAccum += (event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x);
                while (view.wheelAccum >= 60) { view.decrementCurrentIndex(); view.wheelAccum -= 60; }
                while (view.wheelAccum <= -60) { view.incrementCurrentIndex(); view.wheelAccum += 60; }
            }
        }

        delegate: Item {
            id: card
            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isActive: modelData.filePath === root.currentWall
            readonly property int dist: Math.abs(index - view.currentIndex)
            readonly property real sideScale: Math.max(0.58, Math.pow(0.88, Math.max(0, dist - 1)))
            readonly property real radius: root.cardRadius * Math.max(0.45, Math.pow(0.85, dist))

            width: isCurrent ? (root.itemWidth * 1.5 + root.s(4)) : (root.itemWidth * 0.48 * sideScale)
            height: isCurrent ? (root.itemHeight + root.s(30)) : (root.itemHeight * Math.max(0.62, Math.pow(0.90, Math.max(0, dist - 1))))
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            z: isCurrent ? 100 : Math.max(1, 50 - dist)

            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Item {
                id: skewed
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -(root.skewFactor * height) / 2
                width: parent.width
                height: parent.height
                transform: Matrix4x4 { property real k: root.skewFactor; matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }

                // border: primary on the applied wallpaper
                Rectangle {
                    anchors.fill: parent
                    radius: card.radius + root.borderWidth
                    color: card.isActive ? Theme.primary : "transparent"
                }

                Item {
                    id: frame
                    anchors.fill: parent
                    anchors.margins: root.borderWidth

                    Rectangle { anchors.fill: parent; radius: card.radius; color: Theme.surfaceHigh }
                    Rectangle { id: mask; anchors.fill: parent; radius: card.radius; visible: false; layer.enabled: true }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: mask }

                        // image is counter-skewed so the picture itself stays straight
                        Item {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: root.s(-50)
                            width: (root.itemWidth * 1.5) + ((root.itemHeight + root.s(30)) * Math.abs(root.skewFactor)) + root.s(50)
                            height: root.itemHeight + root.s(30)
                            transform: Matrix4x4 { property real k: -root.skewFactor; matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }

                            Image {
                                id: thumbImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: "file://" + root.thumbDir + "/" + card.modelData.fileName + ".jpg"
                                sourceSize: Qt.size(480, 300)
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }
                            // sharp full-size image once a card is in the middle
                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: card.isCurrent ? "file://" + card.modelData.filePath : ""
                                sourceSize: Qt.size(Math.round(width * 1.25), Math.round(height * 1.25))
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }
                        }
                    }

                    // file name on the selected card
                    Rectangle {
                        visible: card.isCurrent
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.rightMargin: root.s(14); anchors.bottomMargin: root.s(12)
                        width: nameText.width + root.s(24); height: root.s(30)
                        radius: height / 2
                        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
                        transform: Matrix4x4 { property real k: -root.skewFactor; matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        SText {
                            id: nameText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, root.itemWidth)
                            text: card.modelData.fileName
                            font.pixelSize: root.s(12)
                            font.weight: Font.Bold
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.isCurrent ? root.apply(card.modelData.filePath) : view.currentIndex = card.index
                }
            }
        }
    }

    SText {
        anchors.centerIn: view
        visible: root.visible && (!root.ready || root.shown.length === 0)
        text: !root.ready ? "Sorting wallpapers by colour…" : "Nothing matches “" + root.query + "”"
        color: "white"
        font.pixelSize: 15
    }

    // ---- filter bar --------------------------------------------------------
    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: view.top
        anchors.bottomMargin: root.visible ? root.s(40) : root.s(80)
        opacity: root.visible ? 1 : 0
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        width: barRow.width + root.s(16)
        height: root.s(48)
        radius: root.s(14)
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.9)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        MouseArea { anchors.fill: parent }

        Row {
            id: barRow
            anchors.centerIn: parent
            spacing: root.s(8)

            // current bucket label (follows the selected card)
            Rectangle {
                height: root.s(34); width: Math.max(root.s(60), bucketLabel.implicitWidth + root.s(24))
                radius: root.s(10)
                color: Theme.surfaceHigh
                Behavior on width { NumberAnimation { duration: 200 } }
                SText {
                    id: bucketLabel
                    anchors.centerIn: parent
                    text: root.query ? root.shown.length + " found" : (root.currentBucket || "All")
                    font.pixelSize: root.s(13); font.weight: Font.Bold
                }
            }

            // random
            Rectangle {
                height: root.s(34); width: height; radius: root.s(10)
                color: rnd.containsMouse ? Theme.primary : Theme.surfaceHigh
                Icon { anchors.centerIn: parent; code: 0xF049D; size: root.s(16); color: rnd.containsMouse ? Theme.fgPrimary : Theme.text }
                MouseArea { id: rnd; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.random() }
            }

            // jump to current
            Rectangle {
                height: root.s(34); width: height; radius: root.s(10)
                color: cur.containsMouse ? Theme.primary : Theme.surfaceHigh
                Icon { anchors.centerIn: parent; code: 0xF01A4; size: root.s(16); color: cur.containsMouse ? Theme.fgPrimary : Theme.text }
                MouseArea { id: cur; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.query = ""; searchInput.text = ""; root.focusCurrent(); } }
            }

            Item { width: root.s(2); height: 1 }

            Repeater {
                model: root.filterData
                Rectangle {
                    id: dot
                    required property var modelData
                    readonly property bool sel: !root.query && root.currentBucket === modelData.name
                    height: root.s(34); width: height
                    radius: root.s(10)
                    color: modelData.hex
                    border.width: sel ? root.s(3) : 0
                    border.color: Theme.text
                    scale: sel ? 1.0 : (dm.containsMouse ? 0.95 : 0.85)
                    opacity: root.items.some(i => i.bucket === modelData.name) ? 1 : 0.3
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.jumpToBucket(dot.modelData.name) }
                }
            }

            Item { width: root.s(2); height: 1 }

            // search
            Rectangle {
                id: searchBox
                readonly property bool open: searchInput.activeFocus || searchInput.text !== ""
                height: root.s(34)
                width: open ? root.s(220) : height
                radius: root.s(10)
                color: Theme.surfaceHigh
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                clip: true
                Icon {
                    id: searchIcon
                    x: (searchBox.height - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    code: 0xF0349; size: root.s(16)
                    color: searchBox.open ? Theme.primary : Theme.text
                }
                TextInput {
                    id: searchInput
                    anchors.left: searchIcon.right; anchors.leftMargin: root.s(8)
                    anchors.right: parent.right; anchors.rightMargin: root.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchBox.open
                    font.family: Theme.font; font.pixelSize: root.s(13)
                    color: Theme.text
                    selectionColor: Theme.primary
                    onTextChanged: { root.query = text; view.currentIndex = 0; }
                    Keys.onEscapePressed: { text = ""; keyCatcher.forceActiveFocus(); }
                    Keys.onLeftPressed: event => { if (cursorPosition === 0) view.decrementCurrentIndex(); else event.accepted = false; }
                    Keys.onRightPressed: event => { if (cursorPosition === text.length) view.incrementCurrentIndex(); else event.accepted = false; }
                    Keys.onDownPressed: keyCatcher.forceActiveFocus()
                    Keys.onReturnPressed: if (root.shown.length) root.apply(root.shown[view.currentIndex].filePath)
                    Keys.onEnterPressed: if (root.shown.length) root.apply(root.shown[view.currentIndex].filePath)
                }
                MouseArea {
                    anchors.fill: parent
                    visible: !searchBox.open
                    cursorShape: Qt.PointingHandCursor
                    onClicked: searchInput.forceActiveFocus()
                }
            }
        }
    }

    // hint line
    SText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: view.bottom; anchors.topMargin: root.s(30)
        visible: root.visible && root.ready
        text: "←/→ browse · Enter apply · type to search · Ctrl+R random · Esc close"
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pixelSize: root.s(12)
    }
}
