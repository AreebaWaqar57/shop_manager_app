import 'package:flutter_test/flutter_test.dart';
import 'package:shop_manager/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and blank values', () {
      expect(Validators.required(null, 'Title'), 'Title is required');
      expect(Validators.required('', 'Title'), 'Title is required');
      expect(Validators.required('   ', 'Title'), 'Title is required');
    });

    test('accepts a value', () {
      expect(Validators.required('Phone', 'Title'), isNull);
    });
  });

  group('Validators.price', () {
    test('requires a value', () {
      expect(Validators.price(null), 'Price is required');
      expect(Validators.price(''), 'Price is required');
    });

    test('rejects text', () {
      expect(Validators.price('abc'), 'Enter a valid number');
    });

    test('rejects zero and negative numbers', () {
      expect(Validators.price('0'), 'Price must be greater than 0');
      expect(Validators.price('-5'), 'Price must be greater than 0');
    });

    test('accepts valid numbers', () {
      expect(Validators.price('9.99'), isNull);
      expect(Validators.price(' 10 '), isNull);
    });
  });

  group('Validators.optionalUrl', () {
    test('accepts an empty value', () {
      expect(Validators.optionalUrl(null), isNull);
      expect(Validators.optionalUrl(''), isNull);
    });

    test('accepts http and https URLs', () {
      expect(Validators.optionalUrl('https://example.com/a.png'), isNull);
      expect(Validators.optionalUrl('http://example.com'), isNull);
    });

    test('rejects invalid URLs', () {
      const message = 'Enter a valid http(s) URL';
      expect(Validators.optionalUrl('not a url'), message);
      expect(Validators.optionalUrl('ftp://example.com'), message);
      expect(Validators.optionalUrl('http://'), message);
    });
  });
}