import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastType { success, info, warning, error }

// ─────────────────────────────────────────────────────────────────────────────
// AppToast — pill-shaped in-app notification that drops from the top.
// Tap or swipe up to dismiss.
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
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.4),
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

  void animateOut(VoidCallback onComplete) {
    if (!mounted) {
      onComplete();
      return;
    }
    _ctrl.reverse().then((_) => onComplete());
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragDy = (_dragDy + d.delta.dy).clamp(-220.0, 8.0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_dragDy < -28 || v < -250) {
      widget.onDismiss();
    } else {
      setState(() => _dragDy = 0);
    }
  }

  Color _accent(bool isDark) {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF34C759);
      case ToastType.info:
        return const Color(0xFF0A84FF);
      case ToastType.warning:
        return const Color(0xFFFF9F0A);
      case ToastType.error:
        return const Color(0xFFFF3B30);
    }
  }

  IconData _icon() {
    if (widget.customIcon != null) return widget.customIcon!;
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.info:
        return Icons.info_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.error:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final bgColor = isDark ? const Color(0xFF1F1F22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final topPad = MediaQuery.of(context).padding.top;
    final maxW = MediaQuery.of(context).size.width - 32;

    return Positioned(
      top: topPad + 10,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Transform.translate(
            offset: Offset(0, _dragDy),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismiss,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.45 : 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon(), color: accent, size: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
