.pragma library

function normalizeDesktopId(appId) {
    const raw = String(appId || '').trim();
    if (!raw) return '';
    return raw.endsWith('.desktop') ? raw : `${raw}.desktop`;
}

function normalizeAppKey(appId) {
    return String(appId || '').trim().toLowerCase().replace(/\.desktop$/, '');
}

function appIdsMatch(a, b) {
    const ka = normalizeAppKey(a);
    const kb = normalizeAppKey(b);
    if (!ka || !kb) return false;
    if (ka === kb) return true;
    if (ka.split('.').pop() === kb.split('.').pop()) return true;
    const shorter = ka.length <= kb.length ? ka : kb;
    const longer = ka.length <= kb.length ? kb : ka;
    return longer.startsWith(shorter) && longer[shorter.length] === '-';
}

function displayNameFor(appId) {
    const normalized = normalizeDesktopId(appId);
    if (!normalized) return '?';
    const base = normalized.replace(/\.desktop$/, '');
    const parts = base.split(/[._\-]/).filter(Boolean);
    if (parts.length === 0) return '?';
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}
