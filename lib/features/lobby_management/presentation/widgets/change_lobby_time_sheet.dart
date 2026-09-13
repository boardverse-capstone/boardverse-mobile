import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import '../../domain/entities/lobby_entity.dart';

/// Bottom sheet cho host đổi giờ lobby.
///
/// BR-NEW-15 (2026-08-18): chỉ nhận `preferredStartTime` /
/// `preferredEndTime` (HH:mm:ss) — không gửi `timeSlot` enum. Host có thể
/// giữ nguyên 1 hoặc cả 2 bằng cách không thay đổi field đó (UI truyền
/// `null` cho server, server dùng `JsonIgnore(Condition = WhenWritingNull)`
/// để giữ giá trị cũ — xem `_LobbyRemoteDatasourceImpl.changeLobbyTime`).
class ChangeLobbyTimeSheet extends StatefulWidget {
  final LobbyEntity lobby;

  const ChangeLobbyTimeSheet({
    super.key,
    required this.lobby,
  });

  /// Show sheet + return true/false (true nếu user confirm & server OK).
  static Future<bool?> show(
    BuildContext context, {
    required LobbyEntity lobby,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<LobbyCubit>(),
        child: ChangeLobbyTimeSheet(lobby: lobby),
      ),
    );
  }

  @override
  State<ChangeLobbyTimeSheet> createState() => _ChangeLobbyTimeSheetState();
}

class _ChangeLobbyTimeSheetState extends State<ChangeLobbyTimeSheet> {
  late TimeOfDay? _start;
  late TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    _start = _parseHHMMSS(widget.lobby.preferredStartTime);
    _end = _parseHHMMSS(widget.lobby.preferredEndTime);
  }

  static TimeOfDay? _parseHHMMSS(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h == 24 ? 0 : h.clamp(0, 23), minute: m);
  }

  static String _toHHMMSS(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Chọn giờ bắt đầu mới',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Chọn giờ kết thúc mới',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  Future<void> _submit() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn cả giờ bắt đầu và kết thúc')),
      );
      return;
    }
    final startMinutes = _start!.hour * 60 + _start!.minute;
    final endMinutes = _end!.hour * 60 + _end!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu')),
      );
      return;
    }

    final cubit = context.read<LobbyCubit>();
    final navigator = Navigator.of(context);
    final result = await cubit.changeLobbyTime(
      lobbyId: widget.lobby.id,
      preferredStartTime: _start != null ? _toHHMMSS(_start!) : null,
      preferredEndTime: _end != null ? _toHHMMSS(_end!) : null,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (lobby) => navigator.pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<LobbyCubit, LobbyState>(
      listenWhen: (prev, curr) => prev is! LobbyFailure && curr is LobbyFailure,
      listener: (context, state) {
        if (state is LobbyFailure && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đổi giờ phòng chờ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BR-NEW-15: chỉ thay đổi giờ chơi dự kiến. Quán vẫn phải open trong khoảng mới.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              _TimeField(
                icon: Icons.play_arrow_rounded,
                label: 'Giờ bắt đầu',
                value: _start,
                onTap: _pickStart,
              ),
              const SizedBox(height: 12),
              _TimeField(
                icon: Icons.stop_rounded,
                label: 'Giờ kết thúc',
                value: _end,
                onTap: _pickEnd,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  const _TimeField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value != null ? _formatTime(value!) : 'Chọn giờ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
