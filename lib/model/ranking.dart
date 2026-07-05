import 'package:cloud_firestore/cloud_firestore.dart';


String keyRankRang = "rang";
String keyRankTeam = "team";
String keyRankPts = "pts";
String keyRankJo = "jo";
String keyRankG = "G";
String keyRankN = "N";
String keyRankP = "P";
String keyRankF = "F";
String keyRankBP = "BP";
String keyRankBC = "BC";
String keyRankPE = "PE";
String keyRankDiff = "DIFF";

String keyRankingId = "id";
String keyRankingChType = "chType";
String keyRankingCompetitionID = "competitionID";
String keyRankingPoule ="poule";
String keyRankingRanks = "ranks";

class Rank {

  String? rang;
  String? team;
  String? pts;
  String? jo;
  String? g;
  String? n;
  String? p;
  String? f;
  String? bp;
  String? bc;
  String? pe;
  String? diff;

  Rank(Map<String, dynamic>? map) {
    rang  = map![keyRankRang];
    team  = map[keyRankTeam];
    pts   = map[keyRankPts];
    jo    = map[keyRankJo];
    g     = map[keyRankG];
    n     = map[keyRankN];
    p     = map[keyRankP];
    f     = map[keyRankF];
    bp    = map[keyRankBP];
    bc    = map[keyRankBC];
    pe    = map[keyRankPE];
    diff  = map[keyRankDiff];
  }

  @override
  String toString() {
    return 'Rank: rang=$rang ' +
    'team=$team ' +
    'pts=$pts ' +
    'jo=$jo ' +
    'g=$g ' +
    'n=$n ' +
    'p=$p ' +
    'f=$f ' +
    'bp=$bp ' +
    'bc=$bc ' +
    'pe=$pe ' +
    'diff=$diff';
  }
}


class Ranking {

  String? id;
  String? chType;
  String? competitionID;
  String? poule;
  List<Rank>? ranks;

  DocumentReference? ref;

  Ranking(DocumentSnapshot snapshot) {
    ref = snapshot.reference;

    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;
    id = map![keyRankingId];
    chType = map[keyRankingChType];
    competitionID = map[keyRankingCompetitionID];
    poule = map[keyRankingPoule];

    List<dynamic>? tmpObject = map[keyRankingRanks];
    ranks = [];
    for(int i=0;i<tmpObject!.length;i++) {
      Rank rank = Rank(tmpObject[i] as Map<String, dynamic>?);
      ranks!.add(rank);
    }
  }
  @override
  String toString() {
    return 'Ranking: id=$id ' +
      'chType=$chType ' +
      'competitionID=$competitionID ' +
      'poule=$poule' +
      'ranks=${ranks.toString()}';
  }

}