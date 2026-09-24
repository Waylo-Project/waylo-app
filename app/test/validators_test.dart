import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/validators.dart';

void main() {
  test('password needs 10+ chars with a letter and a digit', () {
    expect(isValidPassword('abcdefghi1'), isTrue);
    expect(isValidPassword('abc!@#def9'), isTrue);
    expect(isValidPassword('abcdefgh1'), isFalse); // 9 chars
    expect(isValidPassword('abcdefghij'), isFalse); // no digit
    expect(isValidPassword('1234567890'), isFalse); // no letter
  });

  test('email needs a local part, @, and a domain with a TLD', () {
    expect(isValidEmail('me@waylo.app'), isTrue);
    expect(isValidEmail('first.last+tag@mail.co.kr'), isTrue);
    expect(isValidEmail('me@waylo'), isFalse);
    expect(isValidEmail('waylo.app'), isFalse);
    expect(isValidEmail('me @waylo.app'), isFalse);
  });
}
