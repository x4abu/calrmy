import 'dart:async';
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

class RiddleMission {
  final String question;
  final List<String> options;
  final int correctIndex;

  RiddleMission({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isSpeaking = false;
  VoidCallback? onSpeechFinished;

  bool get isSpeaking => _isSpeaking;

  // Runtime fallback key base64 decoded
  static final String _bakedFallback = utf8.decode(base64Decode(
      'QVEuQWI4Uk42SzdpcXdGMlM4SzQ1Wmg2WTAtSTFqYlV6MUhLSFk5aW9yZU5VWTVZckkxM2c='));

  Future<String> getApiKey() async {
    // 1. SharedPreferences user override
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString('custom_gemini_key');
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim();
      }
    } catch (_) {}

    // 2. dart-define compile-time constant
    const buildKey = String.fromEnvironment('GEMINI_API_KEY');
    if (buildKey.isNotEmpty && !buildKey.contains('YOUR_')) {
      return buildKey;
    }

    // 3. dotenv
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null &&
          envKey.trim().isNotEmpty &&
          !envKey.contains('YOUR_') &&
          !envKey.contains('your_gemini')) {
        return envKey.trim();
      }
    } catch (_) {}

    // 4. Baked active key fallback
    return _bakedFallback;
  }

  Future<Map<String, dynamic>> testConnection() async {
    final sw = Stopwatch()..start();
    try {
      final apiKey = await getApiKey();
      final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Ping test. Reply with word PONG.'}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 10,
              }
            }),
          )
          .timeout(const Duration(seconds: 12));

      sw.stop();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'latencyMs': sw.elapsedMilliseconds,
          'message': 'Connected • Latency ${sw.elapsedMilliseconds}ms',
          'model': model,
        };
      } else {
        return {
          'success': false,
          'latencyMs': sw.elapsedMilliseconds,
          'message': 'Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      sw.stop();
      return {
        'success': false,
        'latencyMs': sw.elapsedMilliseconds,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<String> generateWakeUpMessage({
    required String userName,
    required String alarmLabel,
    required String goal,
    required int attemptNumber,
    String language = '',
    String persona = 'Aoede',
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    String personaInstruction = 'Tone: Warm, friendly, soothing.';
    if (persona == 'Fenrir') {
      personaInstruction =
          'Tone: Savage drill sergeant, tough-love, energetic, hilarious motivation.';
    } else if (persona == 'Puck') {
      personaInstruction =
          'Tone: Super hype-man, upbeat, enthusiastic, full of morning excitement!';
    } else if (persona == 'Charon') {
      personaInstruction =
          'Tone: Deep philosophical, calm zen wisdom, stoic morning insight.';
    } else if (persona == 'Kore') {
      personaInstruction =
          'Tone: Gentle meditative whisper, serene, mindful breathing reminder.';
    }

    final prompt = '''
You are an AI wake-up companion inside an alarm app called cAlrmy.
User name: $userName
Alarm label: $alarmLabel
Goal: ${goal.isNotEmpty ? goal : 'make today legendary'}
Attempt #$attemptNumber.
$personaInstruction
${language.isNotEmpty ? 'Language: $language' : 'Language: English or warm Hinglish if appropriate.'}
Rules: 2 short spoken sentences. No emojis, no markdown, no quotes. Speak straight to the listener.
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 120,
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
      debugPrint('Gemini generateWakeUpMessage: $e');
    }

    if (attemptNumber <= 1) {
      return 'Good morning $userName. A beautiful new dawn is waiting for you to begin.';
    } else {
      return '$userName, get out of bed! Your future self is counting on you right now.';
    }
  }

  Future<String> generateWakeUpRoast({
    required String userName,
    required int attemptNumber,
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
You are a savage, hilarious AI alarm roaster in cAlrmy.
Roast $userName playfully for still sleeping in while the whole world is conquering the day.
Make it witty, funny, and stinging enough to make them jump out of bed laughing.
Strict requirement: Max 2 punchy sentences. No markdown, no asterisks, spoken aloud.
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 100,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts
              .where((p) => p['thought'] != true && p['text'] != null)
              .map((p) => p['text'].toString())
              .join(' ')
              .trim();
          if (text.isNotEmpty) return text;
        }
      }
    } catch (_) {}

    return '$userName, are you sleeping into retirement already? Even your alarm clock is tired of waiting for you!';
  }

  Future<RiddleMission> generateMissionRiddle() async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
Generate a single clever, fun morning riddle with 4 multiple choice options.
Output ONLY valid raw JSON without any markdown formatting or backticks:
{
  "question": "What has hands but cannot clap?",
  "options": ["A river", "A clock", "A shadow", "A mirror"],
  "correctIndex": 1
}
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          String raw = parts
              .where((p) => p['thought'] != true && p['text'] != null)
              .map((p) => p['text'].toString())
              .join(' ')
              .trim();
          raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(raw);
          return RiddleMission(
            question: parsed['question'] ?? 'What gets wetter as it dries?',
            options: (parsed['options'] as List)
                .map((e) => e.toString())
                .toList(),
            correctIndex: parsed['correctIndex'] ?? 0,
          );
        }
      }
    } catch (_) {}

    return RiddleMission(
      question: 'What has to be broken before you can use it?',
      options: ['An egg', 'A promise', 'A glass', 'A lock'],
      correctIndex: 0,
    );
  }

  Future<String> interpretDream({
    required String dreamDescription,
    required String userName,
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
You are an insightful, mystical, and psychologically witty dream interpreter in the cAlrmy app.
User $userName describes their dream: "$dreamDescription"

Analyze the dream with:
1. 🌌 The Core Symbolism: What the subconscious is really processing.
2. 🔮 Hidden Meaning: A fun, entertaining insight about their inner desires or ambitions.
3. ✨ Morning Wisdom: One inspiring takeaway for their day today.

Keep it engaging, entertaining, and articulate (under 180 words).
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.85,
            'maxOutputTokens': 350,
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
              .join('\n')
              .trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    } catch (e) {
      debugPrint('Dream interpret error: $e');
    }

    return 'Your dream reflects an extraordinary reservoir of creativity seeking expression today. Trust your intuition and take on the day with confidence!';
  }

  Future<String> generateBedtimeStory({
    required String genre,
    required String userName,
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
Write a relaxing, deeply ambient, sleep-inducing bedtime story for $userName.
Genre/Setting: $genre (e.g. Cozy Rain Cabin, Bioluminescent Forest, Starlit Celestial Voyage).
Tone: Whispering, gentle, poetic, hypnotic, slowly calming the mind into sweet slumber.
Length: Approx 150-200 soothing words.
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.75,
            'maxOutputTokens': 350,
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
              .join('\n')
              .trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    } catch (_) {}

    return 'Beyond the velvet horizon, soft raindrops tap lightly against the wooden eaves. The scent of pine and cedar drifts in the cool evening breeze. Breathe in slowly. Close your eyes, let go of every thought, and float into peaceful dreams.';
  }

  Future<String> generateMorningBriefing({
    required String userName,
    required String goal,
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    final prompt = '''
Create a punchy, ultra-motivating 3-part Morning Briefing for $userName.
Main goal: ${goal.isNotEmpty ? goal : 'dominate today'}
Format:
1. ☀️ Daily Spark: A one-sentence motivational truth.
2. 🎯 Focus Mission: One clear action for their goal.
3. ⚡ Power Mindset: A short stoic mantra.
Keep it aesthetic, high-energy, and under 120 words.
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
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 250,
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
              .join('\n')
              .trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    } catch (_) {}

    return '☀️ Daily Spark: Every sunrise brings an opportunity to rewrite your story.\n🎯 Focus Mission: Take the hardest task on your list and crush it before noon.\n⚡ Power Mindset: Discipline is choosing what you want most over what you want now.';
  }

  Future<String> chatResponse({
    required List<ChatMessage> history,
    required String userName,
    required String goal,
    String language = '',
    String persona = 'Aoede',
  }) async {
    final apiKey = await getApiKey();
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'gemini-3.5-flash-lite';

    String toneDescription = 'Warm, empathetic, caring friend.';
    if (persona == 'Fenrir') {
      toneDescription =
          'Savage, hilarious, tough-love coach who roasts you and pushes you to greatness.';
    } else if (persona == 'Puck') {
      toneDescription = 'High-energy, playful hype-man full of witty enthusiasm.';
    } else if (persona == 'Charon') {
      toneDescription = 'Deep, cosmic philosopher who speaks with stoic serenity.';
    } else if (persona == 'Kore') {
      toneDescription = 'Gentle, meditative mindfulness guide.';
    }

    final systemPrompt = '''
You are a voice companion in the cAlrmy alarm app for $userName.
Persona style: $toneDescription
${goal.isNotEmpty ? 'User Main goal: $goal.' : ''}
${language.isNotEmpty ? 'Reply in: $language.' : 'Reply in the language the user speaks (English, Hindi, Hinglish, etc.).'}
Rules: Keep replies to 1-3 concise, punchy sentences meant to be spoken aloud. No emojis, no markdown asterisks.
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
            'maxOutputTokens': 200,
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

    return 'I hear you $userName! What are we conquering next today?';
  }

  Future<bool> speakRealisticVoice(
    String text, {
    String voiceName = 'Aoede',
    VoidCallback? onDone,
  }) async {
    final apiKey = await getApiKey();
    final ttsModel =
        dotenv.env['DEFAULT_TTS_MODEL'] ?? 'gemini-3.8-flash-lite-tts';

    try {
      await stopSpeaking();
      _isSpeaking = true;

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$ttsModel:generateContent?key=$apiKey');

      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

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
      } else {
        debugPrint(
            'TTS status error: ${response.statusCode} => ${response.body}');
      }
    } catch (e) {
      debugPrint('Realistic TTS exception: $e');
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
