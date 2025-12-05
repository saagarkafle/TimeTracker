import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shift.dart';
import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';

const Color primaryPurple = Color(0xFF667eea);
const Color primaryViolet = Color(0xFF764ba2);

class EarningsContent extends StatefulWidget {
  const EarningsContent({super.key});

  @override
  State<EarningsContent> createState() => _EarningsContentState();
}

class _EarningsContentState extends State<EarningsContent> {
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

    const double firstRate = 12.21;
    const double restRate = 9.0;

    final sorted = weeks.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final currentIndex = sorted.indexWhere((e) => e.key == currentWeekKey);
    if (currentIndex > 0) {
      final entry = sorted.removeAt(currentIndex);
      sorted.insert(0, entry);
    }

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final weekKey = sorted[idx].key;
        final days = sorted[idx].value;
        final isCurrentWeek = weekKey == currentWeekKey;

        final dayPairs = <MapEntry<String, Shift>>[];
        for (final e in days) {
          dayPairs.add(MapEntry(e.key, e.value));
        }
        dayPairs.sort((a, b) => a.key.compareTo(b.key));

        int totalMinutes = 0;
        final perDayInfo = <Map<String, dynamic>>[];
        for (final e in dayPairs) {
          final dateKey = e.key;
          final s = e.value;
          int minutes = 0;
          if (s.arrival != null && s.departure != null) {
            final raw = s.departure!.difference(s.arrival!).inMinutes;
            final workedWithoutBreak = raw - 15;
            final paidMinutes = workedWithoutBreak > 0 ? workedWithoutBreak : 0;
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
        final isPaid = provider.isWeekPaid(weekKey);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentWeek
                ? Border.all(color: primaryPurple, width: 2)
                : Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_weekTitle(weekKey))),
                      if (isCurrentWeek)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${totalHours.toStringAsFixed(2)} hours',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '£${weekAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      ...perDayInfo.map((d) {
                        final parsed = DateTime.tryParse(
                          d['dateKey'] as String,
                        );
                        final dayLabel = parsed != null
                            ? '${weekdaysShort[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]}'
                            : d['dateKey'] as String;
                        final arrival = d['arrival'] as DateTime?;
                        final departure = d['departure'] as DateTime?;
                        final arrivalText = arrival != null
                            ? formatNoYear(arrival)
                            : '—';
                        final departureText = departure != null
                            ? formatNoYear(departure)
                            : '—';
                        final hours = (d['hours'] as double);

                        final complete = arrival != null && departure != null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: complete
                                    ? primaryPurple.withValues(alpha: 0.8)
                                    : Colors.grey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: complete
                                        ? primaryPurple.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: complete
                                        ? primaryPurple
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayLabel,
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
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${hours.toStringAsFixed(2)} h',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '£${(hours * firstRate).toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: complete
                                                ? primaryPurple
                                                : Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryPurple, primaryViolet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Total',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '£${weekAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                provider.setWeekPaid(weekKey, !isPaid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !isPaid
                                          ? 'Marked week as Paid'
                                          : 'Marked week as Not Paid',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPaid
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: isPaid
                                          ? Colors.greenAccent
                                          : Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPaid ? 'Paid' : 'Pending',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
