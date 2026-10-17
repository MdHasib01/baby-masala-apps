const _bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// 123 → "১২৩". Works on any string, leaves non-digits untouched.
String toBnDigits(Object? value) {
  final s = '$value';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final d = int.tryParse(c);
    b.write(d != null && c.codeUnitAt(0) < 128 ? _bn[d] : c);
  }
  return b.toString();
}

/// "০১৭১২" → "01712" (used when normalising phone numbers typed with a Bengali keyboard).
String toAsciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = _bn.indexOf(c);
    b.write(i >= 0 ? '$i' : c);
  }
  return b.toString();
}

/// "৳1,250" style money label with Bengali digits: ৳১২৫০
String taka(num amount) => '৳${toBnDigits(amount % 1 == 0 ? amount.toInt() : amount.toStringAsFixed(2))}';

const _bnMonths = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

/// "2001-05-09" → "৯ মে ২০০১". Returns the input unchanged if it isn't a date.
String formatBnDate(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  return '${toBnDigits(d.day)} ${_bnMonths[d.month - 1]} ${toBnDigits(d.year)}';
}
