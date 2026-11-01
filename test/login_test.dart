import 'package:flutter_test/flutter_test.dart';

bool isLoginInputValid(String email, String password) {

  return email.isNotEmpty && password.isNotEmpty;

}

void main() {

  test('Login fails when email is empty', () {

    final result = isLoginInputValid('', '123456');

    expect(result, false);

  });

  test('Login fails when password is empty', () {

    final result = isLoginInputValid('test@gmail.com', '');

    expect(result, false);

  });

  test('Login input is valid when email and password are filled', () {

    final result = isLoginInputValid('test@gmail.com', '123456');

    expect(result, true);

  });

}
