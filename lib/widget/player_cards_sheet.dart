import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/highlight_type_icons.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:intl/intl.dart';

/// Opens the player disciplinary-cards restitution list.
Future<void> showPlayerCardsSheet(
  BuildContext context, {
  required List<PlayerCardEntry> entries,
  MatchService? matchService,
}) {
  Widget buildSheet() {
    return PlayerCardsSheet(
      entries: entries,
      matchService: matchService,
    );
  }

  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: buildSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => buildSheet(),
  );
}

class PlayerCardsSheet extends StatefulWidget {
  const PlayerCardsSheet({
    super.key,
    required this.entries,
    this.matchService,
  });

  static const Key sheetKey = Key('playerCardsSheet');

  final List<PlayerCardEntry> entries;
  final MatchService? matchService;

  @override
  State<PlayerCardsSheet> createState() => _PlayerCardsSheetState();
}

class _PlayerCardsSheetState extends State<PlayerCardsSheet> {
  bool _loading = true;
  Object? _error;
  Map<String, models.Match?> _matchesById = const <String, models.Match?>{};

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final ids = widget.entries
        .map((entry) => entry.matchId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _matchesById = const <String, models.Match?>{};
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final service = widget.matchService ?? MatchService();
    try {
      final results = await Future.wait(
        ids.map((id) async {
          try {
            return MapEntry(id, await service.getMatchById(id));
          } catch (_) {
            return MapEntry(id, null);
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        _matchesById = Map<String, models.Match?>.fromEntries(results);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<PlayerCardEntry> get _sortedEntries {
    final entries = List<PlayerCardEntry>.from(widget.entries);
    entries.sort((a, b) {
      final aDate = _matchSortDate(a.matchId);
      final bDate = _matchSortDate(b.matchId);
      if (aDate != null && bDate != null) {
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) return byDate;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }

      final byMinute = b.time.compareTo(a.time);
      if (byMinute != 0) return byMinute;
      return b.extraTime.compareTo(a.extraTime);
    });
    return entries;
  }

  DateTime? _matchSortDate(String matchId) {
    final match = _matchesById[matchId.trim()];
    if (match == null) return null;
    final fromTimestamp = match.timestamp?.toDate();
    if (fromTimestamp != null) return fromTimestamp;
    return parseMatchDateCh(match.dateCh);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * (kIsWeb ? 0.85 : 0.78);

    return SafeArea(
      key: PlayerCardsSheet.sheetKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.playerCardsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.playerCardsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, l10n, colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    AppColors colors,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          l10n.playerCardsLoadError(_error.toString()),
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.danger),
        ),
      );
    }

    final entries = _sortedEntries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          l10n.playerCardsEmpty,
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _PlayerCardListTile(
          entry: entry,
          match: _matchesById[entry.matchId.trim()],
        );
      },
    );
  }
}

class _PlayerCardListTile extends StatelessWidget {
  const _PlayerCardListTile({
    required this.entry,
    required this.match,
  });

  final PlayerCardEntry entry;
  final models.Match? match;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final actionType = actionTypeForPlayerCardType(entry.type);
    final iconStyle = actionType == null
        ? HighlightTypeIconStyle(
            icon: Icons.style_rounded,
            color: colors.textSecondary,
          )
        : HighlightTypeIcons.forActionType(context, actionType);

    final typeLabel = entry.type == playerCardTypeRed
        ? l10n.playerCardsTypeRed
        : entry.type == playerCardTypeYellow
            ? l10n.playerCardsTypeYellow
            : entry.type;
    final purgedLabel =
        entry.isPurged ? l10n.playerCardsPurged : l10n.playerCardsNotPurged;
    final matchTitle = playerCardMatchTitle(
      team1: match?.team1,
      team2: match?.team2,
      fallback: l10n.playerCardsUnknownMatch,
    );
    final dateLabel = _formatMatchDate(match, locale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightTypeIconBadge(style: iconStyle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  l10n.playerCardsEntryMeta(
                    typeLabel,
                    playerCardMinuteLabel(entry),
                    purgedLabel,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchDate(models.Match? match, String locale) {
    if (match == null) return '';
    final dateCh = match.dateCh?.trim() ?? '';
    if (dateCh.isNotEmpty) return dateCh;
    final timestamp = match.timestamp?.toDate();
    if (timestamp == null) return '';
    return DateFormat.yMMMd(locale).format(timestamp);
  }
}
