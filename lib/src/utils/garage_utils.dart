import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:intl/intl.dart';

PaymentStatus paymentStatusForAmount(double amountPaid, double grandTotal) {
  if (amountPaid >= grandTotal && grandTotal > 0) {
    return PaymentStatus.paid;
  }
  if (amountPaid > 0) {
    return PaymentStatus.partial;
  }
  return PaymentStatus.unpaid;
}

String normalizeRegNumber(String input) {
  return input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
}

String normalizeMobile(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

String formatAmount(double value) {
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
      .format(value);
}

/// Formats a part/stock quantity, dropping the decimal point for whole
/// numbers (e.g. "4" instead of "4.0") while still showing fractions like
/// "4.5" for parts such as engine oil that are sold/used by volume.
String formatQty(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final text = value.toStringAsFixed(2);
  return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

extension IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

abstract final class FormValidators {
  static String? requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? mobile(String? value) {
    final digits = normalizeMobile(value ?? '');
    if (digits.isEmpty) {
      return 'Mobile number is required';
    }
    if (digits.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  static String? vehicleNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Vehicle number is required';
    }
    final normalized = normalizeRegNumber(trimmed);
    final standard = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$');
    final bharat = RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{4}[A-Z]{1,2}$');
    if (!standard.hasMatch(normalized) && !bharat.hasMatch(normalized)) {
      return 'Enter a valid vehicle number (e.g. KL60K3139)';
    }
    return null;
  }

  static String? positiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  static String? positiveKm(String? value) {
    final error = positiveInteger(value, 'KM reading');
    if (error != null) {
      return error;
    }
    if (int.parse(value!.trim()) == 0) {
      return 'KM reading must be greater than 0';
    }
    return null;
  }

  static String? vehicleYear(String? value) {
    final error = positiveInteger(value, 'Year');
    if (error != null) {
      return error;
    }
    final year = int.parse(value!.trim());
    if (year < 1980 || year > DateTime.now().year + 1) {
      return 'Enter a valid year';
    }
    return null;
  }
}
