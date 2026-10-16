import 'bn_digits.dart';

/// Port of `getDetailedAge()` in frontend/src/tabs/MyBabyTab.tsx.
class ChildAge {
  const ChildAge({required this.ageStr, required this.ageGroup, required this.totalMonths});
  final String ageStr;
  final String ageGroup;
  final int totalMonths;
}

ChildAge detailedAge(String? dob, {DateTime? now}) {
  final birth = dob == null || dob.isEmpty ? null : DateTime.tryParse(dob);
  if (birth == null) return const ChildAge(ageStr: 'অজানা', ageGroup: '9_12m', totalMonths: 9);

  final today = now ?? DateTime.now();
  var years = today.year - birth.year;
  var months = today.month - birth.month;
  var days = today.day - birth.day;

  if (days < 0) {
    months--;
    // Day 0 of the current month == last day of the previous month.
    days += DateTime(today.year, today.month, 0).day;
  }
  if (months < 0) {
    years--;
    months += 12;
  }

  final totalMonths = years * 12 + months;
  final String ageGroup;
  if (totalMonths < 6) {
    ageGroup = 'under_6m';
  } else if (totalMonths <= 8) {
    ageGroup = '6_8m';
  } else if (totalMonths <= 12) {
    ageGroup = '9_12m';
  } else if (totalMonths <= 24) {
    ageGroup = '1_2y';
  } else {
    ageGroup = '2y_plus';
  }

  final b = StringBuffer();
  if (years > 0) b.write('${toBnDigits(years)} বছর ');
  if (months > 0 || years > 0) b.write('${toBnDigits(months)} মাস ');
  b.write('${toBnDigits(days)} দিন');

  return ChildAge(ageStr: b.toString(), ageGroup: ageGroup, totalMonths: totalMonths);
}
