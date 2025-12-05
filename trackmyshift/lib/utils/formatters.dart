const List<String> months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> weekdaysShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String prettyDate(DateTime dt) {
  final d = dt.toLocal();
  return '${weekdaysShort[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
}

String timeOnly(DateTime dt) {
  final t = dt.toLocal();
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

String formatNoYear(DateTime dt) {
  final t = dt.toLocal();
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Round minutes to the nearest 15-minute increment.
/// Examples:
/// 0..7 -> 0, 8..22 -> 15, 23..37 -> 30, 38..52 -> 45, 53..59 -> 60
int roundMinutesTo15(int minutes) {
  if (minutes <= 0) return 0;
  final remainder = minutes % 15;
  final base = minutes - remainder;
  // Round up when remainder >= 8 (half of 15 rounded up)
  if (remainder >= 8) {
    return base + 15;
  }
  return base;
}
