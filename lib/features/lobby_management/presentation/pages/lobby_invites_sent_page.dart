import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/utils/current_user_resolver.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/lobby_invite_entity.dart';
import '../../data/datasources/base/lobby_remote_datasource.dart';
import '../cubit/lobby_invite_cubit.dart';
import '../cubit/lobby_invite_state.dart';
import '../widgets/lobby_invite_card.dart';
import '../widgets/lobby_list_shimmer.dart';

/// Inbox/Sent của host: xem các lời mời mà user đã GỬI đi
/// (status = Pending). Khác với [LobbyInvitesPage] — page đó hiển thị lời
/// mời user NHẬN được.
///
/// Tại sao tách riêng:
/// - Use-case khác: host xem + cancel; invitee xem + accept/decline
/// - State model `LobbyInviteLoaded.pendingInvites` cho invitee;
///   outgoing filter theo `inviterId == currentUserId` để hiển thị cancel
class LobbyInvitesSentPage extends StatefulWidget {
  final LobbyRemoteDatasource? remote;
  final CurrentUserResolver? userResolver;

  const LobbyInvitesSentPage({
    super.key,
    this.remote,
    this.userResolver,
  });

  @override
  State<LobbyInvitesSentPage> createState() => _LobbyInvitesSentPageState();
}

class _LobbyInvitesSentPageState extends State<LobbyInvitesSentPage> {
  late final LobbyRemoteDatasource _remote;
  late final CurrentUserResolver _userResolver;
  String? _currentUserId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _remote = widget.remote ?? getIt<LobbyRemoteDatasource>();
    _userResolver =
        widget.userResolver ?? getIt<CurrentUserResolver>();
    _resolveUserId();
  }

  Future<void> _resolveUserId() async {
    final id = await _userResolver.resolveUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = id;
      _loadingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const GenericPageShimmer(
        itemCount: 4,
        appBarTitle: 'Lời mời đã gửi',
      );
    }

    return BlocProvider<LobbyInviteCubit>(
      create: (_) => LobbyInviteCubit(remoteDatasource: _remote)
        ..loadAllInvites(status: LobbyInviteStatus.pending),
      child: _LobbyInvitesSentView(currentUserId: _currentUserId ?? ''),
    );
  }
}

class _LobbyInvitesSentView extends StatefulWidget {
  final String currentUserId;
  const _LobbyInvitesSentView({required this.currentUserId});

  @override
  State<_LobbyInvitesSentView> createState() => _LobbyInvitesSentViewState();
}

class _LobbyInvitesSentViewState extends State<_LobbyInvitesSentView> {
  LobbyInviteStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời đã gửi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _reload(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilterBar(
            current: _statusFilter,
            onChanged: (status) {
              setState(() => _statusFilter = status);
              _reload();
            },
          ),
          Expanded(
            child: BlocConsumer<LobbyInviteCubit, LobbyInviteState>(
              listener: (context, state) {
                if (state is LobbyInviteCancelled) {
                  context.showTopSnackBar('Đã huỷ lời mời');
                  _reload();
                } else if (state is LobbyInviteError &&
                    state.pendingInvites.isEmpty &&
                    state.allInvites.isEmpty) {
                  context.showTopSnackBar(
                    state.message,
                    isError: true,
                  );
                }
              },
              builder: (context, state) => _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  void _reload() {
    final cubit = context.read<LobbyInviteCubit>();
    cubit.loadAllInvites(status: _statusFilter);
  }

  Widget _buildBody(BuildContext context, LobbyInviteState state) {
    if (state is LobbyInviteLoading) {
      return const LobbyInvitesShimmer();
    }

    final invites = _currentInvites(state);

    if (invites.isEmpty) {
      if (state is LobbyInviteError) {
        return _ErrorState(
          message: state.message,
          onRetry: _reload,
        );
      }
      return const _EmptySentState();
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: invites.length,
        itemBuilder: (context, index) {
          final invite = invites[index];
          final isLoading = state is LobbyInviteActionLoading &&
              state.inviteId == invite.inviteId;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LobbyInviteCard(
              invite: invite,
              isInvitee: false,
              isLoading: isLoading,
              onCancel: () => _confirmCancel(context, invite),
            ),
          );
        },
      ),
    );
  }

  List<LobbyInviteEntity> _currentInvites(LobbyInviteState state) {
    final list = state is LobbyInviteLoaded
        ? state.allInvites
        : state is LobbyInviteActionLoading
            ? state.allInvites
            : state is LobbyInviteError
                ? state.allInvites
                : <LobbyInviteEntity>[];
    // Chỉ giữ lại các invite do current user gửi
    if (widget.currentUserId.isEmpty) return list;
    return list
        .where((i) => i.inviterId == widget.currentUserId)
        .toList();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    LobbyInviteEntity invite,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ lời mời?'),
        content: Text(
          'Bạn có chắc muốn huỷ lời mời tham gia lobby "${invite.gameName}" gửi tới ${invite.inviteeNameOrEmpty}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Huỷ lời mời'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<LobbyInviteCubit>().cancelInvite(invite.inviteId);
    }
  }
}

extension on LobbyInviteEntity {
  // inviteeNameOrEmpty: hiển thị phụ thuộc view; nếu cần, mở rộng entity.
  // Tạm thời fallback về "người chơi" để tránh breaking change.
  String get inviteeNameOrEmpty => 'người chơi';
}

class _StatusFilterBar extends StatelessWidget {
  final LobbyInviteStatus? current;
  final ValueChanged<LobbyInviteStatus?> onChanged;

  const _StatusFilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <(LobbyInviteStatus?, String)>[
      (null, 'Tất cả'),
      (LobbyInviteStatus.pending, 'Chờ'),
      (LobbyInviteStatus.accepted, 'Đã chấp nhận'),
      (LobbyInviteStatus.declined, 'Đã từ chối'),
      (LobbyInviteStatus.cancelled, 'Đã huỷ'),
      (LobbyInviteStatus.expired, 'Hết hạn'),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final (status, label) = entries[index];
          final selected = current == status;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(status),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.white : null,
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemCount: entries.length,
      ),
    );
  }
}

class _EmptySentState extends StatelessWidget {
  const _EmptySentState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 80,
              color: colors.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có lời mời nào',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Các lời mời bạn gửi cho bạn bè sẽ hiển thị ở đây.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
            Icon(Icons.error_outline, size: 80, color: colors.error),
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