import 'package:flutter/material.dart';

import '../../../../core/state/advisory_chat_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ChatHistorySheet extends StatelessWidget {
  const ChatHistorySheet({
    required this.sessions,
    required this.onSessionTap,
    super.key,
  });

  final List<ChatSession> sessions;
  final ValueChanged<ChatSession> onSessionTap;

  static String _formatTimestamp(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Past Conversations', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No past conversations yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.soilInkSoft,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ChatSession session = sessions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.monsoonTealContainer,
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.monsoonTealOnContainer,
                          size: 18,
                        ),
                      ),
                      title: Text(session.previewLabel),
                      subtitle: Text(
                        '${_formatTimestamp(session.timestamp)} · '
                        '${session.firstLine}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSessionTap(session),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
