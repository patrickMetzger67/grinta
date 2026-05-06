
class MatchStatHighLight {
  String? player;
  String? incomingPlayer;
  String? team;
  int? time;
  String? type;

  MatchStatHighLight({
    this.player='',
    this.incomingPlayer='',
    this.team='',
    this.time=0,
    this.type=''
  });
  MatchStatHighLight.fromMap(Map<String,dynamic>? map) {

    if(map!['team'] != null) {
      team = map['team'];
    } else {
      team = '';
    }
    if(map['player'] != null) {
      player = map['player'];
    } else {
      player = '';
    }
    if(map['time'] != null) {
      time = map['time'];
    } else {
      time = 0;
    }
    if(map['type'] != null) {
      type = map['type'];
    } else {
      type = '';
    }
    if(map['incomingPlayer'] != null) {
      incomingPlayer = map['incomingPlayer'];
    } else {
      incomingPlayer = '';
    }
  }
  @override
  String toString() {
    return 'Highlight => team=$team ' +
        'player=$player ' +
        'time=$time ' +
        'type=$type ' +
        'incomingPlayer=$incomingPlayer';
  }
}

class MatchStatPlayer {
  String? team;
  String? player;
  String? shirt;

  MatchStatPlayer({
    this.team='',
    this.player='',
    this.shirt='',
  });

  MatchStatPlayer.fromMap(Map<String,dynamic>? map, String? _team) {
    team = _team;
    if(map!['name'] != null) {
      player = map['name'];
    }
    if(map['shirt'] != null) {
      shirt = map['shirt'];
    }
  }
  @override
  String toString() {
    return 'Player => team=$team ' +
         'name=$player ' +
        'shirt=$shirt';
  }

}

class MatchStats {
  String? matchId;
  List<MatchStatHighLight>? highlights=[];
  List<MatchStatPlayer>? titulars=[];
  List<MatchStatPlayer>? substitutes=[];

  MatchStats({
    this.matchId,
    this.highlights,
    this.titulars,
    this.substitutes,
  });

  MatchStats.fromMap(Map<String,dynamic>? map) {

    if(map!['id'] != null) {
      matchId = map['id'];
    } else {
      matchId = '';
    }

    if(map['highLights'] != null) {
      List<dynamic> tmpHighLights= map['highLights'];
      for(int i=0; i < tmpHighLights.length;i++) {
        MatchStatHighLight _matchStatHighLight = MatchStatHighLight.fromMap(tmpHighLights[i]);
        highlights!.add(_matchStatHighLight);
      }
    }
    if(map['players'] != null) {
      List<dynamic> tmpPlayers= map['players'];
      for(int i=0; i < tmpPlayers.length;i++) {
        String team = tmpPlayers[i]['team'];
        List<dynamic> tmpTitulars= tmpPlayers[i]['titulars'];
        for(int y=0; y < tmpTitulars.length;y++) {
          MatchStatPlayer _matchStatPlayer = MatchStatPlayer.fromMap(tmpTitulars[y],team);
          titulars!.add(_matchStatPlayer);
        }

        List<dynamic> tmpSubstitutes= tmpPlayers[i]['substitutes'];
        for(int y=0; y < tmpSubstitutes.length;y++) {
          MatchStatPlayer _matchStatPlayer = MatchStatPlayer.fromMap(tmpSubstitutes[y],team);
          substitutes!.add(_matchStatPlayer);
        }

      }
    }

  }

  @override
  String toString() {
    return 'MatchStats => id=$matchId ' +
        'highlights=${highlights.toString()} ' +
        'titulars=${titulars.toString()} ' +
        'substitutes=${substitutes.toString()}';
  }

}