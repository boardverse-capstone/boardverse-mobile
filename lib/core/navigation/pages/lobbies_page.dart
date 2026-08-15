import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import '../../../features/lobby_management/presentation/pages/lobby_hub_page.dart';
import '../../theme/app_colors.dart';
import '../../di/injection.dart';

/// Lobbies page - quản lý phòng chờ (tạo, tham gia, lịch sử)
class LobbiesPage extends StatelessWidget {
  const LobbiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<LobbyInviteCubit>(
      create: (_) => getIt<LobbyInviteCubit>(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: const LobbyHubPage(),
      ),
    );
  }
}
