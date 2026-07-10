import 'dart:async';

import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('MonitoringPipeline', () {
    test('buffers multi-line iOS Firebase event blocks before parsing',
        () async {
      final header = StringBuffer()
        ..write('[FirebaseAnalytics][I-ACS023051] Logging event: origin, ')
        ..write('name, params: app, test_event, {');
      final lines = [
        header.toString(),
        '    bool = true;',
        '    double = 42;',
        '    ga_event_origin (_o) = app;',
        '    string = string;',
        '}',
      ];
      final stdout = Stream<List<int>>.fromIterable(
        lines.map((line) => '$line\n'.codeUnits),
      );
      const stderr = Stream<List<int>>.empty();
      final results = <LogEventProcessResult>[];
      final pipeline = MonitoringPipeline(
        processor: LogEventProcessor(parser: IosLogParserService()),
      );

      await pipeline.run(
        stdout: stdout,
        stderr: stderr,
        verbose: false,
        onResult: (result) {
          results.add(result);
          return true;
        },
      );

      expect(results, hasLength(1));
      final event = (results.single as LogEventResult).event;
      expect(event.eventName, equals('test_event'));
      expect(event.parameters['bool'], equals('true'));
      expect(event.parameters['double'], equals('42'));
      expect(event.parameters['ga_event_origin'], equals('app'));
      expect(event.parameters['string'], equals('string'));
    });
  });
}
