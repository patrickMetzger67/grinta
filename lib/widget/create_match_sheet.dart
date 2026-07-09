import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/widget/club_picker_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Shows the match creation form (bottom sheet on mobile, dialog on web).
Future<bool?> showCreateMatchSheet(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialTime,
  Match? matchToEdit,
  VoidCallback? onSaved,
}) {
  if (kIsWeb) {
    return showDialog<bool>(
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 820),
          child: CreateMatchSheet(
            initialDate: initialDate,
            initialTime: initialTime,
            matchToEdit: matchToEdit,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => CreateMatchSheet(
      initialDate: initialDate,
      initialTime: initialTime,
      matchToEdit: matchToEdit,
      onSaved: onSaved,
    ),
  );
}

class CreateMatchSheet extends StatefulWidget {
  const CreateMatchSheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.matchToEdit,
    this.onSaved,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Match? matchToEdit;
  final VoidCallback? onSaved;

  bool get isEditMode => matchToEdit != null;

  @override
  State<CreateMatchSheet> createState() => _CreateMatchSheetState();
}

class _CreateMatchSheetState extends State<CreateMatchSheet> {
  final MatchService _matchService = MatchService();
  final ClubService _clubService = ClubService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _manualOpponentController =
      TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  List<Team> _teams = const <Team>[];
  String? _selectedTeamId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _durationMinutes = 90;
  bool _isHome = true;
  bool _isFriendly = false;
  bool _manualOpponentEntry = false;
  Club? _selectedOpponentClub;
  Club? _ownClub;
  bool _ownClubLoading = false;
  bool _withTracker = false;
  String? _selectedOwnerId;
  String? _selectedSurface;
  List<TeamOwnerRef> _ownerOptions = const <TeamOwnerRef>[];
  bool _ownersLoading = false;
  bool _isSubmitting = false;
  bool _isPrefilling = false;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    if (_isEditMode) {
      _initFromExistingMatch(widget.matchToEdit!);
    } else {
      _selectedDate = DateUtils.dateOnly(widget.initialDate ?? now);
      _selectedTime =
          widget.initialTime ?? TimeOfDay(hour: now.hour, minute: 0);
      _initTeams();
    }
  }

  Future<void> _initFromExistingMatch(Match match) async {
    _isPrefilling = true;

    final DateTime? parsedDate = parseMatchDateCh(match.dateCh);
    final TimeOfDay? parsedTime = parseMatchTimeCh(match.timeCh);
    final DateTime now = DateTime.now();

    _selectedDate = DateUtils.dateOnly(parsedDate ?? now);
    _selectedTime = parsedTime ?? TimeOfDay(hour: now.hour, minute: 0);
    _durationMinutes = match.duration ?? 90;
    _isHome = match.isOwnClub ?? true;
    _isFriendly = match.chType?.trim() == 'Amical';
    _withTracker = match.withTracker == true;
    _selectedOwnerId =
        match.ownerId?.trim().isNotEmpty == true ? match.ownerId : null;
    _venueController.text = match.terrainAdresse1?.trim() ?? '';
    final String surface = match.surfaceDeJeu?.trim() ?? '';
    _selectedSurface =
        kMatchSurfaceOptions.contains(surface) ? surface : null;

    _initTeams();
    _selectedTeamId = singleManagedMatchTeamId(match) ?? _selectedTeamId;

    final String opponentName = (_isHome ? match.team2 : match.team1)?.trim() ?? '';
    final String opponentAffiliation =
        (_isHome ? match.affiliationTeam2 : match.affiliationTeam1)?.trim() ?? '';

    if (opponentAffiliation.isNotEmpty) {
      try {
        final Club? club = await _clubService.getClubById(opponentAffiliation);
        if (club != null) {
          _selectedOpponentClub = club;
          _manualOpponentEntry = false;
        } else {
          _manualOpponentEntry = true;
          _manualOpponentController.text = opponentName;
        }
      } catch (_) {
        _manualOpponentEntry = true;
        _manualOpponentController.text = opponentName;
      }
    } else if (opponentName.isNotEmpty) {
      _manualOpponentEntry = true;
      _manualOpponentController.text = opponentName;
    }

    final Team? team = _selectedTeam;
    if (team != null) {
      await _loadOwnClubForTeam(team);
    }
    await _refreshOwnerOptions();

    if (!mounted) return;
    setState(() => _isPrefilling = false);
  }

  @override
  void dispose() {
    _manualOpponentController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _initTeams() {
    final AppSession session = context.read<AppSession>();
    final List<Team> teams = List<Team>.from(session.managerTeamsForSelectedSeason)
      ..sort(
        (Team a, Team b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );

    _teams = teams;
    if (teams.length == 1) {
      _selectedTeamId = teams.first.keyTeam;
      _loadOwnClubForTeam(teams.first);
    } else if (_selectedTeamId != null &&
        !teams.any((Team t) => t.keyTeam == _selectedTeamId)) {
      _selectedTeamId = null;
      _ownClub = null;
    }
  }

  Team? get _selectedTeam {
    if (_selectedTeamId == null) return null;
    for (final Team team in _teams) {
      if (team.keyTeam == _selectedTeamId) return team;
    }
    return null;
  }

  Future<void> _loadOwnClubForTeam(Team team) async {
    final String? clubId = team.clubId?.trim();
    if (clubId == null || clubId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _ownClub = null;
        _ownClubLoading = false;
      });
      _refreshDefaultVenueAddress();
      return;
    }

    setState(() => _ownClubLoading = true);

    try {
      final Club? club = await _clubService.getClubById(clubId);
      if (!mounted) return;
      setState(() {
        _ownClub = club;
        _ownClubLoading = false;
      });
      _refreshDefaultVenueAddress();
    } catch (_) {
      if (!mounted) return;
      setState(() => _ownClubLoading = false);
    }
  }

  void _refreshDefaultVenueAddress() {
    final Club? venueClub = _isHome ? _ownClub : _selectedOpponentClub;
    if (venueClub == null) {
      return;
    }

    final String address = buildClubMultilineAddress(venueClub);
    if (address.isEmpty) return;
    _venueController.text = address;
  }

  Future<void> _refreshOwnerOptions() async {
    if (!_withTracker) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = const <TeamOwnerRef>[];
        _ownersLoading = false;
      });
      return;
    }

    final Team? team = _selectedTeam;
    final List<TeamOwnerRef> rawRefs = team?.ownerRefs ?? const <TeamOwnerRef>[];
    if (team == null || rawRefs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = const <TeamOwnerRef>[];
        _ownersLoading = false;
        _selectedOwnerId = null;
      });
      return;
    }

    setState(() => _ownersLoading = true);

    try {
      final List<TeamOwnerRef> refs =
          await OwnerService().enrichTeamOwnerRefs(rawRefs);
      if (!mounted) return;
      setState(() {
        _ownerOptions = refs;
        _ownersLoading = false;
        if (refs.length == 1) {
          _selectedOwnerId = refs.first.id;
        } else if (_selectedOwnerId != null &&
            !refs.any((TeamOwnerRef ref) => ref.id == _selectedOwnerId)) {
          _selectedOwnerId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = rawRefs;
        _ownersLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.createMatchDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: context.l10n.createMatchTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _pickOpponentClub() async {
    final Club? club = await showClubPickerSheet(context);
    if (!mounted || club == null) return;

    setState(() {
      _selectedOpponentClub = club;
      _manualOpponentEntry = false;
      _manualOpponentController.clear();
    });
    if (!_isHome) {
      _refreshDefaultVenueAddress();
    }
  }

  void _enableManualOpponentEntry() {
    setState(() {
      _manualOpponentEntry = true;
      _selectedOpponentClub = null;
    });
    if (!_isHome) {
      _venueController.clear();
    }
  }

  void _onTeamChanged(String? teamId) {
    setState(() {
      _selectedTeamId = teamId;
      _selectedOwnerId = null;
      _ownClub = null;
    });

    final Team? team = _selectedTeam;
    if (team != null) {
      _loadOwnClubForTeam(team);
    }
    _refreshOwnerOptions();
  }

  String? _resolveOpponentName() {
    if (_manualOpponentEntry) {
      return _manualOpponentController.text.trim();
    }
    return _selectedOpponentClub?.name?.trim();
  }

  Future<void> _submit() async {
    if (_teams.isEmpty) {
      AppSnackbar.show(context, context.l10n.createMatchNoManagedTeams);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final String? opponentName = _resolveOpponentName();
    if (opponentName == null || opponentName.isEmpty) {
      AppSnackbar.show(context, context.l10n.createMatchOpponentRequired);
      return;
    }

    if (_withTracker && (_selectedOwnerId == null || _selectedOwnerId!.isEmpty)) {
      AppSnackbar.show(context, context.l10n.createMatchOwnerRequired);
      return;
    }

    final AppSession session = context.read<AppSession>();
    final Season? season = session.selectedSeason;
    final Team? team = _selectedTeam;

    if (season == null || team == null || team.keyTeam == null) {
      AppSnackbar.show(context, context.l10n.createMatchError);
      return;
    }

    final String venueAddress = _venueController.text.trim();
    final String successMessage =
        _isEditMode ? context.l10n.editMatchSaved : context.l10n.createMatchSaved;
    final String errorMessage =
        _isEditMode ? context.l10n.editMatchError : context.l10n.createMatchError;
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final VoidCallback? onSaved = widget.onSaved;
    final Match? existingMatch = widget.matchToEdit;

    if (venueAddress.isNotEmpty) {
      await geocodeAddressForNavigation(venueAddress);
    }

    if (!mounted) return;

    setState(() => _isSubmitting = true);

    var didPop = false;
    try {
      final Match match = _isEditMode && existingMatch != null
          ? buildMatchForUpdate(
              existing: existingMatch,
              date: _selectedDate,
              time: _selectedTime,
              durationMinutes: _durationMinutes,
              team: team,
              season: season,
              isHome: _isHome,
              isFriendly: _isFriendly,
              opponentName: opponentName,
              opponentAffiliation: _selectedOpponentClub?.affiliation,
              opponentLogoUrl: _selectedOpponentClub?.logo,
              venueAddress: venueAddress,
              surfaceDeJeu: _selectedSurface,
              withTracker: _withTracker,
              ownerId: _selectedOwnerId,
              ownClub: _ownClub,
            )
          : buildMatchForCreation(
              date: _selectedDate,
              time: _selectedTime,
              durationMinutes: _durationMinutes,
              team: team,
              season: season,
              isHome: _isHome,
              isFriendly: _isFriendly,
              opponentName: opponentName,
              opponentAffiliation: _selectedOpponentClub?.affiliation,
              opponentLogoUrl: _selectedOpponentClub?.logo,
              venueAddress: venueAddress,
              surfaceDeJeu: _selectedSurface,
              withTracker: _withTracker,
              ownerId: _selectedOwnerId,
              ownClub: _ownClub,
            );

      if (_isEditMode) {
        await _matchService.updateMatch(match);
      } else {
        await _matchService.createMatch(match);
      }

      if (!mounted) return;

      navigator.pop(true);
      didPop = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSaved?.call();
        final BuildContext? rootContext = appNavigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          AppSnackbar.show(rootContext, successMessage, isError: false);
        }
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, errorMessage);
      }
    } finally {
      if (mounted && !didPop) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _closeWithoutSaving() {
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  String _surfaceLabel(AppLocalizations l10n, String surface) {
    switch (surface) {
      case kMatchSurfaceSynthetic:
        return l10n.createMatchSurfaceSynthetic;
      case kMatchSurfaceNatural:
        return l10n.createMatchSurfaceNatural;
      default:
        return surface;
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final colors = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: colors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMd(locale).format(_selectedDate);
    final timeLabel = _selectedTime.format(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final String? opponentPreview = _resolveOpponentName();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditMode ? l10n.editMatchTitle : l10n.createMatchTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isPrefilling)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                if (_teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.createMatchNoManagedTeams,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedTeamId,
                    isExpanded: true,
                    dropdownColor: colors.surface,
                    decoration: _fieldDecoration(context, l10n.createMatchTeam),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.createMatchTeamRequired;
                      }
                      return null;
                    },
                    items: _teams
                        .map(
                          (Team team) => DropdownMenuItem<String>(
                            value: team.keyTeam,
                            child: Text(
                              team.name ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isEditMode ? null : _onTeamChanged,
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createMatchHome,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _isHome,
                  activeThumbColor: colors.primary,
                  onChanged: (bool value) {
                    setState(() => _isHome = value);
                    _refreshDefaultVenueAddress();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createMatchFriendly,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _isFriendly,
                  activeThumbColor: colors.primary,
                  onChanged: (bool value) => setState(() => _isFriendly = value),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createMatchDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    dateLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today_rounded, color: colors.primary),
                  onTap: _pickDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createMatchTime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    timeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.schedule_rounded, color: colors.primary),
                  onTap: _pickTime,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _durationMinutes,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  decoration: _fieldDecoration(context, l10n.createMatchDuration),
                  items: kMatchDurationOptions
                      .map(
                        (int minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text(l10n.createMatchDurationMinutes(minutes)),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value == null) return;
                    setState(() => _durationMinutes = value);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.createMatchOpponent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_manualOpponentEntry) ...[
                  OutlinedButton.icon(
                    onPressed: _pickOpponentClub,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      opponentPreview?.isNotEmpty == true
                          ? opponentPreview!
                          : l10n.createMatchSelectOpponentClub,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _enableManualOpponentEntry,
                    child: Text(l10n.createMatchClubNotFound),
                  ),
                ] else
                  TextFormField(
                    controller: _manualOpponentController,
                    decoration: _fieldDecoration(
                      context,
                      l10n.createMatchOpponentNameManual,
                    ),
                    validator: (value) {
                      if (!_manualOpponentEntry) return null;
                      if (value == null || value.trim().isEmpty) {
                        return l10n.createMatchOpponentRequired;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                if (!_manualOpponentEntry &&
                    _selectedOpponentClub != null &&
                    (_selectedOpponentClub!.city?.trim().isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _selectedOpponentClub!.city!.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _venueController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _fieldDecoration(context, l10n.createMatchVenue),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSurface,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  decoration: _fieldDecoration(context, l10n.createMatchSurface),
                  items: kMatchSurfaceOptions
                      .map(
                        (String surface) => DropdownMenuItem<String>(
                          value: surface,
                          child: Text(_surfaceLabel(l10n, surface)),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() => _selectedSurface = value);
                  },
                ),
                if (_ownClubLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createMatchWithTracker,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _withTracker,
                  activeThumbColor: colors.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _withTracker = value;
                      if (!value) {
                        _selectedOwnerId = null;
                      }
                    });
                    _refreshOwnerOptions();
                  },
                ),
                if (_withTracker) ...[
                  const SizedBox(height: 4),
                  if (_ownersLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_ownerOptions.isEmpty)
                    Text(
                      l10n.createMatchNoOwners,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _ownerOptions.any((ref) => ref.id == _selectedOwnerId)
                          ? _selectedOwnerId
                          : null,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      decoration:
                          _fieldDecoration(context, l10n.createMatchSelectOwner),
                      items: _ownerOptions
                          .map(
                            (TeamOwnerRef owner) => DropdownMenuItem<String>(
                              value: owner.id,
                              child: Text(owner.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() => _selectedOwnerId = value);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _closeWithoutSaving,
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting || _teams.isEmpty ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? l10n.editMatchSubmit
                                    : l10n.createMatchSubmit,
                              ),
                      ),
                    ),
                  ],
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
