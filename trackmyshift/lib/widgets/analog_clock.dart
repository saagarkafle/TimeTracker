import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Simple analog clock widget that rebuilds every second.
class AnalogClock extends StatelessWidget {
  final double size;
  const AnalogClock({this.size = 56.0, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        return CustomPaint(size: Size(size, size), painter: _ClockPainter(now));
      },
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime now;
  _ClockPainter(this.now);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()..isAntiAlias = true;

    // Face (subtle)
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(12);
    canvas.drawCircle(center, radius, paint);

    // Ticks
    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 60; i++) {
      final ang = (i * 6) * math.pi / 180;
      final inner = Offset(
        center.dx + (radius - (i % 5 == 0 ? 8 : 4)) * math.cos(ang),
        center.dy + (radius - (i % 5 == 0 ? 8 : 4)) * math.sin(ang),
      );
      final outer = Offset(
        center.dx + (radius - 2) * math.cos(ang),
        center.dy + (radius - 2) * math.sin(ang),
      );
      canvas.drawLine(inner, outer, paint);
    }

    // Hands
    final hour = now.hour % 12 + now.minute / 60.0;
    final minute = now.minute + now.second / 60.0;
    final second = now.second + now.millisecond / 1000.0;

    final hourAngle = (hour * 30) * math.pi / 180;
    final minuteAngle = (minute * 6) * math.pi / 180;
    final secondAngle = (second * 6) * math.pi / 180;

    // Hour hand
    paint
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final hourLen = radius * 0.5;
    final hourOffset = Offset(
      center.dx + hourLen * math.cos(hourAngle - math.pi / 2),
      center.dy + hourLen * math.sin(hourAngle - math.pi / 2),
    );
    canvas.drawLine(center, hourOffset, paint);

    // Minute hand
    paint
      ..color = Colors.white
      ..strokeWidth = 2.4;
    final minLen = radius * 0.72;
    final minOffset = Offset(
      center.dx + minLen * math.cos(minuteAngle - math.pi / 2),
      center.dy + minLen * math.sin(minuteAngle - math.pi / 2),
    );
    canvas.drawLine(center, minOffset, paint);

    // Second hand
    paint
      ..color = Colors.redAccent
      ..strokeWidth = 1.6;
    final secLen = radius * 0.82;
    final secOffset = Offset(
      center.dx + secLen * math.cos(secondAngle - math.pi / 2),
      center.dy + secLen * math.sin(secondAngle - math.pi / 2),
    );
    canvas.drawLine(center, secOffset, paint);

    // Center knob
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawCircle(center, 3.6, paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      now.second != old.now.second ||
      now.minute != old.now.minute ||
      now.hour != old.now.hour;
}
