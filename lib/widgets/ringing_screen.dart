import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'orb_widget.dart';

class RingingScreen extends StatefulWidget {
  final Alarm alarm;
  final bool isDark;

  const RingingScreen({
    super.key,
    required this.alarm,
    this.isDark = true,
  });

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen> {
  final GeminiService _geminiService = GeminiService.instance;
  final AlarmService _alarmService = AlarmService.instance;

  String _spokenMessage = '…';
  int _attemptNumber = 1;
  Timer? _speechTimer;
  bool _isAITalking = false;
  String _userName = 'Abu Saalim';
  String _voiceName = 'Aoede';
  int _delaySeconds = 10;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStartAI();
  }

  Future<void> _loadSettingsAndStartAI() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Abu Saalim';
    _voiceName = prefs.getString('tts_voice') ?? 'Aoede';
    _delaySeconds = prefs.getInt('speech_delay') ?? 10;

    _speechTimer = Timer(Duration(seconds: _delaySeconds), _triggerAISpeech);
  }

  Future<void> _triggerAISpeech() async {
    if (!mounted) return;
    setState(() => _isAITalking = true);

    final text = await _geminiService.generateWakeUpMessage(
      userName: _userName,
      alarmLabel: widget.alarm.label,
      goal: widget.alarm.goal,
      attemptNumber: _attemptNumber,
    );

    if (!mounted) return;
    setState(() => _spokenMessage = text);

    await _geminiService.speakRealisticVoice(
      text,
      voiceName: _voiceName,
      onDone: () {
        if (mounted) {
          setState(() => _isAITalking = false);
          // Escalate again in 25 seconds if still ringing
          _attemptNumber++;
          _speechTimer = Timer(const Duration(seconds: 25), _triggerAISpeech);
        }
      },
    );
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _geminiService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.1,
            colors: [
              AppColors.darkBlob1.withOpacity(0.9),
              AppColors.darkBg1,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Alarm Info
              Column(
                children: [
                  Text(
                    widget.alarm.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: mute,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.alarm.formattedDisplayTime,
                    style: GoogleFonts.interTight(
                      fontSize: 88,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -4,
                      color: ink,
                    ),
                  ),
                ],
              ),

              // Glowing Pulsing Orb
              Column(
                children: [
                  OrbWidget(
                    size: 130,
                    isLive: true,
                    isSpeaking: _isAITalking,
                    icon: Icon(
                      Icons.alarm,
                      size: 44,
                      color: AppColors.darkAccentInk,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI Speech Quote
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      _spokenMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 26,
                        fontStyle: FontStyle.italic,
                        height: 1.25,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Buttons (Snooze & Dismiss)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      _geminiService.stopSpeaking();
                      await _alarmService.snooze();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Snooze 5m',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () async {
                      _geminiService.stopSpeaking();
                      await _alarmService.dismiss();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: acc,
                      foregroundColor: AppColors.darkAccentInk,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
