function buildContextModel(running, pinned, desktopActions, labels, hasMoveSupport) {
    const actions = desktopActions || [];
    const i18n = labels || {};
    const next = [
        { key: 'launch', label: i18n.launch, icon: 'play' }
    ];

    if (running) {
        next.push({ key: 'focus', label: i18n.focus, icon: 'eye' });
    }

    // Add "Workspace" submenu item for running apps
    if (running && hasMoveSupport) {
        next.push({ key: 'move', label: i18n.moveToWorkspace || 'Workspace', icon: 'chevron-right' });
    }

    next.push({
        key: pinned ? 'unpin' : 'pin',
        label: pinned ? i18n.unpin : i18n.pin,
        icon: pinned ? 'unpin' : 'pin'
    });

    if (running) {
        next.push({ key: 'close', label: i18n.close, icon: 'close' });
    }

    actions.forEach((a, i) => next.push({ key: `desktop-${i}`, label: a.name, icon: 'chevron-right' }));

    return next;
}

function desktopActionIndex(actionKey) {
    if (typeof actionKey !== 'string') return -1;
    if (!actionKey.startsWith('desktop-')) return -1;

    const idx = parseInt(actionKey.slice('desktop-'.length), 10);
    if (!Number.isFinite(idx) || idx < 0) return -1;
    return idx;
}
