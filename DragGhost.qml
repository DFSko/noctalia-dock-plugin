import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import "utils/appIdLogic.js" as AppIdLogic

Item {
    id: dragGhost

    required property var dock

    z: 90
    visible: dock.dragCtrl.dragActive && dock.dragCtrl.dragAppId !== ''
    width: dock.iconSize + dock.buttonPadding
    height: dock.iconSize + dock.buttonPadding
    x: (parent.width - width) * 0.5
    y: Math.max(0, Math.min(parent.height - height, dock.dragCtrl.dragColumnY - height * 0.5))
    opacity: dock.dragCtrl.dragActive ? 0.94 : 0
    scale: dock.dragCtrl.dragActive ? 1.06 : 0.97

    Behavior on y {
        NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.iRadiusM
        color: Qt.alpha(Color.mPrimary, 0.16)
    }

    Rectangle {
        width: dock.iconSize
        height: dock.iconSize
        anchors.centerIn: parent
        radius: Style.iRadiusM
        color: 'transparent'
        clip: true

        IconImage {
            id: dragGhostIcon
            anchors.fill: parent
            anchors.margins: dock.iconInset
            source: ThemeIcons.iconForAppId(AppIdLogic.normalizeDesktopId(dock.dragCtrl.dragAppId).toLowerCase())
            visible: source.toString() !== ''
            smooth: true
            asynchronous: true
        }

        NText {
            anchors.centerIn: parent
            visible: !dragGhostIcon.visible
            text: AppIdLogic.displayNameFor(dock.dragCtrl.dragAppId)
            color: Color.mOnSurface
            pointSize: Math.max(10, dock.iconSize * 0.26)
            font.weight: Style.fontWeightBold
        }
    }
}
