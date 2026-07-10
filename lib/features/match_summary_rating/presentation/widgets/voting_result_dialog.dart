import 'package:flutter/material.dart';

import '../cubit/voting_state.dart';

/// Dialog hiển thị kết quả voting.
class VotingResultDialog extends StatelessWidget {
  final List<VotingCandidate> noShowPlayers;
  final List<VotingCandidate> attendedPlayers;
  final VoidCallback onContinue;

  const VotingResultDialog({
    super.key,
    required this.noShowPlayers,
    required this.attendedPlayers,
    required this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required List<VotingCandidate> noShowPlayers,
    required List<VotingCandidate> attendedPlayers,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VotingResultDialog(
        noShowPlayers: noShowPlayers,
        attendedPlayers: attendedPlayers,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNoShow = noShowPlayers.isNotEmpty;

    return AlertDialog(
      icon: Icon(
        hasNoShow ? Icons.warning_amber : Icons.check_circle,
        size: 48,
        color: hasNoShow ? Colors.orange.shade600 : Colors.green.shade600,
      ),
      title: Text(
        hasNoShow ? 'Kết quả bình chọn' : 'Không có người vắng mặt',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasNoShow) ...[
                Text(
                  'Người bị đánh dấu vắng mặt (No-show):',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...noShowPlayers.map((player) => _PlayerTile(
                      candidate: player,
                      color: Colors.red.shade100,
                      icon: Icons.person_off,
                      iconColor: Colors.red,
                    )),
                const SizedBox(height: 16),
              ],
              Text(
                'Người có mặt:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              if (attendedPlayers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Không có dữ liệu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              else
                ...attendedPlayers.map((player) => _PlayerTile(
                      candidate: player,
                      color: Colors.green.shade50,
                      icon: Icons.person,
                      iconColor: Colors.green,
                    )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasNoShow
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasNoShow
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasNoShow ? Icons.info_outline : Icons.check_circle_outline,
                      color: hasNoShow
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasNoShow
                            ? 'Điểm uy tín (Karma) của người vắng mặt sẽ bị giảm.'
                            : 'Tất cả thành viên đều có mặt. Cảm ơn!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasNoShow
                              ? Colors.orange.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onContinue();
          },
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final VotingCandidate candidate;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _PlayerTile({
    required this.candidate,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              candidate.name[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              candidate.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (candidate.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Host',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Icon(icon, size: 18, color: iconColor),
        ],
      ),
    );
  }
}
