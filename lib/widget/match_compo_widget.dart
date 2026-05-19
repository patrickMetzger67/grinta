import 'package:flutter/material.dart';

import '../model/matchStats.dart';
import '../util/app_theme.dart';

class MatchCompoWidget extends StatelessWidget {
  final MatchStats? matchStats;
  final String? team1;
  final String? team2;

  const MatchCompoWidget({
    super.key,
    required this.matchStats,
    required this.team1,
    required this.team2,
  });

  @override
  Widget build(BuildContext context) {
    final titulars = matchStats?.titulars ?? <MatchStatPlayer>[];
    final substitutes = matchStats?.substitutes ?? <MatchStatPlayer>[];
    final highlights = matchStats?.highlights ?? <MatchStatHighLight>[];
    final changes = _extractChanges(highlights);

    debugPrint(
      '[MatchCompoWidget] titulars=${titulars.length} '
          'substitutes=${substitutes.length} '
          'highlights=${highlights.length} '
          'changes=${changes.length}',
    );

    for (final change in changes) {
      debugPrint(
        "[MatchCompoWidget] change ${change.minute}' "
            '${change.outgoingPlayer} -> ${change.incomingPlayer} '
            'team="${change.team}" type="${change.type}"',
      );
    }

    final hasComposition = titulars.isNotEmpty || substitutes.isNotEmpty;

    if (!hasComposition) {
      return _CompositionEmptyState(
        icon: Icons.sports_soccer_rounded,
        title: 'Composition non renseignée',
        message: 'Aucune composition n’a été trouvée pour ce match.',
      );
    }

    final teamNames = _resolveTeamNames(
      titulars: titulars,
      substitutes: substitutes,
      team1: team1,
      team2: team2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderCard(
          titularsCount: titulars.length,
          substitutesCount: substitutes.length,
          changesCount: changes.length,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            if (compact) {
              return Column(
                children: [
                  for (int i = 0; i < teamNames.length; i++) ...[
                    _TeamCompositionCard(
                      teamName: teamNames[i],
                      titulars: _filterPlayersByTeam(titulars, teamNames[i]),
                      substitutes: _filterPlayersByTeam(
                        substitutes,
                        teamNames[i],
                      ),
                      changes: changes,
                    ),
                    if (i < teamNames.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < teamNames.length; i++) ...[
                  Expanded(
                    child: _TeamCompositionCard(
                      teamName: teamNames[i],
                      titulars: _filterPlayersByTeam(titulars, teamNames[i]),
                      substitutes: _filterPlayersByTeam(
                        substitutes,
                        teamNames[i],
                      ),
                      changes: changes,
                    ),
                  ),
                  if (i < teamNames.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<String> _resolveTeamNames({
    required List<MatchStatPlayer> titulars,
    required List<MatchStatPlayer> substitutes,
    required String? team1,
    required String? team2,
  }) {
    final teamsFromStats = <String>[];

    void addTeam(String? value) {
      final teamName = _clean(value);
      if (teamName.isEmpty) return;

      final alreadyExists = teamsFromStats.any(
            (team) => _sameTeam(team, teamName),
      );

      if (!alreadyExists) {
        teamsFromStats.add(teamName);
      }
    }

    for (final player in [...titulars, ...substitutes]) {
      addTeam(player.team);
    }

    if (teamsFromStats.isNotEmpty) {
      return teamsFromStats;
    }

    final fallbackTeams = <String>[];

    void addFallback(String value) {
      final teamName = _clean(value);
      if (teamName.isEmpty) return;

      if (!fallbackTeams.any((team) => _sameTeam(team, teamName))) {
        fallbackTeams.add(teamName);
      }
    }

    addFallback(_clean(team1, fallback: 'Équipe 1'));
    addFallback(_clean(team2, fallback: 'Équipe 2'));

    return fallbackTeams;
  }
}

class _HeaderCard extends StatelessWidget {
  final int titularsCount;
  final int substitutesCount;
  final int changesCount;

  const _HeaderCard({
    required this.titularsCount,
    required this.substitutesCount,
    required this.changesCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Composition',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamCompositionCard extends StatelessWidget {
  final String teamName;
  final List<MatchStatPlayer> titulars;
  final List<MatchStatPlayer> substitutes;
  final List<_PlayerChange> changes;

  const _TeamCompositionCard({
    required this.teamName,
    required this.titulars,
    required this.substitutes,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  teamName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PlayerSection(
            title: 'Titulaires',
            icon: Icons.sports_soccer_rounded,
            players: titulars,
            emptyMessage: 'Aucun titulaire renseigné.',
            changes: changes,
          ),
          const SizedBox(height: 14),
          _PlayerSection(
            title: 'Remplaçants',
            icon: Icons.swap_horiz_rounded,
            players: substitutes,
            emptyMessage: 'Aucun remplaçant renseigné.',
            changes: changes,
          ),
        ],
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MatchStatPlayer> players;
  final String emptyMessage;
  final List<_PlayerChange> changes;

  const _PlayerSection({
    required this.title,
    required this.icon,
    required this.players,
    required this.emptyMessage,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title (${players.length})',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < players.length; i++) ...[
                  _PlayerTile(
                    player: players[i],
                    changes: changes,
                  ),
                  if (i < players.length - 1)
                    Divider(
                      height: 12,
                      color: colors.border,
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final MatchStatPlayer player;
  final List<_PlayerChange> changes;

  const _PlayerTile({
    required this.player,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final playerName = _clean(player.player, fallback: 'Joueur non renseigné');
    final shirt = _clean(player.shirt);
    final playerChanges = _findPlayerChanges(player, changes);

    for (final playerChange in playerChanges) {
      debugPrint(
        "[MatchCompoWidget] affichage changement pour \"$playerName\" "
            "=> ${playerChange.label} ${playerChange.minute}'",
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            shirt.isEmpty ? '-' : shirt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (playerChanges.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final playerChange in playerChanges)
                      _ChangeBadge(change: playerChange),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final _PlayerChangeBadge change;

  const _ChangeBadge({
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = change.isIncoming ? colors.success : colors.warning;
    final minuteText = change.minute > 0 ? " ${change.minute}'" : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            change.isIncoming
                ? Icons.login_rounded
                : Icons.logout_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.label}$minuteText',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompositionEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerChange {
  final String team;
  final String outgoingPlayer;
  final String incomingPlayer;
  final int minute;
  final String type;

  const _PlayerChange({
    required this.team,
    required this.outgoingPlayer,
    required this.incomingPlayer,
    required this.minute,
    required this.type,
  });
}

class _PlayerChangeBadge {
  final String label;
  final int minute;
  final bool isIncoming;

  const _PlayerChangeBadge({
    required this.label,
    required this.minute,
    required this.isIncoming,
  });
}

List<_PlayerChange> _extractChanges(List<MatchStatHighLight> highlights) {
  final changes = <_PlayerChange>[];

  for (final highlight in highlights) {
    final outgoingPlayer = _clean(highlight.player);
    final incomingPlayer = _clean(highlight.incomingPlayer);

    if (outgoingPlayer.isEmpty || incomingPlayer.isEmpty) {
      continue;
    }

    changes.add(
      _PlayerChange(
        team: _clean(highlight.team),
        outgoingPlayer: outgoingPlayer,
        incomingPlayer: incomingPlayer,
        minute: highlight.time ?? 0,
        type: _clean(highlight.type),
      ),
    );
  }

  changes.sort((a, b) => a.minute.compareTo(b.minute));
  return changes;
}

List<_PlayerChangeBadge> _findPlayerChanges(
    MatchStatPlayer player,
    List<_PlayerChange> changes,
    ) {
  final badges = <_PlayerChangeBadge>[];

  for (final change in changes) {
    if (_samePlayer(player.player, change.outgoingPlayer)) {
      badges.add(
        _PlayerChangeBadge(
          label: 'Sortie',
          minute: change.minute,
          isIncoming: false,
        ),
      );
    }

    if (_samePlayer(player.player, change.incomingPlayer)) {
      badges.add(
        _PlayerChangeBadge(
          label: 'Entrée',
          minute: change.minute,
          isIncoming: true,
        ),
      );
    }
  }

  return badges;
}

List<MatchStatPlayer> _filterPlayersByTeam(
    List<MatchStatPlayer> players,
    String teamName,
    ) {
  return players.where((player) => _sameTeam(player.team, teamName)).toList();
}

bool _sameTeam(String? left, String? right) {
  return _normalize(left) == _normalize(right);
}

bool _samePlayer(String? left, String? right) {
  final leftName = _normalizePlayerName(left);
  final rightName = _normalizePlayerName(right);

  if (leftName.isEmpty || rightName.isEmpty) return false;
  if (leftName == rightName) return true;

  final leftParts = leftName.split(' ');
  final rightParts = rightName.split(' ');

  if (leftParts.isEmpty || rightParts.isEmpty) return false;
  if (leftParts.first != rightParts.first) return false;

  if (leftParts.length < 2 || rightParts.length < 2) {
    return false;
  }

  final leftLast = leftParts.last;
  final rightLast = rightParts.last;

  if (leftLast == rightLast) return true;

  if (leftLast.length == 1 && rightLast.startsWith(leftLast)) {
    return true;
  }

  if (rightLast.length == 1 && leftLast.startsWith(rightLast)) {
    return true;
  }

  return _playerSignature(leftName) == _playerSignature(rightName);
}

String _playerSignature(String value) {
  final parts = value.split(' ');
  if (parts.isEmpty) return '';

  final first = parts.first;
  final last = parts.length > 1 ? parts.last : '';

  if (last.isEmpty) return first;
  return '$first ${last[0]}';
}

String _normalizePlayerName(String? value) {
  return _clean(value)
      .toLowerCase()
      .replaceAll('.', ' ')
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'[^a-z0-9àâäéèêëîïôöùûüçñ\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalize(String? value) {
  return _clean(value).toLowerCase();
}

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}