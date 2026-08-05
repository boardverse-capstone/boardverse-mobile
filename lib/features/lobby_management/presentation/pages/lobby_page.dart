import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/current_user_resolver.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_chat_message.dart';
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
  final List<LobbyChatMessage> _chatMessages = [];
  String? _currentUserId;
  bool _chatLoaded = false;

  @override
  void initState() {
    super.initState();
    _resolveCurrentUserAndJoin();
  }

  Future<void> _resolveCurrentUserAndJoin() async {
    final resolver = getIt<CurrentUserResolver>();
    final userId = await resolver.resolveUserId();
    if (!mounted) return;
    if (userId != null) setState(() => _currentUserId = userId);
    await widget.lobbyCubit.initLobbyState(widget.lobbyId, userId ?? '');
  }

  void _loadChatMessages() {
    if (!_chatLoaded) {
      _chatLoaded = true;
      widget.lobbyCubit.loadChatMessages(widget.lobbyId);
    }
  }

  void _sendChatMessage() {
    final content = _chatController.text.trim();
    if (content.isEmpty) return;
    widget.lobbyCubit.sendChatMessage(widget.lobbyId, content);
    _chatController.clear();
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
        child: BlocListener<LobbyCubit, LobbyState>(
          listenWhen: (prev, current) =>
              current is LobbyUpdatedRealtime && prev is! LobbyUpdatedRealtime,
          listener: (sheetCtx, _) {
            if (Navigator.of(sheetCtx).canPop()) Navigator.of(sheetCtx).pop();
          },
          child: BlocBuilder<LobbyCubit, LobbyState>(
            builder: (sheetCtx, state) {
              if (state is LobbyFriendsLoaded) {
                return _FriendsSheet(
                  state: state,
                  onInvite: (friend) => _completeFriendAction(friend, lobby),
                  onAdd: (friend) => _completeAddFriendAction(friend, lobby),
                  onClose: () => Navigator.pop(sheetCtx),
                  showDevBadge: false,
                  sheetContext: sheetCtx,
                );
              }
              return const _SheetLoading(label: 'Đang tải danh sách bạn bè...');
            },
          ),
        ),
      ),
    );
  }

  void _completeFriendAction(FriendEntity friend, LobbyEntity lobby) {
    widget.lobbyCubit.inviteFriend(widget.lobbyId, friend.odId);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi lời mời đến ${friend.username}')),
    );
  }

  void _completeAddFriendAction(FriendEntity friend, LobbyEntity lobby) {
    widget.lobbyCubit.simulateAddFriend(widget.lobbyId, friend.odId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${friend.username} vào phòng')),
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
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

  void _showDissolvedSnackBar(BuildContext context, LobbyDissolved state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Phòng chờ đã được giải tán và xoá khỏi hệ thống.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.lobbyCubit,
      child: BlocConsumer<LobbyCubit, LobbyState>(
        listener: (context, state) {
          if (state is LobbyDismissed) _showDismissDialog(context, state);
          if (state is LobbyDissolved) _showDissolvedSnackBar(context, state);
          if (state is LobbyChatLoaded) {
            setState(() {
              _chatMessages.clear();
              _chatMessages.addAll(state.messages);
            });
          }
          if (state is LobbyChatError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        buildWhen: (previous, current) =>
            current is! LobbyFriendsLoaded &&
            current is! LobbySimulateFriendsLoaded &&
            current is! LobbyChatLoaded &&
            current is! LobbyChatError,
        builder: (context, state) {
          if (state is LobbyLoading) return const _LobbyLoadingScaffold();
          if (state is LobbyFailure) {
            return _LobbyFailureScaffold(
              message: state.message,
              onRetry: () => widget.lobbyCubit.joinLobby(widget.lobbyId, null),
            );
          }
          if (state is LobbyEnded) {
            return _LobbyEndedView(
              lobby: state.lobby,
              currentUserId: _currentUserId ?? '',
              onDissolve: () => _onDissolveEndedLobby(state.lobby),
              onRecreate: () => _onRecreateEndedLobby(state.lobby),
              onExtend: () => _onExtendEndedLobby(state.lobby),
              onShowDetails: () => _showLobbyDetails(context, state.lobby),
            );
          }

          final lobby = state is LobbyCreated
              ? state.lobby
              : state is LobbyUpdatedRealtime
              ? state.lobby
              : null;

          if (lobby == null) return const _LobbyLoadingScaffold();
          _loadChatMessages();
          return _buildLobbyView(context, lobby);
        },
      ),
    );
  }

  Future<void> _onDissolveEndedLobby(LobbyEntity lobby) async {
    await widget.lobbyCubit.dissolveLobby(lobby.id);
  }

  Future<void> _onRecreateEndedLobby(LobbyEntity lobby) async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vào "Phòng chờ" → bấm "Tạo phòng" để tạo lobby mới.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _onExtendEndedLobby(LobbyEntity lobby) =>
      _onRecreateEndedLobby(lobby);

  Future<bool> _confirmDissolveActive(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.delete,
          size: AppIcons.massive,
          color: colors.error,
        ),
        title: const Text('Giải tán phòng chờ?'),
        content: const Text(
          'Phòng chờ sẽ bị xoá vĩnh viễn khỏi hệ thống. '
          'Tất cả tin nhắn, lời mời và báo cáo cũng sẽ bị xoá. '
          'Bạn không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Giải tán'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onDissolveActiveLobby(LobbyEntity lobby) async {
    final confirmed = await _confirmDissolveActive(context);
    if (!confirmed || !mounted) return;
    await widget.lobbyCubit.dissolveLobby(lobby.id);
  }

  Widget _buildLobbyView(BuildContext context, LobbyEntity lobby) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isHost = lobby.hostId == (_currentUserId ?? '');
    final showDissolve = isHost && lobby.status.canDissolve;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Modern AppBar ─────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: Text(
              lobby.gameName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (showDissolve)
                _AppBarAction(
                  icon: AppIcons.delete,
                  iconColor: colors.error,
                  tooltip: 'Giải tán phòng',
                  onTap: () => _onDissolveActiveLobby(lobby),
                ),
              _AppBarAction(
                icon: AppIcons.info,
                iconColor: colors.onSurfaceVariant,
                tooltip: 'Chi tiết phòng',
                onTap: () => _showLobbyDetails(context, lobby),
              ),
            ],
          ),

          // ── Lobby Hero Header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _LobbyHeroHeader(
              lobby: lobby,
              theme: theme,
              onShareInviteCode: () =>
                  _shareInviteCode(context, lobby.inviteCode),
            ),
          ),

          // ── Players Section ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _PlayersSection(
              lobby: lobby,
              currentUserId: _currentUserId ?? '',
              onInvite: () => _showInviteFriendsSheet(context, lobby),
            ),
          ),

          // ── Chat Section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ChatSection(
              controller: _chatController,
              messages: _chatMessages,
              currentUserId: _currentUserId ?? '',
              onSend: _sendChatMessage,
            ),
          ),

          // ── Bottom padding for safe area ────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),

      // ── Bottom Action Bar ───────────────────────────────────────────
      bottomNavigationBar: _LobbyBottomBar(
        lobby: lobby,
        currentUserId: _currentUserId ?? '',
        onLeave: () {
          widget.lobbyCubit.leaveLobby(widget.lobbyId);
          Navigator.pop(context);
        },
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
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: AppBar Action Button
// ══════════════════════════════════════════════════════════════════════════

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarAction({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: iconColor),
      onPressed: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Lobby Hero Header
// ══════════════════════════════════════════════════════════════════════════

class _LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;
  final VoidCallback onShareInviteCode;

  const _LobbyHeroHeader({
    required this.lobby,
    required this.theme,
    required this.onShareInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusLgAll,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Cafe info + Timer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Cafe avatar + info
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Icon(AppIcons.cafe, color: Colors.white, size: 24),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giờ hẹn: ${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                LobbyCountdownTimer(
                  expiresAt: lobby.timeoutAt,
                  onExpired: () {},
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                _HeroStat(
                  label: 'Thành viên',
                  value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                  icon: AppIcons.users,
                  progress: capacityProgress,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeroStat(
                  label: 'Slot trống',
                  value: lobby.slotsRemaining.toString(),
                  icon: AppIcons.userAdd,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeroStat(
                  label: 'Chế độ',
                  value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                  icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                ),
              ],
            ),
          ),

          // Invite code pill
          if (lobby.inviteCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _InviteCodePill(
                code: lobby.inviteCode!,
                onTap: onShareInviteCode,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? progress;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: AppRadius.radiusMdAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.radiusFullAll,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteCodePill extends StatelessWidget {
  final String code;
  final VoidCallback onTap;
  final ThemeData theme;

  const _InviteCodePill({
    required this.code,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: AppRadius.radiusFullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusFullAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.userAdd, size: 16, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mã mời',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                AppIcons.copy,
                size: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Players Section
// ══════════════════════════════════════════════════════════════════════════

class _PlayersSection extends StatelessWidget {
  final LobbyEntity lobby;
  final String currentUserId;
  final VoidCallback onInvite;

  const _PlayersSection({
    required this.lobby,
    required this.currentUserId,
    required this.onInvite,
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
                  color: colors.primaryContainer,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(
                  AppIcons.users,
                  size: AppIcons.sm,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Thành viên (${lobby.currentPlayers}/${lobby.maxPlayers})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _InviteButton(onTap: onInvite),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Player grid
          LobbyPlayerGrid(
            players: lobby.players,
            maxSlots: lobby.maxPlayers,
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InviteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: AppRadius.radiusSmAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSmAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.userAdd,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                'Mời bạn',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Chat Section
// ══════════════════════════════════════════════════════════════════════════

class _ChatSection extends StatelessWidget {
  final TextEditingController controller;
  final List<LobbyChatMessage> messages;
  final String currentUserId;
  final VoidCallback onSend;

  const _ChatSection({
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
                      ? _ChatEmptyState(theme: theme, colors: colors)
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: messages.length,
                          itemBuilder: (context, index) => _ChatBubble(
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

class _ChatEmptyState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _ChatEmptyState({required this.theme, required this.colors});

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

class _ChatBubble extends StatelessWidget {
  final LobbyChatMessage message;
  final String currentUserId;

  const _ChatBubble({required this.message, required this.currentUserId});

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
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
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

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Bottom Action Bar
// ══════════════════════════════════════════════════════════════════════════

class _LobbyBottomBar extends StatelessWidget {
  final LobbyEntity lobby;
  final String currentUserId;
  final VoidCallback onLeave;

  const _LobbyBottomBar({
    required this.lobby,
    required this.currentUserId,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: OutlinedButton.icon(
          onPressed: onLeave,
          icon: const Icon(AppIcons.logout, size: 18),
          label: const Text('Rời phòng'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMdAll,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientCtaButton extends StatelessWidget {
  final bool isActive;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _GradientCtaButton({
    required this.isActive,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [colors.primary, colors.primary.withAlpha(204)],
              )
            : null,
        color: isActive ? null : colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.white : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Loading / Error Scaffolds
// ══════════════════════════════════════════════════════════════════════════

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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.xl),
              _GradientCtaButton(
                isActive: true,
                label: 'Thử lại',
                icon: AppIcons.refresh,
                onTap: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Lobby Ended View
// ══════════════════════════════════════════════════════════════════════════

class _LobbyEndedView extends StatelessWidget {
  final LobbyEntity lobby;
  final String currentUserId;
  final VoidCallback onDissolve;
  final VoidCallback onRecreate;
  final VoidCallback onExtend;
  final VoidCallback onShowDetails;

  const _LobbyEndedView({
    required this.lobby,
    required this.currentUserId,
    required this.onDissolve,
    required this.onRecreate,
    required this.onExtend,
    required this.onShowDetails,
  });

  bool get _isHost => lobby.hostId == currentUserId;

  ({String title, IconData icon, Color color, String subtitle}) _statusInfo(
    ColorScheme colors,
  ) {
    switch (lobby.status) {
      case LobbyStatus.closed:
        return (
          title: 'Phòng đã đóng',
          icon: Icons.lock_outline,
          color: colors.error,
          subtitle: 'Phòng đã được host đóng lại.',
        );
      case LobbyStatus.timeoutFailed:
        return (
          title: 'Phòng đã hết hạn',
          icon: Icons.timer_off_outlined,
          color: colors.error,
          subtitle: 'Không đủ người tham gia trong thời gian chờ.',
        );
      case LobbyStatus.hostCancelled:
        return (
          title: 'Phòng đã bị huỷ',
          icon: Icons.cancel_outlined,
          color: colors.error,
          subtitle: 'Host đã huỷ phòng chờ này.',
        );
      default:
        return (
          title: 'Phòng đã kết thúc',
          icon: Icons.history,
          color: colors.outline,
          subtitle: 'Không còn nhận thành viên mới.',
        );
    }
  }

  Future<bool> _confirmDissolve(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.delete,
          size: AppIcons.massive,
          color: colors.error,
        ),
        title: const Text('Giải tán phòng chờ?'),
        content: const Text(
          'Phòng chờ sẽ bị xoá vĩnh viễn. Bạn không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Giải tán'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final info = _statusInfo(colors);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lobby.gameName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_isHost && lobby.status.canDissolve)
            IconButton(
              tooltip: 'Giải tán phòng',
              icon: Icon(AppIcons.delete, color: colors.error),
              onPressed: () async {
                final confirmed = await _confirmDissolve(context);
                if (confirmed) onDissolve();
              },
            ),
          IconButton(
            tooltip: 'Chi tiết phòng',
            icon: const Icon(AppIcons.info),
            onPressed: onShowDetails,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [info.color, info.color.withAlpha(204)],
              ),
              borderRadius: AppRadius.radiusLgAll,
              boxShadow: [
                BoxShadow(
                  color: info.color.withAlpha(51),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Lobby info card
          _EndedInfoCard(lobby: lobby),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          if (_isHost) ...[
            _ActionCard(
              icon: AppIcons.delete,
              title: 'Giải tán phòng',
              subtitle: 'Xoá vĩnh viễn khỏi hệ thống.',
              iconColor: colors.error,
              isEnabled: lobby.status.canDissolve,
              onTap: () async {
                final confirmed = await _confirmDissolve(context);
                if (confirmed) onDissolve();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionCard(
              icon: AppIcons.refresh,
              title: 'Tạo lại phòng',
              subtitle: 'Tạo lobby mới với cùng game và quán.',
              iconColor: colors.primary,
              onTap: onRecreate,
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionCard(
              icon: Icons.update,
              title: 'Gia hạn phòng',
              subtitle: 'Tạo lobby mới với thời gian mới.',
              iconColor: colors.secondary,
              onTap: onExtend,
            ),
          ] else
            _ActionCard(
              icon: AppIcons.refresh,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
              iconColor: colors.primary,
              onTap: onRecreate,
            ),
        ],
      ),
    );
  }
}

class _EndedInfoCard extends StatelessWidget {
  final LobbyEntity lobby;

  const _EndedInfoCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final timeFmt = DateFormat('HH:mm • dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowSm,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: AppIcons.boardGame,
            label: 'Trò chơi',
            value: lobby.gameName,
            theme: theme,
            colors: colors,
          ),
          _InfoRow(
            icon: AppIcons.cafe,
            label: 'Quán',
            value: lobby.cafeName,
            theme: theme,
            colors: colors,
          ),
          _InfoRow(
            icon: AppIcons.schedule,
            label: 'Giờ hẹn',
            value: timeFmt.format(lobby.scheduledTime.toLocal()),
            theme: theme,
            colors: colors,
          ),
          _InfoRow(
            icon: AppIcons.users,
            label: 'Thành viên',
            value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
            theme: theme,
            colors: colors,
          ),
          _InfoRow(
            icon: AppIcons.user,
            label: 'Chủ phòng',
            value: lobby.hostName,
            theme: theme,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colors;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: AppRadius.radiusMdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isEnabled
                  ? colors.outlineVariant
                  : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (isEnabled ? iconColor : colors.outline).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? iconColor : colors.outline,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isEnabled
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isEnabled
                            ? colors.onSurfaceVariant
                            : colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? colors.onSurfaceVariant : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Lobby Details Sheet
// ══════════════════════════════════════════════════════════════════════════

class _LobbyDetailsSheet extends StatelessWidget {
  final LobbyEntity lobby;

  const _LobbyDetailsSheet({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final rows = [
      _DetailRow(
        icon: AppIcons.boardGame,
        label: 'Game',
        value: lobby.gameName,
      ),
      _DetailRow(icon: AppIcons.cafe, label: 'Quán', value: lobby.cafeName),
      _DetailRow(
        icon: AppIcons.schedule,
        label: 'Giờ hẹn',
        value:
            '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
      ),
      _DetailRow(
        icon: AppIcons.users,
        label: 'Người chơi',
        value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
      ),
      _DetailRow(
        icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
        label: 'Chế độ',
        value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
      ),
      if (lobby.inviteCode != null)
        _DetailRow(
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
              child: row,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          child: Icon(icon, size: AppIcons.md, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
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

// ══════════════════════════════════════════════════════════════════════════
//  MODERN: Friends Sheet
// ══════════════════════════════════════════════════════════════════════════

class _FriendsSheet extends StatelessWidget {
  final LobbyState state;
  final void Function(FriendEntity) onInvite;
  final void Function(FriendEntity) onAdd;
  final VoidCallback onClose;
  final bool showDevBadge;
  final BuildContext sheetContext;

  const _FriendsSheet({
    required this.state,
    required this.onInvite,
    required this.onAdd,
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
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
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
                onAdd: (friend) => onAdd(friend),
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
