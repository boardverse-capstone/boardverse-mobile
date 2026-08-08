import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../features/lobby_management/domain/entities/lobby_entity.dart';
import '../../../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../../../features/lobby_management/presentation/cubit/my_lobbies_state.dart';
import '../../../../features/reservation/presentation/pages/reservation_list_page.dart';

/// Tab "Lịch đặt" — hiển thị lịch sử reservation + lobby của user.
///
/// Phần reservation được tách sang feature `reservation` qua
/// `ReservationListPage`; tab này chỉ chịu trách nhiệm render lobby list
/// (vì lobby list UI thuộc `lobby_management`).
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
  late final MyLobbiesCubit _myLobbiesCubit;

  @override
  void initState() {
    super.initState();
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _myLobbiesCubit.load(null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _myLobbiesCubit.load(null);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            // Reservation list — UI thuộc feature reservation.
            const ReservationListPage(),
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
                  return _ErrorBox(message: state.message);
                }
                if (state is MyLobbiesLoaded) {
                  final lobbies =
                      <LobbyEntity>[...state.joined, ...state.hosted];
                  if (lobbies.isEmpty) {
                    return const _EmptyBox(
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

// ─── Helpers (lobby list) ─────────────────────────────────────────────────

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

class _LobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  const _LobbyCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final time =
        DateFormat('HH:mm • dd/MM').format(lobby.scheduledTime.toLocal());
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

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyBox({required this.icon, required this.message});

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

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

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