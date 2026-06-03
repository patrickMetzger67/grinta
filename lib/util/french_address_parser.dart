/// Parses French football field addresses and builds TRACKER_Fields document ids.
class FrenchAddressParser {
  FrenchAddressParser._();

  /// Splits [terrainAdresse1] into street ([adresse]) and city ([ville]).
  ///
  /// Handles formats like `ROUTE DU RHIN 67150 - ERSTEIN` where the city is
  /// the last segment after ` - ` and the postal code is stripped from the street.
  static ({String adresse, String ville}) parseTerrainAdresse1(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      return (adresse: '', ville: '');
    }

    final dashParts = trimmed.split(RegExp(r'\s+-\s+'));
    if (dashParts.length >= 2) {
      final ville = dashParts.last.trim();
      final streetWithPostalCode =
          dashParts.sublist(0, dashParts.length - 1).join(' - ').trim();
      return (
        adresse: _stripPostalCode(streetWithPostalCode),
        ville: ville,
      );
    }

    final trailingMatch =
        RegExp(r'^(.+?)\s+(\d{5})\s+(.+)$').firstMatch(trimmed);
    if (trailingMatch != null) {
      return (
        adresse: trailingMatch.group(1)!.trim(),
        ville: trailingMatch.group(3)!.trim(),
      );
    }

    return (adresse: _stripPostalCode(trimmed), ville: '');
  }

  /// Document id: `terrainNom + ville` with all whitespace removed, then lowercased.
  static String computeFieldId({
    required String terrainNom,
    required String ville,
  }) {
    return '${terrainNom.trim()}${ville.trim()}'
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  static String _stripPostalCode(String street) {
    return street.replaceAll(RegExp(r'\s+\d{5}\s*$'), '').trim();
  }
}
