import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "utils/settingsLogic.js" as SettingsLogic

ColumnLayout {
    id: root

    property var pluginApi: null

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property bool valueEnabled: cfg.enabled ?? defaults.enabled ?? true
    property int valueIconSize: cfg.iconSize ?? defaults.iconSize ?? 46
    property int valueSpacing: cfg.spacing ?? defaults.spacing ?? 10
    property int valueIconInset: cfg.iconInset ?? defaults.iconInset ?? 2
    property real valueOpacity: cfg.backgroundOpacity ?? defaults.backgroundOpacity ?? 0.78
    property bool valueWorkspaceScrollEnabled: cfg.workspaceScrollEnabled ?? defaults.workspaceScrollEnabled ?? true

    spacing: Style.marginL

    NToggle {
        label: 'Enable dock'
        description: 'Show the dock on the side'
        checked: root.valueEnabled
        onToggled: checked => root.valueEnabled = checked
    }

    SettingSliderRow {
        label: 'Icon size'
        description: 'Icon circle size in pixels'
        from: 24
        to: 96
        stepSize: 1
        value: root.valueIconSize
        text: String(root.valueIconSize)
        onMoved: value => root.valueIconSize = Math.round(value)
    }

    SettingSliderRow {
        label: 'Spacing'
        description: 'Space between dock buttons'
        from: 0
        to: 30
        stepSize: 1
        value: root.valueSpacing
        text: String(root.valueSpacing)
        onMoved: value => root.valueSpacing = Math.round(value)
    }

    SettingSliderRow {
        label: 'Icon inset'
        description: 'Padding around icon inside button'
        from: 0
        to: 8
        stepSize: 1
        value: root.valueIconInset
        text: String(root.valueIconInset)
        onMoved: value => root.valueIconInset = Math.round(value)
    }

    SettingSliderRow {
        label: 'Background opacity'
        description: 'Dock background transparency'
        from: 0.2
        to: 1.0
        stepSize: 0.05
        value: root.valueOpacity
        text: root.valueOpacity.toFixed(2)
        onMoved: value => root.valueOpacity = value
    }

    NToggle {
        label: 'Workspace switch on scroll'
        description: 'Scroll over dock to change workspace'
        checked: root.valueWorkspaceScrollEnabled
        onToggled: checked => root.valueWorkspaceScrollEnabled = checked
    }
    NLabel {
        label: 'Pinned apps source'
        description: 'Apps are synced from launcher pins: Settings.data.appLauncher.pinnedApps'
    }

    function saveSettings() {
        if (!pluginApi) return;

        const payload = SettingsLogic.buildPluginSettingsPayload({
            enabled: root.valueEnabled,
            iconSize: root.valueIconSize,
            spacing: root.valueSpacing,
            iconInset: root.valueIconInset,
            backgroundOpacity: root.valueOpacity,
            workspaceScrollEnabled: root.valueWorkspaceScrollEnabled
        });

        for (const key in payload) {
            pluginApi.pluginSettings[key] = payload[key];
        }

        pluginApi.saveSettings();
    }
}
