import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/models/platform_type.dart';
import 'package:famon_core/src/services/shared/base_log_parser_service.dart';
import 'package:famon_core/src/services/shared/item_array_parser.dart';

/// Service for parsing Firebase Analytics log lines from iOS console output.
///
/// ## iOS Firebase Analytics Log Formats
///
/// This service handles various iOS Firebase Analytics log formats from both
/// iOS Simulator (via xcrun simctl log stream) and physical devices
/// (via idevicesyslog).
///
/// ### Supported Formats
///
/// 1. **Standard iOS Firebase Analytics format**:
///    ```text
///    [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params:
///    app, screen_view (_vs), {
///        ga_screen (_sn) = Dashboard;
///        ga_screen_class (_sc) = HomeViewController;
///    }
///    ```
///
/// 2. **Event logged confirmation**:
///    ```text
///    [FirebaseAnalytics][I-ACS023072] Event logged. Event name,
///    event params: purchase
///    ```
///
/// ### Key Differences from Android
///
/// - Parameters use `=` separator with `;` terminators (not `,`)
/// - Parameter abbreviations appear in parentheses (e.g., `(_vs)`, `(_sn)`)
/// - Module identifier: `[FirebaseAnalytics]` instead of FA tag
/// - Log codes: `[I-ACS023051]` format
///
/// The marker check, pattern loop, params scan, and items scan live in
/// [BaseLogParserService]. This class supplies the iOS patterns, the
/// timestamp extraction, and the value cleaning.
class IosLogParserService extends BaseLogParserService {
  /// Creates a new IosLogParserService
  ///
  /// [logger] - Optional logger for reporting parsing errors
  IosLogParserService({super.logger});

  @override
  PlatformType get platform => PlatformType.iosSimulator;

  @override
  String get platformLabel => 'iOS';

  @override
  List<String> get faMarkers => _faMarkers;

  @override
  List<RegExp> get logPatterns => _logPatterns;

  @override
  List<RegExp> get paramPatterns => _paramPatterns;

  @override
  String get itemOpenToken => '{';

  /// Set of markers that indicate a line may contain Firebase Analytics data.
  static const _faMarkers = [
    'FirebaseAnalytics',
    'FIRAnalytics',
    'Logging event',
    'Event logged',
  ];

  /// Regex patterns for different iOS Firebase Analytics log formats.
  ///
  /// Patterns are ordered by expected frequency of occurrence (most common
  /// first) to minimize the average number of regex evaluations per line.
  static final List<RegExp> _logPatterns = [
    // Pattern 1: Standard iOS Firebase Analytics format
    // Example: [FirebaseAnalytics][I-ACS023051] Logging event: origin, name,
    // params: app, screen_view (_vs), { ... }
    // This captures event name which may have an abbreviation in parentheses.
    // Uses greedy .* to handle nested braces inside items arrays.
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*params:\s*\w+,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 1b: Truncated variant, no closing } (line was cut)
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*params:\s*\w+,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.+)',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 2: Simpler iOS format without params block
    // Example: [FirebaseAnalytics][I-ACS023051] Logging event: app, purchase
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*,\s*(\w+)(?:\s*\([^)]*\))?(?:,|$)',
    ),

    // Pattern 3: Event logged confirmation format with params
    // Example: [FirebaseAnalytics][I-ACS023072] Event logged. Event name,
    // event params: purchase, { ... }
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Event logged\.\s*Event name,\s*event params:\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 3b: Event logged confirmation format without params block
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Event logged\.\s*Event name,\s*event params:\s*(\w+)(?:\s*\([^)]*\))?(?:,|$)',
    ),

    // Pattern 4: FIRAnalytics format (alternative Firebase Analytics logging)
    // Example: FIRAnalytics: Logging event: purchase
    RegExp(r'FIRAnalytics.*Logging event:\s*(\w+)'),

    // Pattern 5: Debug view format with timestamp
    // Example: 2024-01-15 10:30:45.123+0000 [FirebaseAnalytics] Logging event:
    // origin, name, params: app, purchase
    RegExp(
      r'\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+[+-]\d+.*\[FirebaseAnalytics\].*Logging event:.*,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 6: xcrun simctl log stream compact format
    // Compact log output may omit some formatting
    RegExp(r'FirebaseAnalytics.*\bevent:\s*(\w+)', caseSensitive: false),
  ];

  /// Pre-compiled regex patterns for iOS parameter parsing.
  ///
  /// iOS Firebase Analytics uses different parameter formats than Android:
  /// - `key = value;` format with semicolon terminator
  /// - Optional abbreviation in parentheses: `ga_screen (_sn) = Dashboard;`
  static final List<RegExp> _paramPatterns = [
    // iOS format: key (_abbrev) = value;
    RegExp(r'(\w+)\s*(?:\([^)]*\))?\s*=\s*([^;]+);'),

    // Simpler key = value format
    RegExp(r'(\w+)\s*=\s*([^;,}]+)'),

    // Key: value format (sometimes used in logs)
    RegExp(r'(\w+)\s*:\s*([^;,}]+)'),
  ];

  /// Pre-compiled regex pattern for finding the `items` key position.
  static final RegExp _itemsKeyPattern = RegExp(
    r'items\s*=\s*\[',
    caseSensitive: false,
  );

  /// Pattern for cleaning iOS-specific value wrappers
  static final RegExp _iosValueWrapperPattern = RegExp(r'^[A-Za-z]+\((.*)\)$');

  // Pre-compiled patterns for _extractTimestamp (avoids hot path compilation)
  static final RegExp _isoTimestampPattern = RegExp(
    r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+)',
  );
  static final RegExp _timeOnlyPattern = RegExp(r'(\d{2}:\d{2}:\d{2}\.\d+)');

  // Pre-compiled patterns for cleanValue (avoids hot path compilation)
  static final RegExp _surroundingDoubleQuotesPattern = RegExp(r'^"|"$');
  static final RegExp _surroundingSingleQuotesPattern = RegExp(r"^'|'$");
  static final RegExp _surroundingParenthesesPattern = RegExp(r'^\(|\)$');
  static final RegExp _surroundingBracketsPattern = RegExp(r'^\[|\]$');
  static final RegExp _surroundingBracesPattern = RegExp(r'^{|}$');
  static final RegExp _trailingSemicolonPattern = RegExp(r';$');

  /// Create AnalyticsEvent from regex match
  @override
  AnalyticsEvent createAnalyticsEvent(RegExpMatch match, String fullLine) {
    final eventName = match.group(1) ?? 'unknown_event';
    final paramsString = match.groupCount >= 2 ? match.group(2) ?? '' : '';

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: _extractTimestamp(fullLine),
      eventName: eventName,
      parameters: parseParams(paramsString),
      // Parse items from the full line to avoid losing data when the regex
      // capture truncates nested braces inside the items array.
      items: parseItems(fullLine),
    );
  }

  /// Extract timestamp from iOS log line.
  ///
  /// iOS timestamps can be in various formats:
  /// - `2024-01-15 10:30:45.123+0000`
  /// - `10:30:45.123`
  /// - No timestamp at all
  String _extractTimestamp(String line) {
    final isoMatch = _isoTimestampPattern.firstMatch(line);
    if (isoMatch != null) {
      return isoMatch.group(1) ?? '';
    }

    final timeMatch = _timeOnlyPattern.firstMatch(line);
    if (timeMatch != null) {
      return timeMatch.group(1) ?? '';
    }

    // Return current time as fallback
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Trims the block and strips the items array so item fields do not bleed
  /// into top-level params.
  @override
  String normalizeParamsString(String paramsString) =>
      ItemArrayParser.stripIosItemsArray(paramsString.trim(), _itemsKeyPattern);

  @override
  bool hasItemsArray(String paramsString) =>
      _itemsKeyPattern.hasMatch(paramsString);

  @override
  String? extractItemsSubstring(String paramsString) =>
      ItemArrayParser.extractIosItemsSubstring(paramsString, _itemsKeyPattern);

  /// Clean and normalize parameter values.
  @override
  String cleanValue(String value) {
    // Unwrap typed wrappers
    final wrapperMatch = _iosValueWrapperPattern.firstMatch(value.trim());
    final v = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    return v
        .replaceAll(_surroundingDoubleQuotesPattern, '') // Remove quotes
        .replaceAll(_surroundingSingleQuotesPattern, '') // Remove single quotes
        .replaceAll(_surroundingParenthesesPattern, '') // Remove parentheses
        .replaceAll(_surroundingBracketsPattern, '') // Remove brackets
        .replaceAll(_surroundingBracesPattern, '') // Remove braces
        .replaceAll(_trailingSemicolonPattern, '') // Remove trailing semicolon
        .trim();
  }
}
