import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/utils/validators.dart';

void main() {
  group('Validators - Email (Issue I12 / AUTH-08)', () {
    test('accepts standard emails (.com, .org, .in)', () {
      expect(Validators.email('doctor@example.com'), isNull);
      expect(Validators.email('clinic@smilecare.org'), isNull);
      expect(Validators.email('dr.smith@dental.in'), isNull);
    });

    test('accepts modern healthcare and long TLDs (.dental, .clinic, .health, .hospital)', () {
      expect(Validators.email('dr.priya@hyderabad.dental'), isNull);
      expect(Validators.email('contact@smilecare.clinic'), isNull);
      expect(Validators.email('care@city.health'), isNull);
      expect(Validators.email('info@metro.hospital'), isNull);
    });

    test('rejects invalid emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email('noatsign.com'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
      expect(Validators.email('user@nodot'), isNotNull);
      expect(Validators.email('user@domain.c'), isNotNull); // less than 2 chars TLD
    });
  });

  group('Validators - Description (Issue I7 / BKG-05 to BKG-08)', () {
    test('accepts any words between 1 and 500 characters', () {
      expect(Validators.description('Chair stuck'), isNull);
      expect(Validators.description('Broken'), isNull);
      expect(Validators.description('A'), isNull);
      expect(Validators.description('Water leaking from turbine pipe during extraction'), isNull);
    });

    test('rejects empty or whitespace-only descriptions', () {
      expect(Validators.description(null), isNotNull);
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('   '), isNotNull);
      expect(Validators.description('\n\t  '), isNotNull);
    });

    test('rejects descriptions exceeding 500 characters', () {
      final longText = 'a' * 501;
      expect(Validators.description(longText), isNotNull);
    });
  });

  group('Validators - Phone (Issue I9 / BKG-13)', () {
    test('accepts valid 10-digit Indian numbers starting with 6-9', () {
      expect(Validators.phoneNumber('9876543210'), isNull);
      expect(Validators.phoneNumber('+919876543210'), isNull);
      expect(Validators.phoneNumber('+91 9876543210'), isNull);
      expect(Validators.phoneNumber('6301234567'), isNull);
      expect(Validators.phoneNumber('7890123456'), isNull);
      expect(Validators.phoneNumber('8901234567'), isNull);
    });

    test('rejects invalid phone numbers', () {
      expect(Validators.phoneNumber(''), isNotNull);
      expect(Validators.phoneNumber('1234567890'), isNotNull); // starts with 1
      expect(Validators.phoneNumber('5876543210'), isNotNull); // starts with 5
      expect(Validators.phoneNumber('98765'), isNotNull); // short
      expect(Validators.phoneNumber('987654321000'), isNotNull); // too long
      expect(Validators.phoneNumber('abcdefghij'), isNotNull);
    });
  });

  group('Validators - Pincode (Issue I9 / BKG-14 to BKG-16)', () {
    final allowedPrefixes = ['500', '501', '502'];

    test('accepts valid 6-digit Hyderabad pincodes', () {
      expect(Validators.pincode('500034', allowedPrefixes), isNull); // Banjara Hills
      expect(Validators.pincode('500081', allowedPrefixes), isNull); // Madhapur / Hitec City
      expect(Validators.pincode('501505', allowedPrefixes), isNull);
      expect(Validators.pincode('502032', allowedPrefixes), isNull);
    });

    test('rejects non-serviceable pincodes outside Hyderabad', () {
      expect(Validators.pincode('560001', allowedPrefixes), contains('Hyderabad only')); // Bangalore
      expect(Validators.pincode('110001', allowedPrefixes), contains('Hyderabad only')); // Delhi
      expect(Validators.pincode('400001', allowedPrefixes), contains('Hyderabad only')); // Mumbai
    });

    test('rejects malformed pincodes', () {
      expect(Validators.pincode('', allowedPrefixes), isNotNull);
      expect(Validators.pincode('5000', allowedPrefixes), isNotNull);
      expect(Validators.pincode('5000340', allowedPrefixes), isNotNull);
      expect(Validators.pincode('50003A', allowedPrefixes), isNotNull);
    });
  });

  group('Validators - Amount Paid (Issue I15 / DR-07 to DR-09)', () {
    test('accepts whole rupee amounts from 0 to 100000', () {
      expect(Validators.amountPaid('0'), isNull);
      expect(Validators.amountPaid('250'), isNull);
      expect(Validators.amountPaid('1500'), isNull);
      expect(Validators.amountPaid('100000'), isNull);
    });

    test('rejects negative numbers, decimals, and values > 100000', () {
      expect(Validators.amountPaid('-10'), isNotNull);
      expect(Validators.amountPaid('250.50'), isNotNull);
      expect(Validators.amountPaid('100001'), isNotNull);
      expect(Validators.amountPaid('abc'), isNotNull);
      expect(Validators.amountPaid(''), isNotNull);
    });
  });
}
