import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shift.dart';
import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';

class EarningsContent extends StatefulWidget {
  const EarningsContent({super.key});

  @override
  State<EarningsContent> createState() => _EarningsContentState();
}

class _EarningsContentState extends State<EarningsContent> {
  // No dropdown selection needed; current week will be moved to top.

  String _weekTitle(String weekKey) {
    final parsed = DateTime.tryParse(weekKey);
    if (parsed == null) return weekKey;
    final start = parsed.toLocal();
    final end = start.add(const Duration(days: 6));
    final startStr =
        '${weekdaysShort[start.weekday - 1]} ${start.day} ${months[start.month - 1]}';
    final endStr =
        '${weekdaysShort[end.weekday - 1]} ${end.day} ${months[end.month - 1]}';
    return '$startStr — $endStr';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShiftsProvider>();
    final weeks = provider.groupByWeek();

    // determine current week start key (Monday)
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

    const double firstRate = 12.21; // for first 20 hours
    const double restRate = 9.0; // after 20 hours

    final sorted = weeks.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // If the current week exists in the data, move it to the top so it's shown first
    final currentIndex = sorted.indexWhere((e) => e.key == currentWeekKey);
    if (currentIndex > 0) {
      final entry = sorted.removeAt(currentIndex);
      sorted.insert(0, entry);
    }

    if (sorted.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No recorded hours yet.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final weekKey = sorted[idx].key;
        final days = sorted[idx].value;

        // gather and sort days
        final dayPairs = <MapEntry<String, Shift>>[];
        for (final e in days) {
          dayPairs.add(MapEntry(e.key, e.value));
        }
        dayPairs.sort((a, b) => a.key.compareTo(b.key));

        // compute totals using rounded minutes per day
        int totalMinutes = 0;
        final perDayInfo = <Map<String, dynamic>>[];
        for (final e in dayPairs) {
          final dateKey = e.key;
          final s = e.value;
          int minutes = 0;
          if (s.arrival != null && s.departure != null) {
            final raw = s.departure!.difference(s.arrival!).inMinutes;
            // Deduct a 15-minute unpaid break per shift (but not below 0)
            final workedWithoutBreak = raw - 15;
            final paidMinutes = workedWithoutBreak > 0 ? workedWithoutBreak : 0;
            // Round the paid minutes to nearest 15
            minutes = roundMinutesTo15(paidMinutes);
            totalMinutes += minutes;
          }
          perDayInfo.add({
            'dateKey': dateKey,
            'minutes': minutes,
            'hours': minutes / 60.0,
            'arrival': s.arrival,
            'departure': s.departure,
          });
        }

        final totalHours = totalMinutes / 60.0;
        final weekAmount = (totalHours <= 20)
            ? totalHours * firstRate
            : 20 * firstRate + (totalHours - 20) * restRate;

        // build children widgets for days
        final children = perDayInfo.map<Widget>((d) {
          final parsed = DateTime.tryParse(d['dateKey'] as String);
          final dayLabel = parsed != null
              ? '${weekdaysShort[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]}'
              : d['dateKey'] as String;
          final arrival = d['arrival'] as DateTime?;
          final departure = d['departure'] as DateTime?;
          final arrivalText = arrival != null ? formatNoYear(arrival) : '—';
          final departureText = departure != null
              ? formatNoYear(departure)
              : '—';
          final hours = (d['hours'] as double);

          final complete = arrival != null && departure != null;
          final textColor = complete ? null : Theme.of(context).disabledColor;
          return ListTile(
            enabled: complete,
            title: Text(
              dayLabel,
              style: textColor != null ? TextStyle(color: textColor) : null,
            ),
            subtitle: Text(
              'Arrival: $arrivalText  •  Departure: $departureText',
              style: textColor != null ? TextStyle(color: textColor) : null,
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${hours.toStringAsFixed(2)} h',
                  style: textColor != null ? TextStyle(color: textColor) : null,
                ),
                Text(
                  '£${((d['hours'] as double) * firstRate).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }).toList();

        // payment selector and confirmation
        children.add(const Divider(height: 1));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Text('Payment:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (ctx) {
                        final isPaid = provider.isWeekPaid(weekKey);
                        return DropdownButton<String>(
                          value: isPaid ? 'Paid' : 'Not Paid',
                          items: const [
                            DropdownMenuItem(
                              value: 'Not Paid',
                              child: Text('Not Paid'),
                            ),
                            DropdownMenuItem(
                              value: 'Paid',
                              child: Text('Paid'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            final markPaid = val == 'Paid';
                            provider.setWeekPaid(weekKey, markPaid);
                            if (markPaid) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked week as Paid'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final isCurrentWeek = weekKey == currentWeekKey;

        return ExpansionTile(
          initiallyExpanded: isCurrentWeek,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
          title: Text(_weekTitle(weekKey)),
          subtitle: Text('${totalHours.toStringAsFixed(2)} hours'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '£${weekAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
          ),
          children: children,
        );
      },
    );
  }
}
