import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
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

/// Neo-brutalism rating page.
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
          child: _NeoFilledButton(
            label: 'Tiếp tục',
            icon: AppIcons.forward,
            color: AppColors.primary,
            onPressed: () {
              _ratingCubit.submitKarmaRatings();
              setState(() => _currentStep = 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchResultView(BuildContext context, MatchResultEntry state) {
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
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Đang chờ các thành viên khác xác nhận...',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final choices = <Widget>[
                  _ResultChoiceCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Thắng',
                    description: 'Đội bạn thắng trận này',
                    color: AppColors.warning,
                    onTap: () =>
                        _ratingCubit.submitMatchResult(MatchResult.win),
                  ),
                  _ResultChoiceCard(
                    icon: Icons.sentiment_dissatisfied_outlined,
                    label: 'Thua',
                    description: 'Đội bạn thua trận này',
                    color: AppColors.error,
                    onTap: () =>
                        _ratingCubit.submitMatchResult(MatchResult.lose),
                  ),
                  _ResultChoiceCard(
                    icon: Icons.handshake_outlined,
                    label: 'Hòa',
                    description: 'Hai bên ngang tài ngang sức',
                    color: AppColors.info,
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
                        const Text(
                          'Kết quả trận đấu của bạn',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Chọn kết quả phù hợp với trận đấu vừa chơi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
                          icon: const Icon(AppIcons.forward, size: 14),
                          label: const Text(
                            'Bỏ qua (Game không xếp hạng)',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textSecondary,
                            ),
                          ),
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

    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 4,
      ),
    );
  }

  Widget _buildVotingPendingView(BuildContext context, VotingPending state) {
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
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.4),
                        blurRadius: 0,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          AppIcons.warning,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Có thành viên vắng mặt',
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.candidates.length} người có thể bị đánh dấu no-show. Cần ${state.threshold} phiếu để xác nhận.',
                              style: const TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Bình chọn người vắng mặt',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.candidates.map(
                  (candidate) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _NeoCandidateTile(
                      candidate: candidate,
                      onTap: () => _ratingCubit.startVoting(candidate),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _NeoOutlineButton(
                  label: 'Bỏ qua bình chọn',
                  icon: AppIcons.forward,
                  color: AppColors.info,
                  onPressed: () {
                    _ratingCubit.completeVoting();
                    setState(() => _currentStep = 4);
                  },
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
                const Text(
                  'Bình chọn',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Bạn có đồng ý rằng người này vắng mặt không?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.available,
                size: 64,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Cảm ơn bạn!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currentStep == 4
                  ? 'Đánh giá và bình chọn của bạn đã được gửi thành công.'
                  : 'Đánh giá của bạn đã được gửi thành công.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _NeoFilledButton(
              label: 'Về trang chủ',
              icon: AppIcons.home,
              color: AppColors.primary,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => route.isFirst,
                );
              },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
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
                          padding: const EdgeInsets.only(top: 18),
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isCompleted
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
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
            color:
                isHighlighted ? AppColors.primary : AppColors.textTertiary,
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(AppIcons.check,
                    color: AppColors.white, size: 18)
                : Icon(
                    meta.icon,
                    size: 18,
                    color: isActive
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.7),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: compact ? 56 : 76,
          child: Text(
            '${index + 1}. ${meta.label}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: node,
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String label;

  const _LoadingPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  AppIcons.error,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Đã có lỗi xảy ra',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeoFilledButton(
                label: 'Thử lại',
                icon: AppIcons.refresh,
                color: AppColors.primary,
                onPressed: onRetry,
              ),
            ],
          ),
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
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(0, -3),
            ),
          ],
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
  final VoidCallback onTap;

  const _ResultChoiceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 160;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 28, color: AppColors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              description,
                              style: TextStyle(
                                color: AppColors.white
                                    .withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 28, color: AppColors.white),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white
                                  .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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

/// Neo-brutalism candidate tile (used in voting pending view).
class _NeoCandidateTile extends StatelessWidget {
  final VotingCandidate candidate;
  final VoidCallback onTap;

  const _NeoCandidateTile({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    candidate.name.isEmpty
                        ? '?'
                        : candidate.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  candidate.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism filled button.
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism outline button.
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}