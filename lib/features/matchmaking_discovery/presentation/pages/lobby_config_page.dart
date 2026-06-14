import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';

class LobbyConfigPage extends StatefulWidget {
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;
  final MatchmakingCubit matchmakingCubit;

  const LobbyConfigPage({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    required this.matchmakingCubit,
  });

  @override
  State<LobbyConfigPage> createState() => _LobbyConfigPageState();
}

class _LobbyConfigPageState extends State<LobbyConfigPage> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPublic = true;
  int _additionalSlots = 2;
  bool _isCreatingLobby = false;

  @override
  void initState() {
    super.initState();
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createLobby() async {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isCreatingLobby = true);

    final result = await widget.matchmakingCubit.createLobby(
      gameId: widget.gameId,
      gameName: widget.gameName,
      cafeId: widget.cafeId,
      cafeName: widget.cafeName,
      scheduledTime: scheduledDateTime,
      additionalSlots: _additionalSlots,
      isPublic: _isPublic,
    );

    if (!mounted) return;

    setState(() => _isCreatingLobby = false);

    if (result.success && result.lobbyId != null) {
      final lobbyCubit = getIt<LobbyCubit>();
      lobbyCubit.createLobby(
        gameId: widget.gameId,
        cafeId: widget.cafeId,
        scheduledTime: scheduledDateTime,
        additionalSlots: _additionalSlots,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyPage(
              lobbyId: result.lobbyId!,
              lobbyCubit: lobbyCubit,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Không thể tạo phòng'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cấu hình phòng chờ'),
        ),
        body: BlocBuilder<MatchmakingCubit, MatchmakingState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_cafe,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.cafeName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (state is MatchmakingGameDetail) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.extension,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 8),
                                Text(state.game.name),
                                const Spacer(),
                                Text(
                                  '${state.game.minPlayers}-${state.game.maxPlayers} người',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Khung giờ hẹn',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: theme.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.edit,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chế độ phòng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Phòng công khai'),
                    subtitle: Text(
                      _isPublic
                          ? 'Hiển thị trên danh sách tìm kiếm'
                          : 'Chỉ bạn bè được mời',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                  const SizedBox(height: 24),
                  if (state is MatchmakingGameDetail) ...[
                    Text(
                      'Số người cần tuyển thêm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bạn đã có: 1 người',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '${_additionalSlots + 1} / ${state.game.maxPlayers} người',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _additionalSlots.toDouble(),
                            min: 0,
                            max: (state.game.maxPlayers - 1).toDouble(),
                            divisions: state.game.maxPlayers - 1,
                            label: '$_additionalSlots slot',
                            onChanged: (value) {
                              setState(() {
                                _additionalSlots = value.toInt();
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${state.game.minPlayers - 1} tối thiểu',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Text(
                                '${state.game.maxPlayers - 1} tối đa',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isCreatingLobby ? null : _createLobby,
                      icon: _isCreatingLobby
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isCreatingLobby ? 'Đang tạo...' : 'Tạo phòng'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
