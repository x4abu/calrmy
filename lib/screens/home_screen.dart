import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analog_clock.dart';
import '../widgets/new_alarm_modal.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onOpenSheet;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onOpenSheet,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _alarmService = AlarmService.instance;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  String _userName = 'Abu Saalim';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Abu Saalim';
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final h = _currentTime.hour;
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  String _relativeTimeTo(DateTime target) {
    final diff = target.difference(_currentTime);
    if (diff.isNegative) return 'Now';
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours >= 24) {
      return '${hours ~/ 24}d ${hours % 24}h';
    }
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return ValueListenableBuilder<List<Alarm>>(
      valueListenable: _alarmService.alarmsNotifier,
      builder: (context, alarms, child) {
        final activeAlarms = alarms.where((a) => a.isEnabled).toList();
        final next = _alarmService.nextAlarm;

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
              // Greeting & User Name with App Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: mute,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userName,
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 34,
                          fontStyle: FontStyle.italic,
                          color: ink,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: acc.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Glass Clock Card (Analog + Digital)
              GlassBox(
                isDark: widget.isDark,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                child: Column(
                  children: [
                    Center(
                      child: AnalogClock(
                        alarms: alarms,
                        isDark: widget.isDark,
                        size: 230,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          DateFormat('hh:mm').format(_currentTime),
                          style: GoogleFonts.interTight(
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.5,
                            color: ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('a').format(_currentTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: mute,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(_currentTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mute,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Twin Info Tiles: Next alarm & Active alarms
              Row(
                children: [
                  Expanded(
                    child: GlassBox(
                      isDark: widget.isDark,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next alarm',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: mute,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            next != null
                                ? 'in ${_relativeTimeTo(next.nextTriggerDateTime())}'
                                : '—',
                            style: GoogleFonts.interTight(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassBox(
                      isDark: widget.isDark,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active alarms',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: mute,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activeAlarms.length}',
                            style: GoogleFonts.interTight(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 7-day Dot Grid
              GlassBox(
                isDark: widget.isDark,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                borderRadius: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final dayDate = _currentTime.add(Duration(days: i));
                    final isToday = i == 0;
                    final dayOfWeek = dayDate.weekday % 7;
                    final alarmsForDay = activeAlarms
                        .where((a) => a.days.isEmpty || a.days.contains(dayOfWeek))
                        .length;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isToday ? acc : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dayOfWeek],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? (widget.isDark
                                      ? AppColors.darkAccentInk
                                      : Colors.white)
                                  : mute,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? (widget.isDark
                                      ? AppColors.darkAccentInk
                                      : Colors.white)
                                  : ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              alarmsForDay.clamp(0, 3),
                              (dotIdx) => Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isToday
                                      ? (widget.isDark
                                          ? AppColors.darkAccentInk
                                          : Colors.white)
                                      : acc,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Schedule
              Text(
                'Schedule',
                style: GoogleFonts.interTight(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),

              if (activeAlarms.isEmpty)
                GlassBox(
                  isDark: widget.isDark,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nothing scheduled. Add an alarm to get started.',
                      style: TextStyle(color: mute, fontSize: 14),
                    ),
                  ),
                )
              else
                Column(
                  children: activeAlarms.take(4).map((al) {
                    final target = al.nextTriggerDateTime();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  al.formattedDisplayTime,
                                  style: GoogleFonts.interTight(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                  ),
                                ),
                                Text(
                                  al.period,
                                  style: TextStyle(fontSize: 11, color: mute),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dot & Line
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: acc,
                                  boxShadow: [
                                    BoxShadow(
                                      color: acc.withOpacity(0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassBox(
                              isDark: widget.isDark,
                              padding: const EdgeInsets.all(14),
                              borderRadius: 18,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    al.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    al.goal.isNotEmpty
                                        ? al.goal
                                        : 'Sound: ${al.sound.replaceAll('.wav', '')}',
                                    style: TextStyle(fontSize: 13, color: mute),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'in ${_relativeTimeTo(target)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDark
                                          ? AppColors.darkAccentDeep
                                          : AppColors.lightAccentDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Section: All alarms + "+ New" Pill Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All alarms',
                    style: GoogleFonts.interTight(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: ink,
                    ),
                  ),
                  FilledButton(
                    onPressed: widget.onOpenSheet,
                    style: FilledButton.styleFrom(
                      backgroundColor: acc,
                      foregroundColor: widget.isDark
                          ? AppColors.darkAccentInk
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: const Text(
                      '+ New',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // All Alarms List
              if (alarms.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No alarms yet. Tap + New.',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: mute,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: alarms.map((alarm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassBox(
                        isDark: widget.isDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => NewAlarmModal(
                              existingAlarm: alarm,
                              isDark: widget.isDark,
                              onSave: (updated) {
                                _alarmService.updateAlarm(updated);
                              },
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            // Time
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  alarm.formattedDisplayTime,
                                  style: GoogleFonts.interTight(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -1,
                                    color: alarm.isEnabled
                                        ? ink
                                        : mute.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  alarm.period,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: mute,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Label & Days
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alarm.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: alarm.isEnabled
                                          ? ink
                                          : mute.withOpacity(0.5),
                                    ),
                                  ),
                                  Text(
                                    '${alarm.daysSummary} · ${alarm.sound.replaceAll('.wav', '').replaceAll('_', ' ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: mute,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: mute.withOpacity(0.6), size: 20),
                              onPressed: () {
                                _alarmService.deleteAlarm(alarm.id);
                              },
                            ),

                            // Switch
                            Switch(
                              value: alarm.isEnabled,
                              activeColor: acc,
                              onChanged: (_) {
                                _alarmService.toggleAlarm(alarm);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
