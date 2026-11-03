import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm.dart';
import '../theme/app_theme.dart';

class AnalogClock extends StatefulWidget {
  final List<Alarm> alarms;
  final bool isDark;
  final double size;

  const AnalogClock({
    super.key,
    required this.alarms,
    this.isDark = true,
    this.size = 236,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnalogClockPainter(
            alarms: widget.alarms,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final List<Alarm> alarms;
  final bool isDark;

  _AnalogClockPainter({
    required this.alarms,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = isDark ? const Color(0x12FFFFFF) : const Color(0x0F000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final rimPaint = Paint()
      ..color = isDark ? const Color(0x38808080) : const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, rimPaint);

    // 60 Ticks
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 8.0 : 3.5;
      final p1 = Offset(
        center.dx + (radius - 5) * sin(angle),
        center.dy - (radius - 5) * cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 5 - tickLength) * sin(angle),
        center.dy - (radius - 5 - tickLength) * cos(angle),
      );

      final tickPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black)
            .withOpacity(isMajor ? 0.7 : 0.25)
        ..strokeWidth = isMajor ? 1.8 : 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Numerals (12, 3, 6, 9) in Instrument Serif
    final numbers = [
      {'n': '12', 'x': center.dx, 'y': center.dy - radius + 32},
      {'n': '3', 'x': center.dx + radius - 32, 'y': center.dy},
      {'n': '6', 'x': center.dx, 'y': center.dy + radius - 32},
      {'n': '9', 'x': center.dx - radius + 32, 'y': center.dy},
    ];

    for (final item in numbers) {
      final span = TextSpan(
        text: item['n'] as String,
        style: GoogleFonts.instrumentSerif(
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.75),
        ),
      );
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (item['x'] as double) - tp.width / 2,
          (item['y'] as double) - tp.height / 2,
        ),
      );
    }

    // Alarm markers along rim
    final markerPaint = Paint()
      ..color = isDark ? AppColors.darkAccent : AppColors.lightAccent
      ..style = PaintingStyle.fill;

    for (final alarm in alarms.where((a) => a.isEnabled)) {
      final alarmAngle =
          ((alarm.hour % 12) + alarm.minute / 60.0) * 30 * pi / 180;
      final mPos = Offset(
        center.dx + (radius - 18) * sin(alarmAngle),
        center.dy - (radius - 18) * cos(alarmAngle),
      );
      canvas.drawCircle(mPos, 3.4, markerPaint);
    }

    // Current Time
    final now = DateTime.now();
    final millisecond = now.millisecond;
    final secondFraction = now.second + millisecond / 1000.0;
    final minuteFraction = now.minute + secondFraction / 60.0;
    final hourFraction = (now.hour % 12) + minuteFraction / 60.0;

    // Hour Hand
    final hourAngle = hourFraction * 30 * pi / 180;
    final hourHandLength = radius * 0.52;
    final hourPaint = Paint()
      ..color = isDark ? AppColors.darkInk : AppColors.lightInk
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + hourHandLength * sin(hourAngle),
        center.dy - hourHandLength * cos(hourAngle),
      ),
      hourPaint,
    );

    // Minute Hand
    final minAngle = minuteFraction * 6 * pi / 180;
    final minHandLength = radius * 0.72;
    final minPaint = Paint()
      ..color = isDark ? AppColors.darkInk : AppColors.lightInk
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minHandLength * sin(minAngle),
        center.dy - minHandLength * cos(minAngle),
      ),
      minPaint,
    );

    // Second Hand (Accent)
    final secAngle = secondFraction * 6 * pi / 180;
    final secHandLength = radius * 0.85;
    final secTailLength = 16.0;
    final secPaint = Paint()
      ..color = isDark ? AppColors.darkAccent : AppColors.lightAccent
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(
        center.dx - secTailLength * sin(secAngle),
        center.dy + secTailLength * cos(secAngle),
      ),
      Offset(
        center.dx + secHandLength * sin(secAngle),
        center.dy - secHandLength * cos(secAngle),
      ),
      secPaint,
    );

    // Center Hubs
    final centerOuter = Paint()
      ..color = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    canvas.drawCircle(center, 5.0, centerOuter);

    final centerInner = Paint()
      ..color = isDark ? AppColors.darkBg1 : AppColors.lightBg1;
    canvas.drawCircle(center, 2.0, centerInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
