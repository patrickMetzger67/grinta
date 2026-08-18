import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/util/app_theme.dart';

class DebugVideoAssociationTeam {
  const DebugVideoAssociationTeam({
    required this.id,
    required this.name,
    this.kitColor,
  });

  final String id;
  final String name;
  final int? kitColor;
}

Future<DebugVideoRosterPlayer?> showDebugVideoPlayerAssociationSheet({
  required BuildContext context,
  required List<DebugVideoAssociationTeam> teams,
  required List<DebugVideoRosterPlayer> roster,
  String? suggestedTeamId,
  bool useRootNavigator = false,
}) {
  final ordered = [...teams]..sort((a, b) {
      if (a.id == suggestedTeamId) return -1;
      if (b.id == suggestedTeamId) return 1;
      return 0;
    });
  return showModalBottomSheet<DebugVideoRosterPlayer>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: useRootNavigator,
    builder: (sheetContext) {
      return _AssociationSheet(
        teams: ordered,
        roster: roster,
        suggestedTeamId: suggestedTeamId,
      );
    },
  );
}

class _AssociationSheet extends StatefulWidget {
  const _AssociationSheet({
    required this.teams,
    required this.roster,
    this.suggestedTeamId,
  });

  final List<DebugVideoAssociationTeam> teams;
  final List<DebugVideoRosterPlayer> roster;
  final String? suggestedTeamId;

  @override
  State<_AssociationSheet> createState() => _AssociationSheetState();
}

class _AssociationSheetState extends State<_AssociationSheet> {
  late String? _teamId;

  @override
  void initState() {
    super.initState();
    final suggested = widget.suggestedTeamId?.trim();
    final ids = widget.teams.map((team) => team.id).toSet();
    bool hasPlayers(String? id) {
      return id != null && widget.roster.any((player) => player.teamId == id);
    }

    if (suggested != null &&
        suggested.isNotEmpty &&
        ids.contains(suggested) &&
        hasPlayers(suggested)) {
      _teamId = suggested;
    } else {
      final withPlayers = widget.teams.where((team) => hasPlayers(team.id));
      if (withPlayers.isNotEmpty) {
        _teamId = withPlayers.first.id;
      } else if (widget.teams.isNotEmpty) {
        _teamId = widget.teams.first.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final players = widget.roster
        .where((player) => _teamId == null || player.teamId == _teamId)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.debugVideoAssociatePlayerTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.teams.map((team) {
                final selected = team.id == _teamId;
                final suggested = team.id == widget.suggestedTeamId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    suggested
                        ? l10n.debugVideoSuggestedTeam(team.name)
                        : team.name,
                  ),
                  avatar: team.kitColor == null
                      ? null
                      : CircleAvatar(
                          backgroundColor: Color(team.kitColor!),
                          radius: 8,
                        ),
                  onSelected: (_) => setState(() => _teamId = team.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: players.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.debugVideoNoRosterToAssociate,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final number = player.number == null
                            ? l10n.debugVideoCompoNoNumber
                            : '#${player.number}';
                        final name = player.displayName.isEmpty
                            ? number
                            : '$number  ${player.displayName}';
                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: player.isSubstitute
                              ? Text(l10n.debugVideoCompoSubs)
                              : Text(l10n.debugVideoCompoStarters),
                          onTap: () => Navigator.of(context).pop(player),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
