import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
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
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onTapLobby;
  final VoidCallback onRefresh;

  const LobbyHistoryTab({
    super.key,
    required this.myLobbiesCubit,
    required this.timeFormatter,
    required this.onTapLobby,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _MyLobbiesSection(
              cubit: myLobbiesCubit,
              onTapLobby: onTapLobby,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }
}

class _MyLobbiesSection extends StatelessWidget {
  final MyLobbiesCubit cubit;
  final void Function(LobbyEntity) onTapLobby;

  const _MyLobbiesSection({required this.cubit, required this.onTapLobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
      bloc: cubit,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: AppSpacing.md),
              _buildContent(context, state, theme, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    MyLobbiesState state,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (state is MyLobbiesLoading) {
      // Phase 3 2026-08-10: thay spinner bằng shimmer skeleton list.
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const _HistoryItemSkeleton(),
      );
    }
    if (state is MyLobbiesFailure) return _SectionError(message: state.message);
    if (state is MyLobbiesLoaded) {
      if (state.isEmpty) {
        return _SectionEmpty(
          icon: Icons.meeting_room_outlined,
          message: 'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
          colors: colors,
          theme: theme,
        );
      }
      return Column(
        children: [
          for (final lobby in state.joined)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistoryLobbyCard(
                lobby: lobby,
                isJoined: true,
                onTap: () => onTapLobby(lobby),
              ),
            ),
          for (final lobby in state.hosted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistoryLobbyCard(
                lobby: lobby,
                isJoined: false,
                onTap: () => onTapLobby(lobby),
              ),
            ),
        ],
      );
    }
    return _SectionEmpty(
      icon: Icons.meeting_room_outlined,
      message: 'Chưa có phòng chờ nào.',
      colors: colors,
      theme: theme,
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
    // Đồng bộ UI với `ReservationCard` — dùng chung `LobbyCardBase`.
    // Boolean `isJoined` ở đây trở thành "hosted by me" flag cho
    // `isOwnedByMe` trên card (viền primary).
    return LobbyCardBase(
      item: lobbyItemFromEntity(
        lobby,
        isOwnedByMe: !isJoined,
      ),
      onTap: onTap,
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final ColorScheme colors;
  final ThemeData theme;

  const _SectionEmpty({
    required this.icon,
    required this.message,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;

  const _SectionError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Game icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMdAll,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 200,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 120,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Status pill
            Container(
              width: 70,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusSmAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}