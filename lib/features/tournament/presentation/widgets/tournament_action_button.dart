import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';

class TournamentActionButton extends StatelessWidget {
  final TournamentEntity tournament;
  final bool isRegistering;
  final void Function() onRegister;
  final void Function() onUnregister;

  const TournamentActionButton({
    super.key,
    required this.tournament,
    required this.isRegistering,
    required this.onRegister,
    required this.onUnregister,
  });

  @override
  Widget build(BuildContext context) {
    final canRegister = tournament.canRegister;
    final canWithdraw = tournament.canWithdraw;
    final hasAction = canRegister || canWithdraw;

    if (!hasAction) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(AppIcons.info),
          label: const Text('Hiện chưa mở đăng ký'),
        ),
      );
    }

    final isWithdraw = tournament.isUserRegistered && canWithdraw;
    final label = isWithdraw ? 'Rút lui khỏi giải' : 'Đăng ký tham gia';
    final icon = isWithdraw ? AppIcons.close : AppIcons.userCheck;
    final onPressed = isWithdraw ? onUnregister : onRegister;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isRegistering ? null : onPressed,
        icon: isRegistering
            ? const SizedBox(
                width: AppIcons.sm,
                height: AppIcons.sm,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(isRegistering ? 'Đang xử lý...' : label),
      ),
    );
  }
}
