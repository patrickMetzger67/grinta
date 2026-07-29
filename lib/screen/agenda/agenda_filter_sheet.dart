import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/agenda_filter.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/app_theme.dart';

Future<AgendaFilter?> showAgendaFilterSheet(
  BuildContext context, {
  required AgendaFilter initialFilter,
  required List<Team> teams,
}) async {
  if (kIsWeb) {
    return showDialog<AgendaFilter>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appColors.background,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: _AgendaFilterBody(
              initialFilter: initialFilter,
              teams: teams,
              onClose: () => Navigator.of(dialogContext).pop(),
              onApply: (filter) => Navigator.of(dialogContext).pop(filter),
            ),
          ),
        );
      },
    );
  }

  final colors = context.appColors;
  return showModalBottomSheet<AgendaFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _AgendaFilterBody(
            initialFilter: initialFilter,
            teams: teams,
            onClose: () => Navigator.of(sheetContext).pop(),
            onApply: (filter) => Navigator.of(sheetContext).pop(filter),
          ),
        ),
      );
    },
  );
}

class _AgendaFilterBody extends StatefulWidget {
  const _AgendaFilterBody({
    required this.initialFilter,
    required this.teams,
    required this.onClose,
    required this.onApply,
  });

  final AgendaFilter initialFilter;
  final List<Team> teams;
  final VoidCallback onClose;
  final ValueChanged<AgendaFilter> onApply;

  @override
  State<_AgendaFilterBody> createState() => _AgendaFilterBodyState();
}

class _AgendaFilterBodyState extends State<_AgendaFilterBody> {
  late Set<String> _selectedTeamIds;
  late Set<AgendaItemType> _selectedTypes;
  late final List<Team> _sortedTeams;
  late final Set<String> _availableTeamIds;

  @override
  void initState() {
    super.initState();
    _sortedTeams = List<Team>.from(widget.teams)
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    _availableTeamIds = {
      for (final team in _sortedTeams)
        if ((team.keyTeam ?? '').trim().isNotEmpty) team.keyTeam!.trim(),
    };

    final initialTeams = widget.initialFilter.teamIds;
    _selectedTeamIds = initialTeams.isEmpty
        ? Set<String>.from(_availableTeamIds)
        : {
            for (final id in initialTeams)
              if (_availableTeamIds.contains(id)) id,
          };

    final initialTypes = widget.initialFilter.types;
    _selectedTypes = initialTypes.isEmpty
        ? AgendaItemType.values.toSet()
        : Set<AgendaItemType>.from(initialTypes);
  }

  AgendaFilter _buildFilter() {
    return AgendaFilter.normalize(
      selectedTeamIds: _selectedTeamIds,
      selectedTypes: _selectedTypes,
      availableTeamIds: _availableTeamIds,
      availableTypes: AgendaItemType.values.toSet(),
    );
  }

  void _reset() {
    setState(() {
      _selectedTeamIds = Set<String>.from(_availableTeamIds);
      _selectedTypes = AgendaItemType.values.toSet();
    });
  }

  String _typeLabel(AppLocalizations l10n, AgendaItemType type) {
    switch (type) {
      case AgendaItemType.match:
        return l10n.entityMatch;
      case AgendaItemType.entrainement:
        return l10n.entityTraining;
      case AgendaItemType.preparationPhysique:
        return l10n.agendaAddEventPersonalSport;
      case AgendaItemType.nonSport:
        return l10n.agendaAddEventNonSport;
    }
  }

  IconData _typeIcon(AgendaItemType type) {
    switch (type) {
      case AgendaItemType.match:
        return Icons.sports_soccer_rounded;
      case AgendaItemType.entrainement:
        return Icons.fitness_center_rounded;
      case AgendaItemType.preparationPhysique:
        return Icons.directions_run_rounded;
      case AgendaItemType.nonSport:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.agendaFilterTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.actionCancel,
                onPressed: widget.onClose,
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text(
                l10n.agendaFilterTypesSection,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AgendaItemType.values.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  return FilterChip(
                    avatar: Icon(
                      _typeIcon(type),
                      size: 18,
                      color: isSelected ? colors.success : colors.primary,
                    ),
                    label: Text(_typeLabel(l10n, type)),
                    selected: isSelected,
                    selectedColor: colors.success.withValues(alpha: 0.22),
                    checkmarkColor: colors.success,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? colors.success : colors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? colors.success : colors.border,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypes.add(type);
                        } else if (_selectedTypes.length > 1) {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.agendaFilterTeamsSection,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              if (_sortedTeams.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.agendaFilterNoTeams,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedTeamIds.length ==
                            _availableTeamIds.length) {
                          // Keep at least one team selected in the UI draft.
                          final first = _availableTeamIds.first;
                          _selectedTeamIds = <String>{first};
                        } else {
                          _selectedTeamIds =
                              Set<String>.from(_availableTeamIds);
                        }
                      });
                    },
                    child: Text(
                      _selectedTeamIds.length == _availableTeamIds.length
                          ? l10n.agendaFilterSelectNoneTeams
                          : l10n.agendaFilterSelectAllTeams,
                    ),
                  ),
                ),
                for (final team in _sortedTeams) ...[
                  Builder(
                    builder: (context) {
                      final teamId = team.keyTeam?.trim() ?? '';
                      if (teamId.isEmpty) return const SizedBox.shrink();
                      final name = (team.name ?? '').trim().isEmpty
                          ? teamId
                          : team.name!.trim();
                      return CheckboxListTile(
                        value: _selectedTeamIds.contains(teamId),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: colors.primary,
                        title: Text(
                          name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedTeamIds.add(teamId);
                            } else if (_selectedTeamIds.length > 1) {
                              _selectedTeamIds.remove(teamId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: _reset,
                child: Text(l10n.actionReset),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => widget.onApply(_buildFilter()),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.agendaFilterApply),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
