import 'package:intl/intl.dart';

String normalizeRegNumber(String input) {
  return input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
}

String formatAmount(double value) {
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
      .format(value);
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

extension IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
