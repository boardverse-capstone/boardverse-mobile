import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../domain/entities/lobby_invite_entity.dart';

/// Modern lobby invite card với neo-brutalism style: bold borders, hard shadows,
/// gradient header và styled action buttons.
class LobbyInviteCard extends StatelessWidget {
  final LobbyInviteEntity invite;
  final bool isInvitee;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  /// Callback cho action "Gửi lại" (chỉ dành cho terminal state invites).
  final VoidCallback? onResend;

  final bool isLoading;

  /// Card có cần hiển thị row info chips (cafe + member count + expiry) hay
  /// không. Nếu cả 3 field đều null thì bỏ qua row để tránh khoảng trống
  /// thừa (vd: DTO mới không trả nested `lobby` + chưa phải pending).
  static bool _hasInfoChip(LobbyInviteEntity invite) {
    final hasCafe =
        invite.cafeName != null && invite.cafeName!.isNotEmpty;
    final hasMembers =
        invite.currentMembers != null && invite.maxMembers != null;
    final hasExpiry = invite.status == LobbyInviteStatus.pending &&
        invite.remainingTime.inMinutes > 0;
    return hasCafe || hasMembers || hasExpiry;
  }

  const LobbyInviteCard({
    super.key,
    required this.invite,
    this.isInvitee = true,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.onResend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Header with gradient ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: invite.inviterAvatar.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              invite.inviterAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => Center(
                                child: Text(
                                  invite.inviterName.isNotEmpty
                                      ? invite.inviterName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              invite.inviterName.isNotEmpty
                                  ? invite.inviterName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInvitee
                              ? '${invite.inviterName} mời bạn'
                              : 'Lời mời đã gửi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            fontSize: 15,
                          ),
                        ),
                        // Chỉ hiển thị tên game khi server trả về non-null
                        // (BR-NEW-12: DTO mới có thể bỏ qua khi host
                        // chưa publish lobby detail). Tránh fallback "Board Game".
                        if (invite.gameName != null &&
                            invite.gameName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            invite.gameName!,
                            style: TextStyle(
                              color:
                                  AppColors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusBadge(status: invite.status),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Message
                  if (invite.message != null && invite.message!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              invite.message!,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Info chips — chỉ render khi field có data từ server.
                  // Trước đây luôn hiển thị "Quán" + "1/4" fallback làm
                  // card rối khi DTO mới không trả nested `lobby`.
                  if (_hasInfoChip(invite)) ...[
                    Row(
                      children: [
                        if (invite.cafeName != null &&
                            invite.cafeName!.isNotEmpty) ...[
                          _InfoChip(
                              icon: AppIcons.cafe, label: invite.cafeName!),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (invite.currentMembers != null &&
                            invite.maxMembers != null) ...[
                          _InfoChip(
                            icon: AppIcons.users,
                            label:
                                '${invite.currentMembers}/${invite.maxMembers}',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        const Spacer(),
                        if (invite.status == LobbyInviteStatus.pending &&
                            invite.remainingTime.inMinutes > 0)
                          _ExpiryChip(remaining: invite.remainingTime),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Action buttons
                  if (invite.status == LobbyInviteStatus.pending &&
                      invite.isActive) ...[
                    const SizedBox(height: AppSpacing.md),
                    // `hasSlots` trả về null khi thiếu data member counts.
                    // Mặc định hiển thị CTA "Tham gia/Từ chối" — chỉ
                    // show "Phòng đã đầy" khi server xác nhận currentMembers
                    // >= maxMembers (false). Null = unknown → show CTA.
                    if (isInvitee && (invite.hasSlots ?? true))
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineActionButton(
                              label: 'Từ chối',
                              icon: AppIcons.cancelBooking,
                              color: AppColors.error,
                              onPressed: isLoading ? null : onDecline,
                              isLoading: isLoading,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: _FilledActionButton(
                              label: 'Tham gia',
                              icon: AppIcons.userAdd,
                              color: AppColors.primary,
                              onPressed: isLoading ? null : onAccept,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      )
                    else if (!isInvitee)
                      SizedBox(
                        width: double.infinity,
                        child: _OutlineActionButton(
                          label: 'Hủy lời mời',
                          icon: AppIcons.cancelBooking,
                          color: AppColors.error,
                          onPressed: isLoading ? null : onCancel,
                          isLoading: isLoading,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(AppIcons.warning,
                                size: 18, color: AppColors.black),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Phòng đã đầy',
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else if (!isInvitee && invite.canResend) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: _OutlineActionButton(
                        label: 'Gửi lại lời mời',
                        icon: AppIcons.refresh,
                        color: AppColors.info,
                        onPressed: isLoading ? null : onResend,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LobbyInviteStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, fg, label) = switch (status) {
      LobbyInviteStatus.pending => (
        AppColors.white,
        AppColors.primary,
        'Chờ',
      ),
      LobbyInviteStatus.accepted => (
        AppColors.success,
        AppColors.white,
        'Đã chấp nhận',
      ),
      LobbyInviteStatus.declined => (
        AppColors.error,
        AppColors.white,
        'Đã từ chối',
      ),
      LobbyInviteStatus.cancelled => (
        AppColors.error,
        AppColors.white,
        'Đã hủy',
      ),
      LobbyInviteStatus.expired => (
        AppColors.textTertiary,
        AppColors.white,
        'Hết hạn',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
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
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final Duration remaining;

  const _ExpiryChip({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUrgent = remaining.inHours < 1;
    final color = isUrgent ? AppColors.warning : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.timer,
            size: 12,
            color: isUrgent ? AppColors.black : AppColors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Còn ${_format(remaining)}',
            style: TextStyle(
              color: isUrgent ? AppColors.black : AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}p';
    return '${d.inSeconds}s';
  }
}

/// Neo-brutalism filled action button.
class _FilledActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _FilledActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              else ...[
                Icon(icon, size: 16, color: AppColors.white),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism outline action button.
class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}