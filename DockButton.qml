import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "utils/appIdLogic.js" as AppIdLogic
import "utils/dockButtonLogic.js" as DockButtonLogic

Item {
    id: dockButton

    required property string appId
    required property var screen
    required property var dock

    property bool isPinnedEntry: true
    property bool hovering: !contextMenu.visible && buttonArea.containsMouse && !isDragPlaceholder
    readonly property bool isDragPlaceholder: dock.dragCtrl.dragActive && AppIdLogic.normalizeAppKey(dock.dragCtrl.dragAppId) === AppIdLogic.normalizeAppKey(appId)
    readonly property string iconSource: ThemeIcons.iconForAppId(AppIdLogic.normalizeDesktopId(appId).toLowerCase())
    readonly property string tooltipLabel: {
        const entry = DesktopEntries.heuristicLookup(appId);
        const entryName = String(entry?.name || '').trim();
        if (entryName) return entryName;

        const fallbackName = String(appId || '').trim();
        if (fallbackName) return fallbackName.replace(/\.desktop$/i, '');

        return AppIdLogic.displayNameFor(appId);
    }
    readonly property string tooltipDirection: 'right'
    readonly property int runningCount: Math.min(3, dock.launchCtrl.findMatchingToplevels(appId).length)
    readonly property bool isRunning: runningCount > 0
    readonly property bool isLaunchPending: !isRunning && dock.launchCtrl.launchFeedbackAppKey !== '' && dock.launchCtrl.launchFeedbackAppKey === AppIdLogic.normalizeAppKey(appId)
    readonly property bool isShaking: dock.notificationShakeAppKey !== ''
        && dock.notificationShakeAppKey === AppIdLogic.normalizeAppKey(appId)
        && !isDragPlaceholder
    property var desktopActions: []

    width: dock.iconSize + dock.buttonPadding
    height: dock.iconSize + dock.buttonPadding

    function buildContextModel() {
        const running = isRunning;
        const pinned = dock.dragCtrl.isAppPinned(appId);
        const entry = DesktopEntries.heuristicLookup(appId);
        const actions = (entry && entry.actions) ? entry.actions : [];
        desktopActions = actions;

        return DockButtonLogic.buildContextModel(running, pinned, actions, {
            launch: I18n.tr('common.execute'),
            focus: I18n.tr('common.focus'),
            pin: I18n.tr('common.pin'),
            unpin: I18n.tr('common.unpin'),
            close: I18n.tr('common.close')
        });
    }

    function triggerMenuAction(actionKey) {
        switch (actionKey) {
        case 'launch':
            if (dock.launchCtrl.launchApp(appId)) dock.launchCtrl.markLaunchFeedback(appId);
            return;
        case 'focus':
            dock.launchCtrl.focusApp(appId);
            return;
        case 'pin':
        case 'unpin':
            dock.dragCtrl.togglePin(appId);
            return;
        case 'close':
            dock.launchCtrl.closeApp(appId);
            return;
        default:
            break;
        }

        const idx = DockButtonLogic.desktopActionIndex(actionKey);
        if (idx >= 0) {
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
            text: AppIdLogic.displayNameFor(dockButton.appId)
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
        acceptedButtons: dockButton.isPinnedEntry ? Qt.RightButton : (Qt.RightButton | Qt.LeftButton)
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (dockButton.isDragPlaceholder || !dockButton.tooltipLabel) return;
            TooltipService.show(dockButton, dockButton.tooltipLabel, dockButton.tooltipDirection);
        }
        onExited: TooltipService.hide()

        onClicked: mouse => {
            TooltipService.hide();
            if (mouse.button === Qt.RightButton) {
                contextMenu.model = dockButton.buildContextModel();
                PanelService.showContextMenu(contextMenu, contextAnchor, dockButton.screen);
            } else if (mouse.button === Qt.LeftButton) {
                dock.launchCtrl.activateOrLaunch(dockButton.appId);
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
