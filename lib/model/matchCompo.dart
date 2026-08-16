import 'package:cloud_firestore/cloud_firestore.dart';

import 'player_feeling.dart';
export 'player_feeling.dart';

String keyPlayerCompoPlayerId =  "playerID";
String keyPlayerCompoPlayerNumber = "number";
String keyPlayerCompoPlayerNameDisplayed = "playerNameDisplayed";
String keyPlayerCompoPlayerTrackerId = "deviceOwnerId";
String keyPlayerCompoPlayerCustomName = "customeName";
String keyPlayerCompoFeelingBefore = "feelingBefore";
String keyPlayerCompoFeelingAfter = "feelingAfter";

String keyPlayerConvoPlayerId = "playerID";
String keyPlayerConvoIsPresent = "isPresent";
String keyPlayerConvoAsAnswer = "asAnswer";

String keyMatchCompoMatchId = "matchID";
String keyMatchCompoCompoTypeId = "compoTypeID";
String keyMatchCompoSeasonID = "seasonID";
String keyMatchCompoTeamID = "teamID";
String keyMatchCompoGoalkeeper = "goalkeeper";
String keyMatchCompoDefender  = "defender";
String keyMatchCompoMidfielder = "midfielder";
String keyMatchCompoMidfielderAttacking = "midfielderAttacking";
String keyMatchCompoMidfielderDefensive = "midfielderDefensive";
String keyMatchCompoStrikcer = "stricker";
String keyMatchCompoSubstitute = "substitute";
String keyMatchCompoConvocation = "convocation";
String keyMatchCompoFeedback = 'withFeedback';


class PlayerCompo {

  String? playerID;
  int? number;
  String? playerNameDisplayed;
  String? deviceOwnerId;
  String? customName;

  /// Feeling scale 1–5 ("Comment te sens-tu ?"), before match.
  int? feelingBefore;

  /// Feeling scale 1–5 ("Comment te sens-tu ?"), after match.
  int? feelingAfter;

  PlayerCompo({this.playerID, this.number, this.playerNameDisplayed});

  PlayerFeeling? get feelingBeforeEnum => PlayerFeeling.fromValue(feelingBefore);
  PlayerFeeling? get feelingAfterEnum => PlayerFeeling.fromValue(feelingAfter);

  PlayerCompo.fromMap(Map<String,dynamic> map) {
    playerID = map[keyPlayerCompoPlayerId];
    number = map[keyPlayerCompoPlayerNumber];
    playerNameDisplayed=map[keyPlayerCompoPlayerNameDisplayed];
    final rawDeviceOwnerId = map[keyPlayerCompoPlayerTrackerId]?.toString().trim();
    deviceOwnerId =
        (rawDeviceOwnerId != null && rawDeviceOwnerId.isNotEmpty)
            ? rawDeviceOwnerId
            : null;
    final rawCustomName = map[keyPlayerCompoPlayerCustomName]?.toString().trim();
    customName =
        (rawCustomName != null && rawCustomName.isNotEmpty) ? rawCustomName : null;
    if (map[keyPlayerCompoFeelingBefore] != null) {
      feelingBefore = map[keyPlayerCompoFeelingBefore];
    } else {
      feelingBefore = 0;
    }
    if (map[keyPlayerCompoFeelingAfter] != null) {
      feelingAfter = map[keyPlayerCompoFeelingAfter];
    } else {
      feelingAfter = 0;
    }
  }


  Map<String, dynamic> toMap() {

    Map<String, dynamic> map = {
      keyPlayerCompoPlayerId: playerID,
      keyPlayerCompoPlayerNumber: number,
      keyPlayerCompoPlayerNameDisplayed: playerNameDisplayed,
      keyPlayerCompoPlayerTrackerId:deviceOwnerId,
      keyPlayerCompoPlayerCustomName:customName,
      keyPlayerCompoFeelingBefore: feelingBefore,
      keyPlayerCompoFeelingAfter: feelingAfter,
    };
    return map;
  }


  @override
  String toString() {
    return 'PlayerCompo: playerID=$playerID ' +
            'number=$number ' +
            'playerNameDisplayed=$playerNameDisplayed ' +
            'deviceOwnerId=$deviceOwnerId ' +
            'customeName=$customName ' +
            'feelingBefore=$feelingBefore ' +
            'feelingAfter=$feelingAfter';
  }

}

class PlayerConvo {

  String? playerID;
  bool? isPresent;
  bool? asAnswer;


  PlayerConvo({this.playerID, this.isPresent=false, this.asAnswer=false});

  PlayerConvo.fromMap(Map<String,dynamic> map) {
    playerID = map[keyPlayerConvoPlayerId];
    isPresent = map[keyPlayerConvoIsPresent];
    asAnswer = map[keyPlayerConvoAsAnswer];

  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyPlayerConvoPlayerId: playerID,
      keyPlayerConvoIsPresent: isPresent,
      keyPlayerConvoAsAnswer: asAnswer,
    };
    return map;
  }

  @override
  String toString() {
    return 'PlayerConvo: playerID=$playerID ' +
          'isPresent=${isPresent.toString()} ' +
          'asAnswer=${asAnswer.toString()}';
  }

}

class MatchCompo {

  String? matchID;
  String? get matchId => matchID;
  set matchId(String? value) => matchID = value;

  String? seasonID;
  String? compoTypeID;
  String? teamID;
  List<PlayerCompo>? goalkeeper;
  List<PlayerCompo>? defender;
  List<PlayerCompo>? midfielder;
  List<PlayerCompo>? midfielderAttaking;
  List<PlayerCompo>? midfielderDefensive;
  List<PlayerCompo>? stricker;
  List<PlayerCompo>? substitute;
  List<PlayerConvo>? convocation;
  bool? withFeedback=false;

  DocumentReference? ref;

  MatchCompo({
   this.matchID,
   this.compoTypeID,
   this.seasonID,
   this.teamID,
   this.goalkeeper,
   this.defender,
   this.midfielder,
   this.midfielderAttaking,
   this.midfielderDefensive,
   this.stricker,
   this.substitute,
   this.convocation,
   this.withFeedback=false,
  }) {

    if(this.goalkeeper == null)
      this.goalkeeper=[];
    if(this.defender == null)
      this.defender=[];
    if(this.midfielder == null)
      this.midfielder=[];
    if(this.stricker == null)
      this.stricker=[];
    if(this.midfielderDefensive == null)
      this.midfielderDefensive=[];
    if(this.midfielderAttaking == null)
      this.midfielderAttaking=[];
    if(this.substitute==null)
      this.substitute=[];
    if(this.convocation == null)
      this.convocation=[];

  }

  Map<String, dynamic> toMap() {

    List<dynamic> goalkeeperStr=[];
    goalkeeper!.forEach((element) {
      PlayerCompo playerCompo = element;
      goalkeeperStr.add(playerCompo.toMap());
    });

    List<dynamic> defenderListStr=[];
    defender!.forEach((element) {
      PlayerCompo playerCompo = element;
      defenderListStr.add(playerCompo.toMap());
    });

    List<dynamic> midfielderListStr=[];
    midfielder!.forEach((element) {
      PlayerCompo playerCompo = element;
      midfielderListStr.add(playerCompo.toMap());
    });

    List<dynamic> midfielderAttackingListStr=[];
    midfielderAttaking!.forEach((element) {
      PlayerCompo playerCompo = element;
      midfielderAttackingListStr.add(playerCompo.toMap());
    });

    List<dynamic> midfielderDefensiveListStr=[];
    midfielderDefensive!.forEach((element) {
      PlayerCompo playerCompo = element;
      midfielderDefensiveListStr.add(playerCompo.toMap());
    });

    List<dynamic> strickerListStr=[];
    stricker!.forEach((element) {
      PlayerCompo playerCompo = element;
      strickerListStr.add(playerCompo.toMap());
    });

    List<dynamic> substiuteListStr=[];
    substitute!.forEach((element) {
      PlayerCompo playerCompo = element;
      if(playerCompo.playerID != null) substiuteListStr.add(playerCompo.toMap());
    });

    List<dynamic> convocationListStr=[];

    convocation!.forEach((element) {
      PlayerConvo playerConvo = element;
      convocationListStr.add(playerConvo.toMap());
    });

    Map<String, dynamic> map = {
      keyMatchCompoMatchId:matchID,
      keyMatchCompoCompoTypeId:compoTypeID,
      keyMatchCompoSeasonID:seasonID,
      keyMatchCompoTeamID:teamID,
      keyMatchCompoGoalkeeper:goalkeeperStr,
      keyMatchCompoDefender:defenderListStr,
      keyMatchCompoMidfielder:midfielderListStr,
      keyMatchCompoMidfielderAttacking: midfielderAttackingListStr,
      keyMatchCompoMidfielderDefensive: midfielderDefensiveListStr,
      keyMatchCompoStrikcer:strickerListStr,
      keyMatchCompoSubstitute: substiuteListStr,
      keyMatchCompoConvocation: convocationListStr,
      keyMatchCompoFeedback:withFeedback,
    };
    return map;

  }


  MatchCompo.fromSnapshot(DocumentSnapshot documentSnapshot) {

    ref = documentSnapshot.reference;

    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;

    matchID = map![keyMatchCompoMatchId];
    compoTypeID = map[keyMatchCompoCompoTypeId];
    seasonID = map[keyMatchCompoSeasonID];
    teamID = map[keyMatchCompoTeamID];


    if(map[keyMatchCompoFeedback] !=null) {
      withFeedback = map[keyMatchCompoFeedback];
    } else {
      withFeedback = false;
    }


    if(map[keyMatchCompoFeedback] != null) {
      withFeedback = map[keyMatchCompoFeedback];
    } else {
      withFeedback = false;
    }

    List<dynamic> goalkeeperList =
        (map[keyMatchCompoGoalkeeper] as List<dynamic>?) ?? const <dynamic>[];
    goalkeeper=[];
    goalkeeperList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      goalkeeper!.add(playerCompo);
    });


    List<dynamic> defenderList =
        (map[keyMatchCompoDefender] as List<dynamic>?) ?? const <dynamic>[];
    defender=[];
    defenderList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      defender!.add(playerCompo);
    });


    List<dynamic> midfielderList =
        (map[keyMatchCompoMidfielder] as List<dynamic>?) ?? const <dynamic>[];
    midfielder=[];
    midfielderList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      midfielder!.add(playerCompo);
    });


    List<dynamic> midfielderAttackingList =
        (map[keyMatchCompoMidfielderAttacking] as List<dynamic>?) ??
            const <dynamic>[];
    midfielderAttaking=[];
    midfielderAttackingList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      midfielderAttaking!.add(playerCompo);
    });


    List<dynamic> midfielderDefensiveList =
        (map[keyMatchCompoMidfielderDefensive] as List<dynamic>?) ??
            const <dynamic>[];
    midfielderDefensive=[];
    midfielderDefensiveList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      midfielderDefensive!.add(playerCompo);
    });


    List<dynamic> strickerList =
        (map[keyMatchCompoStrikcer] as List<dynamic>?) ?? const <dynamic>[];
    stricker=[];
    strickerList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      stricker!.add(playerCompo);
    });


    List<dynamic> substituteList =
        (map[keyMatchCompoSubstitute] as List<dynamic>?) ?? const <dynamic>[];
    substitute=[];
    substituteList.forEach((element) {
      if (element is! Map) return;
      PlayerCompo playerCompo =
          PlayerCompo.fromMap(Map<String, dynamic>.from(element));
      substitute!.add(playerCompo);
    });

    List<dynamic> convocationList =
        (map[keyMatchCompoConvocation] as List<dynamic>?) ?? const <dynamic>[];
    convocation=[];
    convocationList.forEach((element) {
      if (element is! Map) return;
      PlayerConvo playerConvo =
          PlayerConvo.fromMap(Map<String, dynamic>.from(element));
      convocation!.add(playerConvo);
    });

  }

    @override
  String toString() {
    return 'MatchCompo: ref=${ref.toString()} ' +
       'matchID=$matchID ' +
      'compoTypeID=$compoTypeID ' +
      'goalkeeper=${goalkeeper.toString()} ' +
      'defender=${defender.toString()} ' +
      'midfielder=${midfielder.toString()} ' +
      'midfielderAttacking=${midfielderAttaking.toString()} ' +
      'midfielderDefensive=${midfielderDefensive.toString()} ' +
      'stricker=${stricker.toString()} ' +
      'substitute=${substitute.toString()} ' +
      'convocation=${convocation.toString()}';

  }
}