.import "appIdLogic.js" as AppIdLogic

function collectUnpinnedRunningApps(toplevels, pinnedApps) {
    const values = toplevels || [];
    const pinned = pinnedApps || [];
    const seen = new Set();
    const result = [];

    for (let i = 0; i < values.length; i++) {
        const t = values[i];
        if (!t || !t.appId) continue;

        const key = AppIdLogic.normalizeAppKey(t.appId);
        if (seen.has(key)) continue;
        seen.add(key);

        if (pinned.some(p => AppIdLogic.appIdsMatch(p, t.appId))) continue;
        result.push(t.appId);
    }

    return result;
}

function notificationShakeAppKey(notifAppName, pinnedApps) {
    const pinned = pinnedApps || [];
    for (let i = 0; i < pinned.length; i++) {
        if (AppIdLogic.appIdsMatch(notifAppName, pinned[i])) {
            return AppIdLogic.normalizeAppKey(pinned[i]);
        }
    }
    return '';
}

function computeBarInset(edge, barEdge, displayMode, isBarVisible, barFloating, marginHorizontal, barHeight) {
    if (edge !== 'left' && edge !== 'right') return 0;
    if (barEdge !== edge) return 0;

    if (displayMode === 'non_exclusive') return 0;
    if (displayMode === 'auto_hide' && !isBarVisible) return 0;

    const marginH = barFloating ? Math.ceil(marginHorizontal || 0) : 0;
    return (barHeight || 0) + marginH;
}
