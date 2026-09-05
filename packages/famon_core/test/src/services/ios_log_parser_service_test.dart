import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('IosLogParserService', () {
    test('does not parse incomplete event logged header as name event', () {
      final parser = IosLogParserService();
      const logLine =
          '[FirebaseAnalytics][I-ACS023072] Event logged. Event name, '
          'event params:';

      expect(parser.parse(logLine), isNull);
    });
  });
}
