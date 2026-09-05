import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/models/platform_type.dart';
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart';
import 'package:famon_core/src/services/shared/base_log_parser_service.dart';
import 'package:famon_core/src/services/shared/item_array_parser.dart';
import 'package:injectable/injectable.dart';

/// Service for parsing Firebase Analytics log lines from adb logcat output.
///
/// ## Regex Pattern Matching Strategy
///
/// This service uses a collection of pre-compiled static regex patterns to
/// parse various Firebase Analytics log formats from Android logcat output.
/// The patterns are stored as `static final` to ensure they are compiled once
/// at class load time, avoiding the overhead of regex compilation on each
/// parse call.
///
/// ### Pattern Evaluation Order
///
/// Patterns are ordered by expected frequency of occurrence to minimize
/// unnecessary regex evaluations:
///
/// 1. **Standard format** (`Logging event: origin=\w+,name=...`) - Most common
///    format in modern Firebase Analytics implementations. Accepts any origin
///    value (`app`, `auto`, `firebase`).
/// 2. **FA-SVC tagged patterns** - Firebase Analytics Service logs, frequently
///    seen in debug builds.
/// 3. **FA tagged patterns** - General Firebase Analytics logs.
/// 4. **FA `Logging event (FE)` / `Event logged` formats** - Native Firebase
///    SDK auto-events. Matched by `\bFA\b` to cover both brief (`I/FA:`) and
///    `-v time` (`V FA-SVC  :`, `V FA  :`) logcat output formats.
/// 5. **Basic/legacy formats** - Older or simplified log formats.
///
/// The marker check, pattern loop, params scan, and items scan live in
/// [BaseLogParserService]. This class supplies the Android patterns, the
/// Bundle wrapper handling, and the value cleaning.
@Injectable(as: LogParserInterface)
class LogParserService extends BaseLogParserService {
  /// Creates a new LogParserService
  ///
  /// [logger] - Optional logger for reporting parsing errors
  LogParserService({super.logger});

  @override
  PlatformType get platform => PlatformType.android;

  @override
  String get platformLabel => 'Android';

  @override
  List<String> get faMarkers => _faMarkers;

  @override
  List<RegExp> get logPatterns => _logPatterns;

  @override
  List<RegExp> get paramPatterns => _paramPatterns;

  @override
  String get itemOpenToken => 'Bundle[{';

  /// Set of markers that indicate a line may contain Firebase Analytics data.
  static const _faMarkers = ['FA', 'Logging event', 'Event logged'];

  /// Regex patterns for different Firebase Analytics log formats.
  ///
  /// Patterns are ordered by expected frequency of occurrence (most common
  /// first) to minimize the average number of regex evaluations per line.
  /// Each pattern captures:
  /// - Group 1: Timestamp (MM-DD HH:MM:SS.mmm)
  /// - Group 2: Event name
  /// - Group 3: Parameters (Bundle format, optional in some patterns)
  static final List<RegExp> _logPatterns = [
    // Pattern 1: Standard format with explicit origin field
    // Matches both app-logged (origin=app) and auto/native (origin=auto, origin=firebase) events.
    // Example: Logging event: origin=app,name=purchase,params=Bundle[{...}]
    // Example: Logging event: origin=auto,name=screen_view,params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Logging event: '
      r'origin=\w+,name=([^,]+),params=(Bundle\[.*\])',
    ),

    // Pattern 2: FA-SVC with "Logging event" format
    // Example: FA-SVC Logging event (FE): name=purchase, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),

    // Pattern 3: FA with "Logging event" format
    // Example: FA Logging event: name=add_to_cart, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),

    // Pattern 4: FA-SVC with "Event:" format
    // Example: FA-SVC Event: screen_view Bundle[{screen_name=Home}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),

    // Pattern 5: FA with "Event:" format
    // Example: FA Event: login Bundle[{method=google}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),

    // Pattern 6: FA "Logging event (FE)" format without name= prefix
    // Matches both brief (I/FA:) and -v time (V FA-SVC  :) logcat formats.
    // Example (brief):    I/FA: Logging event (FE): screen_view, Bundle[...]
    // Example (-v time):  V FA-SVC  : Logging event (FE): screen_view, ...
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Logging event \(FE\): ([^,\s]+),.*(Bundle\[.*\])',
    ),

    // Pattern 7: FA "Event logged" format
    // Matches both brief (I/FA:) and -v time (V FA  :) logcat formats.
    // Example (brief):   I/FA: Event logged: purchase, params=Bundle[{...}]
    // Example (-v time): V FA  : Event logged: purchase, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Event logged: ([^,\s]+).*params[:=](Bundle\[.*\])',
    ),

    // Pattern 8: Alternative "Event logged" format (less common)
    // Example: Event logged: add_to_cart params:Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Event logged: ([^\s]+).*params:(Bundle\[.*\])?',
    ),

    // Pattern 9: FA-SVC basic format with event_name: prefix
    // Example: FA-SVC event_name:custom_event
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*event_name:([^\s,]+)',
    ),

    // Pattern 10: FA basic format with event_name: prefix
    // Example: FA event_name:custom_event
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*event_name:([^\s,]+)',
    ),
  ];

  /// Pattern for FA warnings about invalid default parameter types.
  ///
  /// Example: W/FA: Invalid default event parameter type. Name, value:
  /// cart_total_items, 1
  static final RegExp _faInvalidDefaultParamPattern = RegExp(
    r'^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\b[VDIWE]/FA\b.*Invalid default event parameter type\.\s*Name, value:\s*([^,]+),\s*(.+)$',
  );

  /// Pre-compiled regex patterns for parameter parsing.
  ///
  /// These patterns handle various Firebase Analytics Bundle parameter formats.
  static final List<RegExp> _paramPatterns = [
    // Standard key=value format
    RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),
    // Typed parameters: String(value), Long(value), etc.
    RegExp(r'(\w+)=String\(([^)]*)\)'),
    RegExp(r'(\w+)=Long\(([^)]*)\)'),
    RegExp(r'(\w+)=Double\(([^)]*)\)'),
    RegExp(r'(\w+)=Boolean\(([^)]*)\)'),
    RegExp(r'(\w+)=Integer\(([^)]*)\)'),
    RegExp(r'(\w+)=Float\(([^)]*)\)'),
    // Handle quoted strings
    RegExp(r'(\w+)="([^"]*)"'),
    RegExp(r"(\w+)='([^']*)'"),
    // Handle parameters separated by commas with spaces
    RegExp(r'(\w+):\s*([^,\[\]{}]+)(?=[,\]}]|$)'),
    // Key-value pairs with colon separator
    RegExp(r'(\w+)\s*:\s*([^,\[\]{}]+)(?=[,\]}]|$)'),
    // Parameters without type wrapper but with equals
    RegExp(r'(\w+)\s*=\s*([^,\[\]{}()]+)(?=[,\]}]|$)'),
  ];

  /// Pre-compiled regex pattern for typed value wrappers.
  ///
  /// Matches patterns like String(...), Long(...), Double(...), etc.
  static final RegExp _typedWrapperPattern = RegExp(r'^[A-Za-z]+\((.*)\)$');

  /// Validates Firebase event names: letters/digits/underscores, starts with
  /// a letter, max 40 characters.
  static final RegExp _validFirebaseNamePattern =
      RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

  /// Maximum allowed length for a Firebase event name.
  static const int _maxEventNameLength = 40;

  /// Maximum allowed length for a Firebase parameter value.
  static const int _maxParamValueLength = 100;

  /// Create AnalyticsEvent from regex match.
  ///
  /// Returns `null` if the captured event name does not conform to the
  /// Firebase naming convention (`^[a-zA-Z][a-zA-Z0-9_]*$`, max 40 chars),
  /// dropping malformed or potentially malicious log lines.
  @override
  AnalyticsEvent? createAnalyticsEvent(RegExpMatch match, String fullLine) {
    final timestamp = match.group(1)!;
    // GA4 debug logcat appends internal shortcodes: "screen_view(_vs)",
    // "user_engagement(_e)", etc. Strip before validation.
    final eventName = _stripGa4DebugShortcode(match.group(2)!);

    if (!_isValidEventName(eventName)) {
      logger?.warn('Skipping invalid Firebase event name: "$eventName"');
      return null;
    }

    final paramsString = match.groupCount >= 3 ? match.group(3) ?? '' : '';

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: timestamp,
      eventName: eventName,
      parameters: parseParams(paramsString),
      items: parseItems(paramsString),
    );
  }

  /// Special handling for FA warnings about invalid default parameter types.
  @override
  AnalyticsEvent? parseUnmatched(String logLine) {
    final warn = _faInvalidDefaultParamPattern.firstMatch(logLine);
    if (warn == null) return null;

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: warn.group(1)!,
      eventName: 'fa_invalid_default_param',
      parameters: {warn.group(2)!.trim(): cleanValue(warn.group(3)!.trim())},
    );
  }

  static String _stripGa4DebugShortcode(String eventName) {
    final shortcodeStart = eventName.lastIndexOf('(_');
    if (shortcodeStart <= 0 || !eventName.endsWith(')')) return eventName;

    for (var i = shortcodeStart + 2; i < eventName.length - 1; i++) {
      final codeUnit = eventName.codeUnitAt(i);
      final isAsciiLetter = (codeUnit >= 65 && codeUnit <= 90) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (!isAsciiLetter) return eventName;
    }

    return eventName.substring(0, shortcodeStart);
  }

  /// Strips the `Bundle[{` ... `}]` wrapper and the items array.
  @override
  String normalizeParamsString(String paramsString) {
    var clean = paramsString;
    if (clean.startsWith('Bundle[{')) {
      clean = clean.substring(8);
    }
    if (clean.endsWith('}]')) {
      clean = clean.substring(0, clean.length - 2);
    }
    // Remove items array so item_* fields don't bleed into top-level params.
    return ItemArrayParser.stripAndroidItemsArray(clean);
  }

  /// If the pattern scan found few params, try a looser split on commas.
  @override
  void afterParamScan(String cleanParamsString, Map<String, String> params) {
    if (params.length < 3 && cleanParamsString.isNotEmpty) {
      _parseParamsAggressive(cleanParamsString, params);
    }
  }

  @override
  bool hasItemsArray(String paramsString) => paramsString.contains('items=');

  @override
  String? extractItemsSubstring(String paramsString) =>
      ItemArrayParser.extractAndroidItemsSubstring(paramsString);

  @override
  String wrapItemContent(String itemContent) => 'Bundle[{$itemContent}]';

  /// More aggressive parameter parsing for complex formats
  void _parseParamsAggressive(String paramsString, Map<String, String> params) {
    // Split by comma and try to extract key=value pairs
    final parts = paramsString.split(',');

    for (final part in parts) {
      final trimmedPart = part.trim();

      // Look for key=value or key:value patterns
      final colonIndex = trimmedPart.indexOf(':');
      final equalsIndex = trimmedPart.indexOf('=');

      var separatorIndex = -1;
      if (colonIndex != -1 && (equalsIndex == -1 || colonIndex < equalsIndex)) {
        separatorIndex = colonIndex;
      } else if (equalsIndex != -1) {
        separatorIndex = equalsIndex;
      }

      if (separatorIndex > 0 && separatorIndex < trimmedPart.length - 1) {
        final key = trimmedPart.substring(0, separatorIndex).trim();
        final value = trimmedPart.substring(separatorIndex + 1).trim();

        if (key.isNotEmpty &&
            value.isNotEmpty &&
            !value.startsWith('[') &&
            !value.startsWith('{') &&
            key.toLowerCase() != 'items') {
          params[key] = cleanValue(value);
        }
      }
    }
  }

  /// Returns true if [name] conforms to Firebase event name conventions.
  bool _isValidEventName(String name) =>
      name.isNotEmpty &&
      name.length <= _maxEventNameLength &&
      _validFirebaseNamePattern.hasMatch(name);

  /// Clean and normalize a parameter value in a single pass.
  ///
  /// Steps (all in one StringBuffer scan to avoid chained replaceAll):
  /// 1. Unwrap typed wrappers e.g. `String(v)`, `Long(v)`.
  /// 2. Strip leading/trailing delimiter characters (`"'()[]{}`) from the raw
  ///    string.
  /// 3. Iterate the remaining characters once: skip ASCII control characters
  ///    and stop after [_maxParamValueLength] characters have been written.
  @override
  String cleanValue(String value) {
    // Unwrap typed wrappers: String(...), Long(...), Double(...), Boolean(...)
    final wrapperMatch = _typedWrapperPattern.firstMatch(value.trim());
    final raw = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    // Strip surrounding delimiter characters from both ends.
    var start = 0;
    var end = raw.length;
    while (start < end && _isWrapperDelimiter(raw.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _isWrapperDelimiter(raw.codeUnitAt(end - 1))) {
      end--;
    }

    final candidate = raw.substring(start, end).trim();

    // Single pass: skip control characters, collect up to _maxParamValueLength.
    final out = StringBuffer();
    for (final codeUnit in candidate.codeUnits) {
      final isControl =
          (codeUnit >= 0x00 && codeUnit <= 0x1F) || codeUnit == 0x7F;
      if (!isControl) {
        out.writeCharCode(codeUnit);
        if (out.length >= _maxParamValueLength) break;
      }
    }

    return out.toString();
  }

  /// Returns true if [codeUnit] is a delimiter that should be stripped from
  /// the start or end of a parameter value.
  static bool _isWrapperDelimiter(int codeUnit) =>
      codeUnit == 0x22 || // "
      codeUnit == 0x27 || // '
      codeUnit == 0x28 || // (
      codeUnit == 0x29 || // )
      codeUnit == 0x5B || // [
      codeUnit == 0x5D || // ]
      codeUnit == 0x7B || // {
      codeUnit == 0x7D; // }
}
