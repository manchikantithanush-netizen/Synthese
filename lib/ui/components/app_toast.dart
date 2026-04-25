import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastType { success, info, warning, error }

// ─────────────────────────────────────────────────────────────────────────────
// AppToast — call AppToast.show(...) from anywhere with a BuildContext
// ─────────────────────────────────────────────────────────────────────────────
class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;
  static _ToastWidgetState? _state;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Animate out existing toast first, then show new one
    if (_state != null) {
      _state!.animateOut(() => _insertNew(context, message, type, icon, duration));
      return;
    }
    _insertNew(context, message, type, icon, duration);
  }

  static void _insertNew(
    BuildContext context,
    String message,
    ToastType type,
    IconData? icon,
    Duration duration,
  ) {
    _timer?.cancel();
    _current?.remove();
    _current = null;
    _state = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    _current = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        customIcon: icon,
        onDismiss: dismiss,
        onStateReady: (s) => _state = s,
      ),
    );

    overlay.insert(_current!);
    HapticFeedback.lightImpact();

    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_state != null) {
      _state!.animateOut(() {
        _current?.remove();
        _current = null;
        _state = null;
      });
    } else {
      _current?.remove();
      _current = null;
    }
  }

  // Convenience shortcuts
  static void success(BuildContext context, String message, {IconData? icon}) =>
      show(context, message, type: ToastType.success, icon: icon);
  static void info(BuildContext context, String message, {IconData? icon}) =>
      show(context, message, type: ToastType.info, icon: icon);
  static void warning(BuildContext context, String message, {IconData? icon}) =>
      show(context, message, type: ToastType.warning, icon: icon);
  static void error(BuildContext context, String message, {IconData? icon}) =>
      show(context, message, type: ToastType.error, icon: icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widget
// ─────────────────────────────────────────────────────────────────────────────
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final IconData? customIcon;
  final VoidCallback onDismiss;
  final void Function(_ToastWidgetState) onStateReady;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.onStateReady,
    this.customIcon,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    widget.onStateReady(this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Animate out then call [onComplete]
  void animateOut(VoidCallback onComplete) {
    if (!mounted) { onComplete(); return; }
    _ctrl.reverse().then((_) => onComplete());
  }

  Color _accent(bool isDark) {
    switch (widget.type) {
      case ToastType.success: return const Color(0xFF34C759);
      case ToastType.info:    return const Color(0xFF0A84FF);
      case ToastType.warning: return const Color(0xFFFF9F0A);
      case ToastType.error:   return const Color(0xFFFF3B30);
    }
  }

  IconData _icon() {
    if (widget.customIcon != null) return widget.customIcon!;
    switch (widget.type) {
      case ToastType.success: return Icons.check_circle_rounded;
      case ToastType.info:    return Icons.info_rounded;
      case ToastType.warning: return Icons.warning_rounded;
      case ToastType.error:   return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPad + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.25), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon(), color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.message,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close_rounded, color: subColor, size: 18),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
