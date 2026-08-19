import 'package:flutter_test/flutter_test.dart';
import 'package:plantregistratie/main.dart';

void main() {
  test('kan de cross-platform app aanmaken', () {
    expect(const PlantsApp(), isNotNull);
  });
}
