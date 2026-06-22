import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/update_reminder.dart';
import 'package:synthese/services/app_update_service.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class AboutAppPage extends StatefulWidget {
  final VoidCallback onBack;
  const AboutAppPage({super.key, required this.onBack});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  // null = still loading, true = granted, false = denied
  bool? _statusNotification;
  bool? _statusLocation;
  bool? _statusActivity;
  bool? _statusCamera;
  bool? _statusPhotos; // iOS only

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final results = await Future.wait([
      Permission.notification.status,
      Permission.location.status,
      Permission.activityRecognition.status,
      Permission.camera.status,
      if (!Platform.isAndroid) Permission.photos.status,
    ]);

    if (!mounted) return;
    setState(() {
      _statusNotification = results[0].isGranted;
      _statusLocation     = results[1].isGranted;
      _statusActivity     = results[2].isGranted;
      _statusCamera       = results[3].isGranted;
      if (!Platform.isAndroid) _statusPhotos = results[4].isGranted;
    });
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 24, start: 20, end: 20, bottom: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: UniversalBackButton(onPressed: widget.onBack),
                ),
                Text(t.aboutTitle,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              physics: const BouncingScrollPhysics(),
              children: [

                // App identity
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        isDark
                            ? 'assets/logotextdark.png'
                            : 'assets/logotextlight.png',
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.aboutVersion(UpdateReminder.currentVersion),
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Check for updates
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: _TappableRow(
                    icon: Icons.system_update_outlined,
                    title: t.aboutCheckForUpdates,
                    trailing: Icons.chevron_right_rounded,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                    onTap: () => AppUpdateService.instance
                        .checkAndPrompt(context, manual: true),
                  ),
                ),

                const SizedBox(height: 12),

                // Developer
                _SectionLabel(label: t.aboutSecDeveloper, subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: _InfoRow(
                    icon: Icons.person_rounded,
                    title: t.aboutDeveloper,
                    value: 'Thanush M',
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                    isLast: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Privacy Policy & Terms
                _SectionLabel(label: t.aboutSecLegal, subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _TappableRow(
                        icon: Icons.shield_outlined,
                        title: t.aboutPrivacyPolicy,
                        trailing: Icons.open_in_new_rounded,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () => _launch('https://sites.google.com/view/synthese-workout-health/home'),
                      ),
                      _Divider(isDark: isDark),
                      _TappableRow(
                        icon: Icons.description_outlined,
                        title: t.aboutTermsAndConditions,
                        trailing: Icons.open_in_new_rounded,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () => _launch('https://sites.google.com/view/syntheseworkouthealthtandc/home'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Permissions — with live status indicators.
                // Matches exactly the permissions shown in onboarding:
                // Notifications, Location, Activity, Camera (+ Photos on iOS).
                // Photos is hidden on Android — the app uses Android Photo
                // Picker which needs zero permissions.
                _SectionLabel(label: t.aboutSecPermissions, subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    _PermissionRow(
                      icon: Icons.notifications_outlined,
                      title: t.aboutPermNotifications,
                      isGranted: _statusNotification,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                      isLast: false,
                    ),
                    _PermissionRow(
                      icon: Icons.location_on_outlined,
                      title: t.aboutPermLocation,
                      isGranted: _statusLocation,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                      isLast: false,
                    ),
                    _PermissionRow(
                      icon: Icons.directions_walk_rounded,
                      title: t.aboutPermActivity,
                      isGranted: _statusActivity,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                      isLast: false,
                    ),
                    _PermissionRow(
                      icon: Icons.camera_alt_outlined,
                      title: t.aboutPermCamera,
                      isGranted: _statusCamera,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                      // Last on Android, not last on iOS (Photos follows)
                      isLast: Platform.isAndroid,
                    ),
                    // Photos — iOS only (Android Photo Picker needs no permission)
                    if (!Platform.isAndroid)
                      _PermissionRow(
                        icon: Icons.photo_library_outlined,
                        title: t.aboutPermPhotos,
                        isGranted: _statusPhotos,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        isLast: true,
                      ),
                  ]),
                ),

                const SizedBox(height: 12),

                // Contact
                _SectionLabel(label: t.aboutSecContact, subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    _TappableRow(
                      icon: Icons.camera_alt_rounded,
                      title: 'Instagram',
                      value: '@t4nushhh',
                      trailing: Icons.open_in_new_rounded,
                      textColor: textColor, subColor: subColor, isDark: isDark,
                      onTap: () => _launch('https://www.instagram.com/t4nushhh'),
                    ),
                    _Divider(isDark: isDark),
                    _TappableRow(
                      icon: Icons.work_outline_rounded,
                      title: 'LinkedIn',
                      value: 'Thanush Manchikanti',
                      trailing: Icons.open_in_new_rounded,
                      textColor: textColor, subColor: subColor, isDark: isDark,
                      onTap: () => _launch('https://www.linkedin.com/in/thanushmanchikanti'),
                    ),
                    _Divider(isDark: isDark),
                    _TappableRow(
                      icon: Icons.mail_outline_rounded,
                      title: t.aboutEmail,
                      value: 'thanush.manchikanti@gmail.com',
                      trailing: Icons.open_in_new_rounded,
                      textColor: textColor, subColor: subColor, isDark: isDark,
                      onTap: () => _launch('mailto:thanush.manchikanti@gmail.com'),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    t.aboutMadeWith,
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color subColor;
  const _SectionLabel({required this.label, required this.subColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8, top: 4),
        child: Text(label,
            style: TextStyle(
                color: subColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 56),
        child: Container(
            height: 0.5,
            color: isDark ? Colors.white12 : Colors.black12),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color textColor, subColor;
  final bool isDark, isLast;
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, color: subColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(color: textColor, fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: subColor, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
      if (!isLast) _Divider(isDark: isDark),
    ]);
  }
}

class _TappableRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? value;
  final IconData trailing;
  final Color textColor, subColor;
  final bool isDark;
  final VoidCallback onTap;
  const _TappableRow({
    required this.icon,
    required this.title,
    this.value,
    required this.trailing,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TappableRow> createState() => _TappableRowState();
}

class _TappableRowState extends State<_TappableRow> {
  bool _pressed = false;
  Offset? _downPosition;
  // How many logical pixels the finger can drift before we cancel the tap.
  static const double _slopThreshold = 8.0;

  @override
  Widget build(BuildContext context) {
    final hlColor = widget.isDark ? Colors.white12 : Colors.black12;
    return Listener(
      onPointerDown: (e) {
        _downPosition = e.localPosition;
        setState(() => _pressed = true);
      },
      onPointerMove: (e) {
        // If the finger has drifted beyond the slop threshold the user is
        // scrolling — cancel the visual pressed state so the row un-highlights.
        if (_pressed && _downPosition != null) {
          final delta = (e.localPosition - _downPosition!).distance;
          if (delta > _slopThreshold) {
            setState(() => _pressed = false);
          }
        }
      },
      onPointerUp: (e) {
        // Only fire the tap if the pressed state is still active (i.e. the
        // finger didn't drift far enough to be classified as a scroll).
        final wasTap = _pressed;
        _downPosition = null;
        setState(() => _pressed = false);
        if (wasTap) {
          HapticFeedback.selectionClick();
          widget.onTap();
        }
      },
      onPointerCancel: (_) {
        _downPosition = null;
        setState(() => _pressed = false);
      },
      child: Container(
        color: _pressed ? hlColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(widget.icon, color: widget.subColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(widget.title,
                style: TextStyle(color: widget.textColor, fontSize: 16)),
          ),
          const SizedBox(width: 8),
          if (widget.value != null)
            Flexible(
              child: Text(
                widget.value!,
                textAlign: TextAlign.right,
                style: TextStyle(color: widget.subColor, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 6),
          Icon(widget.trailing,
              color: widget.isDark ? Colors.white30 : Colors.black26, size: 16),
        ]),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool? isGranted; // null = loading
  final Color textColor, subColor;
  final bool isDark, isLast;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.isGranted,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF34C759);
    final dimColor = textColor.withValues(alpha: 0.30);

    Widget statusBadge;
    if (isGranted == null) {
      // Still loading — show a small neutral dot
      statusBadge = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dimColor,
        ),
      );
    } else if (isGranted == true) {
      statusBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: green,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Enabled',
            style: TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      statusBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dimColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Not enabled',
            style: TextStyle(
              color: dimColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, color: subColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(color: textColor, fontSize: 16)),
          ),
          const SizedBox(width: 8),
          statusBadge,
        ]),
      ),
      if (!isLast) _Divider(isDark: isDark),
    ]);
  }
}
