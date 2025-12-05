import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shifts_provider.dart';
import 'analog_clock.dart';

// Local copy of the green used in the app (keeps this widget standalone).
const Color spotifyGreenLocal = Color(0xFF1DB954);

class BigCheckButton extends StatefulWidget {
  const BigCheckButton({super.key});

  @override
  State<BigCheckButton> createState() => _BigCheckButtonState();
}

class _BigCheckButtonState extends State<BigCheckButton>
    with TickerProviderStateMixin {
  late AnimationController _holdController;
  bool _actionTriggered = false;
  bool _pressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_actionTriggered) {
        _actionTriggered = true;
        _performAction();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _performAction() async {
    final provider = context.read<ShiftsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (provider.arrival == null) {
      // Ask who the manager is today before checking in
      String selected = 'Garry';
      final result = await showDialog<String?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Who is the manager today?'),
            content: StatefulBuilder(
              builder: (c, setState) {
                return DropdownButton<String>(
                  value: selected,
                  items: const [
                    DropdownMenuItem(value: 'Garry', child: Text('Garry')),
                    DropdownMenuItem(value: 'David', child: Text('David')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selected = v);
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (result != null) {
        provider.recordArrivalWithManager(result);
        messenger.showSnackBar(
          SnackBar(content: Text('Checked in (manager: $result)')),
        );
      }
    } else {
      provider.recordDeparture();
      messenger.showSnackBar(const SnackBar(content: Text('Checked out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<ShiftsProvider>();

    final screenW = MediaQuery.of(context).size.width;
    final baseSize = (screenW * 0.5).clamp(140.0, 300.0).toDouble();
    final outerSize = baseSize;
    final ringSize = (outerSize * 0.94).clamp(120.0, 280.0).toDouble();
    final innerSize = (outerSize * 0.83).clamp(100.0, 250.0).toDouble();
    final clockSize = (innerSize * 0.73).clamp(72.0, 220.0).toDouble();
    final iconSize = (innerSize * 0.42).clamp(36.0, 110.0).toDouble();

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          _performAction();
        },
        onLongPressStart: (_) {
          _actionTriggered = false;
          _holdController.forward(from: 0.0);
          setState(() => _pressed = true);
        },
        onLongPressEnd: (_) {
          if (!_actionTriggered) {
            _holdController.reverse();
          }
          setState(() => _pressed = false);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: SizedBox(
                width: outerSize,
                height: outerSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final glow = 8.0 + (_pulseController.value * 14.0);
                        return Container(
                          width: outerSize,
                          height: outerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: spotifyGreenLocal.withAlpha(40),
                                blurRadius: glow,
                                spreadRadius: glow / 6,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: AnimatedBuilder(
                        animation: _holdController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: _holdController.value,
                            strokeWidth: 8,
                            color: Colors.white.withAlpha(230),
                            backgroundColor: Colors.white24,
                          );
                        },
                      ),
                    ),

                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: Ink(
                        width: innerSize,
                        height: innerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              spotifyGreenLocal.withAlpha(220),
                              spotifyGreenLocal,
                            ],
                          ),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {},
                          splashColor: Colors.white24,
                          highlightColor: Colors.white10,
                          child: AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, _) {
                              final showClock =
                                  shifts.arrival != null ||
                                  _holdController.value > 0.0;
                              return Center(
                                child: showClock
                                    ? AnalogClock(size: clockSize)
                                    : Icon(
                                        Icons.login,
                                        color: Colors.white,
                                        size: iconSize,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shifts.arrival == null ? 'Check in' : 'Check out',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
