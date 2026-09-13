import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/lobby_left_signal.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_search_cubit.dart';
import '../../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../../features/lobby_management/presentation/pages/lobby_hub_page.dart';
import '../../theme/app_colors.dart';
import '../../di/injection.dart';

/// Lobbies page - quản lý phòng chờ (tạo, tham gia, lịch sử).
///
/// Listen [LobbyLeftSignal] để reload dữ liệu khi user rời khỏi lobby
/// (bấm "Rời phòng" trên LobbyPage). Tránh để player thấy UI cũ chưa
/// được cập nhật sau khi trở về tab Lobbies.
class LobbiesPage extends StatefulWidget {
  const LobbiesPage({super.key});

  @override
  State<LobbiesPage> createState() => _LobbiesPageState();
}

class _LobbiesPageState extends State<LobbiesPage> {
  @override
  void initState() {
    super.initState();
    // Listen signal "user vừa rời lobby" → reload cả Explore list + My Lobbies
    // tab để user thấy thông tin mới nhất ngay khi quay về.
    LobbyLeftSignal.instance.addListener(_handleLobbyLeft);
  }

  @override
  void dispose() {
    LobbyLeftSignal.instance.removeListener(_handleLobbyLeft);
    super.dispose();
  }

  void _handleLobbyLeft() {
    if (!mounted) return;
    // Reload Explore tab — bỏ lobby vừa rời khỏi list (optimistic removal).
    context.read<LobbySearchCubit>().loadDiscoverable(limit: 50);
    // Reload "Của tôi" tab — hiển thị lobby vừa rời (user vẫn là member).
    context.read<MyLobbiesCubit>().load(null);
  }

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
