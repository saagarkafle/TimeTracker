import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shifts_provider.dart';
import '../utils/formatters.dart';

class HistoryAddDate extends StatelessWidget {
  const HistoryAddDate({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add date'),
              onPressed: () async {
                final provider = context.read<ShiftsProvider>();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked == null) return;
                if (!context.mounted) return;

                // open the same edit dialog for the picked date
                TimeOfDay? arrivalTod;
                TimeOfDay? departureTod;
                final existing =
                    provider
                        .allShifts['${picked.year.toString().padLeft(4, '0')}-'
                        '${picked.month.toString().padLeft(2, '0')}-'
                        '${picked.day.toString().padLeft(2, '0')}'];
                if (existing != null) {
                  arrivalTod = existing.arrival != null
                      ? TimeOfDay.fromDateTime(existing.arrival!)
                      : null;
                  departureTod = existing.departure != null
                      ? TimeOfDay.fromDateTime(existing.departure!)
                      : null;
                }

                await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          title: Text('Edit times — ${prettyDate(picked)}'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Arrival'),
                                subtitle: Text(
                                  arrivalTod?.format(ctx) ?? 'Not set',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final now = DateTime.now();
                                        final pickedTime = await showTimePicker(
                                          context: ctx,
                                          initialTime:
                                              arrivalTod ??
                                              TimeOfDay.fromDateTime(now),
                                        );
                                        if (pickedTime != null) {
                                          setState(
                                            () => arrivalTod = pickedTime,
                                          );
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
                                subtitle: Text(
                                  departureTod?.format(ctx) ?? 'Not set',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final now = DateTime.now();
                                        final pickedTime = await showTimePicker(
                                          context: ctx,
                                          initialTime:
                                              departureTod ??
                                              TimeOfDay.fromDateTime(now),
                                        );
                                        if (pickedTime != null) {
                                          setState(
                                            () => departureTod = pickedTime,
                                          );
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
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (arrivalTod != null) {
                                  final dt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    arrivalTod!.hour,
                                    arrivalTod!.minute,
                                  );
                                  provider.recordArrivalAt(dt);
                                }
                                if (departureTod != null) {
                                  final dt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    departureTod!.hour,
                                    departureTod!.minute,
                                  );
                                  provider.recordDepartureAt(dt);
                                }
                                ScaffoldMessenger.of(ctx).showSnackBar(
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
          ),
        ],
      ),
    );
  }
}
