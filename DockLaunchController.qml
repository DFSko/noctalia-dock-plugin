import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor
import qs.Services.System
import qs.Services.UI
import "utils/appIdLogic.js" as AppIdLogic
import "utils/toplevelLogic.js" as ToplevelLogic
import "utils/launchPlanLogic.js" as LaunchPlanLogic

Item {
    id: controller

    required property var dock

    property string launchFeedbackAppKey: ''
    property string pendingFocusAppId: ''

    function markLaunchFeedback(appId) {
        launchFeedbackAppKey = AppIdLogic.normalizeAppKey(appId);
        launchFeedbackTimer.restart();
    }

    function clearLaunchFeedback() {
        launchFeedbackAppKey = '';
    }

    function scheduleFocusAfterLaunch(appId) {
        const target = AppIdLogic.normalizeDesktopId(appId);
        if (!target) return;

        pendingFocusAppId = target;
        tryFocusPendingLaunch();
    }

    function clearPendingLaunchFocus() {
        pendingFocusAppId = '';
    }

    function findMatchingToplevels(appId) {
        return ToplevelLogic.findMatchingToplevels(ToplevelManager?.toplevels?.values || [], appId);
    }

    function tryFocusPendingLaunch() {
        if (!pendingFocusAppId) return false;

        const matches = findMatchingToplevels(pendingFocusAppId);
        if (matches.length === 0) return false;

        matches[0].activate();
        clearPendingLaunchFocus();
        return true;
    }

    function focusApp(appId) {
        const matches = findMatchingToplevels(appId);
        const target = ToplevelLogic.nextFocusToplevel(matches, ToplevelManager?.activeToplevel);
        if (!target) return false;
        target.activate();
        return true;
    }

    function closeApp(appId) {
        const toplevel = ToplevelLogic.preferredToplevel(
            findMatchingToplevels(appId),
            ToplevelManager?.activeToplevel
        );
        if (!toplevel) return false;
        toplevel.close();
        return true;
    }

    function launchApp(appId) {
        const normalized = AppIdLogic.normalizeDesktopId(appId);
        if (!normalized) {
            ToastService.showWarning('noctalia-dock-plugin: empty app id');
            return false;
        }

        const app = ThemeIcons.findAppEntry(normalized);
        if (!app) {
            ToastService.showWarning(`noctalia-dock-plugin: app not found: ${normalized}`);
            return false;
        }

        const launcherSettings = Settings?.data?.appLauncher || ({});
        const plan = LaunchPlanLogic.buildLaunchPlan(
            app,
            launcherSettings,
            ProgramCheckerService.app2unitAvailable
        );

        let launched = false;
        if (plan.type === 'execDetached' && plan.command && plan.command.length > 0) {
            Quickshell.execDetached(plan.command);
            launched = true;
        } else if (plan.type === 'spawn' && plan.command && plan.command.length > 0) {
            CompositorService.spawn(plan.command);
            launched = true;
        } else if (plan.type === 'execute' && app.execute) {
            app.execute();
            launched = true;
        }

        if (launched) {
            scheduleFocusAfterLaunch(normalized);
            return true;
        }

        Logger.w('noctalia-dock-plugin', `Could not launch: ${normalized}. No valid launch method.`);
        return false;
    }

    function activateOrLaunch(appId) {
        if (!focusApp(appId) && launchApp(appId)) {
            markLaunchFeedback(appId);
        }
    }

    Timer {
        id: launchFeedbackTimer
        interval: 1600
        repeat: false
        onTriggered: controller.clearLaunchFeedback()
    }
}
