import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/ui/components/app_toast.dart';

/// Google Play In-App Updates.
///
/// Detects when a newer build is available to the user on their Play track
/// (internal / closed / open / production) and prompts to update. Uses a
/// priority-driven strategy:
///  * **Immediate** (blocking, full-screen) when the release's Play update
///    priority is high or the available update is too stale.
///  * **Flexible** (background download + "restart to update" prompt) otherwise.
///
/// Only works for builds installed from Google Play with the matching signing
/// key — `checkForUpdate()` throws on debug / sideloaded builds, which we
/// swallow silently (surfaced only for an explicit manual check).
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// Releases at or above this Play update priority (0–5) use the blocking
  /// "immediate" flow; everything else uses the background "flexible" flow.
  /// Priority is set per-release via the Play Developer Publishing API.
  static const int _immediatePriorityThreshold = 4;

  /// Escalate to an immediate update once an available update is this stale.
  static const int _immediateStalenessDays = 14;

  bool _autoCheckedThisSession = false;
  bool _flexibleInProgress = false;

  /// Check Play for an update and prompt the user. Called automatically on
  /// launch; set [manual] for the in-app "Check for updates" button (bypasses
  /// the once-per-session guard and reports "up to date" / failures).
  Future<void> checkAndPrompt(BuildContext context, {bool manual = false}) async {
    if (!manual && _autoCheckedThisSession) return;
    _autoCheckedThisSession = true;

    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (e) {
      // Non-Play / debug build, or a transient Play error.
      debugPrint('In-app update check failed: $e');
      if (manual && context.mounted) {
        AppToast.warning(
          context,
          AppLocalizations.of(context).updateCheckFailed,
          icon: Icons.system_update_outlined,
        );
      }
      return;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      if (manual && context.mounted) {
        AppToast.success(
          context,
          AppLocalizations.of(context).updateUpToDate,
          icon: Icons.check_circle_outline_rounded,
        );
      }
      return;
    }

    final bool wantImmediate = info.immediateUpdateAllowed &&
        (info.updatePriority >= _immediatePriorityThreshold ||
            (info.clientVersionStalenessDays ?? 0) >= _immediateStalenessDays);

    if (wantImmediate) {
      try {
        await InAppUpdate.performImmediateUpdate();
      } catch (e) {
        debugPrint('Immediate update failed: $e');
      }
      return;
    }

    if (info.flexibleUpdateAllowed && context.mounted) {
      await _runFlexible(context);
    }
  }

  Future<void> _runFlexible(BuildContext context) async {
    if (_flexibleInProgress) return;
    _flexibleInProgress = true;
    try {
      // Resolves with success once Play has finished downloading in background.
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success && context.mounted) {
        _promptRestart(context);
      }
    } catch (e) {
      debugPrint('Flexible update failed: $e');
    } finally {
      _flexibleInProgress = false;
    }
  }

  /// Snackbar prompting the user to restart to finish installing a downloaded
  /// flexible update. [InAppUpdate.completeFlexibleUpdate] restarts the app.
  void _promptRestart(BuildContext context) {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.updateReadyRestart),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: t.updateRestartAction,
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
      ),
    );
  }

  /// Call on app resume: resume an interrupted immediate update, or offer to
  /// install a flexible update that finished downloading while backgrounded.
  Future<void> resumeIfNeeded(BuildContext context) async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (_) {
      return;
    }
    if (info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      try {
        await InAppUpdate.performImmediateUpdate();
      } catch (_) {}
      return;
    }
    if (info.installStatus == InstallStatus.downloaded && context.mounted) {
      _promptRestart(context);
    }
  }
}
