import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/formatters.dart';

class AddTimeDialog extends StatefulWidget {
  final Function(DateTime, TimeOfDay?, TimeOfDay?) onSave;

  const AddTimeDialog({super.key, required this.onSave});

  @override
  State<AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<AddTimeDialog> {
  late DateTime selectedDate;
  TimeOfDay? arrivalTod;
  TimeOfDay? departureTod;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Add Shift Time'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateField(isDark),
            const SizedBox(height: 16),
            _buildTimeField(
              'Arrival',
              arrivalTod,
              () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomTimePickerWidget(
                      initialTime: arrivalTod ?? TimeOfDay.now(),
                      onTimeChanged: (picked) {
                        setState(() => arrivalTod = picked);
                      },
                    ),
                  ),
                );
              },
              () => setState(() => arrivalTod = null),
              isDark,
            ),
            const SizedBox(height: 12),
            _buildTimeField(
              'Departure',
              departureTod,
              () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomTimePickerWidget(
                      initialTime: departureTod ?? TimeOfDay.now(),
                      onTimeChanged: (picked) {
                        setState(() => departureTod = picked);
                      },
                    ),
                  ),
                );
              },
              () => setState(() => departureTod = null),
              isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (arrivalTod == null || departureTod == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please set arrival and departure times'),
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

            if (departureDt.isBefore(arrivalDt)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Departure time must be after arrival time'),
                ),
              );
              return;
            }

            widget.onSave(selectedDate, arrivalTod, departureTod);
            Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prettyDate(selectedDate)),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
            child: const Icon(Icons.calendar_today),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay? value,
    VoidCallback onTap,
    VoidCallback onClear,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value?.format(context) ?? '--:--',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: onTap,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.close),
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
}

class EditTimeDialog extends StatefulWidget {
  final DateTime? arrival;
  final DateTime? departure;
  final Function(DateTime?, DateTime?) onSave;

  const EditTimeDialog({
    super.key,
    this.arrival,
    this.departure,
    required this.onSave,
  });

  @override
  State<EditTimeDialog> createState() => _EditTimeDialogState();
}

class _EditTimeDialogState extends State<EditTimeDialog> {
  late TimeOfDay? arrivalTod;
  late TimeOfDay? departureTod;

  @override
  void initState() {
    super.initState();
    arrivalTod = widget.arrival != null
        ? TimeOfDay.fromDateTime(widget.arrival!)
        : null;
    departureTod = widget.departure != null
        ? TimeOfDay.fromDateTime(widget.departure!)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Edit Shift Times'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField(
              'Arrival',
              arrivalTod,
              () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomTimePickerWidget(
                      initialTime: arrivalTod ?? TimeOfDay.now(),
                      onTimeChanged: (picked) {
                        setState(() => arrivalTod = picked);
                      },
                    ),
                  ),
                );
              },
              () => setState(() => arrivalTod = null),
              isDark,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              'Departure',
              departureTod,
              () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomTimePickerWidget(
                      initialTime: departureTod ?? TimeOfDay.now(),
                      onTimeChanged: (picked) {
                        setState(() => departureTod = picked);
                      },
                    ),
                  ),
                );
              },
              () => setState(() => departureTod = null),
              isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            widget.onSave(
              arrivalTod != null
                  ? DateTime(
                      widget.arrival?.year ?? 0,
                      widget.arrival?.month ?? 0,
                      widget.arrival?.day ?? 0,
                      arrivalTod!.hour,
                      arrivalTod!.minute,
                    )
                  : null,
              departureTod != null
                  ? DateTime(
                      widget.departure?.year ?? 0,
                      widget.departure?.month ?? 0,
                      widget.departure?.day ?? 0,
                      departureTod!.hour,
                      departureTod!.minute,
                    )
                  : null,
            );
            Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TimeOfDay? value,
    VoidCallback onTap,
    VoidCallback onClear,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value?.format(context) ?? '--:--',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: onTap,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.close),
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
}

// Custom scrollable time picker widget
class CustomTimePickerWidget extends StatefulWidget {
  final TimeOfDay? initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const CustomTimePickerWidget({
    super.key,
    this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<CustomTimePickerWidget> createState() => _CustomTimePickerWidgetState();
}

class _CustomTimePickerWidgetState extends State<CustomTimePickerWidget> {
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  late int selectedHour;
  late int selectedMinute;
  late bool isAM;

  @override
  void initState() {
    super.initState();
    final now = widget.initialTime ?? TimeOfDay.now();
    selectedHour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    selectedMinute = now.minute;
    isAM = now.hour < 12;

    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
    periodController = FixedExtentScrollController(initialItem: isAM ? 0 : 1);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 300,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Select Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final hour = isAM
                        ? (selectedHour == 12 ? 0 : selectedHour)
                        : (selectedHour == 12 ? 12 : selectedHour + 12);
                    widget.onTimeChanged(
                      TimeOfDay(hour: hour, minute: selectedMinute),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Hour Picker
                Expanded(
                  child: ListWheelScrollView(
                    controller: hourController,
                    itemExtent: 50,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (int index) {
                      setState(() => selectedHour = index + 1);
                    },
                    children: List<Widget>.generate(12, (int index) {
                      return Center(
                        child: Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                // Minute Picker
                Expanded(
                  child: ListWheelScrollView(
                    controller: minuteController,
                    itemExtent: 50,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (int index) {
                      setState(() => selectedMinute = index);
                    },
                    children: List<Widget>.generate(60, (int index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // AM/PM Picker
                Expanded(
                  child: ListWheelScrollView(
                    controller: periodController,
                    itemExtent: 50,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (int index) {
                      setState(() => isAM = index == 0);
                    },
                    children: [
                      Center(
                        child: Text(
                          'AM',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'PM',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
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
    );
  }
}
