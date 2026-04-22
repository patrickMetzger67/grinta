import 'package:flutter/material.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({
    super.key,
    required this.managedTeamsIds,
    this.title = 'Équipes',
    this.onTeamTap,
    this.teamSubtitle,
    this.trailingBuilder,
  });

  final List<String> managedTeamsIds;
  final String title;
  final void Function(BuildContext context, Team team)? onTeamTap;
  final String? Function(Team team)? teamSubtitle;
  final Widget Function(BuildContext context, Team team)? trailingBuilder;

  @override
  State<TeamsListScreen> createState() =>
      _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        final List<Team> allTeams = List<Team>.from(appSession.selectedTeams);

        allTeams.sort((a, b) {
          final aName = (a.name ?? '').toLowerCase();
          final bName = (b.name ?? '').toLowerCase();
          return aName.compareTo(bName);
        });

        final List<Team> filteredTeams = allTeams.where((team) {
          final String name = (team.name ?? '').toLowerCase();
          final String subtitle =
          (widget.teamSubtitle?.call(team) ?? '').toLowerCase();
          final String query = _search.toLowerCase().trim();

          if (query.isEmpty) return true;
          return name.contains(query) || subtitle.contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
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
                      hintText: 'Rechercher une équipe',
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
                              ? '${allTeams.length} équipe(s)'
                              : '${filteredTeams.length} / ${allTeams.length}',
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
                      (team.name ?? '').trim().isEmpty ? 'Équipe' : team.name!.trim();
                      final String? subtitle = widget.teamSubtitle?.call(team);

                      final bool isManager = team.keyTeam != null && widget.managedTeamsIds.contains(team.keyTeam!);

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: widget.onTeamTap == null
                              ? null
                              : () => widget.onTeamTap!(context, team),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child:Row(
                              children: [
                                _TeamAvatar(name: name),
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
                                      if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({
    required this.name,
  });

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
                  ? 'Aucune équipe trouvée'
                  : 'Aucune équipe disponible',
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