import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;

/// Builds calendar event titles, locations, and map links for agenda items.
class CalendarEventFormatter {
  const CalendarEventFormatter._();

  static String eventTitle(AgendaItem item) {
    switch (item.type) {
      case AgendaItemType.match:
        final match = item.match;
        if (match == null) return item.title;
        return matchEventTitle(teamName: item.title, match: match);
      case AgendaItemType.entrainement:
      case AgendaItemType.preparationPhysique:
      case AgendaItemType.nonSport:
        return item.title;
    }
  }

  static String? eventLocation(AgendaItem item) {
    if (item.type == AgendaItemType.nonSport) {
      final String? location = item.subtitle?.trim();
      return (location == null || location.isEmpty) ? null : location;
    }
    if (item.type != AgendaItemType.match) return null;
    return matchLocation(item.match);
  }

  static String matchEventTitle({
    required String teamName,
    required grinta_match.Match match,
  }) {
    final chType = _clean(match.chType);
    final dayOrTour = (match.day ?? 0) > 0
        ? match.day.toString()
        : _clean(match.tour);

    final line1Parts = <String>[
      _clean(teamName),
      if (chType.isNotEmpty) chType,
      if (dayOrTour.isNotEmpty) dayOrTour,
    ];
    final line1 = line1Parts.join(' - ');

    final team1 = _clean(match.team1);
    final team2 = _clean(match.team2);
    final line2 = [team1, team2].where((part) => part.isNotEmpty).join(' - ');

    if (line2.isEmpty) return line1;
    if (line1.isEmpty) return line2;
    return '$line1\n$line2';
  }

  static String? matchLocation(grinta_match.Match? match) {
    if (match == null) return null;

    final terrainNom = _clean(match.nomDuTerrain);
    final adresse = _clean(match.terrainAdresse1);
    if (terrainNom.isEmpty && adresse.isEmpty) return null;
    if (terrainNom.isEmpty) return adresse;
    if (adresse.isEmpty) return terrainNom;
    return '$terrainNom - $adresse';
  }

  static ({double latitude, double longitude})? matchCoordinates(
    grinta_match.Match? match,
  ) {
    final corners = match?.fieldGpsCorners;
    if (corners == null || !corners.isComplete) return null;

    final points = [
      corners.topLeft!,
      corners.topRight!,
      corners.bottomRight!,
      corners.bottomLeft!,
    ];

    final latitude =
        points.map((point) => point.latitude).reduce((a, b) => a + b) / 4;
    final longitude =
        points.map((point) => point.longitude).reduce((a, b) => a + b) / 4;
    return (latitude: latitude, longitude: longitude);
  }

  static String? mapsUrl(grinta_match.Match? match) {
    final coordinates = matchCoordinates(match);
    if (coordinates != null) {
      return 'https://maps.google.com/maps?q='
          '${coordinates.latitude},${coordinates.longitude}';
    }

    final location = matchLocation(match);
    if (location == null || location.isEmpty) return null;
    return 'https://maps.google.com/maps?q=${Uri.encodeComponent(location)}';
  }

  static String eventDescription({
    required String deepLink,
    required AgendaItem item,
  }) {
    final parts = <String>[deepLink];
    if (item.type == AgendaItemType.match) {
      final maps = mapsUrl(item.match);
      if (maps != null) parts.add(maps);
    }
    return parts.join('\n');
  }

  static String? icsGeoValue(grinta_match.Match? match) {
    final coordinates = matchCoordinates(match);
    if (coordinates == null) return null;
    return '${coordinates.latitude};${coordinates.longitude}';
  }

  static String _clean(String? value) => value?.trim() ?? '';
}
