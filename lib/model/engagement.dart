import 'package:cloud_firestore/cloud_firestore.dart';

String keyEngagementClubId = 'clubId';
String keyEngagementSeasonId = 'seasonId';
String keyEngagementCompetitionId = 'competitionId';
String keyEngagementGroup = 'group';
String keyEngagementStage = 'stage';
String keyEngagementName = 'name';
String keyEngagementTeamId = 'teamId';
String keyEngagementTeamIds = 'teamIds';
String keyEngagementIsDefault = 'isDefault';

class Engagement {

   String? clubId;
   String? seasonId;
   String? competitionId;
   String? group;
   String? stage;
   String? name;
   String? teamId;
   List<String> teamIds = <String>[];
   bool? isDefault;
   DocumentReference? ref;

  Engagement(
      {
        this.clubId='',
        this.seasonId = '',
        this.competitionId='',
        this.group='',
        this.name='',
        this.stage='',
        this.teamId='',
        List<String>? teamIds,
        this.isDefault,
      }) : teamIds = teamIds ?? <String>[];

  Engagement.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    ref = documentSnapshot.reference;
    teamIds = <String>[];

    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;

    if(map![keyEngagementClubId] != null) {
      clubId = map[keyEngagementClubId];
    } else {
      clubId = '';
    }
    if(map[keyEngagementSeasonId] != null) {
      seasonId = map[keyEngagementSeasonId];
    } else {
      seasonId = '';
    }
    if(map[keyEngagementCompetitionId] != null) {
      competitionId = map[keyEngagementCompetitionId];
    } else {
      competitionId = '';
    }
    if(map[keyEngagementGroup] != null) {
      group = map[keyEngagementGroup];
    } else {
      group = '';
    }
    if(map[keyEngagementStage] != null) {
      stage = map[keyEngagementStage];
    } else {
      stage = '';
    }
    if(map[keyEngagementName] != null) {
      name = map[keyEngagementName];
    } else {
      name = '';
    }
    if(map[keyEngagementTeamId] != null) {
      teamId = map[keyEngagementTeamId];
    } else {
      teamId = '';
    }

    teamIds = _parseTeamIds(map[keyEngagementTeamIds]);

    if(map[keyEngagementIsDefault] != null) {
      isDefault = map[keyEngagementIsDefault];
    } else {
      isDefault = false;
    }

  }
  Map<String, dynamic> toMap() {

    Map<String, dynamic> map = {
      keyEngagementClubId:clubId,
      keyEngagementSeasonId:seasonId,
      keyEngagementCompetitionId:competitionId,
      keyEngagementGroup:group,
      keyEngagementName:name,
      keyEngagementStage:stage,
      keyEngagementTeamIds:teamIds,
      keyEngagementIsDefault:isDefault,
    };
    return map;
  }
  @override
  String toString() {
    return 'Engagement -> clubId:$clubId '+
        'seasonId:$seasonId ' +
        'competitionId:$competitionId ' +
        'group:$group ' +
        'name:$name ' +
        'stage:$stage ' +
        'teamId=$teamId ' +
        'teamIds=$teamIds ' +
        'isDefault:$isDefault';
  }
}

List<String> _parseTeamIds(dynamic value) {
  if (value is! List) return <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}