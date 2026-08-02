import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_rating_submission_entity.dart';
import '../../domain/entities/rating_status_entity.dart';
import '../../domain/repositories/booking_repository.dart';

/// Bottom sheet chấm điểm các thành viên trong lobby (gap #5).
///
/// Voter chấm cho từng thành viên khác (không chấm chính mình). Mỗi thành viên
/// có 3 tiêu chí 1-5: attitude, sportsmanship, punctuality.
class RatingFormSheet extends StatefulWidget {
  final BookingEntity booking;
  final RatingStatusEntity? ratingStatus;
  final BookingRepository repository;

  const RatingFormSheet({
    super.key,
    required this.booking,
    required this.repository,
    this.ratingStatus,
  });

  @override
  State<RatingFormSheet> createState() => _RatingFormSheetState();
}

class _RatingFormSheetState extends State<RatingFormSheet> {
  final Map<String, RatingItemEntity> _ratings = {};
  bool _submitting = false;

  /// Members được phép chấm (trừ voter = mình).
  List<String> get _rateableMembers {
    final all = widget.booking.lobbySummary?.memberIds ??
        widget.booking.memberIds;
    return all;
  }

  Future<void> _submit() async {
    if (_ratings.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final submission = BookingRatingSubmissionEntity(
      bookingId: widget.booking.id,
      ratings: _ratings.values.toList(),
    );
    final result = await widget.repository.submitRatings(submission);
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
    final members = _rateableMembers;
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
                  Icons.star_rate_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Chấm điểm các thành viên',
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
              'Đánh giá 1-5 sao. Karma của thành viên sẽ được cập nhật sau khi gửi.',
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
                  return _RatingMemberCard(
                    userId: userId,
                    onChanged: (item) {
                      setState(() {
                        if (item == null) {
                          _ratings.remove(userId);
                        } else {
                          _ratings[userId] = item;
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _ratings.isEmpty || _submitting ? null : _submit,
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
                    : 'Gửi chấm điểm (${_ratings.length})',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingMemberCard extends StatefulWidget {
  final String userId;

  /// Callback khi đã chọn đủ 3 tiêu chí (return null = chưa hoàn tất).
  final ValueChanged<RatingItemEntity?> onChanged;

  const _RatingMemberCard({
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_RatingMemberCard> createState() => _RatingMemberCardState();
}

class _RatingMemberCardState extends State<_RatingMemberCard> {
  int _attitude = 3;
  int _sportsmanship = 3;
  int _punctuality = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  void _notify() {
    widget.onChanged(
      RatingItemEntity(
        ratedUserId: widget.userId,
        attitude: _attitude,
        sportsmanship: _sportsmanship,
        punctuality: _punctuality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thành viên: ${widget.userId.length > 8 ? widget.userId.substring(0, 8) : widget.userId}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _starRow('Thái độ', _attitude, (v) {
              setState(() => _attitude = v);
              _notify();
            }),
            _starRow('Tinh thần thể thao', _sportsmanship, (v) {
              setState(() => _sportsmanship = v);
              _notify();
            }),
            _starRow('Đúng giờ', _punctuality, (v) {
              setState(() => _punctuality = v);
              _notify();
            }),
          ],
        ),
      ),
    );
  }

  Widget _starRow(String label, int current, ValueChanged<int> onChange) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () => onChange(star),
                icon: Icon(
                  star <= current ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade600,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}