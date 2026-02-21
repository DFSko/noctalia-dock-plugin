.import "normalizeAppKey.js" as NormalizeAppKey

function appIdsMatch(a, b) {
    const ka = NormalizeAppKey.normalizeAppKey(a);
    const kb = NormalizeAppKey.normalizeAppKey(b);
    if (!ka || !kb) return false;
    if (ka === kb) return true;
    if (ka.split('.').pop() === kb.split('.').pop()) return true;
    const shorter = ka.length <= kb.length ? ka : kb;
    const longer = ka.length <= kb.length ? kb : ka;
    return longer.startsWith(shorter) && longer[shorter.length] === '-';
}
