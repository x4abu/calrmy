import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/orb_widget.dart';

class TalkScreen extends StatefulWidget {
  final bool isDark;

  const TalkScreen({
    super.key,
    required this.isDark,
  });

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  final GeminiService _geminiService = GeminiService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLive = false;
  bool _isSpeaking = false;
  String _statusText = 'Tap to start talking';
  String _userName = 'Abu Saalim';
  String _userGoal = '';
  String _voiceName = 'Aoede';

  @override
  void initState() {
    super.initState();
    _loadUserConfig();
    _messages.add(
      ChatMessage(
        text:
            "Hi Abu Saalim! I'm your AI companion. Tap the glowing orb or type a message to talk with me.",
        isUser: false,
      ),
    );
  }

  Future<void> _loadUserConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Abu Saalim';
    _userGoal = prefs.getString('user_goal') ?? '';
    _voiceName = prefs.getString('tts_voice') ?? 'Aoede';
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _geminiService.stopSpeaking();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _statusText = 'Thinking…';
    });
    _scrollToBottom();

    final response = await _geminiService.chatResponse(
      history: _messages,
      userName: _userName,
      goal: _userGoal,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _statusText = 'Speaking…';
      _isSpeaking = true;
    });
    _scrollToBottom();

    await _geminiService.speakRealisticVoice(
      response,
      voiceName: _voiceName,
      onDone: () {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _statusText = _isLive ? 'Listening…' : 'Tap to start talking';
          });
        }
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Column(
      children: [
        // Top Header
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Live with your AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: mute,
              ),
            ),
          ),
        ),

        // Glowing Orb + Status
        Column(
          children: [
            OrbWidget(
              size: 130,
              isLive: _isLive,
              isSpeaking: _isSpeaking,
              onTap: () {
                setState(() {
                  _isLive = !_isLive;
                  _statusText =
                      _isLive ? 'Listening…' : 'Tap to start talking';
                });
                if (_isLive) {
                  _sendMessage('Hello, I am awake!');
                } else {
                  _geminiService.stopSpeaking();
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: mute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chat Message History
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, idx) {
              final msg = _messages[idx];
              final isMe = msg.isUser;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? acc
                        : (widget.isDark
                            ? AppColors.darkGlass
                            : AppColors.lightGlass),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: Border.all(
                      color: isMe
                          ? Colors.transparent
                          : (widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                      color: isMe ? AppColors.darkAccentInk : ink,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick Suggestion Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () =>
                    _sendMessage('Good night, ab main sone ja raha hoon.'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  side: BorderSide(
                    color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.4),
                  ),
                ),
                child: Text('Good night', style: TextStyle(color: ink)),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _sendMessage('Good morning!'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  side: BorderSide(
                    color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.4),
                  ),
                ),
                child: Text('Good morning', style: TextStyle(color: ink)),
              ),
            ],
          ),
        ),

        // Input Field & Send Pill Button
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 110,
            top: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: ink, fontSize: 15),
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(color: mute.withOpacity(0.6)),
                    filled: true,
                    fillColor: widget.isDark
                        ? AppColors.darkGlass
                        : AppColors.lightGlass,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide(
                        color: widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide(
                        color: widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _sendMessage(_textController.text),
                style: FilledButton.styleFrom(
                  backgroundColor: acc,
                  foregroundColor: widget.isDark
                      ? AppColors.darkAccentInk
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
