import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

String keyGroundNomTerrain = 'nomTerrain';
String keyGroundAddress = 'address';
String keyGroundSurface = 'surface';
String keyGroundLocation = 'location';

class Ground {

  String? nomTerrain;
  String? address;
  String? surface;
  Location? location;

  Ground({this.nomTerrain, this.address, this.surface, this.location});
  Ground.fromMap(Map<String, dynamic> map) {
    if(map[keyGroundNomTerrain] != null) {
      nomTerrain = map[keyGroundNomTerrain].trim();
    } else {
      nomTerrain = '';
    }
    if(map[keyGroundAddress] != null) {
      address = map[keyGroundAddress].trim();
    } else {
      address = '';
    }
    if(map[keyGroundSurface] != null) {
      surface = map[keyGroundSurface].trim();
    } else {
      surface = '';
    }
    if(map[keyGroundLocation] != null) {
      location = Location.fromMap(map[keyGroundLocation]);
    } else {
      location = null;
    }
  }
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyGroundNomTerrain:nomTerrain,
      keyGroundAddress:address,
      keyGroundSurface:surface,
      keyGroundLocation:location,
    };
    return map;
  }


  @override
  String toString() {
    return 'Ground: nomDuTerrain=$nomTerrain ' +
      'address=$address ' +
      'surface=$surface ' +
      'location=${location.toString()}';
  }

}


String keyLocationGeoHash = 'geohash';
String keyLocationGeoPoint = 'geopoint';

class Location {
  String? geohash;
  GeoPoint? geopoint;

  Location({this.geohash, this.geopoint});
  Location.fromMap(Map<String, dynamic> map) {
    geohash = map[keyLocationGeoHash];
    geopoint = map[keyLocationGeoPoint];
  }
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyLocationGeoHash:geohash,
      keyLocationGeoPoint:geopoint
    };
    return map;
  }

  @override
  String toString() {
    return 'Location: geohash=$geohash ' +
      'geopoint=${geopoint.toString()}';
  }
}


String keyStaffFunction = 'function';
String keyStaffName = 'name';
String keyStaffParticulars = 'particulars';

class Staff {
  String? function;
  String? name;
  List<dynamic>? particulars=[];

  Staff({this.function, this.name, this.particulars});

  Staff.fromMap(Map<String,dynamic> map) {
    if(map[keyStaffFunction] != null) {
      function = map[keyStaffFunction];
    } else {
      function = '';
    }
    if(map[keyStaffName] != null) {
      name = map[keyStaffName];
    } else {
      name = '';
    }
    if(map[keyStaffParticulars] != null) {
      particulars = map[keyStaffParticulars];
    } else {
      particulars=[];
    }
  }
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      keyStaffName:name,
      keyStaffFunction:function,
      keyStaffParticulars:particulars,
    };
    return map;
  }
  @override
  String toString() {

    return 'Staff: name=$name ' +
      'function:$function ' +
      'particulars:${particulars.toString()}';
  }

}

String keyClubName = 'name';
String keyClubAffiliation = 'affiliation';
String keyCubLogo = 'logo';
String keyClubAddress = 'address';
String keyClubZipCode = 'zipCode';
String keyClubCity = 'city';
String keyClubGrounds = 'grounds';
String keyClubLocation = 'location';
String keyClubParticulars = 'particulars';
String keyClubStaff = 'staff';
String keyClubTeams = 'teams';
String keyClubSearchTerms = 'searchTerms';
String keyClubColors = 'colors';

class Club {
  String? name;
  String? affiliation; // key
  String? logo;
  String? address;
  String? zipCode;
  String? city;
  List<Ground>? grounds=[];
  Location? location;
  List<dynamic>? particulars=[];
  List<Staff>? staff=[];
  Map<dynamic, dynamic>? teams={};
  List<dynamic>? searchTerms=[];
  List<Color>? colors=[];

  DocumentReference? ref;

  Club({this.name, this.affiliation, this.logo});

  Club.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    ref = documentSnapshot.reference;
    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;

    name = map![keyClubName];
    affiliation = map[keyClubAffiliation];
    logo = map[keyCubLogo];
    address = map[keyClubAddress];
    zipCode = map[keyClubZipCode];
    city = map[keyClubCity];

    searchTerms = map[keyClubSearchTerms];

    if(map[keyClubGrounds] != null) {
      List<dynamic> tmpGrounds = map[keyClubGrounds];
      for(int i=0; i < tmpGrounds.length;i++) {
        Ground ground = Ground.fromMap(tmpGrounds[i]);
        grounds!.add(ground);
      }
    } else {
      grounds=[];
    }
    particulars = map[keyClubParticulars];
    if(map[keyClubLocation] != null) {
      location = Location.fromMap(map[keyClubLocation]);
    }

    if(map[keyClubStaff] != null) {
      List<dynamic> tmpStaff = map[keyClubStaff];
      for(int i=0; i < tmpStaff.length;i++) {
        staff!.add(Staff.fromMap(tmpStaff[i]));
      }
    } else {
      staff = [];
    }
    if(map[keyClubTeams] != null) {
      teams=map[keyClubTeams];
    } else {
      teams={};
    }

    if(map[keyClubColors] != null) {
      List<dynamic> tmpColor = map[keyClubColors];
      for(int i=0; i < tmpColor.length;i++) {
        Map<String,dynamic> mapColor = tmpColor[i];
        Color _color = Color.fromRGBO(int.parse(mapColor['R']), int.parse(mapColor['G']), int.parse(mapColor['B']), 1);
        colors!.add(_color);
      }
    } else {
      colors = [];
    }
  }

  Map<String, dynamic> toMap() {


    List<dynamic> groundList=[];
    for(int i=0; i < grounds!.length;i++) {
      Map<String, dynamic> _groundMap = grounds![i].toMap();
      groundList.add(_groundMap);
    }

    List<dynamic> staffList=[];
    for(int i=0; i < staff!.length;i++) {
      Map<String, dynamic> _staffMap = staff![i].toMap();
      staffList.add(_staffMap);
    }



    Map<String, dynamic> map = {
      keyClubName:name,
      keyClubAffiliation:affiliation,
      keyCubLogo:logo,
      keyClubAddress:address,
      keyClubZipCode:zipCode,
      keyClubCity:city,
      keyClubLocation:location.toString(),
      keyClubParticulars:particulars.toString(),
      keyClubGrounds:groundList.toString(),
      keyClubStaff:staffList.toString(),
      keyClubTeams:teams.toString(),
      keyClubSearchTerms:searchTerms,
    };
    return map;
  }

  @override
  String toString() {
    return 'Club: name=$name ' +
    'affiliation:$affiliation ' +
    'logo:$logo ' +
    'address:$address ' +
    'city:$city ' +
    'grounds:${grounds.toString()} ' +
    'location:${location.toString()} ' +
    'particulars:${particulars.toString()} ' +
    'staff:${staff.toString()} ' +
    'teams:${teams.toString()} ' +
    'searchTerms:${searchTerms.toString()} ' +
    'colors=${colors.toString()}';
  }

}
