import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/screens/forgot_password_screen.dart';

void main() {

  Widget createScreen() {

    return const MaterialApp(

      home: ForgotPasswordScreen(),

    );

  }

  testWidgets('Forgot password screen loads correctly', (tester) async {

    await tester.pumpWidget(createScreen());

    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);

    expect(

      find.text('Enter your email — we will send a password reset link.'),

      findsOneWidget,

    );

    expect(find.text('Email'), findsOneWidget);

    expect(find.text('Send'), findsOneWidget);

  });

  testWidgets('User can type email', (tester) async {

    await tester.pumpWidget(createScreen());

    await tester.enterText(

      find.widgetWithText(TextFormField, 'Email'),

      'test@gmail.com',

    );

    expect(find.text('test@gmail.com'), findsOneWidget);

  });

  testWidgets('Send button exists and can be tapped', (tester) async {

    await tester.pumpWidget(createScreen());

    final sendButton = find.text('Send');

    expect(sendButton, findsOneWidget);

    await tester.tap(sendButton);

    await tester.pump();

  });

}
