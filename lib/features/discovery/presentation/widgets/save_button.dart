import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Nút lưu/bỏ lưu board game — hiển thị icon bookmark.
///
/// Dùng optimistic update:
/// 1. Đọc isSaved từ SavedGamesCubit (cache local).
/// 2. Tap → gọi cubit.toggleSave(id).
/// 3. Cubit tự động sync cache + revert nếu API lỗi.
///
/// Chỉ hiển thị khi user đã đăng nhập.
///
/// **Đồng bộ với `_CardSaveButton` (recommended_game_card.dart) và
/// `_HeaderSaveButton` (game_detail_header.dart)**: cùng dùng bookmark
/// icon (filled = saved, outline = unsaved), cùng neo-brutalism visual
/// style (white circle + black border + hard offset shadow). Lý do:
/// user nhận diện cùng 1 control dù context khác nhau, không cần phải
/// học lại icon semantics ở mỗi màn hình.
///
/// **Note**: File này hiện không được sử dụng trong code production
/// (orphan, chỉ còn reference ở `presentation.dart` barrel export).
/// Nội dung được giữ cho trường hợp cần reuse trong tương lai, đã
/// được cập nhật từ heart icon (cũ) sang bookmark icon (mới) để khớp
/// với phần còn lại của discovery feature.
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
    this.size = 18,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(isSaved),
          size: size,
          // Cố định màu đen — đồng bộ với `_HeaderSaveButton` và
          // `_CardSaveButton` mới. Trước đây dùng màu error (đỏ) cho
          // saved state → không nhất quán với neo-brutalism header style.
          color: AppColors.black,
        ),
      ),
    );
  }
}
