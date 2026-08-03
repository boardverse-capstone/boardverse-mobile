import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import 'lobby_cafe_selection_page.dart';
import '../../domain/entities/board_game_entity.dart';

/// Trang cấu hình lobby — đã được redesign theo stepper pattern:
/// 1. Cafe + game (header tóm tắt)
/// 2. Thời gian (ngày + giờ)
/// 3. Cấu hình (số người + Karma + bán kính)
/// Mỗi step có indicator rõ ràng; CTA "Tạo phòng" mở dialog summary
/// trước khi submit.
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPublic = true;
  int _additionalSlots = 2;
  bool _isCreatingLobby = false;

  double _searchRadiusKm = 5.0;
  double _minimumKarma = 0.0;

  /// BR-08 Lead-time do server cấu hình (deposit-config của quán). Hiện mock
  /// mặc định 20 phút — phase sau sẽ lấy từ
  /// `BookingRemoteDatasource.getDepositConfig`.
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Chọn giờ hẹn',
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Quay lại màn chọn cafe để user đổi quán.
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

  /// Hiển thị summary dialog trước khi tạo lobby.
  Future<bool> _confirmBeforeCreate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _LobbySummaryDialog(
        cafeName: widget.cafeName,
        gameName: widget.gameName,
        scheduledDate: _selectedDate,
        scheduledTime: _selectedTime,
        additionalSlots: _additionalSlots,
        isPublic: _isPublic,
        minimumKarma: _minimumKarma,
        searchRadiusKm: _searchRadiusKm,
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _createLobby() async {
    if (_isCreatingLobby) return;

    if (widget.cafeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn quán cafe trước khi tạo phòng.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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

    final confirmed = await _confirmBeforeCreate();
    if (!confirmed || !mounted) return;

    _isCreatingLobby = true;

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

    if (!mounted) {
      _isCreatingLobby = false;
      return;
    }

    _isCreatingLobby = false;

    if (result.success && result.lobbyId != null) {
      final lobbyCubit = getIt<LobbyCubit>();

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

  String _karmaHint(double karma) {
    if (karma == 0) return 'Không yêu cầu Karma tối thiểu.';
    if (karma < 60) return 'Ngưỡng thấp — dễ kết nối.';
    if (karma < 80) return 'Ngưỡng trung bình — cộng đồng phổ thông.';
    return 'Ngưỡng cao — chỉ player uy tín.';
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
            final maxPlayers = state is MatchmakingGameDetail
                ? state.game.maxPlayers
                : (widget.gameEntity?.maxPlayers ?? 6);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingAllMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StepIndicator(
                          currentStep: 1,
                          steps: const ['Quán & Game', 'Thời gian', 'Cấu hình'],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionCard(
                          title: 'Quán & Game',
                          trailing: widget.gameEntity != null
                              ? TextButton.icon(
                                  onPressed: _changeCafe,
                                  icon: const Icon(
                                    Icons.swap_horiz,
                                    size: AppSpacing.md + 2,
                                  ),
                                  label: const Text('Đổi quán'),
                                )
                              : null,
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.local_cafe,
                                iconColor: theme.colorScheme.primary,
                                label: widget.cafeName,
                              ),
                              if (widget.gameEntity != null) ...[
                                const Divider(
                                  height: AppSpacing.xl,
                                ),
                                _InfoRow(
                                  icon: Icons.extension,
                                  iconColor: theme.colorScheme.outline,
                                  label: widget.gameEntity!.name,
                                  trailing: Text(
                                    '${widget.gameEntity!.minPlayers}-${widget.gameEntity!.maxPlayers} người',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Thời gian',
                          child: Column(
                            children: [
                              _SelectorRow(
                                icon: Icons.calendar_today,
                                iconColor: theme.colorScheme.primary,
                                label: 'Ngày hẹn',
                                value: _formatDate(context, _selectedDate),
                                onTap: () => _selectDate(context),
                              ),
                              const Divider(height: AppSpacing.xl),
                              _SelectorRow(
                                icon: Icons.access_time,
                                iconColor: theme.colorScheme.primary,
                                label: 'Giờ hẹn',
                                value: _selectedTime.format(context),
                                onTap: () => _selectTime(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Cấu hình',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Phòng công khai'),
                                subtitle: Text(
                                  _isPublic
                                      ? 'Hiển thị trên danh sách tìm kiếm'
                                      : 'Chỉ bạn bè được mời',
                                  style: theme.textTheme.bodySmall,
                                ),
                                value: _isPublic,
                                onChanged: (value) =>
                                    setState(() => _isPublic = value),
                              ),
                              const Divider(height: AppSpacing.lg),
                              _SliderField(
                                label: 'Số người cần tuyển thêm',
                                valueLabel:
                                    '${_additionalSlots + 1} / $maxPlayers người',
                                min: 0,
                                max: (maxPlayers - 1).toDouble(),
                                divisions: (maxPlayers - 1).clamp(1, 100),
                                value: _additionalSlots.toDouble(),
                                onChanged: (v) => setState(
                                    () => _additionalSlots = v.toInt()),
                                helper:
                                    'Bạn đã có 1 người. Tối đa $maxPlayers người.',
                              ),
                              const Divider(height: AppSpacing.lg),
                              _SliderField(
                                label: 'Karma tối thiểu (BR-10)',
                                valueLabel: '${_minimumKarma.toInt()} điểm',
                                min: 0,
                                max: 100,
                                divisions: 20,
                                value: _minimumKarma,
                                onChanged: (v) =>
                                    setState(() => _minimumKarma = v),
                                helper: _karmaHint(_minimumKarma),
                              ),
                              const Divider(height: AppSpacing.lg),
                              _SliderField(
                                label: 'Bán kính tìm kiếm (BR-08)',
                                valueLabel:
                                    '${_searchRadiusKm.toStringAsFixed(1)} km',
                                min: 1,
                                max: 30,
                                divisions: 29,
                                value: _searchRadiusKm,
                                onChanged: (v) =>
                                    setState(() => _searchRadiusKm = v),
                                helper:
                                    'Quán trong bán kính này mới hiện trong tìm phòng.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
                _StickyBottomBar(
                  onSubmit: _isCreatingLobby ? null : _createLobby,
                  isSubmitting: _isCreatingLobby,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Step indicator ở đầu trang — cho thấy user đang ở step nào.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: AppSpacing.lg + 2,
                  height: AppSpacing.lg + 2,
                  decoration: BoxDecoration(
                    color: i < currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: i < currentStep
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: AppSpacing.md,
                        )
                      : Text(
                          '${i + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i < currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: i == currentStep - 1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Container(
              height: 2,
              width: AppSpacing.md,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
        ],
      ],
    );
  }
}

/// Card chứa 1 section — title ở trên, content bên dưới.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Dòng thông tin icon + label (+ optional trailing widget).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.lg, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Selector row — icon + label + value, click để mở picker.
class _SelectorRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SelectorRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusSmAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.lg, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

/// Slider field — label + value + slider + helper text.
class _SliderField extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;
  final String helper;

  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              valueLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom bar với CTA "Tạo phòng" + summary.
class _StickyBottomBar extends StatelessWidget {
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  const _StickyBottomBar({
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(isSubmitting ? 'Đang tạo...' : 'Xem lại & Tạo phòng'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog summary trước khi submit — user thấy toàn bộ config 1 lần cuối.
class _LobbySummaryDialog extends StatelessWidget {
  final String cafeName;
  final String gameName;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final int additionalSlots;
  final bool isPublic;
  final double minimumKarma;
  final double searchRadiusKm;

  const _LobbySummaryDialog({
    required this.cafeName,
    required this.gameName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.additionalSlots,
    required this.isPublic,
    required this.minimumKarma,
    required this.searchRadiusKm,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledDateTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    return AlertDialog(
      title: const Text('Xác nhận tạo phòng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            icon: Icons.local_cafe,
            label: 'Quán',
            value: cafeName,
          ),
          _SummaryRow(
            icon: Icons.extension,
            label: 'Game',
            value: gameName,
          ),
          _SummaryRow(
            icon: Icons.calendar_today,
            label: 'Thời gian',
            value:
                '${scheduledDateTime.day.toString().padLeft(2, '0')}/${scheduledDateTime.month.toString().padLeft(2, '0')}/${scheduledDateTime.year} '
                '${scheduledTime.format(context)}',
          ),
          _SummaryRow(
            icon: Icons.people,
            label: 'Tuyển thêm',
            value: '$additionalSlots người (tổng ${additionalSlots + 1})',
          ),
          _SummaryRow(
            icon: Icons.lock_open,
            label: 'Chế độ',
            value: isPublic ? 'Công khai' : 'Riêng tư',
          ),
          _SummaryRow(
            icon: Icons.star,
            label: 'Karma tối thiểu',
            value: '${minimumKarma.toInt()} điểm',
          ),
          _SummaryRow(
            icon: Icons.radar,
            label: 'Bán kính tìm',
            value: '${searchRadiusKm.toStringAsFixed(1)} km',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Chỉnh sửa'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tạo phòng'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.lg, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}