import QtQuick
import qs.Services.Compositor
import "utils/workspaceLogic.js" as WorkspaceLogic

QtObject {
    id: controller

    property bool workspaceScrollEnabled: true
    property real workspaceWheelAccumulator: 0

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
        const wheelState = WorkspaceLogic.wheelOffsetsFromDelta(
            workspaceWheelAccumulator,
            deltaY,
            workspaceScrollEnabled,
            120
        );
        workspaceWheelAccumulator = wheelState.accumulator;
        if (wheelState.offsets.length === 0) return false;

        return wheelState.offsets.reduce(
            (switched, offset) => switchWorkspaceByOffset(offset, screenObj) || switched,
            false
        );
    }
}
