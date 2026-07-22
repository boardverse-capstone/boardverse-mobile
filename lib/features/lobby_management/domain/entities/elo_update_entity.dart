import 'package:equatable/equatable.dart';

/// Thông tin thay đổi Elo của một user.
class EloUpdateEntity extends Equatable {
  /// ID của user.
  final String odId;

  /// Kết quả đã report (Win/Loss/Draw).
  final String reportedOutcome;

  /// Elo trước khi update.
  final int eloBefore;

  /// Elo sau khi update.
  final int eloAfter;

  /// Thay đổi Elo (+/- điểm).
  final int eloDelta;

  const EloUpdateEntity({
    required this.odId,
    required this.reportedOutcome,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
  });

  /// Kiểm tra Elo có tăng không.
  bool get isGain => eloDelta > 0;

  /// Kiểm tra Elo có giảm không.
  bool get isLoss => eloDelta < 0;

  @override
  List<Object?> get props => [odId, reportedOutcome, eloBefore, eloAfter, eloDelta];
}
