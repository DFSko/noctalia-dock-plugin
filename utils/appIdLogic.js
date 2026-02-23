function normalizeDesktopId(appId) {
    const raw = String(appId || '').trim();
    if (!raw) return '';
    return raw.endsWith('.desktop') ? raw : `${raw}.desktop`;
}

function normalizeAppKey(appId) {
    return String(appId || '').trim().toLowerCase().replace(/\.desktop$/, '');
}

/**
 * Compare two app IDs for matching.
 * Logic:
 * 1. Normalize both IDs (lowercase, strip .desktop suffix)
 * 2. Exact match after normalization
 * 3. Match by last segment (e.g., "org.kde.kate" matches "kate")
 * 4. Prefix match with hyphen separator (e.g., "foo" matches "foo-bar")
 * Examples:
 *   appIdsMatch("kate", "kate.desktop") -> true
 *   appIdsMatch("org.kde.kate", "kate") -> true
 *   appIdsMatch("foo", "foo-bar") -> true
 */
function appIdsMatch(a, b) {
    const ka = normalizeAppKey(a);
    const kb = normalizeAppKey(b);
    if (!ka || !kb) return false;
    if (ka === kb) return true;
    if (ka.split('.').pop() === kb.split('.').pop()) return true;
    const [shorter, longer] = ka.length <= kb.length ? [ka, kb] : [kb, ka];
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
