import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class MetricAddDataSheet extends StatefulWidget {
  const MetricAddDataSheet({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.valueHint,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.onSave,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String valueLabel;
  final String valueHint;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final Future<void> Function({required DateTime when, required int value}) onSave;
  /// Icon shown in the circle above the title. Defaults to Icons.edit_rounded.
  final IconData? icon;
  /// Color of the icon. Defaults to accentColor.
  final Color? iconColor;

  @override
  State<MetricAddDataSheet> createState() => _MetricAddDataSheetState();
}

class _MetricAddDataSheetState extends State<MetricAddDataSheet> {
  late DateTime _selectedDateTime;
  late TextEditingController _valueController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        picked.year, picked.month, picked.day,
        _selectedDateTime.hour, _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
        picked.hour, picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    final value = int.tryParse(_valueController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = AppLocalizations.of(context)
          .metricEnterValid(widget.valueLabel.toLowerCase()));
      return;
    }
    setState(() { _error = null; _saving = true; });
    try {
      await widget.onSave(when: _selectedDateTime, value: value);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).detailSaveFailed;
        _saving = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', localeName).format(dt);
  }

  String _formatTime(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat.jm(localeName).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = widget.textColor;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final pillBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final divColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07);
    final font = GoogleFonts.plusJakartaSans;
    final iconColor = widget.iconColor ?? widget.accentColor;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.93,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── top bar: X left, ✓ right (fixed) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SheetTopButton(
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: textColor),
                      ),
                      _SheetTopButton(
                        isDark: isDark,
                        onTap: _saving ? null : _submit,
                        child: _saving
                            ? SizedBox(
                                width: 24,
                                height: 12,
                                child: BouncingDotsLoader.compact(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              )
                            : Icon(Icons.check_rounded,
                                size: 18, color: textColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

              // ── icon ──
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon ?? Icons.edit_rounded,
                    size: 34,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── title ──
              Center(
                child: Text(
                  widget.title,
                  style: font(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── rows card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Date row
                      _SheetDataRow(
                        label: t.detailDate,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDate(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, color: divColor),
                      // Time row
                      _SheetDataRow(
                        label: t.detailTime,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatTime(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, color: divColor),
                      // Value input row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              widget.valueLabel,
                              style: font(fontSize: 16, color: subColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _valueController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                autofocus: true,
                                textAlign: TextAlign.right,
                                onChanged: (_) {
                                  if (_error != null) setState(() => _error = null);
                                },
                                onSubmitted: (_) => _submit(),
                                style: font(fontSize: 16, color: textColor),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // inline error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _error!,
                    style: font(fontSize: 13, color: Colors.redAccent),
                  ),
                ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── shared helpers ────────────────────────────────────────────────────────────

class _SheetTopButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _SheetTopButton({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SheetDataRow extends StatelessWidget {
  final String label;
  final Color subColor;
  final Color textColor;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) font;
  final Widget trailing;

  const _SheetDataRow({
    required this.label,
    required this.subColor,
    required this.textColor,
    required this.font,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: font(fontSize: 16, color: subColor)),
          trailing,
        ],
      ),
    );
  }
}

ThemeData _pickerTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) return Theme.of(context);
  const bg = Color(0xFF252528);
  return Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      surface: bg,
      surfaceContainerHigh: bg,
      surfaceContainerHighest: bg,
      surfaceContainer: bg,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: bg),
    datePickerTheme: const DatePickerThemeData(backgroundColor: bg),
    timePickerTheme: const TimePickerThemeData(backgroundColor: bg),
  );
}
