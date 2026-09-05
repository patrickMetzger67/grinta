/// Parsed metadata from an FFF epreuves competition engagement URL.
///
/// Pattern:
/// `/competition/engagement/{numericId}-{slug}/phase/{phase}/{groupe}`
class FffCompetitionInfo {
  const FffCompetitionInfo({
    required this.rawUrl,
    this.engagementId,
    this.slug,
    required this.name,
    required this.phase,
    required this.groupe,
  });

  final String rawUrl;
  final String? engagementId;
  final String? slug;
  final String name;
  final int phase;
  final int groupe;

  @override
  String toString() {
    return 'FffCompetitionInfo(name=$name, phase=$phase, groupe=$groupe, '
        'engagementId=$engagementId, slug=$slug)';
  }
}

final RegExp _fffCompetitionUrlPattern = RegExp(
  r'/competition/engagement/(\d+)-([^/]+)/phase/(\d+)/(\d+)',
  caseSensitive: false,
);

final RegExp _ageCategoryPattern = RegExp(r'^u\d+$', caseSensitive: false);

const Map<String, String> _slugWordReplacements = <String, String>{
  'regional': 'Régional',
  'regionale': 'Régionale',
  'departemental': 'Départemental',
  'departementale': 'Départementale',
  'feminine': 'Féminine',
  'feminin': 'Féminin',
  'feminines': 'Féminines',
  'masculin': 'Masculin',
  'masculine': 'Masculine',
  'elite': 'Élite',
  'premiere': 'Première',
  'honneur': 'Honneur',
  'promotion': 'Promotion',
  'preparation': 'Préparation',
  'senior': 'Senior',
  'veterans': 'Vétérans',
  'veteran': 'Vétéran',
};

const Set<String> _frenchLowercaseWords = <String>{
  'a',
  'au',
  'aux',
  'de',
  'des',
  'du',
  'en',
  'et',
  'la',
  'le',
  'les',
};

/// Builds the Firestore `engagement` document id:
/// `{clubId}-{competitionId}-{group}-{stage}`.
String buildEngagementDocumentId({
  required String clubId,
  required String competitionId,
  required String group,
  required String stage,
}) {
  return '$clubId-$competitionId-$group-$stage';
}

/// Parses a single FFF competition engagement URL.
///
/// Also accepts district calendar query URLs:
/// `https://alsace.fff.fr/competitions?competition_id=450652&poule=3`
///
/// [FffCompetitionInfo.groupe] / [FffCompetitionInfo.phase] are `0` when the
/// query URL omits that parameter (do not treat `0` as poule 1).
FffCompetitionInfo? parseFffCompetitionUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final match = _fffCompetitionUrlPattern.firstMatch(trimmed);
  if (match != null) {
    final engagementId = match.group(1);
    final slug = match.group(2)?.trim();
    final phase = int.tryParse(match.group(3) ?? '');
    final groupe = int.tryParse(match.group(4) ?? '');

    if (slug != null && slug.isNotEmpty && phase != null && groupe != null) {
      return FffCompetitionInfo(
        rawUrl: trimmed,
        engagementId: engagementId,
        slug: slug,
        name: slugToCompetitionName(slug),
        phase: phase,
        groupe: groupe,
      );
    }
  }

  return _parseFffCompetitionQueryUrl(trimmed);
}

FffCompetitionInfo? _parseFffCompetitionQueryUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.queryParameters.isEmpty) {
    return null;
  }

  final engagementId = (uri.queryParameters['competition_id'] ??
          uri.queryParameters['competitionId'] ??
          '')
      .trim();
  if (engagementId.isEmpty || int.tryParse(engagementId) == null) {
    return null;
  }

  final pouleRaw = (uri.queryParameters['poule'] ??
          uri.queryParameters['groupe'] ??
          '')
      .trim();
  final phaseRaw = (uri.queryParameters['phase'] ??
          uri.queryParameters['stage'] ??
          '')
      .trim();

  return FffCompetitionInfo(
    rawUrl: url,
    engagementId: engagementId,
    slug: null,
    name: engagementId,
    phase: int.tryParse(phaseRaw) ?? 0,
    groupe: int.tryParse(pouleRaw) ?? 0,
  );
}

/// Parses a list of FFF competition URLs, keeping only valid entries in order.
List<FffCompetitionInfo> parseFffCompetitionUrls(List<String> urls) {
  return urls
      .map(parseFffCompetitionUrl)
      .whereType<FffCompetitionInfo>()
      .toList();
}

/// Whether [url] refers to an FFF friendly-matches competition
/// (e.g. slug `matchs-amicaux-seniors` → "Matchs Amicaux Seniors").
bool isFriendlyCompetitionUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;

  final info = parseFffCompetitionUrl(trimmed);
  if (info != null) {
    final slug = info.slug?.toLowerCase() ?? '';
    if (slug.contains('amicaux') || slug.contains('amical')) {
      return true;
    }

    final name = info.name.toLowerCase();
    return name.contains('amicaux') || name.contains('amical');
  }

  final lower = trimmed.toLowerCase();
  return lower.contains('amicaux') || lower.contains('amical');
}

/// Converts the slug portion (without numeric engagement id) to a display name.
String slugToCompetitionName(String slug) {
  var parts = slug
      .split('-')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isNotEmpty && _ageCategoryPattern.hasMatch(parts.last)) {
    parts = parts.sublist(0, parts.length - 1);
  }

  if (parts.isEmpty) {
    return slug;
  }

  final words = parts.map(_formatSlugWord).toList();
  return _applyFrenchTitleCase(words);
}

String _formatSlugWord(String word) {
  final lower = word.toLowerCase();

  final ageMatch = RegExp(r'^u(\d+)$').firstMatch(lower);
  if (ageMatch != null) {
    return 'U${ageMatch.group(1)}';
  }

  if (RegExp(r'^\d+$').hasMatch(lower)) {
    return word;
  }

  final replacement = _slugWordReplacements[lower];
  if (replacement != null) {
    return replacement;
  }

  return lower[0].toUpperCase() + lower.substring(1);
}

String _applyFrenchTitleCase(List<String> words) {
  return words.asMap().entries.map((entry) {
    final index = entry.key;
    final word = entry.value;
    if (index > 0 && _frenchLowercaseWords.contains(word.toLowerCase())) {
      return word.toLowerCase();
    }
    return word;
  }).join(' ');
}
