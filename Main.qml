import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.System
import qs.Services.UI
import "utils/mainLogic.js" as MainLogic

Item {
    id: root

    property var pluginApi: null

    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    function settingValue(key, fallback) {
        const settings = pluginApi?.pluginSettings;
        const configured = settings ? settings[key] : undefined;
        if (configured !== undefined && configured !== null) return configured;

        const defaultValue = defaults ? defaults[key] : undefined;
        if (defaultValue !== undefined && defaultValue !== null) return defaultValue;

        return fallback;
    }

    readonly property bool enabled: settingValue('enabled', true)
    readonly property int iconSize: settingValue('iconSize', 46)
    readonly property int spacing: settingValue('spacing', 10)
    readonly property int iconInset: settingValue('iconInset', 2)
    readonly property int buttonPadding: Math.max(0, iconInset * 2)
    readonly property real backgroundOpacity: settingValue('backgroundOpacity', 0.78)
    readonly property bool workspaceScrollEnabled: settingValue('workspaceScrollEnabled', true)
    readonly property var pinnedApps: Settings?.data?.appLauncher?.pinnedApps || []
    readonly property DockLaunchController launchCtrl: launchController
    readonly property DockDragController dragCtrl: dragController
    readonly property DockWorkspaceController workspaceCtrl: workspaceController
    property string notificationShakeAppKey: ''
    property int _prevNotifCount: 0
    property var unpinnedRunningApps: []

    DockLaunchController {
        id: launchController
        dock: root
    }

    DockDragController {
        id: dragController
        dock: root
    }

    DockWorkspaceController {
        id: workspaceController
        workspaceScrollEnabled: root.workspaceScrollEnabled
    }

    function updateUnpinnedRunningApps() {
        unpinnedRunningApps = MainLogic.collectUnpinnedRunningApps(
            ToplevelManager?.toplevels?.values || [],
            root.pinnedApps
        );
    }

    function triggerNotificationShake(notifAppName) {
        const appKey = MainLogic.notificationShakeAppKey(notifAppName, root.pinnedApps);
        if (!appKey) return;
        notificationShakeAppKey = appKey;
        notificationShakeTimer.restart();
    }

    Timer {
        id: notificationShakeTimer
        interval: 1000
        repeat: false
        onTriggered: root.notificationShakeAppKey = ''
    }

    Connections {
        target: ToplevelManager.toplevels
        function onValuesChanged() {
            root.updateUnpinnedRunningApps();
            launchController.tryFocusPendingLaunch();
        }
    }

    onPinnedAppsChanged: updateUnpinnedRunningApps()

    Connections {
        target: NotificationService.activeList
        function onCountChanged() {
            const count = NotificationService.activeList.count;
            if (count > root._prevNotifCount && count > 0) {
                const notif = NotificationService.activeList.get(0);
                if (notif && notif.appName)
                    root.triggerNotificationShake(notif.appName);
            }
            root._prevNotifCount = count;
        }
    }


    function getBarInsetForScreen(screenObj, edge) {
        const screenName = screenObj?.name;
        return MainLogic.computeBarInset(
            edge,
            Settings.getBarPositionForScreen(screenName),
            Settings.getBarDisplayModeForScreen(screenName),
            BarService.isVisible,
            Settings?.data?.bar?.floating || false,
            Settings?.data?.bar?.marginHorizontal || 0,
            Style.getBarHeightForScreen(screenName)
        );
    }

    Variants {
        model: Quickshell.screens

        delegate: DockWindow {
            required property var modelData
            dock: root
            dockScreen: modelData
        }
    }
}
