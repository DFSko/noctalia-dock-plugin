/**
 * Move a window to a specified workspace using compositor-specific IPC commands.
 * 
 * @param {Object} toplevel - The Toplevel object to move (from ToplevelManager)
 * @param {Object} workspace - The target workspace object (from CompositorService.workspaces)
 * @returns {boolean} - True if the move command was executed, false otherwise
 */
function moveWindowToWorkspace(toplevel, workspace) {
    if (!toplevel || !workspace) {
        return false;
    }

    // Get compositor type from CompositorService
    const isHyprland = CompositorService?.isHyprland === true;
    const isNiri = CompositorService?.isNiri === true;
    const isSway = CompositorService?.isSway === true;
    const isMango = CompositorService?.isMango === true;
    const isLabwc = CompositorService?.isLabwc === true;

    try {
        if (isHyprland) {
            // Hyprland: Use hyprctl dispatch movetoworkspacesilent
            // Format: hyprctl dispatch movetoworkspacesilent <workspace_id> address:<window_address>
            const windowAddress = toplevel?.wayland?.surface?.toString() || '';
            if (windowAddress) {
                // Extract address from surface pointer (0x...)
                const addrMatch = windowAddress.match(/0x[0-9a-fA-F]+/);
                if (addrMatch) {
                    Quickshell.execDetached([
                        'hyprctl',
                        'dispatch',
                        'movetoworkspacesilent',
                        workspace.idx.toString(),
                        'address:' + addrMatch[0]
                    ]);
                    return true;
                }
            }
            // Fallback: try with workspace name
            Quickshell.execDetached([
                'hyprctl',
                'dispatch',
                'movetoworkspacesilent',
                workspace.name || workspace.idx.toString()
            ]);
            return true;
        } else if (isNiri) {
            // Niri: Use niri msg action move-window-to-workspace
            Quickshell.execDetached([
                'niri',
                'msg',
                'action',
                'move-window-to-workspace',
                workspace.idx.toString()
            ]);
            return true;
        } else if (isSway || CompositorService?.isScroll === true) {
            // Sway/Scroll: Use swaymsg move container to workspace
            Quickshell.execDetached([
                'swaymsg',
                'move',
                'container',
                'to',
                'workspace',
                workspace.name || workspace.idx.toString()
            ]);
            return true;
        } else if (isMango) {
            // MangoWC: Use mangoctl (if available) or fallback
            // MangoWC may not have direct window move command, try generic approach
            Quickshell.execDetached([
                'mangoctl',
                'move-to-workspace',
                workspace.idx.toString()
            ]);
            return true;
        } else if (isLabwc) {
            // LabWC: May not support window move via IPC
            // ext-toplevel-workspace protocol support is limited
            Logger.w('noctalia-dock-plugin', 'LabWC may not support moving windows between workspaces via IPC');
            return false;
        } else {
            // Unknown compositor
            Logger.w('noctalia-dock-plugin', 'Unknown compositor type, cannot move window');
            return false;
        }
    } catch (e) {
        Logger.e('noctalia-dock-plugin', 'Failed to move window to workspace:', e);
        return false;
    }
}

/**
 * Move a window by app ID to a workspace by ID.
 * 
 * @param {string} appId - The application ID to find the toplevel
 * @param {string|number} workspaceId - The workspace ID to move to
 * @param {Object} launchCtrl - The DockLaunchController to find matching toplevels
 * @returns {boolean} - True if the move command was executed, false otherwise
 */
function moveToWorkspaceById(appId, workspaceId, launchCtrl) {
    if (!appId || workspaceId === undefined || workspaceId === null || !launchCtrl) {
        return false;
    }

    const matches = launchCtrl.findMatchingToplevels(appId);
    if (matches.length === 0) {
        Logger.w('noctalia-dock-plugin', 'No matching toplevel found for app:', appId);
        return false;
    }

    // Find the target workspace
    const workspaces = CompositorService?.workspaces;
    if (!workspaces || typeof workspaces.count !== 'number') {
        Logger.w('noctalia-dock-plugin', 'Workspaces model not available');
        return false;
    }

    let targetWorkspace = null;
    for (let i = 0; i < workspaces.count; i++) {
        const ws = workspaces.get(i);
        if (!ws) continue;

        const wsId = ws.id !== undefined ? ws.id : ws.idx;
        if (String(wsId) === String(workspaceId)) {
            targetWorkspace = ws;
            break;
        }
    }

    if (!targetWorkspace) {
        Logger.w('noctalia-dock-plugin', 'Target workspace not found:', workspaceId);
        return false;
    }

    // Move the first matching toplevel (or the active one)
    const toplevel = matches[0];
    return moveWindowToWorkspace(toplevel, targetWorkspace);
}

/**
 * Build a list of workspace items for the Move submenu.
 * 
 * @param {Object} workspacesModel - The workspaces ListModel from CompositorService
 * @param {number} currentWorkspaceId - The ID of the current workspace (to mark it)
 * @returns {Array} - Array of workspace items with key, label, icon, workspaceId
 */
function buildWorkspaceList(workspacesModel, currentWorkspaceId) {
    const result = [];
    
    if (!workspacesModel || typeof workspacesModel.count !== 'number') {
        return result;
    }

    for (let i = 0; i < workspacesModel.count; i++) {
        const ws = workspacesModel.get(i);
        if (!ws) continue;

        const isCurrent = ws.id === currentWorkspaceId || ws.isFocused === true;
        
        result.push({
            key: 'move-to-workspace-' + (ws.id !== undefined ? ws.id : ws.idx),
            label: ws.name || ('Workspace ' + (ws.idx + 1)),
            icon: isCurrent ? 'check' : 'monitor',
            workspaceId: ws.id !== undefined ? ws.id : ws.idx,
            workspaceIdx: ws.idx,
            workspaceName: ws.name,
            disabled: isCurrent
        });
    }

    // Sort by workspace index
    result.sort((a, b) => (a.workspaceIdx || 0) - (b.workspaceIdx || 0));

    return result;
}
