.import "appIdLogic.js" as AppIdLogic

function findMatchingToplevels(toplevels, appId) {
    const target = String(appId || '').trim();
    if (!target) return [];

    const values = toplevels || [];
    return values.filter(t => AppIdLogic.appIdsMatch(target, t?.appId));
}

function preferredToplevel(matches, activeToplevel) {
    if (!matches || matches.length === 0) return null;
    if (activeToplevel && matches.includes(activeToplevel)) return activeToplevel;
    return matches[0];
}

function nextFocusToplevel(matches, activeToplevel) {
    if (!matches || matches.length === 0) return null;
    if (!activeToplevel || !matches.includes(activeToplevel)) return matches[0];

    const idx = matches.indexOf(activeToplevel);
    return matches[(idx + 1) % matches.length];
}
