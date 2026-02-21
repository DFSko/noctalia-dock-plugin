function normalizeAppKey(appId) {
    return String(appId || '').trim().toLowerCase().replace(/\.desktop$/, '');
}
