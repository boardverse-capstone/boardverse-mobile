import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../features/reservation/domain/entities/entities.dart';
import '../../../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../../../features/lobby_management/presentation/cubit/my_lobbies_state.dart';
import '../../../../features/lobby_management/domain/entities/lobby_entity.dart';

/// Tab "Lịch đặt" — hiển thị lịch sử reservation + lobby của user.
///
/// Sau khi flow SePay/booking-payment cũ bị xoá, tab này đổi sang dùng
/// Reservation API (`/api/v1/reservations`) + `MyLobbiesCubit` để hiển thị
/// tất cả phòng chờ mà user đã tạo/tham gia (bao gồm cả reservation).
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  /// Backward-compat — các caller cũ (MainScaffold) gọi `requestRefresh`
  /// khi user double-tap tab. Hiện tại không cần vì cả reservation list lẫn
  /// lobby list đều auto-load khi build.
  static void requestRefresh(BuildContext context) {}

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late final ReservationRepository _reservationRepo;
  late final MyLobbiesCubit _myLobbiesCubit;

  late final Future<List<_ReservationRow>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationRepo = sl<ReservationRepository>();
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _reservationsFuture = _loadReservations();
    _myLobbiesCubit.load(null);
  }

  Future<List<_ReservationRow>> _loadReservations() async {
    final result = await _reservationRepo.getReservations(pageSize: 50);
    return result.fold((_) => const <_ReservationRow>[], (page) {
      return page.items
          .map((r) => _ReservationRow(reservation: r))
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _reservationsFuture = _loadReservations();
          });
          await _myLobbiesCubit.load(null);
          await _reservationsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            _SectionTitle(
              icon: Icons.event_note,
              title: 'Lịch đặt của tôi',
              subtitle: 'Các đơn reservation đã tạo qua BVC',
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<_ReservationRow>>(
              future: _reservationsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingPlaceholder();
                }
                final rows = snap.data ?? const <_ReservationRow>[];
                if (rows.isEmpty) {
                  return const _EmptyPlaceholder(
                    icon: Icons.event_busy,
                    message: 'Bạn chưa tạo đơn reservation nào.',
                  );
                }
                return Column(
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ReservationCard(row: r),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              icon: Icons.meeting_room,
              title: 'Phòng chờ của tôi',
              subtitle: 'Phòng đã tạo hoặc tham gia',
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
              bloc: _myLobbiesCubit,
              builder: (context, state) {
                if (state is MyLobbiesLoading) {
                  return const _LoadingPlaceholder();
                }
                if (state is MyLobbiesFailure) {
                  return _ErrorPlaceholder(message: state.message);
                }
                if (state is MyLobbiesLoaded) {
                  final lobbies = <LobbyEntity>[...state.joined, ...state.hosted];
                  if (lobbies.isEmpty) {
                    return const _EmptyPlaceholder(
                      icon: Icons.meeting_room_outlined,
                      message: 'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
                    );
                  }
                  return Column(
                    children: [
                      for (final l in lobbies)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _LobbyCard(lobby: l),
                        ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

class _ReservationRow {
  final ReservationEntity reservation;
  const _ReservationRow({required this.reservation});
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Icon(icon, color: colors.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
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

class _ReservationCard extends StatelessWidget {
  final _ReservationRow row;
  const _ReservationCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final r = row.reservation;
    final time = DateFormat('HH:mm • dd/MM').format(r.scheduledTime.toLocal());
    final statusColor = _statusColor(colors, r.status);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowSm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.gameName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusFullAll,
                ),
                child: Text(
                  r.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(icon: Icons.storefront, text: r.cafeName),
          _InfoRow(icon: Icons.schedule, text: time),
          _InfoRow(
            icon: Icons.confirmation_number,
            text: 'Cọc: ${r.finalDeposit} BVC',
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme colors, ReservationStatus status) {
    if (status.isTerminal) return colors.error;
    if (status.isActive) return colors.primary;
    return AppColors.warning;
  }
}

class _LobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  const _LobbyCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final time = DateFormat('HH:mm • dd/MM').format(lobby.scheduledTime.toLocal());
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowSm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lobby.gameName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(icon: Icons.storefront, text: lobby.cafeName),
          _InfoRow(icon: Icons.schedule, text: time),
          _InfoRow(
            icon: Icons.group,
            text: '${lobby.currentPlayers}/${lobby.maxPlayers} người',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
          Icon(icon, color: colors.onSurfaceVariant),
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

class _ErrorPlaceholder extends StatelessWidget {
  final String message;
  const _ErrorPlaceholder({required this.message});

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
          Icon(Icons.error_outline, color: colors.onErrorContainer),
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