import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shift.dart';
import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';

const Color primaryPurple = Color(0xFF667eea);
const Color primaryViolet = Color(0xFF764ba2);

class HistoryContent extends StatelessWidget {
  const HistoryContent({super.key});

  void _showAddTimeDialog(BuildContext context) {
    final provider = context.read<ShiftsProvider>();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? arrivalTod;
    TimeOfDay? departureTod;

    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              title: const Text('Add Shift Time'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDateField(ctx, selectedDate, () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    }, isDark),
                    const SizedBox(height: 16),
                    _buildTimeField(
                      ctx,
                      'Arrival',
                      arrivalTod,
                      () async {
                        final now = DateTime.now();
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime:
                              arrivalTod ?? TimeOfDay.fromDateTime(now),
                        );
                        if (picked != null) {
                          setState(() => arrivalTod = picked);
                        }
                      },
                      () => setState(() => arrivalTod = null),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeField(
                      ctx,
                      'Departure',
                      departureTod,
                      () async {
                        final now = DateTime.now();
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime:
                              departureTod ?? TimeOfDay.fromDateTime(now),
                        );
                        if (picked != null) {
                          setState(() => departureTod = picked);
                        }
                      },
                      () => setState(() => departureTod = null),
                      isDark,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (arrivalTod == null || departureTod == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please set both arrival and departure',
                          ),
                        ),
                      );
                      return;
                    }

                    final arrivalDt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      arrivalTod!.hour,
                      arrivalTod!.minute,
                    );
                    final departureDt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      departureTod!.hour,
                      departureTod!.minute,
                    );

                    provider.recordArrivalAt(arrivalDt);
                    provider.recordDepartureAt(departureDt);

                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added shift for ${prettyDate(selectedDate)}',
                        ),
                      ),
                    );
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(
    BuildContext context,
    DateTime selectedDate,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prettyDate(selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: primaryPurple),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    BuildContext context,
    String label,
    TimeOfDay? time,
    VoidCallback onEdit,
    VoidCallback onClear,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (time != null ? primaryPurple : Colors.grey).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (time != null ? primaryPurple : Colors.grey).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label == 'Arrival' ? Icons.login : Icons.logout,
              color: time != null ? primaryPurple : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time?.format(context) ?? 'Not set',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: time != null ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: primaryPurple, size: 18),
                onPressed: onEdit,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (time != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: onClear,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShiftsProvider>();
    final grouped = provider.groupByMonth();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final monthWidgets = grouped.entries.map((monthEntry) {
      final monthKey = monthEntry.key;
      final parts = monthKey.split('-');
      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;

      final monthName = (month >= 1 && month <= 12)
          ? months[month - 1]
          : monthKey;

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
          final shift = provider.allShifts[dateKey];
          days.add(MapEntry(dateKey, shift));
        }

        final visibleDays = days
            .where((e) => e.value?.arrival != null)
            .toList();
        if (visibleDays.isNotEmpty) {
          final weekStartKey =
              '${weekStart.year.toString().padLeft(4, '0')}-'
              '${weekStart.month.toString().padLeft(2, '0')}-'
              '${weekStart.day.toString().padLeft(2, '0')}';
          final isCurrentWeek = weekStartKey == currentWeekKey;

          weeks.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isCurrentWeek
                    ? Border.all(color: primaryPurple, width: 2)
                    : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                      if (isCurrentWeek)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                        ),
                      Text('Week of ${prettyDate(weekStart)}'),
                    ],
                  ),
                  children: visibleDays.map((e) {
                    final dateKey = e.key;
                    final s = e.value;
                    final parsed = DateTime.tryParse(dateKey);
                    final titleText = parsed != null
                        ? prettyDate(parsed)
                        : dateKey;
                    final arrivalText = s?.arrival != null
                        ? formatNoYear(s!.arrival!)
                        : '—';
                    final departureText = s?.departure != null
                        ? formatNoYear(s!.departure!)
                        : '—';

                    String hoursStr = '—';
                    if (s?.arrival != null && s?.departure != null) {
                      final mins = s!.departure!
                          .difference(s.arrival!)
                          .inMinutes;
                      final hrs = mins / 60.0;
                      hoursStr = '${hrs.toStringAsFixed(2)} h';
                    }

                    final complete = s?.arrival != null && s?.departure != null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: complete
                                ? primaryPurple.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Arrival: $arrivalText  •  Departure: $departureText',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Text(
                                  hoursStr,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: complete
                                            ? primaryPurple
                                            : Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: primaryPurple,
                                  ),
                                  tooltip: 'Edit times',
                                  onPressed: () async {
                                    final provider = context
                                        .read<ShiftsProvider>();
                                    if (parsed == null) return;

                                    TimeOfDay? arrivalTod = s?.arrival != null
                                        ? TimeOfDay.fromDateTime(s!.arrival!)
                                        : null;
                                    TimeOfDay? departureTod =
                                        s?.departure != null
                                        ? TimeOfDay.fromDateTime(s!.departure!)
                                        : null;

                                    await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) {
                                        return StatefulBuilder(
                                          builder: (ctx, setState) {
                                            return AlertDialog(
                                              title: Text(
                                                'Edit times — ${prettyDate(parsed)}',
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _buildTimeEditField(
                                                    ctx,
                                                    'Arrival',
                                                    arrivalTod,
                                                    () async {
                                                      final now =
                                                          DateTime.now();
                                                      final picked =
                                                          await showTimePicker(
                                                            context: ctx,
                                                            initialTime:
                                                                arrivalTod ??
                                                                TimeOfDay.fromDateTime(
                                                                  now,
                                                                ),
                                                          );
                                                      if (picked != null) {
                                                        setState(() {
                                                          arrivalTod = picked;
                                                        });
                                                      }
                                                    },
                                                    () => setState(
                                                      () => arrivalTod = null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildTimeEditField(
                                                    ctx,
                                                    'Departure',
                                                    departureTod,
                                                    () async {
                                                      final now =
                                                          DateTime.now();
                                                      final picked =
                                                          await showTimePicker(
                                                            context: ctx,
                                                            initialTime:
                                                                departureTod ??
                                                                TimeOfDay.fromDateTime(
                                                                  now,
                                                                ),
                                                          );
                                                      if (picked != null) {
                                                        setState(() {
                                                          departureTod = picked;
                                                        });
                                                      }
                                                    },
                                                    () => setState(
                                                      () => departureTod = null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryPurple,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (arrivalTod != null) {
                                                      final dt = DateTime(
                                                        parsed.year,
                                                        parsed.month,
                                                        parsed.day,
                                                        arrivalTod!.hour,
                                                        arrivalTod!.minute,
                                                      );
                                                      provider.recordArrivalAt(
                                                        dt,
                                                      );
                                                    }
                                                    if (departureTod != null) {
                                                      final dt = DateTime(
                                                        parsed.year,
                                                        parsed.month,
                                                        parsed.day,
                                                        departureTod!.hour,
                                                        departureTod!.minute,
                                                      );
                                                      provider
                                                          .recordDepartureAt(
                                                            dt,
                                                          );
                                                    }
                                                    ScaffoldMessenger.of(
                                                      ctx,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Times updated',
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.pop(ctx, true);
                                                  },
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                if (s != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Remove record',
                                    onPressed: () async {
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Remove record?'),
                                          content: Text(
                                            'Remove record for $dateKey?',
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Provider.of<ShiftsProvider>(
                                                  ctx,
                                                  listen: false,
                                                ).removeDay(dateKey);
                                                ScaffoldMessenger.of(
                                                  ctx,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Removed $dateKey',
                                                    ),
                                                  ),
                                                );
                                                Navigator.pop(ctx, true);
                                              },
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }

        weekStart = weekStart.add(const Duration(days: 7));
      }

      if (weeks.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                monthName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ...weeks,
        ],
      );
    }).toList();

    if (monthWidgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                'No recorded hours yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: monthWidgets),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTimeDialog(context),
        backgroundColor: primaryPurple,
        tooltip: 'Add shift time',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTimeEditField(
    BuildContext context,
    String label,
    TimeOfDay? time,
    VoidCallback onEdit,
    VoidCallback onClear,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (time != null ? primaryPurple : Colors.grey).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (time != null ? primaryPurple : Colors.grey).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label == 'Arrival' ? Icons.login : Icons.logout,
              color: time != null ? primaryPurple : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time?.format(context) ?? 'Not set',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: time != null ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: primaryPurple, size: 18),
                onPressed: onEdit,
              ),
              if (time != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
