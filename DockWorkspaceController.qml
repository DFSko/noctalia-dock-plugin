import QtQuick
import qs.Services.Compositor
import "utils/workspaceLogic.js" as WorkspaceLogic

QtObject {
    id: controller

    property bool workspaceScrollEnabled: true
    property int workspaceScrollSpeed: 4
    property real workspaceWheelAccumulator: 0
    property real _lastWheelTime: Date.now()

    function switchWorkspaceByOffset(offset, screenObj) {
        const service = CompositorService;
        const model = service?.workspaces;
        if (!model || !offset || model.count === 0) return false;

        const targetWorkspace = WorkspaceLogic.selectWorkspaceTarget(
            model,
            service.globalWorkspaces,
            screenObj?.name || '',
            offset
        );
        if (!targetWorkspace) return false;

        service.switchToWorkspace(targetWorkspace);
        return true;
    }

    function handleDockWheel(deltaY, screenObj) {
        if (!workspaceScrollEnabled || deltaY === 0) return false;

        // Convert speed (ws/sec) to delay (ms): 1 ws/sec = 1000ms, 10 ws/sec = 100ms
        const wheelDebounceMs = 1000 / workspaceScrollSpeed;

        const now = Date.now();
        const timeSinceLastWheel = _lastWheelTime > 0 ? (now - _lastWheelTime) : wheelDebounceMs;

        // Ignore event if debounce is still active
        if (timeSinceLastWheel < wheelDebounceMs) {
            return false;
        }

        // Reset accumulator after debounce so old accumulation doesn't affect
        workspaceWheelAccumulator = 0;

        // Accumulate current delta
        const step = 120;
        workspaceWheelAccumulator += (-deltaY);

        // Check if enough delta accumulated for switch
        if (Math.abs(workspaceWheelAccumulator) < step) {
            return false;
        }

        // Determine direction and keep remainder
        const offset = workspaceWheelAccumulator >= 0 ? 1 : -1;
        workspaceWheelAccumulator -= (offset * step);
        controller._lastWheelTime = now;

        return switchWorkspaceByOffset(offset, screenObj);
    }
}
