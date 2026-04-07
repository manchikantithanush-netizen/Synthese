import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class OnboardingUtils {
  // Preset lists for autocomplete
  static const List<String> _countries =[
    'United States', 'United Kingdom', 'Canada', 'Australia', 'Germany',
    'France', 'India', 'China', 'Japan', 'Brazil', 'United Arab Emirates',
    'Saudi Arabia', 'South Africa', 'Mexico', 'Italy', 'Spain', 'Netherlands',
    'Russia', 'South Korea', 'Turkey', 'Argentina', 'Sweden', 'Switzerland',
    'New Zealand', 'Singapore', 'Malaysia', 'Philippines', 'Indonesia', 'Egypt',
  ];

  static const List<String> _timeZones =[
    'UTC (Coordinated Universal Time)',
    'GMT (Greenwich Mean Time)',
    'EST (Eastern Standard Time)',
    'CST (Central Standard Time)',
    'MST (Mountain Standard Time)',
    'PST (Pacific Standard Time)',
    'AST (Atlantic Standard Time)',
    'AKST (Alaska Standard Time)',
    'HST (Hawaii Standard Time)',
    'CET (Central European Time)',
    'EET (Eastern European Time)',
    'IST (Indian Standard Time)',
    'JST (Japan Standard Time)',
    'AEST (Australian Eastern Standard Time)',
    'AWST (Australian Western Standard Time)',
    'GST (Gulf Standard Time)',
    'BST (British Summer Time)',
    'PDT (Pacific Daylight Time)',
  ];

  // Common Input Decoration (Added BuildContext for Dynamic Theming)
  static InputDecoration iosInput(BuildContext context, String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
      filled: true,
      // DYNAMIC: Fill Color
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
    );
  }

  // Helper method to calculate Age
  static int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  // --- CUSTOM AUTOCOMPLETE WIDGET ---
  static Widget _buildAutocomplete({
    required BuildContext context, // Added Context
    required TextEditingController parentController,
    required String hint,
    required IconData icon,
    required List<String> options,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: parentController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        parentController.text = selection;
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          cursorColor: textColor, // DYNAMIC
          style: TextStyle(color: textColor), // DYNAMIC
          decoration: iosInput(context, hint, icon), // DYNAMIC
          onChanged: (val) {
            parentController.text = val;
          },
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 56,
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                // DYNAMIC
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: textColor.withOpacity(0.1)),
                boxShadow: isDark ? null :[
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: index != options.length - 1
                            // DYNAMIC
                            ? Border(bottom: BorderSide(color: textColor.withOpacity(0.1), width: 0.5))
                            : null,
                      ),
                      child: Text(option, style: TextStyle(color: textColor, fontSize: 16)), // DYNAMIC
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // STEP 0: PERSONAL
  static Widget personal({
    required BuildContext context, // Added Context
    required TextEditingController nameController,
    required TextEditingController countryController,
    required TextEditingController timeZoneController,
    required String? gender,
    required DateTime? dob,
    required Function(String) onGenderSelect,
    required VoidCallback onDateTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Identify yourself", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 32),
          TextField(controller: nameController, cursorColor: textColor, style: TextStyle(color: textColor), decoration: iosInput(context, "Full Name", Icons.person_outline)),
          
          const SizedBox(height: 24),
          Text("Gender", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: ['Male', 'Female'].map((g) {
              bool isSelected = gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onGenderSelect(g),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(color: isSelected ? textColor : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100), borderRadius: BorderRadius.circular(50)),
                    child: Center(child: Text(g, style: TextStyle(color: isSelected ? Theme.of(context).scaffoldBackgroundColor : textColor, fontWeight: FontWeight.bold))),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Text("Date of Birth", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(50)),
              child: Row(
                children:[
                  const Icon(Icons.cake_outlined, color: Color(0xFF8E8E93), size: 20),
                  const SizedBox(width: 12),
                  Text(dob == null ? "Select Date" : DateFormat('MMMM dd, yyyy').format(dob!), style: TextStyle(color: dob == null ? const Color(0xFF8E8E93) : textColor, fontSize: 16)),
                ],
              ),
            ),
          ),
          
          // --- AGE BOX CALCULATION PRESENTATION ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: dob != null 
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: textColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text("Your Age", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                      Text("${_calculateAge(dob!)} years old", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
          Text("Location Details", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          
          // --- AUTOCOMPLETE: COUNTRY & TIMEZONE FIELDS ---
          _buildAutocomplete(
            context: context,
            parentController: countryController,
            hint: "Country",
            icon: Icons.public,
            options: _countries,
          ),
          const SizedBox(height: 12),
          _buildAutocomplete(
            context: context,
            parentController: timeZoneController,
            hint: "Time Zone",
            icon: Icons.access_time,
            options: _timeZones,
          ),
          
          const SizedBox(height: 140), 
        ],
      ),
    );
  }

  // STEP 1: PHYSICAL
  static Widget physical({
    required BuildContext context, // Added Context
    required TextEditingController heightController,
    required TextEditingController weightController,
    required Map<String, dynamic>? bmi,
    required bool hasSupplements,
    required bool hasDisabilities,
    required TextEditingController supplementsController,
    required TextEditingController disabilityController,
    required Function(bool) onSupplementToggle,
    required Function(bool) onDisabilityToggle,
    required Function(String) onValueChange,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Physical Stats", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 32),
          Row(
            children:[
              Expanded(child: TextField(controller: heightController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: iosInput(context, "Height (cm)", Icons.straighten), onChanged: onValueChange)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: weightController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: iosInput(context, "Weight (kg)", Icons.monitor_weight), onChanged: onValueChange)),
            ],
          ),
          if (bmi != null) Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(30), border: Border.all(color: textColor.withOpacity(0.1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text("Your BMI", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
                  Text(bmi["category"], style: TextStyle(color: bmi["color"], fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
                Text(bmi["value"], style: TextStyle(color: textColor, fontSize: 42, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _toggle("Prescription Supplements", hasSupplements, onSupplementToggle, textColor),
          if (hasSupplements) Padding(padding: const EdgeInsets.only(top: 12), child: TextField(controller: supplementsController, style: TextStyle(color: textColor), decoration: iosInput(context, "Details", Icons.medication))),
          const SizedBox(height: 20),
          _toggle("Physical Disabilities", hasDisabilities, onDisabilityToggle, textColor),
          if (hasDisabilities) Padding(padding: const EdgeInsets.only(top: 12), child: TextField(controller: disabilityController, style: TextStyle(color: textColor), decoration: iosInput(context, "Details", Icons.info_outline))),
        ],
      ),
    );
  }

  // STEP 2: FEMALE HEALTH
  static Widget female({
    required BuildContext context, // Added Context
    required TextEditingController cycleController,
    required TextEditingController periodController,
    required DateTime? lastPeriod,
    required Map<String, dynamic>? pData,
    required VoidCallback onDateTap,
    required Function(String) onValueChange,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Health Profile", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 32),
          TextField(controller: cycleController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: iosInput(context, "Cycle Length (Days)", Icons.loop), onChanged: onValueChange),
          const SizedBox(height: 20),
          TextField(controller: periodController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: iosInput(context, "Bleeding Length (Days)", Icons.water_drop_outlined), onChanged: onValueChange),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(50)),
              child: Row(children:[
                const Icon(Icons.calendar_month, color: Color(0xFF8E8E93), size: 20),
                const SizedBox(width: 12),
                Text(lastPeriod == null ? "Last Period Start" : DateFormat('MMMM dd, yyyy').format(lastPeriod), style: TextStyle(color: lastPeriod == null ? const Color(0xFF8E8E93) : textColor, fontSize: 16)),
              ]),
            ),
          ),
          if (pData != null) Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(30), border: Border.all(color: textColor.withOpacity(0.1))),
            child: Column(children: [
              _row("Current Cycle Day", "Day ${pData['cycleDay']}", textColor, textColor),
              Divider(color: textColor.withOpacity(0.1), height: 24),
              _row("Predicted Start", pData['nextStart'], const Color(0xFF4CD964), textColor),
              Divider(color: textColor.withOpacity(0.1), height: 24),
              _row("Predicted End", pData['nextEnd'], Colors.redAccent, textColor),
            ]),
          ),
        ],
      ),
    );
  }

  // STEP 3: SPORTS
  static Widget sports({
    required BuildContext context, // Added Context
    required List<String> options,
    required List<String> selected,
    required Function(String) onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Your Sports", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final sport = options[index];
                final isSelected = selected.contains(sport);
                return GestureDetector(
                  onTap: () => onSelect(sport),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: isSelected ? const Color(0xFF4CD964) : Colors.transparent, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Text(sport, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Row for period data
  static Widget _row(String t, String v, Color valueColor, Color textColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
      Text(t, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
      Text(v, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  // Helper for toggle switches
  static Widget _toggle(String t, bool v, Function(bool) fn, Color textColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
      Text(t, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
      CupertinoSwitch(value: v, activeColor: const Color(0xFF4CD964), onChanged: fn),
    ]);
  }
}