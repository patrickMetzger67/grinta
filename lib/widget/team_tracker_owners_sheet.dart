import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_snackbar.dart' show AppSnackbar;
import 'package:grinta/util/app_theme.dart';

/// Bottom sheet to view or manage GPS tracker owners linked to a team.
Future<bool?> showTeamTrackerOwnersSheet(
  BuildContext context, {
  required Team team,
  required bool isManager,
  required OwnerService ownerService,
  required TeamService teamService,
  UserService? userService,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.appColors.card,
    builder: (sheetContext) => TeamTrackerOwnersSheet(
      team: team,
      isManager: isManager,
      ownerService: ownerService,
      teamService: teamService,
      userService: userService ?? UserService(),
    ),
  );
}

class TeamTrackerOwnersSheet extends StatefulWidget {
  const TeamTrackerOwnersSheet({
    super.key,
    required this.team,
    required this.isManager,
    required this.ownerService,
    required this.teamService,
    required this.userService,
  });

  final Team team;
  final bool isManager;
  final OwnerService ownerService;
  final TeamService teamService;
  final UserService userService;

  @override
  State<TeamTrackerOwnersSheet> createState() => _TeamTrackerOwnersSheetState();
}

class _TeamTrackerOwnersSheetState extends State<TeamTrackerOwnersSheet> {
  bool _loading = true;
  String? _loadError;
  List<Owner> _displayOwners = const [];
  late Set<String> _selectedIds;
  bool _saving = false;

  bool get _readOnly =>
      widget.team.hasAnyTrackerOwners && !widget.isManager;

  bool get _editable => widget.isManager;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.team.ownerRefs.map((ref) => ref.id).toSet();
    _loadOwners();
  }

  Future<String> _teamOwnerEmail() async {
    final String uid = widget.team.uid?.trim() ?? '';
    if (uid.isEmpty) return '';
    final profile = await widget.userService.getById(uid);
    return profile?.email.trim() ?? '';
  }

  Future<void> _loadOwners() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      if (_readOnly) {
        final List<Owner> teamOwners = await _loadTeamOwners();
        if (!mounted) return;
        setState(() {
          _displayOwners = teamOwners;
          _loading = false;
        });
        return;
      }

      if (!widget.isManager) {
        if (!mounted) return;
        setState(() {
          _displayOwners = const [];
          _loading = false;
        });
        return;
      }

      final String teamOwnerEmail = await _teamOwnerEmail();
      final List<Owner> ownersByTeamUidEmail = teamOwnerEmail.isEmpty
          ? const <Owner>[]
          : await widget.ownerService.getOwnersByEmail(teamOwnerEmail);

      if (widget.team.hasAnyTrackerOwners) {
        final List<Owner> assignedOwners = await _loadTeamOwners();
        if (!mounted) return;
        setState(() {
          _displayOwners = _mergeOwners(assignedOwners, ownersByTeamUidEmail);
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _displayOwners = ownersByTeamUidEmail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'load';
        _loading = false;
      });
    }
  }

  List<Owner> _mergeOwners(List<Owner> primary, List<Owner> supplemental) {
    final Map<String, Owner> byId = <String, Owner>{};
    for (final Owner owner in primary) {
      byId[owner.id] = owner;
    }
    for (final Owner owner in supplemental) {
      byId.putIfAbsent(owner.id, () => owner);
    }
    final List<Owner> merged = byId.values.toList();
    merged.sort(
      (Owner a, Owner b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return merged;
  }

  Future<List<Owner>> _loadTeamOwners() async {
    final List<Owner> result = <Owner>[];
    for (final TeamOwnerRef ref in widget.team.ownerRefs) {
      final Owner? owner = await widget.ownerService.getOwnerById(ref.id);
      if (owner != null) {
        result.add(owner);
        continue;
      }
      if (ref.displayLabel.isNotEmpty) {
        result.add(
          Owner(
            id: ref.id,
            name: ref.displayLabel,
            typeTracker: '',
            isActive: true,
            email: '',
            firstname: '',
            lastname: '',
            uidCreate: '',
            uidUpdate: '',
          ),
        );
      }
    }
    result.sort(
      (Owner a, Owner b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return result;
  }

  void _toggleOwner(String ownerId) {
    if (!_editable || ownerId.trim().isEmpty) return;
    setState(() {
      if (_selectedIds.contains(ownerId)) {
        _selectedIds.remove(ownerId);
      } else {
        _selectedIds.add(ownerId);
      }
    });
  }

  Future<void> _saveSelection() async {
    final String? teamId = widget.team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final List<String> ownerIds = _selectedIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
      await widget.teamService.updateOwners(
        teamId: teamId,
        owners: ownerIds,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.teamDetailTrackerOwnersSaved,
        isError: false,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.55;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.teamDetailTrackerOwnersTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
            if (_editable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving || _loading ? null : _saveSelection,
                        child: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.actionValidate),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.actionClose),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Text(
          l10n.errorGeneric(_loadError!),
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    if (_displayOwners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.teamDetailTrackerOwnersEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _displayOwners.length,
      itemBuilder: (context, index) {
        final Owner owner = _displayOwners[index];
        final String typeLabel = owner.typeTracker.trim();

        if (_readOnly) {
          return ListTile(
            leading: Icon(Icons.sensors_rounded, color: colors.primary),
            title: Text(
              owner.name.trim().isEmpty ? owner.id : owner.name.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: typeLabel.isEmpty
                ? null
                : Text(l10n.teamDetailTrackerOwnerType(typeLabel)),
          );
        }

        final bool isSelected = _selectedIds.contains(owner.id);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => _toggleOwner(owner.id),
          controlAffinity: ListTileControlAffinity.leading,
          secondary: Icon(Icons.sensors_rounded, color: colors.primary),
          title: Text(
            owner.name.trim().isEmpty ? owner.id : owner.name.trim(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: typeLabel.isEmpty
              ? null
              : Text(l10n.teamDetailTrackerOwnerType(typeLabel)),
        );
      },
    );
  }
}
