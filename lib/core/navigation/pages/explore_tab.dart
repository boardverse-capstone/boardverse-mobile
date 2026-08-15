import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/pages/search_page.dart';
import '../../theme/app_colors.dart';

/// Explore tab - tìm quán cafe, board games, và lobby public
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Khám phá',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        // Reload đã bỏ — player kéo xuống (pull-to-refresh) trong SearchPage
        // để refresh cả Boardgame lẫn Cafe tab.
      ),
      body: _ExploreContent(),
    );
  }
}

/// Wraps SearchPage so the explore tab can resolve the matchmaking cubit
/// from its own BlocProvider scope (it is provided by the parent MultiBloc
/// in main.dart).
class _ExploreContent extends StatelessWidget {
  const _ExploreContent();

  @override
  Widget build(BuildContext context) {
    return SearchPage(matchmakingCubit: context.read<MatchmakingCubit>());
  }
}
