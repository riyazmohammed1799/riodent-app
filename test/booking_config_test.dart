import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/booking_config_model.dart';

void main() {
  group('BookingConfigModel unit tests', () {
    test('defaultConfig provides required MVP fields and default values', () {
      final config = BookingConfigModel.defaultConfig();

      expect(config.issueTypes, isNotEmpty);
      expect(config.activeIssueTypes, isNotEmpty);
      expect(config.slots, isNotEmpty);
      expect(config.maxDaysAhead, equals(7));
      expect(config.minLeadMinutes, equals(30));
      expect(config.serviceablePincodePrefixes, containsAll(['500', '501', '502']));
      expect(config.doctorCancelReasons, isNotEmpty);
      expect(config.adminCancelReasons, isNotEmpty);
      expect(config.supportPhone, isNotEmpty);
      expect(config.maxOpenRequests, equals(3));
    });

    test('issueTypes handles deduplication by code and active filter', () {
      final rawIssueTypes = [
        {'code': 'chair', 'label': 'Dental Chair', 'active': true},
        {'code': 'autoclave', 'label': 'Autoclave', 'active': true},
        {'code': 'chair', 'label': 'Dental Chair Duplicate', 'active': true}, // duplicate
        {'code': 'inactive_tech', 'label': 'Old Tool', 'active': false},
      ];

      final items = rawIssueTypes.map((m) => IssueTypeItem.fromMap(m)).toList();
      final deduplicated = IssueTypeItem.deduplicateByCode(items);

      expect(deduplicated.length, equals(3));
      expect(deduplicated.where((i) => i.code == 'chair').length, equals(1));
      expect(deduplicated.where((i) => i.active).length, equals(2));
    });

    test('isSlotBookable returns false if start is less than minLeadMinutes from now', () {
      // Slot 9 AM to 12 PM today
      final now = DateTime(2026, 10, 14, 8, 45); // 15 mins before 9 AM
      final slotStart = DateTime(2026, 10, 14, 9, 0);

      expect(BookingConfigModel.isSlotBookable(slotStart: slotStart, now: now, minLeadMinutes: 30), isFalse);

      final bookableNow = DateTime(2026, 10, 14, 8, 20); // 40 mins before 9 AM
      expect(BookingConfigModel.isSlotBookable(slotStart: slotStart, now: bookableNow, minLeadMinutes: 30), isTrue);
    });

    test('isSlotBookable rejects past dates and slots', () {
      final now = DateTime(2026, 10, 14, 10, 0);
      final pastSlotStart = DateTime(2026, 10, 14, 9, 0);
      expect(BookingConfigModel.isSlotBookable(slotStart: pastSlotStart, now: now, minLeadMinutes: 30), isFalse);

      final yesterdaySlot = DateTime(2026, 10, 13, 14, 0);
      expect(BookingConfigModel.isSlotBookable(slotStart: yesterdaySlot, now: now, minLeadMinutes: 30), isFalse);
    });

    test('serialization and deserialization roundtrip', () {
      final config = BookingConfigModel.defaultConfig();
      final map = config.toMap();

      final restored = BookingConfigModel.fromMap(map);
      expect(restored.maxDaysAhead, equals(config.maxDaysAhead));
      expect(restored.minLeadMinutes, equals(config.minLeadMinutes));
      expect(restored.serviceablePincodePrefixes, equals(config.serviceablePincodePrefixes));
      expect(restored.activeIssueTypes.length, equals(config.activeIssueTypes.length));
    });
  });
}
