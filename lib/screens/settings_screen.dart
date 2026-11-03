import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/gemini_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _langController = TextEditingController();
  final TextEditingController _customKeyController = TextEditingController();

  String _voiceName = 'Aoede';
  String _defaultSound = 'zen_singing_bowl.wav';
  int _delaySeconds = 10;
  bool _aiSpeaks = true;
  bool _isPlayingSample = false;
  bool _showCustomKey = false;

  final GeminiService _geminiService = GeminiService.instance;
  final SoundService _soundService = SoundService.instance;
  final AlarmService _alarmService = AlarmService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'Abu Saalim';
      _goalController.text = prefs.getString('user_goal') ?? '';
      _langController.text = prefs.getString('ai_lang') ?? '';
      _voiceName = prefs.getString('tts_voice') ?? 'Aoede';
      _defaultSound = prefs.getString('default_sound') ?? 'zen_singing_bowl.wav';
      _delaySeconds = prefs.getInt('speech_delay') ?? 10;
      _aiSpeaks = prefs.getBool('ai_speaks') ?? true;
      _customKeyController.text = prefs.getString('custom_gemini_key') ?? '';
      _showCustomKey = _customKeyController.text.isNotEmpty;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_goal', _goalController.text.trim());
    await prefs.setString('ai_lang', _langController.text.trim());
    await prefs.setString('tts_voice', _voiceName);
    await prefs.setString('default_sound', _defaultSound);
    await prefs.setInt('speech_delay', _delaySeconds);
    await prefs.setBool('ai_speaks', _aiSpeaks);
    await prefs.setString(
        'custom_gemini_key', _customKeyController.text.trim());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _langController.dispose();
    _customKeyController.dispose();
    _soundService.stop();
    _geminiService.stopSpeaking();
    super.dispose();
  }

  void _testVoiceSample() async {
    if (_isPlayingSample) {
      await _geminiService.stopSpeaking();
      setState(() => _isPlayingSample = false);
      return;
    }

    setState(() => _isPlayingSample = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Studio AI realistic voice sample…'),
        duration: Duration(seconds: 2),
      ),
    );

    final name = _nameController.text.trim().isEmpty
        ? 'Abu Saalim'
        : _nameController.text.trim();
    final sampleText =
        'Hi $name! This is your realistic AI voice powered by Google Studio. I will wake you up gently every morning.';

    await _geminiService.speakRealisticVoice(
      sampleText,
      voiceName: _voiceName,
      onDone: () {
        if (mounted) setState(() => _isPlayingSample = false);
      },
    );
  }

  void _testAlarmNow() {
    final now = DateTime.now();
    final testAlarm = Alarm(
      id: 999999,
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      label: 'Test Alarm',
      goal: _goalController.text.trim().isNotEmpty
          ? _goalController.text.trim()
          : 'Testing cAlrmy features',
      sound: _defaultSound,
      days: [],
    );
    _alarmService.triggerRing(testAlarm);
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
            'Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: mute,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Make it yours',
            style: GoogleFonts.instrumentSerif(
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Card 1: Personalization
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: ink),
                  onChanged: (_) => _saveSettings(),
                  decoration: InputDecoration(
                    labelText: 'Your name (the AI will call you by it)',
                    labelStyle: TextStyle(color: mute, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                TextField(
                  controller: _goalController,
                  maxLines: 2,
                  style: TextStyle(color: ink),
                  onChanged: (_) => _saveSettings(),
                  decoration: InputDecoration(
                    labelText: 'Goal — why do you want to wake up?',
                    hintText: 'e.g. Study Physics at 6 AM, pass the exam',
                    hintStyle: TextStyle(color: mute.withOpacity(0.5)),
                    labelStyle: TextStyle(color: mute, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                TextField(
                  controller: _langController,
                  style: TextStyle(color: ink),
                  onChanged: (_) => _saveSettings(),
                  decoration: InputDecoration(
                    labelText: 'AI language (optional)',
                    hintText: 'Leave empty for automatic auto-detection',
                    hintStyle: TextStyle(color: mute.withOpacity(0.5)),
                    labelStyle: TextStyle(color: mute, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seconds after alarm before AI speaks: $_delaySeconds s',
                        style: TextStyle(color: ink, fontSize: 14),
                      ),
                    ),
                    Slider(
                      value: _delaySeconds.toDouble(),
                      min: 3,
                      max: 45,
                      divisions: 14,
                      activeColor: acc,
                      onChanged: (v) {
                        setState(() => _delaySeconds = v.toInt());
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Realistic AI Voice (Studio AI TTS)
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Realistic AI Voice (Google Studio TTS)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: mute,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _voiceName,
                  dropdownColor:
                      widget.isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                  style: TextStyle(color: ink, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white
                        .withOpacity(widget.isDark ? 0.08 : 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Aoede',
                      child: Text('Aoede (Warm & Natural Female — Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: 'Kore',
                      child: Text('Kore (Gentle & Calm Female)'),
                    ),
                    DropdownMenuItem(
                      value: 'Puck',
                      child: Text('Puck (Cheerful & Lively Male)'),
                    ),
                    DropdownMenuItem(
                      value: 'Charon',
                      child: Text('Charon (Deep & Relaxed Male)'),
                    ),
                    DropdownMenuItem(
                      value: 'Fenrir',
                      child: Text('Fenrir (Clear & Confident Male)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _voiceName = val);
                      _saveSettings();
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testVoiceSample,
                    icon: Icon(
                      _isPlayingSample ? Icons.stop : Icons.volume_up,
                      color: acc,
                    ),
                    label: Text(
                      _isPlayingSample
                          ? 'Stop sample'
                          : 'Listen to realistic voice sample',
                      style: TextStyle(color: ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: Colors.white
                            .withOpacity(widget.isDark ? 0.15 : 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: Sounds & Toggles
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Light mode', style: TextStyle(color: ink, fontSize: 16)),
                    Switch(
                      value: !widget.isDark,
                      activeColor: acc,
                      onChanged: (isLight) => widget.onThemeChanged(!isLight),
                    ),
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI speaks aloud',
                        style: TextStyle(color: ink, fontSize: 16)),
                    Switch(
                      value: _aiSpeaks,
                      activeColor: acc,
                      onChanged: (v) {
                        setState(() => _aiSpeaks = v);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testAlarmNow,
                    icon: Icon(Icons.alarm_on, color: acc),
                    label: Text('Test alarm now', style: TextStyle(color: ink)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: Colors.white
                            .withOpacity(widget.isDark ? 0.15 : 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 4: Backend Key Security Info
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: acc, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Security & Backend .env',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Gemini API key is securely loaded from .env. It is excluded from Git repositories and never exposed in the front-end interface.',
                  style: TextStyle(fontSize: 12.5, color: mute, height: 1.4),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _showCustomKey = !_showCustomKey);
                  },
                  child: Text(
                    _showCustomKey
                        ? 'Hide custom key override'
                        : 'Custom key override (optional)',
                    style: TextStyle(color: acc, fontSize: 13),
                  ),
                ),
                if (_showCustomKey) ...[
                  TextField(
                    controller: _customKeyController,
                    obscureText: true,
                    style: TextStyle(color: ink, fontSize: 14),
                    onChanged: (_) => _saveSettings(),
                    decoration: InputDecoration(
                      labelText: 'Override Gemini API Key',
                      labelStyle: TextStyle(color: mute, fontSize: 12),
                      hintText: 'Leave empty to use backend .env default',
                      hintStyle: TextStyle(color: mute.withOpacity(0.4)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Logo & Version
          Center(
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: acc.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'cAlrmy',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.1 • AI Wake-up Companion',
                  style: TextStyle(fontSize: 12, color: mute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
