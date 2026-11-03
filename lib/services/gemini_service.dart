import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isSpeaking = false;
  VoidCallback? onSpeechFinished;

  bool get isSpeaking => _isSpeaking;

  Future<String> _getApiKey() async {
    // 1. Check SharedPreferences user override
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString('custom_gemini_key');
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }

    // 2. Check dotenv
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty && !envKey.contains('your_gemini')) {
      return envKey.trim();
    }

    // 3. Fallback to empty if not configured
    return '';
  }

  Future<String> generateWakeUpMessage({
    required String userName,
    required String alarmLabel,
    required String goal,
    required int attemptNumber,
    String language = '',
  }) async {
    final apiKey = await _getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
You are a warm, encouraging AI wake-up companion inside an alarm app called cAlrmy.
User name: $userName
Alarm label: $alarmLabel
Goal today: ${goal.isNotEmpty ? goal : 'start a wonderful day'}
Wake-up escalation attempt #$attemptNumber.
${attemptNumber < 2 ? 'Tone: Warm, gentle, friendly.' : 'Tone: Firmer, witty, a little urgent to get out of bed!'}
${language.isNotEmpty ? 'Speak in: $language.' : 'Speak in natural, warm English or Hindi/Hinglish depending on user goal.'}
Strict requirements: Maximum 2 short sentences. No markdown, no emojis, no bullet points, spoken aloud naturally.
''';

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 150,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final textParts = parts
              .where((p) => p['thought'] != true && p['text'] != null)
              .map((p) => p['text'].toString())
              .join(' ')
              .trim();
          if (textParts.isNotEmpty) return textParts;
        }
      }
    } catch (e) {
      debugPrint('Gemini generateWakeUpMessage error: $e');
    }

    // Fallbacks
    if (attemptNumber <= 1) {
      return '$userName, time to wake up! A fresh new morning is waiting for you.';
    } else {
      return '$userName, get out of bed now! Remember your goal: ${goal.isNotEmpty ? goal : 'make today count'}.';
    }
  }

  Future<String> chatResponse({
    required List<ChatMessage> history,
    required String userName,
    required String goal,
    String language = '',
  }) async {
    final apiKey = await _getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final systemPrompt = '''
You are a warm, caring personal AI voice companion in the cAlrmy alarm app for $userName.
Be a true, empathetic friend who listens, motivates, and cares.
${goal.isNotEmpty ? 'Main goal: $goal.' : ''}
${language.isNotEmpty ? 'Reply in: $language.' : 'Reply in the same language the user uses (English, Hindi, Hinglish, etc.).'}
Rules: Keep replies to 1-3 concise, natural sentences spoken aloud. No emojis, no markdown.
''';

    final contents = <Map<String, dynamic>>[];
    for (final msg in history.take(12)) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ]
      });
    }

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.85,
            'maxOutputTokens': 180,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final reply = parts
              .where((p) => p['thought'] != true && p['text'] != null)
              .map((p) => p['text'].toString())
              .join(' ')
              .trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    } catch (e) {
      debugPrint('Gemini chat error: $e');
    }

    return 'I am right here with you, $userName. How are you feeling today?';
  }

  Future<bool> speakRealisticVoice(
    String text, {
    String voiceName = 'Aoede',
    VoidCallback? onDone,
  }) async {
    final apiKey = await _getApiKey();
    final ttsModel = dotenv.env['DEFAULT_TTS_MODEL'] ?? 'gemini-3.8-flash-lite-tts';

    try {
      await stopSpeaking();
      _isSpeaking = true;

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$ttsModel:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': text}
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': voiceName,
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null) {
          for (final p in parts) {
            final inlineData = p['inlineData'];
            if (inlineData != null && inlineData['data'] != null) {
              final base64Str = inlineData['data'] as String;
              final bytes = base64Decode(base64Str);

              await _ttsPlayer.play(BytesSource(bytes));
              _ttsPlayer.onPlayerComplete.listen((_) {
                _isSpeaking = false;
                onDone?.call();
              });
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Realistic TTS error: $e');
    }

    _isSpeaking = false;
    onDone?.call();
    return false;
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _ttsPlayer.stop();
  }
}
