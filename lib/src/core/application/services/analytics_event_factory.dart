import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/shared/log_timestamp_parser.dart';

/// Factory responsible for creating [AnalyticsEvent] instances from log data.
///
/// This keeps ID generation and timestamp parsing outside of the entity itself,
/// making it easier to evolve or test independently.
class AnalyticsEventFactory {
  /// Creates a new [AnalyticsEventFactory].
  ///
  /// [clock] can be provided to control time in tests; by default it uses
  /// [DateTime.now].
  const AnalyticsEventFactory({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Create an [AnalyticsEvent] from parsed logcat output.
  AnalyticsEvent fromParsedLog({
    required String rawTimestamp,
    required String eventName,
    Map<String, String> parameters = const {},
    List<Map<String, String>> items = const [],
  }) {
    final parsedTimestamp =
        parseLogcatTimestamp(rawTimestamp) ?? _clock();
    final uniqueId = '${parsedTimestamp.toIso8601String()}_${eventName}_'
        '${_clock().microsecondsSinceEpoch}';

    return AnalyticsEvent(
      id: uniqueId,
      timestamp: parsedTimestamp,
      rawTimestamp: rawTimestamp,
      eventName: eventName,
      parameters: parameters,
      items: items,
    );
  }
}

