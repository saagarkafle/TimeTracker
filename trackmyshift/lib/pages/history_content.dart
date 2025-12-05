import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shift.dart';
import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';

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
            return AlertDialog(
              title: const Text('Add Shift Time'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(prettyDate(selectedDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Arrival'),
                      subtitle: Text(arrivalTod?.format(ctx) ?? 'Not set'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
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
                          ),
                          if (arrivalTod != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => arrivalTod = null),
                            ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Departure'),
                      subtitle: Text(departureTod?.format(ctx) ?? 'Not set'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
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
                          ),
                          if (departureTod != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => departureTod = null),
                            ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShiftsProvider>();
    final grouped = provider.groupByMonth();

    // current week start key (Monday)
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
      final monthKey = monthEntry.key; // yyyy-MM
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
      bool monthHasCurrent = false;
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
          if (isCurrentWeek) monthHasCurrent = true;

          weeks.add(
            ExpansionTile(
              initiallyExpanded: isCurrentWeek,
              title: Text('Week of ${prettyDate(weekStart)}'),
              children: visibleDays.map((e) {
                final dateKey = e.key;
                final s = e.value;
                final parsed = DateTime.tryParse(dateKey);
                final titleText = parsed != null ? prettyDate(parsed) : dateKey;
                final arrivalText = s?.arrival != null
                    ? formatNoYear(s!.arrival!)
                    : '—';
                final departureText = s?.departure != null
                    ? formatNoYear(s!.departure!)
                    : '—';

                String hoursStr = '—';
                if (s?.arrival != null && s?.departure != null) {
                  final mins = s!.departure!.difference(s.arrival!).inMinutes;
                  final hrs = mins / 60.0;
                  hoursStr = '${hrs.toStringAsFixed(2)} h';
                }

                final complete = s?.arrival != null && s?.departure != null;
                final textColor = complete
                    ? null
                    : Theme.of(context).disabledColor;

                return ListTile(
                  title: Text('$titleText — $hoursStr'),
                  subtitle: Text(
                    'Arrival: $arrivalText  •  Departure: $departureText',
                    style: textColor != null
                        ? TextStyle(color: textColor)
                        : null,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit times',
                        onPressed: () async {
                          final provider = context.read<ShiftsProvider>();
                          if (parsed == null) return;

                          TimeOfDay? arrivalTod = s?.arrival != null
                              ? TimeOfDay.fromDateTime(s!.arrival!)
                              : null;
                          TimeOfDay? departureTod = s?.departure != null
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
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: const Text('Arrival'),
                                          subtitle: Text(
                                            arrivalTod?.format(ctx) ??
                                                'Not set',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () async {
                                                  final now = DateTime.now();
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
                                              ),
                                              if (arrivalTod != null)
                                                IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () => setState(
                                                    () => arrivalTod = null,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        ListTile(
                                          title: const Text('Departure'),
                                          subtitle: Text(
                                            departureTod?.format(ctx) ??
                                                'Not set',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () async {
                                                  final now = DateTime.now();
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
                                              ),
                                              if (departureTod != null)
                                                IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () => setState(
                                                    () => departureTod = null,
                                                  ),
                                                ),
                                            ],
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
                                      TextButton(
                                        onPressed: () {
                                          if (arrivalTod != null) {
                                            final dt = DateTime(
                                              parsed.year,
                                              parsed.month,
                                              parsed.day,
                                              arrivalTod!.hour,
                                              arrivalTod!.minute,
                                            );
                                            provider.recordArrivalAt(dt);
                                          }
                                          if (departureTod != null) {
                                            final dt = DateTime(
                                              parsed.year,
                                              parsed.month,
                                              parsed.day,
                                              departureTod!.hour,
                                              departureTod!.minute,
                                            );
                                            provider.recordDepartureAt(dt);
                                          }
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Times updated'),
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
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove record',
                          onPressed: () async {
                            await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remove record?'),
                                content: Text('Remove record for $dateKey?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Provider.of<ShiftsProvider>(
                                        ctx,
                                        listen: false,
                                      ).removeDay(dateKey);
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('Removed $dateKey'),
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
                );
              }).toList(),
            ),
          );
        }

        weekStart = weekStart.add(const Duration(days: 7));
      }

      return ExpansionTile(
        initiallyExpanded: monthHasCurrent,
        title: Text(monthName),
        children: weeks,
      );
    }).toList();

    final children = <Widget>[];
    children.addAll(monthWidgets);

    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(12), children: children),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTimeDialog(context),
        tooltip: 'Add shift time',
        child: const Icon(Icons.add),
      ),
    );
  }
}
