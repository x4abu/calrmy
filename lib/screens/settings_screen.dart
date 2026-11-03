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
  String _persona = 'Aoede';
  String _defaultSound = 'zen_singing_bowl.wav';
  int _delaySeconds = 6;
  bool _aiSpeaks = true;
  bool _isPlayingSample = false;
  bool _showCustomKey = false;

  // Backend test state
  bool _isTestingBackend = false;
  String? _backendStatus;
  bool _backendSuccess = false;

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
      _persona = prefs.getString('ai_persona') ?? 'Aoede';
      _defaultSound =
          prefs.getString('default_sound') ?? 'zen_singing_bowl.wav';
      _delaySeconds = prefs.getInt('speech_delay') ?? 6;
      _aiSpeaks = prefs.getBool('ai_speaks') ?? true;
      _customKeyController.text = prefs.getString('custom_gemini_key') ?? '';
      _showCustomKey = _customKeyController.text.isNotEmpty;
    });

    // Run background connection check
    _testBackendConnection(silent: true);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_goal', _goalController.text.trim());
    await prefs.setString('ai_lang', _langController.text.trim());
    await prefs.setString('tts_voice', _voiceName);
    await prefs.setString('ai_persona', _persona);
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

  Future<void> _testBackendConnection({bool silent = false}) async {
    setState(() => _isTestingBackend = true);
    final res = await _geminiService.testConnection();

    if (mounted) {
      setState(() {
        _isTestingBackend = false;
        _backendSuccess = res['success'] == true;
        _backendStatus = res['message'] as String?;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_backendSuccess
                ? 'Backend Online! ${res['message']}'
                : 'Connection Failed: ${res['message']}'),
            backgroundColor: _backendSuccess ? Colors.teal : Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

    final success = await _geminiService.speakRealisticVoice(
      sampleText,
      voiceName: _voiceName,
      onDone: () {
        if (mounted) setState(() => _isPlayingSample = false);
      },
    );

    if (!success && mounted) {
      setState(() => _isPlayingSample = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not generate voice sample. Check backend connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _testAlarmNow() {
    final now = DateTime.now();
    final testAlarm = Alarm(
      id: 999999,
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      label: 'Test Alarm Experience',
      goal: _goalController.text.trim().isNotEmpty
          ? _goalController.text.trim()
          : 'Testing cAlrmy features',
      sound: _defaultSound,
      days: [],
      isEnabled: true,
      mission: 'riddle',
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
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 14,
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

          // Backend Health & Status Card
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
                        Icon(
                          _backendSuccess
                              ? Icons.cloud_done
                              : Icons.cloud_sync,
                          color: _backendSuccess ? Colors.teal : acc,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Google Gemini AI Backend',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _backendSuccess
                            ? Colors.teal.withOpacity(0.18)
                            : acc.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _backendSuccess ? 'ONLINE' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _backendSuccess ? Colors.teal : acc,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _backendStatus ??
                      'Loading backend status (gemini-3.5-flash-lite & gemini-3.8-flash-lite-tts)…',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _backendSuccess ? Colors.tealAccent : mute,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isTestingBackend ? null : () => _testBackendConnection(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: acc.withOpacity(0.4)),
                    ),
                    icon: _isTestingBackend
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.speed, size: 16, color: acc),
                    label: Text(
                      _isTestingBackend
                          ? 'Measuring Latency…'
                          : 'Test Gemini Connection',
                      style: TextStyle(color: acc, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                    labelText: 'Current life goal / daily focus',
                    labelStyle: TextStyle(color: mute, fontSize: 13),
                    hintText: 'e.g. Master mobile app development',
                    hintStyle: TextStyle(color: mute.withOpacity(0.4)),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Voice & Persona Studio
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Companion Voice & Persona',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Google Studio gemini-3.8-flash-lite-tts realistic speech.',
                  style: TextStyle(fontSize: 12, color: mute),
                ),
                const SizedBox(height: 14),

                // Voice selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voice',
                        style: TextStyle(color: ink, fontSize: 14)),
                    DropdownButton<String>(
                      value: _voiceName,
                      dropdownColor: widget.isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      style: TextStyle(color: acc, fontWeight: FontWeight.w600),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'Aoede', child: Text('Aoede (Warm)')),
                        DropdownMenuItem(
                            value: 'Puck', child: Text('Puck (Playful)')),
                        DropdownMenuItem(
                            value: 'Charon', child: Text('Charon (Deep)')),
                        DropdownMenuItem(
                            value: 'Kore', child: Text('Kore (Calm)')),
                        DropdownMenuItem(
                            value: 'Fenrir', child: Text('Fenrir (Intense)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _voiceName = val);
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Test voice button
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
                          ? 'Stop Sample'
                          : 'Listen to Realistic Voice Sample',
                      style: TextStyle(color: acc),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: acc.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: Experience Controls
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Dark Mode Aesthetic',
                    style: TextStyle(color: ink, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Deep obsidian glassmorphism',
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                  value: widget.isDark,
                  activeColor: acc,
                  onChanged: (val) => widget.onThemeChanged(val),
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Test Alarm Experience Now',
                    style: TextStyle(color: ink, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Triggers full ringing screen with AI speech & mission',
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: acc),
                  onTap: _testAlarmNow,
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
                      'API Key Security & Backend',
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
                  'Your Google AI Studio key is configured on the backend and compiled into the app. You can also provide a custom key override below.',
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
                    onChanged: (_) {
                      _saveSettings();
                      _testBackendConnection(silent: true);
                    },
                    decoration: InputDecoration(
                      labelText: 'Override Gemini API Key',
                      labelStyle: TextStyle(color: mute, fontSize: 12),
                      hintText: 'Leave empty to use built-in backend default',
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
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.2 • The AI Alarm Companion',
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
