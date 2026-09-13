import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../cubit/my_lobbies_state.dart';
import 'lobby_card_base.dart';

/// Tab "Của tôi" trong Lobby Hub — chỉ hiển thị danh sách phòng chờ
/// mà user đã tạo hoặc tham gia (gồm cả lobby liên kết tới reservation).
///
/// Sau khi booking_payment (VND/SePay) bị xoá, các section
/// "Đặt chỗ sắp tới" và "Lịch sử đặt chỗ" không còn cần thiết — chúng
/// được thay thế bằng tab Bookings mới (hiển thị reservation + lobby).
class LobbyHistoryTab extends StatelessWidget {
  final MyLobbiesCubit myLobbiesCubit;
  final void Function(LobbyEntity) onTapLobby;
  final VoidCallback onRefresh;

  /// Callback khi player bấm nút "Tạo phòng" từ empty state. `null` nếu
  /// không muốn hiển thị action button trong empty state (vd: page chỉ
  /// hiển thị danh sách không cho phép tạo mới).
  final VoidCallback? onCreateLobby;

  const LobbyHistoryTab({
    super.key,
    required this.myLobbiesCubit,
    required this.onTapLobby,
    required this.onRefresh,
    this.onCreateLobby,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeaderSection(
              theme: Theme.of(context),
              colors: Theme.of(context).colorScheme,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            sliver: _MyLobbiesSliver(
              cubit: myLobbiesCubit,
              onTapLobby: onTapLobby,
              onCreateLobby: onCreateLobby,
              onRetry: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nội dung lobby list — return sliver widget theo từng state.
class _MyLobbiesSliver extends StatelessWidget {
  final MyLobbiesCubit cubit;
  final void Function(LobbyEntity) onTapLobby;

  /// Callback khi player bấm nút "Tạo phòng" từ empty state.
  final VoidCallback? onCreateLobby;

  /// Callback khi player bấm "Thử lại" từ error state.
  final VoidCallback onRetry;

  const _MyLobbiesSliver({
    required this.cubit,
    required this.onTapLobby,
    this.onCreateLobby,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
      bloc: cubit,
      builder: (context, state) {
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, MyLobbiesState state) {
    if (state is MyLobbiesLoading) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 265,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _HistoryItemSkeleton(),
          childCount: 4,
        ),
      );
    }
    if (state is MyLobbiesFailure) {
      return SliverToBoxAdapter(
        child: SizedBox(
          // Đặt chiều cao tối thiểu để ErrorStateWidget có không gian
          // hiển thị đẹp khi list ngắn / đang trong tab có nhiều padding.
          height: 480,
          child: ErrorStateWidget(
            message: state.message,
            onRetry: onRetry,
            compact: true,
          ),
        ),
      );
    }
    if (state is MyLobbiesLoaded) {
      if (state.isEmpty) {
        return SliverToBoxAdapter(
          child: SizedBox(
            // Đặt chiều cao tối thiểu để LobbyEmptyState có không gian
            // hiển thị đẹp khi list rỗng trong tab "Phòng chờ của tôi".
            height: 480,
            child: LobbyEmptyState(
              customTitle: 'Chưa có phòng chờ của tôi',
              customMessage:
                  'Bạn chưa tạo hoặc tham gia phòng chờ nào.\nHãy tạo phòng mới hoặc khám phá các phòng đang mở để tham gia.',
              onCreateLobby: onCreateLobby,
            ),
          ),
        );
      }
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 265,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final isJoined = index < state.joined.length;
            final lobby = isJoined
                ? state.joined[index]
                : state.hosted[index - state.joined.length];
            return _HistoryLobbyCard(
              lobby: lobby,
              isJoined: isJoined,
              onTap: () => onTapLobby(lobby),
            );
          },
          childCount: state.joined.length + state.hosted.length,
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 480,
        child: const LobbyEmptyState(
          customTitle: 'Chưa có phòng chờ',
          customMessage: 'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
        ),
      ),
    );
  }
}

class _HistoryLobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  final bool isJoined;
  final VoidCallback onTap;

  const _HistoryLobbyCard({
    required this.lobby,
    required this.isJoined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyCardBase(
      item: lobbyItemFromEntity(
        lobby,
        isOwnedByMe: !isJoined,
      ),
      onTap: onTap,
      layout: LobbyCardLayout.vertical,
    );
  }
}

/// Header section for "Phòng chờ của tôi".
class _HeaderSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _HeaderSection({required this.theme, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withAlpha(204)],
              ),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: const Icon(Icons.meeting_room, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng chờ của tôi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Phòng đã tạo hoặc tham gia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton tile cho history section — match layout của _HistoryLobbyCard.
class _HistoryItemSkeleton extends StatelessWidget {
  const _HistoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork cover placeholder
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.casino_rounded,
                  size: 42,
                  color: Colors.white30,
                ),
              ),
            ),
            // Content — match vertical card padding/sizes
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Cafe placeholder
                    Container(
                      width: 80,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Time chip placeholder (2-row stacked: date + time)
                    Container(
                      width: 140,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    // Share code pill placeholder — full width
                    Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Hint line placeholder
                    Container(
                      width: 120,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

