/// Returns true when [candidateVersion] is newer than [currentVersion].
bool isNewerVersion(String candidateVersion, String currentVersion) {
  final candidate = _SemanticVersion.tryParse(candidateVersion);
  final current = _SemanticVersion.tryParse(currentVersion);
  if (candidate == null || current == null) {
    return candidateVersion != currentVersion;
  }

  return candidate.compareTo(current) > 0;
}

class _SemanticVersion implements Comparable<_SemanticVersion> {
  const _SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.preRelease,
  });

  final int major;
  final int minor;
  final int patch;
  final List<String> preRelease;

  static _SemanticVersion? tryParse(String value) {
    final withoutBuild = value.split('+').first;
    final parts = withoutBuild.split('-');
    final core = parts.first.split('.');
    if (core.length != 3) return null;

    final major = int.tryParse(core[0]);
    final minor = int.tryParse(core[1]);
    final patch = int.tryParse(core[2]);
    if (major == null || minor == null || patch == null) return null;

    return _SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      preRelease:
          parts.length > 1 ? parts.sublist(1).join('-').split('.') : const [],
    );
  }

  @override
  int compareTo(_SemanticVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      final comparison = pair.$1.compareTo(pair.$2);
      if (comparison != 0) return comparison;
    }

    return _comparePreRelease(other);
  }

  int _comparePreRelease(_SemanticVersion other) {
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final length = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < length; i++) {
      final left = preRelease[i];
      final right = other.preRelease[i];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      final comparison = switch ((leftNumber, rightNumber)) {
        (final int leftNumber, final int rightNumber) =>
          leftNumber.compareTo(rightNumber),
        (final int _, null) => -1,
        (null, final int _) => 1,
        _ => left.compareTo(right),
      };
      if (comparison != 0) return comparison;
    }

    return preRelease.length.compareTo(other.preRelease.length);
  }
}
