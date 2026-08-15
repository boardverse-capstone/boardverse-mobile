import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';

/// Neo-brutalism Tournament action button — register/unregister.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    if (!hasAction) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.info, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'HIỆN CHƯA MỞ ĐĂNG KÝ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isWithdraw = tournament.isUserRegistered && canWithdraw;
    final label = isWithdraw ? 'RÚT LUI KHỎI GIẢI' : 'ĐĂNG KÝ THAM GIA';
    final icon = isWithdraw ? AppIcons.close : AppIcons.userCheck;
    final onPressed = isWithdraw ? onUnregister : onRegister;
    final color = isWithdraw ? AppColors.error : AppColors.primary;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: color.withValues(alpha: 0.5),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isRegistering ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRegistering)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  else
                    Icon(icon, color: AppColors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isRegistering ? 'ĐANG XỬ LÝ...' : label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}