// Unit tests cho TransactionEntity:
// - Wire name khớp PascalCase backend (swagger LedgerEntryType)
// - direction / isCredit / isDebit mapping đúng cho từng loại
// - Adjustment đảo chiều theo dấu amount
// - amountVndAbs luôn dương (UI dùng direction để chọn prefix +/-)
// - TransactionModel.toJson dùng wireName (PascalCase) chứ không phải
//   snake_case của enum.name

import 'package:flutter_test/flutter_test.dart';
import 'package:boardverse_mobile/features/wallet/data/models/transaction_model.dart';
import 'package:boardverse_mobile/features/wallet/domain/entities/transaction_entity.dart';

void main() {
  TransactionEntity make({
    required TransactionType type,
    required int amount,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: 'tx-1',
      type: type,
      amount: amount,
      balanceSnapshot: 100,
      note: note,
      createdAt: createdAt ?? DateTime.utc(2026, 8, 1),
    );
  }

  group('TransactionType wireName', () {
    test('match đúng PascalCase của swagger LedgerEntryType', () {
      expect(TransactionType.topUp.wireName, 'TopUp');
      expect(TransactionType.depositHold.wireName, 'DepositHold');
      expect(TransactionType.depositRelease.wireName, 'DepositRelease');
      expect(TransactionType.depositCapture.wireName, 'DepositCapture');
      expect(TransactionType.depositForfeit.wireName, 'DepositForfeit');
      expect(TransactionType.adjustment.wireName, 'Adjustment');
      expect(TransactionType.adminCredit.wireName, 'AdminCredit');
      expect(TransactionType.adminDebit.wireName, 'AdminDebit');
    });

    test('TransactionTypeNames constants khớp wireName', () {
      const pairs = <TransactionType, String>{
        TransactionType.topUp: TransactionTypeNames.topUp,
        TransactionType.depositHold: TransactionTypeNames.depositHold,
        TransactionType.depositRelease: TransactionTypeNames.depositRelease,
        TransactionType.depositCapture: TransactionTypeNames.depositCapture,
        TransactionType.depositForfeit: TransactionTypeNames.depositForfeit,
        TransactionType.adjustment: TransactionTypeNames.adjustment,
        TransactionType.adminCredit: TransactionTypeNames.adminCredit,
        TransactionType.adminDebit: TransactionTypeNames.adminDebit,
      };
      pairs.forEach((type, name) {
        expect(type.wireName, name, reason: 'wireName cho $type');
      });
    });

    test('fromString nhận PascalCase và ném FormatException cho value lạ', () {
      // Round-trip: wireName -> fromString
      for (final t in TransactionType.values) {
        expect(TransactionType.fromString(t.wireName), t);
      }

      // Value rác -> throw
      expect(
        () => TransactionType.fromString('top_up'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TransactionType.fromString('NapTien'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TransactionEntity direction (UX: cộng / trừ)', () {
    test('TopUp = credit', () {
      final tx = make(type: TransactionType.topUp, amount: 100);
      expect(tx.isCredit, isTrue);
      expect(tx.isDebit, isFalse);
    });

    test('DepositRelease = credit (hoàn cọc → ví tăng)', () {
      final tx = make(type: TransactionType.depositRelease, amount: 50);
      expect(tx.isCredit, isTrue);
    });

    test('AdminCredit = credit', () {
      final tx = make(type: TransactionType.adminCredit, amount: 30);
      expect(tx.isCredit, isTrue);
    });

    test('DepositHold = debit (trừ available, khóa vào held)', () {
      final tx = make(type: TransactionType.depositHold, amount: 50);
      expect(tx.isDebit, isTrue);
      expect(tx.isCredit, isFalse);
    });

    test('DepositCapture = debit', () {
      final tx = make(type: TransactionType.depositCapture, amount: 50);
      expect(tx.isDebit, isTrue);
    });

    test('DepositForfeit = debit', () {
      final tx = make(type: TransactionType.depositForfeit, amount: 50);
      expect(tx.isDebit, isTrue);
    });

    test('AdminDebit = debit', () {
      final tx = make(type: TransactionType.adminDebit, amount: 30);
      expect(tx.isDebit, isTrue);
    });

    test('Adjustment +amount = credit', () {
      final tx = make(type: TransactionType.adjustment, amount: 10);
      expect(tx.isCredit, isTrue);
    });

    test('Adjustment −amount = debit (đảo chiều theo dấu)', () {
      final tx = make(type: TransactionType.adjustment, amount: -25);
      expect(tx.isDebit, isTrue);
      expect(tx.isCredit, isFalse);
    });

    test('Adjustment amount = 0 mặc định coi là credit (fallback an toàn)',
        () {
      final tx = make(type: TransactionType.adjustment, amount: 0);
      expect(tx.isCredit, isTrue);
    });
  });

  group('TransactionEntity.amountVndAbs', () {
    test('luôn trả giá trị tuyệt đối × 1000 (UI dùng direction để hiện dấu)',
        () {
      expect(make(type: TransactionType.topUp, amount: 100).amountVndAbs,
          100000);
      expect(make(type: TransactionType.depositHold, amount: 50).amountVndAbs,
          50000);
      expect(make(type: TransactionType.adjustment, amount: -10).amountVndAbs,
          10000);
    });
  });

  group('TransactionModel (de)serialization', () {
    test('toJson dùng PascalCase wireName, không phải enum.name', () {
      final tx = make(type: TransactionType.depositHold, amount: 25);
      final json = (tx as TransactionModel).toJson();

      expect(json['type'], 'DepositHold');
      // Sanity: enum.name là 'depositHold' (snake_case) — phải KHÁC với
      // wireName để đảm bảo test có � nghĩa.
      expect(TransactionType.depositHold.name, 'depositHold');
      expect(json['type'], isNot(equals(TransactionType.depositHold.name)));
    });

    test('fromJson với payload backend thật → round-trip ok', () {
      final json = {
        'id': 'abc-123',
        'type': 'AdminDebit',
        'amount': 50,
        'relatedPaymentRef': null,
        'relatedLobbyId': null,
        'relatedBookingId': null,
        'balanceSnapshot': 100,
        'note': 'Penalty no-show',
        'createdAt': '2026-08-01T00:00:00Z',
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.type, TransactionType.adminDebit);
      expect(tx.isDebit, isTrue);
      expect(tx.note, 'Penalty no-show');
    });
  });
}
