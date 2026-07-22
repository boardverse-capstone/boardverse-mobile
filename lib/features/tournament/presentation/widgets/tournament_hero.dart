import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_list_state.dart';

/// Hero header cho tab Tournament — chỉ hiển thị background gradient
/// + icon trang trí + tiêu đề "Giải đấu" ngắn gọn. Các text thừa
/// ("Cạnh tranh. Kết nối. Chiến thắng." / subtitle / metrics) đã bỏ
/// để tránh dài dòng — title được render bởi SliverAppBar's
/// FlexibleSpaceBar.title ở dưới overlay.
class TournamentHero extends StatelessWidget {
  final TournamentListState state;

  const TournamentHero({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, AppColors.primaryDark, 0.35) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background orb decoration
          Positioned(
            top: -44,
            right: -24,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Background icon (decorative, không có label text)
          Positioned(
            top: 72,
            right: 32,
            child: Icon(
              AppIcons.tournament,
              size: AppIcons.xxl,
              color: onPrimary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}
