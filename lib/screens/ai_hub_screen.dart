import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/orb_widget.dart';

class AiHubScreen extends StatefulWidget {
  final bool isDark;

  const AiHubScreen({super.key, required this.isDark});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  int _activeSubTab = 0; // 0 = Talk, 1 = Dream Journal, 2 = Sleep Stories, 3 = Briefing

  // Talk Companion state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _userName = 'Abu Saalim';
  String _userGoal = '';
  String _selectedVoice = 'Aoede';
  String _selectedPersona = 'Aoede';

  // Dream Journal state
  final TextEditingController _dreamController = TextEditingController();
  String _dreamInterpretation = '';
  bool _isInterpreting = false;

  // Bedtime Story state
  String _selectedStoryTheme = 'Rain Cabin';
  String _bedtimeStory = '';
  bool _isGeneratingStory = false;

  // Morning Briefing state
  String _morningBriefing = '';
  bool _isGeneratingBriefing = false;

  final GeminiService _gemini = GeminiService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Abu Saalim';
      _userGoal = prefs.getString('user_goal') ?? '';
      _selectedVoice = prefs.getString('tts_voice') ?? 'Aoede';
      _selectedPersona = prefs.getString('ai_persona') ?? 'Aoede';

      if (_messages.isEmpty) {
        _messages.add(
          ChatMessage(
            text:
                'Hello $_userName! I am your AI companion in cAlrmy. How are you feeling today?',
            isUser: false,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _dreamController.dispose();
    _gemini.stopSpeaking();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Send Message ---
  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _chatController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (presetText == null) _chatController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await _gemini.chatResponse(
      history: _messages,
      userName: _userName,
      goal: _userGoal,
      persona: _selectedPersona,
    );

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();

      // Automatically speak reply with realistic Google Studio voice
      await _gemini.speakRealisticVoice(reply, voiceName: _selectedVoice);
      if (mounted) setState(() {});
    }
  }

  // --- Dream Journal ---
  Future<void> _interpretDream() async {
    final dream = _dreamController.text.trim();
    if (dream.isEmpty || _isInterpreting) return;

    setState(() {
      _isInterpreting = true;
      _dreamInterpretation = '';
    });

    final result = await _gemini.interpretDream(
      dreamDescription: dream,
      userName: _userName,
    );

    if (mounted) {
      setState(() {
        _dreamInterpretation = result;
        _isInterpreting = false;
      });
    }
  }

  // --- Bedtime Story ---
  Future<void> _generateStory() async {
    if (_isGeneratingStory) return;

    setState(() {
      _isGeneratingStory = true;
      _bedtimeStory = '';
    });

    final story = await _gemini.generateBedtimeStory(
      genre: _selectedStoryTheme,
      userName: _userName,
    );

    if (mounted) {
      setState(() {
        _bedtimeStory = story;
        _isGeneratingStory = false;
      });

      // Speak bedtime story aloud with soothing voice
      await _gemini.speakRealisticVoice(story, voiceName: 'Kore');
      if (mounted) setState(() {});
    }
  }

  // --- Morning Briefing ---
  Future<void> _generateBriefing() async {
    if (_isGeneratingBriefing) return;

    setState(() {
      _isGeneratingBriefing = true;
      _morningBriefing = '';
    });

    final briefing = await _gemini.generateMorningBriefing(
      userName: _userName,
      goal: _userGoal,
    );

    if (mounted) {
      setState(() {
        _morningBriefing = briefing;
        _isGeneratingBriefing = false;
      });

      await _gemini.speakRealisticVoice(briefing, voiceName: _selectedVoice);
      if (mounted) setState(() {});
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
            'Google AI Studio Suite',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mute,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'AI Companion Hub',
            style: GoogleFonts.instrumentSerif(
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),

          // Sub-Tab Switcher
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabItem('🎙️ Voice Chat', 0, acc, ink, mute),
                const SizedBox(width: 8),
                _buildSubTabItem('🌙 Dream Journal', 1, acc, ink, mute),
                const SizedBox(width: 8),
                _buildSubTabItem('📖 Bedtime Story', 2, acc, ink, mute),
                const SizedBox(width: 8),
                _buildSubTabItem('☀️ Daily Briefing', 3, acc, ink, mute),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // View Switcher
          if (_activeSubTab == 0)
            _buildVoiceChatView(ink, mute, acc)
          else if (_activeSubTab == 1)
            _buildDreamJournalView(ink, mute, acc)
          else if (_activeSubTab == 2)
            _buildBedtimeStoryView(ink, mute, acc)
          else
            _buildBriefingView(ink, mute, acc),
        ],
      ),
    );
  }

  Widget _buildSubTabItem(
      String label, int index, Color acc, Color ink, Color mute) {
    final isSelected = _activeSubTab == index;

    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? acc.withOpacity(0.18)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? acc
                : (widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? acc : ink,
          ),
        ),
      ),
    );
  }

  // --- TAB 1: LIVE VOICE COMPANION VIEW ---
  Widget _buildVoiceChatView(Color ink, Color mute, Color acc) {
    return Column(
      children: [
        // 3D Glowing Orb & Persona Selector
        GlassBox(
          isDark: widget.isDark,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Center(
                child: OrbWidget(
                  isListening: _isLoading,
                  isSpeaking: _gemini.isSpeaking,
                  size: 150,
                  onTap: () {
                    if (_gemini.isSpeaking) {
                      _gemini.stopSpeaking();
                      setState(() {});
                    } else {
                      _sendMessage('Good morning! Give me today’s quick spark.');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _gemini.isSpeaking
                    ? 'Speaking Realistic Voice… (Tap orb to stop)'
                    : _isLoading
                        ? 'Thinking…'
                        : 'Tap glowing orb to converse with AI',
                style: TextStyle(fontSize: 12.5, color: mute),
              ),
              const SizedBox(height: 12),

              // Persona Pills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildPersonaChip('Aoede', '🌸 Warm', acc, ink, mute),
                  _buildPersonaChip('Puck', '⚡ Hype', acc, ink, mute),
                  _buildPersonaChip('Fenrir', '🔥 Savage', acc, ink, mute),
                  _buildPersonaChip('Charon', '🌌 Stoic', acc, ink, mute),
                  _buildPersonaChip('Kore', '🧘 Zen', acc, ink, mute),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Chat Message Log
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final msg = _messages[index];
            return Align(
              alignment:
                  msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? acc
                      : (widget.isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: msg.isUser
                        ? Colors.transparent
                        : (widget.isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: msg.isUser ? Colors.black : ink,
                        height: 1.35,
                      ),
                    ),
                    if (!msg.isUser) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          _gemini.speakRealisticVoice(msg.text,
                              voiceName: _selectedVoice);
                          setState(() {});
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up, size: 14, color: acc),
                            const SizedBox(width: 4),
                            Text(
                              'Replay Voice',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: acc,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Text Input Row
        Row(
          children: [
            Expanded(
              child: GlassBox(
                isDark: widget.isDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _chatController,
                  style: TextStyle(color: ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Talk to your AI companion…',
                    hintStyle: TextStyle(color: mute.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _sendMessage(),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
                backgroundColor: acc,
                foregroundColor: Colors.black,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : const Icon(Icons.arrow_upward, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonaChip(
      String personaKey, String label, Color acc, Color ink, Color mute) {
    final isSelected = _selectedPersona == personaKey;

    return InkWell(
      onTap: () async {
        setState(() => _selectedPersona = personaKey);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_persona', personaKey);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? acc.withOpacity(0.25)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? acc : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? acc : mute,
          ),
        ),
      ),
    );
  }

  // --- TAB 2: DREAM JOURNAL VIEW ---
  Widget _buildDreamJournalView(Color ink, Color mute, Color acc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassBox(
          isDark: widget.isDark,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: acc, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dream Psychology & Meaning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Type whatever fragments you remember from last night. Gemini will uncover subconscious metaphors and morning inspiration.',
                style: TextStyle(fontSize: 13, color: mute, height: 1.3),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dreamController,
                maxLines: 4,
                style: TextStyle(color: ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'e.g. I was flying over a violet neon city, looking for a lost golden compass in the clouds…',
                  hintStyle: TextStyle(color: mute.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isInterpreting ? null : _interpretDream,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: acc,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isInterpreting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Icon(Icons.psychology_outlined),
                  label: Text(
                    _isInterpreting
                        ? 'Decoding Subconscious…'
                        : 'Interpret My Dream',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_dreamInterpretation.isNotEmpty) ...[
          const SizedBox(height: 20),
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI DREAM ANALYSIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: acc,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: acc, size: 20),
                      onPressed: () {
                        _gemini.speakRealisticVoice(_dreamInterpretation,
                            voiceName: 'Charon');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _dreamInterpretation,
                  style: TextStyle(
                    fontSize: 14,
                    color: ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 3: BEDTIME SLEEP STORIES VIEW ---
  Widget _buildBedtimeStoryView(Color ink, Color mute, Color acc) {
    const themes = [
      'Rain Cabin',
      'Ancient Redwood Forest',
      'Cosmic Nebula Voyage',
      'Warm Mountain Fireplace',
      'Kyoto Bamboo Grove',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassBox(
          isDark: widget.isDark,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bedtime, color: acc, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ambient Bedtime Sleep Story',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Let soothing storytelling lull you into calm, restorative sleep with gentle AI voice narration.',
                style: TextStyle(fontSize: 13, color: mute, height: 1.3),
              ),
              const SizedBox(height: 14),

              // Theme Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: themes.map((t) {
                  final isSelected = _selectedStoryTheme == t;
                  return InkWell(
                    onTap: () => setState(() => _selectedStoryTheme = t),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? acc.withOpacity(0.2)
                            : (widget.isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? acc : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? acc : ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingStory ? null : _generateStory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: acc,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isGeneratingStory
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Icon(Icons.nightlight_round),
                  label: Text(
                    _isGeneratingStory
                        ? 'Weaving Sleep Story…'
                        : 'Generate & Narrate Story',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_bedtimeStory.isNotEmpty) ...[
          const SizedBox(height: 20),
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SLEEP STORY: $_selectedStoryTheme',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: acc,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _gemini.isSpeaking ? Icons.stop : Icons.volume_up,
                        color: acc,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_gemini.isSpeaking) {
                          _gemini.stopSpeaking();
                          setState(() {});
                        } else {
                          _gemini.speakRealisticVoice(_bedtimeStory,
                              voiceName: 'Kore');
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _bedtimeStory,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: ink,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 4: MORNING BRIEFING VIEW ---
  Widget _buildBriefingView(Color ink, Color mute, Color acc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassBox(
          isDark: widget.isDark,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Morning Briefing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'A high-voltage morning spark tailored to your personal goals.',
                style: TextStyle(fontSize: 13, color: mute, height: 1.3),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingBriefing ? null : _generateBriefing,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: acc,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isGeneratingBriefing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Icon(Icons.flash_on),
                  label: Text(
                    _isGeneratingBriefing
                        ? 'Gathering Morning Spark…'
                        : 'Brief Me for Today',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_morningBriefing.isNotEmpty) ...[
          const SizedBox(height: 20),
          GlassBox(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TODAY’S BLUEPRINT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: acc,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: acc, size: 20),
                      onPressed: () {
                        _gemini.speakRealisticVoice(_morningBriefing,
                            voiceName: _selectedVoice);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _morningBriefing,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: ink,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
