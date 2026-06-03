import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:synthese/l10n/generated/app_localizations.dart';

/// Bridges to the native Android foreground service that fires step-milestone
/// notifications at 1,000 / 5,000 / the user's goal — even while the app is
/// closed or the phone is locked.
///
/// The notification text is localized here (the native service can't reach
/// Flutter's localizations) and handed to the service via [configure], which
/// persists it so the strings survive reboots.
class StepMilestoneService {
  StepMilestoneService._();
  static final StepMilestoneService instance = StepMilestoneService._();

  static const MethodChannel _channel = MethodChannel(
    'com.thanush.synthesehealth/step_milestones',
  );

  /// Push the latest goal + localized text to the native service and start it
  /// (when [enabled]) or stop it.
  ///
  /// [initialSteps] seeds today's count so the service lines up with the in-app
  /// total and doesn't re-alert milestones that were already passed before it
  /// started watching.
  Future<void> configure({
    required AppLocalizations t,
    required bool enabled,
    required int goal,
    required int initialSteps,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('configure', <String, dynamic>{
        'enabled': enabled,
        'goal': goal,
        'initialSteps': initialSteps,
        'channelOngoing': t.stepNotifChannelOngoing,
        'channelMilestone': t.stepNotifChannelMilestone,
        'ongoingTitle': t.stepNotifOngoingTitle,
        // '{steps}' / '{goal}' are placeholders the native service fills in at
        // fire time with the actual, locale-formatted number.
        'ongoingBody': t.stepNotifOngoingBody('{steps}'),
        'title1k': t.stepNotif1kTitle,
        'body1k': t.stepNotif1kBody,
        'title5k': t.stepNotif5kTitle,
        'body5k': t.stepNotif5kBody,
        'titleGoal': t.stepNotifGoalTitle,
        'bodyGoal': t.stepNotifGoalBody('{goal}'),
      });
    } catch (e) {
      debugPrint('StepMilestoneService configure failed: $e');
    }
  }

  /// Stop the foreground service and clear the persisted "enabled" flag so it
  /// won't restart on the next reboot.
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e) {
      debugPrint('StepMilestoneService stop failed: $e');
    }
  }
}
