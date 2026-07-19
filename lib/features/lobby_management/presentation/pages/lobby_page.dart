import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../booking_payment/presentation/pages/booking_summary_page.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import '../widgets/lobby_player_card.dart';
import '../widgets/lobby_countdown_timer.dart';
import '../widgets/online_friends_list.dart';

class LobbyPage extends StatefulWidget {
  final String lobbyId;
  final LobbyCubit lobbyCubit;

  const LobbyPage({super.key, required this.lobbyId, required this.lobbyCubit});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    widget.lobbyCubit.joinLobby(widget.lobbyId, null);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _showInviteFriendsSheet(BuildContext context, LobbyEntity lobby) {
    widget.lobbyCubit.loadOnlineFriends();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: widget.lobbyCubit,
        child: BlocBuilder<LobbyCubit, LobbyState>(
          builder: (sheetCtx, state) {
            if (state is LobbyFriendsLoaded) {
              return _FriendsSheet(
                state: state,
                onInvite: (friend) =>
                    _completeFriendAction(friend, lobby, invite: true),
                onClose: () => Navigator.pop(sheetCtx),
                showDevBadge: false,
                sheetContext: sheetCtx,
              );
            }
            return const _SheetLoading(label: 'Đang tải danh sách bạn bè...');
          },
        ),
      ),
    );
  }

  void _showSimulateFriendsSheet(BuildContext context, LobbyEntity lobby) {
    widget.lobbyCubit.loadSimulateFriends();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: widget.lobbyCubit,
        child: BlocBuilder<LobbyCubit, LobbyState>(
          builder: (sheetCtx, state) {
            if (state is LobbySimulateFriendsLoaded) {
              return _FriendsSheet(
                state: state,
                onInvite: (friend) =>
                    _completeFriendAction(friend, lobby, simulate: true),
                onClose: () => Navigator.pop(sheetCtx),
                showDevBadge: true,
                sheetContext: sheetCtx,
              );
            }
            return const _SheetLoading(
              label: 'Đang tải danh sách bạn bè (giả lập)...',
            );
          },
        ),
      ),
    );
  }

  void _completeFriendAction(
    FriendEntity friend,
    LobbyEntity lobby, {
    bool invite = false,
    bool simulate = false,
  }) {
    if (invite) {
      widget.lobbyCubit.inviteFriend(widget.lobbyId, friend.id);
    }
    if (simulate) {
      widget.lobbyCubit.simulateAddFriend(widget.lobbyId, friend.id);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invite
              ? 'Đã gửi lời mời đến ${friend.name}'
              : '${friend.name} đã được thêm vào phòng!',
        ),
      ),
    );
  }

  void _shareInviteCode(BuildContext context, String? code) {
    if (code == null) return;

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã phòng $code đã được sao chép!'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDismissDialog(BuildContext context, LobbyDismissed state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          AppIcons.warning,
          size: AppIcons.massive,
          color: AppColors.warning,
        ),
        title: Text(state.title),
        content: Text(state.message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(dialogContext).popUntil((route) => route.isFirst);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.lobbyCubit,
      child: BlocConsumer<LobbyCubit, LobbyState>(
        listener: (context, state) {
          if (state is LobbyDismissed) {
            _showDismissDialog(context, state);
          }
          if (state is LobbyReady) {
            _openBookingSummary(context, state);
          }
          if (state is LobbyAutoBookingCreated) {
            _onAutoBookingCreated(context, state);
          }
        },
        buildWhen: (previous, current) =>
            current is! LobbyFriendsLoaded &&
            current is! LobbySimulateFriendsLoaded,
        builder: (context, state) {
          if (state is LobbyLoading) {
            return const _LobbyLoadingScaffold();
          }

          if (state is LobbyFailure) {
            return _LobbyFailureScaffold(
              message: state.message,
              onRetry: () => widget.lobbyCubit.joinLobby(widget.lobbyId, null),
            );
          }

          final lobby = state is LobbyCreated
              ? state.lobby
              : state is LobbyUpdatedRealtime
              ? state.lobby
              : state is LobbyReady
              ? state.lobby
              : state is LobbyAutoBookingCreated
              ? state.lobby
              : null;

          if (lobby == null) {
            return const _LobbyLoadingScaffold();
          }

          return _buildLobbyView(context, lobby);
        },
      ),
    );
  }

  Widget _buildLobbyView(BuildContext context, LobbyEntity lobby) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lobby.gameName),
        actions: [
          IconButton(
            tooltip: 'Chi tiết phòng',
            icon: const Icon(AppIcons.info),
            onPressed: () => _showLobbyDetails(context, lobby),
          ),
        ],
      ),
      body: Column(
        children: [
          _LobbyHeader(
            lobby: lobby,
            theme: theme,
            onShareInviteCode: () =>
                _shareInviteCode(context, lobby.inviteCode),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final chatSection = _ChatPanel(
                  controller: _chatController,
                  messages: _chatMessages,
                  onSend: () {
                    if (_chatController.text.trim().isEmpty) return;
                    setState(() {
                      _chatMessages.add(
                        ChatMessage(
                          senderName: 'Bạn',
                          message: _chatController.text,
                        ),
                      );
                      _chatController.clear();
                    });
                  },
                );

                final lobbyPanel = _MembersSection(
                  lobby: lobby,
                  onSimulate: () => _showSimulateFriendsSheet(context, lobby),
                  onInvite: () => _showInviteFriendsSheet(context, lobby),
                );

                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: lobbyPanel),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 2, child: chatSection),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  children: [
                    lobbyPanel,
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(
                      title: 'Trò chuyện trong phòng',
                      leading: AppIcons.chat,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    chatSection,
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _LobbyBottomActions(
          canBook: lobby.currentPlayers >= lobby.maxPlayers,
          onLeave: () {
            widget.lobbyCubit.leaveLobby(widget.lobbyId);
            Navigator.pop(context);
          },
          onBook: () => _openBookingSummary(context, LobbyReady(lobby: lobby)),
        ),
      ),
    );
  }

  void _showLobbyDetails(BuildContext context, LobbyEntity lobby) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _LobbyDetailsSheet(lobby: lobby),
    );
  }

  void _openBookingSummary(BuildContext context, LobbyReady state) {
    final lobby = state.lobby;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryPage(
          lobbyId: lobby.id,
          cafeId: lobby.cafeId,
          cafeName: lobby.cafeName,
          gameId: lobby.gameId,
          gameName: lobby.gameName,
          scheduledTime: lobby.scheduledTime,
          seatCount: lobby.currentPlayers,
          memberIds: lobby.players.map((p) => p.id).toList(),
        ),
      ),
    );
  }

  void _onAutoBookingCreated(
    BuildContext context,
    LobbyAutoBookingCreated state,
  ) {
    final lobby = state.lobby;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phòng đã đủ người! Đang tạo đơn đặt cọc tự động...'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryPage(
          lobbyId: lobby.id,
          cafeId: lobby.cafeId,
          cafeName: lobby.cafeName,
          gameId: lobby.gameId,
          gameName: lobby.gameName,
          scheduledTime: lobby.scheduledTime,
          seatCount: lobby.currentPlayers,
          memberIds: lobby.players.map((p) => p.id).toList(),
          autoBookingId: state.bookingId,
        ),
      ),
    );
  }
}

class _LobbyLoadingScaffold extends StatelessWidget {
  const _LobbyLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phòng chờ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đang vào phòng...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyFailureScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LobbyFailureScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng chờ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.error,
                  size: AppIcons.massive,
                  color: colors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Không thể vào phòng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;
  final VoidCallback onShareInviteCode;

  const _LobbyHeader({
    required this.lobby,
    required this.theme,
    required this.onShareInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final remainingSlots = lobby.slotsRemaining;
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceContainerHigh, colors.surfaceContainerHighest],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppElevation.shadowXs,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  AppIcons.cafe,
                  color: colors.onPrimaryContainer,
                  size: AppIcons.lg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lobby.cafeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Giờ hẹn: ${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              LobbyCountdownTimer(expiresAt: lobby.timeoutAt, onExpired: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: 'Thành viên',
                  value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                  icon: AppIcons.users,
                  progress: capacityProgress,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderStat(
                  label: 'Slot trống',
                  value: remainingSlots.toString(),
                  icon: AppIcons.userAdd,
                  progress: capacityProgress,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderStat(
                  label: 'Chế độ',
                  value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                  icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                ),
              ),
            ],
          ),
          if (lobby.inviteCode != null) ...[
            const SizedBox(height: AppSpacing.md),
            Material(
              color: colors.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: InkWell(
                onTap: onShareInviteCode,
                borderRadius: AppRadius.radiusMdAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.userAdd,
                        size: AppIcons.md,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã mời phòng',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              lobby.inviteCode!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        AppIcons.copy,
                        size: AppIcons.md,
                        color: colors.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? progress;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIcons.sm, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.radiusFullAll,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final LobbyEntity lobby;
  final VoidCallback onSimulate;
  final VoidCallback onInvite;

  const _MembersSection({
    required this.lobby,
    required this.onSimulate,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                title:
                    'Thành viên (${lobby.currentPlayers}/${lobby.maxPlayers})',
                leading: AppIcons.users,
              ),
            ),
            TextButton.icon(
              onPressed: onSimulate,
              icon: const Icon(AppIcons.refresh, size: AppIcons.sm),
              label: const Text('Giả lập'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.info,
                minimumSize: const Size(0, 40),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton.icon(
              onPressed: onInvite,
              icon: const Icon(AppIcons.userAdd, size: AppIcons.sm),
              label: const Text('Mời bạn bè'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LobbyPlayerGrid(
          players: lobby.players,
          maxSlots: lobby.maxPlayers,
          currentUserId: 'user_001',
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final TextEditingController controller;
  final List<ChatMessage> messages;
  final VoidCallback onSend;

  const _ChatPanel({
    required this.controller,
    required this.messages,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(AppIcons.chat, size: AppIcons.md, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Trò chuyện trong phòng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 220,
            child: messages.isEmpty
                ? _ChatEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _ChatMessageBubble(message: message);
                    },
                  ),
          ),
          const Divider(height: 1),
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
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      prefixIcon: Icon(AppIcons.chat, size: AppIcons.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton.tonal(
                  onPressed: onSend,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(AppIcons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.chat, size: AppIcons.xxl, color: colors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa có tin nhắn nào',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Mở lời chào để làm quen các thành viên nhé!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelf = message.senderName == 'Bạn';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AppIcons.md - 4,
            backgroundColor: isSelf
                ? colors.primaryContainer
                : colors.secondaryContainer,
            foregroundColor: isSelf
                ? colors.onPrimaryContainer
                : colors.onSecondaryContainer,
            child: Text(
              message.senderName.isEmpty
                  ? '?'
                  : message.senderName.characters.first.toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
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
                  message.senderName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
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
                      topLeft: Radius.circular(AppRadius.radiusXs - 2),
                      topRight: Radius.circular(AppRadius.radiusMd),
                      bottomLeft: Radius.circular(AppRadius.radiusMd),
                      bottomRight: Radius.circular(AppRadius.radiusMd),
                    ),
                  ),
                  child: Text(
                    message.message,
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

class _LobbyBottomActions extends StatelessWidget {
  final bool canBook;
  final VoidCallback onLeave;
  final VoidCallback onBook;

  const _LobbyBottomActions({
    required this.canBook,
    required this.onLeave,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = theme.brightness == Brightness.dark
        ? AppColorsDark.cardGradientOrange.last
        : AppColors.primary;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(AppIcons.logout),
            label: const Text('Rời phòng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              textStyle: theme.textTheme.labelLarge,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canBook
                    ? [
                        AppColors.primary,
                        theme.brightness == Brightness.dark
                            ? AppColorsDark.primary
                            : AppColors.primaryDark,
                      ]
                    : [
                        colors.surfaceContainerHighest,
                        colors.surfaceContainerHighest,
                      ],
              ),
              borderRadius: AppRadius.buttonRadius,
              boxShadow: canBook ? AppElevation.shadowSm : null,
            ),
            child: FilledButton.icon(
              onPressed: canBook ? onBook : null,
              icon: const Icon(AppIcons.creditCard),
              label: const Text('Tạo đơn đặt cọc'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: accent,
                disabledForegroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData leading;

  const _SectionTitle({required this.title, required this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Icon(
            leading,
            size: AppIcons.sm,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyDetailsSheet extends StatelessWidget {
  final LobbyEntity lobby;

  const _LobbyDetailsSheet({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final rows = <_DetailRowData>[
      _DetailRowData(
        icon: AppIcons.boardGame,
        label: 'Game',
        value: lobby.gameName,
      ),
      _DetailRowData(icon: AppIcons.cafe, label: 'Quán', value: lobby.cafeName),
      _DetailRowData(
        icon: AppIcons.schedule,
        label: 'Giờ hẹn',
        value:
            '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
      ),
      _DetailRowData(
        icon: AppIcons.users,
        label: 'Người chơi',
        value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
      ),
      _DetailRowData(
        icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
        label: 'Chế độ',
        value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
      ),
      if (lobby.inviteCode != null)
        _DetailRowData(
          icon: AppIcons.copy,
          label: 'Mã mời',
          value: lobby.inviteCode!,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: AppRadius.radiusFullAll,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chi tiết phòng',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _DetailRow(data: row),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  final IconData icon;
  final String label;
  final String value;

  _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _DetailRow extends StatelessWidget {
  final _DetailRowData data;

  const _DetailRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Icon(data.icon, size: AppIcons.md, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                data.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsSheet extends StatelessWidget {
  final LobbyState state;
  final void Function(FriendEntity) onInvite;
  final VoidCallback onClose;
  final bool showDevBadge;
  final BuildContext sheetContext;

  const _FriendsSheet({
    required this.state,
    required this.onInvite,
    required this.onClose,
    required this.showDevBadge,
    required this.sheetContext,
  });

  List<FriendEntity> get _friends => state is LobbyFriendsLoaded
      ? (state as LobbyFriendsLoaded).friends
      : state is LobbySimulateFriendsLoaded
      ? (state as LobbySimulateFriendsLoaded).friends
      : const <FriendEntity>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: AppRadius.radiusFullAll,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (showDevBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: AppRadius.radiusXxsAll,
                      ),
                      child: Text(
                        'DEV',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.infoDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      showDevBadge
                          ? 'Thêm bạn bè (Giả lập)'
                          : 'Mời bạn bè vào phòng',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    icon: const Icon(AppIcons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: OnlineFriendsList(
                friends: _friends,
                controller: controller,
                onInvite: (friend) {
                  Navigator.pop(sheetContext);
                  onInvite(friend);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLoading extends StatelessWidget {
  final String label;

  const _SheetLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String senderName;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
