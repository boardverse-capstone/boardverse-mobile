import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
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
  int _currentStep = 0;

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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang xử lý...'),
          ],
        ),
      );
    }

    if (state is RatingFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _ratingCubit.startRatingFlow('session_001'),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is KarmaRating) {
      return _buildKarmaRatingView(context, state);
    }

    if (state is MatchResultEntry) {
      return _buildMatchResultView(context, state);
    }

    if (state is EloResultDisplay) {
      return _buildEloResultView(context, state);
    }

    // Voting step
    if (state is RatingComplete && _currentStep == 3) {
      return _buildVotingView(context);
    }

    if (state is RatingComplete) {
      return _buildCompleteView(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildKarmaRatingView(BuildContext context, KarmaRating state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress Indicator (4 steps)
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildStepIndicator(0, 'Đánh giá', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(1, 'Kết quả', false),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(2, 'Tổng kết', false),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(3, 'No-show', false),
            ],
          ),
        ),

        // Content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.playersToRate.length,
            itemBuilder: (context, index) {
              final player = state.playersToRate[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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

        // Bottom Action
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _ratingCubit.submitKarmaRatings();
                  setState(() => _currentStep = 1);
                },
                child: const Text('Tiếp tục'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchResultView(BuildContext context, MatchResultEntry state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress Indicator (4 steps)
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildStepIndicator(0, 'Đánh giá', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(1, 'Kết quả', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(2, 'Tổng kết', false),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(3, 'No-show', false),
            ],
          ),
        ),

        if (state.isWaitingConsensus)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kết quả trận đấu của bạn',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn kết quả phù hợp với trận đấu vừa chơi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultButton(
                          icon: Icons.emoji_events,
                          label: 'Thắng',
                          color: Colors.green,
                          onTap: () =>
                              _ratingCubit.submitMatchResult(MatchResult.win),
                        ),
                        _ResultButton(
                          icon: Icons.sentiment_dissatisfied,
                          label: 'Thua',
                          color: Colors.red,
                          onTap: () =>
                              _ratingCubit.submitMatchResult(MatchResult.lose),
                        ),
                        _ResultButton(
                          icon: Icons.handshake,
                          label: 'Hòa',
                          color: Colors.blue,
                          onTap: () =>
                              _ratingCubit.submitMatchResult(MatchResult.draw),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        _ratingCubit.skipMatchResult();
                        setState(() => _currentStep = 2);
                      },
                      child: const Text('Bỏ qua (Game không xếp hạng)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEloResultView(BuildContext context, EloResultDisplay state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EloResultDisplayWidget(
            eloResult: state.eloResult,
            onViewLeaderboard: () {},
            onComplete: () {
              // Check if there are no-show candidates
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
    return Column(
      children: [
        // Progress Indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildStepIndicator(0, 'Đánh giá', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(1, 'Kết quả', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(2, 'Tổng kết', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.outline),
              ),
              _buildStepIndicator(3, 'No-show', true),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Có thành viên vắng mặt',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.candidates.length} người có thể bị đánh dấu no-show. Cần ${state.threshold} phiếu để xác nhận.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bình chọn người vắng mặt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.candidates.map((candidate) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () => _ratingCubit.startVoting(candidate),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                candidate.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                candidate.name,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      _ratingCubit.completeVoting();
                      setState(() => _currentStep = 4);
                    },
                    child: const Text('Bỏ qua bình chọn'),
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
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress Indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildStepIndicator(0, 'Đánh giá', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(1, 'Kết quả', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(2, 'Tổng kết', true),
              Expanded(
                child: Container(height: 2, color: theme.colorScheme.primary),
              ),
              _buildStepIndicator(3, 'No-show', true),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bình chọn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có đồng ý rằng người này vắng mặt không?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
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

    // Check if voting result is ready
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
            const SizedBox(height: 24),
            Text(
              'Cảm ơn bạn!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep == 4
                  ? 'Đánh giá và bình chọn của bạn đã được gửi thành công.'
                  : 'Đánh giá của bạn đã được gửi thành công.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    final theme = Theme.of(context);
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
