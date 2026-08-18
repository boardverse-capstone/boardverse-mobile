import 'package:boardverse/features/matchmaking_discovery/data/models/default_time_slot_model.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/default_time_slot_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeSlotKey', () {
    test('apiName trả về PascalCase đúng spec backend', () {
      expect(TimeSlotKey.morning.apiName, 'Morning');
      expect(TimeSlotKey.afternoon.apiName, 'Afternoon');
      expect(TimeSlotKey.evening.apiName, 'Evening');
      expect(TimeSlotKey.lateNight.apiName, 'LateNight');
    });

    test('displayLabel trả về nhãn tiếng Việt cho UI', () {
      expect(TimeSlotKey.morning.displayLabel, 'Sáng');
      expect(TimeSlotKey.afternoon.displayLabel, 'Chiều');
      expect(TimeSlotKey.evening.displayLabel, 'Tối');
      expect(TimeSlotKey.lateNight.displayLabel, 'Khuya');
    });

    test('fromApiName parse được đúng các giá trị backend', () {
      expect(TimeSlotKey.fromApiName('Morning'), TimeSlotKey.morning);
      expect(TimeSlotKey.fromApiName('Afternoon'), TimeSlotKey.afternoon);
      expect(TimeSlotKey.fromApiName('Evening'), TimeSlotKey.evening);
      expect(TimeSlotKey.fromApiName('LateNight'), TimeSlotKey.lateNight);
    });

    test('fromApiName trả về null cho unknown / null', () {
      expect(TimeSlotKey.fromApiName(null), isNull);
      expect(TimeSlotKey.fromApiName(''), isNull);
      expect(TimeSlotKey.fromApiName('night'), isNull);
      expect(TimeSlotKey.fromApiName('late_night'), isNull);
    });
  });

  group('DefaultTimeSlotModel.fromJson', () {
    test('parse đầy đủ các field từ response backend mẫu', () {
      final json = {
        'slot': 'Morning',
        'displayName': 'Sáng',
        'defaultStartTime': '06:00:00',
        'defaultEndTime': '12:00:00',
        'durationMinutes': 360,
        'description': 'Phiên sáng (06:00 – 12:00)',
      };

      final model = DefaultTimeSlotModel.fromJson(json);

      expect(model.slot, TimeSlotKey.morning);
      expect(model.displayName, 'Sáng');
      expect(model.defaultStartTime, '06:00:00');
      expect(model.defaultEndTime, '12:00:00');
      expect(model.durationMinutes, 360);
      expect(model.description, 'Phiên sáng (06:00 – 12:00)');
    });

    test('LateNight slot được parse đúng (đặc biệt vì tên khác local enum)',
        () {
      final json = {
        'slot': 'LateNight',
        'displayName': 'Khuya',
        'defaultStartTime': '23:00:00',
        'defaultEndTime': '06:00:00',
        'durationMinutes': 420,
        'description': 'Phiên khuya qua đêm (23:00 – 06:00 hôm sau)',
      };

      final model = DefaultTimeSlotModel.fromJson(json);

      expect(model.slot, TimeSlotKey.lateNight);
      expect(model.durationMinutes, 420);
      expect(model.defaultEndTime, '06:00:00');
    });

    test('thiếu slot thì fallback về morning (không throw)', () {
      final json = {
        'displayName': 'Sáng',
        'defaultStartTime': '06:00:00',
        'defaultEndTime': '12:00:00',
        'durationMinutes': 360,
        'description': '',
      };
      final model = DefaultTimeSlotModel.fromJson(json);
      expect(model.slot, TimeSlotKey.morning);
    });

    test('thiếu displayName thì dùng label hardcode', () {
      final json = {
        'slot': 'Evening',
        'defaultStartTime': '17:00:00',
        'defaultEndTime': '23:00:00',
        'durationMinutes': 360,
        'description': 'Phiên tối',
      };
      final model = DefaultTimeSlotModel.fromJson(json);
      expect(model.displayName, 'Tối');
    });

    test('thiếu durationMinutes thì default về 0 (không throw)', () {
      final json = {
        'slot': 'Afternoon',
        'displayName': 'Chiều',
        'defaultStartTime': '12:00:00',
        'defaultEndTime': '17:00:00',
        'description': '',
      };
      final model = DefaultTimeSlotModel.fromJson(json);
      expect(model.durationMinutes, 0);
    });

    test('durationMinutes là double (vd 360.0) vẫn parse được', () {
      final json = {
        'slot': 'Morning',
        'displayName': 'Sáng',
        'defaultStartTime': '06:00:00',
        'defaultEndTime': '12:00:00',
        'durationMinutes': 360.0,
        'description': '',
      };
      final model = DefaultTimeSlotModel.fromJson(json);
      expect(model.durationMinutes, 360);
      expect(model.durationMinutes, isA<int>());
    });
  });

  group('DefaultTimeSlotEntity', () {
    test('props bao gồm tất cả field để Equatable so sánh đúng', () {
      const a = DefaultTimeSlotEntity(
        slot: TimeSlotKey.morning,
        displayName: 'Sáng',
        defaultStartTime: '06:00:00',
        defaultEndTime: '12:00:00',
        durationMinutes: 360,
        description: 'Phiên sáng',
      );
      const b = DefaultTimeSlotEntity(
        slot: TimeSlotKey.morning,
        displayName: 'Sáng',
        defaultStartTime: '06:00:00',
        defaultEndTime: '12:00:00',
        durationMinutes: 360,
        description: 'Phiên sáng',
      );

      expect(a, equals(b));
    });

    test('2 entity khác durationMinutes là khác nhau', () {
      const a = DefaultTimeSlotEntity(
        slot: TimeSlotKey.morning,
        displayName: 'Sáng',
        defaultStartTime: '06:00:00',
        defaultEndTime: '12:00:00',
        durationMinutes: 360,
        description: '',
      );
      const b = DefaultTimeSlotEntity(
        slot: TimeSlotKey.morning,
        displayName: 'Sáng',
        defaultStartTime: '06:00:00',
        defaultEndTime: '12:00:00',
        durationMinutes: 300,
        description: '',
      );

      expect(a, isNot(equals(b)));
    });
  });
}