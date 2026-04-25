import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/update_reminder.dart';

class AboutAppPage extends StatelessWidget {
  final VoidCallback onBack;
  const AboutAppPage({super.key, required this.onBack});

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
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: UniversalBackButton(onPressed: onBack),
                ),
                Text('About App',
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
                        'Version ${UpdateReminder.currentVersion}',
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

                // Developer
                _SectionLabel(label: 'DEVELOPER', subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: _InfoRow(
                    icon: Icons.person_rounded,
                    title: 'Developer',
                    value: 'Thanush M',
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                    isLast: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Privacy Policy
                _SectionLabel(label: 'LEGAL', subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: _TappableRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    trailing: Icons.open_in_new_rounded,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                    onTap: () => _launch('https://sites.google.com/view/syntheseapp/home'),
                  ),
                ),

                const SizedBox(height: 12),

                // Permissions
                _SectionLabel(label: 'PERMISSIONS', subColor: subColor),
                Container(
                  decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    _InfoRow(icon: Icons.notifications_outlined,  title: 'Notifications',        value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: false),
                    _InfoRow(icon: Icons.location_on_outlined,    title: 'Location',             value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: false),
                    _InfoRow(icon: Icons.directions_walk_rounded, title: 'Activity Recognition', value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: false),
                    _InfoRow(icon: Icons.camera_alt_outlined,     title: 'Camera',               value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: false),
                    _InfoRow(icon: Icons.photo_library_outlined,  title: 'Photos & Media',       value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: false),
                    _InfoRow(icon: Icons.watch_outlined,          title: 'Health Connect',       value: '', textColor: textColor, subColor: subColor, isDark: isDark, isLast: true),
                  ]),
                ),

                const SizedBox(height: 12),

                // Contact
                _SectionLabel(label: 'CONTACT THE DEVELOPER', subColor: subColor),
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
                      title: 'Email',
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
                    'Made with ❤️',
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
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
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
        padding: const EdgeInsets.only(left: 56),
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

  @override
  Widget build(BuildContext context) {
    final hlColor = widget.isDark ? Colors.white12 : Colors.black12;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onPointerCancel: (_) => setState(() => _pressed = false),
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
  final String title, body;
  final Color textColor, subColor;
  final bool isDark, isLast;
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
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
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(body,
                style: TextStyle(color: subColor, fontSize: 13, height: 1.45)),
          ])),
        ]),
      ),
      if (!isLast) _Divider(isDark: isDark),
    ]);
  }
}
