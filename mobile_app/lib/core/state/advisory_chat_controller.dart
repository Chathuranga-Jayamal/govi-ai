import 'package:flutter/material.dart';

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
class AdvisoryChatController extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  String? _currentTopic;
  final List<ChatSession> _history = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get currentTopic => _currentTopic;
  List<ChatSession> get history => List.unmodifiable(_history);

  void startConversation({String? topic}) {
    _archiveIfNeeded();
    _messages = topic == null ? [] : [_diagnosisSeedMessage(topic)];
    _currentTopic = topic;
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
        topic: _currentTopic,
        messages: _messages,
        timestamp: DateTime.now(),
      ),
    );
  }

  static ChatMessage _diagnosisSeedMessage(String topic) {
    return ChatMessage(
      text:
          "I see you've diagnosed $topic. Here's what I recommend: "
          'treat the affected plants promptly with an approved '
          "fungicide, remove and destroy heavily infected leaves so "
          "the disease doesn't spread, and avoid overhead irrigation "
          'in the evening since damp foliage overnight makes it '
          'worse. Keep an eye on nearby plants over the next few '
          'days for early signs.',
      isUser: false,
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
