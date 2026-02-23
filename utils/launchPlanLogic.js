function splitArgs(raw) {
    const text = String(raw || '').trim();
    return text ? text.split(' ') : [];
}

function buildLaunchPlan(app, launcherSettings, app2unitAvailable) {
    if (!app) return { type: 'none' };

    const settings = launcherSettings || {};

    if (settings.customLaunchPrefixEnabled && settings.customLaunchPrefix) {
        const prefix = splitArgs(settings.customLaunchPrefix);
        const cmd = app.runInTerminal
            ? prefix.concat(splitArgs(settings.terminalCommand), app.command || [])
            : prefix.concat(app.command || []);
        return { type: 'execDetached', command: cmd };
    }

    if (settings.useApp2Unit && app2unitAvailable && app.id) {
        const cmd = app.runInTerminal
            ? ['app2unit', '--', app.id + '.desktop']
            : ['app2unit', '--'].concat(app.command || []);
        return { type: 'execDetached', command: cmd };
    }

    if (app.runInTerminal) {
        return { type: 'spawn', command: splitArgs(settings.terminalCommand).concat(app.command || []) };
    }

    if (app.command?.length > 0) {
        return { type: 'spawn', command: app.command };
    }

    if (app.execute) {
        return { type: 'execute' };
    }

    return { type: 'none' };
}
