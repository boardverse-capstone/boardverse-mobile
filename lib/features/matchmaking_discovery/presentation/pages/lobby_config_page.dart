import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../lobby_management/presentation/pages/lobby_quote_page.dart';
import '../../../reservation/domain/entities/entities.dart';
import '../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import 'lobby_cafe_selection_page.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/board_game_detail_entity.dart';

/// Trang cấu hình lobby — thiết kế lại mobile-first theo BR-NEW-15:
///
/// - TimeSlot chips thay vì time picker (morning/afternoon/evening/night)
/// - Optional preferredStartTime bên trong slot đã chọn
/// - Segmented button cho số người thay vì slider
/// - Nâng cao (Karma, bán kính) ẩn trong expandable section
/// - Sticky summary card ở bottom hiển thị buffer warning
/// - Stepper đơn giản ở header
class LobbyConfigPage extends StatefulWidget {
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;
  final MatchmakingCubit matchmakingCubit;

  /// Optional: truyền vào khi cần back-về cafe selection (đổi quán).
  final BoardGameEntity? gameEntity;

  const LobbyConfigPage({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    required this.matchmakingCubit,
    this.gameEntity,
  });

  @override
  State<LobbyConfigPage> createState() => _LobbyConfigPageState();
}

class _LobbyConfigPageState extends State<LobbyConfigPage> {
  late DateTime _selectedDate;
  TimeSlot _selectedTimeSlot = TimeSlot.morning;
  TimeOfDay? _preferredStartTime;
  bool _isPublic = true;
  int _maxPlayers = 4;
  bool _isCreatingLobby = false;
  bool _showAdvanced = false;

  double _searchRadiusKm = 5.0;
  double _minimumKarma = 0.0;

  /// Lead-time mặc định 20 phút (theo BR-LOBBY-01)
  final Duration _leadTime = const Duration(minutes: 20);

  /// Tính buffer (phút) từ now đến recruitmentDeadline
  int get _bufferMinutes {
    final now = DateTime.now();
    final scheduledTime = _getScheduledDateTime();
    final deadline = scheduledTime.subtract(_leadTime);
    return deadline.difference(now).inMinutes;
  }

  /// Check xem buffer có warning không (60-120 phút)
  bool get _hasBufferWarning => _bufferMinutes >= 60 && _bufferMinutes < 120;

  /// Check xem buffer có đủ không (< 60 phút → từ chối)
  bool get _isBufferTooShort => _bufferMinutes < 60;

  /// Check xem có thể tạo lobby không
  bool get _canCreateLobby => !_isBufferTooShort;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Set preferredStartTime mặc định là giờ bắt đầu của slot
    _preferredStartTime = _getSlotStartTime(TimeSlot.morning);
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  /// Lấy thời gian bắt đầu mặc định của 1 slot
  TimeOfDay _getSlotStartTime(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 9, minute: 0);
      case TimeSlot.afternoon:
        return const TimeOfDay(hour: 13, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.night:
        return const TimeOfDay(hour: 19, minute: 0);
    }
  }

  /// Lấy thời gian kết thúc của 1 slot
  TimeOfDay _getSlotEndTime(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 13, minute: 0);
      case TimeSlot.afternoon:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 23, minute: 0);
      case TimeSlot.night:
        return const TimeOfDay(hour: 24, minute: 0);
    }
  }

  /// Tính scheduledDateTime từ date + timeSlot
  DateTime _getScheduledDateTime() {
    final startTime = _getSlotStartTime(_selectedTimeSlot);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatBuffer(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}p';
    }
    return '${minutes}p';
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
      setState(() => _selectedDate = picked);
    }
  }

  void _onTimeSlotChanged(TimeSlot? slot) {
    if (slot == null) return;
    setState(() {
      _selectedTimeSlot = slot;
      // Reset preferredStartTime về giờ bắt đầu của slot mới
      _preferredStartTime = _getSlotStartTime(slot);
    });
  }

  Future<void> _selectPreferredTime(BuildContext context) async {
    final startTime = _getSlotStartTime(_selectedTimeSlot);
    final endTime = _getSlotEndTime(_selectedTimeSlot);

    // Giới hạn time picker trong khoảng của slot
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredStartTime ?? startTime,
      helpText: 'Chọn giờ dự kiến (trong khung ${_getSlotLabel(_selectedTimeSlot)})',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      // Validate giờ nằm trong slot
      final pickedHour = picked.hour + picked.minute / 60;
      final startHour = startTime.hour + startTime.minute / 60;
      final endHour = endTime.hour == 24 ? 24.0 : endTime.hour + endTime.minute / 60;

      if (pickedHour >= startHour && pickedHour < endHour) {
        setState(() => _preferredStartTime = picked);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Giờ phải nằm trong khung ${_getSlotLabel(_selectedTimeSlot)} '
                '(${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)})',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getSlotLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'Sáng (9:00-13:00)';
      case TimeSlot.afternoon:
        return 'Chiều (13:00-18:00)';
      case TimeSlot.evening:
        return 'Tối (18:00-23:00)';
      case TimeSlot.night:
        return 'Khuya (19:00-24:00)';
    }
  }

  String _getSlotShortLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'Sáng';
      case TimeSlot.afternoon:
        return 'Chiều';
      case TimeSlot.evening:
        return 'Tối';
      case TimeSlot.night:
        return 'Khuya';
    }
  }

  IconData _getSlotIcon(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return Icons.wb_sunny;
      case TimeSlot.afternoon:
        return Icons.wb_cloudy;
      case TimeSlot.evening:
        return Icons.nights_stay;
      case TimeSlot.night:
        return Icons.bedtime;
    }
  }

  Color _getSlotColor(TimeSlot slot, ColorScheme colorScheme) {
    switch (slot) {
      case TimeSlot.morning:
        return Colors.orange;
      case TimeSlot.afternoon:
        return Colors.amber;
      case TimeSlot.evening:
        return Colors.indigo;
      case TimeSlot.night:
        return Colors.deepPurple;
    }
  }

  void _changeCafe() {
    final game = widget.gameEntity;
    if (game == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: game,
          matchmakingCubit: widget.matchmakingCubit,
        ),
      ),
    );
  }

  Future<void> _createLobby() async {
    if (_isCreatingLobby || !_canCreateLobby) return;

    if (widget.cafeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn quán cafe trước khi tạo phòng.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isCreatingLobby = true);

    final reservationCubit = GetIt.instance<ReservationCubit>();
    reservationCubit.reset();
    reservationCubit.createQuote(
      cafeId: widget.cafeId,
      gameId: widget.gameId,
      playDate: _selectedDate,
      timeSlot: _selectedTimeSlot,
      preferredStartTime: _preferredStartTime != null
          ? '${_preferredStartTime!.hour.toString().padLeft(2, '0')}:'
              '${_preferredStartTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      minPlayers: 2,
      maxPlayers: _maxPlayers,
      isPrivate: !_isPublic,
    );

    if (!mounted) return;
    LobbyFlowNavigator.push(
      context,
      BlocProvider.value(
        value: reservationCubit,
        child: const LobbyQuotePage(),
      ),
    ).then((_) {
      if (mounted) setState(() => _isCreatingLobby = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo phòng chờ'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<MatchmakingCubit, MatchmakingState>(
            builder: (context, state) {
            final BoardGameDetailEntity? gameDetail = state is MatchmakingGameDetail
                ? state.game
                : null;
            final maxPlayers = gameDetail?.maxPlayers ?? widget.gameEntity?.maxPlayers ?? 6;
            final minPlayers = gameDetail?.minPlayers ?? widget.gameEntity?.minPlayers ?? 2;

            return Column(
              children: [
                // Progress indicator
                _ProgressStepper(
                  currentStep: 2,
                  steps: const ['Chọn quán', 'Cấu hình', 'Đặt cọc'],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingAllMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ========== HEADER: Quán + Game ==========
                        _CompactHeaderCard(
                          cafeName: widget.cafeName,
                          gameName: widget.gameName,
                          gameDetail: gameDetail,
                          onChangeCafe: _changeCafe,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ========== SECTION 1: Ngày & Phiên ==========
                        _SectionTitle(
                          title: 'Khi nào?',
                          subtitle: 'Chọn ngày và phiên chơi',
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Date selector
                        _DateSelector(
                          selectedDate: _selectedDate,
                          onTap: () => _selectDate(context),
                          formatDate: _formatDate,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // TimeSlot chips
                        _TimeSlotSelector(
                          selectedSlot: _selectedTimeSlot,
                          onChanged: _onTimeSlotChanged,
                          getSlotLabel: _getSlotLabel,
                          getSlotShortLabel: _getSlotShortLabel,
                          getSlotIcon: _getSlotIcon,
                          getSlotColor: _getSlotColor,
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Preferred start time (optional)
                        _PreferredTimeSelector(
                          preferredTime: _preferredStartTime,
                          slot: _selectedTimeSlot,
                          onTap: () => _selectPreferredTime(context),
                          getSlotStartTime: _getSlotStartTime,
                          getSlotEndTime: _getSlotEndTime,
                          formatTime: _formatTimeOfDay,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ========== SECTION 2: Số người ==========
                        _SectionTitle(
                          title: ' Bao nhiêu người?',
                          subtitle: 'Bao gồm bạn (host)',
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        _PlayerCountSelector(
                          selectedCount: _maxPlayers,
                          minPlayers: minPlayers,
                          maxPlayers: maxPlayers,
                          onChanged: (v) => setState(() => _maxPlayers = v),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ========== SECTION 3: Chế độ ==========
                        _SectionTitle(
                          title: 'Chế độ phòng',
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        _VisibilityToggle(
                          isPublic: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ========== ADVANCED (Expandable) ==========
                        _AdvancedSection(
                          showAdvanced: _showAdvanced,
                          onToggle: () => setState(() => _showAdvanced = !_showAdvanced),
                          minimumKarma: _minimumKarma,
                          onKarmaChanged: (v) => setState(() => _minimumKarma = v),
                          searchRadiusKm: _searchRadiusKm,
                          onRadiusChanged: (v) => setState(() => _searchRadiusKm = v),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                // ========== STICKY BOTTOM ==========
                _StickyBottomSummary(
                  bufferMinutes: _bufferMinutes,
                  hasBufferWarning: _hasBufferWarning,
                  isBufferTooShort: _isBufferTooShort,
                  isCreatingLobby: _isCreatingLobby,
                  canCreate: _canCreateLobby,
                  onCreateLobby: _createLobby,
                  formatBuffer: _formatBuffer,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Progress stepper ở header
class _ProgressStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _ProgressStepper({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepDot(
              index: i + 1,
              label: steps[i],
              isActive: i + 1 == currentStep,
              isCompleted: i + 1 < currentStep,
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  color: i + 1 < currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepDot({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? theme.colorScheme.primary
                : isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
                : Text(
                    '$index',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
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
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Compact header card cho quán + game
class _CompactHeaderCard extends StatelessWidget {
  final String cafeName;
  final String gameName;
  final BoardGameDetailEntity? gameDetail;
  final VoidCallback onChangeCafe;

  const _CompactHeaderCard({
    required this.cafeName,
    required this.gameName,
    required this.gameDetail,
    required this.onChangeCafe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          // Game icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: gameDetail?.thumbnailUrl != null && gameDetail!.thumbnailUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppRadius.radiusSmAll,
                    child: Image.network(
                      gameDetail!.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.extension,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.extension,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.local_cafe,
                      size: 14,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cafeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (gameDetail != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: AppRadius.radiusXsAll,
                    ),
                    child: Text(
                      '${gameDetail!.minPlayers}-${gameDetail!.maxPlayers} người',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Change button
          TextButton(
            onPressed: onChangeCafe,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );
  }
}

/// Section title với subtitle
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Date selector dạng horizontal chips
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  const _DateSelector({
    required this.selectedDate,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Tạo list ngày: hôm nay + 6 ngày tới
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date == today;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: AppRadius.radiusMdAll,
                border: isSelected
                    ? null
                    : Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                            : theme.colorScheme.primaryContainer,
                        borderRadius: AppRadius.radiusXsAll,
                      ),
                      child: Text(
                        'HÔM NAY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getWeekdayShort(date.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[weekday % 7];
  }
}

/// TimeSlot selector dạng chips
class _TimeSlotSelector extends StatelessWidget {
  final TimeSlot selectedSlot;
  final ValueChanged<TimeSlot?> onChanged;
  final String Function(TimeSlot) getSlotLabel;
  final String Function(TimeSlot) getSlotShortLabel;
  final IconData Function(TimeSlot) getSlotIcon;
  final Color Function(TimeSlot, ColorScheme) getSlotColor;

  const _TimeSlotSelector({
    required this.selectedSlot,
    required this.onChanged,
    required this.getSlotLabel,
    required this.getSlotShortLabel,
    required this.getSlotIcon,
    required this.getSlotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TimeSlot.values.map((slot) {
        return _TimeSlotChip(
          slot: slot,
          isSelected: slot == selectedSlot,
          onTap: () => onChanged(slot),
          getLabel: getSlotShortLabel,
          getIcon: getSlotIcon,
          getColor: getSlotColor,
        );
      }).toList(),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(TimeSlot) getLabel;
  final IconData Function(TimeSlot) getIcon;
  final Color Function(TimeSlot, ColorScheme) getColor;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
    required this.getLabel,
    required this.getIcon,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = getColor(slot, theme.colorScheme);
    final icon = getIcon(slot);
    final label = getLabel(slot);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.radiusFullAll,
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preferred start time selector (optional)
class _PreferredTimeSelector extends StatelessWidget {
  final TimeOfDay? preferredTime;
  final TimeSlot slot;
  final VoidCallback onTap;
  final TimeOfDay Function(TimeSlot) getSlotStartTime;
  final TimeOfDay Function(TimeSlot) getSlotEndTime;
  final String Function(TimeOfDay) formatTime;

  const _PreferredTimeSelector({
    required this.preferredTime,
    required this.slot,
    required this.onTap,
    required this.getSlotStartTime,
    required this.getSlotEndTime,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = getSlotStartTime(slot);
    final endTime = getSlotEndTime(slot);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingAllSm,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.radiusSmAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giờ dự kiến bắt đầu',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preferredTime != null
                        ? formatTime(preferredTime!)
                        : 'Chọn giờ (tuỳ chọn)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: preferredTime != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.radiusXsAll,
              ),
              child: Text(
                '${formatTime(startTime)} - ${formatTime(endTime)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Player count selector dạng segmented buttons
class _PlayerCountSelector extends StatelessWidget {
  final int selectedCount;
  final int minPlayers;
  final int maxPlayers;
  final ValueChanged<int> onChanged;

  const _PlayerCountSelector({
    required this.selectedCount,
    required this.minPlayers,
    required this.maxPlayers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tạo list số người có thể chọn
    final counts = List.generate(
      maxPlayers - minPlayers + 1,
      (i) => minPlayers + i,
    );

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tổng số người chơi',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.radiusFullAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selectedCount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      ' người',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: counts.map((count) {
              final isSelected = count == selectedCount;
              return GestureDetector(
                onTap: () => onChanged(count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: AppRadius.radiusSmAll,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bao gồm bạn (host). Cần tối thiểu $minPlayers người.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visibility toggle (Public/Private)
class _VisibilityToggle extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  const _VisibilityToggle({
    required this.isPublic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isPublic
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: AppRadius.radiusMdAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public,
                      size: 20,
                      color: isPublic
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Công khai',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isPublic ? FontWeight.bold : FontWeight.normal,
                        color: isPublic
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: !isPublic
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: AppRadius.radiusMdAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: !isPublic
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Riêng tư',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: !isPublic ? FontWeight.bold : FontWeight.normal,
                        color: !isPublic
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable advanced section (Karma, bán kính)
class _AdvancedSection extends StatelessWidget {
  final bool showAdvanced;
  final VoidCallback onToggle;
  final double minimumKarma;
  final ValueChanged<double> onKarmaChanged;
  final double searchRadiusKm;
  final ValueChanged<double> onRadiusChanged;

  const _AdvancedSection({
    required this.showAdvanced,
    required this.onToggle,
    required this.minimumKarma,
    required this.onKarmaChanged,
    required this.searchRadiusKm,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.radiusFullAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showAdvanced ? Icons.settings : Icons.settings_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  showAdvanced ? 'Ẩn nâng cao' : 'Tuỳ chọn nâng cao',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  showAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        // Advanced options
        if (showAdvanced) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karma slider
                _CompactSlider(
                  icon: Icons.star,
                  label: 'Karma tối thiểu',
                  valueLabel: '${minimumKarma.toInt()} điểm',
                  value: minimumKarma,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: onKarmaChanged,
                ),
                const Divider(height: AppSpacing.lg),

                // Search radius slider
                _CompactSlider(
                  icon: Icons.radar,
                  label: 'Bán kính tìm kiếm',
                  valueLabel: '${searchRadiusKm.toStringAsFixed(1)} km',
                  value: searchRadiusKm,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: onRadiusChanged,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _CompactSlider({
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              valueLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Sticky bottom summary với buffer warning
class _StickyBottomSummary extends StatelessWidget {
  final int bufferMinutes;
  final bool hasBufferWarning;
  final bool isBufferTooShort;
  final bool isCreatingLobby;
  final bool canCreate;
  final VoidCallback onCreateLobby;
  final String Function(int) formatBuffer;

  const _StickyBottomSummary({
    required this.bufferMinutes,
    required this.hasBufferWarning,
    required this.isBufferTooShort,
    required this.isCreatingLobby,
    required this.canCreate,
    required this.onCreateLobby,
    required this.formatBuffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color warningColor;
    String warningText;
    IconData warningIcon;

    if (isBufferTooShort) {
      warningColor = colorScheme.error;
      warningText = 'Không thể tạo: Buffer quá ngắn (< 60 phút)';
      warningIcon = Icons.error;
    } else if (hasBufferWarning) {
      warningColor = Colors.orange;
      warningText = 'Buffer chỉ ${formatBuffer(bufferMinutes)} - khuyến nghị chọn ngày xa hơn';
      warningIcon = Icons.warning;
    } else {
      warningColor = Colors.green;
      warningText = 'Còn ${formatBuffer(bufferMinutes)} để tuyển người';
      warningIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Buffer warning
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSmAll,
                border: Border.all(color: warningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(warningIcon, size: 18, color: warningColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      warningText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canCreate && !isCreatingLobby ? onCreateLobby : null,
                icon: isCreatingLobby
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  isCreatingLobby
                      ? 'Đang tạo...'
                      : isBufferTooShort
                          ? 'Không thể tạo'
                          : 'Xem chi tiết cọc',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
