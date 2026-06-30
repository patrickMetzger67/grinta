import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/engagement_sync.dart';
import 'package:grinta/util/subscription_limits_access.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/team_detail_access.dart';
import 'package:grinta/widget/club_picker_sheet.dart';
import 'package:grinta/widget/equipe_picker_sheet.dart';
import 'package:provider/provider.dart';

class _TeamCreationDraft {
  const _TeamCreationDraft({
    required this.name,
    required this.soccerType,
    this.clubAffiliation,
    this.selectedEquipes = const <Equipe>[],
  });

  final String name;
  final int soccerType;
  final String? clubAffiliation;
  final List<Equipe> selectedEquipes;
}

/// Opens the gated team creation flow (limits, dialog, create, optional detail nav).
Future<void> openTeamCreationFlow(BuildContext context) async {
  final appSession = context.read<AppSession>();
  final seasonId = appSession.selectedSeason?.ref?.id.trim();
  if (seasonId == null || seasonId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.emptyNoCurrentSeason,
      isError: true,
    );
    return;
  }

  final String? userId =
      appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
  if (userId == null || userId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.infoUserNotConnected,
      isError: true,
    );
    return;
  }

  await SubscriptionLimitsService.instance.ensureInitialized();
  await SubscriptionService.instance.refreshForActiveSession();
  await UserTrialService.instance.ensureInitialized();

  final Player? player = appSession.selectedPlayer;
  final String? playerId = player?.keyMember ?? appSession.selectedPlayerId;

  final teamCount = await SubscriptionLimitsService.instance.countTeamsForUser(
    userId: userId,
    seasonId: seasonId,
    playerId: playerId,
    player: player,
  );
  final gate = SubscriptionLimitsService.instance.resolveTeamCreationGate(
    teamCount,
  );

  switch (gate) {
    case TeamCreationGate.allowed:
      break;
    case TeamCreationGate.needsUpgrade:
      if (!context.mounted) return;
      final maxTeams =
          await SubscriptionLimitsService.instance.maxTeamsForUser();
      if (!context.mounted) return;
      await SubscriptionLimitsAccess.showTeamLimitExceeded(
        context,
        SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxTeams,
          tier: SubscriptionLimitsService.instance.resolveEffectiveTier(),
          limit: maxTeams,
          requiresUpgrade: true,
        ),
      );
      return;
    case TeamCreationGate.atMaxLimit:
      if (!context.mounted) return;
      final max = await SubscriptionLimitsService.instance.maxTeamsForUser();
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.subscriptionLimitMaxTeamsReached(max),
        isError: true,
      );
      return;
  }

  if (!context.mounted) return;

  final draft = await _promptTeamCreation(context);
  if (draft == null || !context.mounted) return;

  if (draft.name.trim().isEmpty) {
    AppSnackbar.show(
      context,
      context.l10n.hintRequiredField,
      isError: true,
    );
    return;
  }

  if (playerId == null || playerId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.infoUserNotConnected,
      isError: true,
    );
    return;
  }

  try {
    final bool autoAddCreatorToRoster =
        shouldAutoAddMemberProfileToTeamRoster(player?.positionCodes ?? const []);

    final GrintaPlayer? creatorGrintaPlayer = autoAddCreatorToRoster
        ? _grintaPlayerFromProfile(
            playerId: playerId,
            player: player,
          )
        : null;

    final team = Team(
      name: draft.name,
      seasonID: seasonId,
      players: autoAddCreatorToRoster ? <dynamic>[playerId] : <dynamic>[],
      users: <dynamic>[userId],
      order: 1,
      soccerType: draft.soccerType,
      teamIdInTeamsPerClub: _firstSelectedEquipeId(draft.selectedEquipes),
      category: player?.category,
      clubId: draft.clubAffiliation,
      isGrinta: true,
      uid: userId,
      grintaPlayers: creatorGrintaPlayer == null
          ? <GrintaPlayer>[]
          : <GrintaPlayer>[creatorGrintaPlayer],
    )..isVisible = true;

    final String teamId = await TeamService().createTeam(team);
    team.keyTeam = teamId;

    if (draft.clubAffiliation != null &&
        draft.clubAffiliation!.isNotEmpty &&
        draft.selectedEquipes.isNotEmpty) {
      await syncEngagementsForEquipes(
        grintaTeamId: teamId,
        clubId: draft.clubAffiliation!,
        seasonId: seasonId,
        equipes: draft.selectedEquipes,
      );
    }

    await appSession.init();
    if (!context.mounted) return;

    if (isTeamDetailBlockedForUser(
      team,
      userId,
      memberProfile: player,
    )) {
      AppSnackbar.show(
        context,
        context.l10n.subscriptionLimitTeamCreatedFreePlayer,
      );
      return;
    }

    await Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamDetail,
        builder: (_) => TeamDetailScreen(
          team: team,
          seasonId: seasonId,
          isManager: true,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('openTeamCreationFlow failed: $e');
    debugPrint('$stackTrace');
    if (!context.mounted) return;
    if (e is SubscriptionLimitExceeded) {
      SubscriptionLimitsAccess.showLimitExceeded(context, e);
      return;
    }
    AppSnackbar.show(
      context,
      context.l10n.errorGeneric(e.toString()),
      isError: true,
    );
  }
}

String? _firstSelectedEquipeId(List<Equipe> equipes) {
  if (equipes.isEmpty) return null;
  final equipeId = equipes.first.id?.trim() ?? '';
  return equipeId.isEmpty ? null : equipeId;
}

GrintaPlayer _grintaPlayerFromProfile({
  required String playerId,
  required Player? player,
}) {
  return GrintaPlayer(
    playerId: playerId,
    positions: List<int>.from(player?.positionCodes ?? const <int>[]),
    email: player?.email,
    phoneE164: player?.phoneE164,
    birthday: Player.parseBirthDay(player?.birthDay),
  );
}

Future<_TeamCreationDraft?> _promptTeamCreation(BuildContext context) {
  return showDialog<_TeamCreationDraft>(
    context: context,
    builder: (dialogContext) => const _TeamCreationDialog(),
  );
}

class _TeamCreationDialog extends StatefulWidget {
  const _TeamCreationDialog();

  @override
  State<_TeamCreationDialog> createState() => _TeamCreationDialogState();
}

class _TeamCreationDialogState extends State<_TeamCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _attachToClub = false;
  String? _selectedAffiliation;
  String? _selectedClubName;
  String? _selectedClubLogo;
  String? _clubValidationError;
  List<Equipe> _selectedEquipes = <Equipe>[];
  int _selectedSoccerType = 11;
  String? _autoFilledTeamName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearAutoFilledTeamNameIfNeeded() {
    if (_autoFilledTeamName == null) return;
    if (_nameController.text.trim() == _autoFilledTeamName) {
      _nameController.text = '';
    }
    _autoFilledTeamName = null;
  }

  void _syncTeamNameFromEquipes(List<Equipe> equipes) {
    if (!_attachToClub || equipes.isEmpty) {
      _clearAutoFilledTeamNameIfNeeded();
      return;
    }

    final defaultName = equipes.first.name?.trim() ?? '';
    if (defaultName.isEmpty) return;

    final currentTrimmed = _nameController.text.trim();
    if (currentTrimmed.isEmpty ||
        (_autoFilledTeamName != null &&
            currentTrimmed == _autoFilledTeamName)) {
      _nameController.text = defaultName;
      _autoFilledTeamName = defaultName;
    }
  }

  String? _defaultNameFromSelectedEquipes() {
    if (!_attachToClub || _selectedEquipes.isEmpty) return null;
    final name = _selectedEquipes.first.name?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  Future<void> _pickClub() async {
    final club = await showClubPickerSheet(context);
    if (!mounted || club == null) return;
    setState(() {
      _selectedAffiliation = club.affiliation?.trim();
      _selectedClubName = club.name?.trim();
      _selectedClubLogo = club.logo?.trim();
      _selectedEquipes = <Equipe>[];
      _clubValidationError = null;
      _clearAutoFilledTeamNameIfNeeded();
    });
  }

  Future<void> _pickEquipes() async {
    final affiliation = _selectedAffiliation?.trim();
    final seasonId =
        context.read<AppSession>().selectedSeason?.ref?.id.trim();
    if (affiliation == null ||
        affiliation.isEmpty ||
        seasonId == null ||
        seasonId.isEmpty) {
      return;
    }

    final equipes = await showEquipePickerSheet(
      context,
      clubId: affiliation,
      seasonId: seasonId,
      initialSelection: _selectedEquipes,
    );
    if (!mounted || equipes == null) return;
    setState(() {
      _selectedEquipes = equipes;
      _syncTeamNameFromEquipes(equipes);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final l10n = context.l10n;

    if (_attachToClub &&
        (_selectedAffiliation == null || _selectedAffiliation!.isEmpty)) {
      setState(() {
        _clubValidationError = l10n.teamCreationClubRequired;
      });
      return;
    }

    final trimmedName = _nameController.text.trim();
    final resolvedName = trimmedName.isNotEmpty
        ? trimmedName
        : (_defaultNameFromSelectedEquipes() ?? '');

    if (resolvedName.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }

    final hasClubLinked = _attachToClub &&
        _selectedAffiliation != null &&
        _selectedAffiliation!.trim().isNotEmpty;

    if (!hasClubLinked) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (warningContext) {
          final warningColors = warningContext.appColors;
          return AlertDialog(
            title: Text(l10n.teamCreationNoClubWarningTitle),
            content: Text(l10n.teamCreationNoClubWarning),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: warningColors.border),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(warningContext).pop(false),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(warningContext).pop(true),
                child: Text(l10n.actionOk),
              ),
            ],
          );
        },
      );

      if (proceed != true || !mounted) return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      _TeamCreationDraft(
        name: resolvedName,
        soccerType: _selectedSoccerType,
        clubAffiliation: _attachToClub ? _selectedAffiliation : null,
        selectedEquipes:
            _attachToClub ? _selectedEquipes : const <Equipe>[],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.actionCreateTeam),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.entityTeam,
              ),
              validator: (value) {
                if ((value ?? '').trim().isNotEmpty) return null;
                if (_defaultNameFromSelectedEquipes() != null) {
                  return null;
                }
                return l10n.hintRequiredField;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedSoccerType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.teamCreationSoccerType,
              ),
              items: const <int>[5, 8, 11]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedSoccerType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.teamCreationAttachClubQuestion,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.actionNo),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.actionYes),
                ),
              ],
              selected: {_attachToClub},
              onSelectionChanged: (selection) {
                setState(() {
                  _attachToClub = selection.first;
                  _clubValidationError = null;
                  if (!_attachToClub) {
                    _selectedAffiliation = null;
                    _selectedClubName = null;
                    _selectedClubLogo = null;
                    _selectedEquipes = <Equipe>[];
                    _clearAutoFilledTeamNameIfNeeded();
                  }
                });
              },
            ),
            if (_attachToClub) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickClub,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.teamCreationSelectClub,
                    errorText: _clubValidationError,
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  ),
                  child: Row(
                    children: [
                      if (_selectedClubName != null) ...[
                        ClubLogo(url: _selectedClubLogo ?? ''),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          _selectedClubName ?? l10n.teamCreationSelectClub,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _selectedClubName == null
                                    ? colors.textSecondary
                                    : colors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedAffiliation != null &&
                  _selectedAffiliation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickEquipes,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.teamCreationSelectClubTeams,
                      suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                    ),
                    child: _selectedEquipes.isEmpty
                        ? Text(
                            l10n.teamCreationSelectClubTeams,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.textSecondary),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.teamCreationSelectedClubTeamsCount(
                                  _selectedEquipes.length,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedEquipes
                                    .map(
                                      (equipe) => Chip(
                                        label: Text(
                                          equipe.name?.trim() ?? '',
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.actionCreateTeam),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
    );
  }
}
