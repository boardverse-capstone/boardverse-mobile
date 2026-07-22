import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_page.dart';

/// Trang xem trước (preview) một lobby từ `/api/v1/lobbies/discoverable`.
/// Flow Browse lobbies: List → Preview → Confirm Join → LobbyPage.
///
/// Mục đích:
/// - Hiển thị đầy đủ thông tin lobby (game, cafe, host, slots, karma, ...) trước
///   khi user quyết định tham gia.
/// - Nút "Tham gia" mở confirm dialog với thông tin quan trọng (giờ, karma,
///   slot trống) → user xác nhận → gọi `LobbyCubit.joinLobby` → navigate
///   sang `LobbyPage`.
class LobbyPreviewPage extends StatelessWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  const LobbyPreviewPage({
    super.key,
    required this.lobby,
    required this.lobbyCubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: lobbyCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết phòng chờ'),
          actions: [
            IconButton(
              tooltip: 'Đóng',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: BlocListener<LobbyCubit, LobbyState>(
          listener: (context, state) {
            if (state is LobbyCreated) {
              // Join thành công → navigate sang LobbyPage (đè stack).
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LobbyPage(
                    lobbyId: state.lobby.id,
                    lobbyCubit: lobbyCubit,
                  ),
                ),
              );
            } else if (state is LobbyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(lobby: lobby, theme: theme)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _DetailGrid(lobby: lobby, theme: theme),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: _StatusBanner(lobby: lobby, theme: theme),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.md),
          child: BlocBuilder<LobbyCubit, LobbyState>(
            builder: (context, state) {
              final isLoading = state is LobbyLoading;
              final canJoin = lobby.status == LobbyStatus.open &&
                  lobby.slotsRemaining > 0;
              return FilledButton.icon(
                onPressed: (isLoading || !canJoin)
                    ? null
                    : () => _confirmAndJoin(context),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        canJoin
                            ? AppIcons.userAdd
                            : AppIcons.lock,
                      ),
                label: Text(_buttonLabel(lobby, isLoading)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  textStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _buttonLabel(LobbyEntity lobby, bool isLoading) {
    if (isLoading) return 'Đang tham gia...';
    if (lobby.status != LobbyStatus.open) return 'Phòng không mở';
    if (lobby.slotsRemaining <= 0) return 'Phòng đã đầy';
    return 'Tham gia phòng';
  }

  Future<void> _confirmAndJoin(BuildContext context) async {
    final theme = Theme.of(context);
    final timeText =
        '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(AppIcons.boardGame, color: theme.colorScheme.primary),
        title: const Text('Xác nhận tham gia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn sắp tham gia phòng chờ:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ConfirmRow(
              icon: AppIcons.boardGame,
              label: 'Game',
              value: lobby.gameName,
              theme: theme,
            ),
            _ConfirmRow(
              icon: AppIcons.cafe,
              label: 'Quán',
              value: lobby.cafeName.isEmpty ? '—' : lobby.cafeName,
              theme: theme,
            ),
            _ConfirmRow(
              icon: AppIcons.schedule,
              label: 'Giờ hẹn',
              value: timeText,
              theme: theme,
            ),
            _ConfirmRow(
              icon: AppIcons.users,
              label: 'Slot trống',
              value: '${lobby.slotsRemaining} chỗ',
              theme: theme,
            ),
            if (lobby.minimumKarma > 0)
              _ConfirmRow(
                icon: AppIcons.karma,
                label: 'Yêu cầu Karma',
                value: '${lobby.minimumKarma.toInt()}+',
                theme: theme,
              ),
            if (!lobby.isPublic) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.lock,
                      size: AppIcons.sm,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Phòng riêng tư. Bạn có thể vào nếu có mã mời hoặc '
                        'là bạn bè của Host.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      lobbyCubit.joinLobby(lobby.id, lobby.inviteCode);
    }
  }
}

class _Header extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _Header({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final scheduled = lobby.scheduledTime;
    final hh = scheduled.hour.toString().padLeft(2, '0');
    final mm = scheduled.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppElevation.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (lobby.gameImageUrl != null && lobby.gameImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadius.radiusSmAll,
                  child: Image.network(
                    lobby.gameImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.white.withValues(alpha: 0.25),
                      child: Icon(
                        AppIcons.boardGame,
                        color: colors.onPrimary,
                        size: AppIcons.lg,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Icon(
                    AppIcons.boardGame,
                    color: colors.onPrimary,
                    size: AppIcons.lg,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lobby.gameName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      lobby.cafeName.isEmpty ? 'Quán chưa rõ' : lobby.cafeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.schedule,
                  color: colors.onPrimary,
                  size: AppIcons.md,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Giờ hẹn: $hh:$mm',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(lobby: lobby, theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _StatusChip({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg) = switch (lobby.status) {
      LobbyStatus.open => ('Đang mở', AppIcons.boardGame, Colors.green),
      LobbyStatus.full => ('Đã đầy', AppIcons.users, Colors.orange),
      LobbyStatus.inProgress => ('Đang chơi', AppIcons.boardGame, Colors.blue),
      _ => ('Không khả dụng', AppIcons.lock, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: AppRadius.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcons.sm, color: Colors.white),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _DetailGrid({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final slotsRemaining = lobby.slotsRemaining;
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailTile(
                icon: AppIcons.users,
                label: 'Thành viên',
                value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                progress: capacityProgress,
                theme: theme,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DetailTile(
                icon: AppIcons.userAdd,
                label: 'Slot trống',
                value: slotsRemaining.toString(),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _DetailTile(
                icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                label: 'Chế độ',
                value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                theme: theme,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DetailTile(
                icon: AppIcons.karma,
                label: 'Karma tối thiểu',
                value: lobby.minimumKarma > 0
                    ? '${lobby.minimumKarma.toInt()}+'
                    : 'Không yêu cầu',
                theme: theme,
              ),
            ),
          ],
        ),
        if (lobby.inviteCode != null && lobby.inviteCode!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailTile(
            icon: AppIcons.copy,
            label: 'Mã mời phòng',
            value: lobby.inviteCode!,
            theme: theme,
            highlight: true,
          ),
        ],
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? progress;
  final ThemeData theme;
  final bool highlight;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: highlight ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppIcons.sm,
                color: highlight ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _StatusBanner extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _StatusBanner({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    if (lobby.status == LobbyStatus.full) {
      return _Banner(
        icon: AppIcons.users,
        iconColor: Colors.orange,
        text: 'Phòng đã đầy. Bạn có thể đăng ký vào danh sách chờ hoặc tìm '
            'phòng khác.',
        bgColor: Colors.orange.withValues(alpha: 0.12),
        theme: theme,
      );
    }
    if (lobby.status != LobbyStatus.open) {
      return _Banner(
        icon: AppIcons.lock,
        iconColor: colors.error,
        text: 'Phòng này hiện không nhận thêm thành viên.',
        bgColor: colors.errorContainer.withValues(alpha: 0.5),
        theme: theme,
      );
    }
    return _Banner(
      icon: AppIcons.info,
      iconColor: colors.primary,
      text: 'Bấm "Tham gia phòng" để vào lobby. Hệ thống sẽ kiểm tra Karma và '
          'số slot trống trước khi xác nhận.',
      bgColor: colors.primaryContainer.withValues(alpha: 0.3),
      theme: theme,
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color bgColor;
  final ThemeData theme;

  const _Banner({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.bgColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: AppIcons.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: AppIcons.sm, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}