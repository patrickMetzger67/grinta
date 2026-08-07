import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/screen/agenda/agenda_screen.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_matchday_helper.dart';
import 'package:intl/intl.dart';

/// Calendars tab: competition filter and matchday navigator with agenda cards.
class TeamStatsCalendarsTab extends StatefulWidget {
  const TeamStatsCalendarsTab({
    super.key,
    required this.team,
    this.fallbackSeasonId,
    TeamsPerClubService? teamsPerClubService,
    TeamCompetitionStatsService? teamCompetitionStatsService,
  })  : _teamsPerClubService = teamsPerClubService,
        _teamCompetitionStatsService = teamCompetitionStatsService;

  final Team team;
  final String? fallbackSeasonId;
  final TeamsPerClubService? _teamsPerClubService;
  final TeamCompetitionStatsService? _teamCompetitionStatsService;

  @override
  State<TeamStatsCalendarsTab> createState() => _TeamStatsCalendarsTabState();
}

class _TeamStatsCalendarsTabState extends State<TeamStatsCalendarsTab> {
  bool _loadingCompetitions = true;
  bool _loadingMatches = false;
  bool _didInit = false;
  List<TeamStatsCompetitionOption> _options = const [];
  String? _selectedValue;
  List<TeamStatsMatchdayGroup> _matchdays = const [];
  int _selectedMatchdayIndex = 0;
  bool _userSelectedMatchday = false;

  TeamCompetitionStatsService get _statsService =>
      widget._teamCompetitionStatsService ?? TeamCompetitionStatsService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadCompetitions();
    }
  }

  String? _seasonIdForTeam() =>
      teamStatsSeasonIdForTeam(widget.team, widget.fallbackSeasonId);

  Future<void> _loadCompetitions() async {
    final options = await loadTeamStatsCompetitionOptions(
      team: widget.team,
      l10n: context.l10n,
      fallbackSeasonId: widget.fallbackSeasonId,
      teamsPerClubService: widget._teamsPerClubService,
      includeAllOption: false,
    );

    if (!mounted) return;

    final selectedValue = options.isNotEmpty ? options.first.value : null;
    setState(() {
      _loadingCompetitions = false;
      _options = options;
      _selectedValue = selectedValue;
      _matchdays = const [];
      _selectedMatchdayIndex = 0;
    });

    if (selectedValue != null) {
      await _loadMatches(selectedValue);
    }
  }

  Future<void> _loadMatches(String competitionValue) async {
    final seasonId = _seasonIdForTeam();
    if (seasonId == null) {
      if (!mounted) return;
      setState(() {
        _matchdays = const [];
        _selectedMatchdayIndex = 0;
      });
      return;
    }

    setState(() => _loadingMatches = true);

    final matches = await _statsService.loadCompetitionCalendarMatches(
      team: widget.team,
      seasonId: seasonId,
      competitionUrl: competitionValue,
    );

    if (!mounted) return;

    setState(() {
      _loadingMatches = false;
      _matchdays = groupMatchesByMatchday(
        matches,
        teamId: widget.team.keyTeam,
        clubId: widget.team.clubId,
      );
      if (!_userSelectedMatchday) {
        _selectedMatchdayIndex = defaultMatchdayIndex(_matchdays);
      }
    });
  }

  void _onCompetitionChanged(String value) {
    setState(() {
      _selectedValue = value;
      _matchdays = const [];
      _selectedMatchdayIndex = 0;
      _userSelectedMatchday = false;
    });
    _loadMatches(value);
  }

  void _goToPreviousMatchday() {
    if (_selectedMatchdayIndex <= 0) {
      return;
    }
    setState(() {
      _userSelectedMatchday = true;
      _selectedMatchdayIndex--;
    });
  }

  void _goToNextMatchday() {
    if (_selectedMatchdayIndex >= _matchdays.length - 1) {
      return;
    }
    setState(() {
      _userSelectedMatchday = true;
      _selectedMatchdayIndex++;
    });
  }

  void _goToMatchday(int index) {
    if (index < 0 || index >= _matchdays.length) {
      return;
    }
    setState(() {
      _userSelectedMatchday = true;
      _selectedMatchdayIndex = index;
    });
  }

  TeamStatsMatchdayGroup? get _selectedMatchday {
    if (_matchdays.isEmpty ||
        _selectedMatchdayIndex < 0 ||
        _selectedMatchdayIndex >= _matchdays.length) {
      return null;
    }
    return _matchdays[_selectedMatchdayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_loadingCompetitions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.teamStatsNoCompetitions,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final selectedValue = _selectedValue;
    if (selectedValue == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.teamStatsNoCompetitions,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TeamStatsCompetitionDropdown(
          options: _options,
          selectedValue: selectedValue,
          onChanged: _onCompetitionChanged,
        ),
        const SizedBox(height: 20),
        if (_loadingMatches)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_matchdays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
            child: Text(
              l10n.teamStatsCalendarNoMatchdays,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else ...[
          _MatchdayNavigator(
            matchdays: _matchdays,
            selectedIndex: _selectedMatchdayIndex,
            onPrevious: _goToPreviousMatchday,
            onNext: _goToNextMatchday,
            onMatchdaySelected: _goToMatchday,
          ),
          const SizedBox(height: 16),
          _MatchdayDatesSection(group: _selectedMatchday!),
          const SizedBox(height: 16),
          _MatchdayMatchesList(
            team: widget.team,
            group: _selectedMatchday!,
          ),
        ],
      ],
    );
  }
}

class _MatchdayNavigator extends StatelessWidget {
  const _MatchdayNavigator({
    required this.matchdays,
    required this.selectedIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onMatchdaySelected,
  });

  final List<TeamStatsMatchdayGroup> matchdays;
  final int selectedIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onMatchdaySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isFirst = selectedIndex <= 0;
    final isLast = selectedIndex >= matchdays.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.navNavigation,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MatchdayNavButton(
                icon: Icons.chevron_left_rounded,
                enabled: !isFirst,
                onPressed: onPrevious,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    filled: true,
                    fillColor: colors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedIndex,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      items: [
                        for (var index = 0; index < matchdays.length; index++)
                          DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              matchdayGroupLabel(l10n, matchdays[index]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (index) {
                        if (index == null) {
                          return;
                        }
                        onMatchdaySelected(index);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MatchdayNavButton(
                icon: Icons.chevron_right_rounded,
                enabled: !isLast,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchdayNavButton extends StatelessWidget {
  const _MatchdayNavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: enabled ? colors.background : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _MatchdayDatesSection extends StatelessWidget {
  const _MatchdayDatesSection({required this.group});

  final TeamStatsMatchdayGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final dates = group.uniqueDates;

    final datesLabel = dates.isEmpty
        ? l10n.teamStatsCalendarNoMatchDates
        : dates
            .map((date) => DateFormat.yMMMMd(locale).format(date))
            .join(l10n.teamStatsCalendarDateSeparator);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamStatsCalendarDatesLabel,
          style: textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          datesLabel,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MatchdayMatchesList extends StatelessWidget {
  const _MatchdayMatchesList({
    required this.team,
    required this.group,
  });

  final Team team;
  final TeamStatsMatchdayGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final sortedMatches = sortMatchesByDateTime(group.matches);
    final listEntries = _buildListEntries(sortedMatches, team);

    if (listEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.teamStatsCalendarNoMatchesForMatchday,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < listEntries.length; index++) ...[
          if (index > 0) ...[
            if (listEntries[index] is _MatchdayDayHeaderEntry)
              const SizedBox(height: 14)
            else if (listEntries[index - 1] is! _MatchdayDayHeaderEntry)
              const SizedBox(height: 10)
            else
              const SizedBox(height: 8),
          ],
          switch (listEntries[index]) {
            _MatchdayDayHeaderEntry(:final date) =>
              _MatchdayMatchDateLabel(date: date, locale: locale),
            _MatchdayCardEntry(:final item) => AgendaItemCard(
                  key: ValueKey(item.id),
                  item: item,
                ),
          },
        ],
      ],
    );
  }

  /// One date header per day, then match cards below (agenda day-row pattern).
  static List<_MatchdayListEntry> _buildListEntries(
    List<Match> sortedMatches,
    Team team,
  ) {
    final entries = <_MatchdayListEntry>[];
    DateTime? lastDay;

    for (final match in sortedMatches) {
      final item = AgendaService.matchToAgendaItem(
        match: match,
        team: team,
      );
      if (item == null) {
        continue;
      }

      final date = matchDateForTeamStats(match);
      if (date != null) {
        final day = DateUtils.dateOnly(date);
        if (lastDay == null || day != lastDay) {
          entries.add(_MatchdayDayHeaderEntry(day));
          lastDay = day;
        }
      }
      entries.add(_MatchdayCardEntry(item));
    }

    return entries;
  }
}

sealed class _MatchdayListEntry {
  const _MatchdayListEntry();
}

final class _MatchdayDayHeaderEntry extends _MatchdayListEntry {
  const _MatchdayDayHeaderEntry(this.date);

  final DateTime date;
}

final class _MatchdayCardEntry extends _MatchdayListEntry {
  const _MatchdayCardEntry(this.item);

  final AgendaItem item;
}

class _MatchdayMatchDateLabel extends StatelessWidget {
  const _MatchdayMatchDateLabel({
    required this.date,
    required this.locale,
  });

  final DateTime date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday =
        DateUtils.dateOnly(date).millisecondsSinceEpoch ==
        today.millisecondsSinceEpoch;

    return Text(
      DateFormat.yMMMMd(locale).format(date),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isToday ? colors.primary : colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
