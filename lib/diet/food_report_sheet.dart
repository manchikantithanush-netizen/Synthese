import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/diet/food_analysis_service.dart';

/// Shows a bottom sheet that lets the user report an inaccurate AI food result.
/// All reports land in the top-level `ai_reports` Firestore collection so
/// you can review everything in one place from the Firebase console.
Future<void> showFoodReportSheet(
  BuildContext context,
  FoodAnalysisResult result,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FoodReportSheet(result: result),
  );
}

class _FoodReportSheet extends StatefulWidget {
  final FoodAnalysisResult result;
  const _FoodReportSheet({required this.result});

  @override
  State<_FoodReportSheet> createState() => _FoodReportSheetState();
}

class _FoodReportSheetState extends State<_FoodReportSheet> {
  static const List<String> _issueKeys = [
    'offensive',
    'wrong_food',
    'calories_off',
    'macros_off',
    'micronutrients_off',
    'other',
  ];

  String? _selectedIssue;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _issueLabel(AppLocalizations t, String key) {
    switch (key) {
      // Required by Google Play's AI-generated content policy: users must be
      // able to flag offensive/inappropriate AI output. Hardcoded English (not
      // yet localized) so the option exists everywhere.
      case 'offensive':       return 'Offensive or inappropriate content';
      case 'wrong_food':      return t.reportIssueWrongFood;
      case 'calories_off':    return t.reportIssueCaloriesOff;
      case 'macros_off':      return t.reportIssueMacrosOff;
      case 'micronutrients_off': return t.reportIssueMicronutrientsOff;
      case 'other':           return t.reportIssueOther;
      default:                return key;
    }
  }

  Future<void> _submit() async {
    if (_selectedIssue == null) return;
    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('ai_reports').add({
        'foodName':    widget.result.foodName,
        'calories':    widget.result.estimatedCalories,
        'protein':     widget.result.protein,
        'carbs':       widget.result.carbs,
        'fats':        widget.result.fats,
        'fiber':       widget.result.fiber,
        'sugar':       widget.result.sugar,
        'sodium':      widget.result.sodium,
        'iron':        widget.result.iron,
        'calcium':     widget.result.calcium,
        'potassium':   widget.result.potassium,
        'vitaminC':    widget.result.vitaminC,
        'vitaminD':    widget.result.vitaminD,
        'issue':       _selectedIssue,
        'note':        _noteController.text.trim(),
        'reportedBy':  uid,
        'timestamp':   FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() { _submitting = false; _submitted = true; });
        // Auto-close after showing the success state briefly
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'Permission denied — please update Firestore rules to allow writes to ai_reports.'
                  : 'Failed to submit: ${e.message}',
            ),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final subColor = textColor.withValues(alpha: 0.55);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom + 24;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad),
      child: _submitted ? _buildSuccess(t, textColor, subColor) : _buildForm(t, textColor, subColor, isDark),
    );
  }

  Widget _buildSuccess(AppLocalizations t, Color textColor, Color subColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 56),
        const SizedBox(height: 16),
        Text(
          t.reportSuccessTitle,
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          t.reportSuccessBody,
          style: TextStyle(color: subColor, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.reportSuccessDone,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations t, Color textColor, Color subColor, bool isDark) {
    final chipBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    const accent = Color(0xFFFF9F0A); // orange to match nutrition section

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title + food name
        Text(t.reportTitle,
            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          widget.result.foodName,
          style: TextStyle(color: subColor, fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),

        // Issue chips
        Text(t.reportSelectIssue,
            style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _issueKeys.map((key) {
            final selected = _selectedIssue == key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedIssue = key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.15) : chipBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _issueLabel(t, key),
                  style: TextStyle(
                    color: selected ? accent : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Optional note
        Text(t.reportNoteLabel,
            style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 300,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: t.reportNoteHint,
            hintStyle: TextStyle(color: subColor),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(color: subColor, fontSize: 11),
          ),
        ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (_selectedIssue == null || _submitting) ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: accent.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    t.reportSubmit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
