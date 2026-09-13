import 'package:equatable/equatable.dart';
import '../../domain/entities/in_game_session_entity.dart';
import '../../domain/entities/player_session_entity.dart';
import '../../domain/entities/session_payment_entity.dart';

sealed class InGameState extends Equatable {
  const InGameState();

  @override
  List<Object?> get props => [];
}

class InGameInitial extends InGameState {
  const InGameInitial();
}

class InGameLoading extends InGameState {
  const InGameLoading();
}

/// State khi đã load được phiên chơi từ API
class InGamePlayerSessionLoaded extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;

  const InGamePlayerSessionLoaded({
    required this.session,
    required this.currentDuration,
  });

  @override
  List<Object?> get props => [session, currentDuration];
}

/// State đang gia hạn phiên chơi
class InGameExtending extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final int requestedMinutes;

  const InGameExtending({
    required this.session,
    required this.currentDuration,
    required this.requestedMinutes,
  });

  @override
  List<Object?> get props => [session, currentDuration, requestedMinutes];
}

/// State khi yêu cầu gia hạn thành công
class InGameExtensionRequested extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final ExtensionRequestEntity extensionRequest;

  const InGameExtensionRequested({
    required this.session,
    required this.currentDuration,
    required this.extensionRequest,
  });

  @override
  List<Object?> get props => [session, currentDuration, extensionRequest];
}

/// State đang xử lý thanh toán BVC
class InGamePaymentProcessing extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;

  const InGamePaymentProcessing({
    required this.session,
    required this.currentDuration,
  });

  @override
  List<Object?> get props => [session, currentDuration];
}

/// State khi thanh toán thành công
class InGamePaymentSuccess extends InGameState {
  final PlayerSessionEntity session;
  final SessionPaymentResultEntity paymentResult;

  const InGamePaymentSuccess({
    required this.session,
    required this.paymentResult,
  });

  @override
  List<Object?> get props => [session, paymentResult];
}

/// State khi thanh toán thất bại
class InGamePaymentFailure extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final String message;
  final int? requiredBvc;
  final int? currentBalance;

  const InGamePaymentFailure({
    required this.session,
    required this.currentDuration,
    required this.message,
    this.requiredBvc,
    this.currentBalance,
  });

  @override
  List<Object?> get props => [session, currentDuration, message, requiredBvc, currentBalance];
}

/// Legacy state - vẫn giữ để tương thích
class InGameSessionActive extends InGameState {
  final InGameSessionEntity session;
  final Duration currentDuration;

  const InGameSessionActive({
    required this.session,
    required this.currentDuration,
  });

  @override
  List<Object?> get props => [session, currentDuration];
}

/// Legacy state
class InGameCheckingInventory extends InGameState {
  final InGameSessionEntity session;

  const InGameCheckingInventory({required this.session});

  @override
  List<Object?> get props => [session];
}

/// Legacy state
class InGameCheckoutComplete extends InGameState {
  final double totalAmount;
  final double depositPaid;
  final double remainingAmount;

  const InGameCheckoutComplete({
    required this.totalAmount,
    required this.depositPaid,
    required this.remainingAmount,
  });

  @override
  List<Object?> get props => [totalAmount, depositPaid, remainingAmount];
}

/// Legacy state
class InGameSessionEnded extends InGameState {
  final Duration totalDuration;
  final DateTime startTime;
  final DateTime endTime;

  const InGameSessionEnded({
    required this.totalDuration,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [totalDuration, startTime, endTime];
}

class InGameFailure extends InGameState {
  final String message;

  const InGameFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State khi không có phiên chơi nào đang hoạt động
class InGameNoActiveSession extends InGameState {
  const InGameNoActiveSession();
}

// ─── Split Bill States ──────────────────────────────────────────────────────

/// State đang tải thông tin Split Bill
class InGameSplitBillLoading extends InGameState {
  const InGameSplitBillLoading();
}

/// State khi đã load được thông tin Split Bill
class InGameSplitBillLoaded extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final List<MemberPaymentInfo> members;
  final MemberPaymentInfo? currentUserPayment;

  const InGameSplitBillLoaded({
    required this.session,
    required this.currentDuration,
    required this.members,
    this.currentUserPayment,
  });

  int get paidCount => members.where((m) => m.isPaid).length;
  int get pendingCount => members.where((m) => !m.isPaid).length;

  @override
  List<Object?> get props => [session, currentDuration, members, currentUserPayment];
}

/// State đang polling để kiểm tra thanh toán
class InGameSplitBillPolling extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final MemberPaymentInfo currentUserPayment;
  final int pollCount;

  const InGameSplitBillPolling({
    required this.session,
    required this.currentDuration,
    required this.currentUserPayment,
    this.pollCount = 0,
  });

  @override
  List<Object?> get props => [session, currentDuration, currentUserPayment, pollCount];
}

/// State khi thanh toán Split Bill thành công
class InGameSplitBillPaymentSuccess extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final MemberPaymentInfo paymentInfo;

  const InGameSplitBillPaymentSuccess({
    required this.session,
    required this.currentDuration,
    required this.paymentInfo,
  });

  @override
  List<Object?> get props => [session, currentDuration, paymentInfo];
}

/// State khi không tìm thấy thông tin Split Bill
class InGameSplitBillNotFound extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final String message;

  const InGameSplitBillNotFound({
    required this.session,
    required this.currentDuration,
    required this.message,
  });

  @override
  List<Object?> get props => [session, currentDuration, message];
}

/// State lỗi khi tải Split Bill
class InGameSplitBillError extends InGameState {
  final PlayerSessionEntity session;
  final Duration currentDuration;
  final String message;

  const InGameSplitBillError({
    required this.session,
    required this.currentDuration,
    required this.message,
  });

  @override
  List<Object?> get props => [session, currentDuration, message];
}
