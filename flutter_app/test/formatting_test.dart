import 'package:flutter_test/flutter_test.dart';
import 'package:plantregistratie/main.dart';

void main() {
  test('formatteert datum en tijd in Nederlands formaat', () {
    final value = DateTime(2026, 8, 18, 20, 45).millisecondsSinceEpoch;
    expect(formatDateTime(value), '18-08-2026 20:45');
  });

  test('gebruikt een expliciete datum voor oudere registraties', () {
    expect(dateLabel(DateTime(2020, 2, 3)), '03-02-2020');
  });

  test('formatteert voorraadaantallen met Nederlandse duizendtallen', () {
    expect(formatQuantity(2450), '2.450');
    expect(formatQuantity(-1250), '-1.250');
  });

  test('vertaalt geschiedenisacties naar het Nederlands', () {
    expect(historyAction('created'), 'Aangemaakt');
    expect(historyAction('added'), 'Toegevoegd');
    expect(historyAction('removed'), 'Verwijderd');
  });
}
