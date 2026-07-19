import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/pages/home_page.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/entities/voting_session.dart';
import '../cubit/rating_cubit.dart';
import '../cubit/rating_state.dart';
import '../cubit/voting_state.dart';
import '../widgets/player_rating_card.dart';
import '../widgets/elo_result_display.dart';
import '../widgets/voting_card.dart';
import '../widgets/voting_result_dialog.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final _ratingCubit = getIt<RatingCubit>();
  final _profileCubit = getIt<ProfileCubit>();
  int _currentStep = 0;
  EloResult? _lastEloResult;

  static const _stepMeta = <_StepMeta>[
    _StepMeta(label: 'Đánh giá', icon: AppIcons.starFilled),
    _StepMeta(label: 'Kết quả', icon: AppIcons.elo),
    _StepMeta(label: 'Tổng kết', icon: AppIcons.info),
    _StepMeta(label: 'No-show', icon: AppIcons.busy),
  ];

  @override
  void initState() {
    super.initState();
    _ratingCubit.startRatingFlow('session_001');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _ratingCubit,
      child: BlocBuilder<RatingCubit, RatingState>(
        builder: (context, state) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              appBar: AppBar(
                title: Text(_getTitle()),
                automaticallyImplyLeading: false,
              ),
              body: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    return switch (_currentStep) {
      0 => 'Đánh giá đồng đội',
      1 => 'Nhập kết quả trận đấu',
      2 => 'Tổng kết trận đấu',
      3 => 'Bình chọn No-show',
      _ => 'Hoàn tất',
    };
  }

  Widget _buildBody(BuildContext context, RatingState state) {
    if (state is RatingLoading) {
      return _LoadingPanel(label: 'Đang xử lý...');
    }

    if (state is RatingFailure) {
      return _FailurePanel(
        message: state.message,
        onRetry: () => _ratingCubit.startRatingFlow('session_001'),
      );
    }

    if (state is KarmaRating) {
      return _buildKarmaRatingView(context, state);
    }

    if (state is MatchResultEntry) {
      return _buildMatchResultView(context, state);
    }

    if (state is EloResultDisplay) {
      _lastEloResult = state.eloResult;
      return _buildEloResultView(context, state);
    }

    if (state is RatingComplete && _currentStep == 3) {
      return _buildVotingView(context);
    }

    if (state is RatingComplete) {
      return _buildCompleteView(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildKarmaRatingView(BuildContext context, KarmaRating state) {
    return Column(
      children: [
        _StepProgress(
          currentStep: _currentStep.clamp(0, _stepMeta.length - 1),
          stepMeta: _stepMeta,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            itemCount: state.playersToRate.length,
            itemBuilder: (context, index) {
              final player = state.playersToRate[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PlayerRatingCard(
                  player: player,
                  availableTags: state.availableTags,
                  onTagToggle: (playerId, tagId) {
                    _ratingCubit.toggleKarmaTag(playerId, tagId);
                  },
                ),
              );
            },
          ),
        ),
        _BottomActionBar(
          child: FilledButton.icon(
            onPressed: () {
              _ratingCubit.submitKarmaRatings();
              setState(() => _currentStep = 1);
            },
            icon: const Icon(AppIcons.forward),
            label: const Text('Tiếp tục'),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchResultView(BuildContext context, MatchResultEntry state) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _StepProgress(
          currentStep: _currentStep.clamp(0, _stepMeta.length - 1),
          stepMeta: _stepMeta,
        ),
        if (state.isWaitingConsensus)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Đang chờ các thành viên khác xác nhận...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final theme = Theme.of(context);
                final wide = constraints.maxWidth >= 720;
                final choices = <Widget>[
                  _ResultChoiceCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Thắng',
                    description: 'Đội bạn thắng trận này',
                    color: theme.colorScheme.tertiary,
                    background: theme.colorScheme.tertiaryContainer,
                    onTap: () =>
                        _ratingCubit.submitMatchResult(MatchResult.win),
                  ),
                  _ResultChoiceCard(
                    icon: Icons.sentiment_dissatisfied_outlined,
                    label: 'Thua',
                    description: 'Đội bạn thua trận này',
                    color: theme.colorScheme.error,
                    background: theme.colorScheme.errorContainer,
                    onTap: () =>
                        _ratingCubit.submitMatchResult(MatchResult.lose),
                  ),
                  _ResultChoiceCard(
                    icon: Icons.handshake_outlined,
                    label: 'Hòa',
                    description: 'Hai bên ngang tài ngang sức',
                    color: theme.colorScheme.secondary,
                    background: theme.colorScheme.secondaryContainer,
                    onTap: () =>
                        _ratingCubit.submitMatchResult(MatchResult.draw),
                  ),
                ];

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kết quả trận đấu của bạn',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Chọn kết quả phù hợp với trận đấu vừa chơi',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        wide
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: choices
                                    .map(
                                      (c) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                          ),
                                          child: c,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : Column(children: choices),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton.icon(
                          onPressed: () {
                            _ratingCubit.skipMatchResult();
                            setState(() => _currentStep = 2);
                          },
                          icon: const Icon(AppIcons.forward, size: AppIcons.sm),
                          label: const Text('Bỏ qua (Game không xếp hạng)'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEloResultView(BuildContext context, EloResultDisplay state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _StepProgress(
            currentStep: _currentStep.clamp(0, _stepMeta.length - 1),
            stepMeta: _stepMeta,
          ),
          const SizedBox(height: AppSpacing.lg),
          EloResultDisplayWidget(
            eloResult: state.eloResult,
            onViewLeaderboard: () {},
            onComplete: () {
              _ratingCubit.checkPendingVotes();
              final votingState = _ratingCubit.votingState;
              if (votingState is VotingPending) {
                setState(() => _currentStep = 3);
              } else {
                _ratingCubit.completeRating();
                setState(() => _currentStep = 4);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVotingView(BuildContext context) {
    final votingState = _ratingCubit.votingState;

    if (votingState is VotingPending) {
      return _buildVotingPendingView(context, votingState);
    }

    if (votingState is VotingActive) {
      return _buildVotingActiveView(context, votingState);
    }

    if (votingState is VotingResult) {
      return const SizedBox.shrink();
    }

    if (votingState is VotingComplete) {
      return _buildCompleteView(context);
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildVotingPendingView(BuildContext context, VotingPending state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final warningColor = theme.brightness == Brightness.dark
        ? AppColorsDark.warning
        : AppColors.warning;

    return Column(
      children: [
        _StepProgress(
          currentStep: _currentStep.clamp(0, _stepMeta.length - 1),
          stepMeta: _stepMeta,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusMdAll,
                    border: Border.all(
                      color: warningColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: warningColor.withValues(alpha: 0.18),
                          borderRadius: AppRadius.radiusXxsAll,
                        ),
                        child: Icon(
                          AppIcons.warning,
                          color: warningColor,
                          size: AppIcons.md,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Có thành viên vắng mặt',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: warningColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${state.candidates.length} người có thể bị đánh dấu no-show. Cần ${state.threshold} phiếu để xác nhận.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Bình chọn người vắng mặt',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.candidates.map(
                  (candidate) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Material(
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.cardRadius,
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _ratingCubit.startVoting(candidate),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: AppSpacing.xl,
                                backgroundColor: colors.secondaryContainer,
                                foregroundColor: colors.onSecondaryContainer,
                                child: Text(
                                  candidate.name.isEmpty
                                      ? '?'
                                      : candidate.name.characters.first
                                            .toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onSecondaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  candidate.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colors.outline),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _ratingCubit.completeVoting();
                      setState(() => _currentStep = 4);
                    },
                    icon: const Icon(AppIcons.forward, size: AppIcons.sm),
                    label: const Text('Bỏ qua bình chọn'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingActiveView(BuildContext context, VotingActive state) {
    return Column(
      children: [
        _StepProgress(
          currentStep: _currentStep.clamp(0, _stepMeta.length - 1),
          stepMeta: _stepMeta,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bình chọn',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bạn có đồng ý rằng người này vắng mặt không?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                VotingCard(
                  candidate: VotingCandidate(
                    id: state.session.targetPlayerId,
                    name: state.session.targetPlayerName,
                    avatarUrl: state.session.targetPlayerAvatar,
                  ),
                  noShowVotes: state.session.noShowVotes,
                  notNoShowVotes: state.session.notNoShowVotes,
                  totalVoters: state.session.eligibleVoters.length,
                  remainingTime: state.session.remainingTime,
                  onVoteNoShow: () => _onVoteSubmitted(VoteType.noShow),
                  onVoteNotNoShow: () => _onVoteSubmitted(VoteType.notNoShow),
                  onSkip: () => _onVoteSubmitted(VoteType.skip),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onVoteSubmitted(VoteType vote) {
    _ratingCubit.submitVote(vote);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final votingState = _ratingCubit.votingState;
      if (votingState is VotingResult) {
        VotingResultDialog.show(
          context: context,
          noShowPlayers: votingState.noShowPlayers,
          attendedPlayers: votingState.attendedPlayers,
          onContinue: () {
            _ratingCubit.completeVoting();
            setState(() => _currentStep = 4);
          },
        );
      }
    });
  }

  Widget _buildCompleteView(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = theme.brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;

    _syncProfileToBackend();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.available,
                size: AppIcons.massive,
                color: successColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Cảm ơn bạn!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currentStep == 4
                  ? 'Đánh giá và bình chọn của bạn đã được gửi thành công.'
                  : 'Đánh giá của bạn đã được gửi thành công.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(AppIcons.home),
                label: const Text('Về trang chủ'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncProfileToBackend() {
    final elo = _lastEloResult;
    if (elo == null) return;
    _profileCubit.updateProgress(globalElo: elo.newElo, level: 1);
  }
}

class _StepMeta {
  final String label;
  final IconData icon;

  const _StepMeta({required this.label, required this.icon});
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  final List<_StepMeta> stepMeta;

  const _StepProgress({required this.currentStep, required this.stepMeta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        boxShadow: AppElevation.shadowXxs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(stepMeta.length, (index) {
              final meta = stepMeta[index];
              final isCompleted = currentStep > index;
              final isActive = currentStep == index;
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepNode(
                      meta: meta,
                      index: index,
                      isCompleted: isCompleted,
                      isActive: isActive,
                      compact: compact,
                    ),
                    if (index < stepMeta.length - 1)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.radiusFullAll,
                              color: isCompleted
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final _StepMeta meta;
  final int index;
  final bool isCompleted;
  final bool isActive;
  final bool compact;

  const _StepNode({
    required this.meta,
    required this.index,
    required this.isCompleted,
    required this.isActive,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isHighlighted = isCompleted || isActive;

    final node = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlighted
                ? colors.primary
                : colors.surfaceContainerHighest,
            border: Border.all(
              color: isHighlighted ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    AppIcons.check,
                    color: Colors.white,
                    size: AppIcons.md,
                  )
                : Icon(
                    meta.icon,
                    size: AppIcons.md,
                    color: isActive ? Colors.white : colors.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: compact ? 56 : 76,
          child: Text(
            '${index + 1}. ${meta.label}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isHighlighted ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: node,
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String label;

  const _LoadingPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailurePanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.error,
                size: AppIcons.massive,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã có lỗi xảy ra',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Widget child;

  const _BottomActionBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: AppElevation.shadowMd,
        ),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _ResultChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ResultChoiceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 160;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius,
              side: BorderSide(color: color.withValues(alpha: 0.32)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: AppIcons.xl, color: color),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: AppIcons.xl, color: color),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
