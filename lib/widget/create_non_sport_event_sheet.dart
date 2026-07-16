import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/non_sport_event.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/non_sport_event_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/member_search_sheet.dart';
import 'package:grinta/widget/non_sport_event_invitees_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<NonSportEvent?> showCreateNonSportEventSheet(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialTime,
  NonSportEvent? eventToEdit,
  VoidCallback? onSaved,
}) async {
  final NonSportEvent? saved;
  if (kIsWeb) {
    saved = await showDialog<NonSportEvent>(
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
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: CreateNonSportEventSheet(
            initialDate: initialDate,
            initialTime: initialTime,
            eventToEdit: eventToEdit,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  } else {
    saved = await showModalBottomSheet<NonSportEvent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.card,
      builder: (_) => CreateNonSportEventSheet(
        initialDate: initialDate,
        initialTime: initialTime,
        eventToEdit: eventToEdit,
        onSaved: onSaved,
      ),
    );
  }

  // Create/edit UI is already closed; show feedback + invite statuses on host.
  if (saved != null && context.mounted) {
    AppSnackbar.show(
      context,
      eventToEdit == null
          ? context.l10n.createNonSportEventSaved
          : context.l10n.editNonSportEventSaved,
      isError: false,
    );
    await showNonSportEventInviteesSheet(context, event: saved);
  }

  return saved;
}

class CreateNonSportEventSheet extends StatefulWidget {
  const CreateNonSportEventSheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.eventToEdit,
    this.onSaved,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final NonSportEvent? eventToEdit;
  final VoidCallback? onSaved;

  bool get isEditMode => eventToEdit != null;

  @override
  State<CreateNonSportEventSheet> createState() =>
      _CreateNonSportEventSheetState();
}

class _CreateNonSportEventSheetState extends State<CreateNonSportEventSheet> {
  final NonSportEventService _eventService = NonSportEventService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _allDay = false;
  bool _isSubmitting = false;

  List<Team> _teams = const <Team>[];
  final Set<String> _selectedTeamIds = <String>{};
  final Map<String, Player> _inviteesByMemberId = <String, Player>{};
  final Map<String, Set<String>> _selectedMemberIdsByTeam =
      <String, Set<String>>{};
  final Set<String> _manualInviteeIds = <String>{};
  final Set<String> _loadingTeamIds = <String>{};

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final NonSportEvent? existing = widget.eventToEdit;
    if (existing != null) {
      _titleController.text = existing.title;
      _locationController.text = existing.location ?? '';
      _allDay = existing.allDay;
      _startDate = DateUtils.dateOnly(existing.startAt);
      _endDate = DateUtils.dateOnly(existing.endAt);
      _startTime = TimeOfDay.fromDateTime(existing.startAt);
      _endTime = TimeOfDay.fromDateTime(existing.endAt);
      _selectedTeamIds.addAll(existing.teamIds);
      _initTeams();
      unawaited(_prefillInvitees(existing));
    } else {
      _startDate = DateUtils.dateOnly(widget.initialDate ?? now);
      _endDate = _startDate;
      _startTime = widget.initialTime ?? TimeOfDay(hour: now.hour, minute: 0);
      final int endHour = (_startTime.hour + 1) % 24;
      _endTime = TimeOfDay(
        hour: endHour,
        minute: _startTime.minute,
      );
      if (endHour < _startTime.hour) {
        _endDate = _startDate.add(const Duration(days: 1));
      }
      _initTeams();
    }
  }

  Future<void> _prefillInvitees(NonSportEvent existing) async {
    final PlayerService playerService = PlayerService();
    for (final NonSportInvitee invitee in existing.invitees) {
      final Player? player =
          await playerService.getPlayerById(invitee.memberId);
      if (player == null) {
        continue;
      }
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        continue;
      }
      _inviteesByMemberId[memberId] = player;
      if (invitee.teamIds.isEmpty) {
        _manualInviteeIds.add(memberId);
      } else {
        for (final String teamId in invitee.teamIds) {
          _selectedMemberIdsByTeam
              .putIfAbsent(teamId, () => <String>{})
              .add(memberId);
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initTeams() {
    final AppSession session = context.read<AppSession>();
    final List<Team> teams = List<Team>.from(session.teamsForAgendaSelectedSeason)
      ..sort(
        (Team a, Team b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );
    _teams = teams;
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.createNonSportEventStartDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = DateUtils.dateOnly(picked);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      helpText: context.l10n.createNonSportEventEndDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = DateUtils.dateOnly(picked));
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: context.l10n.createNonSportEventStartTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startTime = picked;
      _ensureEndAfterStart();
    });
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: context.l10n.createNonSportEventEndTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endTime = picked;
      _ensureEndAfterStart();
    });
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _ensureEndAfterStart() {
    if (_allDay) {
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
      return;
    }
    final DateTime startAt = _combine(_startDate, _startTime);
    DateTime endAt = _combine(_endDate, _endTime);
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
      _endDate = DateUtils.dateOnly(endAt);
      _endTime = TimeOfDay(hour: endAt.hour, minute: endAt.minute);
    }
  }

  Future<void> _toggleTeam(Team team, bool selected) async {
    final String? teamId = team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      return;
    }

    if (!selected) {
      setState(() {
        _selectedTeamIds.remove(teamId);
        final Set<String>? removed = _selectedMemberIdsByTeam.remove(teamId);
        if (removed != null) {
          for (final String memberId in removed) {
            final bool stillSelectedElsewhere = _selectedMemberIdsByTeam.values
                .any((Set<String> ids) => ids.contains(memberId));
            if (!stillSelectedElsewhere &&
                !_manualInviteeIds.contains(memberId)) {
              _inviteesByMemberId.remove(memberId);
            }
          }
        }
      });
      return;
    }

    setState(() {
      _selectedTeamIds.add(teamId);
      _loadingTeamIds.add(teamId);
    });

    try {
      final List<Player> members = await _eventService.loadAllTeamMembers(team);
      if (!mounted) return;

      final Set<String> memberIds = <String>{};
      for (final Player player in members) {
        final String? memberId = effectiveMemberId(player);
        if (memberId == null) {
          continue;
        }
        memberIds.add(memberId);
        _inviteesByMemberId[memberId] = player;
      }

      setState(() {
        _selectedMemberIdsByTeam[teamId] = memberIds;
        _loadingTeamIds.remove(teamId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedTeamIds.remove(teamId);
        _loadingTeamIds.remove(teamId);
      });
      AppSnackbar.show(
        context,
        context.l10n.createNonSportEventError,
        isError: true,
      );
    }
  }

  Future<void> _selectTeamMembers(Team team) async {
    final String? teamId = team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      return;
    }

    setState(() => _loadingTeamIds.add(teamId));
    try {
      final List<Player> members = await _eventService.loadAllTeamMembers(team);
      if (!mounted) return;
      setState(() => _loadingTeamIds.remove(teamId));

      final Set<String> initialSelected =
          Set<String>.from(_selectedMemberIdsByTeam[teamId] ?? const <String>{});

      final Set<String>? picked = await showDialog<Set<String>>(
        context: context,
        builder: (dialogContext) {
          final Set<String> draft = Set<String>.from(initialSelected);
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final colors = context.appColors;
              return AlertDialog(
                backgroundColor: colors.card,
                surfaceTintColor: Colors.transparent,
                title: Text(context.l10n.createNonSportEventSelectMembers),
                content: SizedBox(
                  width: 420,
                  height: 420,
                  child: members.isEmpty
                      ? Text(context.l10n.createNonSportEventNoTeamMembers)
                      : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final Player player = members[index];
                            final String? memberId = effectiveMemberId(player);
                            if (memberId == null) {
                              return const SizedBox.shrink();
                            }
                            return CheckboxListTile(
                              value: draft.contains(memberId),
                              onChanged: (bool? value) {
                                setLocalState(() {
                                  if (value == true) {
                                    draft.add(memberId);
                                  } else {
                                    draft.remove(memberId);
                                  }
                                });
                              },
                              title: Text(playerDisplayName(player)),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.l10n.actionCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(draft),
                    child: Text(context.l10n.actionValidate),
                  ),
                ],
              );
            },
          );
        },
      );

      if (picked == null || !mounted) {
        return;
      }

      setState(() {
        _selectedTeamIds.add(teamId);
        final Set<String> previous =
            _selectedMemberIdsByTeam[teamId] ?? const <String>{};
        for (final String memberId in previous.difference(picked)) {
          final bool stillElsewhere = _selectedMemberIdsByTeam.entries.any(
            (MapEntry<String, Set<String>> e) =>
                e.key != teamId && e.value.contains(memberId),
          );
          if (!stillElsewhere && !_manualInviteeIds.contains(memberId)) {
            _inviteesByMemberId.remove(memberId);
          }
        }

        _selectedMemberIdsByTeam[teamId] = picked;
        for (final Player player in members) {
          final String? memberId = effectiveMemberId(player);
          if (memberId != null && picked.contains(memberId)) {
            _inviteesByMemberId[memberId] = player;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTeamIds.remove(teamId));
      AppSnackbar.show(
        context,
        context.l10n.createNonSportEventError,
        isError: true,
      );
    }
  }

  Future<void> _addOtherProfile() async {
    final Player? player = await showMemberSearchSheet(
      context,
      title: context.l10n.createNonSportEventAddProfile,
      excludeMemberIds: _inviteesByMemberId.keys.toSet(),
    );
    if (player == null || !mounted) {
      return;
    }
    final String? memberId = effectiveMemberId(player);
    if (memberId == null) {
      return;
    }
    setState(() {
      _inviteesByMemberId[memberId] = player;
      _manualInviteeIds.add(memberId);
    });
  }

  void _removeInvitee(String memberId) {
    setState(() {
      _inviteesByMemberId.remove(memberId);
      _manualInviteeIds.remove(memberId);
      for (final Set<String> ids in _selectedMemberIdsByTeam.values) {
        ids.remove(memberId);
      }
      _selectedTeamIds.removeWhere(
        (String teamId) =>
            (_selectedMemberIdsByTeam[teamId] ?? const <String>{}).isEmpty,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar.show(
        context,
        context.l10n.createNonSportEventError,
        isError: true,
      );
      return;
    }

    final AppSession session = context.read<AppSession>();
    _ensureEndAfterStart();

    final DateTime startAt = _allDay
        ? DateTime(_startDate.year, _startDate.month, _startDate.day)
        : _combine(_startDate, _startTime);
    final DateTime endAt = _allDay
        ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
        : _combine(_endDate, _endTime);

    if (!endAt.isAfter(startAt) && !_allDay) {
      AppSnackbar.show(
        context,
        context.l10n.createNonSportEventInvalidRange,
        isError: true,
      );
      return;
    }
    if (_allDay && _endDate.isBefore(_startDate)) {
      AppSnackbar.show(
        context,
        context.l10n.createNonSportEventInvalidRange,
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String clubId = _teams
          .where(
            (Team team) =>
                team.keyTeam != null &&
                _selectedTeamIds.contains(team.keyTeam),
          )
          .map((Team team) => team.clubId?.trim() ?? '')
          .firstWhere((String id) => id.isNotEmpty, orElse: () => '');

      final NonSportEventCreateResult result;
      if (_isEditMode) {
        result = await _eventService.updateEvent(
          l10n: context.l10n,
          existing: widget.eventToEdit!,
          title: _titleController.text,
          startAt: startAt,
          endAt: endAt,
          allDay: _allDay,
          location: _locationController.text,
          teamIds: _selectedTeamIds.toList(),
          invitees: _inviteesByMemberId.values.toList(),
          editorUserId: user.uid,
        );
      } else {
        result = await _eventService.createEvent(
          l10n: context.l10n,
          title: _titleController.text,
          startAt: startAt,
          endAt: endAt,
          allDay: _allDay,
          location: _locationController.text,
          teamIds: _selectedTeamIds.toList(),
          invitees: _inviteesByMemberId.values.toList(),
          createdByUserId: user.uid,
          createdByMemberId: session.selectedPlayerId,
          seasonId: session.selectedSeason?.ref?.id,
          clubId: clubId,
        );
      }

      if (!mounted) {
        return;
      }

      widget.onSaved?.call();
      // Close create/edit dialog immediately; invite statuses open afterwards.
      Navigator.of(context).pop(result.event);
    } catch (error, stackTrace) {
      debugPrint('CreateNonSportEventSheet._submit failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        _isEditMode
            ? context.l10n.editNonSportEventError
            : context.l10n.createNonSportEventError,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final media = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: kIsWeb ? 16 : 0,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? l10n.editNonSportEventTitle
                            : l10n.createNonSportEventTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.actionClose,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.createNonSportEventTitleField,
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.createNonSportEventTitleRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _allDay,
                  onChanged: (bool value) => setState(() {
                    _allDay = value;
                    _ensureEndAfterStart();
                  }),
                  title: Text(l10n.createNonSportEventAllDay),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.createNonSportEventStartDate,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickStartDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          DateFormat.yMMMd(locale).format(_startDate),
                        ),
                      ),
                    ),
                    if (!_allDay) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickStartTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(_startTime.format(context)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.createNonSportEventEndDate,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickEndDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          DateFormat.yMMMd(locale).format(_endDate),
                        ),
                      ),
                    ),
                    if (!_allDay) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickEndTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(_endTime.format(context)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.createNonSportEventLocation,
                    hintText: l10n.createNonSportEventLocationHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.createNonSportEventInviteTeams,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (_teams.isEmpty)
                  Text(
                    l10n.createNonSportEventNoTeams,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  )
                else
                  ..._teams.map((Team team) {
                    final String teamId = team.keyTeam?.trim() ?? '';
                    final bool selected = _selectedTeamIds.contains(teamId);
                    final bool loading = _loadingTeamIds.contains(teamId);
                    final int selectedCount =
                        _selectedMemberIdsByTeam[teamId]?.length ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: selected,
                              onChanged: _isSubmitting || loading
                                  ? null
                                  : (bool? value) =>
                                      _toggleTeam(team, value == true),
                              title: Text(team.name ?? teamId),
                              subtitle: selected
                                  ? Text(
                                      l10n.createNonSportEventSelectedMembersCount(
                                        selectedCount,
                                      ),
                                    )
                                  : null,
                              secondary: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            if (selected)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isSubmitting || loading
                                      ? null
                                      : () => _selectTeamMembers(team),
                                  child: Text(
                                    l10n.createNonSportEventSelectMembers,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.createNonSportEventInviteOthers,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _addOtherProfile,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(l10n.createNonSportEventAddProfile),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_inviteesByMemberId.isEmpty)
                  Text(
                    l10n.createNonSportEventNoInvitees,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  )
                else
                  ..._inviteesByMemberId.entries.map((entry) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(playerDisplayName(entry.value)),
                      trailing: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _removeInvitee(entry.key),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isEditMode
                                    ? l10n.editNonSportEventSubmit
                                    : l10n.createNonSportEventSubmit,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
