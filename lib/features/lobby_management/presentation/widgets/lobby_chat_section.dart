import 'package:flutter/material.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_chat_message.dart';

/// Chat section trong LobbyPage — list messages + input field.
class LobbyChatSection extends StatelessWidget {
  final TextEditingController controller;
  final List<LobbyChatMessage> messages;
  final String currentUserId;
  final VoidCallback onSend;

  const LobbyChatSection({
    super.key,
    required this.controller,
    required this.messages,
    required this.currentUserId,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(
                  AppIcons.chat,
                  size: AppIcons.sm,
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tin nhắn',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Chat card
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.radiusLgAll,
              border: Border.all(color: colors.outlineVariant),
              boxShadow: AppElevation.shadowSm,
            ),
            child: Column(
              children: [
                // Messages list
                SizedBox(
                  height: 240,
                  child: messages.isEmpty
                      ? ChatEmptyState(theme: theme, colors: colors)
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: messages.length,
                          itemBuilder: (context, index) => ChatBubble(
                            message: messages[index],
                            currentUserId: currentUserId,
                          ),
                        ),
                ),
                const Divider(height: 1),
                // Input row
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Nhắn tin...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.outline,
                            ),
                            prefixIcon: Icon(
                              AppIcons.chat,
                              size: AppIcons.md,
                              color: colors.outline,
                            ),
                            filled: true,
                            fillColor: colors.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.radiusMdAll,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.primary.withAlpha(204),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withAlpha(77),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: onSend,
                          icon: const Icon(
                            AppIcons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state cho chat section.
class ChatEmptyState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const ChatEmptyState({super.key, required this.theme, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.chat, size: 48, color: colors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa có tin nhắn',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mở lời chào để làm quen!',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

/// Một bubble chat message.
class ChatBubble extends StatelessWidget {
  final LobbyChatMessage message;
  final String currentUserId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: AppRadius.radiusFullAll,
            ),
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isSelf = message.senderId == currentUserId;
    final senderName = message.senderName;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isSelf
                ? colors.primaryContainer
                : colors.secondaryContainer,
            foregroundColor: isSelf
                ? colors.onPrimaryContainer
                : colors.onSecondaryContainer,
            child: Text(
              senderName.isEmpty
                  ? '?'
                  : senderName.characters.first.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelf
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.radiusXs - 2),
                      topRight: const Radius.circular(AppRadius.radiusMd),
                      bottomLeft: const Radius.circular(AppRadius.radiusMd),
                      bottomRight: const Radius.circular(AppRadius.radiusMd),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
