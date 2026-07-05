import 'package:cloud_firestore/cloud_firestore.dart';


String keyRankingPerDayChType = "chType";
String keyRankingPerDayCompetitionID = "competitionID";
String keyRankingPerDayPoule = "poule";
String keyRankingPerDayTeamName = "team";
String keyRankingPerDayTeamAffiliate ="teamAffiliate";
String keyRankingPerDaySeasonID ="seasonID";
String keyRankingPerDayDay = "day";
String keyRankingPerDayNbTeams= "nbTeams";
String keyRankingPerDayJo = "jo";
String keyRankingPerDayG = "g";
String keyRankingPerDayN = "n";
String keyRankingPerDayP = "p";
String keyRankingPerDayPts = "pts";
String keyRankingPerDayRank = "rank";
String keyRankingPerDayBc = "bc";
String keyRankingPerDayBp = "bp";
String keyRankingPerDayDiff = "diff";


class RankingPerDay {

  String? chType;
  String? competitionID;
  String? poule;
  String? teamName;
  String? teamAffiliate;
  String? seasonID;

  int? day;

  int? nbTeams;
  int? jo;
  int? g;
  int? n;
  int? p;

  int? pts;
  int? rank;


  int? bc;
  int? bp;
  int? diff;

  DocumentReference? ref;

  RankingPerDay({this.chType, this.teamName, this.teamAffiliate, this.day, this.jo, this.g, this.n, this.p, this.pts, this.rank, this.bc, this.bp, this.diff});

  RankingPerDay.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    ref = snapshot.reference;
    Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;

    if(map![keyRankingPerDayChType] != null) {
      chType = map[keyRankingPerDayChType];
    } else {
      chType = '';
    }
    competitionID = snapshot.get(keyRankingPerDayCompetitionID);
    poule = snapshot.get(keyRankingPerDayPoule);
    teamName = snapshot.get(keyRankingPerDayTeamName);
    teamAffiliate = snapshot.get(keyRankingPerDayTeamAffiliate);
    seasonID = snapshot.get(keyRankingPerDaySeasonID);
    day = snapshot.get(keyRankingPerDayDay);
    nbTeams = snapshot.get(keyRankingPerDayNbTeams);
    jo = snapshot.get(keyRankingPerDayJo);
    g = snapshot.get(keyRankingPerDayG);
    n = snapshot.get(keyRankingPerDayN);
    p = snapshot.get(keyRankingPerDayP);
    pts = snapshot.get(keyRankingPerDayPts);
    rank = snapshot.get(keyRankingPerDayRank);
    bc = snapshot.get(keyRankingPerDayBc);
    bp = snapshot.get(keyRankingPerDayBp);
  }

  @override
  String toString() {
    return 'RankingPerDay => chType=$chType ' +
      'competitionID=$competitionID ' +
      'poule=$poule ' +
      'teamName=$teamName ' +
      'teamAffiliate=$teamAffiliate ' +
      'seasonID=$seasonID ' +
      'day=$day ' +
      'nbTeams=$nbTeams ' +
      'jo=$jo ' +
      'g=$g ' +
      'n=$n ' +
      'p=$p ' +
      'pts=$pts ' +
      'rank=$rank ' +
      'bc=$bc ' +
      'bp=$bp';
  }

}
