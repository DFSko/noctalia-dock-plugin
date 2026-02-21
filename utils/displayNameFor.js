.import "normalizeDesktopId.js" as NormalizeDesktopId

function displayNameFor(appId) {
    const normalized = NormalizeDesktopId.normalizeDesktopId(appId);
    if (!normalized) return '?';
    const base = normalized.replace(/\.desktop$/, '');
    const parts = base.split(/[._\-]/).filter(Boolean);
    if (parts.length === 0) return '?';
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}
