import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_page.dart';

/// Modern lobby preview page với gradient hero header và elevated design.
class LobbyPreviewPage extends StatefulWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  const LobbyPreviewPage({
    super.key,
    required this.lobby,
    required this.lobbyCubit,
  });

  @override
  State<LobbyPreviewPage> createState() => _LobbyPreviewPageState();
}

class _LobbyPreviewPageState extends State<LobbyPreviewPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lobby = widget.lobby;
    final lobbyCubit = widget.lobbyCubit;

    return BlocProvider.value(
      value: lobbyCubit,
      child: Scaffold(
        body: BlocListener<LobbyCubit, LobbyState>(
          listener: (context, state) {
            if (state is LobbyCreated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LobbyPage(
                    lobbyId: state.lobby.id,
                    lobbyCubit: lobbyCubit,
                  ),
                ),
              );
            } else if (state is LobbyFailure) {
              final is409 = state.message.contains('409') ||
                  state.message.contains('trạng thái mở') ||
                  state.message.contains('đã đóng') ||
                  state.message.contains('đang chờ cafe duyệt') ||
                  state.message.contains('đang chơi');
              if (is409) {
                _showLobbyStatusDialog(state.message);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            }
          },
          child: CustomScrollView(
            slivers: [
              // ── Gradient Hero Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(lobby: lobby, theme: theme),
              ),

              // ── Detail grid ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _DetailGrid(lobby: lobby, theme: theme),
                ),
              ),

              // ── Status banner ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _StatusBanner(lobby: lobby, theme: theme),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),

        // ── Bottom CTA ──────────────────────────────────────────────
        bottomNavigationBar: _BottomCta(lobby: lobby, lobbyCubit: lobbyCubit),
      ),
    );
  }

  void _showLobbyStatusDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.info,
                    color: Theme.of(ctx).colorScheme.tertiary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng không khả dụng',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          message,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HERO HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _HeroHeader({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final scheduled = lobby.scheduledTime;
    final hh = scheduled.hour.toString().padLeft(2, '0');
    final mm = scheduled.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
        borderRadius: AppRadius.radiusLgAll,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top: game info + time
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game image
                if (lobby.gameImageUrl != null && lobby.gameImageUrl!.isNotEmpty)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      lobby.gameImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _GameInitial(name: lobby.gameName, colors: colors),
                    ),
                  )
                else
                  _GameInitial(name: lobby.gameName, colors: colors),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.gameName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.store_outlined, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lobby.cafeName.isEmpty ? 'Quán chưa rõ' : lobby.cafeName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom: time + status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Giờ hẹn: $hh:$mm',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

class _GameInitial extends StatelessWidget {
  final String name;
  final ColorScheme colors;

  const _GameInitial({required this.name, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
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
      LobbyStatus.open => ('Đang mở', AppIcons.boardGame, AppColors.success),
      LobbyStatus.full => ('Đã đầy', AppIcons.users, AppColors.warning),
      LobbyStatus.inProgress => ('Đang chơi', AppIcons.boardGame, AppColors.info),
      _ => ('Không khả dụng', AppIcons.lock, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: AppRadius.radiusFullAll,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
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

// ══════════════════════════════════════════════════════════════════════════════
//  DETAIL GRID
// ══════════════════════════════════════════════════════════════════════════════

class _DetailGrid extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _DetailGrid({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
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
                colors: colors,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _DetailTile(
                icon: AppIcons.userAdd,
                label: 'Slot trống',
                value: lobby.slotsRemaining.toString(),
                theme: theme,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DetailTile(
                icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                label: 'Chế độ',
                value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _DetailTile(
                icon: AppIcons.karma,
                label: 'Karma tối thiểu',
                value: lobby.minimumKarma > 0 ? '${lobby.minimumKarma.toInt()}+' : 'Không yêu cầu',
                theme: theme,
                colors: colors,
              ),
            ),
          ],
        ),
        if (lobby.inviteCode != null && lobby.inviteCode!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailTile(
            icon: AppIcons.copy,
            label: 'Mã mời phòng',
            value: lobby.inviteCode!,
            theme: theme,
            colors: colors,
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
  final ColorScheme colors;
  final bool highlight;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
    required this.theme,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? colors.primaryContainer.withValues(alpha: 0.3) : colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: highlight ? colors.primary.withValues(alpha: 0.5) : colors.outlineVariant,
        ),
        boxShadow: highlight ? null : AppElevation.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: highlight ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppRadius.radiusFullAll,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
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

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS BANNER
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _StatusBanner({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    if (lobby.status == LobbyStatus.full) {
      return _Banner(
        icon: Icons.groups,
        iconColor: AppColors.warning,
        text: 'Phòng đã đầy. Bạn có thể đăng ký vào danh sách chờ hoặc tìm phòng khác.',
        bgColor: AppColors.warning.withValues(alpha: 0.08),
        theme: theme,
      );
    }
    if (lobby.status != LobbyStatus.open) {
      return _Banner(
        icon: AppIcons.lock,
        iconColor: colors.error,
        text: 'Phòng này hiện không nhận thêm thành viên.',
        bgColor: colors.errorContainer.withValues(alpha: 0.3),
        theme: theme,
      );
    }
    return _Banner(
      icon: AppIcons.info,
      iconColor: colors.primary,
      text: 'Bấm "Tham gia phòng" để vào lobby. Hệ thống sẽ kiểm tra Karma và số slot trống trước khi xác nhận.',
      bgColor: colors.primaryContainer.withValues(alpha: 0.2),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM CTA
// ══════════════════════════════════════════════════════════════════════════════

class _BottomCta extends StatelessWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  const _BottomCta({required this.lobby, required this.lobbyCubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
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
        child: BlocBuilder<LobbyCubit, LobbyState>(
          builder: (context, state) {
            final isLoading = state is LobbyLoading;
            final canJoin = lobby.status == LobbyStatus.open && lobby.slotsRemaining > 0;
            return _GradientCtaButton(
              isActive: canJoin && !isLoading,
              isLoading: isLoading,
              label: _buttonLabel(lobby, isLoading),
              icon: canJoin ? AppIcons.userAdd : AppIcons.lock,
              onTap: canJoin ? () => _confirmAndJoin(context) : null,
            );
          },
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(AppIcons.boardGame, color: theme.colorScheme.primary),
        title: const Text('Xác nhận tham gia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn sắp tham gia phòng chờ:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            _ConfirmRow(icon: AppIcons.boardGame, label: 'Game', value: lobby.gameName, theme: theme),
            _ConfirmRow(icon: AppIcons.cafe, label: 'Quán', value: lobby.cafeName.isEmpty ? '—' : lobby.cafeName, theme: theme),
            _ConfirmRow(icon: AppIcons.schedule, label: 'Giờ hẹn', value: timeText, theme: theme),
            _ConfirmRow(icon: AppIcons.users, label: 'Slot trống', value: '${lobby.slotsRemaining} chỗ', theme: theme),
            if (lobby.minimumKarma > 0)
              _ConfirmRow(icon: AppIcons.karma, label: 'Yêu cầu Karma', value: '${lobby.minimumKarma.toInt()}+', theme: theme),
            if (!lobby.isPublic) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.lock, size: 16, color: theme.colorScheme.onTertiaryContainer),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Phòng riêng tư. Bạn cần mã mời hoặc là bạn bè của Host.',
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
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Tham gia')),
        ],
      ),
    );

    if (confirmed == true) {
      lobbyCubit.joinLobby(lobby.id, lobby.inviteCode);
    }
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _ConfirmRow({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _GradientCtaButton extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _GradientCtaButton({
    required this.isActive,
    required this.isLoading,
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
            ? LinearGradient(colors: [colors.primary, colors.primary.withAlpha(204)])
            : null,
        color: isActive ? null : colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  Icon(icon, size: 22, color: isActive ? Colors.white : colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
