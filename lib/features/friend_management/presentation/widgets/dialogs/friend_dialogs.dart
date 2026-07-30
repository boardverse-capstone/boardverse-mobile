import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Dialog for confirming destructive friend actions (unfriend, block).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive
                ? Theme.of(dialogContext).colorScheme.error
                : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Result from report dialog.
class ReportResult {
  const ReportResult({required this.category, required this.reason});
  final String category;
  final String reason;
}

/// Dialog for reporting a user.
Future<ReportResult?> showReportDialog(BuildContext context) async {
  final theme = Theme.of(context);
  const categories = [
    'Spam',
    'Harassment',
    'FakeAccount',
    'InappropriateContent',
    'Other',
  ];
  var selectedCategory = categories.first;
  final reasonController = TextEditingController();

  return showDialog<ReportResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Báo cáo người chơi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại vi phạm',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (value) {
                          if (value) setState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: reasonController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Lý do chi tiết (5–1000 ký tự)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.length < 5) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Lý do phải có ít nhất 5 ký tự.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    ReportResult(
                      category: selectedCategory,
                      reason: reason,
                    ),
                  );
                },
                child: const Text('Gửi báo cáo'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Helper to show a snackbar message.
void showActionSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      duration: duration,
    ),
  );
}
