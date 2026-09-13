import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Shared Empty State widget following Neo-Brutalism design pattern.
/// 
/// Use this widget when a list/section has no data to display.
/// The widget displays:
/// - A centered icon in a neo-brutalism circle/badge
/// - A bold title (uppercase)
/// - A descriptive message
/// - Optional action button
/// 
/// Usage:
/// ```dart
/// // Basic usage
/// return EmptyStateWidget(
///   icon: Icons.event_busy,
///   title: 'Chưa có lịch hẹn',
///   message: 'Hãy tạo lịch hẹn mới để bắt đầu.',
/// );
/// 
/// // With action button
/// return EmptyStateWidget(
///   icon: Icons.people_outline,
///   title: 'Chưa có bạn bè',
///   message: 'Tìm kiếm bạn bè để kết nối.',
///   actionLabel: 'Tìm kiếm',
///   actionIcon: Icons.search,
///   onAction: () => navigateToSearch(),
/// );
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display (default: `Icons.inbox_outlined`)
  final IconData icon;

  /// Title text (will be displayed in uppercase)
  final String title;

  /// Descriptive message below title
  final String message;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button icon
  final IconData? actionIcon;

  /// Callback when action button is pressed
  final VoidCallback? onAction;

  /// Custom icon size multiplier (default: 1.0)
  /// Use values > 1.0 for larger icons, < 1.0 for smaller
  final double iconScale;

  /// Use compact layout (less vertical spacing)
  final bool compact;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconScale = 1.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    final iconSize = AppIcons.xxl * iconScale;
    final iconPadding = AppSpacing.lg * iconScale;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container - Neo-Brutalism circle
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),

            // Title - uppercase bold
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),

            // Message - secondary color
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),

            // Action button (optional)
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              _ActionButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction!,
                borderColor: borderColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Neo-Brutalism filled action button for empty states.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color borderColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.white, size: AppIcons.sm),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRE-BUILT EMPTY STATES FOR COMMON USE CASES
// ════════════════════════════════════════════════════════════════════════════

/// Pre-configured empty state for reservation/booking screens.
class ReservationEmptyState extends StatelessWidget {
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onCreateReservation;

  const ReservationEmptyState({
    super.key,
    this.customTitle,
    this.customMessage,
    this.onCreateReservation,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.event_busy,
      title: customTitle ?? 'Chưa có lịch hẹn',
      message: customMessage ??
          'Hãy tạo lịch hẹn mới để bắt đầu trải nghiệm board game.',
      actionLabel: onCreateReservation != null ? 'Tạo lịch hẹn' : null,
      actionIcon: Icons.add,
      onAction: onCreateReservation,
    );
  }
}

/// Pre-configured empty state for lobby/waiting room screens.
class LobbyEmptyState extends StatelessWidget {
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onCreateLobby;

  const LobbyEmptyState({
    super.key,
    this.customTitle,
    this.customMessage,
    this.onCreateLobby,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.meeting_room_outlined,
      title: customTitle ?? 'Chưa có phòng chờ',
      message: customMessage ??
          'Hãy là người đầu tiên tạo phòng để mọi người cùng tham gia!',
      actionLabel: onCreateLobby != null ? 'Tạo phòng' : null,
      actionIcon: Icons.add,
      onAction: onCreateLobby,
    );
  }
}

/// Pre-configured empty state for friend management screens.
class FriendsEmptyState extends StatelessWidget {
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onSearchFriends;

  const FriendsEmptyState({
    super.key,
    this.customTitle,
    this.customMessage,
    this.onSearchFriends,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: customTitle ?? 'Chưa có bạn bè',
      message: customMessage ?? 'Tìm kiếm bạn bè để kết nối và mời chơi cùng.',
      actionLabel: onSearchFriends != null ? 'Tìm kiếm' : null,
      actionIcon: Icons.search,
      onAction: onSearchFriends,
    );
  }
}

/// Pre-configured empty state for friend requests.
class FriendRequestsEmptyState extends StatelessWidget {
  const FriendRequestsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.mark_email_read_outlined,
      title: 'Không có lời mời nào',
      message: 'Các lời mời kết bạn từ người khác sẽ hiển thị ở đây.',
    );
  }
}

/// Pre-configured empty state for search results with no results.
class SearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const SearchEmptyState({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Không tìm thấy kết quả',
      message: query.isNotEmpty
          ? 'Không có kết quả cho "$query".\nHãy thử từ khóa khác.'
          : 'Nhập từ khóa để tìm kiếm.',
      actionLabel: onClearSearch != null ? 'Xóa tìm kiếm' : null,
      actionIcon: Icons.clear,
      onAction: onClearSearch,
    );
  }
}

/// Pre-configured empty state for wallet/transaction history.
class WalletEmptyState extends StatelessWidget {
  final VoidCallback? onTopUp;

  const WalletEmptyState({super.key, this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'Chưa có giao dịch nào',
      message: 'Nạp BVC để bắt đầu sử dụng và xem lịch sử giao dịch tại đây.',
      actionLabel: onTopUp != null ? 'Nạp BVC' : null,
      actionIcon: Icons.add,
      onAction: onTopUp,
    );
  }
}

/// Pre-configured empty state for tournament/ELO history.
class TournamentHistoryEmptyState extends StatelessWidget {
  final VoidCallback? onBrowseTournaments;

  const TournamentHistoryEmptyState({
    super.key,
    this.onBrowseTournaments,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.emoji_events_outlined,
      title: 'Chưa có lịch sử thi đấu',
      message:
          'Tham gia giải đấu để xây dựng thứ hạng Elo và lịch sử thi đấu của bạn.',
      actionLabel: onBrowseTournaments != null ? 'Xem giải đấu' : null,
      actionIcon: Icons.emoji_events,
      onAction: onBrowseTournaments,
    );
  }
}

/// Pre-configured empty state for cafe list.
class CafeEmptyState extends StatelessWidget {
  final bool hasLocationPermission;
  final VoidCallback? onRetry;

  const CafeEmptyState({
    super.key,
    this.hasLocationPermission = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: hasLocationPermission
          ? Icons.storefront_outlined
          : Icons.location_off_rounded,
      title: hasLocationPermission
          ? 'Không có quán cafe nào'
          : 'Không thể tải quán cafe',
      message: hasLocationPermission
          ? 'Hãy thử lại sau hoặc thay đổi bộ lọc để xem thêm kết quả.'
          : 'Hãy bật vị trí trên profile hoặc thử lại sau nhé.',
      actionLabel: onRetry != null ? 'Thử lại' : null,
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}

/// Pre-configured empty state for board game list.
class BoardGameEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const BoardGameEmptyState({
    super.key,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.casino_outlined,
      title: 'Không có board game',
      message: 'Không tìm thấy board game phù hợp với bộ lọc hiện tại.',
      actionLabel: onClearFilters != null ? 'Xóa bộ lọc' : null,
      actionIcon: Icons.filter_alt_off,
      onAction: onClearFilters,
    );
  }
}

/// Pre-configured empty state for lobby invites.
class LobbyInvitesEmptyState extends StatelessWidget {
  const LobbyInvitesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.mail_outline,
      title: 'Không có lời mời nào',
      message: 'Lời mời tham gia phòng từ bạn bè sẽ xuất hiện ở đây.',
    );
  }
}

/// Pre-configured empty state for player check-in (no session).
class CheckInEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CheckInEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.hourglass_empty,
      title: 'Không có phiên chơi',
      message: 'Bạn chưa check-in tại quán.\nVui lòng đợi staff quét QR để bắt đầu.',
      actionLabel: onRefresh != null ? 'Làm mới' : null,
      actionIcon: Icons.refresh,
      onAction: onRefresh,
    );
  }
}
