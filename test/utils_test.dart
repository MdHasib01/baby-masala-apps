import 'package:baby_care/core/utils/bn_digits.dart';
import 'package:baby_care/core/utils/child_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detailedAge (port of getDetailedAge in MyBabyTab.tsx)', () {
    final now = DateTime(2026, 10, 16);

    test('under 6 months', () {
      final a = detailedAge('2026-06-01', now: now);
      expect(a.ageGroup, 'under_6m');
      expect(a.totalMonths, 4);
      expect(a.ageStr, '৪ মাস ১৫ দিন');
    });

    test('borrowing days from the previous month', () {
      // Sep has 30 days: 16 Oct − 20 Aug = 1 month 26 days
      final a = detailedAge('2026-08-20', now: now);
      expect(a.totalMonths, 1);
      expect(a.ageStr, '১ মাস ২৬ দিন');
    });

    test('group boundaries match the web', () {
      expect(detailedAge('2026-04-16', now: now).ageGroup, '6_8m'); // 6 months
      expect(detailedAge('2026-02-16', now: now).ageGroup, '6_8m'); // 8 months
      expect(detailedAge('2026-01-16', now: now).ageGroup, '9_12m'); // 9 months
      expect(detailedAge('2025-10-16', now: now).ageGroup, '9_12m'); // 12 months
      expect(detailedAge('2025-09-16', now: now).ageGroup, '1_2y'); // 13 months
      expect(detailedAge('2024-10-16', now: now).ageGroup, '1_2y'); // 24 months
      expect(detailedAge('2024-09-16', now: now).ageGroup, '2y_plus');
    });

    test('years are shown when over a year', () {
      expect(detailedAge('2024-09-10', now: now).ageStr, '২ বছর ১ মাস ৬ দিন');
    });

    test('missing / invalid DOB falls back like the web', () {
      expect(detailedAge('').ageGroup, '9_12m');
      expect(detailedAge('not-a-date').ageStr, 'অজানা');
    });
  });

  group('Bengali digits', () {
    test('to Bengali', () {
      expect(toBnDigits(1250), '১২৫০');
      expect(toBnDigits('রুম 12'), 'রুম ১২');
    });

    test('to ASCII (phone numbers typed on a Bengali keyboard)', () {
      expect(toAsciiDigits('০১৭১২৩৪৫৬৭৮'), '01712345678');
    });

    test('taka formatting', () {
      expect(taka(350), '৳৩৫০');
      expect(taka(12.5), '৳১২.৫০');
    });
  });
}
