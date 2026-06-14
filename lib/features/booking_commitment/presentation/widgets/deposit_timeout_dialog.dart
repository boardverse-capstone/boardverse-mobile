import 'package:flutter/material.dart';

class DepositTimeoutDialog extends StatelessWidget {
  final double? refundAmount;
  final int? karmaPenalty;
  final VoidCallback onConfirm;

  const DepositTimeoutDialog({
    super.key,
    this.refundAmount,
    this.karmaPenalty,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Colors.red.shade700,
        size: 48,
      ),
      title: const Text('Hết thời gian đặt cọc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Một thành viên không đóng cọc đúng hạn. Phòng đã bị hủy.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (refundAmount != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Tiền cọc đã hoàn trả',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (karmaPenalty != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_down, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Điểm Karma bị trừ: $karmaPenalty',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onConfirm,
          child: const Text('Đã hiểu'),
        ),
      ],
    );
  }
}
