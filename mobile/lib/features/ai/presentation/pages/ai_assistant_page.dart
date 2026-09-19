import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/models/ai_citation.dart';
import '../widgets/ai_sources_section.dart';

class _ChatBubble {
  final bool isUser;
  final String text;
  final String? grounding;
  final List<AiCitation> citations;

  const _ChatBubble({
    required this.isUser,
    required this.text,
    this.grounding,
    this.citations = const [],
  });
}

class AiAssistantPage extends StatefulWidget {
  final AiRemoteDataSource? aiRemoteDataSource;
  final String? initialQuestionId;

  const AiAssistantPage({
    super.key,
    this.aiRemoteDataSource,
    this.initialQuestionId,
  });

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  late final AiRemoteDataSource _ai;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];

  String? _conversationId;
  bool _loading = false;
  String? _error;
  String? _errorCode;

  static const _suggestions = [
    'Which subjects are available for Year 1?',
    'Explain nephrotic syndrome',
    'How do I use MedStudy exams?',
    'What can I access with my subscription?',
  ];

  @override
  void initState() {
    super.initState();
    _ai = widget.aiRemoteDataSource ?? AiRemoteDataSource();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    if (_loading) return;
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatBubble(isUser: true, text: text));
      _controller.clear();
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    _scrollToEnd();

    try {
      final result = await _ai.chat(
        message: text,
        conversationId: _conversationId,
        questionId: widget.initialQuestionId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId;
        _messages.add(
          _ChatBubble(
            isUser: false,
            text: result.reply,
            grounding: result.grounding,
            citations: result.citations,
          ),
        );
        _loading = false;
      });
      _scrollToEnd();
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorCode = e.code;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorCode = 'NETWORK';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to send message.';
        _errorCode = 'UNKNOWN';
        _loading = false;
      });
    }
  }

  Future<void> _newConversation() async {
    final oldId = _conversationId;
    setState(() {
      _messages.clear();
      _conversationId = null;
      _error = null;
      _errorCode = null;
      _loading = false;
    });
    if (oldId != null) {
      try {
        await _ai.deleteConversation(oldId);
      } catch (_) {
        // Best-effort clear
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool get _canRetry =>
      _error != null &&
      _errorCode != 'AI_DISABLED' &&
      _errorCode != 'AI_QUOTA_EXCEEDED';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('MedStudy AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('ai_assistant_new'),
            tooltip: 'New conversation',
            onPressed: _loading ? null : _newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                children: [
                  if (widget.initialQuestionId != null &&
                      widget.initialQuestionId!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.secondaryColor,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This chat is linked to the question you were reviewing. Ask anything about that MCQ.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _IntroCard(onSuggestion: _loading ? null : _send),
                  const SizedBox(height: AppTheme.spacingMd),
                  ..._messages.map(
                    (m) => _Bubble(
                      isUser: m.isUser,
                      text: m.text,
                      grounding: m.grounding,
                      citations: m.citations,
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      child: LinearProgressIndicator(
                        key: Key('ai_assistant_loading'),
                      ),
                    ),
                  if (_error != null)
                    Container(
                      key: const Key('ai_assistant_error'),
                      margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.warningSoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (_canRetry)
                            TextButton(
                              key: const Key('ai_assistant_retry'),
                              onPressed: () {
                                final lastUser = _messages.lastWhere(
                                  (m) => m.isUser,
                                  orElse: () =>
                                      const _ChatBubble(isUser: true, text: ''),
                                );
                                if (lastUser.text.isNotEmpty) {
                                  // Remove failed trailing user bubble duplicate on retry
                                  setState(() {
                                    if (_messages.isNotEmpty &&
                                        _messages.last.isUser) {
                                      _messages.removeLast();
                                    }
                                  });
                                  _send(lastUser.text);
                                }
                              },
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ai_assistant_input'),
                      controller: _controller,
                      enabled: !_loading,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ask MedStudy AI…',
                        filled: true,
                        fillColor: AppTheme.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      key: const Key('ai_assistant_send'),
                      onPressed: _loading ? null : () => _send(),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final void Function(String)? onSuggestion;

  const _IntroCard({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.secondarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.secondaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Educational AI Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask about MedStudy subjects, materials, exams, or medical concepts from content you can access. Not a substitute for a clinician.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _AiAssistantPageState._suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    onPressed:
                        onSuggestion == null ? null : () => onSuggestion!(s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final String? grounding;
  final List<AiCitation> citations;

  const _Bubble({
    required this.isUser,
    required this.text,
    this.grounding,
    this.citations = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? AppTheme.primaryColor : Colors.white;
    final fg = isUser ? Colors.white : AppTheme.textPrimaryColor;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: isUser
            ? const Key('ai_assistant_user_bubble')
            : const Key('ai_assistant_bot_bubble'),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: bg,
          gradient: isUser ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: isUser ? null : Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: (isUser ? AppTheme.primaryColor : Colors.black)
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MedStudy AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              style: TextStyle(color: fg, fontSize: 14, height: 1.45),
            ),
            if (!isUser && citations.isNotEmpty) ...[
              const SizedBox(height: 8),
              AiSourcesSection(
                citations: citations,
                grounding: grounding,
                compact: true,
              ),
            ] else if (!isUser && grounding != null) ...[
              const SizedBox(height: 6),
              Text(
                'Grounding: $grounding',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
