import 'package:mason_logger/mason_logger.dart';

/// Parse parameter string from Firebase Analytics Bundle format into a map.
Map<String, String> parseBundleParams(
  String paramsString, {
  Logger? logger,
}) {
  final params = <String, String>{};

  if (paramsString.isEmpty) {
    return params;
  }

  try {
    // Enhanced regex patterns to handle various parameter formats
    final patterns = [
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

    // Clean the params string first
    var cleanParamsString = paramsString;
    if (cleanParamsString.startsWith('Bundle[{')) {
      cleanParamsString = cleanParamsString.substring(8);
    }
    if (cleanParamsString.endsWith('}]')) {
      cleanParamsString =
          cleanParamsString.substring(0, cleanParamsString.length - 2);
    }

    for (final pattern in patterns) {
      final matches = pattern.allMatches(cleanParamsString);
      for (final match in matches) {
        if (match.groupCount >= 2) {
          final key = match.group(1)?.trim();
          final value = match.group(2)?.trim();

          if (key != null &&
              value != null &&
              key.isNotEmpty &&
              value.isNotEmpty) {
            // Skip items parameter as it's handled separately
            if (key.toLowerCase() != 'items') {
              params[key] = cleanBundleValue(value);
            }
          }
        }
      }
    }

    // If we didn't get many params, try a more aggressive approach
    if (params.length < 3 && cleanParamsString.isNotEmpty) {
      _parseParamsAggressive(cleanParamsString, params);
    }
  } catch (e) {
    logger?.detail('Parameter parsing error: $e');
  }

  return params;
}

/// More aggressive parameter parsing for complex formats.
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
        params[key] = cleanBundleValue(value);
      }
    }
  }
}

/// Parse items array from Firebase Analytics Bundle format.
List<Map<String, String>> parseBundleItems(
  String paramsString, {
  Logger? logger,
}) {
  final items = <Map<String, String>>[];

  if (paramsString.isEmpty || !paramsString.contains('items=')) {
    return items;
  }

  try {
    // Look for items array: items=[Bundle[{...}], Bundle[{...}]]
    final itemsRegex = RegExp(
      r'items=\[(Bundle\[\{[^\}]+\}\](?:,\s*Bundle\[\{[^\}]+\}\])*)\]',
    );
    final itemsMatch = itemsRegex.firstMatch(paramsString);

    if (itemsMatch != null) {
      final itemsString = itemsMatch.group(1);
      if (itemsString != null) {
        // Extract individual Bundle[{...}] items
        final itemRegex = RegExp(r'Bundle\[\{([^\}]+)\}\]');
        final itemMatches = itemRegex.allMatches(itemsString);

        for (final itemMatch in itemMatches) {
          final itemParamsString = itemMatch.group(1);
          if (itemParamsString != null) {
            final itemParams =
                parseBundleParams('Bundle[{$itemParamsString}]');
            if (itemParams.isNotEmpty) {
              items.add(itemParams);
            }
          }
        }
      }
    }
  } catch (e) {
    logger?.detail('Items parsing error: $e');
  }

  return items;
}

/// Clean and normalize parameter values.
String cleanBundleValue(String value) {
  // Unwrap typed wrappers like String(...), Long(...), Double(...),
  // Boolean(...)
  final typedWrapper = RegExp(r'^[A-Za-z]+\((.*)\)$');
  final wrapperMatch = typedWrapper.firstMatch(value.trim());
  final v = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

  return v
      .replaceAll(RegExp(r'^"|"$'), '') // Remove surrounding quotes
      .replaceAll(RegExp(r"^'|'$"), '') // Remove surrounding single quotes
      .replaceAll(RegExp(r'^\(|\)$'), '') // Remove surrounding parentheses
      .replaceAll(RegExp(r'^\[|\]$'), '') // Remove surrounding brackets
      .replaceAll(RegExp(r'^{|}$'), '') // Remove surrounding braces
      .trim();
}

