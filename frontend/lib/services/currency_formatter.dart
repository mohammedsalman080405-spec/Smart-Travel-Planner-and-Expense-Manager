import 'package:intl/intl.dart';

/// Application-wide INR formatting with Indian digit grouping.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _wholeRupees = NumberFormat.currency(
    locale: 'en_IN',
    name: 'INR',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _paise = NumberFormat.currency(
    locale: 'en_IN',
    name: 'INR',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount, {bool includePaise = false}) =>
      (includePaise ? _paise : _wholeRupees).format(amount);
}
