import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Nút lưu/bỏ lưu board game — hiển thị icon heart.
///
/// Dùng optimistic update:
/// 1. Đọc isSaved từ SavedGamesCubit (cache local).
/// 2. Tap → gọi cubit.toggleSave(id).
/// 3. Cubit tự động sync cache + revert nếu API lỗi.
///
/// Chỉ hiển thị khi user đã đăng nhập.
class SaveButton extends StatelessWidget {
  final String gameTemplateId;
  final bool isSaved;
  final VoidCallback onToggle;
  final double size;
  final Color? activeColor;

  const SaveButton({
    super.key,
    required this.gameTemplateId,
    required this.isSaved,
    required this.onToggle,
    this.size = 24,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(isSaved),
          size: size,
          color: isSaved
              ? (activeColor ?? AppColors.error)
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}
