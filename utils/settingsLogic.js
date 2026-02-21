function buildPluginSettingsPayload(values) {
    const input = values || ({});
    return {
        enabled: input.enabled,
        iconSize: input.iconSize,
        spacing: input.spacing,
        iconInset: input.iconInset,
        backgroundOpacity: input.backgroundOpacity,
        workspaceScrollEnabled: input.workspaceScrollEnabled
    };
}
