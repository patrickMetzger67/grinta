class MatchStatHighLight {
  String? player;
  String? incomingPlayer;
  String? team;
  int? time;
  String? type;

  MatchStatHighLight({
    this.player = '',
    this.incomingPlayer = '',
    this.team = '',
    this.time = 0,
    this.type = '',
  });

  MatchStatHighLight.fromMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};

    team = _stringFromAny(
      data['team'] ??
          data['teamName'] ??
          data['club'] ??
          data['side'],
    );

    player = _stringFromAny(
      data['player'] ??
          data['playerName'] ??
          data['outgoingPlayer'] ??
          data['playerOut'] ??
          data['outPlayer'] ??
          data['sortant'],
    );

    incomingPlayer = _stringFromAny(
      data['incomingPlayer'] ??
          data['incoming_player'] ??
          data['incoming'] ??
          data['incomingName'] ??
          data['incomingPlayerName'] ??
          data['playerIn'] ??
          data['inPlayer'] ??
          data['entrant'] ??
          data['substitute'] ??
          data['assist'],
    );

    time = _intFromAny(
      data['time'] ?? data['minute'] ?? data['elapsed'],
    );

    type = _stringFromAny(
      data['type'] ?? data['eventType'] ?? data['detail'] ?? data['label'],
    );
  }

  @override
  String toString() {
    return 'Highlight => team=$team '
        'player=$player '
        'time=$time '
        'type=$type '
        'incomingPlayer=$incomingPlayer';
  }
}

class MatchStatPlayer {
  String? team;
  String? player;
  String? shirt;

  MatchStatPlayer({
    this.team = '',
    this.player = '',
    this.shirt = '',
  });

  MatchStatPlayer.fromMap(Map<String, dynamic>? map, String? selectedTeam) {
    final data = map ?? <String, dynamic>{};

    team = selectedTeam ?? '';
    player = _stringFromAny(
      data['name'] ?? data['player'] ?? data['playerName'] ?? data['nom'],
    );
    shirt = _stringFromAny(
      data['shirt'] ?? data['number'] ?? data['shirtNumber'] ?? data['numero'],
    );
  }

  @override
  String toString() {
    return 'Player => team=$team '
        'name=$player '
        'shirt=$shirt';
  }
}

class MatchStats {
  String? matchId;
  List<MatchStatHighLight>? highlights = [];
  List<MatchStatPlayer>? titulars = [];
  List<MatchStatPlayer>? substitutes = [];

  MatchStats({
    this.matchId,
    this.highlights,
    this.titulars,
    this.substitutes,
  });

  MatchStats.fromMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};

    matchId = _stringFromAny(data['id'] ?? data['matchId']);
    highlights = <MatchStatHighLight>[];
    titulars = <MatchStatPlayer>[];
    substitutes = <MatchStatPlayer>[];

    final rawHighlights = data['highLights'] ?? data['highlights'] ?? data['events'];
    if (rawHighlights is List) {
      for (final item in rawHighlights) {
        if (item is Map) {
          highlights!.add(
            MatchStatHighLight.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawPlayers = data['players'];
    if (rawPlayers is List) {
      for (final teamBlock in rawPlayers) {
        if (teamBlock is! Map) continue;

        final teamData = Map<String, dynamic>.from(teamBlock);
        final team = _stringFromAny(teamData['team'] ?? teamData['teamName']);

        final rawTitulars = teamData['titulars'] ?? teamData['starters'];
        if (rawTitulars is List) {
          for (final item in rawTitulars) {
            if (item is Map) {
              titulars!.add(
                MatchStatPlayer.fromMap(Map<String, dynamic>.from(item), team),
              );
            }
          }
        }

        final rawSubstitutes = teamData['substitutes'] ?? teamData['subs'];
        if (rawSubstitutes is List) {
          for (final item in rawSubstitutes) {
            if (item is Map) {
              substitutes!.add(
                MatchStatPlayer.fromMap(Map<String, dynamic>.from(item), team),
              );
            }
          }
        }
      }
    }
  }

  @override
  String toString() {
    return 'MatchStats => id=$matchId '
        'highlights=${highlights.toString()} '
        'titulars=${titulars.toString()} '
        'substitutes=${substitutes.toString()}';
  }
}

String _stringFromAny(dynamic value) {
  if (value == null) return '';

  if (value is String) {
    return value.trim();
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  if (value is Map) {
    final name = value['name'] ??
        value['playerName'] ??
        value['displayName'] ??
        value['shortName'] ??
        value['label'];
    return _stringFromAny(name);
  }

  return value.toString().trim();
}

int _intFromAny(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();

  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  return 0;
}
