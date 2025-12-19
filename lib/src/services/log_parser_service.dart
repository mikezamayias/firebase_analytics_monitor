import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/services/parsers/log_line_parsers.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// Service for parsing Firebase Analytics log lines from adb logcat output
@Injectable(as: LogParserInterface)
class LogParserService implements LogParserInterface {
  /// Creates a new LogParserService
  ///
  /// [logger] - Optional logger for reporting parsing errors
  LogParserService({Logger? logger})
      : _logger = logger,
        _parsers = [
          BundleEventLogParser(logger),
          NameOnlyEventLogParser(logger),
          InvalidDefaultParamWarningParser(logger),
        ];

  /// The logger instance used for reporting parsing errors.
  final Logger? _logger;

  /// Registered parsers for different log formats.
  final List<LogLineParser> _parsers;

  @override
  AnalyticsEvent? parse(String logLine) {
    if (logLine.isEmpty) return null;

    for (final parser in _parsers) {
      final event = parser.tryParse(logLine);
      if (event != null) return event;
    }

    return null;
  }
}
