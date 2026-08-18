import 'package:grinta/model/match.dart';

enum MatchVideoObjectKind { person, ball }

class MatchVideoDetection {
  const MatchVideoDetection({
    required this.kind,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.score = 1,
    this.atMs,
    this.trackId,
    this.playerId,
    this.jerseyNumber,
    this.teamId,
  });

  final MatchVideoObjectKind kind;
  final double left;
  final double top;
  final double width;
  final double height;
  final double score;

  /// Position in the video, in milliseconds.
  final int? atMs;
  final String? trackId;
  final String? playerId;
  final int? jerseyNumber;
  final String? teamId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kind': kind.name,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'score': score,
      if (atMs != null) 'atMs': atMs,
      if (trackId != null) 'trackId': trackId,
      if (playerId != null) 'playerId': playerId,
      if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
      if (teamId != null) 'teamId': teamId,
    };
  }

  factory MatchVideoDetection.fromMap(Map<String, dynamic> map) {
    return MatchVideoDetection(
      kind: matchVideoObjectKindFromName('${map['kind'] ?? ''}'),
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 1,
      atMs: (map['atMs'] as num?)?.toInt(),
      trackId: map['trackId']?.toString(),
      playerId: map['playerId']?.toString(),
      jerseyNumber: (map['jerseyNumber'] as num?)?.toInt(),
      teamId: map['teamId']?.toString(),
    );
  }
}

class MatchVideoTeam {
  MatchVideoTeam({
    this.teamId,
    this.name,
    this.kitColor,
  });

  String? teamId;
  String? name;

  /// ARGB kit color chosen for this team on the video.
  int? kitColor;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (teamId != null && teamId!.trim().isNotEmpty) 'teamId': teamId,
      if (name != null && name!.trim().isNotEmpty) 'name': name,
      if (kitColor != null) 'kitColor': matchVideoColorToHex(kitColor),
    };
  }

  factory MatchVideoTeam.fromMap(Map<String, dynamic>? map) {
    if (map == null) return MatchVideoTeam();
    return MatchVideoTeam(
      teamId: map['teamId']?.toString(),
      name: map['name']?.toString(),
      kitColor: matchVideoColorFromHex(
        (map['kitColor'] ?? map['color'])?.toString(),
      ),
    );
  }
}

class MatchVideo {
  MatchVideo({
    this.id,
    this.matchId,
    this.videoUrl,
    this.storagePath,
    MatchVideoTeam? team1,
    MatchVideoTeam? team2,
    int? team1KitColor,
    int? team2KitColor,
    this.refereeKitColor,
    List<MatchVideoDetection>? detections,
  })  : team1 = team1 ?? MatchVideoTeam(kitColor: team1KitColor),
        team2 = team2 ?? MatchVideoTeam(kitColor: team2KitColor),
        detections = detections ?? <MatchVideoDetection>[];

  String? id;
  String? matchId;

  /// Same URL as [Match.videoUrl]. Stored here for the analysis document.
  String? videoUrl;
  String? storagePath;

  /// Home / [Match.team1] kit on this video.
  MatchVideoTeam team1;

  /// Away / [Match.team2] kit on this video.
  MatchVideoTeam team2;

  int? get team1KitColor => team1.kitColor;
  set team1KitColor(int? value) => team1.kitColor = value;

  int? get team2KitColor => team2.kitColor;
  set team2KitColor(int? value) => team2.kitColor = value;

  /// Referee / assistant referee kit on this video.
  int? refereeKitColor;

  List<MatchVideoDetection> detections;

  /// Copies team names / ids from the match sheet onto this video analysis.
  void applyMatch(Match match) {
    matchId = match.id;
    team1.name = match.team1?.trim();
    team2.name = match.team2?.trim();
    final ids = (match.teams ?? const <dynamic>[])
        .map((raw) => raw?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final primary = match.teamID?.trim();
    if (primary != null && primary.isNotEmpty) {
      team1.teamId = primary;
      final opponents = ids.where((id) => id != primary);
      team2.teamId = opponents.isEmpty ? team2.teamId : opponents.first;
    } else {
      team1.teamId = ids.isNotEmpty ? ids.first : team1.teamId;
      team2.teamId = ids.length > 1 ? ids[1] : team2.teamId;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (matchId != null) 'matchId': matchId,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (storagePath != null) 'storagePath': storagePath,
      'team1': team1.toMap(),
      'team2': team2.toMap(),
      if (team1KitColor != null)
        'team1KitColor': matchVideoColorToHex(team1KitColor),
      if (team2KitColor != null)
        'team2KitColor': matchVideoColorToHex(team2KitColor),
      if (refereeKitColor != null)
        'refereeKitColor': matchVideoColorToHex(refereeKitColor),
      'detections': detections.map((item) => item.toMap()).toList(),
    };
  }

  factory MatchVideo.fromMap(Map<String, dynamic> map) {
    final rawDetections = map['detections'];
    final team1 = _teamFromMap(map['team1']);
    final team2 = _teamFromMap(map['team2']);
    team1.kitColor ??= matchVideoColorFromHex(map['team1KitColor']?.toString());
    team2.kitColor ??= matchVideoColorFromHex(map['team2KitColor']?.toString());
    return MatchVideo(
      id: map['id']?.toString(),
      matchId: map['matchId']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      storagePath: map['storagePath']?.toString(),
      team1: team1,
      team2: team2,
      refereeKitColor: matchVideoColorFromHex(
        (map['refereeKitColor'] ?? map['officialKitColor'])?.toString(),
      ),
      detections: rawDetections is List
          ? rawDetections
              .whereType<Map>()
              .map(
                (item) => MatchVideoDetection.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <MatchVideoDetection>[],
    );
  }

  static MatchVideoTeam _teamFromMap(dynamic raw) {
    if (raw is Map) {
      return MatchVideoTeam.fromMap(Map<String, dynamic>.from(raw));
    }
    return MatchVideoTeam();
  }
}

MatchVideoObjectKind matchVideoObjectKindFromName(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'ball':
    case 'sports ball':
      return MatchVideoObjectKind.ball;
    default:
      return MatchVideoObjectKind.person;
  }
}

String? matchVideoColorToHex(int? argb) {
  if (argb == null) return null;
  final rgb = argb & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

int? matchVideoColorFromHex(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  return int.tryParse(value, radix: 16);
}

const List<int> kMatchVideoKitColorPresets = <int>[
  0xFFFFFFFF,
  0xFF111111,
  0xFF1E4DB7,
  0xFF0D47A1,
  0xFF4FC3F7,
  0xFFC62828,
  0xFFB71C1C,
  0xFFF9A825,
  0xFFD4FF00,
  0xFF2E7D32,
  0xFFF95C1B,
  0xFF6A1B9A,
  0xFF4E342E,
  0xFF9E9E9E,
];
