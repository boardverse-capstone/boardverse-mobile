import 'package:flutter/material.dart';
import '../../domain/entities/deposit_entity.dart';

class DepositStatusCard extends StatelessWidget {
  final List<DepositRecord> records;
  final double amount;
  final VoidCallback? onDeposit;

  const DepositStatusCard({
    super.key,
    required this.records,
    required this.amount,
    this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidCount = records.where((r) => r.hasDeposited).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái đặt cọc',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paidCount == records.length
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$paidCount/${records.length} đã đóng',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: paidCount == records.length
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...records.map(
              (record) => _DepositMemberTile(record: record, onTap: () {}),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số tiền cọc mỗi người',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _formatCurrency(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (onDeposit != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDeposit,
                  icon: const Icon(Icons.payment),
                  label: const Text('Đóng tiền cọc'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ';
  }
}

class _DepositMemberTile extends StatelessWidget {
  final DepositRecord record;
  final VoidCallback onTap;

  const _DepositMemberTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
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
              padding: const EdgeInsets.all(2),
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
      title: Text(
        record.userName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: record.hasDeposited
              ? Colors.green.shade100
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          record.hasDeposited ? 'Đã đóng' : 'Chưa đóng',
          style: theme.textTheme.labelSmall?.copyWith(
            color: record.hasDeposited
                ? Colors.green.shade800
                : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
