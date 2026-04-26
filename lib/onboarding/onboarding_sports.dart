import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingSports extends StatefulWidget {
  final List<String> options;
  final List<String> selected;
  final Function(String) onSelect;

  const OnboardingSports({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<OnboardingSports> createState() => _OnboardingSportsState();
}

class _OnboardingSportsState extends State<OnboardingSports> {
  bool _showSecondarySection = false;
  bool _showTertiarySection = false;

  String? _secondarySport;
  String? _tertiarySport;

  void _showSportPicker(BuildContext context, {required bool isSecondary}) {
    HapticFeedback.selectionClick();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    // Exclude sports that are already selected in the primary picker
    // and exclude the other picker's selection to avoid duplicates.
    List<String> availableSports = widget.options.where((sport) {
      if (widget.selected.contains(sport)) return false;
      if (isSecondary && _tertiarySport == sport) return false;
      if (!isSecondary && _secondarySport == sport) return false;
      return true;
    }).toList();

    if (availableSports.isEmpty) return;

    final currentSport = isSecondary ? _secondarySport : _tertiarySport;
    int selectedIndex = currentSport != null
        ? availableSports.indexOf(currentSport).clamp(0, availableSports.length - 1)
        : 0;

    final scrollController = FixedExtentScrollController(initialItem: selectedIndex);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isSecondary ? "Secondary Sport" : "Tertiary Sport",
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            height: 180,
            child: ListWheelScrollView.useDelegate(
              controller: scrollController,
              itemExtent: 48,
              perspective: 0.003,
              diameterRatio: 1.8,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                HapticFeedback.selectionClick();
                selectedIndex = index;
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: availableSports.length,
                builder: (context, index) {
                  return Center(
                    child: Text(
                      availableSports[index],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: textColor.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final chosenSport = availableSports[selectedIndex];
                setState(() {
                  if (isSecondary) {
                    _secondarySport = chosenSport;
                  } else {
                    _tertiarySport = chosenSport;
                  }
                });
                widget.onSelect(chosenSport);
                Navigator.pop(context);
              },
              child: Text('Done',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES FOR MAIN VIEW
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final containerBg = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100; // DYNAMIC PILL BG

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Sports Profile",
              style: TextStyle(
                  color: textColor, // DYNAMIC
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  // ORIGINAL PRIMARY SPORT PICKER
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final sport = widget.options[index];
                      final isSelected = widget.selected.contains(sport);
                      
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact(); // CRISP HAPTIC ADDED HERE
                          widget.onSelect(sport);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          decoration: BoxDecoration(
                            color: containerBg, // DYNAMIC
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4CD964)
                                    : Colors.transparent,
                                width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:[
                              Text(sport,
                                  style: TextStyle(
                                      color: textColor, // DYNAMIC
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              // ANIMATED CHECKMARK ADDED HERE
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                child: isSelected
                                    ? const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 22, key: ValueKey('checked'))
                                    : const SizedBox(width: 22, height: 22, key: ValueKey('unchecked')),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ADD SECONDARY SPORT BUTTON
                  if (!_showSecondarySection)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showSecondarySection = true);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: containerBg, // DYNAMIC
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:[
                            Icon(Icons.add_circle_outline, color: Color(0xFF4CD964), size: 20),
                            SizedBox(width: 10),
                            Text("Add Secondary Sport", style: TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),

                  // SECONDARY SPORT PICKER CONTAINER
                  if (_showSecondarySection) ...[
                    const SizedBox(height: 12),
                    Text("Secondary Sport", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showSportPicker(context, isSecondary: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(color: containerBg, borderRadius: BorderRadius.circular(50)), // DYNAMIC
                        child: Row(
                          children:[
                            const Icon(Icons.sports_basketball_outlined, color: Color(0xFF8E8E93), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _secondarySport ?? "Select Secondary Sport", 
                              style: TextStyle(color: _secondarySport == null ? const Color(0xFF8E8E93) : textColor, fontSize: 16) // DYNAMIC
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ADD TERTIARY SPORT BUTTON
                  if (_showSecondarySection && !_showTertiarySection)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showTertiarySection = true);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 24, bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: containerBg, // DYNAMIC
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:[
                            Icon(Icons.add_circle_outline, color: Color(0xFF4CD964), size: 20),
                            SizedBox(width: 10),
                            Text("Add Tertiary Sport", style: TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),

                  // TERTIARY SPORT PICKER CONTAINER
                  if (_showTertiarySection) ...[
                    const SizedBox(height: 24),
                    Text("Tertiary Sport", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showSportPicker(context, isSecondary: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(color: containerBg, borderRadius: BorderRadius.circular(50)), // DYNAMIC
                        child: Row(
                          children:[
                            const Icon(Icons.sports_esports_outlined, color: Color(0xFF8E8E93), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _tertiarySport ?? "Select Tertiary Sport", 
                              style: TextStyle(color: _tertiarySport == null ? const Color(0xFF8E8E93) : textColor, fontSize: 16) // DYNAMIC
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40), // Bottom padding for smooth scrolling
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}