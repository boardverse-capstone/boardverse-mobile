import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../features/lobby_management/presentation/pages/lobby_page.dart';

class LobbiesPage extends StatelessWidget {
  const LobbiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LobbyCubit>(
      create: (_) => getIt<LobbyCubit>(),
      child: const _LobbiesPageContent(),
    );
  }
}

class _LobbiesPageContent extends StatefulWidget {
  const _LobbiesPageContent();

  @override
  State<_LobbiesPageContent> createState() => _LobbiesPageContentState();
}

class _LobbiesPageContentState extends State<_LobbiesPageContent> {
  late final LobbyCubit _lobbyCubit;
  bool _isLoading = false;
  List<_MockLobby> _lobbies = [];

  @override
  void initState() {
    super.initState();
    _lobbyCubit = getIt<LobbyCubit>();
    _loadMockLobbies();
  }

  void _loadMockLobbies() {
    setState(() {
      _isLoading = true;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _lobbies = [
            _MockLobby(
              id: 'lobby_001',
              gameName: 'Catan',
              cafeName: 'Board Game Cafe District 1',
              currentPlayers: 2,
              maxPlayers: 4,
              scheduledTime: DateTime.now().add(const Duration(hours: 1)),
              isPublic: true,
            ),
            _MockLobby(
              id: 'lobby_002',
              gameName: 'Ticket to Ride',
              cafeName: 'Meeple Station',
              currentPlayers: 3,
              maxPlayers: 5,
              scheduledTime: DateTime.now().add(const Duration(hours: 2)),
              isPublic: true,
            ),
            _MockLobby(
              id: 'lobby_003',
              gameName: 'Coup',
              cafeName: 'Dice & Cards Lounge',
              currentPlayers: 4,
              maxPlayers: 6,
              scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
              isPublic: true,
            ),
            _MockLobby(
              id: 'lobby_004',
              gameName: 'Pandemic',
              cafeName: 'Game Haven',
              currentPlayers: 1,
              maxPlayers: 4,
              scheduledTime: DateTime.now().add(const Duration(hours: 3)),
              isPublic: true,
            ),
          ];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng chờ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMockLobbies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lobbies.isEmpty
              ? _buildEmptyView(context)
              : _buildLobbyList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateLobbyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phòng'),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có phòng nào gần bạn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo phòng mới để bắt đầu chơi với mọi người!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateLobbyDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _loadMockLobbies();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lobbies.length,
        itemBuilder: (context, index) {
          final lobby = _lobbies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LobbyCardWidget(
              lobby: lobby,
              onJoin: () => _joinLobby(context, lobby),
            ),
          );
        },
      ),
    );
  }

  void _joinLobby(BuildContext context, _MockLobby lobby) {
    _lobbyCubit.loadMockLobby();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyPage(
          lobbyId: lobby.id,
          lobbyCubit: _lobbyCubit,
        ),
      ),
    );
  }

  void _showCreateLobbyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => _CreateLobbySheet(
        onCreateLobby: (lobby) {
          Navigator.pop(bottomSheetContext);
          setState(() {
            _lobbies.insert(0, lobby);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo phòng "${lobby.gameName}"'),
              action: SnackBarAction(
                label: 'Vào phòng',
                onPressed: () => _joinLobby(context, lobby),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockLobby {
  final String id;
  final String gameName;
  final String cafeName;
  final int currentPlayers;
  final int maxPlayers;
  final DateTime scheduledTime;
  final bool isPublic;

  _MockLobby({
    required this.id,
    required this.gameName,
    required this.cafeName,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.scheduledTime,
    required this.isPublic,
  });
}

class _LobbyCardWidget extends StatelessWidget {
  final _MockLobby lobby;
  final VoidCallback onJoin;

  const _LobbyCardWidget({
    required this.lobby,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotsRemaining = lobby.maxPlayers - lobby.currentPlayers;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.extension,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lobby.gameName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_cafe,
                                  size: 14,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lobby.cafeName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context, slotsRemaining),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.people,
                        '${lobby.currentPlayers}/${lobby.maxPlayers}',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        context,
                        Icons.schedule,
                        _formatTime(lobby.scheduledTime),
                      ),
                      const Spacer(),
                      if (lobby.isPublic)
                        Icon(
                          Icons.public,
                          size: 18,
                          color: theme.colorScheme.outline,
                        )
                      else
                        Icon(
                          Icons.lock,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap để xem chi tiết',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  FilledButton(
                    onPressed: onJoin,
                    child: const Text('Tham gia'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, int slotsRemaining) {
    final theme = Theme.of(context);

    if (slotsRemaining <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Gần đầy',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$slotsRemaining slot',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _CreateLobbySheet extends StatefulWidget {
  final Function(_MockLobby) onCreateLobby;

  const _CreateLobbySheet({required this.onCreateLobby});

  @override
  State<_CreateLobbySheet> createState() => _CreateLobbySheetState();
}

class _CreateLobbySheetState extends State<_CreateLobbySheet> {
  final _gameNameController = TextEditingController(text: 'Catan');
  final _cafeNameController = TextEditingController(text: 'Board Game Cafe');
  int _maxPlayers = 4;
  bool _isPublic = true;

  @override
  void dispose() {
    _gameNameController.dispose();
    _cafeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tạo phòng mới',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _gameNameController,
            decoration: const InputDecoration(
              labelText: 'Tên game',
              prefixIcon: Icon(Icons.extension),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cafeNameController,
            decoration: const InputDecoration(
              labelText: 'Tên quán',
              prefixIcon: Icon(Icons.local_cafe),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Số người chơi tối đa',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 2; i <= 8; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: _maxPlayers == i,
                  onSelected: (selected) {
                    if (selected) setState(() => _maxPlayers = i);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Phòng công khai'),
            subtitle: const Text('Cho phép người khác tìm thấy phòng này'),
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createLobby,
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng'),
            ),
          ),
        ],
      ),
    );
  }

  void _createLobby() {
    final lobby = _MockLobby(
      id: 'lobby_${DateTime.now().millisecondsSinceEpoch}',
      gameName: _gameNameController.text.isEmpty ? 'Board Game' : _gameNameController.text,
      cafeName: _cafeNameController.text.isEmpty ? 'Unknown Cafe' : _cafeNameController.text,
      currentPlayers: 1,
      maxPlayers: _maxPlayers,
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      isPublic: _isPublic,
    );
    widget.onCreateLobby(lobby);
  }
}
