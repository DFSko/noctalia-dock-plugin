function workspaceValues(source) {
    if (!source) return [];

    if (typeof source.count === 'number' && typeof source.get === 'function') {
        const next = [];
        for (let i = 0; i < source.count; i++) {
            next.push(source.get(i));
        }
        return next;
    }

    return Array.isArray(source) ? source : [];
}

function selectWorkspaceTarget(workspaces, globalWorkspaces, screenName, offset) {
    if (!offset) return null;

    const values = workspaceValues(workspaces);
    if (values.length === 0) return null;

    const allWorkspaces = [];
    const localWorkspaces = [];

    for (let i = 0; i < values.length; i++) {
        const ws = values[i];
        if (!ws) continue;

        allWorkspaces.push(ws);

        if (!globalWorkspaces && screenName && ws.output && ws.output !== screenName) continue;
        localWorkspaces.push(ws);
    }

    const targetList = localWorkspaces.length > 0 ? localWorkspaces : allWorkspaces;
    if (targetList.length === 0) return null;

    const ordered = targetList.slice().sort((a, b) => (a.idx || 0) - (b.idx || 0));
    let current = ordered.findIndex(ws => ws.isFocused === true);
    if (current < 0) current = 0;

    let next = (current + offset) % ordered.length;
    if (next < 0) next = ordered.length - 1;

    return ordered[next] || null;
}

function wheelOffsetsFromDelta(accumulator, deltaY, enabled, stepValue) {
    if (!enabled || deltaY === 0) {
        return { accumulator: accumulator, offsets: [] };
    }

    const step = stepValue > 0 ? stepValue : 120;
    let nextAccumulator = accumulator + (-deltaY);
    const offsets = [];

    while (nextAccumulator >= step) {
        offsets.push(1);
        nextAccumulator -= step;
    }

    while (nextAccumulator <= -step) {
        offsets.push(-1);
        nextAccumulator += step;
    }

    return { accumulator: nextAccumulator, offsets: offsets };
}
