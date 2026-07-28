import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../../booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../../booking_payment/presentation/cubit/booking_result_state.dart';
import '../../../booking_payment/presentation/pages/booking_detail_page.dart';
import '../../../booking_payment/presentation/widgets/booking_summary_cards.dart';
import '../../../booking_payment/domain/entities/booking_entity.dart';
import '../../../booking_payment/domain/entities/booking_history_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../cubit/my_lobbies_state.dart';

/// Tab Lịch sử - Hiển thị phòng chờ của tôi và lịch sử đặt chỗ.
class LobbyHistoryTab extends StatelessWidget {
  final MyLobbiesCubit myLobbiesCubit;
  final BookingResultCubit bookingCubit;
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onTapLobby;
  final VoidCallback onRefresh;

  const LobbyHistoryTab({
    super.key,
    required this.myLobbiesCubit,
    required this.bookingCubit,
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
            child: _MyLobbiesSection(cubit: myLobbiesCubit, onTapLobby: onTapLobby),
          ),
          SliverToBoxAdapter(
            child: _UpcomingBookingsSection(cubit: bookingCubit),
          ),
          SliverToBoxAdapter(
            child: _BookingHistorySection(cubit: bookingCubit),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
                  Icon(Icons.meeting_room, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Phòng chờ của tôi',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildContent(BuildContext context, MyLobbiesState state, ThemeData theme, ColorScheme colors) {
    if (state is MyLobbiesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is MyLobbiesFailure) {
      return _SectionError(message: state.message);
    }

    if (state is MyLobbiesLoaded) {
      if (state.isEmpty) {
        return _SectionEmpty(
          icon: Icons.meeting_room_outlined,
          message: 'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
        );
      }

      return Column(
        children: [
          for (final lobby in state.joined)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistoryLobbyCard(
                lobby: lobby,
                isActive: true,
                onTap: () => onTapLobby(lobby),
              ),
            ),
          for (final lobby in state.hosted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistoryLobbyCard(
                lobby: lobby,
                isActive: false,
                onTap: () => onTapLobby(lobby),
              ),
            ),
        ],
      );
    }

    return _SectionEmpty(
      icon: Icons.meeting_room_outlined,
      message: 'Chưa có phòng chờ nào.',
    );
  }
}

class _HistoryLobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  final bool isActive;
  final VoidCallback onTap;

  const _HistoryLobbyCard({
    required this.lobby,
    required this.isActive,
    required this.onTap,
  });

  Color _getStatusColor(ThemeData theme) {
    switch (lobby.status) {
      case LobbyStatus.open:
        return theme.colorScheme.primary;
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

  String _getStatusText() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _getStatusColor(theme);

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isActive ? statusColor.withValues(alpha: 0.5) : colors.outlineVariant,
            ),
            boxShadow: AppElevation.shadowXxs,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusMdAll,
                ),
                child: Icon(
                  isActive ? Icons.sports_esports : Icons.meeting_room,
                  color: statusColor,
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
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: AppRadius.radiusXsAll,
                            ),
                            child: Text(
                              'HOẠT ĐỘNG',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')} • '
                          '${lobby.scheduledTime.day}/${lobby.scheduledTime.month}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: AppRadius.radiusXsAll,
                          ),
                          child: Text(
                            _getStatusText(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingBookingsSection extends StatelessWidget {
  final BookingResultCubit cubit;

  const _UpcomingBookingsSection({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<BookingResultCubit, BookingResultState>(
      bloc: cubit,
      builder: (context, state) {
        final upcoming = _extractUpcoming(state);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.event_available, color: colors.tertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Đặt chỗ sắp tới',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (upcoming.isEmpty)
                _SectionEmpty(
                  icon: Icons.event_busy,
                  message: 'Chưa có lịch hẹn nào.',
                )
              else
                for (final b in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: UpcomingBookingSummaryCard(
                      booking: b,
                      onChanged: () async {},
                      detailPageBuilder: (ctx, booking) => BookingDetailPage(booking: booking),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  List<BookingEntity> _extractUpcoming(BookingResultState state) {
    if (state is ResultUpcomingBookings) return state.bookings;
    if (state is ResultUpcomingAndHistory) return state.upcoming;
    return const [];
  }
}

class _BookingHistorySection extends StatelessWidget {
  final BookingResultCubit cubit;

  const _BookingHistorySection({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<BookingResultCubit, BookingResultState>(
      bloc: cubit,
      builder: (context, state) {
        final history = _extractHistory(state);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.history, color: colors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Lịch sử đặt chỗ',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (history.isEmpty)
                _SectionEmpty(
                  icon: Icons.history,
                  message: 'Chưa có lịch sử đặt chỗ.',
                )
              else
                for (final h in history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: HistoryBookingSummaryCard(item: h),
                  ),
            ],
          ),
        );
      },
    );
  }

  List<BookingHistoryEntity> _extractHistory(BookingResultState state) {
    if (state is ResultHistory) return state.items;
    if (state is ResultUpcomingAndHistory) return state.history;
    return const [];
  }
}

class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SectionEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
