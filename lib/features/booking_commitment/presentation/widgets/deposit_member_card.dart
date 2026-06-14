import 'package:flutter/material.dart';
import '../../domain/entities/deposit_entity.dart';

class DepositMemberCard extends StatelessWidget {
  final DepositRecord record;
  final bool isCurrentUser;
  final bool canDeposit;

  const DepositMemberCard({
    super.key,
    required this.record,
    this.isCurrentUser = false,
    this.canDeposit = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isCurrentUser
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(record.avatarUrl),
              onBackgroundImageError: (_, _) {},
              child: record.avatarUrl.isEmpty
                  ? Text(record.userName[0].toUpperCase())
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: record.hasDeposited ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  record.hasDeposited ? Icons.check : Icons.schedule,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              record.userName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bạn',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          record.hasDeposited
              ? 'Đã đóng lúc ${_formatTime(record.depositedAt)}'
              : 'Chưa đóng',
          style: theme.textTheme.bodySmall?.copyWith(
            color: record.hasDeposited
                ? Colors.green
                : theme.colorScheme.outline,
          ),
        ),
        trailing: isCurrentUser && !record.hasDeposited && canDeposit
            ? FilledButton(onPressed: () {}, child: const Text('Đóng cọc'))
            : record.hasDeposited
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
