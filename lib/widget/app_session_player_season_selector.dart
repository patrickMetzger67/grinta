import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/season.dart';
import '../util/app_theme.dart';

import 'app_session_player_avatar.dart';
import '../provider/appSession.dart';

class AppSessionPlayerSeasonSelector extends StatelessWidget {
  const AppSessionPlayerSeasonSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        final Map<String, Player> playerMap = appSession.currentUserPlayers;
        final List<Player> playerList = playerMap.values.toList()
          ..sort((a, b) {
            final aName = _playerLabel(context, a).toLowerCase();
            final bName = _playerLabel(context, b).toLowerCase();
            return aName.compareTo(bName);
          });

        if (playerList.isEmpty) {
          return const SizedBox.shrink();
        }

        final Player selectedPlayer = appSession.selectedPlayer ?? playerList.first;
        final String selectedPlayerId = selectedPlayer.keyMember!;

        final Map<String, Season> seasonMap =
        appSession.getSeasonsForPlayer(selectedPlayerId);

        final List<Season> seasonList = seasonMap.values.toList()
          ..sort((a, b) {
            final aStart = a.startDate;
            final bStart = b.startDate;
            if (aStart == null && bStart == null) return 0;
            if (aStart == null) return 1;
            if (bStart == null) return -1;
            return bStart.compareTo(aStart);
          });

        Season? selectedSeason = appSession.selectedSeason;
        if (selectedSeason?.ref?.id != null &&
            !seasonMap.containsKey(selectedSeason!.ref!.id)) {
          selectedSeason = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (playerList.length > 1)
              _PlayerSelectorField(
                players: playerList,
                selectedPlayerId: selectedPlayerId,
                selectedImageUrls: appSession.playersPhotoUrls[selectedPlayerId],
                onChanged: (value) {
                  if (value == null) return;
                  appSession.setSelectedPlayerId(value);
                },
              )
            else
              _SinglePlayerDisplay(
                player: selectedPlayer,
                imageUrls: appSession.playersPhotoUrls[selectedPlayerId],
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSeason?.ref?.id != null &&
                  seasonMap.containsKey(selectedSeason!.ref!.id)
                  ? selectedSeason.ref!.id
                  : null,
              isExpanded: true,
              decoration: _inputDecoration(
                context,
                hintText: context.l10n.hintSelectSeason,
              ),
              items: seasonList.map((season) {
                final seasonId = season.ref?.id;
                if (seasonId == null) return null;

                return DropdownMenuItem<String>(
                  value: seasonId,
                  child: Text(
                    _seasonLabel(context, season),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );
              }).whereType<DropdownMenuItem<String>>().toList(),
              onChanged: (value) {
                if (value == null) return;
                final season = seasonMap[value];
                if (season != null) {
                  appSession.setSelectedSeason(season);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static InputDecoration _inputDecoration(
      BuildContext context, {
        String? hintText,
      }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: context.appColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: context.appColors.border.withOpacity(0.50),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: context.appColors.border.withOpacity(0.50),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: context.appColors.primary,
        ),
      ),
    );
  }

  String _playerLabel(BuildContext context, Player player) {
    final firstName = player.firstName ?? '';
    final lastName = player.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : context.l10n.entityPlayer;
  }

  String _seasonLabel(BuildContext context, Season season) {
    if (season.name != null && season.name!.trim().isNotEmpty) {
      return season.name!.trim();
    }

    final start = season.startDate?.toDate();
    final end = season.endDate?.toDate();

    if (start != null && end != null) {
      return '${start.year} / ${end.year}';
    }

    if (season.ref?.id != null) {
      return season.ref!.id;
    }

    return context.l10n.entitySeason;
  }
}

class _PlayerSelectorField extends StatelessWidget {
  final List<Player> players;
  final String selectedPlayerId;
  final List<String>? selectedImageUrls;
  final ValueChanged<String?> onChanged;

  const _PlayerSelectorField({
    required this.players,
    required this.selectedPlayerId,
    required this.selectedImageUrls,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Player selectedPlayer = players.firstWhere(
          (p) => p.keyMember == selectedPlayerId,
      orElse: () => players.first,
    );

    return Row(
      children: [
        AppSessionPlayerAvatar(
          player: selectedPlayer,
          imageUrls: selectedImageUrls,
          radius: 18,
          watchSessionForStaleWebAvatar: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedPlayerId,
            isExpanded: true,
            decoration: AppSessionPlayerSeasonSelector._inputDecoration(context),
            items: players.map((player) {
              final playerId = player.keyMember!;
              return DropdownMenuItem<String>(
                value: playerId,
                child: _PlayerDropdownItem(player: player),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SinglePlayerDisplay extends StatelessWidget {
  final Player player;
  final List<String>? imageUrls;

  const _SinglePlayerDisplay({
    required this.player,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border.withOpacity(0.50),
        ),
      ),
      child: Row(
        children: [
          AppSessionPlayerAvatar(
            player: player,
            imageUrls: imageUrls,
            radius: 18,
            watchSessionForStaleWebAvatar: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _playerLabel(context, player),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  String _playerLabel(BuildContext context, Player player) {
    final firstName = player.firstName ?? '';
    final lastName = player.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : context.l10n.entityPlayer;
  }
}

class _PlayerDropdownItem extends StatelessWidget {
  final Player player;

  const _PlayerDropdownItem({
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _playerLabel(context, player),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  String _playerLabel(BuildContext context, Player player) {
    final firstName = player.firstName ?? '';
    final lastName = player.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : context.l10n.entityPlayer;
  }
}
