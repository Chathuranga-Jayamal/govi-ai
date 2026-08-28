import 'package:flutter/material.dart';

import '../../features/advisory/domain/advisory_topic.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatSession {
  const ChatSession({
    required this.topic,
    required this.messages,
    required this.timestamp,
  });

  final String? topic;
  final List<ChatMessage> messages;
  final DateTime timestamp;

  String get previewLabel => topic ?? 'General chat';

  String get firstLine => messages.isEmpty ? '' : messages.first.text;
}

/// Owns the Advisory tab's live conversation plus its in-memory history.
///
/// Lives above the bottom-nav `IndexedStack` (see [AdvisoryChatScope] in
/// core/widgets/main_shell.dart) because IndexedStack never rebuilds or
/// disposes an inactive branch page on tab switch — AdvisoryChatScreen's
/// own State has no lifecycle hook for "the user just switched tabs", so
/// the source of truth for "should this be a fresh conversation" has to
/// live somewhere both the bottom nav and the screen itself can reach.
///
/// Message content itself (seeding the first reply, handling follow-ups)
/// is fetched from the real /advisory endpoint by AdvisoryChatScreen — this
/// controller only holds the resulting messages/topic, since that fetch is
/// asynchronous and needs a visible loading state the screen owns.
class AdvisoryChatController extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  AdvisoryTopic? _topic;
  final List<ChatSession> _history = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AdvisoryTopic? get topic => _topic;
  String? get currentTopic => _topic?.label;
  List<ChatSession> get history => List.unmodifiable(_history);

  void startConversation({AdvisoryTopic? topic}) {
    _archiveIfNeeded();
    _messages = [];
    _topic = topic;
    notifyListeners();
  }

  void addUserMessage(String text) {
    _messages = [..._messages, ChatMessage(text: text, isUser: true)];
    notifyListeners();
  }

  void addBotMessage(String text) {
    _messages = [..._messages, ChatMessage(text: text, isUser: false)];
    notifyListeners();
  }

  void _archiveIfNeeded() {
    final bool hasExchange = _messages.any((message) => message.isUser);
    if (!hasExchange) return;

    _history.insert(
      0,
      ChatSession(
        topic: _topic?.label,
        messages: _messages,
        timestamp: DateTime.now(),
      ),
    );
  }
}

class AdvisoryChatScope extends InheritedNotifier<AdvisoryChatController> {
  const AdvisoryChatScope({
    required AdvisoryChatController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AdvisoryChatController of(BuildContext context) {
    final AdvisoryChatScope? scope = context
        .dependOnInheritedWidgetOfExactType<AdvisoryChatScope>();
    assert(scope != null, 'AdvisoryChatScope not found in context');
    return scope!.notifier!;
  }
}
