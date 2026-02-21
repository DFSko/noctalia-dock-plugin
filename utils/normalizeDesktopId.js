function normalizeDesktopId(appId) {
    const raw = String(appId || '').trim();
    if (!raw) return '';
    return raw.endsWith('.desktop') ? raw : `${raw}.desktop`;
}
