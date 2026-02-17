import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

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

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: 'Icon size'
            description: 'Icon circle size in pixels'
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 24
            to: 96
            stepSize: 1
            value: root.valueIconSize
            onMoved: value => root.valueIconSize = Math.round(value)
            text: String(root.valueIconSize)
        }
    }

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: 'Spacing'
            description: 'Space between dock buttons'
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 0
            to: 30
            stepSize: 1
            value: root.valueSpacing
            onMoved: value => root.valueSpacing = Math.round(value)
            text: String(root.valueSpacing)
        }
    }

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: 'Icon inset'
            description: 'Padding around icon inside button'
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 0
            to: 8
            stepSize: 1
            value: root.valueIconInset
            onMoved: value => root.valueIconInset = Math.round(value)
            text: String(root.valueIconInset)
        }
    }

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: 'Background opacity'
            description: 'Dock background transparency'
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 0.2
            to: 1.0
            stepSize: 0.05
            value: root.valueOpacity
            onMoved: value => root.valueOpacity = value
            text: root.valueOpacity.toFixed(2)
        }
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

        pluginApi.pluginSettings.enabled = root.valueEnabled;
        pluginApi.pluginSettings.iconSize = root.valueIconSize;
        pluginApi.pluginSettings.spacing = root.valueSpacing;
        pluginApi.pluginSettings.iconInset = root.valueIconInset;
        pluginApi.pluginSettings.backgroundOpacity = root.valueOpacity;
        pluginApi.pluginSettings.workspaceScrollEnabled = root.valueWorkspaceScrollEnabled;

        pluginApi.saveSettings();
    }
}
