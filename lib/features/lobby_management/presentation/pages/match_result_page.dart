import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/current_user_resolver.dart';
import '../cubit/match_result_cubit.dart';
import '../cubit/match_result_state.dart';
import '../widgets/outcome_selector.dart';
import '../widgets/consensus_status_card.dart';

class MatchResultPage extends StatefulWidget {
  final MatchResultCubit matchResultCubit;
  final String lobbyId;
  final String gameName;

  /// Optional override; nếu trống sẽ resolve từ JWT qua
  /// [CurrentUserResolver.resolveUserId].
  final String currentUserId;
  final VoidCallback? onComplete;

  const MatchResultPage({
    super.key,
    required this.matchResultCubit,
    required this.lobbyId,
    required this.gameName,
    this.currentUserId = '',
    this.onComplete,
  });

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

class _MatchResultPageState extends State<MatchResultPage> {
  String? _resolvedUserId;

  @override
  void initState() {
    super.initState();
    widget.matchResultCubit.loadMatchResult(widget.lobbyId);
    if (widget.currentUserId.isEmpty) {
      _resolveCurrentUser();
    }
  }

  Future<void> _resolveCurrentUser() async {
    final id = await getIt<CurrentUserResolver>().resolveUserId();
    if (!mounted) return;
    setState(() => _resolvedUserId = id);
  }

  String get _effectiveUserId =>
      widget.currentUserId.isNotEmpty ? widget.currentUserId : (_resolvedUserId ?? '');

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchResultCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đánh giá trận đấu'),
        ),
        body: BlocConsumer<MatchResultCubit, MatchResultState>(
          listener: (context, state) {
            if (state is MatchResultError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is MatchResultFinalized) {
              // Show success dialog
              _showFinalizedDialog(context, state);
            }
          },
          builder: (context, state) {
            if (state is MatchResultLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MatchResultError) {
              return _ErrorState(
                message: state.message,
                onRetry: () => widget.matchResultCubit.loadMatchResult(widget.lobbyId),
              );
            }

            if (state is MatchResultLoaded ||
                state is MatchResultSubmitted ||
                state is MatchResultConflict ||
                state is MatchResultFinalized) {
              final result = state is MatchResultLoaded
                  ? state.result
                  : state is MatchResultSubmitted
                      ? state.result
                      : state is MatchResultFinalized
                          ? state.result
                          : (state as MatchResultConflict).result;
              final selectedOutcome = state is MatchResultLoaded
                  ? state.selectedOutcome
                  : state is MatchResultSubmitted
                      ? state.submittedOutcome
                      : null;
              final isSubmitting = state is MatchResultLoaded && state.isSubmitting;

              return _buildResultContent(
                context,
                result,
                selectedOutcome,
                isSubmitting,
                state is MatchResultFinalized ? state : null,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildResultContent(
    BuildContext context,
    dynamic result,
    dynamic selectedOutcome,
    bool isSubmitting, [
    MatchResultFinalized? finalizedState,
  ]) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game info header
          Card(
            elevation: AppElevation.elevationSm,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.radiusSmAll,
                    ),
                    child: Icon(
                      AppIcons.boardGame,
                      color: colors.onPrimaryContainer,
                      size: AppIcons.xl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gameName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Đánh giá trận đấu',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Outcome selector section
          if (!result.isFinalized) ...[
            Text(
              'Kết quả của bạn',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chọn kết quả trận đấu từ góc nhìn của bạn',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutcomeSelector(
              selectedOutcome: selectedOutcome,
              onSelected: (outcome) {
                widget.matchResultCubit.selectOutcome(outcome);
              },
              isDisabled: isSubmitting,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedOutcome == null || isSubmitting
                    ? null
                    : () => widget.matchResultCubit.submitResult(widget.lobbyId),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Gửi kết quả'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],

          // Consensus status section
          ConsensusStatusCard(
            result: result,
            currentUserId: _effectiveUserId,
          ),

          // Finalized: Show Elo changes
          if (finalizedState != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Thay đổi Elo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...finalizedState.submitResponse.eloUpdates.map((elo) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: EloChangeDisplay(
                    eloUpdate: elo,
                    isCurrentUser: elo.odId == _effectiveUserId,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _showFinalizedDialog(BuildContext context, MatchResultFinalized state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.celebration,
          size: AppIcons.massive,
          color: AppColors.success,
        ),
        title: const Text('Đã hoàn tất đánh giá!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kết quả đã được đồng thuận và Elo đã được cập nhật.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.submitResponse.matchHistoryId != null)
              Text(
                'Mã trận: ${state.submitResponse.matchHistoryId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onComplete?.call();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            Icon(
              Icons.error_outline,
              size: 80,
              color: colors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
