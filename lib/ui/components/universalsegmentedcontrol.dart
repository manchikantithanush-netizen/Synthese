import 'package:flutter/material.dart';

class UniversalSegmentedControl<T> extends StatelessWidget {
  final List<T> items;
  final List<String> labels;
  final T selectedItem;
  final ValueChanged<T> onSelectionChanged;
  final double height;
  final EdgeInsets padding;

  const UniversalSegmentedControl({
    super.key,
    required this.items,
    required this.labels,
    required this.selectedItem,
    required this.onSelectionChanged,
    this.height = 44,
    this.padding = const EdgeInsets.all(4),
  }) : assert(items.length == labels.length);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.06);
    final selectedColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.1);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            final label = labels[index];
            final isSelected = item == selectedItem;

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelectionChanged(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(height / 2 - padding.top),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
