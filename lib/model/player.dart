import 'package:cloud_firestore/cloud_firestore.dart';

import '../util/player_positions.dart';
import '../util/player_profile_validator.dart' as profile_validator;
import '../util/search_options.dart';

String keyPlayerFirstName = 'firstName';
String keyPlayerLastName = 'lastName';
String keyPlayerStatut = 'statut';
String keyPlayerBirthDay = 'birthDay';
String keyPlayerBirthPlace = 'birthPlace';
String keyPlayerNationality = 'nationality';
String keyPlayerPositions = 'positions';
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
String keyPlayerEmail = 'email';
String keyPlayerPhoneE164 = 'phoneE164';
String keyPlayerPhoneCountryCode = 'phoneCountryCode';


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
  List<dynamic>? positions;
  String? category;
  String? sexe;
  String? userID;
  int? views;
  List<dynamic>? likes;
  String? photo;
  String? creatorUserId;  // if null the player is created by a backend program otherwise it contains the app user id
  String? personNumber;
  String? clubId;
  String? email;
  String? phoneE164;
  String? phoneCountryCode;
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
    this.positions,
    this.category='',
    this.sexe='',
    this.userID='',
    this.views,
    this.likes,
    this.photo='',
    this.personNumber,
    this.clubId,
    this.email,
    this.phoneE164,
    this.phoneCountryCode,
    this.searchOptions,
    this.unavailable,
    this.users,
  });

  List<int> get positionCodes {
    final raw = positions;
    if (raw == null || raw.isEmpty) return const [];

    return raw
        .map((value) {
          if (value is int) return value;
          return int.tryParse(value.toString());
        })
        .whereType<int>()
        .toList();
  }

  /// Profile position includes Educateur/Entraineur (coach/educator).
  bool get isEducatorOrCoach =>
      positionCodes.contains(positionCodeEducator);

  bool get isProfileComplete => profile_validator.isProfileComplete(this);

  bool get isProfileAndContactValid =>
      profile_validator.isProfileAndContactValid(this);

  Player toEditableProfile() {
    final birthDayTrimmed = birthDay?.trim();
    final birthPlaceTrimmed = birthPlace?.trim();
    final emailTrimmed = email?.trim();
    final phoneTrimmed = phoneE164?.trim();
    final phoneCountryTrimmed = phoneCountryCode?.trim();

    return copyWith(
      firstName: firstName?.trim() ?? '',
      lastName: lastName?.trim() ?? '',
      birthDay: birthDayTrimmed != null && birthDayTrimmed.isNotEmpty
          ? birthDayTrimmed
          : '',
      birthPlace: birthPlaceTrimmed != null && birthPlaceTrimmed.isNotEmpty
          ? birthPlaceTrimmed
          : '',
      nationality: nationality?.trim() ?? '',
      positions: positionCodes,
      email: emailTrimmed != null && emailTrimmed.isNotEmpty
          ? emailTrimmed
          : null,
      phoneE164: phoneTrimmed != null && phoneTrimmed.isNotEmpty
          ? phoneTrimmed
          : null,
      phoneCountryCode: phoneCountryTrimmed != null &&
              phoneCountryTrimmed.isNotEmpty
          ? phoneCountryTrimmed
          : null,
    );
  }

  static Player forNewMember({
    required String userId,
    required Player profile,
  }) {
    return _forNewMemberDocument(
      profile: profile,
      userId: userId,
      creatorUserId: userId,
    );
  }

  /// Member created by a coach/manager for roster assignment (no linked app user yet).
  static Player forInvitedMember({
    required String creatorUserId,
    required Player profile,
  }) {
    return _forNewMemberDocument(
      profile: profile,
      userId: '',
      creatorUserId: creatorUserId,
    );
  }

  static Player _forNewMemberDocument({
    required Player profile,
    required String userId,
    required String creatorUserId,
  }) {
    final searchOptions = buildPlayerSearchOptions(
      firstName: profile.firstName?.trim() ?? '',
      lastName: profile.lastName?.trim() ?? '',
    );
    final trimmedUserId = userId.trim();
    final users = trimmedUserId.isEmpty ? <String>[] : <String>[trimmedUserId];

    return Player(
      firstName: profile.firstName?.trim() ?? '',
      lastName: profile.lastName?.trim() ?? '',
      birthDay: profile.birthDay?.trim() ?? '',
      birthPlace: profile.birthPlace?.trim() ?? '',
      nationality: profile.nationality?.trim() ?? '',
      positions: profile.positionCodes,
      email: profile.email?.trim() ?? '',
      phoneE164: profile.phoneE164?.trim() ?? '',
      phoneCountryCode: profile.phoneCountryCode?.trim() ?? '',
      statut: 1,
      userID: trimmedUserId,
      users: users,
      searchOptions: searchOptions,
      views: 0,
      likes: [],
      photo: '',
      clubId: '',
      category: '',
      sexe: 'M',
      personNumber: '',
    )..creatorUserId = creatorUserId;
  }

  Map<String, dynamic> toProfileUpdateMap() {
    final searchOptions = buildPlayerSearchOptions(
      firstName: firstName?.trim() ?? '',
      lastName: lastName?.trim() ?? '',
    );

    return {
      keyPlayerFirstName: firstName?.trim() ?? '',
      keyPlayerLastName: lastName?.trim() ?? '',
      keyPlayerBirthDay: birthDay?.trim() ?? '',
      keyPlayerBirthPlace: birthPlace?.trim() ?? '',
      keyPlayerNationality: nationality?.trim() ?? '',
      keyPlayerPositions: positionCodes,
      keyPlayerEmail: email?.trim() ?? '',
      keyPlayerPhoneE164: phoneE164?.trim() ?? '',
      keyPlayerPhoneCountryCode: phoneCountryCode?.trim() ?? '',
      keyPlayerSearchOptions: searchOptions,
    };
  }

  Player copyWith({
    String? keyMember,
    String? firstName,
    String? lastName,
    int? statut,
    String? birthDay,
    String? birthPlace,
    String? nationality,
    List<dynamic>? positions,
    String? category,
    String? sexe,
    String? userID,
    int? views,
    List<dynamic>? likes,
    String? photo,
    String? creatorUserId,
    String? personNumber,
    String? clubId,
    String? email,
    String? phoneE164,
    String? phoneCountryCode,
    List<dynamic>? users,
    List<dynamic>? searchOptions,
    List<dynamic>? unavailable,
    DocumentReference? ref,
  }) {
    return Player(
      keyMember: keyMember ?? this.keyMember,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      statut: statut ?? this.statut,
      birthDay: birthDay ?? this.birthDay,
      birthPlace: birthPlace ?? this.birthPlace,
      nationality: nationality ?? this.nationality,
      positions: positions ?? this.positions,
      category: category ?? this.category,
      sexe: sexe ?? this.sexe,
      userID: userID ?? this.userID,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      photo: photo ?? this.photo,
      personNumber: personNumber ?? this.personNumber,
      clubId: clubId ?? this.clubId,
      email: email ?? this.email,
      phoneE164: phoneE164 ?? this.phoneE164,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      users: users ?? this.users,
      searchOptions: searchOptions ?? this.searchOptions,
      unavailable: unavailable ?? this.unavailable,
    )
      ..creatorUserId = creatorUserId ?? this.creatorUserId
      ..ref = ref ?? this.ref;
  }

  static DateTime? parseBirthDay(String? birthDay) {
    final trimmed = birthDay?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final parts = trimmed.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  static Player fromMap(Map<String, dynamic> map) {
    final player = Player();

    if (map[keyPlayerKeyMember] != null) {
      player.keyMember = map[keyPlayerKeyMember];
    } else {
      player.keyMember = '';
    }

    player.firstName = map[keyPlayerFirstName];
    player.lastName = map[keyPlayerLastName];
    player.statut = map[keyPlayerStatut];
    player.category = map[keyPlayerCategory];
    player.birthDay = map[keyPlayerBirthDay];
    player.birthPlace = map[keyPlayerBirthPlace];
    player.nationality = map[keyPlayerNationality];
    if (map[keyPlayerPositions] != null) {
      player.positions = map[keyPlayerPositions];
    } else {
      player.positions = [];
    }
    if (map[keyPlayerSexe] != null) {
      player.sexe = map[keyPlayerSexe];
    } else {
      player.sexe = 'M';
    }

    player.userID = map[keyPlayerUserID];
    if (map[keyPlayerPhoto] != null) {
      player.photo = map[keyPlayerPhoto];
    } else {
      player.photo = '';
    }

    if (map[keyPlayerViews] != null) {
      player.views = map[keyPlayerViews];
    } else {
      player.views = 0;
    }
    if (map[keyPlayerLikes] != null) {
      player.likes = map[keyPlayerLikes];
    } else {
      player.likes = [];
    }
    if (map[keyPlayerCreatorUserId] != null) {
      player.creatorUserId = map[keyPlayerCreatorUserId];
    }
    if (map[keyPlayerPersonNumber] != null) {
      player.personNumber = map[keyPlayerPersonNumber];
    } else {
      player.personNumber = '';
    }

    if (map[keyPlayerClubId] != null) {
      player.clubId = map[keyPlayerClubId];
    } else {
      player.clubId = '';
    }

    if (map[keyPlayerSearchOptions] != null) {
      player.searchOptions = map[keyPlayerSearchOptions];
    } else {
      player.searchOptions = [];
    }

    if (map[keyPlayerEmail] != null) {
      player.email = map[keyPlayerEmail];
    }
    if (map[keyPlayerPhoneE164] != null) {
      player.phoneE164 = map[keyPlayerPhoneE164];
    }
    if (map[keyPlayerPhoneCountryCode] != null) {
      player.phoneCountryCode = map[keyPlayerPhoneCountryCode];
    }

    if (map[keyPlayerUnavailability] != null) {
      player.unavailable = [];
      final unavailabilityList = map[keyPlayerUnavailability];
      for (int i = 0; i < unavailabilityList.length; i++) {
        final unavailability = Unavailability();
        unavailability.id = unavailabilityList[i]['id'];
        unavailability.from = unavailabilityList[i]['from'];
        unavailability.to = unavailabilityList[i]['to'];
        unavailability.details = unavailabilityList[i]['details'];
        if (unavailabilityList[i]['isVisible'] != null) {
          unavailability.isVisible = unavailabilityList[i]['isVisible'];
        } else {
          unavailability.isVisible = true;
        }
        switch (unavailabilityList[i]['type']) {
          case 'holiday':
            unavailability.unavailabilityType = UnavailabilityType.holiday;
            break;
          case 'unwell':
            unavailability.unavailabilityType = UnavailabilityType.unwell;
            break;
          case 'injured':
            unavailability.unavailabilityType = UnavailabilityType.injured;
            break;
          case 'other':
            unavailability.unavailabilityType = UnavailabilityType.other;
            break;
        }
        player.unavailable!.add(unavailability);
      }
    } else {
      player.unavailable = [];
    }

    if (map[keyPlayerUsers] != null) {
      player.users = map[keyPlayerUsers];
    } else {
      player.users = [];
    }

    return player;
  }

  Player.fromDocumentsnapshot(DocumentSnapshot snapshot) {
    ref = snapshot.reference;
    final map = snapshot.data() as Map<String, dynamic>?;
    if (map == null) return;

    final parsed = Player.fromMap(map);
    keyMember = parsed.keyMember;
    if (keyMember == null || keyMember!.trim().isEmpty) {
      keyMember = snapshot.id;
    }
    firstName = parsed.firstName;
    lastName = parsed.lastName;
    statut = parsed.statut;
    category = parsed.category;
    birthDay = parsed.birthDay;
    birthPlace = parsed.birthPlace;
    nationality = parsed.nationality;
    positions = parsed.positions;
    sexe = parsed.sexe;
    userID = parsed.userID;
    photo = parsed.photo;
    views = parsed.views;
    likes = parsed.likes;
    creatorUserId = parsed.creatorUserId;
    personNumber = parsed.personNumber;
    clubId = parsed.clubId;
    searchOptions = parsed.searchOptions;
    email = parsed.email;
    phoneE164 = parsed.phoneE164;
    phoneCountryCode = parsed.phoneCountryCode;
    unavailable = parsed.unavailable;
    users = parsed.users;
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
      keyPlayerPositions: positions ?? [],
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
      keyPlayerEmail: email?.trim() ?? '',
      keyPlayerPhoneE164: phoneE164?.trim() ?? '',
      keyPlayerPhoneCountryCode: phoneCountryCode?.trim() ?? '',
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