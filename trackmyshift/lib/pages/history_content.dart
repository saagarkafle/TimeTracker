import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shift.dart';
import '../providers/shifts_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/history_dialogs.dart';
import '../widgets/history_week_card.dart';

class HistoryContent extends StatelessWidget {
  const HistoryContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShiftsProvider>();
    final grouped = provider.groupByMonth();

    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final currentWeekKey =
        '${currentWeekStart.year.toString().padLeft(4, '0')}-'
        '${currentWeekStart.month.toString().padLeft(2, '0')}-'
        '${currentWeekStart.day.toString().padLeft(2, '0')}';

    final sortedMonths = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GestureDetector(
                onTap: () => _showAddTimeDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: AppColors.primaryPurple),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: grouped.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedMonths.length,
              itemBuilder: (context, idx) {
                final monthKey = sortedMonths[idx].key;
                final monthDays = sortedMonths[idx].value;

                return _buildMonthSection(
                  context,
                  monthKey,
                  monthDays,
                  currentWeekKey,
                  provider,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No shift history yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddTimeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    String monthKey,
    List<MapEntry<String, Shift>> monthDays,
    String currentWeekKey,
    ShiftsProvider provider,
  ) {
    final parts = monthKey.split('-');
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final monthName = (month >= 1 && month <= 12)
        ? months[month - 1]
        : monthKey;

    // Convert list of entries to map for easier lookup
    final monthMap = Map.fromEntries(monthDays);

    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    DateTime weekStart = first.subtract(Duration(days: first.weekday - 1));

    final weeks = <Widget>[];
    while (weekStart.isBefore(last) || weekStart.isAtSameMomentAs(last)) {
      final days = <MapEntry<String, Shift?>>[];
      for (int i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        final dateKey =
            '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

        final shift = monthMap[dateKey];
        days.add(MapEntry(dateKey, shift));
      }

      final visibleDays = days.where((e) => e.value?.arrival != null).toList();
      if (visibleDays.isNotEmpty) {
        final weekStartKey =
            '${weekStart.year.toString().padLeft(4, '0')}-'
            '${weekStart.month.toString().padLeft(2, '0')}-'
            '${weekStart.day.toString().padLeft(2, '0')}';
        final isCurrentWeek = weekStartKey == currentWeekKey;

        weeks.add(
          HistoryWeekCard(
            weekStart: weekStart,
            days: days,
            isCurrentWeek: isCurrentWeek,
            onEdit: (dateKey, shift) {
              if (shift != null) {
                _showEditDialog(context, dateKey, shift, provider);
              }
            },
            onDelete: (dateKey) =>
                _showDeleteConfirmation(context, dateKey, provider),
          ),
        );
      }

      weekStart = weekStart.add(const Duration(days: 7));
    }

    if (weeks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 12),
          child: Text(
            '$monthName $year',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...weeks,
        const SizedBox(height: 12),
      ],
    );
  }

  void _showAddTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddTimeDialog(
        onSave: (date, arrival, departure) {
          if (arrival != null && departure != null) {
            final provider = context.read<ShiftsProvider>();
            final arrivalDt = DateTime(
              date.year,
              date.month,
              date.day,
              arrival.hour,
              arrival.minute,
            );
            final departureDt = DateTime(
              date.year,
              date.month,
              date.day,
              departure.hour,
              departure.minute,
            );

            provider.recordArrivalAt(arrivalDt);
            provider.recordDepartureAt(departureDt);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shift added successfully')),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String dateKey,
    Shift shift,
    ShiftsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => EditTimeDialog(
        arrival: shift.arrival,
        departure: shift.departure,
        onSave: (arrival, departure) {
          if (arrival == null && departure == null) {
            provider.allShifts.remove(dateKey);
          } else {
            final arrivalDt = arrival;
            final departureDt = departure;

            if (arrivalDt != null) {
              provider.recordArrivalAt(arrivalDt);
            }
            if (departureDt != null) {
              provider.recordDepartureAt(departureDt);
            }
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Shift updated')));
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String dateKey,
    ShiftsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.allShifts.remove(dateKey);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Shift deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
