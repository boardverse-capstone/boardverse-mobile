import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../cubit/my_lobbies_state.dart';

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
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

  Color _statusColor(ThemeData theme) {
    final successColor =
        theme.brightness == Brightness.dark ? AppColorsDark.success : AppColors.success;
    switch (lobby.status) {
      case LobbyStatus.open:
        return successColor;
      case LobbyStatus.full:
      case LobbyStatus.inProgress:
        return theme.colorScheme.tertiary;
      case LobbyStatus.ratingOpen:
        return AppColors.info;
      case LobbyStatus.closed:
      case LobbyStatus.timeoutFailed:
      case LobbyStatus.hostCancelled:
        return theme.colorScheme.error;
    }
  }

  String _statusText() {
    switch (lobby.status) {
      case LobbyStatus.open:
        return 'Đang tuyển';
      case LobbyStatus.full:
        return 'Đã đầy';
      case LobbyStatus.inProgress:
        return 'Đang chơi';
      case LobbyStatus.ratingOpen:
        return 'Đánh giá';
      case LobbyStatus.closed:
        return 'Đã đóng';
      case LobbyStatus.timeoutFailed:
        return 'Hết hạn';
      case LobbyStatus.hostCancelled:
        return 'Đã huỷ';
    }
  }

  bool get _isActive =>
      lobby.status == LobbyStatus.open ||
      lobby.status == LobbyStatus.full ||
      lobby.status == LobbyStatus.inProgress ||
      lobby.status == LobbyStatus.ratingOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(theme);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: _isActive ? statusColor.withValues(alpha: 0.4) : colors.outlineVariant,
        ),
        boxShadow: AppElevation.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusLgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusLgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withAlpha(204)],
                    ),
                    borderRadius: AppRadius.radiusMdAll,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isActive ? Icons.sports_esports : Icons.meeting_room_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lobby.gameName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, statusColor.withAlpha(204)],
                                ),
                                borderRadius: AppRadius.radiusFullAll,
                              ),
                              child: Text(
                                'HOẠT ĐỘNG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')} • '
                            '${lobby.scheduledTime.day}/${lobby.scheduledTime.month}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.radiusFullAll,
                            ),
                            child: Text(
                              _statusText(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
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