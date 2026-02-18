import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "AppUtils.js" as AppUtils

Item {
    id: dockButton

    required property string appId
    required property var screen
    required property var dock

    property bool hovering: !contextMenu.visible && buttonArea.containsMouse && !isDragPlaceholder
    readonly property bool isDragPlaceholder: dock.dragActive && AppUtils.normalizeAppKey(dock.dragAppId) === AppUtils.normalizeAppKey(appId)
    readonly property string iconSource: ThemeIcons.iconForAppId(AppUtils.normalizeDesktopId(appId).toLowerCase())
    readonly property int runningCount: Math.min(3, dock.findMatchingToplevels(appId).length)
    readonly property bool isRunning: runningCount > 0
    readonly property bool isLaunchPending: !isRunning && dock.launchFeedbackAppKey !== '' && dock.launchFeedbackAppKey === AppUtils.normalizeAppKey(appId)
    readonly property bool isShaking: dock.notificationShakeAppKey !== ''
        && dock.notificationShakeAppKey === AppUtils.normalizeAppKey(appId)
        && !isDragPlaceholder
    property var desktopActions: []

    width: dock.iconSize + dock.buttonPadding
    height: dock.iconSize + dock.buttonPadding

    function buildContextModel() {
        const next = [];
        const running = isRunning;
        const pinned = dock.isAppPinned(appId);

        next.push({ key: 'launch', label: I18n.tr('common.execute'), icon: 'play' });

        if (running) {
            next.push({ key: 'focus', label: I18n.tr('common.focus'), icon: 'eye' });
        }

        next.push({
            key: pinned ? 'unpin' : 'pin',
            label: pinned ? I18n.tr('common.unpin') : I18n.tr('common.pin'),
            icon: pinned ? 'unpin' : 'pin'
        });

        if (running) {
            next.push({ key: 'close', label: I18n.tr('common.close'), icon: 'close' });
        }

        const entry = DesktopEntries.heuristicLookup(appId);
        const actions = (entry && entry.actions) ? entry.actions : [];
        desktopActions = actions;

        for (let i = 0; i < actions.length; i++) {
            next.push({ key: `desktop-${i}`, label: actions[i].name, icon: 'chevron-right' });
        }

        return next;
    }

    function triggerMenuAction(actionKey) {
        if (actionKey === 'launch') {
            if (dock.launchApp(appId)) dock.markLaunchFeedback(appId);
            return;
        }
        if (actionKey === 'focus') {
            dock.focusApp(appId);
            return;
        }
        if (actionKey === 'pin' || actionKey === 'unpin') {
            dock.togglePin(appId);
            return;
        }
        if (actionKey === 'close') {
            dock.closeApp(appId);
            return;
        }
        if (actionKey.startsWith('desktop-')) {
            const idx = parseInt(actionKey.replace('desktop-', ''), 10);
            const action = desktopActions[idx];
            if (!action) return;
            if (action.command && action.command.length > 0) {
                Quickshell.execDetached(action.command);
            } else if (action.execute) {
                action.execute();
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu
        model: []

        onTriggered: action => {
            dockButton.triggerMenuAction(action);
            PanelService.closeContextMenu(dockButton.screen);
        }
    }

    Item {
        id: contextAnchor
        width: 1
        height: 1
        y: parent.height * 0.5
        x: {
            const pos = Settings.getBarPositionForScreen(dockButton.screen?.name);
            const menuWidth = Math.max(contextMenu.calculatedWidth || 0, contextMenu.implicitWidth || 0);

            if (pos === 'right') {
                return parent.width + menuWidth + Style.marginM + 4;
            }
            if (pos === 'left') {
                return parent.width + 4 - (1 + Style.marginM);
            }
            return parent.width + 4 + (menuWidth * 0.5) - 0.5;
        }
        opacity: 0
    }


    Rectangle {
        anchors.fill: parent
        radius: Style.iRadiusM
        color: (dockButton.hovering && !dockButton.isDragPlaceholder) ? Qt.alpha(Color.mPrimary, 0.20) : 'transparent'

        Behavior on color {
            ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: launchPulse
        anchors.centerIn: parent
        width: dock.iconSize + Math.max(0, dock.buttonPadding - 2)
        height: dock.iconSize + Math.max(0, dock.buttonPadding - 2)
        radius: Style.iRadiusM
        color: 'transparent'
        border.width: 1
        border.color: Qt.alpha(Color.mPrimary, 0.9)
        visible: dockButton.isLaunchPending && !dockButton.isDragPlaceholder
        opacity: 0.25

        SequentialAnimation on opacity {
            running: launchPulse.visible
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.20
                to: 0.92
                duration: 360
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                from: 0.92
                to: 0.20
                duration: 360
                easing.type: Easing.InOutCubic
            }
        }
    }

    Rectangle {
        id: iconContainer
        width: dock.iconSize
        height: dock.iconSize
        anchors.centerIn: parent
        radius: Style.iRadiusM
        color: 'transparent'
        clip: true
        transformOrigin: Item.Center

        SequentialAnimation on rotation {
            running: dockButton.isShaking
            loops: 2

            NumberAnimation { from: 0; to: 45; duration: 65; easing.type: Easing.OutCubic }
            NumberAnimation { from: 45; to: -45; duration: 135; easing.type: Easing.InOutCubic }
            NumberAnimation { from: -45; to: 25; duration: 115; easing.type: Easing.InOutCubic }
            NumberAnimation { from: 25; to: -25; duration: 115; easing.type: Easing.InOutCubic }
            NumberAnimation { from: -25; to: 0; duration: 70; easing.type: Easing.InCubic }
        }

        SequentialAnimation on scale {
            running: dockButton.isShaking
            loops: 1

            NumberAnimation { from: 1.0; to: 1.5; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { from: 1.5; to: 1.0; duration: 500; easing.type: Easing.InCubic }
        }

        IconImage {
            id: appIcon
            anchors.fill: parent
            anchors.margins: dock.iconInset
            source: dockButton.iconSource
            visible: source.toString() !== '' && !dockButton.isDragPlaceholder
            smooth: true
            asynchronous: true
        }

        NText {
            anchors.centerIn: parent
            visible: !appIcon.visible && !dockButton.isDragPlaceholder
            text: AppUtils.displayNameFor(dockButton.appId)
            color: Color.mOnSurface
            pointSize: Math.max(10, dock.iconSize * 0.26)
            font.weight: Style.fontWeightBold
        }

        Rectangle {
            visible: dockButton.isDragPlaceholder
            anchors.fill: parent
            color: 'transparent'
            radius: Style.iRadiusM
            border.width: 1
            border.color: Qt.alpha(Color.mOutline, 0.65)
        }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.model = dockButton.buildContextModel();
                PanelService.showContextMenu(contextMenu, contextAnchor, dockButton.screen);
            }
        }
    }

    Column {
        visible: dockButton.runningCount > 0 && !dockButton.isDragPlaceholder
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: dockButton.runningCount

            Rectangle {
                width: 5
                height: 5
                radius: 3
                color: Color.mPrimary
            }
        }
    }

}
