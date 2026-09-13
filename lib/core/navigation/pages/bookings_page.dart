import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme.dart';
import '../../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../../features/reservation/presentation/cubit/my_reservations_cubit.dart';
import '../../../features/reservation/presentation/widgets/my_reservations_panel.dart';

/// Tab "Lịch đặt" — hiển thị danh sách reservation của user.
///
/// Sử dụng endpoint `GET /api/v1/reservations/my` (mới thêm Sep 2026) — gộp
/// cả reservation do user tạo (Host) và reservation user tham gia (Member).
///
/// **UI/UX:**
/// - Tab strip "Tôi tạo (N) | Tôi tham gia (M)" với count badge lấy từ
///   `hostedCount` / `joinedCount` trong response (server-authoritative).
/// - Tab Host → cam (primary), tab Member → xanh dương (info).
/// - Trên card: border + shadow tone theo role, kèm participation badge
///   "CHỦ PHÒNG" / "THÀNH VIÊN" để player phân biệt được ngay cả khi cuộn
///   nhanh qua nhiều card.
///
/// `MyReservationsCubit` được tạo ở cấp page để cubit sống xuyên suốt các
/// lần rebuild — tránh mất query khi user filter rồi rời page.
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocProvider<MyReservationsCubit>(
      create: (_) => MyReservationsCubit(
        repository: sl<ReservationRepository>(),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tiêu đề page — luôn nằm bên trái
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LỊCH ĐẶT',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lịch hẹn bạn tạo và lịch hẹn bạn tham gia',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: MyReservationsPanel(),
            ),
          ],
        ),
      ),
    );
  }
}