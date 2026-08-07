import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/lobby_management/lobby_routes.dart';
import '../cubit/lobby_invite_cubit.dart';
import '../cubit/lobby_invite_state.dart';

/// App-bar action group cho [LobbyHubPage]:
/// - "Lời mời" (inbox): navigate sang LobbyInvitesPage, có badge đếm
///   số lời mời Pending
/// - "Nhập mã" : navigate sang JoinByCodePage
///
/// Pending count tự động refresh khi user mở app / pull-to-refresh trong
/// inbox (qua `LobbyInviteCubit` shared instance trong DI). Page chỉ lắng
/// nghe state để hiển thị badge — không tự fetch.
class LobbyHubActions extends StatefulWidget {
  final LobbyInviteCubit? inviteCubit;

  const LobbyHubActions({
    super.key,
    this.inviteCubit,
  });

  @override
  State<LobbyHubActions> createState() => _LobbyHubActionsState();
}

class _LobbyHubActionsState extends State<LobbyHubActions> {
  late final LobbyInviteCubit _cubit;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _cubit = widget.inviteCubit ??
        BlocProvider.of<LobbyInviteCubit>(context, listen: false);
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LobbyInviteCubit, LobbyInviteState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is LobbyInviteLoaded) {
          _setCount(state.pendingInvites.length);
        } else if (state is LobbyInviteActionLoading) {
          _setCount(state.pendingInvites.length);
        } else if (state is LobbyInviteError) {
          _setCount(state.pendingInvites.length);
        } else if (state is LobbyInviteEmpty) {
          _setCount(0);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Nhập mã phòng',
            icon: const Icon(Icons.link_rounded),
            onPressed: () => _openJoinByCode(context),
          ),
          _InviteInboxButton(
            count: _pendingCount,
            onPressed: () => _openInbox(context),
          ),
        ],
      ),
    );
  }

  void _setCount(int c) {
    if (_pendingCount == c) return;
    setState(() => _pendingCount = c);
  }

  Future<void> _openJoinByCode(BuildContext context) async {
    Navigator.of(context).pushNamed(LobbyRoutes.joinByCode);
  }

  Future<void> _openInbox(BuildContext context) async {
    Navigator.of(context).pushNamed(LobbyRoutes.lobbyInvites);
  }
}

class _InviteInboxButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _InviteInboxButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Lời mời Lobby',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.mail_outline_rounded),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: AppRadius.radiusSmAll,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: onPressed,
    );
  }
}