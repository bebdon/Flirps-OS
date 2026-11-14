import QtQuick
import Quickshell
import Quickshell.Io

// Resident overlays (app launcher + power menu), opened over IPC:
//   qs -c panels ipc call launcher toggle
//   qs -c panels ipc call power toggle
//   qs -c panels ipc call clipboard toggle
//   qs -c panels ipc call wallpapers toggle
//   qs -c panels ipc call cheatsheet toggle      (SUPER+K)
//   qs -c panels ipc call overview toggle        (SUPER+Tab)
ShellRoot {
    id: shellRoot
    Launcher { id: launcher }
    PowerMenu { id: power }
    Clipboard { id: clip }
    Wallpapers { id: walls }
    QuickSettings {
        id: qs
        onOpenPower: { qs.close(); power.open(); }
        onOpenMedia: { qs.close(); media.open(); }
    }
    Dashboard { id: dash }
    MediaPopup { id: media }
    Desktop {
        id: desktop
        onContextMenu: (x, y) => { shellRoot.closeAll(); desktopMenu.openAt(x, y); }
    }
    DesktopMenu {
        id: desktopMenu
        onWallpapers: walls.open()
        onEditWidgets: desktop.editing = true
        onShortcuts: cheatsheet.open()
    }
    Cheatsheet { id: cheatsheet }
    Overview {
        id: overview
        onSearchApps: text => launcher.setQuery(text)
    }
    CalcTool { id: calcTool }
    TimerTool { id: timerTool }
    NotesTool { id: notesTool }
    Osd { id: osd }
    Bar { }
    Dock { }
    Polkit { }
    NotifPopups { }
    NotifCenter { id: notifCenter }
    Rotator { id: rotator }

    function closeAll() { launcher.close(); power.close(); clip.close(); walls.close(); qs.close(); dash.close(); media.close(); notifCenter.close(); cheatsheet.close(); overview.close(); desktopMenu.close(); }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { const v = cheatsheet.shown; shellRoot.closeAll(); if (!v) cheatsheet.open(); }
        function close(): void { cheatsheet.close(); }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { const v = overview.shown; shellRoot.closeAll(); if (!v) overview.open(); }
        function close(): void { overview.close(); }
    }
    IpcHandler {
        target: "desktopmenu"
        function open(x: int, y: int): void { shellRoot.closeAll(); desktopMenu.openAt(x, y); }   // for testing; normally right-click
        function close(): void { desktopMenu.close(); }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { const v = launcher.visible; shellRoot.closeAll(); if (!v) launcher.open(); }
        function close(): void { launcher.close(); }
        function query(text: string): void { shellRoot.closeAll(); launcher.setQuery(text); }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { const v = power.visible; shellRoot.closeAll(); if (!v) power.open(); }
        function close(): void { power.close(); }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void { const v = clip.visible; shellRoot.closeAll(); if (!v) clip.open(); }
        function close(): void { clip.close(); }
    }
    IpcHandler {
        target: "wallpapers"
        function toggle(): void { const v = walls.visible; shellRoot.closeAll(); if (!v) walls.open(); }
        function close(): void { walls.close(); }
    }
    IpcHandler {
        target: "quicksettings"
        function toggle(): void { const v = qs.shown; shellRoot.closeAll(); if (!v) qs.open(); }
        function close(): void { qs.close(); }
        function expand(list: string): void { qs.expandedList = list; }
    }
    IpcHandler {
        target: "dashboard"
        function toggle(): void { const v = dash.shown; shellRoot.closeAll(); if (!v) dash.open(); }
        function close(): void { dash.close(); }
    }
    IpcHandler {
        target: "media"
        function toggle(): void { const v = media.shown; shellRoot.closeAll(); if (!v) media.open(); }
        function close(): void { media.close(); }
    }
    IpcHandler {
        target: "desktop"
        function edit(): void { desktop.editing = !desktop.editing; }
        function reload(): void { }
    }
    IpcHandler {
        target: "calculator"
        function toggle(): void { calcTool.toggle(); }
    }
    IpcHandler {
        target: "timer"
        function toggle(): void { timerTool.toggle(); }
    }
    IpcHandler {
        target: "notes"
        function toggle(): void { notesTool.toggle(); }
    }
    IpcHandler {
        target: "osd"
        function locks(key: string): void { osd.locks(key); }
        function brightness(): void { osd.brightness(); }
        function show(title: string, detail: string): void { osd.show(0xF02FC, title, detail, true); }
    }
    IpcHandler {
        target: "notifcenter"
        function toggle(): void { const v = notifCenter.shown; shellRoot.closeAll(); if (!v) notifCenter.open(); }
        function close(): void { notifCenter.close(); }
    }
    IpcHandler {
        target: "bar"
        function toggle(): void { BarCfg.hidden = !BarCfg.hidden; }
        function refresh(): void { BarCfg.refreshNightlight(); }
    }
}
