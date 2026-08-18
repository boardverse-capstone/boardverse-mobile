import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../cubit/cafe_detail_cubit.dart';
import '../cubit/cafe_detail_state.dart';
import '../cubit/matchmaking_cubit.dart';
import '../widgets/cafe_detail/cafe_detail_shimmer.dart';
import '../widgets/cafe_detail/cafe_detail_view.dart';

/// Trang xem chi tiết quán cafe.
///
/// User tap vào CafeCard → vào đây xem thông tin quán.
/// Từ đây mới có CTA để đặt lobby.
///
/// Hỗ trợ 2 flow:
/// 1. Chọn cafe từ tab Cafe → ấn "Đặt chỗ" → chọn game trong quán
/// 2. Chọn game trước → chọn cafe → đi thẳng sang LobbyCafeSelectionPage
class CafeDetailPage extends StatelessWidget {
  final String cafeId;
  final BoardGameEntity? selectedGame;
  final CafeEntity? cafeEntity;
  final MatchmakingCubit matchmakingCubit;

  /// Query text đang được search ở SearchPage. Dùng để restore lại kết
  /// quả search cafe khi player back từ flow đặt chỗ (cubit state đã bị
  /// thay đổi bởi LobbyConfigPage → không còn là CafeSearchResults nữa).
  final String? searchQuery;

  const CafeDetailPage({
    super.key,
    required this.cafeId,
    this.selectedGame,
    this.cafeEntity,
    required this.matchmakingCubit,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CafeDetailCubit(matchmakingCubit.repository)..loadCafeDetail(cafeId),
      child: Scaffold(
        body: BlocBuilder<CafeDetailCubit, CafeDetailState>(
          builder: (context, state) {
            if (state is CafeDetailLoading) {
              return const CafeDetailShimmer();
            }

            if (state is CafeDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }

            if (state is CafeDetailLoaded) {
              return CafeDetailView(
                cafe: state.cafe,
                selectedGame: selectedGame,
                cafeEntity: cafeEntity,
                matchmakingCubit: matchmakingCubit,
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}