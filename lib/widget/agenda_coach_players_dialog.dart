import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:provider/provider.dart';

class AgendaCoachPlayersSelection {
  const AgendaCoachPlayersSelection({
    required this.teamId,
    required this.playersByMemberId,
  });

  final String teamId;
  final Map<String, Player> playersByMemberId;

  Set<String> get memberIds => playersByMemberId.keys.toSet();
}

/// Manager picks a managed team (if several) then one or more roster players
/// whose coach-visible personal sport activities should appear in the agenda.
Future<AgendaCoachPlayersSelection?> showAgendaCoachPlayersDialog(
  BuildContext context, {
  String? initialTeamId,
  Set<String> initiallySelectedMemberIds = const {},
}) {
  return showDialog<AgendaCoachPlayersSelection>(
    context: context,
    builder: (dialogContext) => _AgendaCoachPlayersDialog(
      initialTeamId: initialTeamId,
      initiallySelectedMemberIds: initiallySelectedMemberIds,
    ),
  );
}

class _AgendaCoachPlayersDialog extends StatefulWidget {
  const _AgendaCoachPlayersDialog({
    this.initialTeamId,
    this.initiallySelectedMemberIds = const {},
  });

  final String? initialTeamId;
  final Set<String> initiallySelectedMemberIds;

  @override
  State<_AgendaCoachPlayersDialog> createState() =>
      _AgendaCoachPlayersDialogState();
}

class _AgendaCoachPlayersDialogState extends State<_AgendaCoachPlayersDialog> {
  final TeamPlayersService _playersService = TeamPlayersService();

  String? _selectedTeamId;
  List<Player> _players = const [];
  final Set<String> _selectedMemberIds = <String>{};
  bool _loadingPlayers = false;
  String? _playersError;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds.addAll(
      widget.initiallySelectedMemberIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final teams = context.read<AppSession>().managerTeamsForSelectedSeason;
      if (teams.isEmpty) return;
      final initial = widget.initialTeamId?.trim();
      final match = teams.cast<Team?>().firstWhere(
            (team) => (team?.keyTeam?.trim() ?? '') == initial,
            orElse: () => null,
          );
      final teamId = (match?.keyTeam?.trim().isNotEmpty == true)
          ? match!.keyTeam!.trim()
          : (teams.first.keyTeam?.trim() ?? '');
      if (teamId.isEmpty) return;
      _onTeamChanged(teamId);
    });
  }

  Future<void> _onTeamChanged(String teamId) async {
    setState(() {
      _selectedTeamId = teamId;
      _loadingPlayers = true;
      _playersError = null;
      _players = const [];
    });

    try {
      final players = await _playersService.loadPlayers(teamId: teamId);
      if (!mounted) return;
      final availableIds = <String>{
        for (final player in players)
          if ((effectiveMemberId(player) ?? '').isNotEmpty)
            effectiveMemberId(player)!,
      };
      setState(() {
        _players = players;
        _selectedMemberIds.removeWhere((id) => !availableIds.contains(id));
        _loadingPlayers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _playersError = e.toString();
        _loadingPlayers = false;
      });
    }
  }

  void _toggleMember(String memberId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedMemberIds.add(memberId);
      } else {
        _selectedMemberIds.remove(memberId);
      }
    });
  }

  void _submit() {
    final teamId = _selectedTeamId?.trim() ?? '';
    if (teamId.isEmpty) return;

    final selected = <String, Player>{};
    for (final player in _players) {
      final id = effectiveMemberId(player)?.trim() ?? '';
      if (id.isNotEmpty && _selectedMemberIds.contains(id)) {
        selected[id] = player;
      }
    }
    Navigator.of(context).pop(
      AgendaCoachPlayersSelection(
        teamId: teamId,
        playersByMemberId: selected,
      ),
    );
  }

  String _teamLabel(Team team) {
    final name = (team.name ?? '').trim();
    if (name.isNotEmpty) return name;
    return team.keyTeam?.trim() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final teams = context.watch<AppSession>().managerTeamsForSelectedSeason;
    final showTeamDropdown = teams.length > 1;

    return AlertDialog(
      backgroundColor: colors.card,
      title: Text(l10n.agendaCoachPlayersTitle),
      content: SizedBox(
        width: 420,
        child: teams.isEmpty
            ? Text(l10n.agendaCoachPlayersNoTeams)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.agendaCoachPlayersSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  if (showTeamDropdown) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.agendaCoachPlayersTeam,
                      ),
                      items: [
                        for (final team in teams)
                          if ((team.keyTeam?.trim() ?? '').isNotEmpty)
                            DropdownMenuItem(
                              value: team.keyTeam!.trim(),
                              child: Text(
                                _teamLabel(team),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _onTeamChanged(value);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    l10n.agendaCoachPlayersPlayers,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingPlayers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_playersError != null)
                    Text(
                      l10n.agendaCoachPlayersLoadError,
                      style: TextStyle(color: colors.danger),
                    )
                  else if (_players.isEmpty)
                    Text(
                      l10n.agendaCoachPlayersEmptyRoster,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                            final player = _players[index];
                            final memberId =
                                effectiveMemberId(player)?.trim() ?? '';
                            if (memberId.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final selected =
                                _selectedMemberIds.contains(memberId);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (value) =>
                                  _toggleMember(memberId, value),
                              secondary: PlayerPhoto(
                                player: player,
                                radius: 18,
                              ),
                              title: Text(playerDisplayName(player)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        if (_selectedMemberIds.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                AgendaCoachPlayersSelection(
                  teamId: _selectedTeamId?.trim() ?? '',
                  playersByMemberId: const {},
                ),
              );
            },
            child: Text(l10n.agendaCoachPlayersClear),
          ),
        FilledButton(
          onPressed: teams.isEmpty || _selectedTeamId == null
              ? null
              : _submit,
          child: Text(l10n.actionValidate),
        ),
      ],
    );
  }
}
