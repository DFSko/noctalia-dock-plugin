# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.3] - 2026-02-23

### Added
- Added "Move to Workspace" submenu item in right-click context menu for running applications
- Support for moving windows across workspaces on Hyprland, Niri, Sway, Scroll, and MangoWC compositors
- New utility module `utils/moveWindowLogic.js` for compositor-agnostic window management

### Changed
- Updated `utils/dockButtonLogic.js` to support submenu items in context menu
- Enhanced `DockButton.qml` with workspace awareness and move functionality

## [1.0.2] - 2026-02-21

### Changed
- Simplified dock internals by extracting controller/logic modules and cleaning drag handlers.
- Improved workspace selection flow and unpinned app filtering behavior.
- Consolidated settings slider row and default fallback handling.

### Fixed
- Corrected dock app tooltip placement to appear on the right side of the dock.
- Restricted dock hit area to the button lane for more accurate interaction.
- Fixed a drag controller regression introduced during refactoring.

## [1.0.1] - 2026-02-19

### Changed
- Improved public plugin metadata in `manifest.json` (`name`, `version`, `description`).
- Updated `README.md` with installation via repository URL in Noctalia Control Center.
- Added versioning and release notes guidance to `README.md`.

## [1.0.0] - 2026-02-18

### Added
- Initial public release of `noctalia-dock-plugin`.
- Vertical dock with launcher-synced pinned apps.
- Dock interactions (focus/launch/reorder), running indicators, and workspace scroll switching.
- Plugin settings support and screenshot/docs.
