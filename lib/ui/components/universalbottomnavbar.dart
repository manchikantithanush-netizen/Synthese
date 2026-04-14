import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UniversalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final bool hidden;

  const UniversalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.hidden = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : Colors.white;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;
    final activeColor = isDark ? Colors.white : Colors.black;

    if (hidden) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isActive ? 1.2 : 1.0,
                        child: Icon(
                          item.icon,
                          color: isActive ? activeColor : inactiveColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isActive ? activeColor : inactiveColor,
                          fontSize: isActive ? 12 : 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final String label;
  final IconData icon;

  const NavItem({required this.label, required this.icon});
}
