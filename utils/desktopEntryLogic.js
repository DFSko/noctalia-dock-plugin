function _pushUnique(items, value) {
    const text = String(value || '').trim();
    if (!text || items.indexOf(text) >= 0) return;
    items.push(text);
}

function desktopEntryIdVariants(appId) {
    const raw = String(appId || '').trim();
    const variants = [];
    if (!raw) return variants;

    const lower = raw.toLowerCase();
    const withoutDesktop = raw.replace(/\.desktop$/i, '');
    const lowerWithoutDesktop = withoutDesktop.toLowerCase();

    _pushUnique(variants, raw);
    _pushUnique(variants, lower);
    _pushUnique(variants, withoutDesktop);
    _pushUnique(variants, lowerWithoutDesktop);
    _pushUnique(variants, `${withoutDesktop}.desktop`);
    _pushUnique(variants, `${lowerWithoutDesktop}.desktop`);

    return variants;
}

function findExactDesktopEntry(desktopEntries, appId) {
    if (!desktopEntries || !desktopEntries.byId) return null;

    const variants = desktopEntryIdVariants(appId);
    for (let i = 0; i < variants.length; i++) {
        try {
            const entry = desktopEntries.byId(variants[i]);
            if (entry) return entry;
        } catch (e) {}
    }

    return null;
}

function findDesktopEntry(desktopEntries, themeIcons, appId) {
    const exact = findExactDesktopEntry(desktopEntries, appId);
    if (exact) return exact;

    if (themeIcons && themeIcons.findAppEntry) {
        try {
            return themeIcons.findAppEntry(appId);
        } catch (e) {}
    }

    return null;
}
