import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../pages/lobby_auto_match_page.dart';
import '../pages/lobby_create_by_cafe_page.dart';

/// Bottom sheet chọn entry-point khi player bấm "Tạo lobby".
///
/// Nguyên tắc UX:
/// - Câu hỏi dẫn dắt player tự đối chiếu với nhu cầu thay vì đọc chữ "entry-point".
/// - Auto-match đứng đầu + badge "Nhanh nhất" — giải quyết 80% case (player
///   vào app chưa có kế hoạch gì).
/// - Mỗi option là 1 câu hỏi + 1 dòng giải thích ngắn (≤ 12 từ) để player
///   đọc trong 2 giây và tự chọn.
class LobbyCreateEntrySheet extends StatelessWidget {
  /// "Tôi đã biết muốn chơi game nào" — flow cũ: chọn game → chọn quán.
  final VoidCallback onPickGameFirst;

  const LobbyCreateEntrySheet({super.key, required this.onPickGameFirst});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPickGameFirst,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          LobbyCreateEntrySheet(onPickGameFirst: onPickGameFirst),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
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
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bạn muốn chơi với ai?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn 1 cách bắt đầu phù hợp nhất.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 1. Auto-match (RECOMMENDED) ─────────────────────────────────
            _EntryOption(
              icon: Icons.shuffle,
              iconColor: theme.colorScheme.primary,
              title: 'Cho tôi ghép với người khác',
              subtitle: 'Hệ thống tự tìm phòng đang mở gần bạn.',
              badge: 'Nhanh nhất',
              badgeColor: theme.colorScheme.primary,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LobbyAutoMatchPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 2. Chọn game trước ─────────────────────────────────────────
            _EntryOption(
              icon: Icons.casino,
              iconColor: theme.colorScheme.secondary,
              title: 'Tôi đã biết muốn chơi game nào',
              subtitle: 'Chọn game → hệ thống tìm quán có sẵn hộp.',
              onTap: () {
                Navigator.of(context).pop();
                onPickGameFirst();
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 3. Chọn quán trước ─────────────────────────────────────────
            _EntryOption(
              icon: Icons.local_cafe,
              iconColor: theme.colorScheme.tertiary,
              title: 'Tôi đã biết quán muốn tới',
              subtitle: 'Chọn quán → chọn game tại quán.',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LobbyCreateByCafePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _EntryOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? iconColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
