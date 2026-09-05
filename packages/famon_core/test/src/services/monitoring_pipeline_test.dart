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

    test('buffers multi-line Event logged. blocks before parsing', () async {
      final header = StringBuffer()
        ..write('[FirebaseAnalytics][I-ACS023072] Event logged. Event name, ')
        ..write('event params: test_event, {');
      final lines = [
        header.toString(),
        '    bool = true;',
        '    ga_event_origin (_o) = app;',
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
      expect(event.parameters['ga_event_origin'], equals('app'));
    });

    test('keeps buffering until the outer iOS event block closes', () async {
      final header = StringBuffer()
        ..write('[FirebaseAnalytics][I-ACS023051] Logging event: origin, ')
        ..write('name, params: app, nested_event, {');
      final lines = [
        header.toString(),
        '    nested = {',
        '        child = yes;',
        '    }',
        '    string = after_nested;',
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
      expect(event.eventName, equals('nested_event'));
      expect(event.parameters['string'], equals('after_nested'));
    });

    test('recovers when a new iOS block starts before the previous one closes',
        () async {
      final firstHeader = StringBuffer()
        ..write('[FirebaseAnalytics][I-ACS023051] Logging event: origin, ')
        ..write('name, params: app, first_event, {');
      final secondHeader = StringBuffer()
        ..write('[FirebaseAnalytics][I-ACS023051] Logging event: origin, ')
        ..write('name, params: app, second_event, {');
      final lines = [
        firstHeader.toString(),
        '    first = yes;',
        secondHeader.toString(),
        '    second = yes;',
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

      expect(results, hasLength(2));
      final events =
          results.cast<LogEventResult>().map((result) => result.event).toList();
      expect(events[0].eventName, equals('first_event'));
      expect(events[0].parameters['first'], equals('yes'));
      expect(events[1].eventName, equals('second_event'));
      expect(events[1].parameters['second'], equals('yes'));
    });
  });
}
