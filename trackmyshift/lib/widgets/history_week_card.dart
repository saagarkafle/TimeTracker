import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';

class HistoryWeekCard extends StatelessWidget {
  final DateTime weekStart;
  final List<MapEntry<String, Shift?>> days;
  final bool isCurrentWeek;
  final Function(String dateKey, Shift? shift) onEdit;
  final Function(String dateKey) onDelete;

  const HistoryWeekCard({
    super.key,
    required this.weekStart,
    required this.days,
    required this.isCurrentWeek,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentWeek
            ? Border.all(color: AppColors.primaryPurple, width: 2)
            : Border.all(color: AppColors.getBorderColor(context), width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: isCurrentWeek,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Week of ${prettyDate(weekStart)}')),
              if (isCurrentWeek)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: days
                    .where((e) => e.value?.arrival != null)
                    .map(
                      (entry) => _buildDayRow(context, entry.key, entry.value!),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, String dateKey, Shift shift) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = DateTime.tryParse(dateKey);
    final dayLabel = parsed != null
        ? '${weekdaysShort[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]}'
        : dateKey;

    final arrivalText = shift.arrival != null
        ? formatNoYear(shift.arrival!)
        : '—';
    final departureText = shift.departure != null
        ? formatNoYear(shift.departure!)
        : '—';

    int minutes = 0;
    if (shift.arrival != null && shift.departure != null) {
      final raw = shift.departure!.difference(shift.arrival!).inMinutes;
      final workedWithoutBreak = raw - 15;
      final paidMinutes = workedWithoutBreak > 0 ? workedWithoutBreak : 0;
      minutes = roundMinutesTo15(paidMinutes);
    }
    final hours = minutes / 60.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.primaryPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arrival: $arrivalText  •  Departure: $departureText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${hours.toStringAsFixed(2)} h',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => onEdit(dateKey, shift),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => onDelete(dateKey),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
