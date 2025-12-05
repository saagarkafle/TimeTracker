import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';
import '../widgets/big_check_button.dart';

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Today'),
                subtitle: StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    final now = snapshot.data ?? DateTime.now();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prettyDate(now),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeOnly(now),
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 32),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            const BigCheckButton(),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('Arrival'),
                subtitle: Text(
                  shifts.arrival != null
                      ? formatNoYear(shifts.arrival!)
                      : 'Not recorded',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear arrival',
                  onPressed: () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear arrival?'),
                        content: const Text(
                          'Remove the recorded arrival time?',
                        ),
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
                              ).clearArrival();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Arrival cleared'),
                                ),
                              );
                              Navigator.pop(ctx, true);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Departure'),
                subtitle: Text(
                  shifts.departure != null
                      ? formatNoYear(shifts.departure!)
                      : 'Not recorded',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear departure',
                  onPressed: () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear departure?'),
                        content: const Text(
                          'Remove the recorded departure time?',
                        ),
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
                              ).clearDeparture();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Departure cleared'),
                                ),
                              );
                              Navigator.pop(ctx, true);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear today\'s times?'),
                    content: const Text(
                      'This will remove today\'s arrival and departure records.',
                    ),
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
                          ).clearToday();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Today\'s times cleared'),
                            ),
                          );
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear'),
            ),
            const SizedBox(height: 24),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'This app records arrival and departure times per day and persists a history. Use History to view past days.',
            ),
          ],
        ),
      ),
    );
  }
}
