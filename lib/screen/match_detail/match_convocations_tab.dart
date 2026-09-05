import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';

import '../../model/effectives.dart';
import '../../model/grinta_player.dart';
import '../../model/grinta_player_hw.dart';
import '../../model/match.dart' as models;
import '../../model/matchCompo.dart';
import '../../model/player.dart';
import '../../model/team.dart';
import '../../provider/appSession.dart';
import '../../services/effectivesService.dart';
import '../../services/subscription_service.dart';
import '../../services/user_trial_service.dart';
import '../../services/matchCompoService.dart';
import '../../services/member_invitation_service.dart';
import '../../services/playerService.dart';
import '../../services/teamService.dart';
import '../../services/team_players_service.dart';
import '../../util/app_theme.dart';
import '../../util/match_compo_pitch_mapper.dart';
import '../../util/match_convocation_helper.dart';
import '../../util/playerDisplayName.dart';
import '../../util/player_photo_resolver.dart';
import '../../util/soft_keyboard.dart';
import '../../widget/account_create_profile_entry.dart';
import '../../widget/add_grinta_player_sheet.dart';
import '../../widget/member_search_sheet.dart';
import '../../widget/player_name_filter_field.dart';
import '../../widget/playerPhoto.dart';
import '../../widget/send_match_convocations_sheet.dart';
import '../../widget/subscription_paywall.dart';
import '../team_players/training_team_players_presence.dart';

/// Onglet convocations pour convoquer les joueurs à un match.
class MatchConvocationsTab extends StatefulWidget {
  const MatchConvocationsTab({
    super.key,
    required this.match,
    required this.isManager,
  });

  final models.Match match;
  final bool isManager;

  @override
  State<MatchConvocationsTab> createState() => _MatchConvocationsTabState();
}

class _MatchConvocationsTabState extends State<MatchConvocationsTab>
    with AutomaticKeepAliveClientMixin {
  final _matchCompoService = MatchCompoService();
  final _teamPlayersService = TeamPlayersService();
  final _teamService = TeamService();
  final _playerService = PlayerService();
  final _effectivesService = EffectivesService();

  MatchCompo? _cachedMatchCompo;
  Stream<MatchCompo?>? _matchCompoStream;
  String? _streamMatchId;
  List<String> _streamProfileTeamIds = const <String>[];
  String? _streamPreferredTeamId;

  bool _loadingPlayers = true;
  String? _resolvedTeamId;
  Team? _team;
  List<Player> _teamPlayers = [];
  MatchCompo? _draftCompo;
  bool _saving = false;

  /// Owned by the keep-alive tab so StreamBuilder rebuilds / body remounts
  /// cannot dispose the filter mid-typing (mobile focus regression).
  final TextEditingController _nameFilterCtrl = TextEditingController();
  final FocusNode _nameFilterFocus = FocusNode();

  @override
  bool get wantKeepAlive => true;

  bool get _canEdit =>
      widget.isManager && widget.match.isMatchPlayed != true;

  @override
  void dispose() {
    _nameFilterCtrl.dispose();
    _nameFilterFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final matchId = widget.match.id?.trim() ?? '';
    final appSession = context.read<AppSession>();
    final profileTeamIds = profileTeamIdsForMatch(
      profileTeamIds: appSession.teamIdsForSelectedSeason,
      match: widget.match,
    );
    final preferredTeamId = resolveTeamIdForMatch(
      widget.match,
      managedTeamIds: appSession.managedTeamsIdsForSelectedSeason,
    );

    final bool streamInputsChanged = _streamMatchId != matchId ||
        !_setEquals(_streamProfileTeamIds, profileTeamIds) ||
        _streamPreferredTeamId != preferredTeamId;

    if (streamInputsChanged) {
      _streamMatchId = matchId;
      _streamProfileTeamIds = List<String>.from(profileTeamIds);
      _streamPreferredTeamId = preferredTeamId;
      _matchCompoStream = matchId.isEmpty
          ? Stream<MatchCompo?>.value(null)
          : _matchCompoService.streamMatchCompoForMatchAndTeamIds(
              matchId,
              profileTeamIds: profileTeamIds,
              preferredTeamId: preferredTeamId,
            );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTeamPlayers();
  }

  bool _setEquals(List<String> a, List<String> b) {
    return Set<String>.from(a).containsAll(b) &&
        Set<String>.from(b).containsAll(a);
  }

  Future<void> _loadTeamPlayers() async {
    final managedTeamIds =
        context.read<AppSession>().managedTeamsIdsForSelectedSeason;
    final teamId = resolveTeamIdForMatch(
      widget.match,
      matchCompo: _draftCompo ?? _cachedMatchCompo,
      managedTeamIds: managedTeamIds,
    );

    if (teamId == null || teamId.isEmpty) {
      if (mounted) {
        setState(() {
          _resolvedTeamId = null;
          _team = null;
          _teamPlayers = [];
          _loadingPlayers = false;
        });
      }
      return;
    }

    try {
      final team = await _teamService.getTeamById(teamId);
      final players = await _teamPlayersService.loadPlayers(teamId: teamId);

      if (mounted) {
        setState(() {
          _resolvedTeamId = teamId;
          _team = team;
          _teamPlayers = players;
          _loadingPlayers = false;
        });
        await _ensureConvokedPlayersLoaded();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedTeamId = teamId;
          _loadingPlayers = false;
        });
      }
    }
  }

  Future<void> _ensureConvokedPlayersLoaded() async {
    final convocations = _draftCompo?.convocation ?? const <PlayerConvo>[];
    if (convocations.isEmpty) {
      return;
    }

    final rosterLookupIds = _rosterMemberLookupIds();

    final missingIds = convocations
        .map((c) => c.playerID?.trim() ?? '')
        .where((id) => id.isNotEmpty && !rosterLookupIds.contains(id))
        .toList();

    if (missingIds.isEmpty) {
      return;
    }

    final extraPlayers = <Player>[];
    for (final id in missingIds) {
      final player = await _playerService.getPlayerById(id);
      if (player != null) {
        extraPlayers.add(player);
      }
    }

    if (extraPlayers.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _teamPlayers = TeamPlayersService.dedupePlayersByMemberId(
        <Player>[..._teamPlayers, ...extraPlayers],
      )..sort(TeamPlayersService.comparePlayersByName);
    });
  }

  Set<String> _rosterMemberLookupIds() {
    return <String>{
      for (final Player player in _teamPlayers)
        ...playerMemberLookupIds(player),
    };
  }

  void _hydrateFromMatchCompo(MatchCompo? compo) {
    if (compo == null) {
      setState(() => _draftCompo = null);
      return;
    }
    _draftCompo = compo;
    setState(() {});
    _ensureConvokedPlayersLoaded();
  }

  /// Copies starters/subs/meta from [remote] without touching convocations.
  void _syncLineupFromRemote(MatchCompo draft, MatchCompo remote) {
    draft.goalkeeper = List<PlayerCompo>.from(remote.goalkeeper ?? const []);
    draft.defender = List<PlayerCompo>.from(remote.defender ?? const []);
    draft.midfielder = List<PlayerCompo>.from(remote.midfielder ?? const []);
    draft.midfielderAttaking =
        List<PlayerCompo>.from(remote.midfielderAttaking ?? const []);
    draft.midfielderDefensive =
        List<PlayerCompo>.from(remote.midfielderDefensive ?? const []);
    draft.stricker = List<PlayerCompo>.from(remote.stricker ?? const []);
    draft.substitute = List<PlayerCompo>.from(remote.substitute ?? const []);
    draft.compoTypeID = remote.compoTypeID;
    draft.seasonID = remote.seasonID ?? draft.seasonID;
    draft.withFeedback = remote.withFeedback;
    draft.ref = remote.ref ?? draft.ref;
  }

  /// True when local convocation answers match the Firestore snapshot.
  bool _convocationsMatchRemote(MatchCompo? draft, MatchCompo? remote) {
    if (draft == null || remote == null) {
      return draft == remote;
    }

    final draftList = draft.convocation ?? const <PlayerConvo>[];
    final remoteList = remote.convocation ?? const <PlayerConvo>[];
    if (draftList.length != remoteList.length) {
      return false;
    }

    final remoteByPlayerId = <String, PlayerConvo>{};
    for (final PlayerConvo convo in remoteList) {
      final id = convo.playerID?.trim();
      if (id != null && id.isNotEmpty) {
        remoteByPlayerId[id] = convo;
      }
    }

    for (final PlayerConvo convo in draftList) {
      final id = convo.playerID?.trim();
      if (id == null || id.isEmpty) {
        return false;
      }
      final other = remoteByPlayerId[id];
      if (other == null) {
        return false;
      }
      if (convo.isPresent != other.isPresent ||
          convo.asAnswer != other.asAnswer) {
        return false;
      }
    }
    return true;
  }

  Map<String, PlayerConvo> get _convocationsByPlayerId {
    final map = <String, PlayerConvo>{};
    for (final PlayerConvo convo in _draftCompo?.convocation ?? const []) {
      final id = convo.playerID?.trim();
      if (id != null && id.isNotEmpty) {
        map[id] = convo;
      }
    }
    return map;
  }

  Future<void> _saveConvocations(List<PlayerConvo> convocations) async {
    if (!_canEdit || _saving) {
      return;
    }

    final matchId = widget.match.id?.trim();
    final teamId = _resolvedTeamId ??
        resolveTeamIdForMatch(
          widget.match,
          matchCompo: _draftCompo,
          managedTeamIds:
              context.read<AppSession>().managedTeamsIdsForSelectedSeason,
        );
    if (matchId == null || matchId.isEmpty) {
      return;
    }
    if (teamId == null || teamId.isEmpty) {
      return;
    }

    setState(() => _saving = true);

    try {
      // Write convocations only. A full MatchCompo.toMap() merge would overwrite
      // starters/subs with a stale keep-alive draft (e.g. wipe 4-3-3 right-back).
      await _matchCompoService.saveMatchCompoConvocations(
        matchId: matchId,
        teamId: teamId,
        seasonId: widget.match.seasonID,
        convocations: convocations,
      );

      final compo = _draftCompo ??
          MatchCompo(
            matchID: matchId,
            teamID: teamId,
            seasonID: widget.match.seasonID,
          );
      compo.matchID = matchId;
      compo.teamID = teamId;
      compo.seasonID = widget.match.seasonID;
      compo.convocation = convocations;
      _draftCompo = compo;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.matchConvocationsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _onPlayerToggled(String playerId, bool selected) async {
    if (!_canEdit) {
      return;
    }

    if (selected) {
      final player = _playerByMemberId(playerId);
      if (player != null &&
          _isPlayerUnavailableOnMatchDate(player, managerView: true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.matchPlayerCannotConvokeUnavailable)),
          );
        }
        return;
      }
    }

    final convocations = toggleConvocation(
      convocations: List<PlayerConvo>.from(
        _draftCompo?.convocation ?? const <PlayerConvo>[],
      ),
      playerId: playerId,
      selected: selected,
    );

    setState(() {
      _draftCompo ??= MatchCompo(
        matchID: widget.match.id,
        teamID: _resolvedTeamId,
        seasonID: widget.match.seasonID,
      );
      _draftCompo!.convocation = convocations;
    });

    await _saveConvocations(convocations);
  }

  Player? _playerByMemberId(String memberId) {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) return null;
    for (final player in _teamPlayers) {
      if (playerMemberLookupIds(player).contains(trimmed)) {
        return player;
      }
    }
    return null;
  }

  String? get _seasonId => widget.match.seasonID?.trim();

  DateTime? get _matchEventDate => matchEventDateTime(widget.match);

  bool _isPlayerUnavailableOnMatchDate(
    Player player, {
    required bool managerView,
  }) {
    return isPlayerUnavailableOnDate(
      player,
      _seasonId,
      _matchEventDate,
      managerView: managerView,
    );
  }

  bool _teamHasLegacyPlayers(Team team) {
    for (final dynamic rawId in team.players ?? const <dynamic>[]) {
      if (rawId?.toString().trim().isNotEmpty == true) {
        return true;
      }
    }
    return false;
  }

  bool _teamUsesGrintaRoster(Team team) {
    if (_teamHasLegacyPlayers(team)) {
      return false;
    }
    if (team.isGrinta == true) {
      return true;
    }
    for (final GrintaPlayer entry in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      if (entry.playerId.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Set<String> _rosterPlayerIds() => _rosterMemberLookupIds();

  Future<void> _onAddPlayerPressed() async {
    if (!_canEdit || _saving) {
      return;
    }

    await UserTrialService.instance.ensureInitialized();
    await SubscriptionService.instance.refreshForActiveSession();
    if (!UserTrialService.instance.hasPremiumAccess) {
      if (!mounted) {
        return;
      }
      final appSession = context.read<AppSession>();
      await SubscriptionPaywall.show(
        context,
        allowSkip: true,
        initialKind: prefersCoachSubscriptionOffering(appSession)
            ? SubscriptionOfferingKind.coach
            : SubscriptionOfferingKind.player,
      );
      return;
    }

    await _addPlayerToTeam();
  }

  Future<void> _addPlayerToTeam() async {
    if (!_canEdit || _saving) {
      return;
    }

    final teamId = _resolvedTeamId?.trim();
    final team = _team;
    if (teamId == null || teamId.isEmpty || team == null) {
      return;
    }

    final l10n = context.l10n;
    final selected = await showMemberSearchSheet(
      context,
      title: l10n.actionAddPlayer,
      excludeMemberIds: _rosterPlayerIds(),
      showCreateButton: _teamUsesGrintaRoster(team),
    );
    if (selected == null || !mounted) {
      return;
    }

    if (_isPlayerUnavailableOnMatchDate(selected, managerView: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchPlayerCannotConvokeUnavailable)),
      );
      return;
    }

    final String? memberId = effectiveMemberId(selected);
    if (memberId == null || memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.entityPlayerUnknown)),
      );
      return;
    }

    try {
      if (_teamUsesGrintaRoster(team)) {
        final AddGrintaPlayerDetails? details = await showAddGrintaPlayerSheet(
          context,
          member: selected,
          onSubmit: (playerDetails) async {
            final invitationResult =
                await MemberInvitationService.instance.notifyOrInviteMember(
              l10n: l10n,
              member: selected,
              memberId: memberId,
              email: playerDetails.email ?? '',
              phoneE164: playerDetails.phoneE164,
              teamId: teamId,
              seasonId: widget.match.seasonID,
              teamName: team.name ?? '',
            );
            if (!invitationResult.success &&
                !invitationResult.invitationCreated) {
              throw StateError(invitationResult.error ?? '');
            }

            final List<GrintaPlayerHW> hwHistory =
                playerDetails.initialMeasurement != null
                    ? <GrintaPlayerHW>[playerDetails.initialMeasurement!]
                    : const <GrintaPlayerHW>[];

            await TeamService().addGrintaPlayer(
              teamId: teamId,
              player: GrintaPlayer(
                playerId: memberId,
                positions: List<int>.from(playerDetails.positions),
                email: playerDetails.email,
                phoneE164: playerDetails.phoneE164,
                birthday: playerDetails.birthday,
                hwHistory: hwHistory,
                invitationId: invitationResult.invitationId,
                preferredFoot: playerDetails.preferredFoot,
              ),
              firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
            );
          },
        );
        if (details == null || !mounted) {
          return;
        }
      } else {
        final String? seasonId = widget.match.seasonID?.trim();
        if (seasonId == null || seasonId.isEmpty) {
          throw StateError('Missing seasonId for legacy player add');
        }

        await _effectivesService.addEffectives(
          Effectives(
            memberID: memberId,
            seasonID: seasonId,
            teamID: teamId,
            type: 0,
            clubId: team.clubId?.trim() ?? '',
          ),
        );
        await TeamService().addPlayer(teamId: teamId, playerId: memberId);
      }

      if (!mounted) {
        return;
      }

      await _loadTeamPlayers();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.actionAddPlayer}: ${playerDisplayName(selected, unknownLabel: l10n.entityPlayer)}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final matchId = widget.match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return _ConvocationsEmptyState(
        icon: Icons.groups_outlined,
        message: context.l10n.matchConvocationsUnavailable,
      );
    }

    // Keep the name filter outside StreamBuilder: Firestore / hydrate
    // rebuilds were remounting the TextField and dropping mobile focus.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: PlayerNameFilterField(
            key: const ValueKey('match-convocations-name-filter'),
            controller: _nameFilterCtrl,
            focusNode: _nameFilterFocus,
          ),
        ),
        Expanded(
          child: StreamBuilder<MatchCompo?>(
            stream: _matchCompoStream ?? Stream<MatchCompo?>.value(null),
            builder: (context, snapshot) {
        if (snapshot.hasData) {
          final streamCompo = snapshot.data;
          _cachedMatchCompo = streamCompo;
          final shouldHydrate = !_saving &&
              (_draftCompo == null ||
                  !_convocationsMatchRemote(_draftCompo, streamCompo));
          if (shouldHydrate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_saving) {
                _hydrateFromMatchCompo(streamCompo);
              }
            });
          } else if (!_saving &&
              streamCompo != null &&
              _draftCompo != null) {
            // Keep lineup fields fresh while preserving local convocation edits.
            _syncLineupFromRemote(_draftCompo!, streamCompo);
          }
        }

        final matchCompo = _draftCompo ?? _cachedMatchCompo;

        final waitingForFirstData = matchCompo == null &&
            _loadingPlayers &&
            !snapshot.hasError &&
            snapshot.connectionState == ConnectionState.waiting;

        if (waitingForFirstData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: context.appColors.primary),
                const SizedBox(height: 16),
                Text(
                  context.l10n.trainingPlayersLoading,
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _ConvocationsEmptyState(
            icon: Icons.error_outline_rounded,
            message: '${snapshot.error}',
          );
        }

        return _ConvocationsBody(
          key: const ValueKey('match-convocations-body'),
          match: widget.match,
          players: _teamPlayers,
          convocationsByPlayerId: _convocationsByPlayerId,
          seasonId: _seasonId,
          matchEventDate: _matchEventDate,
          managerView: widget.isManager,
          canEdit: _canEdit,
          canSendConvocations:
              widget.isManager && _convocationsByPlayerId.isNotEmpty,
          saving: _saving,
          nameFilterCtrl: _nameFilterCtrl,
          onPlayerToggled: _onPlayerToggled,
          onAddPlayer: _onAddPlayerPressed,
        );
            },
          ),
        ),
      ],
    );
  }
}

class _ConvocationsBody extends StatefulWidget {
  const _ConvocationsBody({
    super.key,
    required this.match,
    required this.players,
    required this.convocationsByPlayerId,
    required this.seasonId,
    required this.matchEventDate,
    required this.managerView,
    required this.canEdit,
    required this.canSendConvocations,
    required this.saving,
    required this.nameFilterCtrl,
    required this.onPlayerToggled,
    required this.onAddPlayer,
  });

  final models.Match match;
  final List<Player> players;
  final Map<String, PlayerConvo> convocationsByPlayerId;
  final String? seasonId;
  final DateTime? matchEventDate;
  final bool managerView;
  final bool canEdit;
  final bool canSendConvocations;
  final bool saving;
  final TextEditingController nameFilterCtrl;
  final Future<void> Function(String playerId, bool selected) onPlayerToggled;
  final Future<void> Function() onAddPlayer;

  @override
  State<_ConvocationsBody> createState() => _ConvocationsBodyState();
}

class _ConvocationsBodyState extends State<_ConvocationsBody> {
  List<Player> get _convokedPlayers {
    return widget.players.where((player) {
      if (!_isPlayerConvoked(player)) return false;
      return !isPlayerUnavailableOnDate(
        player,
        widget.seasonId,
        widget.matchEventDate,
        managerView: widget.managerView,
      );
    }).toList();
  }

  List<Player> get _filteredPlayers {
    return widget.players
        .where(
          (Player player) =>
              playerMatchesNameQuery(player, widget.nameFilterCtrl.text),
        )
        .toList();
  }

  bool _isPlayerUnavailable(Player player) {
    return isPlayerUnavailableOnDate(
      player,
      widget.seasonId,
      widget.matchEventDate,
      managerView: widget.managerView,
    );
  }

  bool _isPlayerConvoked(Player player) {
    for (final String id in playerMemberLookupIds(player)) {
      if (widget.convocationsByPlayerId.containsKey(id)) {
        return true;
      }
    }
    return false;
  }

  PlayerConvo? _convoForPlayer(Player player) {
    for (final String id in playerMemberLookupIds(player)) {
      final PlayerConvo? convo = widget.convocationsByPlayerId[id];
      if (convo != null) {
        return convo;
      }
    }
    return null;
  }

  Future<void> _onSendConvocations(BuildContext context) async {
    if (widget.saving) return;
    await showSendMatchConvocationsSheet(
      context,
      match: widget.match,
      convokedPlayers: _convokedPlayers,
    );
  }

  Widget _buildPlayerTile({
    required BuildContext context,
    required Player player,
  }) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final playerId = effectiveMemberId(player) ?? '';
    final convo = _convoForPlayer(player);
    final isConvoked = convo != null;
    final isUnavailable = _isPlayerUnavailable(player);
    final cardBackground = isUnavailable
        ? colors.warning.withValues(alpha: 0.12)
        : convocationCardBackground(colors, convo) ?? colors.card;
    final titleColor =
        isUnavailable ? colors.textSecondary : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnavailable
                ? colors.warning.withValues(alpha: 0.35)
                : colors.border,
          ),
        ),
        child: widget.canEdit
            ? CheckboxListTile(
                value: isConvoked,
                activeColor: colors.primary,
                onChanged: widget.canEdit &&
                        playerId.isNotEmpty &&
                        !widget.saving
                    ? (value) {
                        if (value == true && isUnavailable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.matchPlayerCannotConvokeUnavailable,
                              ),
                            ),
                          );
                          return;
                        }
                        widget.onPlayerToggled(playerId, value == true);
                      }
                    : null,
                secondary: Opacity(
                  opacity: isUnavailable ? 0.55 : 1,
                  child: PlayerPhoto(player: player, radius: 20),
                ),
                title: Text(
                  playerDisplayName(
                    player,
                    unknownLabel: l10n.entityPlayer,
                  ),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: _buildSubtitle(
                  l10n: l10n,
                  colors: colors,
                  convo: convo,
                  isConvoked: isConvoked,
                  isUnavailable: isUnavailable,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              )
            : ListTile(
                leading: Opacity(
                  opacity: isUnavailable ? 0.55 : 1,
                  child: PlayerPhoto(player: player, radius: 20),
                ),
                title: Text(
                  playerDisplayName(
                    player,
                    unknownLabel: l10n.entityPlayer,
                  ),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: _buildSubtitle(
                  l10n: l10n,
                  colors: colors,
                  convo: convo,
                  isConvoked: isConvoked,
                  isUnavailable: isUnavailable,
                ),
                trailing: isConvoked
                    ? Icon(
                        convo.isPresent == true && convo.asAnswer == true
                            ? Icons.check_circle_outline
                            : Icons.schedule_outlined,
                        color: convo.isPresent == true &&
                                convo.asAnswer == true
                            ? colors.success
                            : colors.warning,
                      )
                    : null,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (widget.players.isEmpty) {
      return _ConvocationsEmptyState(
        icon: Icons.groups_outlined,
        message: l10n.emptyNoPlayerForTeam,
        action: widget.canEdit
            ? ListenableBuilder(
                listenable: Listenable.merge([
                  SubscriptionService.instance,
                  UserTrialService.instance,
                ]),
                builder: (context, _) {
                  final showPremiumBadge =
                      !UserTrialService.instance.hasPremiumAccess;

                  return FilledButton(
                    onPressed: widget.saving ? null : widget.onAddPlayer,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_outlined),
                        const SizedBox(width: 8),
                        Text(l10n.actionAddPlayer),
                        if (showPremiumBadge) ...[
                          const SizedBox(width: 8),
                          SubscriptionPremiumBadge(
                            colors: colors,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              )
            : null,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      floatingActionButton:
          widget.canEdit && !isSoftKeyboardOpen(context)
          ? ListenableBuilder(
              listenable: Listenable.merge([
                SubscriptionService.instance,
                UserTrialService.instance,
              ]),
              builder: (context, _) {
                final showPremiumBadge =
                    !UserTrialService.instance.hasPremiumAccess;

                return FloatingActionButton(
                  tooltip: l10n.actionAddPlayer,
                  onPressed: widget.saving ? null : widget.onAddPlayer,
                  child: SubscriptionPremiumBadge.withIconOverlay(
                    context: context,
                    colors: colors,
                    showPremium: showPremiumBadge,
                    icon: const Icon(Icons.person_add_outlined),
                  ),
                );
              },
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canSendConvocations && !isSoftKeyboardOpen(context))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FilledButton.icon(
                onPressed: widget.saving
                    ? null
                    : () => _onSendConvocations(context),
                icon: const Icon(Icons.send_rounded),
                label: Text(l10n.matchConvocationsSendAction),
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.nameFilterCtrl,
              builder: (context, _, __) {
                final List<Player> filteredPlayers = _filteredPlayers;
                final bool showEmptyFilterResult = filteredPlayers.isEmpty;

                if (showEmptyFilterResult) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.emptyNoPlayerForTeam,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    return _buildPlayerTile(
                      context: context,
                      player: filteredPlayers[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSubtitle({
    required dynamic l10n,
    required AppColors colors,
    required PlayerConvo? convo,
    required bool isConvoked,
    required bool isUnavailable,
  }) {
    final lines = <String>[];
    if (isUnavailable) {
      lines.add(l10n.matchPlayerUnavailableOnMatchDate);
    }
    if (isConvoked && convo != null) {
      lines.add(_statusLabel(l10n, convo));
    }
    if (lines.isEmpty) return null;

    return Text(
      lines.join(' · '),
      style: TextStyle(
        color: isUnavailable ? colors.warning : colors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  String _statusLabel(dynamic l10n, PlayerConvo convo) {
    if (convo.isPresent == true && convo.asAnswer == true) {
      return l10n.matchConvocationsStatusPresent;
    }
    return l10n.matchConvocationsStatusPending;
  }
}

class _ConvocationsEmptyState extends StatelessWidget {
  const _ConvocationsEmptyState({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
