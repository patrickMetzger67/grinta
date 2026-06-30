import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/team_creation_access.dart';
import 'package:grinta/util/team_deletion_access.dart';
import 'package:grinta/util/team_detail_access.dart';
import 'package:grinta/util/team_equipe_lookup.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/club_picker_sheet.dart';
import 'package:grinta/widget/equipe_competitions_count_label.dart';
import 'package:grinta/widget/equipe_competitions_sheet.dart';
import '../core/extensions/l10n_extension.dart';
import '../util/app_theme.dart';
import 'package:provider/provider.dart';

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({
    super.key,
    required this.managedTeamsIds,
    this.title,
    this.onTeamTap,
    this.teamSubtitle,
    this.trailingBuilder,
  });

  final List<String> managedTeamsIds;
  final String? title;
  final void Function(BuildContext context, Team team, bool isMananger)? onTeamTap;
  final String? Function(Team team)? teamSubtitle;
  final Widget Function(BuildContext context, Team team)? trailingBuilder;

  @override
  State<TeamsListScreen> createState() =>
      _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  Map<String, Equipe> _equipesByTeamKey = <String, Equipe>{};
  Object? _equipeLookupKey;
  Object? _scheduledEquipeLookupKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Object _equipeLookupKeyFor(List<Team> teams, String? seasonId) {
    return Object.hashAll([
      ...teams.map(
        (team) => Object.hash(
          team.keyTeam,
          team.clubId,
          team.teamIdInTeamsPerClub,
          team.seasonID,
        ),
      ),
      seasonId,
    ]);
  }

  void _scheduleEquipeLookup(List<Team> teams, String? seasonId) {
    final lookupKey = _equipeLookupKeyFor(teams, seasonId);
    if (_equipeLookupKey == lookupKey || _scheduledEquipeLookupKey == lookupKey) {
      return;
    }
    _scheduledEquipeLookupKey = lookupKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledEquipeLookupKey != lookupKey) return;
      _loadEquipes(teams, seasonId, lookupKey);
    });
  }

  void _loadEquipes(List<Team> teams, String? seasonId, Object lookupKey) {
    if (_equipeLookupKey == lookupKey) return;
    _equipeLookupKey = lookupKey;

    loadEquipesForTeams(
      teams: teams,
      fallbackSeasonId: seasonId,
    ).then((equipesByTeamKey) {
      if (!mounted || _equipeLookupKey != lookupKey) return;
      setState(() => _equipesByTeamKey = equipesByTeamKey);
    });
  }

  Future<void> _onCreateTeam(BuildContext context) async {
    await openTeamCreationFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        final List<Team> allTeams = List<Team>.from(appSession.selectedTeams);
        final seasonId = appSession.selectedSeason?.ref?.id;
        _scheduleEquipeLookup(allTeams, seasonId);

        allTeams.sort((a, b) {
          final aName = (a.name ?? '').toLowerCase();
          final bName = (b.name ?? '').toLowerCase();
          return aName.compareTo(bName);
        });

        final List<Team> filteredTeams = allTeams.where((team) {
          final String name = (team.name ?? '').toLowerCase();
          final String customSubtitle =
              (widget.teamSubtitle?.call(team) ?? '').toLowerCase();
          final equipe = _equipesByTeamKey[team.keyTeam?.trim() ?? ''];
          final String competitionSubtitle = equipe != null &&
                  equipe.competitions.isNotEmpty
              ? l10n
                  .teamCreationClubTeamCompetitionsCount(
                    equipe.competitions.length,
                  )
                  .toLowerCase()
              : '';
          final String query = _search.toLowerCase().trim();

          if (query.isEmpty) return true;
          return name.contains(query) ||
              customSubtitle.contains(query) ||
              competitionSubtitle.contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? l10n.entityTeams),
            actions: [
              ListenableBuilder(
                listenable: Listenable.merge([
                  SubscriptionService.instance,
                  UserTrialService.instance,
                ]),
                builder: (context, _) {
                  final String? userId =
                      appSession.user?.uid ??
                      FirebaseAuth.instance.currentUser?.uid;
                  final seasonId = appSession.selectedSeason?.ref?.id.trim();
                  final gate = _resolveTeamCreationGate(
                    appSession: appSession,
                    userId: userId,
                    seasonId: seasonId,
                  );
                  final showPremiumBadge =
                      gate == TeamCreationGate.needsUpgrade;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    child: Tooltip(
                      message: l10n.actionCreateTeam,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _onCreateTeam(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: colors.primary,
                                  size: 22,
                                ),
                                if (showPremiumBadge) ...[
                                  const SizedBox(width: 8),
                                  SubscriptionPremiumBadge(
                                    colors: colors,
                                    compact: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _search = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l10n.hintSearchTeam,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _search = '';
                          });
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          _search.isEmpty
                              ? l10n.teamsListCount(allTeams.length)
                              : l10n.teamsListCountFiltered(
                                  filteredTeams.length,
                                  allTeams.length,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredTeams.isEmpty
                      ? _EmptyTeamsState(search: _search)
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: filteredTeams.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final Team team = filteredTeams[index];
                      final String name =
                      (team.name ?? '').trim().isEmpty
                          ? l10n.entityTeam
                          : team.name!.trim();
                      final String? customSubtitle =
                          widget.teamSubtitle?.call(team);
                      final Equipe? equipe =
                          _equipesByTeamKey[team.keyTeam?.trim() ?? ''];
                      final int competitionCount =
                          equipe?.competitions.length ?? 0;
                      final bool hasCompetitions = competitionCount > 0;

                      final bool isManager = team.keyTeam != null && widget.managedTeamsIds.contains(team.keyTeam!);
                      final String? currentUserUid =
                          appSession.user?.uid ??
                          FirebaseAuth.instance.currentUser?.uid;
                      final bool isOwner = isTeamOwner(team, currentUserUid);

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: widget.onTeamTap == null
                              ? null
                              : () async {
                                  final allowed = await ensureCanOpenTeamDetail(
                                    context,
                                    team: team,
                                  );
                                  if (!allowed || !context.mounted) return;
                                  widget.onTeamTap!(
                                    context,
                                    team,
                                    isManager,
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child:Row(
                              children: [
                                _TeamAvatar(name: name, clubId: team.clubId),
                                if (isManager) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.verified_rounded,
                                    color: colors.success,
                                    size: 18,
                                  ),
                                ],
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (customSubtitle != null &&
                                          customSubtitle.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          customSubtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (hasCompetitions) ...[
                                        const SizedBox(height: 4),
                                        EquipeCompetitionsCountLabel(
                                          count: competitionCount,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (hasCompetitions && equipe != null) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    tooltip: l10n.equipeCompetitionsSheetTitle(
                                      name,
                                    ),
                                    onPressed: () => showEquipeCompetitionsSheet(
                                      context,
                                      equipe: equipe,
                                    ),
                                  ),
                                ],
                                if (isOwner) ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: colors.danger,
                                    ),
                                    tooltip: l10n.actionDeleteTeam,
                                    onPressed: () async {
                                      await deleteOwnedTeam(
                                        context,
                                        team: team,
                                        popAfterDelete: false,
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(width: 8),
                                widget.trailingBuilder?.call(context, team) ??
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.textSecondary,
                                    ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

TeamCreationGate _resolveTeamCreationGate({
  required AppSession appSession,
  required String? userId,
  required String? seasonId,
}) {
  if (userId == null ||
      userId.isEmpty ||
      seasonId == null ||
      seasonId.isEmpty) {
    return TeamCreationGate.allowed;
  }

  if (!SubscriptionLimitsService.instance.isInitialized) {
    return TeamCreationGate.allowed;
  }

  final int teamCount;
  if (SubscriptionService.instance.coachTier != null) {
    teamCount = appSession.managedTeamsIdsForSelectedSeason.length;
  } else {
    teamCount = appSession.selectedTeams.length;
  }

  return SubscriptionLimitsService.instance.resolveTeamCreationGate(
    teamCount,
  );
}

class _TeamAvatar extends StatefulWidget {
  const _TeamAvatar({
    required this.name,
    this.clubId,
  });

  final String name;
  final String? clubId;

  @override
  State<_TeamAvatar> createState() => _TeamAvatarState();
}

class _TeamAvatarState extends State<_TeamAvatar> {
  static final ClubService _clubService = ClubService();

  Future<Club?>? _clubFuture;

  @override
  void initState() {
    super.initState();
    _clubFuture = _loadClub();
  }

  @override
  void didUpdateWidget(covariant _TeamAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clubId != widget.clubId) {
      _clubFuture = _loadClub();
    }
  }

  Future<Club?>? _loadClub() {
    final clubId = widget.clubId?.trim() ?? '';
    if (clubId.isEmpty) {
      return null;
    }
    return _clubService.getClubById(clubId);
  }

  @override
  Widget build(BuildContext context) {
    final clubId = widget.clubId?.trim() ?? '';
    if (clubId.isEmpty) {
      return _TeamInitialAvatar(name: widget.name);
    }

    return FutureBuilder<Club?>(
      future: _clubFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _TeamAvatarLoading();
        }

        final logo = snapshot.data?.logo?.trim();
        if (logo != null && logo.isNotEmpty) {
          return ClubLogo(url: logo);
        }

        return _TeamInitialAvatar(name: widget.name);
      },
    );
  }
}

class _TeamInitialAvatar extends StatelessWidget {
  const _TeamInitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return CircleAvatar(
      radius: 24,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TeamAvatarLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CircleAvatar(
      radius: 24,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _EmptyTeamsState extends StatelessWidget {
  const _EmptyTeamsState({
    required this.search,
  });

  final String search;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bool isSearching = search.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.groups_rounded,
              size: 52,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? context.l10n.teamsListNoResults
                  : context.l10n.teamsListNoTeams,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Essaie avec un autre mot-clé.'
                  : 'Les équipes apparaîtront ici dès qu’elles seront chargées.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}