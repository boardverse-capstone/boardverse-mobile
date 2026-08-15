import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_engagement_cubit.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_engagement_state.dart';

/// Panel hiển thị Waitlist (T-03) + Spectator (T-04) ngay trong tab Info
/// của [TournamentDetailPage]. Auto-switch giữa các state dựa trên
/// [TournamentEngagementCubit] mà widget cha cung cấp.
///
/// UI tham chiếu design system Neo-Brutalism: border đậm, hard shadow,
/// bo góc vuông vức, màu vibrant. Tất cả copy tiếng Việt dễ hiểu.
class TournamentEngagementPanel extends StatelessWidget {
  const TournamentEngagementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentEngagementCubit, TournamentEngagementState>(
      builder: (context, state) {
        if (state is TournamentEngagementInitial ||
            state is TournamentEngagementLoading) {
          return const _EngagementSkeleton();
        }
        if (state is TournamentEngagementError) {
          return _EngagementError(
            message: state.message,
            onRetry: () {
              final cubit = context.read<TournamentEngagementCubit>();
              final id = cubit.currentTournamentId;
              if (id != null) cubit.load(id);
            },
          );
        }

        // TournamentEngagementLoaded / ActionInProgress đều render UI
        // tương tự (chỉ khác ở việc disable button).
        final loaded = state is TournamentEngagementLoaded
            ? state
            : (state is TournamentEngagementActionInProgress
                ? state
                : null);
        if (loaded == null) return const SizedBox.shrink();

        final inProgress = state is TournamentEngagementActionInProgress;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SpectatorCard(
              mySpectator: loaded.mySpectator,
              inProgress: inProgress,
            ),
            const SizedBox(height: AppSpacing.sm),
            _WaitlistCard(
              myWaitlist: loaded.myWaitlist,
              inProgress: inProgress,
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Spectator
// ═══════════════════════════════════════════════════════════════════════════

class _SpectatorCard extends StatelessWidget {
  final MySpectatorStatus mySpectator;
  final bool inProgress;

  const _SpectatorCard({
    required this.mySpectator,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpectating = mySpectator.isSpectating;
    final cubit = context.read<TournamentEngagementCubit>();

    return NeoPanel(
      accentColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBadge(icon: Icons.visibility_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Theo dõi giải đấu',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              NeoStatusPill(
                label: isSpectating ? 'Đang theo dõi' : 'Chưa theo dõi',
                color: isSpectating
                    ? AppColors.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSpectating
                ? 'Bạn sẽ nhận thông báo khi có vòng đấu mới hoặc kết quả được cập nhật.'
                : 'Theo dõi giải để xem diễn biến các vòng đấu và bảng xếp hạng trực tiếp. Không cần đăng ký làm người chơi.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (isSpectating && mySpectator.entry?.joinedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Đã theo dõi từ ${_formatDate(mySpectator.entry!.joinedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          NeoPrimaryButton(
            label: isSpectating ? 'Ngừng theo dõi' : 'Theo dõi',
            icon: isSpectating
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            background: isSpectating
                ? theme.colorScheme.surfaceContainerHighest
                : AppColors.info,
            textColor: isSpectating
                ? theme.colorScheme.onSurface
                : AppColors.white,
            loading: inProgress,
            onPressed: inProgress
                ? null
                : () {
                    if (isSpectating) {
                      cubit.stopSpectating();
                    } else {
                      cubit.startSpectating();
                    }
                  },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Waitlist
// ═══════════════════════════════════════════════════════════════════════════

class _WaitlistCard extends StatelessWidget {
  final MyWaitlistStatus myWaitlist;
  final bool inProgress;

  const _WaitlistCard({
    required this.myWaitlist,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<TournamentEngagementCubit>();

    if (!myWaitlist.isInWaitlist) {
      return NeoPanel(
        accentColor: AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NeoIconBadge(icon: Icons.hourglass_top_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Danh sách chờ',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khi giải đã đầy người, bạn có thể tham gia danh sách chờ. '
              'Khi có người rút lui, hệ thống sẽ tự động mời bạn vào giải.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            NeoPrimaryButton(
              label: 'Tham gia danh sách chờ',
              icon: Icons.hourglass_top_outlined,
              background: AppColors.warning,
              textColor: AppColors.white,
              loading: inProgress,
              onPressed: inProgress ? null : cubit.joinWaitlist,
            ),
          ],
        ),
      );
    }

    // Đã trong waitlist — render theo status.
    final status = myWaitlist.status ?? WaitlistEntryStatus.waiting;
    switch (status) {
      case WaitlistEntryStatus.waiting:
        return _WaitingCard(
          myWaitlist: myWaitlist,
          inProgress: inProgress,
        );
      case WaitlistEntryStatus.promoted:
        return _OfferCard(
          myWaitlist: myWaitlist,
          inProgress: inProgress,
        );
      case WaitlistEntryStatus.expired:
      case WaitlistEntryStatus.cancelled:
        return NeoPanel(
          accentColor: theme.colorScheme.outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeoIconBadge(icon: Icons.history_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Danh sách chờ — ${status.displayLabel}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                status == WaitlistEntryStatus.expired
                    ? 'Offer đã hết hạn do bạn không phản hồi kịp. Bạn có thể vào lại danh sách chờ nếu vẫn muốn tham gia.'
                    : 'Bạn đã rời/từ chối khỏi danh sách chờ của giải này.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ],
          ),
        );
    }
  }
}

class _WaitingCard extends StatelessWidget {
  final MyWaitlistStatus myWaitlist;
  final bool inProgress;

  const _WaitingCard({
    required this.myWaitlist,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<TournamentEngagementCubit>();
    final pos = myWaitlist.position;

    return NeoPanel(
      accentColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBadge(icon: Icons.hourglass_top_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Bạn đang ở vị trí thứ ${pos ?? "?"}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              NeoStatusPill(
                label: 'Đang chờ',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hệ thống sẽ tự động mời bạn vào giải khi có người chơi rút lui. '
            'Bạn có thể rời danh sách chờ bất kỳ lúc nào trước khi nhận offer.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (myWaitlist.joinedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tham gia từ ${_formatDate(myWaitlist.joinedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          NeoPrimaryButton(
            label: 'Rời danh sách chờ',
            icon: Icons.exit_to_app_outlined,
            background: theme.colorScheme.surfaceContainerHighest,
            textColor: theme.colorScheme.onSurface,
            loading: inProgress,
            onPressed: inProgress ? null : cubit.leaveWaitlist,
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final MyWaitlistStatus myWaitlist;
  final bool inProgress;

  const _OfferCard({
    required this.myWaitlist,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<TournamentEngagementCubit>();
    final deadline = myWaitlist.promotionDeadline;

    return NeoPanel(
      accentColor: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBadge(icon: Icons.celebration_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Có suất dành cho bạn!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              NeoStatusPill(
                label: 'Đã mời',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bạn vừa được thăng cấp từ danh sách chờ lên người chơi. '
            'Xác nhận để giữ chỗ, hoặc từ chối nếu không muốn tham gia.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (deadline != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hạn phản hồi: ${_formatDate(deadline)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child:               NeoPrimaryButton(
                label: 'Xác nhận',
                icon: Icons.check_circle_outline,
                background: AppColors.success,
                textColor: AppColors.white,
                loading: inProgress,
                onPressed:
                    inProgress ? null : cubit.confirmWaitlistOffer,
              ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NeoPrimaryButton(
                  label: 'Từ chối',
                  icon: Icons.cancel_outlined,
                  background: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurface,
                  loading: inProgress,
                  onPressed:
                      inProgress ? null : cubit.declineWaitlistOffer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sub-widgets: skeleton / error
// ═══════════════════════════════════════════════════════════════════════════

class _EngagementSkeleton extends StatelessWidget {
  const _EngagementSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBlock(theme: theme, color: AppColors.info),
        const SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(theme: theme, color: AppColors.warning),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final ThemeData theme;
  final Color color;

  const _SkeletonBlock({required this.theme, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: color, width: 2),
        borderRadius: AppRadius.radiusMdAll,
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _EngagementError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EngagementError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeoPanel(
      accentColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBadge(icon: Icons.error_outline),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Không tải được thông tin',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          NeoPrimaryButton(
            label: 'Thử lại',
            icon: Icons.refresh_outlined,
            background: AppColors.error,
            textColor: AppColors.white,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════════

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year} $hh:$mi';
}