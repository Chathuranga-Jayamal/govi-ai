import 'package:flutter/material.dart';

import '../../../../core/state/advisory_chat_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/chat_bubble.dart';

/// Read-only view of a past conversation. Deliberately not wired into
/// go_router — this is a transient detail view reached only from the
/// history sheet, not something that needs a deep-linkable route.
class ChatHistoryDetailScreen extends StatelessWidget {
  const ChatHistoryDetailScreen({required this.session, super.key});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(session.previewLabel)),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: session.messages.length,
        itemBuilder: (context, index) =>
            ChatBubble(message: session.messages[index]),
      ),
    );
  }
}
