import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/utils/form_validators.dart';

void main() {
  test('Email and strong password validators reject invalid input', () {
    expect(FormValidators.emailAddress(''), isNotNull);
    expect(FormValidators.emailAddress('not-an-email'), isNotNull);
    expect(FormValidators.emailAddress('student@host.edu.om'), isNull);

    expect(FormValidators.strongPassword('123456'), isNotNull);
    expect(FormValidators.strongPassword('Abcdefgh'), isNotNull);
    expect(FormValidators.strongPassword('Abcdef1!'), isNull);

    expect(
      FormValidators.confirmPassword('Abcdef1!', 'wrong'),
      'Passwords do not match',
    );
    expect(FormValidators.confirmPassword('Abcdef1!', 'Abcdef1!'), isNull);
  });
}
