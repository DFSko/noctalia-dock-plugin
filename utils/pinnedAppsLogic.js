.import "appIdLogic.js" as AppIdLogic

function isAppPinned(pinnedApps, appId) {
    const target = AppIdLogic.normalizeAppKey(appId);
    if (!target) return false;

    const arr = pinnedApps || [];
    return arr.some(p => AppIdLogic.normalizeAppKey(p) === target);
}

function togglePinnedApp(pinnedApps, appId) {
    const target = AppIdLogic.normalizeAppKey(appId);
    if (!target) return null;

    const arr = (pinnedApps || []).slice();
    const idx = arr.findIndex(p => AppIdLogic.normalizeAppKey(p) === target);
    if (idx >= 0) {
        arr.splice(idx, 1);
        return arr;
    }

    const normalized = AppIdLogic.normalizeDesktopId(appId);
    if (!normalized) return null;
    arr.push(normalized);
    return arr;
}

function indexOfPinnedApp(pinnedApps, appId) {
    const target = AppIdLogic.normalizeAppKey(appId);
    if (!target) return -1;

    const arr = pinnedApps || [];
    return arr.findIndex(p => AppIdLogic.normalizeAppKey(p) === target);
}

function movePinnedAppToIndex(pinnedApps, appId, targetIndex) {
    const arr = (pinnedApps || []).slice();
    const sourceIndex = indexOfPinnedApp(arr, appId);
    if (sourceIndex < 0 || arr.length <= 1) {
        return { changed: false, items: arr };
    }

    const clampedTarget = Math.max(0, Math.min(arr.length - 1, targetIndex));
    if (sourceIndex === clampedTarget) {
        return { changed: false, items: arr };
    }

    const moved = arr.splice(sourceIndex, 1)[0];
    arr.splice(clampedTarget, 0, moved);
    return { changed: true, items: arr };
}

function beginDragState(appId, leftPressColumnY) {
    const dragAppId = AppIdLogic.normalizeDesktopId(appId);
    return {
        dragAppId: dragAppId,
        dragColumnY: leftPressColumnY,
        dragActive: dragAppId !== ''
    };
}

function _buttonStep(iconSize, buttonPadding, spacing) {
    if (iconSize <= 0 || buttonPadding < 0 || spacing < 0) return null;
    const buttonExtent = iconSize + buttonPadding;
    const step = buttonExtent + spacing;
    return (step > 0 && buttonExtent > 0) ? { buttonExtent, step } : null;
}

function reorderTargetIndex(columnY, iconSize, buttonPadding, spacing) {
    const metrics = _buttonStep(iconSize, buttonPadding, spacing);
    if (!metrics) return null;
    return Math.round((columnY - (metrics.buttonExtent * 0.5)) / metrics.step);
}

function indexAtColumnY(columnY, appCount, iconSize, buttonPadding, spacing) {
    if (appCount <= 0) return -1;

    const metrics = _buttonStep(iconSize, buttonPadding, spacing);
    if (!metrics) return -1;

    const rawIndex = Math.floor(columnY / metrics.step);
    if (rawIndex < 0 || rawIndex >= appCount) return -1;

    const offsetInSlot = columnY - (rawIndex * metrics.step);
    return (offsetInSlot >= 0 && offsetInSlot <= metrics.buttonExtent) ? rawIndex : -1;
}
