import 'package:cloud_firestore/cloud_firestore.dart';

// keys

String keySeasonCurrent = 'isCurrent';
String keySeasonStartDate = 'startDate';
String keySeasonEndDate = 'endDate';
String keySeasonName = 'name';
String keySeasonClubName = 'clubName';
String keySeasonAffiliateNumber ='affiliateNumber';
String keySeasonNewVersion = 'newVersion';



class Season {

  String? name;
  Timestamp? startDate;
  Timestamp? endDate;
  bool? isCurrent;
  String? clubName;
  String? affiliateNumber;
  bool? newVersion;

  DocumentReference? ref;


  Season({
   this.name,
   this.startDate,
   this.endDate,
   this.isCurrent,
   this.clubName,
   this.affiliateNumber,
   this.newVersion
  });

  Season.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    ref = snapshot.reference;
    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;
    name = map![keySeasonName];
    startDate = map[keySeasonStartDate];
    endDate = map[keySeasonEndDate];
    isCurrent = map[keySeasonCurrent];
    clubName = map[keySeasonClubName];
    affiliateNumber = map[keySeasonAffiliateNumber];
    if(map[keySeasonNewVersion] != null) {
      newVersion = map[keySeasonNewVersion];
    } else {
      newVersion = false;
    }
  }
  @override
  String toString() {
    return ('name: $name startDate: $startDate endDate: $endDate current: $isCurrent clubName:$clubName affiliateNumber:$affiliateNumber newVersion:$newVersion');
  }
}