import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UniversalSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? width;
  final double? height;
  final bool enableHapticFeedback;

  const UniversalSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width,
    this.height,
    this.enableHapticFeedback = true,
  });

  @override
  State<UniversalSwitch> createState() => _UniversalSwitchState();
}

class _UniversalSwitchState extends State<UniversalSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(UniversalSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onChanged?.call(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    final switchWidth = widget.width ?? 48.0;
    final switchHeight = widget.height ?? 28.0;
    final activeColor = widget.activeColor ?? const Color(0xFF34C759); // Green color
    final inactiveColor = widget.inactiveColor ?? 
        (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: switchWidth,
            height: switchHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), // More oval shape
              color: widget.value ? activeColor : inactiveColor,
            ),
            child: Stack(
              children: [
                // Thumb
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: widget.value 
                      ? switchWidth - 24 - 2 // Go all the way to the end
                      : 2,
                  top: (switchHeight - 24) / 2, // Center vertically
                  child: Container(
                    width: 24, // Much smaller thumb
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A convenient row widget that combines text with the universal switch
class UniversalSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enableHapticFeedback;
  final MainAxisAlignment mainAxisAlignment;

  const UniversalSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.enableHapticFeedback = true,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        UniversalSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          enableHapticFeedback: enableHapticFeedback,
        ),
      ],
    );
  }
}
