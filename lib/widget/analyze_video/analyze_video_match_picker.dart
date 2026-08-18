import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/widget/analyze_video/analyze_video_kit_color_picker.dart';

class DebugVideoMatchPicker extends StatelessWidget {
  const DebugVideoMatchPicker({
    super.key,
    required this.dateController,
    required this.dateInvalid,
    required this.loadingMatches,
    required this.matchesFailed,
    required this.hasManagedTeams,
    required this.matches,
    required this.selectedMatch,
    required this.loadingCompos,
    required this.compos,
    required this.onDateSubmitted,
    required this.onPickDate,
    required this.onSelectMatch,
    required this.team1KitColor,
    required this.team2KitColor,
    required this.onTeam1KitColor,
    required this.onTeam2KitColor,
    required this.refereeKitColor,
    required this.onRefereeKitColor,
    this.detectedJerseyNumbers = const <int>{},
    this.detectedTeamJerseyKeys = const <String>{},
    this.associatedPlayerIds = const <String>{},
  });

  final TextEditingController dateController;
  final bool dateInvalid;
  final bool loadingMatches;
  final bool matchesFailed;
  final bool hasManagedTeams;
  final List<Match> matches;
  final Match? selectedMatch;
  final bool loadingCompos;
  final List<MatchCompo> compos;
  final ValueChanged<String> onDateSubmitted;
  final VoidCallback onPickDate;
  final ValueChanged<Match> onSelectMatch;
  final int? team1KitColor;
  final int? team2KitColor;
  final ValueChanged<int> onTeam1KitColor;
  final ValueChanged<int> onTeam2KitColor;
  final int? refereeKitColor;
  final ValueChanged<int> onRefereeKitColor;
  final Set<int> detectedJerseyNumbers;
  final Set<String> detectedTeamJerseyKeys;
  final Set<String> associatedPlayerIds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.debugVideoMatchSectionTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.debugVideoMatchDateLabel,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9/\-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.debugVideoMatchDateHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: onDateSubmitted,
                    onEditingComplete: () =>
                        onDateSubmitted(dateController.text),
                    onTapOutside: (_) =>
                        onDateSubmitted(dateController.text),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.debugVideoMatchDateLabel,
                  onPressed: onPickDate,
                  icon: Icon(
                    Icons.calendar_today_rounded,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            if (dateInvalid) ...[
              const SizedBox(height: 8),
              Text(
                l10n.debugVideoMatchDateInvalid,
                style: textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.debugVideoMatchListTitle,
              style: textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (loadingMatches)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (matchesFailed)
              Text(
                l10n.debugVideoMatchLoadError,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else if (!hasManagedTeams)
              Text(
                l10n.debugVideoMatchNoManagedTeams,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else if (matches.isEmpty)
              Text(
                l10n.debugVideoMatchEmpty,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else
              ...matches.map((match) {
                final selected = match.id == selectedMatch?.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.background,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selected ? colors.primary : colors.border,
                        ),
                      ),
                      title: Text(
                        debugVideoMatchLabel(match),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: selected,
                      onTap: () => onSelectMatch(match),
                    ),
                  ),
                );
              }),
            if (selectedMatch != null) ...[
              const SizedBox(height: 12),
              DebugVideoKitColorRow(
                team1Name: (selectedMatch!.team1?.trim().isNotEmpty ?? false)
                    ? selectedMatch!.team1!.trim()
                    : l10n.debugVideoTeam1Fallback,
                team2Name: (selectedMatch!.team2?.trim().isNotEmpty ?? false)
                    ? selectedMatch!.team2!.trim()
                    : l10n.debugVideoTeam2Fallback,
                team1Color: team1KitColor,
                team2Color: team2KitColor,
                refereeColor: refereeKitColor,
                onTeam1Color: onTeam1KitColor,
                onTeam2Color: onTeam2KitColor,
                onRefereeColor: onRefereeKitColor,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.debugVideoCompoTitle,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.debugVideoCompoOneTeamHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (loadingCompos)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (compos.isEmpty)
                Text(
                  l10n.debugVideoCompoEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                ...compos.map(
                  (compo) => _CompoRoster(
                    match: selectedMatch!,
                    compo: compo,
                    detectedTeamJerseyKeys: detectedTeamJerseyKeys,
                    associatedPlayerIds: associatedPlayerIds,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompoRoster extends StatelessWidget {
  const _CompoRoster({
    required this.match,
    required this.compo,
    required this.detectedTeamJerseyKeys,
    required this.associatedPlayerIds,
  });

  final Match match;
  final MatchCompo compo;
  final Set<String> detectedTeamJerseyKeys;
  final Set<String> associatedPlayerIds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final teamName =
        teamDisplayNameForTeamId(match, compo.teamID) ?? compo.teamID ?? '';
    final roster = debugVideoRosterFromCompo(compo);
    final starters = roster.where((p) => !p.isSubstitute).toList();
    final subs = roster.where((p) => p.isSubstitute).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (starters.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.debugVideoCompoStarters,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: starters
                  .map(
                    (player) => _RosterChip(
                      player: player,
                      detected: isRosterJerseyOnTeam(
                            teamId: player.teamId,
                            number: player.number,
                            keys: detectedTeamJerseyKeys,
                          ) ||
                          isRosterPlayerAssociated(
                            player.playerId,
                            associatedPlayerIds,
                          ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.debugVideoCompoSubs,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: subs
                  .map(
                    (player) => _RosterChip(
                      player: player,
                      detected: isRosterJerseyOnTeam(
                            teamId: player.teamId,
                            number: player.number,
                            keys: detectedTeamJerseyKeys,
                          ) ||
                          isRosterPlayerAssociated(
                            player.playerId,
                            associatedPlayerIds,
                          ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (roster.isEmpty)
            Text(
              l10n.debugVideoCompoEmpty,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _RosterChip extends StatelessWidget {
  const _RosterChip({
    required this.player,
    required this.detected,
  });

  final DebugVideoRosterPlayer player;
  final bool detected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final number = player.number == null
        ? l10n.debugVideoCompoNoNumber
        : '#${player.number}';
    final label = player.displayName.isEmpty
        ? number
        : '$number ${player.displayName}';
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: colors.background,
      side: BorderSide(
        color: detected ? colors.success : colors.border,
        width: detected ? 2 : 1,
      ),
    );
  }
}
