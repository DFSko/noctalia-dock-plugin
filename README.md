# noctalia-dock-plugin

A vertical dock plugin for Noctalia with pinned apps synced from the launcher.

## Compatibility

- Shell project: [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell)
- Plugin id: `noctalia-dock-plugin`
- Entry points: `Main.qml`, `Settings.qml`

## Features

- Left-side vertical dock with exclusive panel space
- Pinned apps are sourced from `Settings.data.appLauncher.pinnedApps`
- Click to focus an existing window or launch the app
- Drag and drop to reorder pinned apps
- Launcher button at the bottom of the dock
- Uses shell launcher behavior (`customLaunchPrefix`, `app2unit`, terminal command fallback)

## Settings

Available in plugin settings:

- Enable dock
- Icon size
- Spacing between buttons
- Icon inset
- Background opacity

## Notes

- Pin and unpin apps from the launcher UI; the dock reflects that list automatically.
- Reordering in the dock updates launcher pinned order.
