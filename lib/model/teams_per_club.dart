import 'package:cloud_firestore/cloud_firestore.dart';

String keyTeamsPerClubClubId = 'clubId';
String keyTeamsPerClubSeasonId = 'seasonId';
String keyTeamsPerClubEquipes = 'equipes';
String keyTeamsPerClubScrapedAt = 'scrapedAt';
String keyTeamsPerClubSourceUrl = 'sourceUrl';

String keyEquipeId = 'id';
String keyEquipeName = 'name';
String keyEquipeUrl = 'url';
String keyEquipeCompetitions = 'competitions';

/// One équipe entry inside [TeamsPerClub.equipes].
class Equipe {
  String? id;
  String? name;
  String? url;
  List<String> competitions;

  Equipe({
    this.id,
    this.name,
    this.url,
    List<String>? competitions,
  }) : competitions = competitions ?? <String>[];

  factory Equipe.fromMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return Equipe(
      id: data[keyEquipeId]?.toString() ?? '',
      name: data[keyEquipeName]?.toString() ?? '',
      url: data[keyEquipeUrl]?.toString() ?? '',
      competitions: _parseStringList(data[keyEquipeCompetitions]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      keyEquipeId: id ?? '',
      keyEquipeName: name ?? '',
      keyEquipeUrl: url ?? '',
      keyEquipeCompetitions: competitions,
    };
  }

  @override
  String toString() {
    return 'Equipe(id=$id, name=$name, url=$url, '
        'competitions=$competitions)';
  }
}

/// Scraped FFF teams listing for one club and season.
class TeamsPerClub {
  String? clubId;
  String? seasonId;
  List<Equipe> equipes;
  DateTime? scrapedAt;
  String? sourceUrl;

  DocumentReference? ref;

  TeamsPerClub({
    this.clubId,
    this.seasonId,
    List<Equipe>? equipes,
    this.scrapedAt,
    this.sourceUrl,
    this.ref,
  }) : equipes = equipes ?? <Equipe>[];

  factory TeamsPerClub.fromMap(
    Map<String, dynamic> map, {
    DocumentReference? ref,
  }) {
    final List<Equipe> parsedEquipes = <Equipe>[];
    final rawEquipes = map[keyTeamsPerClubEquipes];

    if (rawEquipes is List) {
      for (final entry in rawEquipes) {
        if (entry is Map<String, dynamic>) {
          parsedEquipes.add(Equipe.fromMap(entry));
        } else if (entry is Map) {
          parsedEquipes.add(
            Equipe.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return TeamsPerClub(
      clubId: map[keyTeamsPerClubClubId]?.toString() ?? '',
      seasonId: map[keyTeamsPerClubSeasonId]?.toString() ?? '',
      equipes: deduplicateEquipes(parsedEquipes),
      scrapedAt: _parseDateTime(map[keyTeamsPerClubScrapedAt]),
      sourceUrl: map[keyTeamsPerClubSourceUrl]?.toString() ?? '',
      ref: ref,
    );
  }

  factory TeamsPerClub.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final map = snapshot.data() as Map<String, dynamic>? ?? {};
    return TeamsPerClub.fromMap(
      map,
      ref: snapshot.reference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      keyTeamsPerClubClubId: clubId ?? '',
      keyTeamsPerClubSeasonId: seasonId ?? '',
      keyTeamsPerClubEquipes: equipes.map((e) => e.toMap()).toList(),
      keyTeamsPerClubScrapedAt: scrapedAt != null
          ? Timestamp.fromDate(scrapedAt!)
          : null,
      keyTeamsPerClubSourceUrl: sourceUrl ?? '',
    };
  }

  @override
  String toString() {
    return 'TeamsPerClub(clubId=$clubId, seasonId=$seasonId, '
        'equipes=${equipes.length}, scrapedAt=$scrapedAt, '
        'sourceUrl=$sourceUrl)';
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) return <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

/// Deduplicates [equipes] by non-empty [Equipe.id], keeping the first entry
/// per id and merging [Equipe.competitions] (unique URLs, order preserved).
List<Equipe> deduplicateEquipes(List<Equipe> equipes) {
  final byId = <String, Equipe>{};
  final result = <Equipe>[];

  for (final equipe in equipes) {
    final id = equipe.id?.trim() ?? '';
    if (id.isEmpty) {
      result.add(equipe);
      continue;
    }

    final existing = byId[id];
    if (existing == null) {
      byId[id] = equipe;
      result.add(equipe);
    } else {
      _mergeEquipeCompetitions(existing, equipe);
    }
  }

  return result;
}

void _mergeEquipeCompetitions(Equipe target, Equipe source) {
  final seen = target.competitions.toSet();
  for (final url in source.competitions) {
    if (url.isNotEmpty && seen.add(url)) {
      target.competitions.add(url);
    }
  }
}
