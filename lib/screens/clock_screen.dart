import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class WorldCity {
  final String name;
  final String country;
  final double utcOffsetHours;
  final String icon;

  const WorldCity({
    required this.name,
    required this.country,
    required this.utcOffsetHours,
    required this.icon,
  });

  DateTime get localTime {
    final nowUtc = DateTime.now().toUtc();
    final totalMinutes = (utcOffsetHours * 60).round();
    return nowUtc.add(Duration(minutes: totalMinutes));
  }

  bool get isDay {
    final hour = localTime.hour;
    return hour >= 6 && hour < 19;
  }

  String get timeDifferenceString {
    final userNow = DateTime.now();
    final diff = localTime.difference(userNow).inMinutes / 60.0;
    if (diff.abs() < 0.1) return 'Same time';
    final sign = diff > 0 ? '+' : '';
    final h = diff.truncate();
    final m = ((diff - h).abs() * 60).round();
    if (m == 0) return '$sign${h}h';
    return '$sign${h}h ${m}m';
  }
}

class ClockScreen extends StatefulWidget {
  final bool isDark;

  const ClockScreen({super.key, required this.isDark});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  static const List<WorldCity> _cities = [
    WorldCity(
        name: 'Mumbai', country: 'India', utcOffsetHours: 5.5, icon: '🇮🇳'),
    WorldCity(
        name: 'Dubai', country: 'UAE', utcOffsetHours: 4.0, icon: '🇦🇪'),
    WorldCity(
        name: 'London', country: 'UK', utcOffsetHours: 0.0, icon: '🇬🇧'),
    WorldCity(
        name: 'New York', country: 'USA', utcOffsetHours: -5.0, icon: '🇺🇸'),
    WorldCity(
        name: 'Tokyo', country: 'Japan', utcOffsetHours: 9.0, icon: '🇯🇵'),
    WorldCity(
        name: 'Sydney', country: 'Australia', utcOffsetHours: 11.0, icon: '🇦🇺'),
    WorldCity(
        name: 'Paris', country: 'France', utcOffsetHours: 1.0, icon: '🇫🇷'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addSleepAlarm(DateTime wakeTime, String cycleLabel) async {
    final hh = wakeTime.hour.toString().padLeft(2, '0');
    final mm = wakeTime.minute.toString().padLeft(2, '0');

    final newAlarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch,
      time: '$hh:$mm',
      label: 'Wake up ($cycleLabel)',
      goal: 'Feel refreshed & energised',
      days: [],
      isEnabled: true,
      sound: 'zen_singing_bowl.wav',
    );

    await AlarmService.instance.addAlarm(newAlarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled alarm for $hh:$mm ($cycleLabel)'),
          backgroundColor: widget.isDark
              ? AppColors.darkCard
              : AppColors.lightCard,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'World Time & Sleep Cycles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mute,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Global Rhythm',
            style: GoogleFonts.instrumentSerif(
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Sleep Cycle Calculator Card
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bedtime_outlined, color: acc, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sleep Cycle Calculator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: acc.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '90-min cycles',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: acc,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Waking up at the end of a 90-min sleep cycle prevents grogginess. If you fall asleep now:',
                  style: TextStyle(fontSize: 13, color: mute, height: 1.3),
                ),
                const SizedBox(height: 14),

                // Sleep Cycle Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCycleChip(
                      context,
                      cycles: 1,
                      duration: const Duration(minutes: 90),
                      label: 'Power Nap',
                      ink: ink,
                      mute: mute,
                      acc: acc,
                    ),
                    _buildCycleChip(
                      context,
                      cycles: 3,
                      duration: const Duration(hours: 4, minutes: 30),
                      label: 'Short Rest',
                      ink: ink,
                      mute: mute,
                      acc: acc,
                    ),
                    _buildCycleChip(
                      context,
                      cycles: 4,
                      duration: const Duration(hours: 6),
                      label: '6.0 Hours',
                      ink: ink,
                      mute: mute,
                      acc: acc,
                    ),
                    _buildCycleChip(
                      context,
                      cycles: 5,
                      duration: const Duration(hours: 7, minutes: 30),
                      label: 'Optimal (7.5h)',
                      isRecommended: true,
                      ink: ink,
                      mute: mute,
                      acc: acc,
                    ),
                    _buildCycleChip(
                      context,
                      cycles: 6,
                      duration: const Duration(hours: 9),
                      label: 'Full Recovery',
                      ink: ink,
                      mute: mute,
                      acc: acc,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // World Clock Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORLD CLOCKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: mute,
                ),
              ),
              Text(
                'Local: ${DateFormat('HH:mm:ss').format(_now)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: acc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // City list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final city = _cities[index];
              final cityTime = city.localTime;
              final timeStr = DateFormat('hh:mm').format(cityTime);
              final period = DateFormat('a').format(cityTime);

              return GlassBox(
                isDark: widget.isDark,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(city.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                city.isDay
                                    ? Icons.wb_sunny_outlined
                                    : Icons.nights_stay_outlined,
                                size: 12,
                                color: city.isDay
                                    ? Colors.amber
                                    : Colors.indigoAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${city.country} • ${city.timeDifferenceString}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mute,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: mute,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('EEE, MMM d').format(cityTime),
                          style: TextStyle(fontSize: 11, color: mute),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCycleChip(
    BuildContext context, {
    required int cycles,
    required Duration duration,
    required String label,
    required Color ink,
    required Color mute,
    required Color acc,
    bool isRecommended = false,
  }) {
    // Standard 14 mins to fall asleep
    final wakeTime = _now.add(duration).add(const Duration(minutes: 14));
    final timeStr = DateFormat('hh:mm a').format(wakeTime);

    return InkWell(
      onTap: () => _addSleepAlarm(wakeTime, label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isRecommended
              ? acc.withOpacity(0.18)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRecommended
                ? acc.withOpacity(0.4)
                : (widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
            width: isRecommended ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isRecommended ? acc : ink,
                  ),
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 12, color: acc),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: mute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
