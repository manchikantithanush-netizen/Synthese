import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App-wide busy indicator: three bouncing dots.
///
/// [color] defaults to [ColorScheme.primary] so it tracks light/dark theme and
/// your global `ThemeData` primary. Pass an explicit [color] for section accents
/// (for example finance pink) while keeping the same motion.
class BouncingDotsLoader extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;
  final Duration duration;

  const BouncingDotsLoader({
    super.key,
    this.color,
    this.dotSize = 10,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 900),
  });

  /// Smaller dots for tight spaces (e.g. full-width buttons, ~44×22).
  const BouncingDotsLoader.compact({
    super.key,
    this.color,
  })  : dotSize = 5,
        spacing = 3,
        duration = const Duration(milliseconds: 850);

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didUpdateWidget(covariant BouncingDotsLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final t = (_controller.value + i * 0.18) % 1.0;
            final y = math.sin(t * math.pi) * (6 + widget.dotSize * 0.9);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing * 0.5),
              child: Transform.translate(
                offset: Offset(0, -y),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
