import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shifts_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/big_check_button.dart';
import '../widgets/card_widgets.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<ShiftsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Date & Time Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: StreamBuilder<DateTime>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => DateTime.now(),
                ),
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconContainer(
                            icon: Icons.calendar_today,
                            isActive: true,
                            size: 40,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Today',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        prettyDate(now),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeOnly(now),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                          height: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Check In/Out Button
            const BigCheckButton(),
            const SizedBox(height: 24),

            // Arrival & Departure Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Arrival
                  _buildTimeCard(
                    context,
                    icon: Icons.login,
                    label: 'Arrival',
                    time: shifts.arrival != null
                        ? formatNoYear(shifts.arrival!)
                        : 'Not recorded',
                    isRecorded: shifts.arrival != null,
                    onClear: () => _clearArrival(context),
                  ),
                  const SizedBox(height: 12),
                  // Departure
                  _buildTimeCard(
                    context,
                    icon: Icons.logout,
                    label: 'Departure',
                    time: shifts.departure != null
                        ? formatNoYear(shifts.departure!)
                        : 'Not recorded',
                    isRecorded: shifts.departure != null,
                    onClear: () => _clearDeparture(context),
                  ),
                  if (shifts.arrival != null && shifts.departure != null) ...[
                    const SizedBox(height: 16),
                    _buildDurationCard(context, shifts),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String time,
    required bool isRecorded,
    required VoidCallback onClear,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      isHighlighted: isRecorded,
      child: Row(
        children: [
          IconContainer(
            icon: icon,
            isActive: isRecorded,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (isRecorded)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClear,
              tooltip: 'Clear $label',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(BuildContext context, ShiftsProvider shifts) {
    final mins = shifts.departure!.difference(shifts.arrival!).inMinutes;
    final hours = mins / 60.0;

    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      isHighlighted: true,
      child: Row(
        children: [
          IconContainer(
            icon: Icons.schedule,
            isActive: true,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours.toStringAsFixed(2)} hours',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearArrival(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear arrival?'),
        content: const Text('Remove the recorded arrival time?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ShiftsProvider>(
                context,
                listen: false,
              ).clearArrival();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Arrival cleared')));
              Navigator.pop(ctx, true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearDeparture(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear departure?'),
        content: const Text('Remove the recorded departure time?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ShiftsProvider>(
                context,
                listen: false,
              ).clearDeparture();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Departure cleared')),
              );
              Navigator.pop(ctx, true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
