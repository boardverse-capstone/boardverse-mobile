import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import '../widgets/lobby_status_badge.dart';
import 'lobby_page.dart';

/// Neo-brutalism lobby preview page.
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
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // ── Hero Card ────────────────────────────────────────────────
                _NeoHeroCard(lobby: lobby),

                const SizedBox(height: AppSpacing.md),

                // ── Detail Grid ─────────────────────────────────────────────
                _DetailGrid(lobby: lobby),

                const SizedBox(height: AppSpacing.md),

                // ── Status Banner ─────────────────────────────────────────
                _StatusBanner(lobby: lobby),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomCta(
          lobby: lobby,
          lobbyCubit: lobbyCubit,
        ),
      ),
    );
  }

  void _showLobbyStatusDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      AppIcons.info,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phòng không khả dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.black.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _NeoFilledButton(
              label: 'Đã hiểu',
              icon: AppIcons.check,
              color: AppColors.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HERO CARD — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _NeoHeroCard extends StatelessWidget {
  final LobbyEntity lobby;

  const _NeoHeroCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduled = lobby.scheduledTime;
    final hh = scheduled.hour.toString().padLeft(2, '0');
    final mm = scheduled.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: gradient bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Game image / initial
                if (lobby.gameImageUrl != null &&
                    lobby.gameImageUrl!.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      lobby.gameImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _GameInitial(name: lobby.gameName),
                    ),
                  )
                else
                  _GameInitial(name: lobby.gameName),

                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.gameName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.store,
                            size: 14,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lobby.cafeName.isEmpty
                                  ? 'Quán chưa rõ'
                                  : lobby.cafeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusChip(lobby: lobby),
              ],
            ),
          ),

          // ── Bottom: time row ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Time pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.4),
                        blurRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$hh:$mm',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Capacity
                _CapacityBadge(lobby: lobby),
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

  const _GameInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final LobbyEntity lobby;

  const _CapacityBadge({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;
    final color = isFull ? AppColors.success : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, size: 16, color: AppColors.white),
          const SizedBox(width: 6),
          Text(
            '${lobby.currentPlayers}/${lobby.maxPlayers}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LobbyEntity lobby;

  const _StatusChip({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final variant = resolveBadgeVariant(
      lobbyStatus: lobby.status,
      reservationStatus: lobby.reservationStatus,
    );
    return LobbyStatusBadge(variant: variant, dense: true);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DETAIL GRID — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _DetailGrid extends StatelessWidget {
  final LobbyEntity lobby;

  const _DetailGrid({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Column(
      children: [
        // Row 1: Members + Slots
        Row(
          children: [
            Expanded(
              child: _NeoTile(
                icon: AppIcons.users,
                label: 'THÀNH VIÊN',
                value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                progress: capacityProgress,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoTile(
                icon: AppIcons.userAdd,
                label: 'SLOT TRỐNG',
                value: '${lobby.slotsRemaining}',
                accentColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Row 2: Mode + Karma
        Row(
          children: [
            Expanded(
              child: _NeoTile(
                icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                label: 'CHẾ ĐỘ',
                value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                accentColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoTile(
                icon: AppIcons.karma,
                label: 'KARMA TỐI THIỂU',
                value: lobby.minimumKarma > 0
                    ? '${lobby.minimumKarma.toInt()}+'
                    : 'Không yêu cầu',
                accentColor: AppColors.accent,
              ),
            ),
          ],
        ),

        // Invite code row
        if (lobby.inviteCode != null && lobby.inviteCode!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _NeoInviteTile(
            code: lobby.inviteCode!,
          ),
        ],
      ],
    );
  }
}

class _NeoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? progress;
  final Color accentColor;

  const _NeoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 14, color: AppColors.white),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeoInviteTile extends StatelessWidget {
  final String code;

  const _NeoInviteTile({required this.code});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: const Icon(
              AppIcons.copy,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÃ MỜI PHÒNG',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.white,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace',
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

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS BANNER — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  final LobbyEntity lobby;

  const _StatusBanner({required this.lobby});

  @override
  Widget build(BuildContext context) {
    if (lobby.status == LobbyStatus.full) {
      return _NeoBanner(
        icon: Icons.groups,
        iconColor: AppColors.warning,
        text:
            'Phòng đã đầy. Bạn có thể đăng ký vào danh sách chờ hoặc tìm phòng khác.',
      );
    }
    if (lobby.status != LobbyStatus.open) {
      return _NeoBanner(
        icon: AppIcons.lock,
        iconColor: AppColors.error,
        text: 'Phòng này hiện không nhận thêm thành viên.',
      );
    }
    return _NeoBanner(
      icon: AppIcons.info,
      iconColor: AppColors.primary,
      text:
          'Bấm "Tham gia phòng" để vào lobby. Hệ thống sẽ kiểm tra Karma và số slot trống trước khi xác nhận.',
    );
  }
}

class _NeoBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _NeoBanner({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: iconColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM CTA — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _BottomCta extends StatelessWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  const _BottomCta({required this.lobby, required this.lobbyCubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<LobbyCubit, LobbyState>(
          builder: (context, state) {
            final isLoading = state is LobbyLoading;
            final canJoin =
                lobby.status == LobbyStatus.open && lobby.slotsRemaining > 0;
            return _NeoFilledButton(
              label: _buttonLabel(lobby, isLoading),
              icon: canJoin ? AppIcons.userAdd : AppIcons.lock,
              color: canJoin ? AppColors.primary : AppColors.textTertiary,
              isLoading: isLoading,
              onPressed: canJoin ? () => _confirmAndJoin(context) : null,
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
    return 'THAM GIA PHÒNG';
  }

  Future<void> _confirmAndJoin(BuildContext context) async {
    final timeText =
        '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  AppIcons.boardGame,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Xác nhận tham gia',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Info rows
              _ConfirmRow(
                icon: AppIcons.boardGame,
                label: 'Game',
                value: lobby.gameName,
              ),
              _ConfirmRow(
                icon: AppIcons.cafe,
                label: 'Quán',
                value: lobby.cafeName.isEmpty ? '—' : lobby.cafeName,
              ),
              _ConfirmRow(
                icon: AppIcons.schedule,
                label: 'Giờ hẹn',
                value: timeText,
              ),
              _ConfirmRow(
                icon: AppIcons.users,
                label: 'Slot trống',
                value: '${lobby.slotsRemaining} chỗ',
              ),
              if (lobby.minimumKarma > 0)
                _ConfirmRow(
                  icon: AppIcons.karma,
                  label: 'Yêu cầu Karma',
                  value: '${lobby.minimumKarma.toInt()}+',
                ),

              if (!lobby.isPublic) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.lock,
                        size: 16,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Phòng riêng tư. Bạn cần mã mời hoặc là bạn bè của Host.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AppColors.black.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Huỷ',
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'Tham gia',
                      icon: AppIcons.userAdd,
                      color: AppColors.primary,
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.black,
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

// ══════════════════════════════════════════════════════════════════════════════
//  NEO-BRUTALISM BUTTONS
// ══════════════════════════════════════════════════════════════════════════════

class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _NeoFilledButton({
    required this.label,
    this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.white),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
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

class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}