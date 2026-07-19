import 'package:cloud_firestore/cloud_firestore.dart';


class TrainingGroup {
  final String id;
  final String groupName;
  final List<String> players;

  TrainingGroup({
    required this.id,
    required this.groupName,
    List<String>? players,
  }) : players = players ?? [];

  /// Convertit l'objet en Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id':id,
      'groupName': groupName,
      'players': players,
    };
  }

  /// Construit l'objet depuis une Map (Firestore)
  factory TrainingGroup.fromMap(String id, Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('TrainingGroup map is null');
    }

    return TrainingGroup(
      id: id,
      groupName: (map['groupName'] is String)
          ? map['groupName'] as String
          : '',
      players: (map['players'] is List)
          ? List<String>.from(
        (map['players'] as List)
            .where((e) => e is String),
      )
          : [],
    );
  }

  /// Copie sécurisée (utile pour update immuable)
  TrainingGroup copyWith({
    String? id,
    String? groupName,
    List<String>? players,
  }) {
    return TrainingGroup(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      players: players ?? List<String>.from(this.players),
    );
  }
}

class TrainingWorkshop {
  String id;
  String name;
  String description;

  TrainingWorkshop({
    String? id,
    String? name,
    String? description,
  })  : id= id ?? '',
        name = name ?? '',
        description = description ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory TrainingWorkshop.fromMap(Map<String, dynamic> map) {
    return TrainingWorkshop(
      id:map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

class TrainingWorkshopCompleted {
  final String trainingWorkshopId;
  final String trainingGroupId;
  bool allPlayer = false;
  final Timestamp? startAt;
  final Timestamp? endAt;

  TrainingWorkshopCompleted({
    required this.trainingWorkshopId,
    required this.trainingGroupId,
    this.startAt,
    this.endAt,
    required this.allPlayer,
  });

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'trainingWorkshopId': trainingWorkshopId,
      'trainingGroupId': trainingGroupId,
      'startAt': startAt,
      'endAt': endAt,
      'allPlayer': allPlayer,
    };
  }

  /// Construction sécurisée depuis Firestore
  factory TrainingWorkshopCompleted.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('TrainingWorkshopCompleted map is null');
    }

    return TrainingWorkshopCompleted(
      trainingWorkshopId:
      (map['trainingWorkshopId'] is String)
          ? map['trainingWorkshopId'] as String
          : '',
      trainingGroupId:
      (map['trainingGroupId'] is String)
          ? map['trainingGroupId'] as String
          : '',
      startAt:
      (map['startAt'] is Timestamp)
          ? map['startAt'] as Timestamp
          : null,
      endAt:
      (map['endAt'] is Timestamp)
          ? map['endAt'] as Timestamp
          : null,
      allPlayer:
      (map['allPlayer'] is bool)
          ? map['allPlayer'] as bool
          : false,
    );
  }

  /// Copie sécurisée
  TrainingWorkshopCompleted copyWith({
    String? trainingWorkshopId,
    String? trainingGroupId,
    Timestamp? startAt,
    Timestamp? endAt,
    bool? allPlayer,
  }) {
    return TrainingWorkshopCompleted(
      trainingWorkshopId: trainingWorkshopId ?? this.trainingWorkshopId,
      trainingGroupId: trainingGroupId ?? this.trainingGroupId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allPlayer: allPlayer ?? this.allPlayer,
    );
  }
}

String keyPtPlayerId = 'playerId';
String keyPtPresenceType = 'presenceType';
String keyPtRpeBefore = 'rpeBefore';
String keyPtMessageBefore = 'messageBefore';
String keyPtRpeAfter = 'rpeAfter';
String keyPtMessageAfter = 'messageAfter';
String keyPtFeelingBefore = 'feelingBefore';
String keyPtFeelingAfter = 'feelingAfter';
String keyPtVolume = 'volume';
String keyPtIntensity = 'intensity';
String keyPtMentalLoad = 'mentalLoad';
String keyPtPleasure = 'pleasure';
String keyPltDeviceId = 'deviceId';
String keyPltCustomName = 'customName';

enum PresenceType { present, blesse, excuse, absent, late }

/// Échelle "Comment te sens-tu ?" — 1 (très mal) → 5 (très bien).
enum PlayerFeeling {
  veryBad(1),
  bad(2),
  neutral(3),
  good(4),
  veryGood(5);

  const PlayerFeeling(this.value);
  final int value;

  static PlayerFeeling? fromValue(int? value) {
    if (value == null) return null;
    for (final feeling in PlayerFeeling.values) {
      if (feeling.value == value) return feeling;
    }
    return null;
  }
}

class PlayerTraining {
  String? playerId;
  PresenceType? presenceType;
  int? rpeBefore;
  String? messageBefore;
  int? rpeAfter;
  String? messageAfter;

  /// Feeling scale 1–5 ("Comment te sens-tu ?"), before session.
  int? feelingBefore;

  /// Feeling scale 1–5 ("Comment te sens-tu ?"), after session.
  int? feelingAfter;

  // VICP
  int? volume;
  int? intensity;
  int? mentalLoad;
  int? pleasure;

  String? deviceId;
  String? customName;

  PlayerTraining({this.playerId, this.presenceType});

  PlayerFeeling? get feelingBeforeEnum => PlayerFeeling.fromValue(feelingBefore);
  PlayerFeeling? get feelingAfterEnum => PlayerFeeling.fromValue(feelingAfter);

  PlayerTraining.fromMap(Map<String, dynamic> map) {
    switch (map[keyPtPresenceType]) {
      case 'PresenceType.present':
        presenceType = PresenceType.present;
        break;
      case 'PresenceType.blesse':
        presenceType = PresenceType.blesse;
        break;
      case 'PresenceType.excuse':
        presenceType = PresenceType.excuse;
        break;
      case 'PresenceType.absent':
        presenceType = PresenceType.absent;
        break;
      case 'PresenceType.late':
        presenceType = PresenceType.late;
        break;
    }

    playerId = map[keyPtPlayerId];

    if(map[keyPtRpeBefore] != null) {
      rpeBefore = map[keyPtRpeBefore];
    } else {
      rpeBefore = 0;
    }
    if(map[keyPtMessageBefore] != null) {
      messageBefore = map[keyPtMessageBefore];
    } else {
      messageBefore = '';
    }

    if(map[keyPtRpeAfter] != null) {
      rpeAfter = map[keyPtRpeAfter];
    } else {
      rpeAfter = 0;
    }
    if(map[keyPtMessageAfter] != null) {
      messageAfter = map[keyPtMessageAfter];
    } else {
      messageAfter = '';
    }

    if(map[keyPtFeelingBefore] != null) {
      feelingBefore = map[keyPtFeelingBefore];
    } else {
      feelingBefore = 0;
    }
    if(map[keyPtFeelingAfter] != null) {
      feelingAfter = map[keyPtFeelingAfter];
    } else {
      feelingAfter = 0;
    }

    if(map[keyPtVolume] != null) {
      volume = map[keyPtVolume];
    } else {
      volume = 0;
    }

    if(map[keyPtIntensity] != null) {
      intensity = map[keyPtIntensity];
    } else {
      intensity = 0;
    }

    if(map[keyPtMentalLoad] != null) {
      mentalLoad = map[keyPtMentalLoad];
    } else {
      mentalLoad = 0;
    }
    if(map[keyPtPleasure] != null) {
      pleasure = map[keyPtPleasure];
    } else {
      pleasure = 0;
    }
    deviceId = map[keyPltDeviceId] ?? '';
    customName = map[keyPltCustomName] ?? '';

  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyPtPlayerId: playerId,
      keyPtPresenceType: presenceType.toString(),
      keyPtRpeBefore: rpeBefore,
      keyPtRpeAfter: rpeAfter,
      keyPtMessageBefore: messageBefore,
      keyPtMessageAfter: messageAfter,
      keyPtFeelingBefore: feelingBefore,
      keyPtFeelingAfter: feelingAfter,
      keyPtVolume:volume,
      keyPtIntensity:intensity,
      keyPtMentalLoad:mentalLoad,
      keyPtPleasure:pleasure,
      keyPltDeviceId:deviceId,
      keyPltCustomName:customName,
    };
    return map;
  }



  @override
  String toString() {
    return 'PlayerTraining: playerId=$playerId ' +
        'presenceType=${presenceType.toString()} ' +
        'rpeBefore:${rpeBefore.toString()} ' +
        'messageBefore=$messageBefore ' +
        'rpeAfter:${rpeAfter.toString()} ' +
        'messageAfter=$messageAfter ' +
        'feelingBefore:${feelingBefore.toString()} ' +
        'feelingAfter:${feelingAfter.toString()} ' +
        'volume=$volume ' +
        'intensity=$intensity ' +
        'mentalLoad=$mentalLoad ' +
        'pleasure=$pleasure ' +
        'deviceId=$deviceId ' +
        'customName=$customName';
  }
  double note() {
    if(volume != null && intensity != null && mentalLoad != null && pleasure != null) {
      return ((volume!+intensity!+mentalLoad!+pleasure!)/4);
    } else {
      return 0.0;
    }
  }
}

String keyTgTrainingId = 'trainingId';
String keyTgSeasonId = 'seasonId';
String keyTgDateTime = 'dateTime';
String keyTgDate = 'dateTg';
String keyTgTeamId = 'teamId';
String keyTgFieldId = 'fieldId';
String keyTgDuration = 'duration';
String keyTgPlayerTraining = 'playerTraining';
String keyTgIsFinish = 'isFinish';
String keyTgWithRPE = 'withRPE';
String keyTgWithVICP = 'withVICP';
String keyTgIsNotifBeforeSended = 'isNotifBeforeSended';
String keyTgDateTimeNotifBeforeSended = 'dateTimeNotifBeforeSended';
String keyTgIsNotifAfterSended = 'isNotifAfterSended';
String keyTgDateTimeNotifAfterSended = 'dateTimeNotifAfterSended';
String keyTgSessionType = 'sessionType';
String keyTgGameState = 'gameState';
String keyTgFieldPosition = 'fieldPosition';
String keyTgGamePhases = 'gamePhases';
String keyTgMentalDominant = 'mentalDominant';
String keyTgAthleticDominant = 'athleticDominant';
String keyTgAssociatedTechnicalMeans = 'associatedTechnicalMeans';
String keyTgGamePrinciple = 'gamePrinciple';
String keyTgVersion = 'version';
String keyTgTacticalPrinciple = 'tacticalPrinciple';
String keyTgClubId = 'clubId';
String keyTgIsReccurent = 'isReccurent';
String keyTgReccurentCode = 'reccurentCode';
String keyTgReccurentDay = 'reccurentDay';
String keyTgRecurrentStart = 'reccurentStart';
String keyTgRecurrentEnd = 'reccurentEnd';
String keyTgStartTime = 'startTime';
String keyTgStartEnd = 'startEnd';
String keyTgWithTracker = 'withTracker';
String keyTgIsTrackerDataUploaded = 'isTrackerDataUploaded';

String keyTgStartAt = 'trainingStartAt';
String keyTgEndAt = 'trainingEndAt';
String keyTgOwnerId = 'ownerId';



String _asString(dynamic v, {String fallback = ''}) => v is String ? v : fallback;
bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final normalized = v.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

Timestamp? _asTimestamp(dynamic v) => v is Timestamp ? v : null;
List<dynamic> _asList(dynamic v) => v is List ? v : <dynamic>[];

class Training {
  String? docId;
  String? trainingId;
  String? seasonId;
  String? clubId;
    Timestamp? dateTime;
  String? dateTg;
  String? teamId;
  String? fieldId;
  int? duration;

  List<PlayerTraining> playerTraining;

  bool? isFinish;
  bool? withRPE;
  bool? withVICP;
  bool? isNotifBeforeSended;
  Timestamp? dateTimeNotifBeforeSended;
  bool? isNotifAfterSended;
  Timestamp? dateTimeNotifAfterSended;

  String? sessionType;
  String? gameState;
  String? fieldPosition;
  String? gamePhases;
  List<dynamic>? gamePrinciple;
  List<dynamic>? associatedTechnicalMeans;
  List<dynamic>? athleticDominant;
  List<dynamic>? mentalDominant;
  String? version;
  List<dynamic>? tacticalPrinciple = [];

  bool? isReccurent;
  String? reccurentCode;
  List<dynamic>? reccurentDay = [];
  Timestamp? reccurentStart;
  Timestamp? reccurentEnd;
  String? startTime;
  String? endTime;

  bool withTracker = false;
  bool isTrackerDataUploaded = false;
  Timestamp? trainingStartAt;
  Timestamp? trainingEndAt;
  String? ownerId;

  List<TrainingGroup> trainingGroup;
  List<TrainingWorkshop> trainingWorkshop;
  List<TrainingWorkshopCompleted> trainingWorkshopCompleted;

  DocumentReference? ref;

  Training({
    this.docId,
    this.trainingId,
    this.seasonId,
    this.clubId,
    this.dateTime,
    this.dateTg,
    this.teamId,
    this.fieldId,
    this.duration,
    List<dynamic>? playerTraining,
    this.isFinish,
    this.withRPE,
    this.withVICP,
    this.isNotifBeforeSended,
    this.dateTimeNotifBeforeSended,
    this.isNotifAfterSended,
    this.dateTimeNotifAfterSended,
    this.sessionType,
    this.gameState,
    this.fieldPosition,
    this.gamePhases,
    this.mentalDominant,
    this.associatedTechnicalMeans,
    this.athleticDominant,
    this.gamePrinciple,
    this.tacticalPrinciple,
    this.version = '2',
    this.isReccurent = false,
    this.reccurentCode = '',
    this.reccurentDay,
    this.reccurentStart,
    this.reccurentEnd,
    this.startTime,
    this.endTime,
    this.ref,
    this.withTracker=false,
    this.isTrackerDataUploaded=false,
    this.trainingStartAt,
    this.trainingEndAt,
    this.ownerId,
    List<TrainingGroup>? trainingGroup,
    List<TrainingWorkshop>? trainingWorkshop,
    List<TrainingWorkshopCompleted>? trainingWorkshopCompleted,
  })  : playerTraining = (playerTraining ?? [])
      .map((e) {
        if (e is PlayerTraining) return e;
        if (e is Map<String, dynamic>) return PlayerTraining.fromMap(e);
        if (e is Map) return PlayerTraining.fromMap(Map<String, dynamic>.from(e));
        throw StateError('Invalid PlayerTraining element: ${e.runtimeType}');
        }).toList(),
        trainingGroup = trainingGroup ?? <TrainingGroup>[],
        trainingWorkshop = trainingWorkshop ?? <TrainingWorkshop>[],
        trainingWorkshopCompleted =
            trainingWorkshopCompleted ?? <TrainingWorkshopCompleted>[];

  /// VERSION SECURE (factory)
  factory Training.fromMap(
      Map<String, dynamic>? map, {
        String? docId,
        DocumentReference? ref,
      }) {
    if (map == null) {
      throw ArgumentError('Training map is null');
    }

    final raw = map[keyTgPlayerTraining];

    final parsedPlayerTraining = (raw is List)
        ? raw
        .where((e) => e != null)
        .map((e) {
      if (e is Map<String, dynamic>) return PlayerTraining.fromMap(e);
      if (e is Map) return PlayerTraining.fromMap(Map<String, dynamic>.from(e));
      // si jamais tu avais stocké des objets déjà typés (rare)
      if (e is PlayerTraining) return e;
      throw StateError('Invalid PlayerTraining element: ${e.runtimeType}');
    })
        .toList()
        : <PlayerTraining>[];

    // TrainingGroup
    final groupsRaw = _asList(map['trainingGroup']);
    final parsedGroups = <TrainingGroup>[];
    for (final e in groupsRaw) {
      try {
        if (e is Map<String, dynamic>) {
          parsedGroups.add(
            TrainingGroup.fromMap(_asString(e['id'], fallback: ''), e),
          );
        } else if (e is Map) {
          final m = Map<String, dynamic>.from(e as Map);
          parsedGroups.add(TrainingGroup.fromMap(_asString(m['id']), m));
        }
      } catch (_) {}
    }

    // TrainingWorkshop
    final workshopsRaw = _asList(map['trainingWorkshop']);
    final parsedWorkshops = <TrainingWorkshop>[];
    for (final e in workshopsRaw) {
      try {
        if (e is Map<String, dynamic>) {
          parsedWorkshops.add(TrainingWorkshop.fromMap(e));
        } else if (e is Map) {
          parsedWorkshops.add(
            TrainingWorkshop.fromMap(Map<String, dynamic>.from(e as Map)),
          );
        }
      } catch (_) {}
    }

    // TrainingWorkshopCompleted
    final completedRaw = _asList(map['trainingWorkshopCompleted']);
    final parsedCompleted = <TrainingWorkshopCompleted>[];
    for (final e in completedRaw) {
      try {
        if (e is Map<String, dynamic>) {
          parsedCompleted.add(TrainingWorkshopCompleted.fromMap(e));
        } else if (e is Map) {
          parsedCompleted.add(
            TrainingWorkshopCompleted.fromMap(Map<String, dynamic>.from(e as Map)),
          );
        }
      } catch (_) {}
    }

    return Training(
      docId:docId,
      trainingId: _asString(map[keyTgTrainingId],
          fallback: _asString(docId, fallback: '')),
      seasonId: _asString(map[keyTgSeasonId]),
      clubId: _asString(map[keyTgClubId]),
      dateTime: _asTimestamp(map[keyTgDateTime]),
      dateTg: _asString(map[keyTgDate], fallback: ''),
      teamId: _asString(map[keyTgTeamId]),
      fieldId: _asString(map[keyTgFieldId]),
      duration: _asInt(map[keyTgDuration], fallback: 0),
      playerTraining: parsedPlayerTraining,
      isFinish: _asBool(map[keyTgIsFinish]),
      withRPE: _asBool(map[keyTgWithRPE]),
      withVICP: _asBool(map[keyTgWithVICP]),
      isNotifBeforeSended: _asBool(map[keyTgIsNotifBeforeSended]),
      dateTimeNotifBeforeSended:
      _asTimestamp(map[keyTgDateTimeNotifBeforeSended]),
      isNotifAfterSended: _asBool(map[keyTgIsNotifAfterSended]),
      dateTimeNotifAfterSended: _asTimestamp(map[keyTgDateTimeNotifAfterSended]),
      sessionType: _asString(map[keyTgSessionType]),
      gameState: _asString(map[keyTgGameState]),
      fieldPosition: _asString(map[keyTgFieldPosition]),
      gamePhases: _asString(map[keyTgGamePhases]),
      mentalDominant: _asList(map[keyTgMentalDominant]),
      athleticDominant: _asList(map[keyTgAthleticDominant]),
      associatedTechnicalMeans: _asList(map[keyTgAssociatedTechnicalMeans]),
      gamePrinciple: _asList(map[keyTgGamePrinciple]),
      tacticalPrinciple: _asList(map[keyTgTacticalPrinciple]),
      version: _asString(map[keyTgVersion], fallback: '1'),
      isReccurent: _asBool(map[keyTgIsReccurent]),
      reccurentCode: _asString(map[keyTgReccurentCode]),
      reccurentDay: _asList(map[keyTgReccurentDay]),
      reccurentStart: _asTimestamp(map[keyTgRecurrentStart]),
      reccurentEnd: _asTimestamp(map[keyTgRecurrentEnd]),
      startTime: _asString(map[keyTgStartTime]),
      endTime: _asString(map[keyTgStartEnd]),
      withTracker: _asBool(map[keyTgWithTracker]),
      isTrackerDataUploaded: _asBool(map[keyTgIsTrackerDataUploaded]),
      trainingStartAt: _asTimestamp(map[keyTgStartAt]),
      trainingEndAt: _asTimestamp(map[keyTgEndAt]),
      ownerId: _asString(map[keyTgOwnerId]),
      trainingGroup: parsedGroups,
      trainingWorkshop: parsedWorkshops,
      trainingWorkshopCompleted: parsedCompleted,
      ref: ref,
    );
  }

  /// toMap SECURE (Firestore)
  Map<String, dynamic> toMap() {
    return {
      keyTgTrainingId: trainingId,
      keyTgSeasonId: seasonId,
      keyTgClubId: clubId,
      keyTgDateTime: dateTime,
      keyTgDate: dateTg,
      keyTgTeamId: teamId,
      keyTgFieldId: fieldId,
      keyTgDuration: duration,

      /// ✅ plus d'erreur de null ici
      keyTgPlayerTraining: playerTraining.map((e) => e.toMap()).toList(),

      keyTgIsFinish: isFinish ?? false,
      keyTgWithRPE: withRPE ?? false,
      keyTgWithVICP: withVICP ?? false,
      keyTgIsNotifBeforeSended: isNotifBeforeSended ?? false,
      keyTgDateTimeNotifBeforeSended: dateTimeNotifBeforeSended,
      keyTgIsNotifAfterSended: isNotifAfterSended ?? false,
      keyTgDateTimeNotifAfterSended: dateTimeNotifAfterSended,
      keyTgSessionType: sessionType ?? '',
      keyTgGameState: gameState ?? '',
      keyTgFieldPosition: fieldPosition ?? '',
      keyTgGamePhases: gamePhases ?? '',
      keyTgMentalDominant: mentalDominant ?? [],
      keyTgAthleticDominant: athleticDominant ?? [],
      keyTgAssociatedTechnicalMeans: associatedTechnicalMeans ?? [],
      keyTgGamePrinciple: gamePrinciple ?? [],
      keyTgTacticalPrinciple: tacticalPrinciple ?? [],
      keyTgVersion: version ?? '2',
      keyTgIsReccurent: isReccurent ?? false,
      keyTgReccurentCode: reccurentCode ?? '',
      keyTgReccurentDay: reccurentDay ?? [],
      keyTgRecurrentStart: reccurentStart,
      keyTgRecurrentEnd: reccurentEnd,
      keyTgStartTime: startTime ?? '',
      keyTgStartEnd: endTime ?? '',
      keyTgWithTracker: withTracker ?? false,
      keyTgIsTrackerDataUploaded:isTrackerDataUploaded ?? false,
      keyTgStartAt: trainingStartAt,
      keyTgEndAt: trainingEndAt,
      keyTgOwnerId: ownerId ?? '',

      'trainingGroup': trainingGroup.map((e) => e.toMap()).toList(),
      'trainingWorkshop': trainingWorkshop.map((e) => e.toMap()).toList(),
      'trainingWorkshopCompleted':
      trainingWorkshopCompleted.map((e) => e.toMap()).toList(),
    };
  }

  factory Training.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data();
    if (data == null || data is! Map<String, dynamic>) {
      throw ArgumentError('DocumentSnapshot data is null or invalid');
    }

    return Training.fromMap(
      data,
      docId: documentSnapshot.id,
      ref: documentSnapshot.reference,
    );
  }

  @override
  String toString() {
    return 'Training: trainingId:$trainingId '
        'seasonId:$seasonId '
    /*
        'clubId:$clubId '
        'dateTime:${dateTime.toString()} '
        'dateTg:$dateTg '
        'teamId:$teamId '
        'fieldId:$fieldId '
        'duration:${duration.toString()} '
        'playerTraining:${playerTraining.toString()} '
        'isFinish:$isFinish '
        'withRPE:${withRPE.toString()} '
        'withVICP:${withVICP.toString()} '
        'isNotifBeforeSended:${isNotifBeforeSended.toString()}'
        'dateTimeBeforeSended:${dateTimeNotifBeforeSended.toString()} '
        'isNotifAfterSended:${isNotifAfterSended.toString()} '
        'dateTimeAfterSended:${dateTimeNotifAfterSended.toString()} '
        'sessionType:$sessionType '
        'gameState:$gameState '
        'fieldPosition:$fieldPosition '
        'gamePhases:$gamePhases '
        'gamePrinciple:$gamePrinciple '
        'version=$version '
        'tacticalPrinciple=$tacticalPrinciple '
        'recurrentCode=$reccurentCode '
        'reccurentDay=${reccurentDay.toString()} '
        'reccurentStart=${reccurentStart.toString()} '
        'reccurentEnd=${reccurentEnd.toString()} '
        'startTime=$startTime '
        'endTime=$endTime '

     */
        'withTracker=$withTracker ';
  }
}