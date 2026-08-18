import 'package:flutter/material.dart';

import '../../../../core/state/advisory_chat_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_history_sheet.dart';
import 'chat_history_detail_screen.dart';

const String _genericBotReply =
    "That's a good question. Based on similar cases, I'd recommend "
    'consulting your local Agrarian Services Center and following the '
    'recommended dosage guidelines for your crop. (Full AI-powered '
    'answers are coming soon.)';

class AdvisoryChatScreen extends StatefulWidget {
  const AdvisoryChatScreen({this.initialTopic, super.key});

  final String? initialTopic;

  @override
  State<AdvisoryChatScreen> createState() => _AdvisoryChatScreenState();
}

class _AdvisoryChatScreenState extends State<AdvisoryChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedLanguage = 'En';
  static const List<String> _languageOptions = ['සිං', 'தமி', 'En'];

  AdvisoryChatController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final String? topic = widget.initialTopic;
    final AdvisoryChatController? controller = _controller;
    if (controller == null) return;
    if (topic != null && topic != controller.currentTopic) {
      controller.startConversation(topic: topic);
    }
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
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

  Future<void> _sendMessage(String text) async {
    final String trimmed = text.trim();
    final AdvisoryChatController? controller = _controller;
    if (trimmed.isEmpty || controller == null) return;

    controller.addUserMessage(trimmed);
    _textController.clear();
    _scrollToBottom();

    // Mock response — real RAG/LLM wiring comes in a later phase.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    controller.addBotMessage(_genericBotReply);
    _scrollToBottom();
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
              child: messages.isEmpty
                  ? _WelcomeState(onSuggestionTap: _sendMessage)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          ChatBubble(message: messages[index]),
                    ),
            ),
            _ChatInputBar(
              controller: _textController,
              onSend: () => _sendMessage(_textController.text),
              onAttachmentTap: _showAttachmentComingSoon,
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

  final ValueChanged<String> onSuggestionTap;

  static const List<String> _suggestions = [
    'Best fertilizer for rice?',
    'How to treat leaf blight?',
    'When to harvest tea?',
  ];

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
              'Ask me anything about crop diseases, treatments, or '
              'farming advice',
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
              children: _suggestions.map((question) {
                return OutlinedButton(
                  onPressed: () => onSuggestionTap(question),
                  child: Text(question),
                );
              }).toList(),
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
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;

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
            onPressed: onAttachmentTap,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask about crop diseases, treatments...',
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            onPressed: onSend,
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
