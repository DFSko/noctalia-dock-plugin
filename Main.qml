import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.System
import qs.Services.Compositor
import qs.Services.UI
import "AppUtils.js" as AppUtils

Item {
    id: root

    property var pluginApi: null

    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property bool enabled: pluginApi?.pluginSettings?.enabled ?? defaults.enabled ?? true
    readonly property int iconSize: pluginApi?.pluginSettings?.iconSize ?? defaults.iconSize ?? 46
    readonly property int spacing: pluginApi?.pluginSettings?.spacing ?? defaults.spacing ?? 10
    readonly property int iconInset: pluginApi?.pluginSettings?.iconInset ?? defaults.iconInset ?? 2
    readonly property int buttonPadding: Math.max(0, iconInset * 2)
    readonly property real backgroundOpacity: pluginApi?.pluginSettings?.backgroundOpacity ?? defaults.backgroundOpacity ?? 0.78
    readonly property bool workspaceScrollEnabled: pluginApi?.pluginSettings?.workspaceScrollEnabled ?? defaults.workspaceScrollEnabled ?? true
    readonly property var pinnedApps: Settings?.data?.appLauncher?.pinnedApps || []
    property bool dragActive: false
    property string dragAppId: ''
    property bool leftPressActive: false
    property real leftPressColumnY: 0
    property string leftPressedAppId: ''
    property real dragColumnY: 0
    property string launchFeedbackAppKey: ''
    property real workspaceWheelAccumulator: 0

    function markLaunchFeedback(appId) {
        launchFeedbackAppKey = AppUtils.normalizeAppKey(appId);
        launchFeedbackTimer.restart();
    }

    function clearLaunchFeedback() {
        launchFeedbackAppKey = '';
    }

    function switchWorkspaceByOffset(offset, screenObj) {
        if (!CompositorService || !CompositorService.workspaces || CompositorService.workspaces.count === 0) return false;
        if (!offset) return false;

        const allWorkspaces = [];
        const localWorkspaces = [];
        const screenName = screenObj?.name || '';

        for (let i = 0; i < CompositorService.workspaces.count; i++) {
            const ws = CompositorService.workspaces.get(i);
            if (!ws) continue;
            allWorkspaces.push(ws);

            if (!CompositorService.globalWorkspaces && screenName && ws.output && ws.output !== screenName) continue;
            localWorkspaces.push(ws);
        }

        const targetList = localWorkspaces.length > 0 ? localWorkspaces : allWorkspaces;
        if (targetList.length === 0) return false;

        targetList.sort((a, b) => (a.idx || 0) - (b.idx || 0));

        let current = targetList.findIndex(ws => ws.isFocused === true);
        if (current < 0) current = 0;

        let next = (current + offset) % targetList.length;
        if (next < 0) next = targetList.length - 1;

        const targetWorkspace = targetList[next];
        if (!targetWorkspace) return false;

        CompositorService.switchToWorkspace(targetWorkspace);
        return true;
    }

    function handleDockWheel(deltaY, screenObj) {
        if (!workspaceScrollEnabled || deltaY === 0) return false;

        const effectiveDelta = -deltaY;
        workspaceWheelAccumulator += effectiveDelta;

        let switched = false;

        while (workspaceWheelAccumulator >= 120) {
            switched = switchWorkspaceByOffset(1, screenObj) || switched;
            workspaceWheelAccumulator -= 120;
        }

        while (workspaceWheelAccumulator <= -120) {
            switched = switchWorkspaceByOffset(-1, screenObj) || switched;
            workspaceWheelAccumulator += 120;
        }

        return switched;
    }

    Timer {
        id: launchFeedbackTimer
        interval: 1600
        repeat: false
        onTriggered: root.clearLaunchFeedback()
    }


    function getBarInsetForScreen(screenObj, edge) {
        const screenName = screenObj?.name;
        const barEdge = Settings.getBarPositionForScreen(screenName);
        if (barEdge !== edge) return 0;

        const displayMode = Settings.getBarDisplayModeForScreen(screenName);
        if (displayMode === 'non_exclusive') return 0;
        if (displayMode === 'auto_hide' && !BarService.isVisible) return 0;

        const barFloating = Settings.data.bar.floating || false;
        const barHeight = Style.getBarHeightForScreen(screenName);
        const marginV = barFloating ? Math.ceil(Settings.data.bar.marginVertical || 0) : 0;
        const marginH = barFloating ? Math.ceil(Settings.data.bar.marginHorizontal || 0) : 0;

        if (edge === 'top' || edge === 'bottom') return barHeight + marginV;
        return barHeight + marginH;
    }

    function launchApp(appId) {
        const normalized = AppUtils.normalizeDesktopId(appId);
        if (!normalized) {
            ToastService.showWarning('noctalia-dock-plugin: empty app id');
            return false;
        }

        const app = ThemeIcons.findAppEntry(normalized);
        if (!app) {
            ToastService.showWarning(`noctalia-dock-plugin: app not found: ${normalized}`);
            return false;
        }

        if (Settings.data.appLauncher.customLaunchPrefixEnabled && Settings.data.appLauncher.customLaunchPrefix) {
            const prefix = Settings.data.appLauncher.customLaunchPrefix.split(' ');

            if (app.runInTerminal) {
                const terminal = Settings.data.appLauncher.terminalCommand.split(' ');
                const command = prefix.concat(terminal.concat(app.command || []));
                Quickshell.execDetached(command);
            } else {
                const command = prefix.concat(app.command || []);
                Quickshell.execDetached(command);
            }
            return true;
        }

        if (Settings.data.appLauncher.useApp2Unit && ProgramCheckerService.app2unitAvailable && app.id) {
            if (app.runInTerminal) {
                Quickshell.execDetached(['app2unit', '--', app.id + '.desktop']);
            } else {
                Quickshell.execDetached(['app2unit', '--'].concat(app.command || []));
            }
            return true;
        }

        if (app.runInTerminal) {
            const terminal = Settings.data.appLauncher.terminalCommand.split(' ');
            const command = terminal.concat(app.command || []);
            CompositorService.spawn(command);
            return true;
        } else if (app.command && app.command.length > 0) {
            CompositorService.spawn(app.command);
            return true;
        } else if (app.execute) {
            app.execute();
            return true;
        }

        Logger.w('noctalia-dock-plugin', `Could not launch: ${normalized}. No valid launch method.`);
        return false;
    }

    function findMatchingToplevels(appId) {
        const target = String(appId || '').trim();
        if (!target) return [];
        return ToplevelManager.toplevels.values.filter(t => AppUtils.appIdsMatch(target, t?.appId));
    }

    function getPreferredToplevel(appId) {
        const matches = findMatchingToplevels(appId);
        if (matches.length === 0) return null;
        const active = ToplevelManager?.activeToplevel;
        if (active && matches.includes(active)) return active;
        return matches[0];
    }

    function focusApp(appId) {
        const toplevel = getPreferredToplevel(appId);
        if (!toplevel) return false;
        toplevel.activate();
        return true;
    }

    function closeApp(appId) {
        const toplevel = getPreferredToplevel(appId);
        if (!toplevel) return false;
        toplevel.close();
        return true;
    }

    function activateOrLaunch(appId) {
        if (!focusApp(appId) && launchApp(appId)) {
            markLaunchFeedback(appId);
        }
    }

    function isAppPinned(appId) {
        const target = AppUtils.normalizeAppKey(appId);
        const arr = Settings.data.appLauncher.pinnedApps || [];
        return arr.some(p => AppUtils.normalizeAppKey(p) === target);
    }

    function togglePin(appId) {
        const target = AppUtils.normalizeAppKey(appId);
        if (!target) return;

        let arr = (Settings.data.appLauncher.pinnedApps || []).slice();
        const idx = arr.findIndex(p => AppUtils.normalizeAppKey(p) === target);
        if (idx >= 0) arr.splice(idx, 1);
        else arr.push(AppUtils.normalizeDesktopId(appId));
        Settings.data.appLauncher.pinnedApps = arr;
    }

    function indexOfPinnedApp(appId) {
        const target = AppUtils.normalizeAppKey(appId);
        if (!target) return -1;
        const arr = Settings.data.appLauncher.pinnedApps || [];
        return arr.findIndex(p => AppUtils.normalizeAppKey(p) === target);
    }

    function movePinnedAppToIndex(appId, targetIndex) {
        const arr = (Settings.data.appLauncher.pinnedApps || []).slice();
        const sourceIndex = indexOfPinnedApp(appId);
        if (sourceIndex < 0 || arr.length <= 1) return false;

        const clampedTarget = Math.max(0, Math.min(arr.length - 1, targetIndex));
        if (sourceIndex === clampedTarget) return false;

        const moved = arr.splice(sourceIndex, 1)[0];
        arr.splice(clampedTarget, 0, moved);
        Settings.data.appLauncher.pinnedApps = arr;
        return true;
    }

    function beginDrag(appId) {
        dragAppId = AppUtils.normalizeDesktopId(appId);
        dragColumnY = leftPressColumnY;
        dragActive = dragAppId !== '';
    }

    function updateDragTargetFromColumnY(columnY) {
        if (!dragActive) return;

        const arr = Settings.data.appLauncher.pinnedApps || [];
        if (arr.length <= 1) return;

        const buttonExtent = iconSize + buttonPadding;
        const step = buttonExtent + spacing;
        if (step <= 0 || buttonExtent <= 0) return;

        const rawIndex = Math.round((columnY - (buttonExtent * 0.5)) / step);
        movePinnedAppToIndex(dragAppId, rawIndex);
    }

    function endDrag() {
        dragActive = false;
        dragAppId = '';
        dragColumnY = 0;
    }

    function clearPointerState() {
        leftPressActive = false;
        leftPressColumnY = 0;
        leftPressedAppId = '';
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            readonly property var dockScreen: modelData

            screen: dockScreen
            visible: root.enabled
            color: 'transparent'

            anchors {
                top: true
                right: false
                left: true
                bottom: true
            }

            margins {
                top: root.getBarInsetForScreen(dockScreen, 'top')
                right: root.getBarInsetForScreen(dockScreen, 'right')
                left: root.getBarInsetForScreen(dockScreen, 'left')
                bottom: root.getBarInsetForScreen(dockScreen, 'bottom')
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: 'noctalia:noctalia-dock-plugin'
            WlrLayershell.exclusionMode: ExclusionMode.Auto

            implicitWidth: dockWrap.implicitWidth
            implicitHeight: dockWrap.implicitHeight

            mask: Region { item: dockWrap }

            Rectangle {
                id: dockWrap
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                color: Qt.alpha(Color.mSurface, root.backgroundOpacity)
                radius: Style.radiusXL

                implicitWidth: dockColumn.implicitWidth + 12

                Column {
                    id: dockColumn
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 6
                    spacing: root.spacing

                    move: Transition {
                        NumberAnimation {
                            properties: 'x,y'
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: root.pinnedApps

                        delegate: DockButton {
                            required property var modelData
                            appId: String(modelData)
                            screen: dockScreen
                            dock: root
                        }
                    }
                }

                Item {
                    id: dockLauncherButton
                    width: root.iconSize + root.buttonPadding
                    height: root.iconSize + root.buttonPadding
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.iRadiusM
                        color: launcherMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.20) : 'transparent'

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    NIcon {
                        anchors.centerIn: parent
                        icon: 'grid-dots'
                        pointSize: root.iconSize * 0.62
                        color: launcherMouseArea.containsMouse ? Color.mPrimary : Color.mOnSurfaceVariant
                    }

                    MouseArea {
                        id: launcherMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: (root.dragActive || root.leftPressActive || root.ctrlHeld) ? Qt.LeftButton : Qt.NoButton
                        onClicked: PanelService.toggleLauncher(dockScreen)
                    }
                }

                MouseArea {
                    id: dragCatcher
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: dockLauncherButton.top
                    anchors.bottomMargin: 6
                    z: -1
                    hoverEnabled: false
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true

                    onPressed: mouse => {
                        const point = dockColumn.mapFromItem(dragCatcher, mouse.x, mouse.y);
                        const arr = Settings.data.appLauncher.pinnedApps || [];
                        if (arr.length === 0) return;

                        const step = root.iconSize + root.buttonPadding + root.spacing;
                        if (step <= 0) return;

                        const rawIndex = Math.floor(point.y / step);
                        const index = Math.max(0, Math.min(arr.length - 1, rawIndex));

                        root.leftPressActive = true;
                        root.leftPressColumnY = point.y;
                        root.dragColumnY = point.y;
                        root.leftPressedAppId = String(arr[index] || '');
                    }

                    onPositionChanged: mouse => {
                        if (!root.leftPressActive) return;
                        const point = dockColumn.mapFromItem(dragCatcher, mouse.x, mouse.y);
                        root.dragColumnY = point.y;

                        if (!root.dragActive) {
                            const dragDistance = Math.abs(point.y - root.leftPressColumnY);
                            if (dragDistance >= Qt.styleHints.startDragDistance && root.leftPressedAppId) {
                                root.beginDrag(root.leftPressedAppId);
                            }
                        }

                        if (root.dragActive) {
                            root.updateDragTargetFromColumnY(point.y);
                        }
                    }

                    onReleased: {
                        if (root.dragActive) {
                            root.endDrag();
                            root.clearPointerState();
                            return;
                        }
                        const appId = root.leftPressedAppId;
                        root.clearPointerState();
                        if (appId) root.activateOrLaunch(appId);
                    }

                    onCanceled: {
                        root.endDrag();
                        root.clearPointerState();
                    }
                }

                DragGhost {
                    dock: root
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const deltaY = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y;
                        event.accepted = root.handleDockWheel(deltaY, dockScreen);
                    }
                }
            }
        }
    }
}
