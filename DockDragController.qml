import QtQuick
import qs.Commons
import "utils/pinnedAppsLogic.js" as PinnedAppsLogic

QtObject {
    id: controller

    required property var dock

    property bool dragActive: false
    property string dragAppId: ''
    property bool leftPressActive: false
    property real leftPressColumnY: 0
    property string leftPressedAppId: ''
    property real dragColumnY: 0

    function _pinnedApps() {
        return Settings?.data?.appLauncher?.pinnedApps || [];
    }

    function _writePinnedApps(arr) {
        if (!Settings?.data?.appLauncher) return false;
        Settings.data.appLauncher.pinnedApps = arr;
        return true;
    }

    function isAppPinned(appId) {
        return PinnedAppsLogic.isAppPinned(_pinnedApps(), appId);
    }

    function togglePin(appId) {
        const next = PinnedAppsLogic.togglePinnedApp(_pinnedApps(), appId);
        if (!next) return false;
        return _writePinnedApps(next);
    }

    function indexOfPinnedApp(appId) {
        return PinnedAppsLogic.indexOfPinnedApp(_pinnedApps(), appId);
    }

    function movePinnedAppToIndex(appId, targetIndex) {
        const result = PinnedAppsLogic.movePinnedAppToIndex(_pinnedApps(), appId, targetIndex);
        if (!result.changed) return false;
        return _writePinnedApps(result.items);
    }

    function beginDrag(appId) {
        const state = PinnedAppsLogic.beginDragState(appId, leftPressColumnY);
        dragAppId = state.dragAppId;
        dragColumnY = state.dragColumnY;
        dragActive = state.dragActive;
    }

    function updateDragTargetFromColumnY(columnY) {
        if (!dragActive) return;

        const arr = _pinnedApps();
        if (arr.length <= 1) return;

        const rawIndex = PinnedAppsLogic.reorderTargetIndex(
            columnY,
            dock.iconSize,
            dock.buttonPadding,
            dock.spacing
        );
        if (rawIndex === null) return;
        movePinnedAppToIndex(dragAppId, rawIndex);
    }

    function endDrag() {
        dragActive = false;
        dragAppId = '';
        dragColumnY = 0;
    }

    function indexAtColumnY(columnY, appCount) {
        return PinnedAppsLogic.indexAtColumnY(columnY, appCount, dock.iconSize, dock.buttonPadding, dock.spacing);
    }

    function clearPointerState() {
        leftPressActive = false;
        leftPressColumnY = 0;
        leftPressedAppId = '';
    }
}
