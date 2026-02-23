.import "appIdLogic.js" as AppIdLogic

function buildPinnedMatchState(pinnedApps) {
    const values = pinnedApps || [];
    const keySet = new Set();
    const suffixSet = new Set();
    const dashPrefixSet = new Set();

    for (let i = 0; i < values.length; i++) {
        const key = AppIdLogic.normalizeAppKey(values[i]);
        if (!key) continue;

        keySet.add(key);
        suffixSet.add(key.split('.').pop());

        const parts = key.split('-');
        for (let j = 0; j < parts.length - 1; j++) {
            dashPrefixSet.add(parts.slice(0, j + 1).join('-'));
        }
    }

    return { keySet, suffixSet, dashPrefixSet };
}

function pinnedMatchesAppKey(appKey, pinnedState) {
    if (!appKey) return false;

    if (pinnedState.keySet.has(appKey)) return true;
    if (pinnedState.suffixSet.has(appKey.split('.').pop())) return true;
    if (pinnedState.dashPrefixSet.has(appKey)) return true;

    const parts = appKey.split('-');
    for (let j = 0; j < parts.length - 1; j++) {
        if (pinnedState.keySet.has(parts.slice(0, j + 1).join('-'))) return true;
    }

    return false;
}

function collectUnpinnedRunningApps(toplevels, pinnedApps) {
    const values = toplevels || [];
    const pinned = pinnedApps || [];
    const seen = new Set();
    const result = [];
    const pinnedState = buildPinnedMatchState(pinned);

    for (let i = 0; i < values.length; i++) {
        const t = values[i];
        if (!t || !t.appId) continue;

        const key = AppIdLogic.normalizeAppKey(t.appId);
        if (seen.has(key)) continue;
        seen.add(key);

        if (pinnedMatchesAppKey(key, pinnedState)) continue;
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
