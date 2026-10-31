import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';

class ExpenseChart extends StatefulWidget {
  final Map<String, double> categorySpending;
  final Map<String, double> categoryBudgets;
  final String currency;

  const ExpenseChart({
    super.key,
    required this.categorySpending,
    required this.categoryBudgets,
    this.currency = 'USD',
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int _touchedIndex = -1;

  final Map<String, Color> _categoryColors = {
    'Accommodation': const Color(0xFF3B82F6),
    'Transportation': const Color(0xFF00D2FF),
    'Food': const Color(0xFFF59E0B),
    'Activities': const Color(0xFF10B981),
    'Shopping': const Color(0xFFEC4899),
    'Other': const Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    final spendingEntries = widget.categorySpending.entries
        .where((e) => e.value > 0)
        .toList();

    final totalSpent = widget.categorySpending.values.fold(0.0, (a, b) => a + b);

    if (totalSpent <= 0) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, color: AppTheme.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              'No expenses recorded for this trip yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: spendingEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final isTouched = idx == _touchedIndex;
                final fontSize = isTouched ? 16.0 : 12.0;
                final radius = isTouched ? 65.0 : 55.0;
                final color = _categoryColors[e.key] ?? const Color(0xFF64748B);
                final pct = (e.value / totalSpent * 100).toStringAsFixed(1);

                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  title: '$pct%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Legend
        Wrap(
          spacing: 14,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: spendingEntries.map((e) {
            final color = _categoryColors[e.key] ?? const Color(0xFF64748B);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key}: \$${e.value.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
