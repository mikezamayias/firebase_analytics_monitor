#!/usr/bin/env dart
// This is a development tool that uses print for CLI output.
// ignore_for_file: avoid_print

import 'dart:io';

const _pubspecVersionPattern = r'^version:\s*.+$';
const _dartVersionPattern = "const packageVersion = '[^']+';";
// Matches the hosted-dependency declaration (with caret constraint) only —
// the path-based `dependency_overrides` entry does not start with `^` and is
// safely ignored.
const _famonCoreDepPattern = r'famon_core:\s*\^[^\s]+';

const _validPackages = {'famon', 'famon_core', 'both'};

/// Updates package versions across the monorepo. Versions are decoupled:
/// `famon` (CLI) and `famon_core` (library) move on independent tracks.
///
///   - `--package famon`:       pubspec.yaml `version:` field +
///                              lib/src/version.dart
///   - `--package famon_core`:  packages/famon_core/pubspec.yaml `version:`
///   - `--package both`:        all of the above, AND lockstep the
///                              `famon_core: ^X.Y.Z` constraint in root pubspec
///                              (legacy synchronized-bump mode)
///
/// All updates are validated up front and applied atomically: if any source
/// cannot be located or rewritten, no file is mutated.
///
/// Usage:
///   dart run tool/update_version.dart --package famon       1.5.1
///   dart run tool/update_version.dart --package famon_core  1.5.1
///   dart run tool/update_version.dart --package both        1.5.1
void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed == null) {
    _printUsage();
    exit(1);
  }
  final (package, version) = parsed;

  final versionRegex = RegExp(r'^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$');
  if (!versionRegex.hasMatch(version)) {
    print('Error: Invalid version format: $version');
    print('Expected format: x.y.z (e.g., 1.5.1 or 1.5.1-beta.1)');
    exit(1);
  }

  final updates = _buildUpdates(package, version);

  // Phase 1 — preflight every update. Any failure aborts before any write.
  for (final update in updates) {
    final error = update.preflight();
    if (error != null) {
      print('Error: $error');
      exit(1);
    }
  }

  // Phase 2 — apply writes. If write N throws after writes 1..N-1 succeeded,
  // restore those files from the snapshot captured during preflight.
  final completed = <_FileUpdate>[];
  try {
    for (final update in updates) {
      update.apply();
      completed.add(update);
      print('Updated ${update.path} → version $version');
    }
  } on FileSystemException catch (e) {
    stderr.writeln(
      'Error: write failed for ${e.path ?? '<unknown>'}: ${e.message}',
    );
    for (final done in completed) {
      done.restore();
      stderr.writeln('Reverted ${done.path}');
    }
    exit(1);
  }

  print('\n$package version updated to $version.');
  final changelog = switch (package) {
    'famon' => 'CHANGELOG.md',
    'famon_core' => 'packages/famon_core/CHANGELOG.md',
    _ => 'both CHANGELOG.md files',
  };
  print('Remember to update $changelog with changes.');
}

(String, String)? _parseArgs(List<String> args) {
  String? package;
  String? version;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--package') {
      if (i + 1 >= args.length) return null;
      package = args[++i];
    } else if (a.startsWith('--package=')) {
      package = a.substring('--package='.length);
    } else if (a == '--help' || a == '-h') {
      return null;
    } else if (!a.startsWith('-')) {
      if (version != null) return null; // duplicate positional
      version = a;
    } else {
      return null; // unknown flag
    }
  }

  if (package == null || version == null) return null;
  if (!_validPackages.contains(package)) return null;
  return (package, version);
}

void _printUsage() {
  print('Usage: dart run tool/update_version.dart --package <name> <version>');
  print('');
  print('  --package famon       Bump famon CLI only');
  print('  --package famon_core  Bump famon_core library only');
  print('  --package both        Bump both in lockstep (legacy)');
  print('');
  print('Example: dart run tool/update_version.dart --package famon 1.5.1');
}

List<_FileUpdate> _buildUpdates(String package, String version) {
  final rootVersion = _Rewrite(
    pattern: RegExp(_pubspecVersionPattern, multiLine: true),
    replacement: 'version: $version',
    description: 'version: field',
  );
  final coreVersion = _Rewrite(
    pattern: RegExp(_pubspecVersionPattern, multiLine: true),
    replacement: 'version: $version',
    description: 'version: field',
  );
  final coreDep = _Rewrite(
    pattern: RegExp(_famonCoreDepPattern),
    replacement: 'famon_core: ^$version',
    description: 'famon_core dependency constraint',
  );
  final dartConst = _Rewrite(
    pattern: RegExp(_dartVersionPattern),
    replacement: "const packageVersion = '$version';",
    description: 'packageVersion constant',
  );

  return switch (package) {
    'famon' => [
      _FileUpdate('pubspec.yaml', [rootVersion]),
      _FileUpdate('lib/src/version.dart', [dartConst]),
    ],
    'famon_core' => [
      _FileUpdate('packages/famon_core/pubspec.yaml', [coreVersion]),
    ],
    'both' => [
      _FileUpdate('pubspec.yaml', [rootVersion, coreDep]),
      _FileUpdate('packages/famon_core/pubspec.yaml', [coreVersion]),
      _FileUpdate('lib/src/version.dart', [dartConst]),
    ],
    _ => throw StateError('unreachable: package=$package'),
  };
}

class _Rewrite {
  _Rewrite({
    required this.pattern,
    required this.replacement,
    required this.description,
  });

  final RegExp pattern;
  final String replacement;
  final String description;
}

class _FileUpdate {
  _FileUpdate(this.path, this.rewrites);

  final String path;
  final List<_Rewrite> rewrites;

  String? _originalContent;
  String? _newContent;

  /// Returns null on success, or an error message describing why the update
  /// cannot be applied. Captures the file's current contents so [restore]
  /// can revert if a later update in the batch fails.
  String? preflight() {
    final file = File(path);
    if (!file.existsSync()) {
      return '$path not found';
    }

    final original = file.readAsStringSync();
    var next = original;
    for (final rewrite in rewrites) {
      if (!rewrite.pattern.hasMatch(next)) {
        return 'Could not locate ${rewrite.description} in $path';
      }
      next = next.replaceFirst(rewrite.pattern, rewrite.replacement);
    }

    _originalContent = original;
    _newContent = next;
    return null;
  }

  void apply() {
    final newContent = _newContent;
    if (newContent == null) {
      throw StateError('apply() called before preflight() for $path');
    }
    File(path).writeAsStringSync(newContent);
  }

  void restore() {
    final original = _originalContent;
    if (original == null) return;
    try {
      File(path).writeAsStringSync(original);
    } on FileSystemException catch (e) {
      stderr.writeln(
        'WARNING: failed to restore $path: ${e.message}. '
        'Inspect manually with `git diff $path`.',
      );
    }
  }
}
