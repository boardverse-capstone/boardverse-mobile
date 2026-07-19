import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/entities/booking_history_entity.dart';
import 'status_pill.dart';

/// Centralized UI helpers for booking_payment — keeps text labels, colors,
/// icons and formatters consistent across all pages/widgets.
///
/// NOTE: this file is purely UI mapping. It does NOT alter business state
/// or mock data — it just reads existing fields and produces labels/colors.
class BookingUiHelpers {
  BookingUiHelpers._();

  // -----------------------
  // Status mapping (BookingStatus)
  // -----------------------

  static StatusPillVariant statusToVariant(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingDeposit:
        return StatusPillVariant.pendingDeposit;
      case BookingStatus.confirmed:
        return StatusPillVariant.confirmed;
      case BookingStatus.checkedIn:
        return StatusPillVariant.checkedIn;
      case BookingStatus.cancelledByPlayer:
        return StatusPillVariant.cancelledByPlayer;
      case BookingStatus.cancelledByCafe:
        return StatusPillVariant.cancelledByCafe;
      case BookingStatus.expired:
        return StatusPillVariant.expired;
    }
  }

  static String statusToLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingDeposit:
        return 'Chờ cọc';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đang chơi';
      case BookingStatus.cancelledByPlayer:
        return 'Đã hủy';
      case BookingStatus.cancelledByCafe:
        return 'Quán hủy';
      case BookingStatus.expired:
        return 'Hết hạn';
    }
  }

  /// Used by pages that still read status via `.name` (string).
  static StatusPillVariant variantFromStringName(String name) {
    switch (name) {
      case 'confirmed':
        return StatusPillVariant.confirmed;
      case 'checkedIn':
        return StatusPillVariant.checkedIn;
      case 'pendingDeposit':
        return StatusPillVariant.pendingDeposit;
      case 'cancelledByPlayer':
        return StatusPillVariant.cancelledByPlayer;
      case 'cancelledByCafe':
        return StatusPillVariant.cancelledByCafe;
      case 'expired':
        return StatusPillVariant.expired;
      default:
        return StatusPillVariant.neutral;
    }
  }

  static String labelFromStringName(String name) {
    switch (name) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedIn':
        return 'Đang chơi';
      case 'pendingDeposit':
        return 'Chờ cọc';
      case 'cancelledByPlayer':
        return 'Đã hủy';
      case 'cancelledByCafe':
        return 'Quán hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return name;
    }
  }

  // -----------------------
  // History status mapping
  // -----------------------

  static StatusPillVariant historyVariant(BookingHistoryStatus status) {
    switch (status) {
      case BookingHistoryStatus.upcoming:
        return StatusPillVariant.upcoming;
      case BookingHistoryStatus.completed:
        return StatusPillVariant.completed;
      case BookingHistoryStatus.cancelled:
        return StatusPillVariant.cancelled;
      case BookingHistoryStatus.noShow:
        return StatusPillVariant.noShow;
    }
  }

  static String historyLabel(BookingHistoryStatus status) {
    switch (status) {
      case BookingHistoryStatus.upcoming:
        return 'Sắp tới';
      case BookingHistoryStatus.completed:
        return 'Đã chơi';
      case BookingHistoryStatus.cancelled:
        return 'Đã huỷ';
      case BookingHistoryStatus.noShow:
        return 'Vắng';
    }
  }

  // -----------------------
  // Payment method mapping
  // -----------------------

  static IconData paymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sandboxMock:
        return Icons.science_rounded;
      case PaymentMethod.vnpay:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
    }
  }

  static Color paymentMethodColor(PaymentMethod method, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (method) {
      case PaymentMethod.sandboxMock:
        return AppColors.warning;
      case PaymentMethod.vnpay:
        return scheme.primary;
      case PaymentMethod.momo:
        return AppColors.error;
    }
  }

  // -----------------------
  // Formatting
  // -----------------------

  static String formatVnd(double v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${f.format(v).trim()} đ';
  }

  static String formatDateTime(DateTime dt, {String pattern = 'HH:mm — dd/MM'}) =>
      DateFormat(pattern).format(dt);

  static String formatLongDateTime(DateTime dt) =>
      DateFormat('EEEE, dd/MM/yyyy — HH:mm').format(dt);
}
