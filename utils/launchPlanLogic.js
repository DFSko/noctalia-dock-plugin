function splitArgs(raw) {
    const text = String(raw || '').trim();
    if (!text) return [];
    return text.split(' ');
}

function buildLaunchPlan(app, launcherSettings, app2unitAvailable) {
    if (!app) return { type: 'none' };

    const settings = launcherSettings || ({});

    if (settings.customLaunchPrefixEnabled && settings.customLaunchPrefix) {
        const prefix = splitArgs(settings.customLaunchPrefix);
        if (app.runInTerminal) {
            const terminal = splitArgs(settings.terminalCommand);
            return {
                type: 'execDetached',
                command: prefix.concat(terminal.concat(app.command || []))
            };
        }

        return {
            type: 'execDetached',
            command: prefix.concat(app.command || [])
        };
    }

    if (settings.useApp2Unit && app2unitAvailable && app.id) {
        if (app.runInTerminal) {
            return { type: 'execDetached', command: ['app2unit', '--', app.id + '.desktop'] };
        }

        return { type: 'execDetached', command: ['app2unit', '--'].concat(app.command || []) };
    }

    if (app.runInTerminal) {
        const terminal = splitArgs(settings.terminalCommand);
        return { type: 'spawn', command: terminal.concat(app.command || []) };
    }

    if (app.command && app.command.length > 0) {
        return { type: 'spawn', command: app.command };
    }

    if (app.execute) {
        return { type: 'execute' };
    }

    return { type: 'none' };
}
