import '../models/deposit_model.dart';
import '../models/booking_qr_model.dart';

/// Mock data source for booking commitment feature.
/// Provides realistic sample data for UI development and testing.
class MockBookingDatasource {
  // ─── Deposit Status List ───────────────────────────────────────────────

  /// Trạng thái nộp tiền cọc real-time của từng thành viên
  static DepositModel get mockDepositStatusList => DepositModel(
        id: 'deposit_001',
        lobbyId: 'lobby_001',
        bookingId: '',
        amount: 50000,
        status: DepositStatusModel.pending,
        deadline: DateTime.now().add(const Duration(minutes: 5)),
        records: const [
          DepositRecordModel(
            oduserId: 'user_001',
            userName: 'Minh Player',
            avatarUrl: 'https://i.pravatar.cc/150?u=minh',
            hasDeposited: true,
            depositedAt: '2024-01-15T10:15:00Z',
          ),
          DepositRecordModel(
            oduserId: 'user_002',
            userName: 'Thu Hà',
            avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
            hasDeposited: false,
            depositedAt: null,
          ),
          DepositRecordModel(
            oduserId: 'user_003',
            userName: 'Anh Khoa',
            avatarUrl: 'https://i.pravatar.cc/150?u=anhkhoa',
            hasDeposited: true,
            depositedAt: '2024-01-15T10:16:00Z',
          ),
          DepositRecordModel(
            oduserId: 'user_004',
            userName: 'Lan Chi',
            avatarUrl: 'https://i.pravatar.cc/150?u=lanchi',
            hasDeposited: false,
            depositedAt: null,
          ),
          DepositRecordModel(
            oduserId: 'user_005',
            userName: 'Hoàng Nam',
            avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
            hasDeposited: true,
            depositedAt: '2024-01-15T10:17:00Z',
          ),
        ],
      );

  // ─── Deposit Timeout Error ─────────────────────────────────────────────

  /// Nội dung thông báo hủy phòng khi quá hạn
  static DepositTimeoutModel get mockDepositTimeoutError =>
      const DepositTimeoutModel(
        title: 'Hết thời gian đặt cọc',
        message:
            'Một thành viên không đóng cọc đúng hạn. Phòng đã bị hủy, tiền cọc đã hoàn trả và điểm Karma đã bị trừ.',
        showRefundInfo: true,
        refundAmount: 100000,
        karmaPenalty: -5,
        showPenaltyBadge: true,
      );

  // ─── Booking QR Payload ────────────────────────────────────────────────

  /// Chuỗi dữ liệu mã hóa QR Code Booking
  static BookingQrModel get mockBookingQrPayload => BookingQrModel(
        bookingId: 'BOOK2024_001',
        cafeName: 'Board Game Hub District 1',
        gameName: 'Avalon: The Resistance Game',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        tableNumber: 5,
        playerNames: 'Minh, Thu Hà, Anh Khoa, Lan Chi, Hoàng Nam',
        qrPayload:
            'BOARDVERSE|BOOK2024_001|cafe_001|bg_001|20240115T113000|5|Minh,ThuHa,AnhKhoa,LanChi,HoangNam',
      );

  // ─── No Show History Badge ────────────────────────────────────────────

  /// Nhãn trạng thái "Vắng mặt (No-Show)"
  static BookingHistoryModel get mockNoShowHistoryBadge => BookingHistoryModel(
        id: 'history_001',
        cafeName: 'Meeple Station',
        gameName: 'Ma Sói',
        scheduledTime: DateTime.now().subtract(const Duration(days: 2)),
        actualCheckinTime: null,
        status: BookingHistoryStatusModel.noShow,
        hasNoShowBadge: true,
      );

  // ─── Helper Methods ───────────────────────────────────────────────────

  /// Cập nhật trạng thái deposit khi một thành viên đóng cọc
  static DepositModel simulateDepositMade(
      DepositModel deposit, String userId) {
    final updatedRecords = deposit.records.map((record) {
      if (record.oduserId == userId) {
        return DepositRecordModel(
          oduserId: record.oduserId,
          userName: record.userName,
          avatarUrl: record.avatarUrl,
          hasDeposited: true,
          depositedAt: DateTime.now().toIso8601String(),
        );
      }
      return record;
    }).toList();

    final allDeposited = updatedRecords.every((r) => r.hasDeposited);

    return DepositModel(
      id: deposit.id,
      lobbyId: deposit.lobbyId,
      bookingId: deposit.bookingId,
      amount: deposit.amount,
      status: allDeposited ? DepositStatusModel.allPaid : DepositStatusModel.partiallyPaid,
      deadline: deposit.deadline,
      records: updatedRecords,
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────────────────────

class DepositTimeoutModel {
  final String title;
  final String message;
  final bool showRefundInfo;
  final double refundAmount;
  final int karmaPenalty;
  final bool showPenaltyBadge;

  const DepositTimeoutModel({
    required this.title,
    required this.message,
    required this.showRefundInfo,
    required this.refundAmount,
    required this.karmaPenalty,
    required this.showPenaltyBadge,
  });
}
