import 'package:cloud_firestore/cloud_firestore.dart';

String keyPlayerFirstName = 'firstName';
String keyPlayerLastName = 'lastName';
String keyPlayerStatut = 'statut';
String keyPlayerBirthDay = 'birthDay';
String keyPlayerBirthPlace = 'birthPlace';
String keyPlayerNationality = 'nationality';
String keyPlayerSeasons = 'seasons';
String keyPlayerKeyMember = 'keyMember';
String keyPlayerCategory = 'category';
String keyPlayerSexe = 'sexe';
String keyPlayerUserID = 'userID';
String keyPlayerUsers = 'users';
String keyPlayerViews = 'views';
String keyPlayerLikes = 'likes';
String keyPlayerPhoto = 'photo';
String keyPlayerCreatorUserId = 'creatorUserId';
String keyPlayerPersonNumber = 'personNumber';
String keyPlayerClubId = 'clubId';
String keyPlayerSearchOptions = 'searchOptions';
String keyPlayerUnavailability = 'unavailability';


enum  UnavailabilityType { holiday, unwell, injured, other }

Map<UnavailabilityType, String> reasonsMap={
  UnavailabilityType.holiday:"Vacances",
  UnavailabilityType.injured:"Blessé",
  UnavailabilityType.unwell:"Malade",
  UnavailabilityType.other:"Autre motif"
};

class Unavailability {

  String? id;
  Timestamp? from;
  Timestamp? to;
  UnavailabilityType? unavailabilityType;
  String? details;
  bool? isVisible;

  Unavailability({this.from, this.to, this.unavailabilityType, this.details, this.id, this.isVisible=true});

  @override
  String toString() {
    return 'from=${from!.millisecondsSinceEpoch.toString()} ' +
      'to=${to!.millisecondsSinceEpoch.toString()} ' +
      'unavailabilityType=${unavailabilityType.toString()} ' +
      'details=$details';
  }

}


class Player {
  String? keyMember;
  String? firstName;
  String? lastName;
  int? statut;     // 1=Active
  String? birthDay;
  String? birthPlace;
  String? nationality;
  String? category;
  String? sexe;
  String? userID;
  int? views;
  List<dynamic>? likes;
  String? photo;
  String? creatorUserId;  // if null the player is created by a backend program otherwise it contains the app user id
  String? personNumber;
  String? clubId;
  List<dynamic>? users=[];

  List<dynamic>? searchOptions=[];
  List<dynamic>? unavailable=[];

  DocumentReference? ref;

  Player({
    this.keyMember='',
    this.firstName='',
    this.lastName='',
    this.statut=1,
    this.birthDay='',
    this.birthPlace='',
    this.nationality,
    this.category='',
    this.sexe='',
    this.userID='',
    this.views,
    this.likes,
    this.photo='',
    this.personNumber,
    this.clubId,
    this.searchOptions,
    this.unavailable,
    this.users,
  });

  Player.fromDocumentsnapshot(DocumentSnapshot snapshot) {

    ref = snapshot.reference;

    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;

    if(map != null) {
      if(map[keyPlayerKeyMember] != null) {
        keyMember     = map[keyPlayerKeyMember];
      } else {
        keyMember = '';
      }

      firstName     = map[keyPlayerFirstName];
      lastName      = map[keyPlayerLastName];
      statut        = map[keyPlayerStatut];
      category      = map[keyPlayerCategory];
      birthDay      = map[keyPlayerBirthDay];
      birthPlace    = map[keyPlayerBirthPlace];
      nationality   = map[keyPlayerNationality];
      if(map[keyPlayerSexe] != null) {
        sexe          = map[keyPlayerSexe];
      } else {
        sexe = 'M';
      }

      userID        = map[keyPlayerUserID];
      if(map[keyPlayerPhoto] != null) {
        photo         = map[keyPlayerPhoto];
      } else {
        photo = "";
      }

      if(map[keyPlayerViews] != null) {
        views         = map[keyPlayerViews];
      } else {
        views         = 0;
      }
      if(map[keyPlayerLikes] != null) {
        likes         = map[keyPlayerLikes];
      } else {
        likes= [];
      }
      if(map[keyPlayerCreatorUserId] != null) {
        creatorUserId   = map[keyPlayerCreatorUserId];
      }
      if(map[keyPlayerPersonNumber] != null) {
        personNumber    = map[keyPlayerPersonNumber];
      } else {
        personNumber = '';
      }

      if(map[keyPlayerClubId] != null) {
        clubId = map[keyPlayerClubId];
      } else {
        clubId = '';
      }

      if(map[keyPlayerSearchOptions] != null) {
        searchOptions = map[keyPlayerSearchOptions];
      } else {
        searchOptions = [];
      }

      if(map[keyPlayerUnavailability] != null) {
        unavailable = [];
        List<dynamic> _unavailabilityList  = map[keyPlayerUnavailability];
        for(int i=0; i <_unavailabilityList.length;i++) {
          Unavailability _unavailability = Unavailability();
          _unavailability.id = _unavailabilityList[i]['id'];
          _unavailability.from = _unavailabilityList[i]['from'];
          _unavailability.to = _unavailabilityList[i]['to'];
          _unavailability.details = _unavailabilityList[i]['details'];
          if(_unavailabilityList[i]['isVisible'] != null) {
            _unavailability.isVisible = _unavailabilityList[i]['isVisible'];
          } else {
            _unavailability.isVisible = true;
          }
          switch(_unavailabilityList[i]['type']) {
            case 'holiday':
              _unavailability.unavailabilityType = UnavailabilityType.holiday;
              break;
            case 'unwell':
              _unavailability.unavailabilityType = UnavailabilityType.unwell;
              break;
            case 'injured':
              _unavailability.unavailabilityType = UnavailabilityType.injured;
              break;
            case 'other':
              _unavailability.unavailabilityType = UnavailabilityType.other;
              break;
          }
          unavailable!.add(_unavailability);
        }
      } else {
        unavailable = [];
      }

      if(map[keyPlayerUsers] != null) {
        users = map[keyPlayerUsers];
      } else {
        users = [];
      }
    }
  }

  Map<String, dynamic> toMap() {

    List<dynamic> _unavailabilityList = [];

    if(unavailable != null) {
      for(int i=0; i < unavailable!.length;i++) {
        Unavailability _unavailability = unavailable![i];
        Map<dynamic, dynamic> _mapUnavailability = {};

        _mapUnavailability['id'] = _unavailability.id;
        _mapUnavailability['from'] = _unavailability.from;
        _mapUnavailability['to'] = _unavailability.to;
        _mapUnavailability['details'] = _unavailability.details;
        _mapUnavailability['isVisible'] = _unavailability.isVisible;

        switch(_unavailability.unavailabilityType!) {

          case UnavailabilityType.holiday:
            _mapUnavailability['type'] = 'holiday';
            break;
          case UnavailabilityType.unwell:
            _mapUnavailability['type'] = 'unwell';
            break;
          case UnavailabilityType.injured:
            _mapUnavailability['type'] = 'injured';
            break;
          case UnavailabilityType.other:
            _mapUnavailability['type'] = 'other';
            break;
        }
        _unavailabilityList.add(_mapUnavailability);
      }
    }


    Map<String, dynamic> map = {
      keyPlayerKeyMember: keyMember,
      keyPlayerFirstName: firstName,
      keyPlayerLastName: lastName,
      keyPlayerStatut:  statut,     // 1 = Active ....
      keyPlayerCategory: category,
      keyPlayerBirthDay: birthDay,
      keyPlayerBirthPlace: birthPlace,
      keyPlayerNationality: nationality,
      keyPlayerSexe: sexe,
      keyPlayerUserID: userID,
      keyPlayerViews: views,
      keyPlayerLikes: likes,
      keyPlayerPhoto: photo,
      keyPlayerCreatorUserId:creatorUserId,
      keyPlayerPersonNumber:personNumber,
      keyPlayerClubId:clubId,
      keyPlayerSearchOptions:searchOptions,
      keyPlayerUnavailability:_unavailabilityList,
      keyPlayerUsers:users,
    };

    return map;
  }



  @override
  String toString() {
    return 'Player {' +
        'keyMember: $keyMember '  +
        'personNumber:$personNumber ' +
        'fistName: $firstName '   +
        'lastNmae: $lastName '    +
        'birthYear: $birthDay '  +
        'catagory: $category '  +
        'sexe: $sexe '  +
        'userID: $userID '  +
        'ref: $ref ' +
        'likes: ${likes.toString()} ' +
        'views: $views ' +
        'photo: >$photo< ' +
        'statut: >$statut< ' +
        'creatorUserId:$creatorUserId '+
        'clubId:$clubId '+
        'unavailable=$unavailable ' +
        'users=$users';
  }


}