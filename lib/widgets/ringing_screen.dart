import 'dart:async';
import 'dart:math';
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
  String _persona = 'Aoede';
  int _delaySeconds = 6;

  // Mission States
  bool _showMissionDialog = false;

  // Math Mission
  late int _mathA;
  late int _mathB;
  late int _mathAnswer;
  final TextEditingController _mathInputController = TextEditingController();

  // Riddle Mission
  RiddleMission? _riddle;
  int? _selectedRiddleOption;

  // Shake / Tap Mission
  int _shakeCount = 0;
  final int _targetShakes = 15;

  @override
  void initState() {
    super.initState();
    _initMission();
    _loadSettingsAndStartAI();
  }

  void _initMission() {
    final rand = Random();
    _mathA = rand.nextInt(40) + 12;
    _mathB = rand.nextInt(40) + 15;
    _mathAnswer = _mathA + _mathB;

    if (widget.alarm.mission == 'riddle') {
      _geminiService.generateMissionRiddle().then((r) {
        if (mounted) setState(() => _riddle = r);
      });
    }
  }

  Future<void> _loadSettingsAndStartAI() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Abu Saalim';
    _voiceName = prefs.getString('tts_voice') ?? 'Aoede';
    _persona = prefs.getString('ai_persona') ?? 'Aoede';
    _delaySeconds = prefs.getInt('speech_delay') ?? 6;

    _speechTimer = Timer(Duration(seconds: _delaySeconds), _triggerAISpeech);
  }

  Future<void> _triggerAISpeech() async {
    if (!mounted) return;
    setState(() => _isAITalking = true);

    String text;
    if (widget.alarm.mission == 'roast') {
      text = await _geminiService.generateWakeUpRoast(
        userName: _userName,
        attemptNumber: _attemptNumber,
      );
    } else {
      text = await _geminiService.generateWakeUpMessage(
        userName: _userName,
        alarmLabel: widget.alarm.label,
        goal: widget.alarm.goal,
        attemptNumber: _attemptNumber,
        persona: _persona,
      );
    }

    if (!mounted) return;
    setState(() => _spokenMessage = text);

    await _geminiService.speakRealisticVoice(
      text,
      voiceName: _voiceName,
      onDone: () {
        if (mounted) {
          setState(() => _isAITalking = false);
          _attemptNumber++;
          _speechTimer = Timer(const Duration(seconds: 22), _triggerAISpeech);
        }
      },
    );
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _geminiService.stopSpeaking();
    _mathInputController.dispose();
    super.dispose();
  }

  void _onDismissPressed() {
    if (widget.alarm.mission == 'none') {
      _completeDismiss();
    } else {
      setState(() => _showMissionDialog = true);
    }
  }

  Future<void> _completeDismiss() async {
    _speechTimer?.cancel();
    await _geminiService.stopSpeaking();
    await _alarmService.dismiss();
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
            radius: 1.15,
            colors: [
              AppColors.darkBlob1.withOpacity(0.95),
              AppColors.darkBg1,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SafeArea(
          child: _showMissionDialog
              ? _buildMissionView(ink, mute, acc)
              : _buildStandardRingingView(ink, mute, acc),
        ),
      ),
    );
  }

  Widget _buildStandardRingingView(Color ink, Color mute, Color acc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Alarm Info
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.alarm.mission != 'none') ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.alarm.mission.toUpperCase()} MISSION',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.alarm.label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: mute,
                  ),
                ),
              ],
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
              size: 135,
              isLive: true,
              isSpeaking: _isAITalking,
              icon: Icon(
                Icons.alarm,
                size: 44,
                color: AppColors.darkAccentInk,
              ),
            ),
            const SizedBox(height: 24),

            // AI Spoken Quote
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
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
              onPressed: _onDismissPressed,
              style: FilledButton.styleFrom(
                backgroundColor: acc,
                foregroundColor: AppColors.darkAccentInk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: Text(
                widget.alarm.mission != 'none'
                    ? 'Start Mission'
                    : 'Dismiss',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- MISSION CHALLENGE VIEW ---
  Widget _buildMissionView(Color ink, Color mute, Color acc) {
    final mission = widget.alarm.mission;

    return Center(
      child: GlassBox(
        isDark: widget.isDark,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'WAKE-UP MISSION',
                  style: GoogleFonts.interTight(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. MATH MISSION
            if (mission == 'math') ...[
              Text(
                'Solve this math problem to dismiss:',
                style: TextStyle(color: mute, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Text(
                '$_mathA + $_mathB = ?',
                style: GoogleFonts.interTight(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mathInputController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ink, fontSize: 26, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Answer',
                  hintStyle: TextStyle(color: mute.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(_mathInputController.text.trim());
                    if (val == _mathAnswer) {
                      _completeDismiss();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wrong answer! Try again to wake up!'),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: acc,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Verify & Wake Up',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]
            // 2. SHAKE / TAP MISSION
            else if (mission == 'shake') ...[
              Text(
                'Tap the button repeatedly to prove you are awake!',
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _shakeCount / _targetShakes,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(acc),
                    ),
                  ),
                  Text(
                    '$_shakeCount / $_targetShakes',
                    style: GoogleFonts.interTight(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _shakeCount++);
                  if (_shakeCount >= _targetShakes) {
                    _completeDismiss();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: acc,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                icon: const Icon(Icons.touch_app),
                label: const Text('TAP! TAP! TAP!',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]
            // 3. RIDDLE MISSION
            else if (mission == 'riddle') ...[
              if (_riddle == null)
                const CircularProgressIndicator()
              else ...[
                Text(
                  _riddle!.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(_riddle!.options.length, (idx) {
                    final opt = _riddle!.options[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedRiddleOption = idx);
                          if (idx == _riddle!.correctIndex) {
                            _completeDismiss();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Incorrect! Think carefully.'),
                                backgroundColor: Colors.redAccent,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRiddleOption == idx
                                ? acc.withOpacity(0.3)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ]
            // 4. ROAST MISSION
            else ...[
              Text(
                'Listen to the AI wake-up roast. Are you ready to admit defeat and get out of bed?',
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _completeDismiss,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: acc,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('I am Awake! Stop the Roast',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showMissionDialog = false),
              child: Text('Back to Alarm', style: TextStyle(color: mute)),
            ),
          ],
        ),
      ),
    );
  }
}
