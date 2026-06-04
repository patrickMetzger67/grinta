import 'package:cloud_firestore/cloud_firestore.dart';

String keyTeamName = 'name';
String keyTeamCategory = 'category';
String keyTeamSubCategory = 'subCategory';
String keyTeamDesc = 'desc';
String keyTeamIsVisible = 'isVisible';
String keyTeamEffectives = 'effectives';
String keyTeamKey = 'keyTeam';
String keyTeamSeasonID = 'seasonID';
String keyTeamOrder = 'order';
String keyTeamIsCompetition = 'isCompetition';
String keyTeamChType = "chType";
String keyTeamCompetitions = "competitions";
String keyTeamSoccerType = "soccerType";
String keyTeamPhoto = 'photo';
String keyTeamUrlFb = 'urlFb';
String keyTeamUrlInsta = 'urlInsta';
String keyTeamUrlTwitter = 'urlTwitter';
String keyTeamClubId = 'clubId';
String keyTeamManagers = 'managers';
String keyTeamPlayers = 'players';
String keyTeamUsers = 'users';
String keyCompetitionName = "name";
String keyCompetitonChType = "chType";
String keyCompetitionUrlCalendar = "urlCalendar";
String keyCompetitionUrlRanking = "urlRanking";
String keyCompetitionCompetitionID = "competitionID";
String keyCompetitionPoule = "poule";
String keyCompetitionIsDefault = "isDefault";


class Competition {
  String? name;
  String? chType;
  String? urlCalendar;
  String? urlRanking;
  String? competitionID;
  String? poule;
  bool? isDefault;

  Competition(
      {this.name = '',
        this.chType = '',
        this.urlCalendar = '',
        this.urlRanking = '',
        this.competitionID = '',
        this.poule = '',
        this.isDefault = false,
      });

  Competition.fromMap(Map<String, dynamic>? map) {
    name = map![keyCompetitionName];
    chType = map[keyCompetitonChType];
    urlCalendar = map[keyCompetitionUrlCalendar];
    urlRanking = map[keyCompetitionUrlRanking];
    competitionID = map[keyCompetitionCompetitionID];
    poule = map[keyCompetitionPoule];
    isDefault = map[keyCompetitionIsDefault];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyCompetitionName:name,
      keyCompetitonChType:chType,
      keyCompetitionUrlCalendar:urlCalendar,
      keyCompetitionUrlRanking:urlRanking,
      keyCompetitionCompetitionID:competitionID,
      keyCompetitionPoule:poule,
      keyCompetitionIsDefault:isDefault,
    };
    return map;
  }

  @override
  String toString() {
    return 'competition: name=$name ' +
        'chType=$chType ' +
        'urlCalendar=$urlCalendar ' +
        'urlRanking=$urlRanking ' +
        'competitionID=$competitionID ' +
        'poule=$poule ' +
        'isDefault=$isDefault';
  }
}



class Team {
  String? keyTeam;
  String? name;
  String? category;
  String? subCategory;
  String? desc='';
  bool? isVisible = false;
  String? seasonID;
  int? order;
  String? chType;
  bool? isCompetition = false;
  int? soccerType;
  String? photo;
  String? urlFb;
  String? urlInsta;
  String? urlTwitter;
  String? clubId;
  List<dynamic>? managers=[];
  List<Competition>? competitions;

  List<dynamic>? players=[];
  List<dynamic>? users=[];
  bool? withTracker=false;
  List<dynamic> owners=[];

  DocumentReference? ref;

  Team(
      {this.keyTeam,
        this.name,
        this.category,
        this.subCategory,
        this.seasonID,
        this.order=1,
        this.chType,
        this.soccerType,
        this.photo,
        this.urlFb,
        this.urlInsta,
        this.urlTwitter,
        this.clubId,
        this.players,
        this.users,
        this.withTracker,
      });

  Team.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    ref = snapshot.reference;


    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;
    keyTeam = map![keyTeamKey];
    name = map[keyTeamName];
    category = map[keyTeamCategory];
    subCategory = map[keyTeamSubCategory];
    desc = map[keyTeamDesc];
    isVisible = map[keyTeamIsVisible];
    isCompetition = map[keyTeamIsCompetition];
    seasonID = map[keyTeamSeasonID];
    chType = map[keyTeamChType];
    order = map[keyTeamOrder];
    soccerType = map[keyTeamSoccerType];
    photo = map[keyTeamPhoto];
    List<dynamic> tmpObject = map[keyTeamCompetitions];
    competitions = [];
    for (int i = 0; i < tmpObject.length; i++) {
      Competition competition = Competition.fromMap(tmpObject[i] as Map<String, dynamic>?);
      competitions!.add(competition);
    }
    if(map[keyTeamUrlFb] != null) {
      urlFb = map[keyTeamUrlFb];
    } else {
      urlFb = '';
    }

    if(map[keyTeamUrlInsta] != null) {
      urlInsta = map[keyTeamUrlInsta];
    } else {
      urlInsta = '';
    }
    if(map[keyTeamUrlTwitter] != null) {
      urlTwitter = map[keyTeamUrlTwitter];
    } else {
      urlTwitter = '';
    }
    if(map[keyTeamClubId] != null) {
      clubId = map[keyTeamClubId];
    } else {
      clubId = '';
    }

    if(map[keyTeamManagers] != null) {
      managers = map[keyTeamManagers];
    } else {
      managers = [];
    }

    if(map[keyTeamPlayers] != null) {
      players = map[keyTeamPlayers];
    } else {
      players = [];
    }

    if(map[keyTeamUsers] != null) {
      users = map[keyTeamUsers];
    } else {
      users = map[keyTeamUsers];
    }
    withTracker= (map['withTracker'] ?? false) as bool;
    owners = List<dynamic>.from(
      (map['owners'] as List<dynamic>?) ?? const <dynamic>[],
    );

  }

  /// Parsed entries from [owners] (id + display name).
  List<TeamOwnerRef> get ownerRefs => TeamOwnerRef.parseList(owners);

  bool get hasTrackerOwners => ownerRefs.isNotEmpty;

  /// True when [owners] has at least one non-null Firestore entry (even if [ownerRefs] is empty).
  bool get hasRawOwners {
    for (final entry in owners) {
      if (entry == null) continue;
      if (entry is String && entry.trim().isNotEmpty) return true;
      if (entry is Map && entry.isNotEmpty) return true;
    }
    return false;
  }

  bool get hasAnyTrackerOwners => hasTrackerOwners || hasRawOwners;

  @override
  String toString() {
    return 'Team: name = >$name< ' +
        'chType = >$chType< ' +
        'keyTeam = >$keyTeam< ' +
        'category = $category ' +
        'subCategory = $subCategory ' +
        'desc = $desc ' +
        'isVisible = $isVisible ' +
        'isCompetition = $isCompetition ' +
        'seasonID = $seasonID ' +
        'order = $order ' +
        'soccerType =$soccerType ' +
        'competitions = ${competitions.toString()} ' +
        'photo = $photo ' +
        'urlFb = $urlFb ' +
        'urlInst = $urlInsta ' +
        'urlTwitter = $urlTwitter ' +
        'clubId=$clubId ' +
        'players=$players ' +
        'users=$users ' +
        'managers=${managers.toString()} ' +
        'withTracker=$withTracker  ' +
        'owners=${owners.toString()}';
  }

  Map<String, dynamic> toMap() {

    List<dynamic> allCompetitions=[];
    if(competitions != null) {
      for (var competition in competitions!) {
        allCompetitions.add(competition.toMap());
      }
    }


    Map<String, dynamic> map = {
      keyTeamKey: keyTeam,
      keyTeamName:name,
      keyTeamChType:chType,
      keyTeamCategory:category,
      keyTeamSubCategory: subCategory,
      keyTeamDesc:desc,
      keyTeamIsVisible:isVisible,
      keyTeamIsCompetition:isCompetition,
      keyTeamSeasonID:seasonID,
      keyTeamOrder:order,
      keyTeamSoccerType:soccerType,
      keyTeamPhoto:photo,
      keyTeamUrlFb:urlFb,
      keyTeamUrlInsta:urlInsta,
      keyTeamUrlTwitter:urlTwitter,
      keyTeamCompetitions:allCompetitions,
      keyTeamClubId:clubId,
      keyTeamManagers:managers,
      keyTeamPlayers:players,
      keyTeamUsers:users,
      'withTracker':withTracker,
      'owners':owners,
    };
    return map;
  }

  void setKeyTeam() {

    keyTeam = keyTeam!.replaceAll(' ', '').toUpperCase();
    keyTeam = removeDiacritics(keyTeam!);
  }
}

enum ResultType {
  win,
  lost,
  draw
}

class  TeamStatsOnFly {

  int played;
  int win;
  double averageWin;
  int draw;
  double averageDraw;
  int lost;
  double averageLost;
  int goalScored;
  double averageGoalScored;
  int goalConceded;
  double averageGoalConceded;
  int cleanSheet;
  List<dynamic> resultType=[];

  TeamStatsOnFly({this.played=0,
    this.win=0,
    this.averageWin=0.0,
    this.draw=0,
    this.averageDraw = 0.0,
    this.lost=0,
    this.averageLost = 0.0,
    this.goalScored=0,
    this.averageGoalScored=0.0,
    this.goalConceded=0,
    this.averageGoalConceded=0.0,
    this.cleanSheet=0});

  @override
  String toString() {
    return 'teamStatsOnFly played=$played ' +
        'win=$win ' +
        'averageWin=$averageWin' +
        'draw=$draw ' +
        'averageDraw=$averageDraw ' +
        'lost=$lost ' +
        'averageLost=$averageLost ' +
        'goalScored=$goalScored ' +
        'averageGoalScored=$averageGoalScored ' +
        'goalConceded=$goalConceded ' +
        'averageGoalConceded=$averageGoalConceded ' +
        'cleanSheet=$cleanSheet ' +
        'resultType=${resultType.toString()}';
  }

}
/// Owner reference stored on [Team.owners] (id string or map with id/name).
class TeamOwnerRef {
  final String id;
  final String name;

  const TeamOwnerRef({required this.id, required this.name});

  /// Label for UI (name when set, otherwise [id]).
  String get displayLabel {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return id;
  }

  /// True when [name] is missing or only mirrors [id] (e.g. string Firestore entry).
  bool get needsNameLookup {
    final trimmed = name.trim();
    return trimmed.isEmpty || trimmed == id;
  }

  TeamOwnerRef withName(String resolvedName) {
    final trimmed = resolvedName.trim();
    if (trimmed.isEmpty) return this;
    return TeamOwnerRef(id: id, name: trimmed);
  }

  static List<TeamOwnerRef> parseList(List<dynamic> raw) {
    final result = <TeamOwnerRef>[];
    for (final entry in raw) {
      final parsed = parseOne(entry);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  static TeamOwnerRef? parseOne(dynamic entry) {
    if (entry == null) return null;
    if (entry is String) {
      final id = entry.trim();
      if (id.isEmpty) return null;
      return TeamOwnerRef(id: id, name: id);
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      final id = (map['id'] ?? map['ownerId'] ?? map['ownerID'] ?? '')
          .toString()
          .trim();
      if (id.isEmpty) return null;
      final name = (map['name'] ??
              map['displayName'] ??
              map['label'] ??
              '')
          .toString()
          .trim();
      return TeamOwnerRef(id: id, name: name.isEmpty ? id : name);
    }
    return null;
  }
}

String removeDiacritics(String str) {
  var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}