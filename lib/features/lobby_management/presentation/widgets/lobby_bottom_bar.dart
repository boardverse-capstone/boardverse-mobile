import 'package:flutter/material.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';

/// Bottom bar của LobbyPage.
///
/// Phân biệt rõ 2 action:
/// - **"Rời phòng"** (member thường + host): chỉ pop UI — cho phép user
///   tạm ra ngoài dùng tính năng khác của app, KHÔNG gọi API. User có
///   thể vào lại lobby bất cứ lúc nào qua tab "Đang tham gia".
/// - **"Huỷ phòng"** (chỉ host, khi `onCancel != null`): gọi API
///   `POST /lobbies/{id}/close` — đóng lobby thật sự, status = Closed.
///   Không thể join lại. Có dialog xác nhận trước khi thực thi.
///
/// Hai action dùng icon khác nhau + màu khác nhau để tránh nhầm lẫn
/// nghiệp vụ (trước đây host bấm "Rời phòng" → server tự động chuyển
/// status thành `HostCancelled` do `POST /leave` → mọi join về sau đều
/// trả 409).
class LobbyBottomBar extends StatelessWidget {
  /// Callback "Rời phòng" — chỉ pop UI, không gọi API.
  final VoidCallback onLeave;

  /// Callback "Huỷ phòng" — chỉ truyền cho Host. Khi `null`, nút này
  /// ẩn đi (member thường không có quyền đóng lobby).
  final VoidCallback? onCancel;

  const LobbyBottomBar({
    super.key,
    required this.onLeave,
    this.onCancel,
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
        // 2 nút cạnh nhau nếu host, 1 nút full-width nếu member thường.
        child: Row(
          children: [
            // ── "Rời phòng" — pop UI, không gọi API ───────────────
            Expanded(
              flex: onCancel != null ? 1 : 2,
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
            // ── "Huỷ phòng" — chỉ host, gọi API /close ────────────
            if (onCancel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 1,
                child: FilledButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(AppIcons.cancelBooking, size: 18),
                  label: const Text('Huỷ phòng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMdAll,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}