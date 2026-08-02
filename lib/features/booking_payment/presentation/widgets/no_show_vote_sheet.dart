import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';

/// Bottom sheet vote vắng mặt (gap #4).
///
/// User tick vào các thành viên KHÔNG có mặt tại quán trong khung giờ
/// booking. Submit → POST /api/bookings/{id}/no-show-votes.
class NoShowVoteSheet extends StatefulWidget {
  final BookingEntity booking;

  /// Repository dùng để submit vote.
  /// Inject qua constructor để testable.
  final BookingRepository repository;

  const NoShowVoteSheet({
    super.key,
    required this.booking,
    required this.repository,
  });

  @override
  State<NoShowVoteSheet> createState() => _NoShowVoteSheetState();
}

class _NoShowVoteSheetState extends State<NoShowVoteSheet> {
  final Set<String> _selected = <String>{};
  bool _submitting = false;

  /// Members hiển thị — lấy từ lobbySummary nếu có, fallback memberIds.
  List<String> get _memberIds {
    final summary = widget.booking.lobbySummary;
    if (summary != null && summary.memberIds.isNotEmpty) {
      return summary.memberIds;
    }
    return widget.booking.memberIds;
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final result = await widget.repository.submitNoShowVote(
      bookingId: widget.booking.id,
      absentMemberIds: _selected.toList(),
      votedAt: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (data) => Navigator.pop(context, data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = _memberIds;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.how_to_vote_rounded,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Vote vắng mặt',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chọn thành viên không có mặt tại quán. '
              'Khi vote đạt ngưỡng BR-10, cọc của họ sẽ bị tịch thu.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (ctx, index) {
                  final userId = members[index];
                  final isSelected = _selected.contains(userId);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _selected.add(userId);
                      } else {
                        _selected.remove(userId);
                      }
                    }),
                    title: Text('Thành viên: ${_shortId(userId)}'),
                    subtitle: const Text('Tick nếu vắng mặt tại quán'),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _selected.isEmpty || _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting
                    ? 'Đang gửi...'
                    : 'Gửi vote (${_selected.length})',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }
}