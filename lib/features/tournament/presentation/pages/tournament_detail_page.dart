import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/current_user_resolver.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/tabs/tournament_info_tab.dart';
import 'package:boardverse_mobile/features/tournament/presentation/tabs/tournament_participants_tab.dart';
import 'package:boardverse_mobile/features/tournament/presentation/tabs/tournament_matches_tab.dart';

/// Full-page view of a single tournament with three tabs:
/// 1) Info + Register/Withdraw
/// 2) Participants list (taps open ParticipantDetailPage)
/// 3) Matches / Brackets (taps open MatchDetailPage)
class TournamentDetailPage extends StatelessWidget {
  final String tournamentId;
  final TournamentEntity? initialTournament;
  final TournamentDetailCubit? cubit;

  const TournamentDetailPage({
    super.key,
    required this.tournamentId,
    this.initialTournament,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<TournamentDetailCubit>.value(
        value: cubit!,
        child: _TournamentDetailView(
          initialTournament: initialTournament,
        ),
      );
    }
    return FutureBuilder<String?>(
      future: getIt<CurrentUserResolver>().resolveUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data;
        return BlocProvider<TournamentDetailCubit>(
          create: (_) {
            final cubit = getIt<TournamentDetailCubit>();
            cubit.loadDetail(tournamentId, currentUserId: userId);
            return cubit;
          },
          child: _TournamentDetailView(
            initialTournament: initialTournament,
          ),
        );
      },
    );
  }
}

class _TournamentDetailView extends StatefulWidget {
  final TournamentEntity? initialTournament;
  const _TournamentDetailView({this.initialTournament});

  @override
  State<_TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<_TournamentDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TournamentDetailCubit, TournamentDetailState>(
      listenWhen: (prev, curr) =>
          curr is TournamentDetailActionSuccess ||
          curr is TournamentDetailError,
      listener: (ctx, state) {
        if (state is TournamentDetailActionSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSmAll,
              ),
              content: Text(state.message),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is TournamentDetailError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSmAll,
              ),
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final tournament = _resolveTournament(state, widget.initialTournament);
        final participants = _resolveParticipants(state);
        final matches = _resolveMatches(state);
        final isRegistering = state is TournamentDetailRegistering;
        final isLoading = state is TournamentDetailLoading ||
            state is TournamentDetailActionSuccess;

        final title = tournament?.title ?? 'Chi tiết giải đấu';

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: theme.colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  tabs: [
                    const Tab(text: 'Thông tin'),
                    Tab(text: 'Người tham gia (${participants.length})'),
                    Tab(text: 'Bàn đấu (${matches.length})'),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading && tournament == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    TournamentInfoTab(
                      tournament: tournament!,
                      isRegistering: isRegistering,
                      onRegister: () => context
                          .read<TournamentDetailCubit>()
                          .register(tournament.id),
                      onUnregister: () => context
                          .read<TournamentDetailCubit>()
                          .unregister(tournament.id),
                    ),
                    TournamentParticipantsTab(
                      tournamentId: tournament.id,
                      participants: participants,
                    ),
                    TournamentMatchesTab(
                      tournamentId: tournament.id,
                      matches: matches,
                    ),
                  ],
                ),
        );
      },
    );
  }

  TournamentEntity? _resolveTournament(
    TournamentDetailState state,
    TournamentEntity? initial,
  ) {
    if (state is TournamentDetailLoaded) return state.tournament;
    if (state is TournamentDetailRegistering) return state.tournament;
    if (state is TournamentDetailError) return state.tournament ?? initial;
    return initial;
  }

  List<TournamentParticipantEntity> _resolveParticipants(
      TournamentDetailState state) {
    if (state is TournamentDetailLoaded) return state.participants;
    if (state is TournamentDetailRegistering) return state.participants;
    if (state is TournamentDetailError) return state.participants ?? const [];
    return const [];
  }

  List<TournamentMatchEntity> _resolveMatches(
      TournamentDetailState state) {
    if (state is TournamentDetailLoaded) return state.matches;
    if (state is TournamentDetailRegistering) return state.matches;
    if (state is TournamentDetailError) return state.matches ?? const [];
    return const [];
  }
}