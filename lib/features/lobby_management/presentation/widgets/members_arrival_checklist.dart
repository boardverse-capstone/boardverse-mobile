import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';

/// Trạng thái arrival của từng member trong lobby (self-report).
enum MemberArrivalStatus {
  unknown,
  enRoute,
  arrived,
  checkedIn,
}

extension MemberArrivalStatusX on MemberArrivalStatus {
  String get displayName {
    switch (this) {
      case MemberArrivalStatus.unknown:
        return 'Chưa rõ';
      case MemberArrivalStatus.enRoute:
        return 'Đang đến';
      case MemberArrivalStatus.arrived:
        return 'Đã đến';
      case MemberArrivalStatus.checkedIn:
        return 'Đã check-in';
    }
  }

  Color get color {
    switch (this) {
      case MemberArrivalStatus.unknown:
        return AppColors.textTertiary;
      case MemberArrivalStatus.enRoute:
        return AppColors.warning;
      case MemberArrivalStatus.arrived:
        return AppColors.info;
      case MemberArrivalStatus.checkedIn:
        return AppColors.success;
    }
  }

  IconData get icon {
    switch (this) {
      case MemberArrivalStatus.unknown:
        return Icons.help_outline_rounded;
      case MemberArrivalStatus.enRoute:
        return Icons.directions_car_rounded;
      case MemberArrivalStatus.arrived:
        return Icons.location_on_rounded;
      case MemberArrivalStatus.checkedIn:
        return Icons.check_circle_rounded;
    }
  }
}

/// Card hiển thị cho host: tổng hợp arrival status của từng member trong
/// lobby. Neo-brutalism style với bold border + hard shadow.
class MembersArrivalChecklist extends StatelessWidget {
  final List<LobbyPlayer> players;
  final Map<String, MemberArrivalStatus> arrivalByUserId;
  final bool isHostView;

  /// Optional — nếu `false` (player đang xem chính mình), chỉ show 1 dòng.
  final bool showFullList;

  const MembersArrivalChecklist({
    super.key,
    required this.players,
    required this.arrivalByUserId,
    this.isHostView = true,
    this.showFullList = true,
  });

  int _countWhere(MemberArrivalStatus target) {
    return arrivalByUserId.values.where((s) => s == target).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final checkedIn = _countWhere(MemberArrivalStatus.checkedIn);
    final enRoute = _countWhere(MemberArrivalStatus.enRoute);
    final arrived = _countWhere(MemberArrivalStatus.arrived);
    final unknown = _countWhere(MemberArrivalStatus.unknown);
    final total = players.length;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isHostView ? 'Trạng thái các thành viên' : 'Trạng thái của bạn',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Summary chips row
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              _summaryChip(context, MemberArrivalStatus.checkedIn, '$checkedIn'),
              _summaryChip(context, MemberArrivalStatus.arrived, '$arrived'),
              _summaryChip(context, MemberArrivalStatus.enRoute, '$enRoute'),
              _summaryChip(context, MemberArrivalStatus.unknown, '$unknown'),
            ],
          ),
          if (showFullList && isHostView) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 2,
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...players.map((p) {
              final status =
                  arrivalByUserId[p.userId] ?? MemberArrivalStatus.unknown;
              return _MemberRow(player: p, status: status);
            }),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(
    BuildContext context,
    MemberArrivalStatus status,
    String count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
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
          Icon(status.icon, color: AppColors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final LobbyPlayer player;
  final MemberArrivalStatus status;
  const _MemberRow({required this.player, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, color: AppColors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  status.displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
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