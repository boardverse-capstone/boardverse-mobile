import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/current_user_resolver.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_status_pill.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_detail_header.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_detail_info.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_action_button.dart';

/// Bottom sheet hiển thị chi tiết 1 tournament + các tab (info /
/// participants / matches) + nút register/withdraw.
///
/// Có 2 cách mở:
/// 1. Từ list (đã có sẵn [TournamentEntity] đầy đủ): truyền `tournament`.
/// 2. Từ "My Registrations" (chỉ có flat [MyRegistrationEntry] / id):
///    truyền `tournamentId` + optional `initialTitle` — sheet sẽ tự
///    fetch full detail qua [TournamentDetailCubit].
class TournamentDetailSheet extends StatefulWidget {
  final TournamentEntity? tournament;
  final String? tournamentId;
  final String? initialTitle;

  const TournamentDetailSheet({
    super.key,
    this.tournament,
    this.tournamentId,
    this.initialTitle,
  }) : assert(
          tournament != null || tournamentId != null,
          'Phải truyền tournament hoặc tournamentId',
        );

  @override
  State<TournamentDetailSheet> createState() => _TournamentDetailSheetState();
}

class _TournamentDetailSheetState extends State<TournamentDetailSheet> {
  late final TournamentDetailCubit _cubit;
  bool _resolvingUser = true;

  String get _resolvedId => widget.tournament?.id ?? widget.tournamentId!;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<TournamentDetailCubit>();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    String? userId;
    try {
      userId = await getIt<CurrentUserResolver>().resolveUserId();
    } catch (_) {
      userId = null;
    }
    if (!mounted) return;

    final loadFuture = _cubit.loadDetail(
      _resolvedId,
      currentUserId: userId,
    );
    setState(() => _resolvingUser = false);
    await loadFuture;
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<TournamentDetailCubit>.value(
      value: _cubit,
      child: BlocConsumer<TournamentDetailCubit, TournamentDetailState>(
        listener: (ctx, state) {
          if (state is TournamentDetailActionSuccess) {
            final messenger = ScaffoldMessenger.of(ctx);
            Navigator.of(ctx).pop(true);
            messenger.showSnackBar(
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
        builder: (ctx, state) {
          // Khi không có [TournamentEntity] truyền vào (mở từ My
          // Registrations), hiển thị placeholder cho tới khi cubit fetch
          // xong hoặc gặp lỗi.
          TournamentEntity? currentTournament = widget.tournament;
          var isLoading = _resolvingUser;
          var isRegistering = false;

          if (state is TournamentDetailLoaded) {
            currentTournament = state.tournament;
            isLoading = false;
          } else if (state is TournamentDetailRegistering) {
            currentTournament = state.tournament;
            isRegistering = true;
          } else if (state is TournamentDetailLoading) {
            isLoading = true;
          } else if (state is TournamentDetailActionSuccess) {
            isLoading = true;
          } else if (state is TournamentDetailError &&
              state.tournament != null) {
            currentTournament = state.tournament;
          }

          // Nếu vẫn chưa có tournament entity (vd: mở từ My Registrations
          // + API trả lỗi) → tạo entity tối thiểu với id + title để show
          // header rồi tiếp tục hiển thị error state.
          if (currentTournament == null) {
            final placeholder = _placeholderEntity();
            if (state is TournamentDetailError) {
              return _buildErrorContent(
                context,
                state.message,
                _resolvedId,
                placeholder,
              );
            }
            return _buildInitialLoading(
              context,
              currentTournament ?? placeholder,
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.52,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.radiusTopOnly(
                  topLeft: AppRadius.radiusXl,
                  topRight: AppRadius.radiusXl,
                ),
              ),
              child: isLoading || currentTournament == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(
                      context,
                      scrollController,
                      ctx,
                      currentTournament,
                      isRegistering,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    String message,
    String id,
    TournamentEntity placeholder,
  ) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.radiusTopOnly(
            topLeft: AppRadius.radiusXl,
            topRight: AppRadius.radiusXl,
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(theme),
              const SizedBox(height: AppSpacing.lg),
              TournamentDetailHeader(
                tournament: placeholder,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: AppIcons.xxl * 2,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Đã xảy ra lỗi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _cubit.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialLoading(
    BuildContext context,
    TournamentEntity placeholder,
  ) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.radiusTopOnly(
            topLeft: AppRadius.radiusXl,
            topRight: AppRadius.radiusXl,
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(theme),
              const SizedBox(height: AppSpacing.lg),
              TournamentDetailHeader(
                tournament: placeholder,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    BuildContext ctx,
    TournamentEntity tournament,
    bool isRegistering,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(theme),
          const SizedBox(height: AppSpacing.lg),
          TournamentDetailHeader(
            tournament: tournament,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
          TournamentStatusPill(status: tournament.status),
          const SizedBox(height: AppSpacing.md),
          if (tournament.description.isNotEmpty) ...[
            _buildDescription(theme, tournament),
            const SizedBox(height: AppSpacing.xl),
          ],
          TournamentDetailInfo(tournament: tournament),
          const SizedBox(height: AppSpacing.xl),
          TournamentActionButton(
            tournament: tournament,
            isRegistering: isRegistering,
            onRegister: () =>
                ctx.read<TournamentDetailCubit>().register(tournament.id),
            onUnregister: () =>
                ctx.read<TournamentDetailCubit>().unregister(tournament.id),
          ),
        ],
      ),
    );
  }

  /// Placeholder entity dùng khi mở sheet bằng id (không có full
  /// `TournamentEntity`). Header vẫn render được, body sẽ được thay
  /// bằng loading / error state.
  TournamentEntity _placeholderEntity() {
    final now = DateTime.now();
    return TournamentEntity(
      id: _resolvedId,
      title: widget.initialTitle ?? 'Chi tiết giải đấu',
      cafeName: '',
      gameTemplateName: '',
      startTime: now,
      registrationDeadline: now,
      status: TournamentStatus.upcoming,
      currentParticipants: 0,
      maxParticipants: 0,
      minKarmaRequirement: 0,
      registrationFee: null,
      prizePool: 0,
      description: '',
      organizerName: null,
      roundDurationMinutes: 60,
      preliminaryRounds: 3,
      currentRound: null,
      isUserRegistered: false,
      isUserCheckedIn: false,
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: AppSpacing.xxxl,
        height: AppSpacing.xxs,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: AppRadius.radiusFullAll,
        ),
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, TournamentEntity tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Text(
        tournament.description,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}
