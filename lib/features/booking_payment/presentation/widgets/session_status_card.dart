import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/session_member_entity.dart';
import '../../domain/entities/session_status_entity.dart';

/// Card realtime session-status (gap #8) — poll mỗi 30s khi booking ở
/// `CheckedIn`. Hiển thị: thành viên nào về sớm, bill ước tính cuối cùng.
class SessionStatusCard extends StatelessWidget {
  final SessionStatusEntity session;

  const SessionStatusCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppElevation.shadowXxs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.16),
                    AppColors.success.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: AppColors.success,
                    size: AppIcons.md,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Phiên chơi đang diễn ra',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${session.currentDurationMinutes} phút',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thành viên (${session.members.length})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...session.members.map((m) => _buildMemberRow(context, m)),
                  if (session.estimatedFinalBill != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bill ước tính cuối cùng',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _billLine(context, 'Tiền chơi', session.estimatedFinalBill!.subtotal),
                    _billLine(
                      context,
                      'Phụ thu',
                      session.estimatedFinalBill!.penalty,
                      color: AppColors.warning,
                    ),
                    _billLine(
                      context,
                      'Cọc đã áp dụng',
                      session.estimatedFinalBill!.depositApplied,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 4),
                    _billLine(
                      context,
                      'Tổng',
                      session.estimatedFinalBill!.total,
                      bold: true,
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

  Widget _buildMemberRow(BuildContext context, dynamic member) {
    final theme = Theme.of(context);
    final isLeft = member.status == SessionMemberStatus.leftEarly ||
        member.status == SessionMemberStatus.checkedOut;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isLeft
                ? Icons.logout_rounded
                : Icons.sports_esports_rounded,
            size: 16,
            color: isLeft
                ? AppColors.warning
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              member.username,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLeft ? AppColors.warning : null,
                decoration: isLeft ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isLeft && member.partialBillAmount > 0)
            Text(
              _formatVnd(member.partialBillAmount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _billLine(BuildContext context, String label, double amount,
      {Color? color, bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _formatVnd(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(double amount) {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf đ';
  }
}