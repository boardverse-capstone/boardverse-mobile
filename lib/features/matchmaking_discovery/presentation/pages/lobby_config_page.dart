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
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPublic = true;
  int _additionalSlots = 2;
  bool _isCreatingLobby = false;

  // ─── Phase 6: BR-10 + BR-08 inputs ─────────────────────────────────
  double _searchRadiusKm = 5.0;
  double _minimumKarma = 0.0;
  // BR-08 Lead-time do server cấu hình (deposit-config của quán). Hiện mock
  // mặc định 20 phút — phase sau sẽ lấy từ `BookingRemoteDatasource.getDepositConfig`.
  final Duration _leadTime = const Duration(minutes: 20);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Chọn ngày hẹn',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Chọn giờ hẹn',
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _createLobby() async {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn thời gian trong tương lai'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isCreatingLobby = true);

    final result = await widget.matchmakingCubit.createLobby(
      gameId: widget.gameId,
      gameName: widget.gameName,
      cafeId: widget.cafeId,
      cafeName: widget.cafeName,
      scheduledTime: scheduledDateTime,
      additionalSlots: _additionalSlots,
      isPublic: _isPublic,
      searchRadiusKm: _searchRadiusKm,
      minimumKarma: _minimumKarma,
      leadTime: _leadTime,
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
        searchRadiusKm: _searchRadiusKm,
        minimumKarma: _minimumKarma,
        leadTime: _leadTime,
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
                    'Ngày hẹn',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
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
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(context, _selectedDate),
                            style: theme.textTheme.titleMedium,
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
                  const SizedBox(height: 16),
                  Text(
                    'Giờ hẹn',
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
                  const SizedBox(height: 24),
                  // ─── BR-10: ngưỡng Karma tối thiểu ────────────────────
                  Text(
                    'Điều kiện Karma (BR-10)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chỉ chấp nhận thành viên Karma ≥',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${_minimumKarma.toInt()} điểm',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _minimumKarma == 0
                              ? 'Không yêu cầu Karma tối thiểu.'
                              : _minimumKarma < 60
                                  ? 'Ngưỡng thấp — dễ kết nối.'
                                  : _minimumKarma < 80
                                      ? 'Ngưỡng trung bình — cộng đồng phổ thông.'
                                      : 'Ngưỡng cao — chỉ player uy tín.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Slider(
                          value: _minimumKarma,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_minimumKarma.toInt()} Karma',
                          onChanged: (value) =>
                              setState(() => _minimumKarma = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ─── BR-08: bán kính tìm kiếm ───────────────────────
                  Text(
                    'Bán kính tìm kiếm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tìm lobby khả dụng trong vòng',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${_searchRadiusKm.toStringAsFixed(1)} km',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _searchRadiusKm,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '${_searchRadiusKm.toStringAsFixed(1)} km',
                          onChanged: (value) =>
                              setState(() => _searchRadiusKm = value),
                        ),
                        Text(
                          'Quán trong bán kính này mới hiện trong danh sách tìm phòng. '
                          'Bạn có thể điều chỉnh tùy nhu cầu.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
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
