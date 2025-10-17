import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic Dart test', () {
    expect(2 + 2, equals(4));
    expect('SmartRFID'.isNotEmpty, isTrue);
    expect([1, 2, 3].length, equals(3));
  });
}