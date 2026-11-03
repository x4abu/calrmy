import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/alarm.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/talk_screen.dart';
import 'services/alarm_service.dart';
import 'theme/app_theme.dart';
import 'widgets/new_alarm_modal.dart';
import 'widgets/ringing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    try {
      await dotenv.load(fileName: ".env.example");
    } catch (_) {}
  }

  await AlarmService.instance.init();

  runApp(const CalrmyApp());
}

class CalrmyApp extends StatefulWidget {
  const CalrmyApp({super.key});

  @override
  State<CalrmyApp> createState() => _CalrmyAppState();
}

class _CalrmyAppState extends State<CalrmyApp> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('is_dark_theme') ?? true;
    });
  }

  void _toggleTheme(bool isDark) async {
    setState(() => _isDark = isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cAlrmy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(isDark: _isDark),
      home: MainShell(
        isDark: _isDark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const MainShell({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final AlarmService _alarmService = AlarmService.instance;

  void _openNewAlarmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewAlarmModal(
        isDark: widget.isDark,
        onSave: (newAlarm) {
          _alarmService.addAlarm(newAlarm);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg1 = widget.isDark ? AppColors.darkBg1 : AppColors.lightBg1;
    final bg2 = widget.isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Stack(
      children: [
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
            ),
          ),
        ),

        // Ambient Decorative Blobs
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (widget.isDark ? AppColors.darkBlob1 : AppColors.lightBlob1)
                  .withOpacity(0.55),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (widget.isDark ? AppColors.darkBlob2 : AppColors.lightBlob2)
                  .withOpacity(0.55),
            ),
          ),
        ),

        // Main Scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                isDark: widget.isDark,
                onOpenSheet: _openNewAlarmSheet,
              ),
              TalkScreen(isDark: widget.isDark),
              SettingsScreen(
                isDark: widget.isDark,
                onThemeChanged: widget.onThemeChanged,
              ),
            ],
          ),

          // Floating Glass Bottom Navigation Bar
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 68,
              margin: const EdgeInsets.only(left: 28, right: 28, bottom: 16),
              child: GlassBox(
                isDark: widget.isDark,
                borderRadius: 99,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Alarms',
                      icon: Icons.alarm,
                      acc: acc,
                      ink: ink,
                      mute: mute,
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Talk',
                      icon: Icons.graphic_eq,
                      acc: acc,
                      ink: ink,
                      mute: mute,
                    ),
                    _buildNavItem(
                      index: 2,
                      label: 'Settings',
                      icon: Icons.tune,
                      acc: acc,
                      ink: ink,
                      mute: mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fullscreen Ringing Screen
        ValueListenableBuilder<Alarm?>(
          valueListenable: _alarmService.ringingAlarmNotifier,
          builder: (context, ringingAlarm, child) {
            if (ringingAlarm == null) return const SizedBox.shrink();
            return RingingScreen(
              alarm: ringingAlarm,
              isDark: widget.isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required Color acc,
    required Color ink,
    required Color mute,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(widget.isDark ? 0.16 : 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? ink : mute,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
