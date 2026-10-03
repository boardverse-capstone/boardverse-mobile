import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import '../../domain/entities/lobby_entity.dart';

/// Bottom sheet cho host đổi giờ lobby.
///
/// **Fix 2026-10-03:**
/// 1. Nội dung hiển thị được viết lại bằng ngôn ngữ tự nhiên, bỏ mã
///    `BR-NEW-15` và tiếng Anh nội bộ ("open", "system") khiến người
///    dùng cảm giác như đang đọc log hệ thống.
/// 2. Thêm loading state + snackbar thành công để user biết thao tác
///    có đang được xử lý hay không (trước đây nút bấm xong im lặng).
/// 3. Tóm tắt "giờ cũ → giờ mới" để user thấy rõ mình sắp đổi sang
///    khung giờ nào, tránh bấm nhầm.
///
/// **Lưu ý BR (BR-NEW-15, 2026-08-18):** Chỉ gửi
/// `preferredStartTime` / `preferredEndTime` (HH:mm:ss) — server dùng
/// `JsonIgnore(Condition = WhenWritingNull)` để giữ field nào user
/// không thay đổi.
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

  /// Track trạng thái submit để disable button + show spinner.
  /// Trước đây không có flag này → nút "Xác nhận" nhìn như đứng im
  /// trong khi request đang chạy, user tưởng bị lỗi và bấm đi bấm lại.
  bool _isSubmitting = false;

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
    if (_isSubmitting) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Chọn giờ bắt đầu',
      cancelText: 'Huỷ',
      confirmText: 'Xong',
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
    if (_isSubmitting) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _end ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Chọn giờ kết thúc',
      cancelText: 'Huỷ',
      confirmText: 'Xong',
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
    if (_isSubmitting) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần chọn cả giờ bắt đầu và giờ kết thúc nhé'),
        ),
      );
      return;
    }
    final startMinutes = _start!.hour * 60 + _start!.minute;
    final endMinutes = _end!.hour * 60 + _end!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giờ kết thúc phải sau giờ bắt đầu'),
        ),
      );
      return;
    }

    // Lock UI + show spinner trong khi request đang chạy. Trước đây
    // thiếu flag này → user bấm nhiều lần, gửi nhiều request trùng nhau.
    setState(() => _isSubmitting = true);

    final cubit = context.read<LobbyCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.changeLobbyTime(
      lobbyId: widget.lobby.id,
      preferredStartTime: _toHHMMSS(_start!),
      preferredEndTime: _toHHMMSS(_end!),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        // Lỗi từ server (vd: buffer không đủ 60 phút, ngoài giờ mở cửa
        // của quán). Hiển thị ngay — trước đây dựa vào BlocListener
        // của sheet nhưng listener đôi lúc không fire đúng nếu state
        // cubit đã chuyển trạng thái khác từ realtime stream, dẫn đến
        // user bấm xong thấy im lặng.
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      (lobby) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật giờ mới cho cả nhóm'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        // Trả về true để caller (nếu cần) biết thao tác thành công.
        navigator.pop(true);
      },
    );
  }

  /// So sánh với giờ cũ → render card "Tóm tắt thay đổi" hoặc ẩn
  /// đi nếu user chưa đổi gì.
  bool get _hasChanges {
    if (_start == null || _end == null) return false;
    final oldStart = _parseHHMMSS(widget.lobby.preferredStartTime);
    final oldEnd = _parseHHMMSS(widget.lobby.preferredEndTime);
    if (oldStart == null || oldEnd == null) return true;
    return oldStart.hour != _start!.hour ||
        oldStart.minute != _start!.minute ||
        oldEnd.hour != _end!.hour ||
        oldEnd.minute != _end!.minute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocListener<LobbyCubit, LobbyState>(
      // Catch lỗi cubit nếu vì lý do nào đó (vd: realtime fail) mà
      // snackbar trong `_submit` không hiển thị kịp. Lúc đó cubit vẫn
      // emit LobbyFailure qua các flow khác, listener này sẽ bắt được
      // để user không bị bỏ lửng.
      listenWhen: (prev, curr) => prev is! LobbyFailure && curr is LobbyFailure,
      listener: (context, state) {
        if (state is LobbyFailure && mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
              ),
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
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề + icon
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: colors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi giờ gặp mặt',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật lại khung giờ cả nhóm sẽ gặp nhau tại quán',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tóm tắt thay đổi (chỉ hiện khi user đã chọn khác giờ cũ)
              if (_hasChanges) ...[
                _ChangeSummary(
                  oldStart: _parseHHMMSS(widget.lobby.preferredStartTime),
                  oldEnd: _parseHHMMSS(widget.lobby.preferredEndTime),
                  newStart: _start,
                  newEnd: _end,
                ),
                const SizedBox(height: 16),
              ],

              _TimeField(
                icon: Icons.play_arrow_rounded,
                label: 'Giờ bắt đầu',
                value: _start,
                onTap: _isSubmitting ? null : _pickStart,
              ),
              const SizedBox(height: 12),
              _TimeField(
                icon: Icons.stop_rounded,
                label: 'Giờ kết thúc',
                value: _end,
                onTap: _isSubmitting ? null : _pickEnd,
              ),

              const SizedBox(height: 12),

              // Lưu ý nhỏ cho user — ngôn ngữ tự nhiên, không có mã BR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quán phải đang mở cửa trong khung giờ bạn chọn. '
                        'Mọi người trong phòng sẽ nhận được thông báo ngay.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSecondaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          (_isSubmitting || !_hasChanges) ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu thay đổi'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

class _ChangeSummary extends StatelessWidget {
  final TimeOfDay? oldStart;
  final TimeOfDay? oldEnd;
  final TimeOfDay? newStart;
  final TimeOfDay? newEnd;

  const _ChangeSummary({
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
  });

  String _format(TimeOfDay? t) {
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Thay đổi của bạn',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DiffRow(
            label: 'Bắt đầu',
            oldValue: _format(oldStart),
            newValue: _format(newStart),
          ),
          const SizedBox(height: 4),
          _DiffRow(
            label: 'Kết thúc',
            oldValue: _format(oldEnd),
            newValue: _format(newEnd),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;

  const _DiffRow({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
        ),
        Text(
          oldValue,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onPrimaryContainer.withValues(alpha: 0.6),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: colors.onPrimaryContainer.withValues(alpha: 0.6),
          ),
        ),
        Text(
          newValue,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay? value;
  final VoidCallback? onTap;

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
    final colors = theme.colorScheme;
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
