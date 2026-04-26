import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/ui/components/switch.dart';
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

  
  // --- REUSABLE MATERIAL NUMBER PICKER DIALOG ---
  void _showNumberPicker({
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
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    int selectedValue = controller.text.isNotEmpty
        ? int.tryParse(controller.text) ?? initialValue
        : initialValue;

    final scrollController = FixedExtentScrollController(
      initialItem: selectedValue - min,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
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
                selectedValue = min + index;
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: max - min + 1,
                builder: (context, index) {
                  final val = min + index;
                  return Center(
                    child: Text(
                      '$val $suffix',
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
                controller.text = selectedValue.toString();
                onValueChange(selectedValue.toString());
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
                  onTap: () => _showNumberPicker(
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
                  onTap: () => _showNumberPicker(
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
                  onTap: () => _showNumberPicker(
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
                  onTap: () => _showNumberPicker(
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
          
          UniversalSwitchRow(
            title: "Prescription Supplements",
            value: hasSupplements,
            onChanged: onSupplementToggle,
            activeColor: const Color(0xFF4CD964),
          ), 
          if (hasSupplements) Padding(
            padding: const EdgeInsets.only(top: 12), 
            child: TextField(
              controller: supplementsController, 
              style: TextStyle(color: textColor), 
              decoration: OnboardingUtils.iosInput(context, "Details", Icons.medication) 
            )
          ),
          
          const SizedBox(height: 20),
          
          UniversalSwitchRow(
            title: "Physical Disabilities",
            value: hasDisabilities,
            onChanged: onDisabilityToggle,
            activeColor: const Color(0xFF4CD964),
          ), 
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