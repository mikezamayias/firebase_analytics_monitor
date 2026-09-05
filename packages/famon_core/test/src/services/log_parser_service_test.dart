import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('LogParserService', () {
    test('strips GA4 debug shortcode from Android event names', () {
      final parser = LogParserService();
      const logLine =
          '09-10 15:41:35.626  3815 28115 V FA-SVC  : Logging event: '
          'origin=auto,name=screen_view(_vs),params=Bundle[{'
          'ga_screen=HomeScreen, ga_screen_class=HomeActivity}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('screen_view'));
      expect(result.parameters['ga_screen'], equals('HomeScreen'));
      expect(result.parameters['ga_screen_class'], equals('HomeActivity'));
    });
  });
}
