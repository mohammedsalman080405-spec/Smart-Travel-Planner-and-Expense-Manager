import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/currency_formatter.dart';

void main() {
  test('formats whole rupees with Indian digit grouping', () {
    expect(CurrencyFormatter.format(18500), '₹18,500');
    expect(CurrencyFormatter.format(125000), '₹1,25,000');
    expect(CurrencyFormatter.format(1250000), '₹12,50,000');
  });

  test('formats paise when requested', () {
    expect(CurrencyFormatter.format(1250.5, includePaise: true), '₹1,250.50');
  });
}
