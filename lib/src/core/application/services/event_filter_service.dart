import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart';
import 'package:firebase_analytics_monitor/src/core/domain/value_objects/event_statistics.dart';
import 'package:injectable/injectable.dart';

/// Service for filtering and analyzing analytics events
@injectable
class EventFilterService {
  /// Creates a new EventFilterService with injected repository
  EventFilterService({required this.eventRepository});

  /// The repository used for accessing event data.
  final EventRepository eventRepository;

  /// Gets a filtered list of analytics events.
  ///
  /// Supports filtering by [eventNames], date range ([fromDate] and [toDate]),
  /// frequency thresholds ([minFrequency] and [maxFrequency]),
  /// [excludeEvents], and an optional [limit].
  Future<List<AnalyticsEvent>> getFilteredEvents({
    List<String>? eventNames,
    DateTime? fromDate,
    DateTime? toDate,
    int? minFrequency,
    int? maxFrequency,
    List<String>? excludeEvents,
    int? limit,
  }) async {
    var events = await eventRepository.getAllEvents();

    // Filter by event names
    if (eventNames != null && eventNames.isNotEmpty) {
      events = events
          .where((AnalyticsEvent e) => eventNames.contains(e.eventName))
          .toList();
    }

    // Filter by excluded events
    if (excludeEvents != null && excludeEvents.isNotEmpty) {
      events = events
          .where((AnalyticsEvent e) => !excludeEvents.contains(e.eventName))
          .toList();
    }

    // Filter by date range
    if (fromDate != null) {
      events = events
          .where(
            (AnalyticsEvent e) =>
                e.timestamp.isAfter(fromDate) ||
                e.timestamp.isAtSameMomentAs(fromDate),
          )
          .toList();
    }
    if (toDate != null) {
      events = events
          .where(
            (AnalyticsEvent e) =>
                e.timestamp.isBefore(toDate) ||
                e.timestamp.isAtSameMomentAs(toDate),
          )
          .toList();
    }

    // Filter by frequency
    if (minFrequency != null || maxFrequency != null) {
      final eventCounts = <String, int>{};
      for (final event in events) {
        eventCounts[event.eventName] = (eventCounts[event.eventName] ?? 0) + 1;
      }

      events = events.where((AnalyticsEvent e) {
        final count = eventCounts[e.eventName] ?? 0;
        if (minFrequency != null && count < minFrequency) return false;
        if (maxFrequency != null && count > maxFrequency) return false;
        return true;
      }).toList();
    }

    // Sort by timestamp (newest first)
    events.sort(
      (AnalyticsEvent a, AnalyticsEvent b) =>
          b.timestamp.compareTo(a.timestamp),
    );

    // Apply limit
    if (limit != null && limit > 0) {
      events = events.take(limit).toList();
    }

    return events;
  }

  /// Gets the frequency count for each event type.
  ///
  /// Optionally filters by date range using [fromDate] and [toDate].
  Future<Map<String, int>> getEventFrequencies({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final events = await getFilteredEvents(
      fromDate: fromDate,
      toDate: toDate,
    );

    final frequencies = <String, int>{};
    for (final event in events) {
      frequencies[event.eventName] = (frequencies[event.eventName] ?? 0) + 1;
    }

    return frequencies;
  }

  /// Gets the top events sorted by frequency.
  ///
  /// Returns up to [limit] event names, optionally filtered by date range.
  Future<List<String>> getTopEventsByFrequency({
    int limit = 10,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final frequencies = await getEventFrequencies(
      fromDate: fromDate,
      toDate: toDate,
    );

    final sortedEntries = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  /// Gets event names with frequency at or below the [threshold].
  Future<List<String>> getLowFrequencyEvents({
    int threshold = 5,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final frequencies = await getEventFrequencies(
      fromDate: fromDate,
      toDate: toDate,
    );

    return frequencies.entries
        .where((e) => e.value <= threshold)
        .map((e) => e.key)
        .toList();
  }

  /// Gets event names with frequency at or above the [threshold].
  Future<List<String>> getHighFrequencyEvents({
    int threshold = 100,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final frequencies = await getEventFrequencies(
      fromDate: fromDate,
      toDate: toDate,
    );

    return frequencies.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList();
  }

  /// Computes aggregate statistics for events.
  ///
  /// Includes total count, unique types, frequency map, and date range.
  Future<EventStatistics> getEventStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final events = await getFilteredEvents(
      fromDate: fromDate,
      toDate: toDate,
    );

    final frequencies = <String, int>{};
    DateTime? earliest;
    DateTime? latest;

    for (final event in events) {
      frequencies[event.eventName] = (frequencies[event.eventName] ?? 0) + 1;

      if (earliest == null || event.timestamp.isBefore(earliest)) {
        earliest = event.timestamp;
      }
      if (latest == null || event.timestamp.isAfter(latest)) {
        latest = event.timestamp;
      }
    }

    DateTimeRange? dateRange;
    if (earliest != null && latest != null) {
      dateRange = DateTimeRange(start: earliest, end: latest);
    }

    return EventStatistics(
      totalEvents: events.length,
      uniqueEventTypes: frequencies.length,
      topEvents: frequencies,
      dateRange: dateRange,
    );
  }

  /// Searches for events containing a specific parameter.
  ///
  /// Requires [parameterName]. Optionally matches a specific [parameterValue]
  /// and filters by date range.
  Future<List<AnalyticsEvent>> searchEventsByParameter({
    required String parameterName,
    String? parameterValue,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final events = await getFilteredEvents(
      fromDate: fromDate,
      toDate: toDate,
    );

    return events.where((event) {
      if (!event.parameters.containsKey(parameterName)) return false;

      if (parameterValue != null) {
        return event.parameters[parameterName] == parameterValue;
      }

      return true;
    }).toList();
  }
}
