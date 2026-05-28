import 'package:flutter/material.dart';

/// Adaptive layout for onboarding "intro" slides that fits any phone.
///
/// The problem this solves: the old slides put a [Column] with [Spacer]s inside
/// a box constrained to the exact viewport height. On short screens (small
/// phones, large system text, long translations) the content couldn't fit, the
/// [Spacer]s collapsed to zero, and the continue button overflowed off-screen —
/// so it couldn't be tapped.
///
/// Here the content lives inside a [SingleChildScrollView] whose child is forced
/// to be at least as tall as the viewport via [ConstrainedBox] + [IntrinsicHeight]:
///   * When there's spare room, the column fills the viewport and any [Spacer]s
///     among [children] expand to distribute everything exactly as before.
///   * When the content is taller than the viewport, it keeps its natural height
///     and the whole slide scrolls, so the button is always reachable.
///
/// Pass the full slide content (title, features, [Spacer]s, and the button) in
/// [children], just like a normal [Column]. Only use widgets that support
/// intrinsic height — do not nest another scroll view inside.
class AdaptiveOnboardingSlide extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  /// Optional override for the slide padding. When null, padding adapts to the
  /// available width/height (and the keyboard inset, if any).
  final EdgeInsets? padding;

  /// Viewports shorter than this (logical px) use the tighter "compact" spacing.
  final double compactBreakpoint;

  const AdaptiveOnboardingSlide({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.padding,
    this.compactBreakpoint = 760,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < compactBreakpoint;
        final horizontalPadding = constraints.maxWidth < 370 ? 20.0 : 28.0;
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        final basePadding =
            padding ??
            EdgeInsets.fromLTRB(
              horizontalPadding,
              isCompact ? 8 : 12,
              horizontalPadding,
              isCompact ? 12 : 24,
            );
        final resolvedPadding = basePadding.copyWith(
          bottom: basePadding.bottom + keyboardInset,
        );

        return SingleChildScrollView(
          padding: resolvedPadding,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - resolvedPadding.vertical)
                  .clamp(0.0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: crossAxisAlignment,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
