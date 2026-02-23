import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.UI

PanelWindow {
    id: dockWindow

    required property var dock
    required property var dockScreen
    readonly property var dragCtrlRef: dock.dragCtrl
    readonly property var launchCtrlRef: dock.launchCtrl
    readonly property var workspaceCtrlRef: dock.workspaceCtrl

    screen: dockScreen
    visible: dock.enabled
    color: 'transparent'

    anchors {
        top: true
        right: false
        left: true
        bottom: true
    }

    margins {
        top: 0
        right: dock.getBarInsetForScreen(dockScreen, 'right')
        left: dock.getBarInsetForScreen(dockScreen, 'left')
        bottom: 0
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

        color: Qt.alpha(Color.mSurface, dock.backgroundOpacity)
        radius: Style.radiusXL

        implicitWidth: dockColumn.implicitWidth + 12

        Column {
            id: dockColumn
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 6
            spacing: dock.spacing

            move: Transition {
                NumberAnimation {
                    properties: 'x,y'
                    duration: Style.animationFast
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: dock.pinnedApps

                delegate: DockButton {
                    required property string modelData
                    appId: modelData
                    screen: dockScreen
                    dock: dockWindow.dock
                }
            }

            Rectangle {
                width: dock.iconSize * 0.6
                height: 1
                color: Qt.alpha(Color.mOutline, 0.65)
                anchors.horizontalCenter: parent.horizontalCenter
                visible: dock.unpinnedRunningApps.length > 0 && dock.pinnedApps.length > 0
            }

            Repeater {
                model: dock.unpinnedRunningApps

                delegate: DockButton {
                    required property string modelData
                    appId: modelData
                    screen: dockScreen
                    dock: dockWindow.dock
                    isPinnedEntry: false
                }
            }
        }

        Item {
            id: dockLauncherButton
            width: dock.iconSize + dock.buttonPadding
            height: dock.iconSize + dock.buttonPadding
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
                pointSize: dock.iconSize * 0.62
                color: launcherMouseArea.containsMouse ? Color.mPrimary : Color.mOnSurfaceVariant
            }

            MouseArea {
                id: launcherMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: (dragCtrlRef.dragActive || dragCtrlRef.leftPressActive) ? Qt.NoButton : Qt.LeftButton
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

            function mapToColumn(mouse) {
                return dockColumn.mapFromItem(dragCatcher, mouse.x, mouse.y);
            }

            onPressed: mouse => {
                const point = mapToColumn(mouse);
                dragCtrlRef.handlePressAt(point.x, point.y, dock.pinnedApps);
            }

            onPositionChanged: mouse => {
                if (!dragCtrlRef.leftPressActive) return;
                const point = mapToColumn(mouse);
                dragCtrlRef.handleMoveAt(point.y, Qt.styleHints.startDragDistance);
            }

            onReleased: {
                const appId = dragCtrlRef.handleRelease();
                if (appId) launchCtrlRef.activateOrLaunch(appId);
            }

            onCanceled: dragCtrlRef.handleCancel()
        }

        DragGhost {
            dock: dockWindow.dock
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const deltaY = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y;
                event.accepted = workspaceCtrlRef.handleDockWheel(deltaY, dockScreen);
            }
        }
    }
}
