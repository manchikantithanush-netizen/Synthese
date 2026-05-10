import 'package:flutter/material.dart';
import 'package:synthese/ui/components/switch.dart';

class OnboardingStage3 extends StatelessWidget {
  final bool hasSupplements;
  final bool hasDisabilities;
  final TextEditingController supplementsController;
  final TextEditingController disabilityController;
  final TextEditingController injuryHistoryController;
  final Function(bool) onSupplementToggle;
  final Function(bool) onDisabilityToggle;

  const OnboardingStage3({
    super.key,
    required this.hasSupplements,
    required this.hasDisabilities,
    required this.supplementsController,
    required this.disabilityController,
    required this.injuryHistoryController,
    required this.onSupplementToggle,
    required this.onDisabilityToggle,
  });

  InputDecoration _iosInput(BuildContext context, String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
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
        children: [
          Text(
            "Anything else\nwe should know?",
            style: TextStyle(
              color: textColor,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Optional details that help us tailor your experience.",
            style: TextStyle(
              color: textColor.withOpacity(0.55),
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 32),

          UniversalSwitchRow(
            title: "Prescription Supplements",
            value: hasSupplements,
            onChanged: onSupplementToggle,
            activeColor: const Color(0xFF4CD964),
          ),
          if (hasSupplements)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: supplementsController,
                style: TextStyle(color: textColor),
                decoration:
                    _iosInput(context, "Details", Icons.medication),
              ),
            ),

          const SizedBox(height: 20),

          UniversalSwitchRow(
            title: "Physical Disabilities",
            value: hasDisabilities,
            onChanged: onDisabilityToggle,
            activeColor: const Color(0xFF4CD964),
          ),
          if (hasDisabilities)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: disabilityController,
                style: TextStyle(color: textColor),
                decoration:
                    _iosInput(context, "Details", Icons.info_outline),
              ),
            ),

          const SizedBox(height: 28),

          Text(
            "Injury & Health History",
            style:
                TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: injuryHistoryController,
            style: TextStyle(color: textColor),
            cursorColor: textColor,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: "Describe past injuries or conditions",
              hintStyle:
                  const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: textColor.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E5CE6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF5E5CE6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "A note on AI",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "We're not using AI on this information today. In the future, we may add AI-powered insights to help you better understand your goals, spot patterns in your training, and get personalized suggestions.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "If we ever do, you'll see a clear consent prompt first — fully opt-in, your data stays yours.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.55),
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
