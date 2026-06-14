import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../booking_commitment/presentation/cubit/booking_cubit.dart';
import '../../../booking_commitment/presentation/pages/deposit_page.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import '../widgets/lobby_player_card.dart';
import '../widgets/lobby_countdown_timer.dart';
import '../widgets/online_friends_list.dart';

class LobbyPage extends StatefulWidget {
  final String lobbyId;
  final LobbyCubit lobbyCubit;

  const LobbyPage({
    super.key,
    required this.lobbyId,
    required this.lobbyCubit,
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    widget.lobbyCubit.joinLobby(widget.lobbyId, null);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _showInviteFriendsSheet(BuildContext context) {
    widget.lobbyCubit.loadOnlineFriends();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mời bạn bè',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: BlocBuilder<LobbyCubit, LobbyState>(
                  bloc: widget.lobbyCubit,
                  builder: (context, state) {
                    if (state is LobbyFriendsLoaded) {
                      return OnlineFriendsList(
                        friends: state.friends,
                        onInvite: (friend) {
                          widget.lobbyCubit.inviteFriend(widget.lobbyId, friend.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã gửi lời mời đến ${friend.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareInviteCode(BuildContext context, String? code) {
    if (code == null) return;

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã phòng $code đã được sao chép!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showDismissDialog(BuildContext context, LobbyDismissed state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange.shade700,
          size: 48,
        ),
        title: Text(state.title),
        content: Text(state.message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.lobbyCubit,
      child: BlocConsumer<LobbyCubit, LobbyState>(
        listener: (context, state) {
          if (state is LobbyDismissed) {
            _showDismissDialog(context, state);
          }
          if (state is LobbyReady) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DepositPage(
                  lobbyId: state.lobby.id,
                  gameName: state.lobby.gameName,
                  cafeName: state.lobby.cafeName,
                  bookingCubit: getIt<BookingCubit>(),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LobbyLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is LobbyFailure) {
            return Scaffold(
              appBar: AppBar(title: const Text('Phòng chờ')),
              body: Center(
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
                      onPressed: () =>
                          widget.lobbyCubit.joinLobby(widget.lobbyId, null),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final lobby = state is LobbyCreated
              ? state.lobby
              : state is LobbyUpdatedRealtime
                  ? state.lobby
                  : null;

          if (lobby == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildLobbyView(context, lobby);
        },
      ),
    );
  }

  Widget _buildLobbyView(BuildContext context, lobby) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lobby.gameName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLobbyDetails(context, lobby),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Thông tin phòng + Đồng hồ đếm ngược
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_cafe,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lobby.cafeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${lobby.slotsRemaining} slot trống',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LobbyCountdownTimer(
                      expiresAt: lobby.expiresAt,
                      onExpired: () {},
                    ),
                  ],
                ),
                if (lobby.inviteCode != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mã phòng: ${lobby.inviteCode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _shareInviteCode(context, lobby.inviteCode),
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Grid avatar thành viên
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thành viên (${lobby.currentPlayers}/${lobby.maxPlayers})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showInviteFriendsSheet(context),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Mời bạn bè'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LobbyPlayerGrid(
                    players: lobby.players,
                    maxSlots: lobby.maxPlayers,
                    currentUserId: 'user_001',
                  ),
                  const SizedBox(height: 24),

                  // Chat nội bộ
                  Text(
                    'Trò chuyện trong phòng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _chatMessages.isEmpty
                        ? Center(
                            child: Text(
                              'Chưa có tin nhắn nào',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              final msg = _chatMessages[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodySmall,
                                    children: [
                                      TextSpan(
                                        text: '${msg.senderName}: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      TextSpan(text: msg.message),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (_chatController.text.isNotEmpty) {
                            setState(() {
                              _chatMessages.add(ChatMessage(
                                senderName: 'Bạn',
                                message: _chatController.text,
                              ));
                              _chatController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.lobbyCubit.leaveLobby(widget.lobbyId);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Rời phòng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: lobby.currentPlayers >= lobby.minPlayers
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DepositPage(
                                lobbyId: lobby.id,
                                gameName: lobby.gameName,
                                cafeName: lobby.cafeName,
                                bookingCubit: getIt<BookingCubit>(),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.payment),
                  label: const Text('Tiến hành đặt cọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLobbyDetails(BuildContext context, lobby) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết phòng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.extension,
              label: 'Game',
              value: lobby.gameName,
            ),
            _DetailRow(
              icon: Icons.local_cafe,
              label: 'Quán',
              value: lobby.cafeName,
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Giờ hẹn',
              value: _formatTime(lobby.scheduledTime),
            ),
            _DetailRow(
              icon: Icons.people,
              label: 'Người chơi',
              value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
            ),
            _DetailRow(
              icon: Icons.public,
              label: 'Chế độ',
              value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String senderName;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
