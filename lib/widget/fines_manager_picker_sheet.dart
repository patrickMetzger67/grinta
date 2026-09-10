import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/team_fines_manager_filter.dart';
import 'package:grinta/widget/player_name_filter_field.dart';

/// Picks the team fines manager from the already-loaded roster.
///
/// Returns `''` for « Non désigné », a member id when a player is tapped,
/// or `null` if the sheet is dismissed.
Future<String?> showFinesManagerPickerSheet(
  BuildContext context, {
  required List<Player> players,
  String? currentId,
}) {
  final colors = context.appColors;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FinesManagerPickerSheet(
      players: players,
      currentId: currentId,
    ),
  );
}

class FinesManagerPickerSheet extends StatefulWidget {
  const FinesManagerPickerSheet({
    super.key,
    required this.players,
    this.currentId,
  });

  static const Key sheetKey = ValueKey<String>('fines-manager-picker-sheet');
  static const Key noneKey = ValueKey<String>('fines-manager-picker-none');

  static Key playerKey(String memberId) =>
      ValueKey<String>('fines-manager-picker-player-$memberId');

  final List<Player> players;
  final String? currentId;

  @override
  State<FinesManagerPickerSheet> createState() =>
      _FinesManagerPickerSheetState();
}

class _FinesManagerPickerSheetState extends State<FinesManagerPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  TeamFinesManagerCandidate _candidateFor(
    Player player,
    AppLocalizations l10n,
  ) {
    return TeamFinesManagerCandidate(
      memberId: effectiveMemberId(player) ?? '',
      firstName: player.firstName ?? '',
      lastName: player.lastName ?? '',
      displayName: playerDisplayName(
        player,
        unknownLabel: l10n.entityPlayer,
      ),
    );
  }

  bool _playerMatches(Player player, String query, AppLocalizations l10n) {
    return finesManagerCandidateMatches(_candidateFor(player, l10n), query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final double height = (media.size.height - media.viewInsets.bottom) * 0.72;
    final String? currentId = widget.currentId?.trim();
    final bool noneSelected = currentId == null || currentId.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        key: FinesManagerPickerSheet.sheetKey,
        height: height,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l10n.teamFinesManagerTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PlayerNameFilterField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  padding: const EdgeInsets.only(bottom: 8),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    final String query = value.text;
                    final List<Player> filtered = widget.players
                        .where(
                          (player) => _playerMatches(player, query, l10n),
                        )
                        .toList(growable: false);
                    final bool showEmptyRosterHint =
                        widget.players.isEmpty && query.trim().isEmpty;
                    final bool showNoMatchHint =
                        widget.players.isNotEmpty && filtered.isEmpty;

                    return ListView.builder(
                      itemCount: 1 +
                          filtered.length +
                          (showEmptyRosterHint || showNoMatchHint ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ListTile(
                            key: FinesManagerPickerSheet.noneKey,
                            leading: Icon(
                              Icons.person_off_outlined,
                              color: colors.textSecondary,
                            ),
                            title: Text(l10n.teamFinesManagerNone),
                            selected: noneSelected,
                            onTap: () => Navigator.of(context).pop(''),
                          );
                        }

                        final int playerIndex = index - 1;
                        if (playerIndex < filtered.length) {
                          final Player player = filtered[playerIndex];
                          final String memberId =
                              effectiveMemberId(player) ?? '';
                          return ListTile(
                            key: FinesManagerPickerSheet.playerKey(
                              memberId.isEmpty ? '$playerIndex' : memberId,
                            ),
                            leading: Icon(
                              Icons.person_outline_rounded,
                              color: colors.primary,
                            ),
                            title: Text(
                              playerDisplayName(
                                player,
                                unknownLabel: l10n.entityPlayer,
                              ),
                            ),
                            selected: !noneSelected &&
                                playerMemberLookupIds(player)
                                    .contains(currentId),
                            onTap: () => Navigator.of(context).pop(memberId),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Text(
                            showEmptyRosterHint
                                ? l10n.emptyNoPlayerForTeam
                                : l10n.adminPlayersSearchEmpty,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
