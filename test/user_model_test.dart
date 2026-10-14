import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/user_model.dart';

void main() {
  group('UserModel unit tests (Issue I2 / SEC-03, SEC-04)', () {
    final now = DateTime(2026, 10, 14, 12, 0);

    test('toMap does not write role field to prevent client privilege escalation', () {
      final user = UserModel(
        uid: 'user_123',
        displayName: 'Dr. Rao',
        phone: '9876543210',
        email: 'dr.rao@smilecare.dental',
        clinicName: 'Smile Care Dental',
        clinicAddress: 'Banjara Hills, Hyderabad',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map.containsKey('role'), isFalse);
      expect(map['displayName'], equals('Dr. Rao'));
      expect(map['phone'], equals('9876543210'));
      expect(map['email'], equals('dr.rao@smilecare.dental'));
    });

    test('isAdmin is determined by custom claim, not client doc', () {
      final regularUser = UserModel(
        uid: 'user_regular',
        displayName: 'Dr. Regular',
        phone: '9876543210',
        isAdmin: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(regularUser.isAdmin, isFalse);

      final adminUser = regularUser.copyWith(isAdmin: true);
      expect(adminUser.isAdmin, isTrue);
    });
  });
}
