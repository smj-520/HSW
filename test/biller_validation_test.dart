import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/constants/biller_categories.dart';

void main() {
  test('Name can be any non-empty service label and is trimmed', () {
    expect(
      validateBillerFields(
        name: '  Ooredoo Wi-Fi  ',
        category: 'mobile',
        accountNumber: '123',
      ),
      isNull,
    );
    expect(
      validateBillerFields(
        name: '   ',
        category: 'mobile',
        accountNumber: '123',
      ),
      'Name is required',
    );
  });

  test('Category must be one of the supported expense ids', () {
    expect(
      validateBillerFields(
        name: 'Oman Electricity',
        category: null,
        accountNumber: '123',
      ),
      'Category is required',
    );
    expect(
      validateBillerFields(
        name: 'Oman Electricity',
        category: '',
        accountNumber: '123',
      ),
      'Category is required',
    );
    expect(
      validateBillerFields(
        name: 'Oman Electricity',
        category: 'Electricity',
        accountNumber: '123',
      ),
      'Select a valid category',
    );
    expect(
      validateBillerFields(
        name: 'Hostel Rent',
        category: 'hostel_fees',
        accountNumber: '99',
      ),
      isNull,
    );
    expect(isAllowedBillerCategory('not-a-category'), isFalse);
    expect(isAllowedBillerCategory('mess_food'), isTrue);
  });

  test('Account number stays required', () {
    expect(
      validateBillerFields(
        name: 'Restaurant Bill',
        category: 'mess_food',
        accountNumber: '  ',
      ),
      'Account number is required',
    );
  });

  test('Name and category are independent', () {
    expect(
      validateBillerFields(
        name: 'Ooredoo Wi-Fi',
        category: 'mobile',
        accountNumber: 'ACC-1',
      ),
      isNull,
    );
  });
}
