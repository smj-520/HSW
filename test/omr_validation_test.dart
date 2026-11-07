import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/utils/formatters.dart';

void main() {
  test('OMR amount parsing rejects empty or non-positive input', () {
    expect(parseOmrToBaisa(''), isNull);
    expect(parseOmrToBaisa('0'), isNull);
    expect(parseOmrToBaisa('-5'), isNull);
    expect(parseOmrToBaisa('500'), 500000);
    expect(parseOmrToBaisa('500.000'), 500000);
    expect(formatOmr(500000, sign: OmrSign.plus), '+500.000 OMR');
    expect(formatOmr(-240000), '-240.000 OMR');
    expect(formatOmr(240000), '240.000 OMR');
  });
}
