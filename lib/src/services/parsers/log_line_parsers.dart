import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/services/parsers/bundle_parsing_utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// Base interface for specialized log line parsers.
abstract class LogLineParser {
  const LogLineParser(this.logger);

  /// Logger used for detailed debug output.
  final Logger? logger;

  /// Attempts to parse [logLine] and return an [AnalyticsEvent].
  ///
  /// Returns `null` if this parser does not recognize the format.
  AnalyticsEvent? tryParse(String logLine);
}

/// Parser for standard Firebase Analytics events with Bundle parameters.
class BundleEventLogParser extends LogLineParser {
  const BundleEventLogParser(super.logger);

  /// Regex patterns for different Firebase Analytics log formats that contain
  /// Bundle parameters.
  static final List<RegExp> _logPatterns = [
    // Standard format: Logging event:
    // origin=app,name=event_name,params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Logging event: '
      r'origin=app,name=([^,]+),params=(Bundle\[.*\])',
    ),
    // Alternative format: Event logged: event_name
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Event logged: ([^\s]+).*params:(Bundle\[.*\])?',
    ),
    // More comprehensive Firebase format with Bundle parameters (FA-SVC)
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),
    // Same as above but tagged with FA instead of FA-SVC
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),
    // Newer Firebase format: Event name followed by parameters (FA-SVC)
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),
    // Newer Firebase format: Event name followed by parameters (FA)
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),
    // Older "Logging event (FE)" format tagged as I/FA
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*I/FA.*Logging event \(FE\): ([^,\s]+),.*(Bundle\[.*\])',
    ),
    // I/FA: Event logged: event_name, params=(Bundle[..])
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*I/FA.*Event logged: ([^,\s]+).*params[:=](Bundle\[.*\])',
    ),
  ];

  @override
  AnalyticsEvent? tryParse(String logLine) {
    for (final regex in _logPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        final timestamp = match.group(1)!;
        final eventName = match.group(2)!;
        final paramsString = match.groupCount >= 3 ? match.group(3) ?? '' : '';

        final params = parseBundleParams(paramsString, logger: logger);
        final items = parseBundleItems(paramsString, logger: logger);

        return AnalyticsEvent.fromParsedLog(
          rawTimestamp: timestamp,
          eventName: eventName,
          parameters: params,
          items: items,
        );
      }
    }

    return null;
  }
}

/// Parser for basic event_name-only formats (no parameters).
class NameOnlyEventLogParser extends LogLineParser {
  const NameOnlyEventLogParser(super.logger);

  static final List<RegExp> _nameOnlyPatterns = [
    // Basic format: Just event name with timestamp (FA-SVC)
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*event_name:([^\s,]+)',
    ),
    // Basic format: Just event name with timestamp (FA)
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*event_name:([^\s,]+)',
    ),
  ];

  @override
  AnalyticsEvent? tryParse(String logLine) {
    for (final regex in _nameOnlyPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        final timestamp = match.group(1)!;
        final eventName = match.group(2)!;

        return AnalyticsEvent.fromParsedLog(
          rawTimestamp: timestamp,
          eventName: eventName,
        );
      }
    }

    return null;
  }
}

/// Parser for FA warnings about invalid default parameter types.
class InvalidDefaultParamWarningParser extends LogLineParser {
  const InvalidDefaultParamWarningParser(super.logger);

  static final RegExp _pattern = RegExp(
    r'^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\b[VDIWE]/FA\b.*Invalid default event parameter type\.\s*Name, value:\s*([^,]+),\s*(.+)$',
  );

  @override
  AnalyticsEvent? tryParse(String logLine) {
    final warn = _pattern.firstMatch(logLine);
    if (warn == null) return null;

    final timestamp = warn.group(1)!;
    final paramName = warn.group(2)!.trim();
    final paramValue = warn.group(3)!.trim();

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: timestamp,
      eventName: 'fa_invalid_default_param',
      parameters: {paramName: cleanBundleValue(paramValue)},
    );
  }
}

