// lib/screens/agent_guide_screen.dart
// "Agent Guide" screen — Amy, the conversational guide of the app.
// Introduces the app, answers questions, supports the user.
// Reached through the permanent floating button (AgentGuideFab).
// Palette: night-blue background 0xFF0A1628, green accent 0xFF2E8B7B
// (same colours as the home carousel of the app).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/agent_guide_knowledge.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../widgets/nav_cartouche.dart';

class AgentGuideScreen extends StatefulWidget {
  const AgentGuideScreen({super.key});

  @override
  State<AgentGuideScreen> createState() => _AgentGuideScreenState();
}

class _AgentGuideMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  _AgentGuideMessage(this.role, this.content);
}

class _AgentGuideScreenState extends State<AgentGuideScreen> {
  static const _avatarAsset = 'assets/univers_visuel/agent_guide.png';
  static const _maxHistoryForApi = 20;

  // Palette taken from home_carousel_screen.dart
  static const Color _bgNight = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF152840);
  static const Color _accentGreen = Color(0xFF2E8B7B);

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AgentGuideMessage> _messages = [];

  bool _isSending = false;
  int? _speakingIndex;

  static const List<String> _suggestions = [
    'The principle of the app',
    'How does it work',
    'What are the sources?',
    'How to find a thought?',
    'What is the quiz for?',
    'And the wheel of chance?',
    'Why fill in my profile?',
    'Privacy of my exchanges',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_AgentGuideMessage(
      'assistant',
      'Hi, I\'m Amy, your guide. I\'m here to explain the application '
          'and help you if you get stuck. Ask me anything, or pick a '
          'suggestion below.',
    ));
    TtsService.instance.init();
    TtsService.instance.onStateChanged = (key, isSpeaking) {
      if (!mounted) return;
      if (!isSpeaking) {
        setState(() => _speakingIndex = null);
      }
    };
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_AgentGuideMessage('user', trimmed));
      _isSending = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    final trimmedHistory = history.length > _maxHistoryForApi
        ? history.sublist(history.length - _maxHistoryForApi)
        : history;

    try {
      final reply = await AIService.instance.generateAgentReply(
        messages: trimmedHistory,
        systemPrompt: AgentGuideKnowledge.systemPrompt,
      );

      if (!mounted) return;

      final isError = reply.startsWith('[ERREUR_API]');
      final displayReply =
          isError ? reply.replaceFirst('[ERREUR_API] ', '') : reply;

      setState(() {
        _messages.add(_AgentGuideMessage('assistant', displayReply));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_AgentGuideMessage(
          'assistant',
          'I could not answer. Please try again in a moment.',
        ));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleSpeak(int index, String text) async {
    if (_speakingIndex == index) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingIndex = null);
      return;
    }
    await TtsService.instance.stop();
    if (mounted) setState(() => _speakingIndex = index);
    await TtsService.instance.speak(text, approachKey: 'agent_guide_$index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgNight,
      appBar: AppBar(
        backgroundColor: _bgNight,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Amy — your guide',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeroAvatar()),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (_isSending && index == _messages.length) {
                            return _buildTypingIndicator();
                          }
                          final msg = _messages[index];
                          final isUser = msg.role == 'user';
                          return _buildBubble(msg, isUser, index);
                        },
                        childCount: _messages.length + (_isSending ? 1 : 0),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildSuggestions()),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
            _buildInputBar(),
            _buildBottomRetour(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accentGreen.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              _avatarAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _surface,
                child: const Icon(Icons.person,
                    size: 48, color: _accentGreen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_AgentGuideMessage msg, bool isUser, int index) {
    final bgColor = isUser ? _accentGreen : _surface;
    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: _surface,
                backgroundImage: const AssetImage(_avatarAsset),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: SelectableText(
                    msg.content,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.45,
                      color: textColor,
                    ),
                  ),
                ),
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: InkWell(
                      onTap: () => _toggleSpeak(index, msg.content),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _speakingIndex == index
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                              size: 16,
                              color: _accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _speakingIndex == index ? 'Stop' : 'Listen',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _surface,
              backgroundImage: const AssetImage(_avatarAsset),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 22,
              height: 14,
              child: _TypingDots(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _suggestions.map((s) {
          return InkWell(
            onTap: _isSending ? null : () => _send(s),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _accentGreen,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _accentGreen.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                s,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: _bgNight,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              enabled: !_isSending,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask your question…',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: _surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: _accentGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _isSending ? _surface : _accentGreen,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isSending ? null : () => _send(_inputController.text),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRetour() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      color: _bgNight,
      child: SafeArea(
        top: false,
        child: Center(
          child: NavCartoucheRetour(
            onTap: () => Navigator.of(context).pop(),
            label: 'Back',
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_ctrl.value + i * 0.2) % 1.0;
            final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
