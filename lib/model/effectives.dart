import 'package:cloud_firestore/cloud_firestore.dart';


class Tracker {
  String? ownerId;
  String? deviceId;

  Tracker({
    this.ownerId,
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'deviceId': deviceId,
    };
  }

  factory Tracker.fromMap(Map<String, dynamic> map) {
    return Tracker(
      ownerId: map['ownerId'] as String?,
      deviceId: map['deviceId'] as String?,
    );
  }
}

String keyEffectivesMemberID = 'memberID';
String keyEffectivesSeasonID = 'seasonID';
String keyEffectivesTeamID = 'teamID';
String keyEffectivesPosition = 'position';
String keyEffectivesPiedFort = 'piedFort';
String keyEffectivesTaille = 'taille';
String keyEffectivesPoids = 'poids';
String keyEffectivesType= 'type';
String keyEffectivesText= 'text';
String keyEffectivesText2= 'text2';
String keyEffectivesOrder= 'order';
String keyEffectivesClubId = 'clubId';
String keyEffectivesDate= 'modificationDate';

class Effectives {

  String? memberID;
  String? seasonID;
  String? teamID;
  int? position;  // 1=coach, 2=dirigeant, 3=Gardien de but, 4=défenseur, 5=milieu, 6=attaquant
  String? piedFort;
  int? taille;
  int? poids;
  int? type; // 1=joueur,2=Entraineur/educateur, 3=Dirigeant, 4=Entraineur/Joueur
  String? text;  // texte complémentaire
  String? text2; // 2eme texte complémentaire
  int? order;
  String? clubId;
  Timestamp? modificationDate;

  List<String>? trackers;


  DocumentReference? ref;

  Effectives({
    this.memberID,
    this.seasonID,
    this.teamID,
    this.order=0,
    this.position=0,
    this.piedFort="",
    this.taille=0,
    this.poids=0,
    this.type=1,
    this.text="",
    this.text2='',
    this.clubId = '',
    this.modificationDate,
    this.trackers,
  });

  Effectives.fromData(DocumentSnapshot snapshot) {

    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;

    ref = snapshot.reference;
    memberID = map![keyEffectivesMemberID];
    seasonID = map[keyEffectivesSeasonID];
    teamID = map[keyEffectivesTeamID];


    if(map[keyEffectivesPosition] != null) {
        position = map[keyEffectivesPosition];
    } else {
      position = 0;
    }
    if(map[keyEffectivesPiedFort] != null) {
      piedFort = map[keyEffectivesPiedFort];
    } else {
      piedFort ="";
    }
    if(map[keyEffectivesTaille] != null) {
      taille = map[keyEffectivesTaille];
    } else {
      taille = 0;
    }
    if(map[keyEffectivesPoids] != null) {
      poids = map[keyEffectivesPoids];
    } else {
      poids = 0;
    }
    type =  map[keyEffectivesType];
    text =  map[keyEffectivesText];
    if(map[keyEffectivesDate] != null) {
      modificationDate = map[keyEffectivesDate];
    }
    if(map[keyEffectivesText2] != null) {
      text2 = map[keyEffectivesText2];
    } else {
      text2 = '';
    }
    if(map[keyEffectivesOrder] != null) {
      order = map[keyEffectivesOrder];
    } else {
      order = 0;
    }
    if(map[keyEffectivesClubId] != null) {
      clubId = map[keyEffectivesClubId];
    } else {
      // old version of the data model, set to the default clubId (500554)
      clubId = '';
    }

    trackers =  (map['trackers'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        const <String>[];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyEffectivesMemberID: memberID,
      keyEffectivesSeasonID: seasonID,
      keyEffectivesTeamID: teamID,
      keyEffectivesPosition: position,
      keyEffectivesPiedFort: piedFort,
      keyEffectivesTaille: taille,
      keyEffectivesPoids: poids,
      keyEffectivesType:type,
      keyEffectivesText:text,
      keyEffectivesText2:text2,
      keyEffectivesOrder:order,
      keyEffectivesClubId:clubId,
      keyEffectivesDate:modificationDate,
      'trackers': trackers,
    };

    return map;
  }

  @override
  String toString() {
    return 'Effectives:' +
            'memberID = $memberID ' +
            'seasonID = $seasonID ' +
            'teamID   = $teamID ' +
            'position = $position ' +
            'piedFort = $piedFort ' +
            'taille = $taille ' +
            'poids = $poids ' +
            'type = $type ' +
            'text= $text ' +
            'text2 = $text2 ' +
            'order = $order ' +
            'clubId =$clubId ' +
            'trackers = ${trackers.toString()} ' +
            'date=${modificationDate.toString()} ';
  }

}
String getStrPosition(int position) {

  String strPosition="";
  switch(position) {
    case 0:
      strPosition = 'Joueur';
      break;
    case 1:
      strPosition = 'Educateur/Entraineur';
      break;
    case 2:
      strPosition = 'Dirigeant';
      break;
    case 3:
      strPosition = 'Gardien de but';
      break;
    case 4:
      strPosition = 'Défenseur';
      break;
    case 5:
      strPosition = 'Milieu';
      break;
    case 6:
      strPosition = 'Attaquant';
      break;
  }

  return strPosition;
}
int? getIntPosition(String position) {

  int? intPosition;

  switch(position) {
    case 'Educateur/Entraineur':
      intPosition = 1;
      break;
    case 'Dirigeant':
      intPosition = 2;
      break;
    case 'Gardien de but':
      intPosition = 3;
      break;
    case 'Défenseur':
      intPosition = 4;
      break;
    case 'Milieu':
      intPosition = 5;
      break;
    case 'Attaquant':
      intPosition = 6;
      break;
  }
  return intPosition;

}