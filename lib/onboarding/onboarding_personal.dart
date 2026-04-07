import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'onboarding_utils.dart';

class OnboardingPersonal extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController countryController;
  final TextEditingController timeZoneController;
  final String? gender;
  final DateTime? dob;
  final Function(String) onGenderSelect;
  final VoidCallback onDateTap;

  const OnboardingPersonal({
    super.key,
    required this.nameController,
    required this.countryController,
    required this.timeZoneController,
    required this.gender,
    required this.dob,
    required this.onGenderSelect,
    required this.onDateTap,
  });

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

  int _calculateAge(DateTime birthDate) {
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

  Widget _buildAutocomplete({
    required BuildContext context,
    required TextEditingController parentController,
    required String hint,
    required IconData icon,
    required List<String> options,
  }) {
    // DYNAMIC THEME VARIABLES
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
          decoration: OnboardingUtils.iosInput(context, hint, icon), // Passed context
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
              width: MediaQuery.of(context).size.width - 56, // Matches parent padding (28 left + 28 right)
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                // DYNAMIC: Dropdown background matches theme
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                // DYNAMIC: Border
                border: Border.all(color: textColor.withOpacity(0.1)),
                // Added subtle shadow for light mode so dropdown stands out
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
                            // DYNAMIC: Separator borders
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

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            "Identify yourself", 
            style: TextStyle(
              color: textColor, // DYNAMIC
              fontSize: 32, 
              fontWeight: FontWeight.w700, 
              letterSpacing: -1
            )
          ),
          
          const SizedBox(height: 32),
          
          TextField(
            controller: nameController, 
            cursorColor: textColor, // DYNAMIC
            style: TextStyle(color: textColor), // DYNAMIC
            decoration: OnboardingUtils.iosInput(context, "Full Name", Icons.person_outline) // Passed Context
          ),
          
          const SizedBox(height: 24),
          
          Text("Gender", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
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
                    decoration: BoxDecoration(
                      // DYNAMIC: Selected pill is solid text color, unselected is subtle gray
                      color: isSelected ? textColor : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100), 
                      borderRadius: BorderRadius.circular(50)
                    ),
                    child: Center(
                      child: Text(
                        g, 
                        style: TextStyle(
                          // DYNAMIC: Selected text inverts color, unselected stays standard text color
                          color: isSelected ? Theme.of(context).scaffoldBackgroundColor : textColor, 
                          fontWeight: FontWeight.bold
                        )
                      )
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Text("Date of Birth", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                // DYNAMIC: Background
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(50)
              ),
              child: Row(
                children:[
                  const Icon(Icons.cake_outlined, color: Color(0xFF8E8E93), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    dob == null ? "Select Date" : DateFormat('MMMM dd, yyyy').format(dob!), 
                    style: TextStyle(
                      // DYNAMIC: Placeholder vs actual text color
                      color: dob == null ? const Color(0xFF8E8E93) : textColor, 
                      fontSize: 16
                    )
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: dob != null 
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    // DYNAMIC: Background and border for the calculated age box
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: textColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text("Your Age", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)), // DYNAMIC
                      Text("${_calculateAge(dob!)} years old", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)), // DYNAMIC
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
          
          Text("Location Details", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          
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
}