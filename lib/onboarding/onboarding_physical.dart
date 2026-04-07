import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'onboarding_utils.dart';

class OnboardingPhysical extends StatelessWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController waistCircumferenceController;
  final Map<String, dynamic>? bmi;
  final bool hasSupplements;
  final bool hasDisabilities;
  final TextEditingController supplementsController;
  final TextEditingController disabilityController;
  final Function(bool) onSupplementToggle;
  final Function(bool) onDisabilityToggle;
  final Function(String) onValueChange;

  const OnboardingPhysical({
    super.key,
    required this.heightController,
    required this.weightController,
    required this.bodyFatController,
    required this.waistCircumferenceController,
    required this.bmi,
    required this.hasSupplements,
    required this.hasDisabilities,
    required this.supplementsController,
    required this.disabilityController,
    required this.onSupplementToggle,
    required this.onDisabilityToggle,
    required this.onValueChange,
  });

  Widget _toggle(String t, bool v, Function(bool) fn, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children:[
        Text(t, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        CupertinoTheme(
          data: const CupertinoThemeData(primaryColor: Color(0xFF4CD964)),
          child: CNSwitch(
            value: v, 
            onChanged: (val) => fn(val),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE CUPERTINO PICKER MODAL ---
  void _showCupertinoPicker({
    required BuildContext context,
    required String title,
    required int min,
    required int max,
    required int initialValue,
    required TextEditingController controller,
    required String suffix,
  }) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find the current index based on what's already in the text field
    int selectedValue = controller.text.isNotEmpty ? int.tryParse(controller.text) ?? initialValue : initialValue;
    int selectedIndex = selectedValue - min;
    if (selectedIndex < 0) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material( // <--- ADDED MATERIAL HERE TO FIX YELLOW LINES
        color: Colors.transparent,
        child: Container(
          height: 320,
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text("Done", style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
                      onPressed: () {
                        // If user hits done without scrolling, lock in the default value
                        if (controller.text.isEmpty) {
                          controller.text = selectedValue.toString();
                          onValueChange(selectedValue.toString());
                        }
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 45,
                  diameterRatio: 1.2,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  ),
                  onSelectedItemChanged: (int index) {
                    HapticFeedback.selectionClick();
                    int actualValue = min + index;
                    controller.text = actualValue.toString();
                    onValueChange(actualValue.toString());
                  },
                  children: List.generate(
                    max - min + 1,
                    (index) => Center(
                      child: Text(
                        "${min + index} $suffix",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            "Physical Stats", 
            style: TextStyle(
              color: textColor, 
              fontSize: 32, 
              fontWeight: FontWeight.w700, 
              letterSpacing: -1
            )
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children:[
              Expanded(
                child: TextField(
                  controller: heightController, 
                  readOnly: true, // Prevents keyboard from showing
                  style: TextStyle(color: textColor), 
                  decoration: OnboardingUtils.iosInput(context, "Height (cm)", Icons.straighten), 
                  onTap: () => _showCupertinoPicker(
                    context: context, 
                    title: "Height", 
                    min: 100, max: 250, initialValue: 170, 
                    controller: heightController, suffix: "cm"
                  ),
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: weightController, 
                  readOnly: true, // Prevents keyboard from showing
                  style: TextStyle(color: textColor), 
                  decoration: OnboardingUtils.iosInput(context, "Weight (kg)", Icons.monitor_weight), 
                  onTap: () => _showCupertinoPicker(
                    context: context, 
                    title: "Weight", 
                    min: 30, max: 200, initialValue: 70, 
                    controller: weightController, suffix: "kg"
                  ),
                )
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children:[
              Expanded(
                child: TextField(
                  controller: bodyFatController, 
                  readOnly: true, // Prevents keyboard from showing
                  style: TextStyle(color: textColor), 
                  decoration: OnboardingUtils.iosInput(context, "Body Fat (%)", Icons.percent),
                  onTap: () => _showCupertinoPicker(
                    context: context, 
                    title: "Body Fat", 
                    min: 5, max: 60, initialValue: 20, 
                    controller: bodyFatController, suffix: "%"
                  ),
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: waistCircumferenceController, 
                  readOnly: true, // Prevents keyboard from showing
                  style: TextStyle(color: textColor), 
                  decoration: OnboardingUtils.iosInput(context, "Waist (cm)", Icons.linear_scale),
                  onTap: () => _showCupertinoPicker(
                    context: context, 
                    title: "Waist", 
                    min: 40, max: 150, initialValue: 80, 
                    controller: waistCircumferenceController, suffix: "cm"
                  ),
                )
              ),
            ],
          ),

          if (bmi != null) Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(30), 
              border: Border.all(color: textColor.withOpacity(0.1)) 
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text("Your BMI", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), 
                  Text(bmi!["category"], style: TextStyle(color: bmi!["color"], fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
                Text(bmi!["value"], style: TextStyle(color: textColor, fontSize: 42, fontWeight: FontWeight.w800)), 
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _toggle("Prescription Supplements", hasSupplements, onSupplementToggle, textColor), 
          if (hasSupplements) Padding(
            padding: const EdgeInsets.only(top: 12), 
            child: TextField(
              controller: supplementsController, 
              style: TextStyle(color: textColor), 
              decoration: OnboardingUtils.iosInput(context, "Details", Icons.medication) 
            )
          ),
          
          const SizedBox(height: 20),
          
          _toggle("Physical Disabilities", hasDisabilities, onDisabilityToggle, textColor), 
          if (hasDisabilities) Padding(
            padding: const EdgeInsets.only(top: 12), 
            child: TextField(
              controller: disabilityController, 
              style: TextStyle(color: textColor), 
              decoration: OnboardingUtils.iosInput(context, "Details", Icons.info_outline) 
            )
          ),
          
          const SizedBox(height: 40), 
        ],
      ),
    );
  }
}