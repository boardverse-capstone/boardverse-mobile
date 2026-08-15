import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/utils/current_user_resolver.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_detail_state.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_engagement_cubit.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_engagement_state.dart';
import 'package:boardverse/features/tournament/presentation/tabs/tournament_info_tab.dart';
import 'package:boardverse/features/tournament/presentation/tabs/tournament_participants_tab.dart';
import 'package:boardverse/features/tournament/presentation/tabs/tournament_matches_tab.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_error_state.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_skeleton.dart';

/// Full-page view of a single tournament with three tabs:
/// 1) Info + Register/Withdraw
/// 2) Participants list (taps open ParticipantDetailPage)
/// 3) Matches / Brackets (taps open MatchDetailPage)
class TournamentDetailPage extends StatelessWidget {
  final String tournamentId;
  final TournamentEntity? initialTournament;
  final TournamentDetailCubit? cubit;
  final TournamentEngagementCubit? engagementCubit;

  const TournamentDetailPage({
    super.key,
    required this.tournamentId,
    this.initialTournament,
    this.cubit,
    this.engagementCubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<TournamentDetailCubit>.value(value: cubit!),
          BlocProvider<TournamentEngagementCubit>(
            create: (_) =>
                engagementCubit ??
                getIt<TournamentEngagementCubit>()..load(tournamentId),
          ),
        ],
        child: _TournamentDetailView(initialTournament: initialTournament),
      );
    }

    return _TournamentDetailLoader(
      tournamentId: tournamentId,
      initialTournament: initialTournament,
    );
  }
}

class _TournamentDetailLoader extends StatefulWidget {
  final String tournamentId;
  final TournamentEntity? initialTournament;

  const _TournamentDetailLoader({
    required this.tournamentId,
    this.initialTournament,
  });

  @override
  State<_TournamentDetailLoader> createState() =>
      _TournamentDetailLoaderState();
}

class _TournamentDetailLoaderState extends State<_TournamentDetailLoader> {
  late final Future<String?> _userIdFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = getIt<CurrentUserResolver>().resolveUserId();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: SafeArea(child: TournamentSkeleton.detailPage()),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<TournamentDetailCubit>(
              create: (_) => getIt<TournamentDetailCubit>()
                ..loadDetail(widget.tournamentId,
                    currentUserId: snapshot.data),
            ),
            BlocProvider<TournamentEngagementCubit>(
              create: (_) => getIt<TournamentEngagementCubit>()
                ..load(widget.tournamentId),
            ),
          ],
          child: _TournamentDetailView(
            initialTournament: widget.initialTournament,
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

        // Listen riêng cho EngagementCubit để show toast cho các action
        // waitlist / spectator. Đặt trong builder để có context sau khi
        // provider đã wire xong.
        return MultiBlocListener(
          listeners: [
            BlocListener<TournamentEngagementCubit, TournamentEngagementState>(
              listenWhen: (prev, curr) =>
                  curr is TournamentEngagementSuccessNotice ||
                  curr is TournamentEngagementError,
              listener: (ctx, engState) {
                if (engState is TournamentEngagementSuccessNotice) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusSmAll,
                      ),
                      content: Text(engState.message),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else if (engState is TournamentEngagementError) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusSmAll,
                      ),
                      content: Text(engState.message),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
          child: _buildScaffold(
            context: context,
            theme: theme,
            state: state,
            tournament: tournament,
            participants: participants,
            matches: matches,
            isRegistering: isRegistering,
            title: tournament?.title ?? 'Chi tiết giải đấu',
          ),
        );
      },
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required ThemeData theme,
    required TournamentDetailState state,
    required TournamentEntity? tournament,
    required List<TournamentParticipantEntity> participants,
    required List<TournamentMatchEntity> matches,
    required bool isRegistering,
    required String title,
  }) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              final cubit = context.read<TournamentDetailCubit>();
              if (cubit.currentTournamentId != null) {
                cubit.loadDetail(
                  cubit.currentTournamentId!,
                  currentUserId: _resolveCurrentUserId(state),
                );
              }
              // Đồng thời refresh waitlist + spectator state.
              final engagementCubit =
                  context.read<TournamentEngagementCubit>();
              if (engagementCubit.currentTournamentId != null) {
                engagementCubit.load(
                  engagementCubit.currentTournamentId!,
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
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
      body: tournament == null
          ? state is TournamentDetailError
              ? TournamentErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<TournamentDetailCubit>().refresh(),
                )
              : TournamentSkeleton.detailBody()
          : TabBarView(
              controller: _tabController,
              children: [
                TournamentInfoTab(
                  tournament: tournament,
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
    TournamentDetailState state,
  ) {
    if (state is TournamentDetailLoaded) return state.participants;
    if (state is TournamentDetailRegistering) return state.participants;
    if (state is TournamentDetailError) return state.participants ?? const [];
    return const [];
  }

  List<TournamentMatchEntity> _resolveMatches(TournamentDetailState state) {
    if (state is TournamentDetailLoaded) return state.matches;
    if (state is TournamentDetailRegistering) return state.matches;
    if (state is TournamentDetailError) return state.matches ?? const [];
    return const [];
  }

  String? _resolveCurrentUserId(TournamentDetailState state) {
    if (state is TournamentDetailLoaded) return state.tournament.isUserRegistered ? 'current_user' : null;
    if (state is TournamentDetailRegistering) return state.tournament.isUserRegistered ? 'current_user' : null;
    return null;
  }
}
