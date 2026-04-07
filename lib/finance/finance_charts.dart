import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Pie Chart Painter for Category Spending
class CategoryPieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double innerRadiusRatio;

  CategoryPieChartPainter({
    required this.values,
    required this.colors,
    this.innerRadiusRatio = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.every((v) => v == 0)) return;
    
    // Guard against mismatched arrays
    if (values.length != colors.length) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final innerRadius = radius * innerRadiusRatio;
    double startAngle = -pi / 2;
    final total = values.reduce((a, b) => a + b);
    
    // Prevent division by zero
    if (total == 0) return;

    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweepAngle = (values[i] / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          center.dx + innerRadius * cos(startAngle),
          center.dy + innerRadius * sin(startAngle),
        )
        ..lineTo(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..lineTo(
          center.dx + innerRadius * cos(startAngle + sweepAngle),
          center.dy + innerRadius * sin(startAngle + sweepAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryPieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

/// Bar Chart Painter for Monthly Trends
class MonthlyTrendsBarChartPainter extends CustomPainter {
  final List<double> expenses;
  final List<double> incomes;
  final List<String> labels;
  final Color expenseColor;
  final Color incomeColor;
  final Color labelColor;
  final Color gridColor;

  MonthlyTrendsBarChartPainter({
    required this.expenses,
    required this.incomes,
    required this.labels,
    required this.expenseColor,
    required this.incomeColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (expenses.isEmpty) return;
    
    // Guard against mismatched arrays
    if (expenses.length != incomes.length || expenses.length != labels.length) return;

    final allValues = [...expenses, ...incomes];
    if (allValues.isEmpty) return;
    
    final maxValue = allValues.reduce((a, b) => max(a, b));
    if (maxValue == 0) return;

    final chartHeight = size.height - 30;
    final chartWidth = size.width - 40;
    final barGroupWidth = chartWidth / expenses.length;
    final barWidth = barGroupWidth * 0.3;
    final gap = barGroupWidth * 0.1;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      canvas.drawLine(Offset(40, y), Offset(size.width, y), gridPaint);
    }

    // Draw Y-axis labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i <= 4; i++) {
      final value = (maxValue * i / 4).round();
      final label = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString();
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      textPainter.layout();
      final y = chartHeight * (1 - i / 4) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(0, y));
    }

    // Draw bars
    for (int i = 0; i < expenses.length; i++) {
      final x = 40 + i * barGroupWidth + barGroupWidth / 2 - barWidth - gap / 2;

      // Income bar (left)
      final incomeHeight = (incomes[i] / maxValue) * chartHeight;
      final incomePaint = Paint()..color = incomeColor;
      final incomeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - incomeHeight, barWidth, incomeHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(incomeRect, incomePaint);

      // Expense bar (right)
      final expenseHeight = (expenses[i] / maxValue) * chartHeight;
      final expensePaint = Paint()..color = expenseColor;
      final expenseRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + barWidth + gap, chartHeight - expenseHeight, barWidth, expenseHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(expenseRect, expensePaint);

      // Month label
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth - textPainter.width / 2, chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MonthlyTrendsBarChartPainter oldDelegate) {
    return oldDelegate.expenses != expenses || oldDelegate.incomes != incomes;
  }
}

/// Horizontal Bar Painter for Income vs Expense Comparison
class IncomeExpenseBarPainter extends CustomPainter {
  final double income;
  final double expense;
  final Color incomeColor;
  final Color expenseColor;
  final Color backgroundColor;

  IncomeExpenseBarPainter({
    required this.income,
    required this.expense,
    required this.incomeColor,
    required this.expenseColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Prevent division by zero
    final maxValue = max(income, expense);
    if (maxValue == 0) return;

    const barHeight = 24.0;
    const gap = 16.0;

    // Background for income bar
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, barHeight),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Income bar
    final incomeWidth = (income / maxValue) * size.width;
    final incomePaint = Paint()..color = incomeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, incomeWidth, barHeight),
        const Radius.circular(12),
      ),
      incomePaint,
    );

    // Background for expense bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barHeight + gap, size.width, barHeight),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Expense bar
    final expenseWidth = (expense / maxValue) * size.width;
    final expensePaint = Paint()..color = expenseColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barHeight + gap, expenseWidth, barHeight),
        const Radius.circular(12),
      ),
      expensePaint,
    );
  }

  @override
  bool shouldRepaint(covariant IncomeExpenseBarPainter oldDelegate) {
    return oldDelegate.income != income || oldDelegate.expense != expense;
  }
}
