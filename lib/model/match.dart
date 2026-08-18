
import 'fieldGpsCorners.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



String keyMatchId = 'id';
String keyMatchChType = 'chType';
String keyMatchDateCh = 'dateCh';
String keyMatchTimeCh = 'timeCh';
String keyMatchDay = 'day';
String keyMatchSeasonID = 'seasonID';
String keyMatchSurfaceDeJeu = 'surfaceDeJeu';
String keyMatchTeam1 = 'team1';
String keyMatchAffiliationTeam1 = 'affiliationTeam1';
String keyMatchTeam1UrlLogo = 'team1UrlLogo';
String keyMatchTeam2 = 'team2';
String keyMatchAffiliationTeam2 = 'affiliationTeam2';
String keyMatchTeam2UrlLogo = 'team2UrlLogo';
String keyMatchTerrainAdresse1 = 'terrainAdresse1';
String keyMatchTerrainAdresse2 = 'terrainAdresse2';
String keyMatchNomDuTerrain = "terrainNom";
String keyMatchIsReport = 'isReport';
String keyMatchIsOwnClub = 'isOwnClub';
String keyMatchIsMatchPlayed = 'isMatchPlayed';
String keyMatchIsMatchVisible='isMatchVisible';
String keyMatchHomeScore = 'homeScore';
String keyMatchOutsideScore = 'outsideScore';
String keyMatchTab = 'tab';
String keyMatchTour = "tour";
String keyMatchIsTeam1Forfeit = "isTeam1Forfeit";
String keyMatchIsTeam2Forfeit = "isTeam2Forfeit";
String keyMatchCentralReferee = "centralReferee";
String keyMatchAssistantReferee1 = "assistantReferee1";
String keyMatchAssistantReferee2 = "assistantReferee2";
String keyMatchPrincipalObserver = "principalObserver";
String keyMatchAssistantObserver = "assistantObserver";
String keyMatchAccompanyingDelegate = "accompanyingDelegate";
String keyMatchUrl = "url";
String keyMatchCompetitionID = "competitionID";
String keyMatchPoule = "poule";
String keyMatchTeamID = "teamID";
String keyMatchSoccerType ="soccerType";
String keyMatchIsStatApplied ="isStatApplied";
String keyMatchDateTimeConvo = 'dateTimeConvo';
String keyMatchMessageConvo = 'messageConvo';
String keyMatchAddressConvo = 'addressConvo';
String keyMatchLiveFollowers = 'liveFollowers';
String keyMatchFieldId = 'fieldId'; // only if home match
String keyMatchIsAdded = 'isAdded';
String keyMatchHighLightsManagerUid = 'highLightsManagerUid';
String keyMatchMvpManaged = 'mvpManaged';
String keyMatchIsMvpStarted = 'isMvpStarted';
String keyMatchDescription = 'description';
String keyMatchClubs = 'clubs';
String keyMatchStage = 'stage';
String keyMatchTeams = 'teams';
String keyMatchUrlMatchDetails = 'urlMatchDetails';
String keyMatchWhereMatchIsPlayed = 'whereIsPlayed'; // clubId where the match is played
String keyMatchIsInHighLight = 'isInHighLight';
String keyMatchWithTracker = 'withTracker';
String keyMatchIsTrackerDataUploaded = 'isTrackerDataUploaded';
String keyMatchTimestamp = 'timestamp';
String keyMatchDuration = 'duration';
String keyMatchIsScrapping = 'isScrapping';

class Match {


  String?  id;         // id de la rencontre
  String? chType;      // type de championnat
  String? dateCh;   // date et heure de la rencontre
  String? timeCh;
  int? day;          // journée de championnat
  String? tour;      // Si coupe

  String? seasonID;    // id de la saison
  String? surfaceDeJeu;  // type de pelouse
  String? team1;         // Equipe 1
  String? affiliationTeam1='';
  bool? isTeam1Forfeit;  // Equipe 1 forfait ?
  String? team1UrlLogo; // Logo de l'équipe 1
  String? team2;       // Equipe 2
  String? affiliationTeam2='';
  bool? isTeam2Forfeit;  // Equipe 1 forfait ?
  String? team2UrlLogo; // logo de l'équipe 2
  String? terrainAdresse1;
  String? terrainAddress2;
  String? nomDuTerrain;
  bool?  isReport;
  bool? isOwnClub;
  bool? isMatchPlayed;
  bool? isMatchVisible;
  int? homeScore;
  int? outSideScore;
  String? tab;     // Tirs au but
  String? centralReferee;
  String? assistantReferee1;
  String? assistantReferee2;
  String? principalObserver;
  String? assistantObserver;
  String? accompanyingDelegate;
  String? url;     // Url match details
  String? competitionID;
  String? poule;
  String? teamID;
  int? soccerType;
  bool? isStatApplied;

  Timestamp? dateTimeConvo;
  String? messageConvo;
  String? addressConvo;

  List<dynamic> liveFollowers=[];
  String? fieldId;   // only if home match
  bool? isAdded;  // match added manually
  String? highLightsManagerUid;
  bool? mvpManaged;
  bool? isMvpStarted;

  String? description;
  List<dynamic>? clubs=[];
  String? stage;
  List<dynamic>? teams=[];

  String? urlMatchDetails;
  String? whereIsPlayed;

  bool? isInHighLight;
  bool? withTracker;

  FieldGpsCorners? fieldGpsCorners;
  String? ownerId;
  bool? isTrackerDataUploaded;
  Timestamp? timestamp;
  int? duration;
  bool? isScrapping;

  /// URL de la vidéo d'analyse. Non persistée dans Firestore.
  String? videoUrl;

  DocumentReference? ref;

  Match({
    this.id,
    this.chType,
    this.dateCh,
    this.timeCh,
    this.day,
    this.seasonID,
    this.surfaceDeJeu,
    this.team1,
    this.affiliationTeam1,
    this.team1UrlLogo,
    this.team2,
    this.affiliationTeam2,
    this.team2UrlLogo,
    this.terrainAdresse1,
    this.terrainAddress2,
    this.nomDuTerrain,
    this.isReport,
    this.isOwnClub,
    this.isMatchPlayed,
    this.isMatchVisible,
    this.homeScore,
    this.outSideScore,
    this.tab,
    this.tour,
    this.isTeam1Forfeit,
    this.isTeam2Forfeit,
    this.centralReferee,
    this.assistantReferee1,
    this.assistantReferee2,
    this.principalObserver,
    this.assistantObserver,
    this.accompanyingDelegate,
    this.url,
    this.competitionID,
    this.poule,
    this.teamID,
    this.soccerType,
    this.isStatApplied,
    this.fieldId,
    this.isAdded,
    this.addressConvo,
    this.messageConvo,
    this.highLightsManagerUid,
    this.mvpManaged,
    this.isMvpStarted,
    this.clubs,
    this.stage,
    this.teams,
    this.whereIsPlayed='',
    this.isInHighLight,
    this.withTracker,
    this.fieldGpsCorners,
    this.ownerId,
    this.isTrackerDataUploaded,
    this.timestamp,
    this.duration,
    this.isScrapping = true,
    this.videoUrl,
  });


  Match.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;


    if(map != null && map['fieldGpsCorners'] != null) {
      fieldGpsCorners = FieldGpsCorners.fromMap(map['fieldGpsCorners']);
    }

    ownerId = map!['ownerId'] ?? '';

    map.forEach((key, value) {
      if(key == 'urlMatchDetails') {
        urlMatchDetails = value;
      }
    });

    ref = snapshot.reference;
    id= snapshot.get(keyMatchId);

    chType = snapshot.get(keyMatchChType);
    dateCh = snapshot.get(keyMatchDateCh);
    if(map[keyMatchTimeCh] != null) {
      timeCh = snapshot.get(keyMatchTimeCh);
    } else {
      timeCh = '18:00';
    }

    if(map[keyMatchDay] != null) {
      day = snapshot.get(keyMatchDay);
    } else {
      day = 0;
    }

    seasonID = snapshot.get(keyMatchSeasonID);
    if(map[keyMatchSurfaceDeJeu] != null) {
      surfaceDeJeu = snapshot.get(keyMatchSurfaceDeJeu);
    } else {
      surfaceDeJeu = '';
    }

    team1 = snapshot.get(keyMatchTeam1);
    affiliationTeam1 = snapshot.get(keyMatchAffiliationTeam1);
    team1UrlLogo = snapshot.get(keyMatchTeam1UrlLogo);
    team2 = snapshot.get(keyMatchTeam2);
    affiliationTeam2 = snapshot.get(keyMatchAffiliationTeam2);
    team2UrlLogo = snapshot.get(keyMatchTeam2UrlLogo);
    if(map[keyMatchTerrainAdresse1] != null) {
      terrainAdresse1 = snapshot.get(keyMatchTerrainAdresse1);
    } else {
      terrainAdresse1 = '';
    }
    if(map[keyMatchTerrainAdresse2] != null) {
      terrainAddress2 = snapshot.get(keyMatchTerrainAdresse2);
    } else {
      terrainAddress2 = '';
    }

    if(map[keyMatchNomDuTerrain] != null) {
      nomDuTerrain = snapshot.get(keyMatchNomDuTerrain);
    } else {
      nomDuTerrain = '';
    }

    if(map[keyMatchIsReport] != null) {
      isReport = map[keyMatchIsReport];
    } else {
      isReport = false;
    }
    if(map[keyMatchIsOwnClub] != null) {
      isOwnClub = map[keyMatchIsOwnClub];
    } else {
      isOwnClub = false;
    }
    if(map[keyMatchIsMatchPlayed] != null) {
      isMatchPlayed = map[keyMatchIsMatchPlayed];
    } else {
      isMatchPlayed = false;
    }

    isMatchVisible = snapshot.get(keyMatchIsMatchVisible);
    homeScore = map[keyMatchHomeScore] ?? 0;
    outSideScore = map[keyMatchOutsideScore] ?? 0;
    tab=snapshot.get(keyMatchTab);
    if(map[keyMatchTour] != null) {
      tour = snapshot.get(keyMatchTour);
    } else {
      tour = '';
    }

    isTeam1Forfeit = snapshot.get(keyMatchIsTeam1Forfeit);
    isTeam2Forfeit = snapshot.get(keyMatchIsTeam2Forfeit);
    if(map[keyMatchCentralReferee] != null) {
      centralReferee = snapshot.get(keyMatchCentralReferee);
    } else {
      centralReferee = '';
    }
    if(map[keyMatchAssistantReferee1] != null){
      assistantReferee1 = snapshot.get(keyMatchAssistantReferee1);
    } else {
      assistantReferee1 = '';
    }
    if(map[keyMatchAssistantReferee2] != null) {
      assistantReferee2 = snapshot.get(keyMatchAssistantReferee2);
    } else {
      assistantReferee2 = '';
    }
    if(map[keyMatchPrincipalObserver] != null) {
      principalObserver = snapshot.get(keyMatchPrincipalObserver);
    } else {
      principalObserver = '';
    }


    if(map[keyMatchAssistantObserver] != null) {
      assistantObserver =map[keyMatchAssistantObserver];
    } else {
      assistantObserver = '';
    }
    if(map[keyMatchAccompanyingDelegate] != null) {
      accompanyingDelegate = map[keyMatchAccompanyingDelegate];
    } else {
      accompanyingDelegate = '';
    }

    url = snapshot.get(keyMatchUrl);
    competitionID = snapshot.get(keyMatchCompetitionID);
    poule = snapshot.get(keyMatchPoule);
    if(map[keyMatchTeamID] != null) {
      teamID = map[keyMatchTeamID];
    } else {
      teamID = '';
    }
    if(map[keyMatchSoccerType] != null) {
      soccerType = map[keyMatchSoccerType];
    } else {
      soccerType = 11;
    }
    isStatApplied = snapshot.get(keyMatchIsStatApplied);

    if(map[keyMatchDateTimeConvo] != null) {
      dateTimeConvo = map[keyMatchDateTimeConvo];
    } else {
      dateTimeConvo = null;
    }
    if(map[keyMatchMessageConvo] != null) {
      messageConvo = map[keyMatchMessageConvo];
    } else {
      messageConvo = '';
    }
    if(map[keyMatchAddressConvo] != null) {
      addressConvo = map[keyMatchAddressConvo];
    } else {
      addressConvo = '';
    }
    if(map[keyMatchLiveFollowers] != null) {
      liveFollowers = map[keyMatchLiveFollowers];
    } else {
      liveFollowers = [];
    }
    if(map[keyMatchFieldId] != null) {
      fieldId = map[keyMatchFieldId];
    } else {
      fieldId = null;
    }

    if(map[keyMatchIsAdded] != null) {
      isAdded = map[keyMatchIsAdded];
    } else {
      isAdded = false;
    }

    if(map[keyMatchHighLightsManagerUid] != null) {
      highLightsManagerUid = map[keyMatchHighLightsManagerUid];
    } else {
      highLightsManagerUid = '';
    }

    if(map[keyMatchMvpManaged] != null) {
      mvpManaged = map[keyMatchMvpManaged];
    } else {
      mvpManaged = false;
    }

    if(map[keyMatchIsMvpStarted] != null ) {
      isMvpStarted = map[keyMatchIsMvpStarted];
    } else {
      isMvpStarted = false;
    }
    if(map[keyMatchDescription] != null) {
      description = snapshot.get(keyMatchDescription);
    } else {
      description = '';
    }

    if(map[keyMatchClubs] != null) {
      clubs = map[keyMatchClubs];
    } else {
      clubs = [];
    }

    if(map[keyMatchStage] != null) {
      stage = map[keyMatchStage];
    } else {
      stage = '';
    }


    if(map[keyMatchTeams] != null) {
      teams = map[keyMatchTeams];
    } else {
      teams = [];
    }

    if(map[keyMatchWhereMatchIsPlayed] != null) {
      whereIsPlayed = map[keyMatchWhereMatchIsPlayed];
    } else {
      whereIsPlayed = '';
    }

    if(map[keyMatchIsInHighLight] != null) {
      isInHighLight = map[keyMatchIsInHighLight];
    } else {
      isInHighLight = false;
    }

    withTracker = map[keyMatchWithTracker] ?? false;
    isTrackerDataUploaded = map[keyMatchIsTrackerDataUploaded] ?? false;
    timestamp = map[keyMatchTimestamp]?? null;
    duration = map[keyMatchDuration] ?? 90;

    if (map[keyMatchIsScrapping] != null) {
      isScrapping = map[keyMatchIsScrapping];
    } else {
      isScrapping = true;
    }

  }


  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyMatchId:id,
      keyMatchChType:chType,
      keyMatchDateCh:dateCh,
      keyMatchTimeCh:timeCh,
      keyMatchDay:day,
      keyMatchSeasonID:seasonID,
      keyMatchSurfaceDeJeu:surfaceDeJeu,
      keyMatchTeam1:team1,
      keyMatchAffiliationTeam1:affiliationTeam1,
      keyMatchTeam1UrlLogo:team1UrlLogo,
      keyMatchTeam2:team2,
      keyMatchAffiliationTeam2:affiliationTeam2,
      keyMatchTeam2UrlLogo:team2UrlLogo,
      keyMatchTerrainAdresse1:terrainAdresse1,
      keyMatchTerrainAdresse2:terrainAddress2,
      keyMatchNomDuTerrain:nomDuTerrain,
      keyMatchIsReport:isReport,
      keyMatchIsOwnClub:isOwnClub,
      keyMatchIsMatchPlayed:isMatchPlayed,
      keyMatchIsMatchVisible: isMatchVisible,
      keyMatchHomeScore:homeScore,
      keyMatchOutsideScore:outSideScore,
      keyMatchTab:tab,
      keyMatchTour:tour,
      keyMatchIsTeam1Forfeit:isTeam1Forfeit,
      keyMatchIsTeam2Forfeit:isTeam2Forfeit,
      keyMatchCentralReferee:centralReferee,
      keyMatchAssistantReferee1:assistantReferee1,
      keyMatchAssistantReferee2:assistantReferee2,
      keyMatchPrincipalObserver:principalObserver,
      keyMatchAssistantObserver:assistantObserver,
      keyMatchAccompanyingDelegate:accompanyingDelegate,
      keyMatchUrl:url,
      keyMatchCompetitionID:competitionID,
      keyMatchPoule:poule,
      keyMatchTeamID:teamID,
      keyMatchSoccerType:soccerType,
      keyMatchIsStatApplied:isStatApplied,
      keyMatchDateTimeConvo:dateTimeConvo,
      keyMatchMessageConvo:messageConvo,
      keyMatchAddressConvo:addressConvo,
      keyMatchLiveFollowers:liveFollowers,
      keyMatchFieldId:fieldId,
      keyMatchIsAdded:isAdded,
      keyMatchHighLightsManagerUid:highLightsManagerUid,
      keyMatchMvpManaged:mvpManaged,
      keyMatchIsMvpStarted:isMvpStarted,
      keyMatchDescription:description,
      keyMatchClubs:clubs,
      keyMatchStage:stage,
      keyMatchTeams:teams,
      keyMatchWhereMatchIsPlayed:whereIsPlayed,
      keyMatchIsInHighLight:isInHighLight,
      keyMatchWithTracker:withTracker,
      'fieldGpsCorners': fieldGpsCorners?.toMap(),
      'ownerId':ownerId,
      keyMatchIsTrackerDataUploaded:isTrackerDataUploaded ?? false,
      keyMatchTimestamp:timestamp,
      keyMatchDuration:duration,
      keyMatchIsScrapping:isScrapping ?? true,
    };
    return map;
  }


  @override
  String toString() {
    return 'Match: id = $id ' +
        'chType = $chType ' +
        'dateCh = $dateCh ' +
        'timeeCh = $timeCh ' +
        'day = $day ' +
        'seasonID = $seasonID ' +
        'surfaceDeJeu = $surfaceDeJeu ' +
        'team1 = >$team1< ' +
        'affiliationTeam1 = >$affiliationTeam1< ' +
        'team1UrlLogo = $team1UrlLogo ' +
        'team2 = >$team2< ' +
        'affiliationTeam2 = >$affiliationTeam2< ' +
        'team2UrlLogo = $team2UrlLogo ' +
        'terrainAdresse1 = $terrainAdresse1 ' +
        'terrainAdresse2 = $terrainAddress2 ' +
        'nomDuTerrain = $nomDuTerrain ' +
        'isReport = $isReport ' +
        'isOwnClub = $isOwnClub ' +
        'isMatchPlayed = $isMatchPlayed ' +
        'isMatchVisible=$isMatchVisible ' +
        'homeScore = $homeScore ' +
        'outsideScore = $outSideScore '  +
        'tab=$tab ' +
        'tour = $tour ' +
        'isTeam1Forfeit = $isTeam1Forfeit ' +
        'isTeam2Forfeit = $isTeam2Forfeit ' +
        'centralReferee = $centralReferee ' +
        'assitantReferee1 = $assistantReferee1 ' +
        'assistantReferee2 = $assistantReferee2 ' +
        'principalObserver = $principalObserver ' +
        'assistantObserver = $assistantObserver  ' +
        'accompanyingDelegate = $accompanyingDelegate ' +
        'url = $url ' +
        'competitionID = $competitionID ' +
        'poule=$poule ' +
        'teamID = $teamID ' +
        'soccerType =$soccerType ' +
        'isStatApplied=$isStatApplied ' +
        'dateTimeConvo=${dateTimeConvo.toString()} ' +
        'messageConvo:$messageConvo ' +
        'addressConvo:$addressConvo ' +
        'liveFollowers:${liveFollowers.toString()} ' +
        'fieldId:$fieldId ' +
        'isAdded:${isAdded.toString()} ' +
        'highLightsManagerUid:$highLightsManagerUid ' +
        'mvpManaged:${mvpManaged.toString()} ' +
        'isMvpStarted:${isMvpStarted.toString()} ' +
        'description:$description ' +
        'clubs:$clubs ' +
        'teams:$teams ' +
        'stage:$stage ' +
        'whereIsPlayed:$whereIsPlayed ' +
        'withTracker=$withTracker ' +
        'ownerId=$ownerId ' +
        'fieldGpsCorners=${fieldGpsCorners.toString()} ' +
        'isTrackerDataUploaded=$isTrackerDataUploaded ' +
        'videoUrl=$videoUrl';
  }

}