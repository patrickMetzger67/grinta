import 'package:cloud_firestore/cloud_firestore.dart';

enum ActionType {
  timeEvent,
  goal,
  yellowCard,
  redCard,
  substitution,
}

String keySubstitutionAffiliationTeam     = 'affliationTeam';
String keySubstitutionEnteringPlayerId    = 'enteringPlayerId';
String keySubstitutionEnteringPlayerName  = 'enteringPlayerName';
String keySubstitutionEnteringPlayerNumber = 'enteringPlayerNumber';
String keySubstitutionOutgoingPlayerId    = 'outgoingPlayerId';
String keySubstitutionOutgoingPlayerName  = 'outgoingPlayerName';
String keySubstitutionOutgoingPlayerNumber = 'outgoingPlayerNumber';


class Substitution {

  String? affiliationTeam;
  String? enteringPlayerId;
  String? enteringPlayerName; // if opponent player
  int?  enteringPlayerNumber; // if opponent player
  String? outgoingPlayerId;
  String? outgoingPlayerName;  // if opponent player
  int? outgoingPlayerNumber; // if opponent player

  Substitution({this.affiliationTeam, this.enteringPlayerId, this.enteringPlayerName, this.outgoingPlayerName, this.outgoingPlayerId});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keySubstitutionAffiliationTeam:affiliationTeam,
      keySubstitutionEnteringPlayerId:enteringPlayerId,
      keySubstitutionEnteringPlayerName:enteringPlayerName,
      keySubstitutionEnteringPlayerNumber:enteringPlayerNumber,
      keySubstitutionOutgoingPlayerId:outgoingPlayerId,
      keySubstitutionOutgoingPlayerName:outgoingPlayerName,
      keySubstitutionOutgoingPlayerNumber:outgoingPlayerNumber,

    };
    return map;
  }

  Substitution.fromMap(Map<String,dynamic>? map) {
    affiliationTeam       = map![keySubstitutionAffiliationTeam];
    enteringPlayerId      = map[keySubstitutionEnteringPlayerId];
    enteringPlayerName    = map[keySubstitutionEnteringPlayerName];
    enteringPlayerNumber  = map[keySubstitutionEnteringPlayerNumber];
    outgoingPlayerId      = map[keySubstitutionOutgoingPlayerId];
    outgoingPlayerName    = map[keySubstitutionOutgoingPlayerName];
    outgoingPlayerNumber  = map[keySubstitutionOutgoingPlayerNumber];
  }

  @override
  String toString() {
    // TODO: implement toString
    return 'Substitution: affiliationTeam=$affiliationTeam ' +
    'enteringPlayerId=$enteringPlayerId ' +
    'enteringPlayerName=$enteringPlayerName ' +
    'outgoingPlayerId=$outgoingPlayerId ' +
    'outgoingPlayerName=$outgoingPlayerName';
  }

}


enum TimeType {
  kickOff,
  halTime,
  secondHalf,
  startExtraTime,
  end,
}

String keyTimeEventType = 'type';
String keyTimeEventValue = 'value';

class TimeEvent {

  TimeType? type;
  int? value;    // only if additionalTime else the value is 0

  TimeEvent({this.type, this.value=0});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyTimeEventType:type.toString(),
      keyTimeEventValue:value
    };
    return map;
  }

  TimeEvent.fromMap(Map<String,dynamic>? map) {
    switch(map![keyTimeEventType]) {
      case 'TimeType.kickOff':
        type = TimeType.kickOff;
        break;
      case 'TimeType.end':
        type = TimeType.end;
        break;
      case 'TimeType.startExtraTime':
        type = TimeType.startExtraTime;
        break;
      case 'TimeType.halTime':
        type = TimeType.halTime;
        break;
      case 'TimeType.secondHalf':
        type = TimeType.secondHalf;
        break;
    }
    value = map[keyTimeEventValue];
  }

  @override
  String toString() {
    return 'TimeEvent: type=${type.toString()} ' +
      'value=$value';
  }

}


enum CardType {
  yellow,
  red,
}
String keyYellowRedCardAffiliationTeam = 'affiliationTeam';
String keyYellowRedCardPlayerId        = 'playerID';
String keyYellowRedCardPlayerName      = 'playerName';
String keyYellowRedCardPlayerNumber    = 'playerNumber';
String keyYellowRedCardCardType        = 'cardType';


class YellowRedCard {
  String? affiliationTeam;
  String? playerId;
  String? playerName;// if opponent goal
  int? playerNumber;
  CardType? cardType;

  YellowRedCard({this.affiliationTeam, this.playerId, this.playerName, this.cardType});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyYellowRedCardAffiliationTeam:affiliationTeam,
      keyYellowRedCardPlayerId:playerId,
      keyYellowRedCardPlayerName:playerName,
      keyYellowRedCardPlayerNumber:playerNumber,
      keyYellowRedCardCardType:cardType.toString()
    };
    return map;
  }

  YellowRedCard.fromMap(Map<String,dynamic>? map) {
    affiliationTeam = map![keyYellowRedCardAffiliationTeam];
    playerId        = map[keyYellowRedCardPlayerId];
    playerName      = map[keyYellowRedCardPlayerName];
    playerNumber    = map[keyYellowRedCardPlayerNumber];
    switch(map[keyYellowRedCardCardType]) {
      case 'CardType.yellow':
        cardType = CardType.yellow;
        break;
      case 'CardType.red':
        cardType = CardType.red;
        break;
    }
  }

  @override
  String toString() {
    // TODO: implement toString
    return 'YellowRedCard: affiliationTeam=$affiliationTeam ' +
      'playerId=$playerId ' +
      'playerName=$playerName ' +
      'playerNumber=$playerNumber ' +
      'cardType=${cardType.toString()}';
  }
}


String keyGoalAffilicationTeam = 'affiliationTeam';
String keyGoalGoalType = 'goalType';
String keyGoalScorerPlayerId = 'playerId';
String keyGoalDecisivePasserPlayerID = 'decisivePlayerId';
String keyGoalDecisivePasser = 'decisivePasser';
String keyGoalPlayerName = 'playerName';
String keyGoalPlayerNumber = 'playerNumber';
String keyGoalPlayerDecisivePasserNumber = 'playerDecisivePasserNumber';
String keyGoalPlayerScorerPosDx = 'scorerPosDx';
String keyGoalPlayerScorerPosDy = 'scorerPosDy';
String keyGoalPlayerPasserPosDx = 'passerPosDx';
String keyGoalPlayerPasserPosDy = 'passserPosDy';

enum GoalType {
  normal,
  penalty,
  freeKick
}


class Goal {

  String? affiliationTeam;
  GoalType? goalType;

  String? playerId;
  String? decisivePasserPlayerId;

  String? playerName;      // if opponent goal
  int? playerNumber;   // if opponent goal
  String? playerDecisivePasser; // if opponent goal
  int? playerDecisivePasserNumber; // if opponent goal


  double scorerPosDx=0.0;
  double scorerPosDy=0.0;

  double passerPosDx=0.0;
  double passerPosDy=0.0;


  Goal({this.affiliationTeam, this.goalType, this.playerId, this.playerName, this.decisivePasserPlayerId});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyGoalAffilicationTeam: affiliationTeam,
      keyGoalGoalType:goalType.toString(),
      keyGoalScorerPlayerId:playerId,
      keyGoalDecisivePasserPlayerID:decisivePasserPlayerId,
      keyGoalPlayerName:playerName,
      keyGoalPlayerNumber:playerNumber,
      keyGoalDecisivePasser:playerDecisivePasser,
      keyGoalPlayerDecisivePasserNumber:playerDecisivePasserNumber,
      keyGoalPlayerScorerPosDx:scorerPosDx,
      keyGoalPlayerScorerPosDy:scorerPosDy,
      keyGoalPlayerPasserPosDx:passerPosDx,
      keyGoalPlayerPasserPosDy:passerPosDy
    };

    return map;
  }
  Goal.fromMap(Map<String,dynamic>? map) {

    switch(map![keyGoalGoalType]) {
      case 'GoalType.normal':
        goalType = GoalType.normal;
        break;
      case 'GoalType.freeKick':
        goalType = GoalType.freeKick;
        break;
      case 'GoalType.penalty':
        goalType = GoalType.penalty;
        break;
    }

    affiliationTeam =  map[keyGoalAffilicationTeam];
    playerId = map[keyGoalScorerPlayerId];
    decisivePasserPlayerId =  map[keyGoalDecisivePasserPlayerID];
    playerName = map[keyGoalPlayerName];
    playerNumber = map[keyGoalPlayerNumber];
    playerDecisivePasser = map[keyGoalDecisivePasser];
    playerDecisivePasserNumber = map[keyGoalPlayerDecisivePasserNumber];
    if(map[keyGoalPlayerScorerPosDx] != null) {
      scorerPosDx = map[keyGoalPlayerScorerPosDx];
    } else {
      scorerPosDx = 0.0;
    }
    if(map[keyGoalPlayerScorerPosDy] != null) {
      scorerPosDy = map[keyGoalPlayerScorerPosDy];
    } else {
      scorerPosDy = 0.0;
    }

    if(map[keyGoalPlayerPasserPosDx] != null) {
      passerPosDx = map[keyGoalPlayerPasserPosDx];
    } else {
      passerPosDx = 0.0;
    }
    if(map[keyGoalPlayerPasserPosDy] != null) {
      passerPosDy = map[keyGoalPlayerPasserPosDy];
    } else {
      passerPosDy = 0.0;
    }

  }
  @override
  String toString() {
    return 'Goal: affiliationTeam = $affiliationTeam ' +
    'goalType = $goalType ' +
    'playerId = $playerId ' +
     'decisivePasserPlayerId = $decisivePasserPlayerId ' +
    'playerName = $playerName ' +
    'playerNumber = $playerNumber ' +
    'playerDecisivePasser = $playerDecisivePasser ' +
    'playerDecisivePasserNumber = $playerDecisivePasserNumber ' +
    'scorerPosDx:$scorerPosDx ' +
    'scorerPosDy:$scorerPosDy ' +
    'passerPosDx:$passerPosDx ' +
    'passerPosDy:$passerPosDy';

  }
}

String keyHlMatchCalendarId = 'matchCalendarId';
String keyHlMinute = 'minute';
String keyHlExtraTime = 'extraTime';
String keyHlAction = 'action';
String keyHlValue = 'value';
String keyHlPhoto = 'photo';
String keyHlDateTime = 'dateTime';


class Highlights {
  String? matchCalendarId;
  int? minute;
  int? extraTime;
  ActionType? actionType;
  dynamic value;
  String? photo;
  Timestamp? dateTime;
  DocumentReference? ref;

  Highlights(
      {this.matchCalendarId,
      this.minute=0,
      this.extraTime=0,
      this.actionType,
      this.value,
      this.photo,
      this.dateTime});

  Highlights.fromSnapshot(DocumentSnapshot documentSnapshot) {
    ref = documentSnapshot.reference;

    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;

    matchCalendarId = map![keyHlMatchCalendarId];
    minute = map[keyHlMinute];
    if(map[keyHlExtraTime] != null) {
      extraTime = map[keyHlExtraTime];
    } else {
      extraTime = 0;
    }
    photo = map[keyHlPhoto];
    dateTime = map[keyHlDateTime];


    switch(map[keyHlAction]) {
      case 'ActionType.timeEvent':
        actionType = ActionType.timeEvent;
        value = TimeEvent.fromMap(map[keyHlValue]);
        break;
      case 'ActionType.goal':
        actionType = ActionType.goal;
        value = Goal.fromMap(map[keyHlValue]);
        break;
      case 'ActionType.yellowCard':
        actionType = ActionType.yellowCard;
        value = YellowRedCard.fromMap(map[keyHlValue]);
        break;
      case 'ActionType.redCard':
        actionType = ActionType.redCard;
        value = YellowRedCard.fromMap(map[keyHlValue]);
        break;
      case 'ActionType.substitution':
        actionType = ActionType.substitution;
        value = Substitution.fromMap(map[keyHlValue]);
        break;
    }
  }

  Map<String, dynamic> toMap() {

    Map<String, dynamic> actionMap={};
    if(value.runtimeType == Goal) {
      Goal goal = value;
      actionMap = goal.toMap();
    }
    if(value.runtimeType == TimeEvent) {
      TimeEvent timeEvent = value;
      actionMap = timeEvent.toMap();
    }
    if(value.runtimeType == YellowRedCard) {
      YellowRedCard yellowRedCard = value;
      actionMap = yellowRedCard.toMap();
    }
    if(value.runtimeType == Substitution) {
      Substitution substitution = value;
      actionMap = substitution.toMap();
    }

    Map<String, dynamic> map = {
      keyHlMatchCalendarId: matchCalendarId,
      keyHlMinute: minute,
      keyHlExtraTime: extraTime,
      keyHlAction:actionType.toString(),
      keyHlValue:actionMap,
      keyHlPhoto:photo,
      keyHlDateTime:dateTime,
    };
    return map;
  }

  @override
  String toString() {
    return 'HighLights: matchCalendarId=$matchCalendarId ' +
      'minute=$minute ' +
      'extraTime=$extraTime ' +
      'actionType=${actionType.toString()} ' +
      'value=${value.toString()} ' +
      'photo=$photo ' +
      'dateTime=${dateTime.toString()}';
  }


}
