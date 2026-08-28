import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/advisory_chat_controller.dart';
import '../../../../core/state/current_user_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/advisory_repository.dart';
import '../../domain/advisory_result.dart';
import '../../domain/advisory_topic.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_history_sheet.dart';
import 'chat_history_detail_screen.dart';

// A small set of crop+disease pairs confirmed to exist in the advisory
// knowledge base, so tapping one always retrieves real grounded content
// instead of hitting the "no information found" fallback. The KB only
// covers disease-treatment topics (no general fertilizer/harvest advice),
// which is why these read as disease names rather than open questions.
const List<AdvisoryTopic> _suggestedTopics = [
  AdvisoryTopic(crop: 'rice', disease: 'blast', label: 'Rice Blast'),
  AdvisoryTopic(
    crop: 'tomato',
    disease: 'late_blight',
    label: 'Tomato Late Blight',
  ),
  AdvisoryTopic(crop: 'tea', disease: 'gray_blight', label: 'Tea Gray Blight'),
];

// How many recent messages to send as conversation_history — the backend
// has no server-side storage, so the client is the source of truth for
// memory and re-sends a bounded recent slice on every turn.
const int _maxHistoryMessages = 8;

String _languageCodeFor(String uiLabel) {
  switch (uiLabel) {
    case 'සිං':
      return 'si';
    case 'தமி':
      return 'ta';
    default:
      return 'en';
  }
}

String _uiLabelForLanguageCode(String? code) {
  switch (code) {
    case 'si':
      return 'සිං';
    case 'ta':
      return 'தமி';
    default:
      return 'En';
  }
}

class AdvisoryChatScreen extends StatefulWidget {
  const AdvisoryChatScreen({this.initialTopic, super.key});

  final AdvisoryTopic? initialTopic;

  @override
  State<AdvisoryChatScreen> createState() => _AdvisoryChatScreenState();
}

class _AdvisoryChatScreenState extends State<AdvisoryChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AdvisoryRepository _advisoryRepository = AdvisoryRepository();

  String _selectedLanguage = 'En';
  bool _languageInitializedFromProfile = false;
  static const List<String> _languageOptions = ['සිං', 'தமி', 'En'];

  AdvisoryChatController? _controller;

  bool _isSending = false;
  bool _showSlowNotice = false;
  String? _sendError;
  Timer? _slowTimer;

  // Remembers the last attempted (message, history) pair so Retry can
  // re-issue exactly that request without duplicating the user's bubble.
  ({String message, List<ChatMessage> history})? _pendingRetry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_languageInitializedFromProfile) {
      final String? preferred = CurrentUserScope.of(
        context,
      ).user?.preferredLanguage;
      if (preferred != null) {
        _selectedLanguage = _uiLabelForLanguageCode(preferred);
      }
      _languageInitializedFromProfile = true;
    }

    final AdvisoryChatController controller = AdvisoryChatScope.of(context);
    if (_controller != controller) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller..addListener(_onControllerChanged);
      _maybeSeedForNewTopic();
    }
  }

  @override
  void didUpdateWidget(covariant AdvisoryChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeSeedForNewTopic();
  }

  /// Starts a new conversation only when a genuinely new, non-null topic
  /// has arrived (e.g. a fresh diagnosis from Capture/Result). A null
  /// topic or the same topic as what's already loaded leaves the
  /// conversation untouched.
  void _maybeSeedForNewTopic() {
    final AdvisoryTopic? topic = widget.initialTopic;
    final AdvisoryChatController? controller = _controller;
    if (controller == null) return;
    if (topic != null && topic != controller.topic) {
      controller.startConversation(topic: topic);
      _sendMessage(topic.label);
    }
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _slowTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  List<Map<String, String>> _historyPayload(List<ChatMessage> history) {
    final List<ChatMessage> recent = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;
    return recent
        .map((m) => {'role': m.isUser ? 'user' : 'bot', 'content': m.text})
        .toList();
  }

  Future<void> _sendMessage(String text) async {
    final String trimmed = text.trim();
    final AdvisoryChatController? controller = _controller;
    if (trimmed.isEmpty || controller == null) return;

    final List<ChatMessage> historyBeforeSend = controller.messages;
    controller.addUserMessage(trimmed);
    _textController.clear();
    _scrollToBottom();

    await _fetchReply(message: trimmed, history: historyBeforeSend);
  }

  Future<void> _fetchReply({
    required String message,
    required List<ChatMessage> history,
  }) async {
    final AdvisoryChatController? controller = _controller;
    if (controller == null) return;

    _pendingRetry = (message: message, history: history);
    setState(() {
      _isSending = true;
      _sendError = null;
      _showSlowNotice = false;
    });

    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted) return;
      setState(() => _showSlowNotice = true);
    });

    try {
      final AdvisoryResult result = await _advisoryRepository.postAdvisory(
        message: message,
        crop: controller.topic?.crop,
        disease: controller.topic?.disease,
        language: _languageCodeFor(_selectedLanguage),
        conversationHistory: _historyPayload(history),
      );
      if (!mounted) return;

      // The wait is over — stop the slow-notice timer before revealing the
      // reply bubble-by-bubble, so "Still thinking..." can't show up
      // alongside content that's already arrived.
      _slowTimer?.cancel();
      setState(() => _showSlowNotice = false);

      final List<String> parts = result.reply
          .split('\n\n')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      final List<String> bubbles = parts.isEmpty ? [result.reply] : parts;

      for (final part in bubbles) {
        if (!mounted) return;
        controller.addBotMessage(part);
        _scrollToBottom();
        if (part != bubbles.last) {
          await Future.delayed(const Duration(milliseconds: 900));
        }
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _sendError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sendError = 'Something went wrong. Please try again.');
    } finally {
      _slowTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSending = false;
          _showSlowNotice = false;
        });
      }
    }
  }

  void _retryLastFetch() {
    final pending = _pendingRetry;
    if (pending == null) return;
    _fetchReply(message: pending.message, history: pending.history);
  }

  void _onSuggestionTap(AdvisoryTopic topic) {
    final AdvisoryChatController? controller = _controller;
    if (controller == null) return;
    controller.startConversation(topic: topic);
    _sendMessage(topic.label);
  }

  void _showAttachmentComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo attachment coming soon')),
    );
  }

  void _showHistorySheet() {
    final List<ChatSession> history = _controller?.history ?? const [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ChatHistorySheet(
        sessions: history,
        onSessionTap: (session) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatHistoryDetailScreen(session: session),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatMessage> messages = _controller?.messages ?? const [];
    final bool showWelcome =
        messages.isEmpty && !_isSending && _sendError == null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              selectedLanguage: _selectedLanguage,
              languageOptions: _languageOptions,
              onLanguageSelected: (language) {
                setState(() => _selectedLanguage = language);
              },
              onHistoryTap: _showHistorySheet,
            ),
            const Divider(height: 1),
            Expanded(
              child: showWelcome
                  ? _WelcomeState(onSuggestionTap: _onSuggestionTap)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount:
                          messages.length +
                          (_isSending ? 1 : 0) +
                          (_sendError != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          return ChatBubble(message: messages[index]);
                        }
                        final int extraIndex = index - messages.length;
                        if (_isSending && extraIndex == 0) {
                          return _TypingIndicator(
                            showSlowNotice: _showSlowNotice,
                          );
                        }
                        return _ErrorRetryBubble(
                          message: _sendError!,
                          onRetry: _retryLastFetch,
                        );
                      },
                    ),
            ),
            _ChatInputBar(
              controller: _textController,
              onSend: () => _sendMessage(_textController.text),
              onAttachmentTap: _showAttachmentComingSoon,
              enabled: !_isSending,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.selectedLanguage,
    required this.languageOptions,
    required this.onLanguageSelected,
    required this.onHistoryTap,
  });

  final String selectedLanguage;
  final List<String> languageOptions;
  final ValueChanged<String> onLanguageSelected;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paddyGreenContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppColors.paddyGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Govi Advisor', style: theme.textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.history),
            color: AppColors.soilInkSoft,
            tooltip: 'Past conversations',
            onPressed: onHistoryTap,
          ),
          Row(
            children: languageOptions.map((language) {
              final bool selected = language == selectedLanguage;
              return Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onLanguageSelected(language),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.paddyGreen
                          : AppColors.paddyGreenContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      language,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? AppColors.riceHusk
                            : AppColors.paddyGreenOnContainer,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  const _WelcomeState({required this.onSuggestionTap});

  final ValueChanged<AdvisoryTopic> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.monsoonTealContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: AppColors.monsoonTealOnContainer,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Govi Advisor', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask me about a crop disease, or just say hello to get '
              'started',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.soilInkSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: _suggestedTopics.map((topic) {
                return OutlinedButton(
                  onPressed: () => onSuggestionTap(topic),
                  child: Text(topic.label),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.showSlowNotice});

  final bool showSlowNotice;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.monsoonTealContainer,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final double t = (_controller.value - i * 0.2) % 1.0;
                    final double opacity =
                        0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.monsoonTealOnContainer,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            if (widget.showSlowNotice) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Still thinking, this can take a minute…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.monsoonTealOnContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorRetryBubble extends StatelessWidget {
  const _ErrorRetryBubble({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.alertRedContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.alertRedOnContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onRetry, child: const Text('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            color: AppColors.soilInkSoft,
            onPressed: enabled ? onAttachmentTap : null,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask about crop diseases, treatments...',
              ),
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.paddyGreen,
              foregroundColor: AppColors.riceHusk,
            ),
          ),
        ],
      ),
    );
  }
}
