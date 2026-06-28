import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/equipe_competitions_count_label.dart';
import 'package:grinta/widget/equipe_competitions_sheet.dart';

/// Shows a searchable bottom sheet to pick one or more club équipes.
Future<List<Equipe>?> showEquipePickerSheet(
  BuildContext context, {
  required String clubId,
  required String seasonId,
  List<Equipe> initialSelection = const <Equipe>[],
}) {
  return showModalBottomSheet<List<Equipe>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => EquipePickerSheet(
      clubId: clubId,
      seasonId: seasonId,
      initialSelection: initialSelection,
    ),
  );
}

class EquipePickerSheet extends StatefulWidget {
  const EquipePickerSheet({
    super.key,
    required this.clubId,
    required this.seasonId,
    this.initialSelection = const <Equipe>[],
  });

  final String clubId;
  final String seasonId;
  final List<Equipe> initialSelection;

  @override
  State<EquipePickerSheet> createState() => _EquipePickerSheetState();
}

class _EquipePickerSheetState extends State<EquipePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TeamsPerClubService _teamsPerClubService = TeamsPerClubService();
  Timer? _debounce;
  String _query = '';
  late Set<String> _selectedIds;
  List<Equipe> _allEquipes = <Equipe>[];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelection
        .map((e) => e.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    _searchController.addListener(_onSearchChanged);
    _loadEquipes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipes() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final teamsPerClub = await _teamsPerClubService.getByClubIdAndSeason(
        clubId: widget.clubId,
        seasonId: widget.seasonId,
      );

      if (!mounted) return;

      setState(() {
        _allEquipes = teamsPerClub?.equipes ?? <Equipe>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  List<Equipe> get _filteredEquipes {
    if (_query.isEmpty) return _allEquipes;
    return _allEquipes.where((equipe) {
      final name = equipe.name?.trim().toLowerCase() ?? '';
      return name.contains(_query);
    }).toList();
  }

  void _toggleEquipe(Equipe equipe) {
    final id = equipe.id?.trim() ?? '';
    if (id.isEmpty) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirmSelection() {
    final selected = _allEquipes
        .where((equipe) => _selectedIds.contains(equipe.id?.trim()))
        .toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.sizeOf(context).height;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final height = deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
    final l10n = context.l10n;
    final colors = context.appColors;
    final filtered = _filteredEquipes;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: l10n.actionBack,
                ),
                Expanded(
                  child: Text(
                    l10n.teamCreationSelectClubTeams,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.hintSearchClubTeam,
                hintText: l10n.hintSearchClubTeam,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(context, filtered),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  child: Text(
                    l10n.teamCreationSelectedClubTeamsCount(_selectedIds.length),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Equipe> filtered,
  ) {
    final colors = context.appColors;
    final l10n = context.l10n;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.errorGeneric(_loadError!),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ),
      );
    }

    if (_allEquipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.teamCreationNoClubTeams,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.emptyNoData,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final equipe = filtered[index];
        final id = equipe.id?.trim() ?? '';
        final isSelected = id.isNotEmpty && _selectedIds.contains(id);

        final hasCompetitions = equipe.competitions.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: id.isEmpty ? null : () => _toggleEquipe(equipe),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: id.isEmpty ? null : (_) => _toggleEquipe(equipe),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  equipe.name?.trim() ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: hasCompetitions
                    ? EquipeCompetitionsCountLabel(
                        count: equipe.competitions.length,
                      )
                    : null,
                secondary: hasCompetitions
                    ? IconButton(
                        icon: const Icon(Icons.info_outline_rounded),
                        tooltip: l10n.equipeCompetitionsSheetTitle(
                          equipe.name?.trim() ?? '',
                        ),
                        onPressed: () => showEquipeCompetitionsSheet(
                          context,
                          equipe: equipe,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
