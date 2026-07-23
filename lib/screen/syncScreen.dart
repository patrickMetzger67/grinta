import 'package:firebase_auth/firebase_auth.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/answerService.dart';
import 'package:grinta/services/effectivesService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/tracker/tracker_hub_page.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/widget/uploadTrackerButton.dart';
import 'package:provider/provider.dart';

import '../model/answer.dart';
import '../model/fieldGpsCorners.dart';
import '../model/match.dart' as match_model;
import '../model/matchCompo.dart';
import '../model/season.dart';
import '../model/team.dart';
import '../model/training.dart';
import '../model/feature_discovery_ids.dart';
import '../util/app_theme.dart';
import '../util/field_gps_localization_helper.dart';
import '../widget/feature_discovery_random_banner.dart';
import '../widget/nav_icon_count_badge.dart';


class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final MatchService _matchService = MatchService();
  final TrackerFieldService _trackerFieldService = TrackerFieldService();
  String? _selectedTeamId;

  Season? currentSeason;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    currentSeason = context.watch<AppSession>().selectedSeason;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.navHome,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: colors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureDiscoveryRandomBanner(
            parentScreenId: FeatureDiscoveryIds.tabSync,
            includeBaseScreens: false,
          ),
          Card(
            color: colors.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildTeamsDropdown(
                context: context,
                colors: colors,
                textTheme: textTheme,
                seasonId: currentSeason?.ref!.id,
                userId: userId,
              ),
            ),
          ),

        ],
      ),
    );
  }

  String? _trackerLabelFromDeviceOwner(DeviceOwner deviceOwner) {
    final customName = deviceOwner.customName?.trim();
    if (customName == null || customName.isEmpty) {
      return null;
    }
    return customName;
  }

  Future<String?> _resolveTrackerIdForMatchPlayer({
    required PlayerCompo playerCompo,
    required Map<String, DeviceOwner> ownerDevicesByDocId,
    required String? seasonId,
  }) async {
    final directName = playerCompo.customName?.trim();
    if (directName != null && directName.isNotEmpty) {
      return directName;
    }

    final deviceOwnerDocId = playerCompo.deviceOwnerId?.trim();
    if (deviceOwnerDocId != null && deviceOwnerDocId.isNotEmpty) {
      final deviceOwner = ownerDevicesByDocId[deviceOwnerDocId];
      if (deviceOwner != null) {
        final label = _trackerLabelFromDeviceOwner(deviceOwner);
        if (label != null) return label;
      }
    }

    final playerId = playerCompo.playerID?.trim();
    if (playerId == null ||
        playerId.isEmpty ||
        seasonId == null ||
        seasonId.isEmpty) {
      return null;
    }

    final effective = await EffectivesService().getEffectivesByMemberAndSeason(
      memberId: playerId,
      seasonId: seasonId,
    );
    final trackers = effective?.trackers;
    if (trackers == null || trackers.isEmpty) return null;

    for (final trackerDocId in trackers) {
      final deviceOwner = ownerDevicesByDocId[trackerDocId];
      if (deviceOwner == null) continue;
      final label = _trackerLabelFromDeviceOwner(deviceOwner);
      if (label != null) return label;
    }

    return null;
  }

  Future<Map<String, String>> _buildMatchDevicePlayerMap({
    required MatchCompo matchCompo,
    required Map<String, DeviceOwner> ownerDevicesByDocId,
    required String? seasonId,
  }) async {
    final devicePlayerMap = <String, String>{};
    final seenTrackerIds = <String>{};

    Future<void> addFromPlayers(List<PlayerCompo>? players) async {
      if (players == null) return;
      for (final playerCompo in players) {
        final playerId = playerCompo.playerID?.trim();
        if (playerId == null || playerId.isEmpty) continue;

        final trackerId = await _resolveTrackerIdForMatchPlayer(
          playerCompo: playerCompo,
          ownerDevicesByDocId: ownerDevicesByDocId,
          seasonId: seasonId,
        );
        if (trackerId == null || trackerId.isEmpty) continue;
        if (seenTrackerIds.contains(trackerId)) continue;

        seenTrackerIds.add(trackerId);
        devicePlayerMap[trackerId] = playerId;
      }
    }

    await addFromPlayers(matchCompo.goalkeeper);
    await addFromPlayers(matchCompo.defender);
    await addFromPlayers(matchCompo.midfielder);
    await addFromPlayers(matchCompo.midfielderAttaking);
    await addFromPlayers(matchCompo.midfielderDefensive);
    await addFromPlayers(matchCompo.stricker);
    await addFromPlayers(matchCompo.substitute);

    return devicePlayerMap;
  }

  Future<Map<String, String>> _buildTrainingDevicePlayerMap({
    required Training training,
    required Map<String, DeviceOwner> ownerDevicesByDocId,
    required String seasonId,
  }) async {
    final devicePlayerMap = <String, String>{};
    final seenTrackerIds = <String>{};

    final answers = await AnswerService()
        .getAnswersByObjectId(training.trainingId!);
    final answersMap = <String, Answer>{
      for (final answer in answers)
        if (answer.playerTraining?.playerId != null)
          answer.playerTraining!.playerId!: answer,
    };

    for (final playerTraining in training.playerTraining) {
      final playerId = playerTraining.playerId?.trim();
      if (playerId == null || playerId.isEmpty) continue;

      final answer = answersMap[playerId];
      final bool isPresent;
      if (answer == null) {
        isPresent = playerTraining.presenceType == PresenceType.present ||
            playerTraining.presenceType == PresenceType.late;
      } else {
        final presence = answer.playerTraining?.presenceType;
        isPresent = presence == PresenceType.present ||
            presence == PresenceType.late;
      }
      if (!isPresent) continue;

      String? trackerId;
      final deviceDocId = playerTraining.deviceId?.trim();
      if (deviceDocId != null && deviceDocId.isNotEmpty) {
        final deviceOwner = ownerDevicesByDocId[deviceDocId];
        if (deviceOwner != null) {
          trackerId = _trackerLabelFromDeviceOwner(deviceOwner);
        }
      } else {
        final effective =
            await EffectivesService().getEffectivesByMemberAndSeason(
          memberId: playerId,
          seasonId: seasonId,
        );
        for (final trackerDocId in effective?.trackers ?? const <String>[]) {
          final deviceOwner = ownerDevicesByDocId[trackerDocId];
          if (deviceOwner == null) continue;
          trackerId = _trackerLabelFromDeviceOwner(deviceOwner);
          if (trackerId != null) break;
        }
      }

      if (trackerId == null || trackerId.isEmpty) continue;
      if (seenTrackerIds.contains(trackerId)) continue;

      seenTrackerIds.add(trackerId);
      devicePlayerMap[trackerId] = playerId;
    }

    return devicePlayerMap;
  }

  List<String> _sortTrackerIds(Iterable<String> trackerIds) {
    final sorted = trackerIds.toList()
      ..sort((a, b) {
        final intA = int.tryParse(a);
        final intB = int.tryParse(b);
        if (intA != null && intB != null) {
          return intA.compareTo(intB);
        }
        return a.compareTo(b);
      });
    return sorted;
  }

  Future<FieldGpsCorners?> _ensureMatchFieldGpsCorners(
    match_model.Match match,
  ) {
    return FieldGpsLocalizationHelper.ensureMatchFieldGpsCorners(
      context,
      match: match,
      matchService: _matchService,
      trackerFieldService: _trackerFieldService,
    );
  }

  Future<bool> _ensureEventSyncNotFullyClosed(String eventId) async {
    final existing = await EventSyncService().getEventSync(eventId);
    if (existing?.isFullySynced != true) return true;
    if (!mounted) return false;

    final colors = context.appColors;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(dialogContext.l10n.trackerAlreadySyncedTitle),
        content: Text(dialogContext.l10n.trackerAllSensorsSynced),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.actionOk),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _openMatchTrackerHub({
    required match_model.Match match,
    required List<String> trackerIdsToSend,
    required Map<String, String> devicePlayerMap,
    required FieldGpsCorners fieldGpsCorners,
  }) async {
    if (!mounted || trackerIdsToSend.isEmpty) return;

    final eventId = match.id;
    if (eventId == null || eventId.isEmpty) return;
    if (!await _ensureEventSyncNotFullyClosed(eventId)) return;
    if (!mounted) return;

    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.syncTrackerHub,
      parameters: const <String, Object>{
        'is_match': true,
      },
    );
    await Navigator.push(
      context,
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.trackerHub,
        builder: (_) => TrackerHubPage(
          trackerIds: trackerIdsToSend,
          eventId: eventId,
          isMatch: true,
          fieldGpsCorners: fieldGpsCorners,
          devicePlayerMap: devicePlayerMap,
          ownerId: match.ownerId!,
        ),
      ),
    );
  }

  Future<void> _openTrainingTrackerHub({
    required Training training,
    required List<String> trackerIdsToSend,
    required Map<String, String> devicePlayerMap,
  }) async {
    if (!mounted || trackerIdsToSend.isEmpty) return;

    final eventId = training.docId;
    if (eventId == null || eventId.isEmpty) return;
    if (!await _ensureEventSyncNotFullyClosed(eventId)) return;
    if (!mounted) return;

    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.syncTrackerHub,
      parameters: const <String, Object>{
        'is_match': false,
      },
    );
    await Navigator.push(
      context,
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.trackerHub,
        builder: (_) => TrackerHubPage(
          trackerIds: trackerIdsToSend,
          eventId: eventId,
          isMatch: false,
          fieldGpsCorners: null,
          devicePlayerMap: devicePlayerMap,
          ownerId: training.ownerId!,
        ),
      ),
    );
  }

  Widget _buildEventsSectionTitle({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CountBadgeLabel(count: count),
      ],
    );
  }

  Widget _buildTeamsDropdown({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? seasonId,
    required String? userId,
  }) {
    if (seasonId == null || seasonId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.myTeams,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.emptyNoCurrentSeason,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (userId == null || userId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.myTeams,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.infoUserNotConnected,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }

    final session = context.watch<AppSession>();

    if (session.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.myTeams,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CircularProgressIndicator(
              color: colors.primary,
            ),
          ),
        ],
      );
    }

    final teams = session.managerTeamsForSelectedSeason;

    if (teams.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.myTeams,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.emptyNoTeamForSeason,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          );
        }

        final bool selectedExists = teams.any(
              (team) => team.keyTeam == _selectedTeamId,
        );

        final String selectedValue =
        selectedExists ? _selectedTeamId! : teams.first.keyTeam!;

        if (!selectedExists && _selectedTeamId != selectedValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedTeamId = selectedValue;
            });
          });
        }

        final Team selectedTeam = teams.firstWhere(
              (team) => team.keyTeam == selectedValue,
          orElse: () => teams.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.myTeams,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.entityTeam,
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
              ),
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: teams.map((team) {
                return DropdownMenuItem<String>(
                  value: team.keyTeam,
                  child: Text(
                    team.name ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTeamId = value;
                });
              },
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<match_model.Match>>(
              stream: _matchService.streamMatchesToUploadTrackerData(
                selectedValue,
              ),
              builder: (context, matchSnapshot) {
                if (matchSnapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventsSectionTitle(
                        context: context,
                        colors: colors,
                        textTheme: textTheme,
                        title: context.l10n.syncMatchesToSync,
                        count: 0,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (matchSnapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventsSectionTitle(
                        context: context,
                        colors: colors,
                        textTheme: textTheme,
                        title: context.l10n.syncMatchesToSync,
                        count: 0,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          context.l10n.errorLoadingResource(context.l10n.entityMatches),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final matches = matchSnapshot.data ?? <match_model.Match>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventsSectionTitle(
                      context: context,
                      colors: colors,
                      textTheme: textTheme,
                      title: context.l10n.syncMatchesToSync,
                      count: matches.length,
                    ),
                    const SizedBox(height: 10),
                    if (matches.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          context.l10n.emptyNoPendingMatch,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: matches.map((match) {
                          return Card(
                            color: colors.card,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: colors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${match.team1 ?? ''} vs ${match.team2 ?? ''}',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${match.dateCh ?? '-'} ${match.timeCh ?? ''}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          match.nomDuTerrain?.isNotEmpty == true
                                              ? match.nomDuTerrain!
                                              : (match.terrainAdresse1?.isNotEmpty == true
                                              ? match.terrainAdresse1!
                                              : '-'),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  UploadTrackerButton(
                                    onPressed: () async {
                                      try {
                                        final owner = await OwnerService().getOwnerById(match.ownerId!);

                                        if (owner != null && owner.typeTracker == "inspirit") {
                                          final matchCompo = await MatchCompoService()
                                              .getFirstMatchCompoByMatchId(match.id!);

                                          if (matchCompo == null) {
                                            debugPrint('matchCompo introuvable');
                                            return;
                                          }

                                          final ownerDevices =
                                              await DeviceOwnerService()
                                                  .getByOwnerId(owner.id);
                                          final ownerDevicesByDocId = {
                                            for (final od in ownerDevices) od.id: od,
                                          };

                                          final devicePlayerMap =
                                              await _buildMatchDevicePlayerMap(
                                            matchCompo: matchCompo,
                                            ownerDevicesByDocId: ownerDevicesByDocId,
                                            seasonId: currentSeason?.ref?.id,
                                          );
                                          final trackerIdsToSend =
                                              _sortTrackerIds(devicePlayerMap.keys);

                                          if (!mounted) return;

                                          if (trackerIdsToSend.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  context.l10n.syncNoDeviceForMatch,
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final fieldGpsCorners =
                                              await _ensureMatchFieldGpsCorners(match);
                                          if (fieldGpsCorners == null || !mounted) {
                                            return;
                                          }

                                          await _openMatchTrackerHub(
                                            match: match,
                                            trackerIdsToSend: trackerIdsToSend,
                                            devicePlayerMap: devicePlayerMap,
                                            fieldGpsCorners: fieldGpsCorners,
                                          );
                                        }
                                      } catch (e, st) {
                                        debugPrint('Erreur upload match: $e');
                                        debugPrintStack(stackTrace: st);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Training>>(
              stream: TrainingService().streamTrainingsToUploadTrackerData(
                selectedValue,
              ),
              builder: (context, trainingSnapshot) {
                if (trainingSnapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventsSectionTitle(
                        context: context,
                        colors: colors,
                        textTheme: textTheme,
                        title: context.l10n.syncTrainingsToSync,
                        count: 0,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (trainingSnapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventsSectionTitle(
                        context: context,
                        colors: colors,
                        textTheme: textTheme,
                        title: context.l10n.syncTrainingsToSync,
                        count: 0,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          context.l10n.errorLoadingResource(context.l10n.entityTrainings),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final trainings = trainingSnapshot.data ?? <Training>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventsSectionTitle(
                      context: context,
                      colors: colors,
                      textTheme: textTheme,
                      title: context.l10n.syncTrainingsToSync,
                      count: trainings.length,
                    ),
                    const SizedBox(height: 10),
                    if (trainings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          context.l10n.emptyNoPendingTraining,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: trainings.map((training) {
                          return Card(
                            color: colors.card,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: colors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.entityTraining,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${training.dateTg ?? '-'} ${training.startTime ?? ''}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.sports_soccer_outlined,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  UploadTrackerButton(
                                    onPressed: () async {
                                      try {

                                        final owner = await OwnerService()
                                            .getOwnerById(training.ownerId!);
                                        if (owner != null &&
                                            owner.typeTracker == 'inspirit') {
                                          final seasonId = currentSeason?.ref?.id;
                                          if (seasonId == null || seasonId.isEmpty) {
                                            return;
                                          }

                                          final ownerDevices =
                                              await DeviceOwnerService()
                                                  .getByOwnerId(owner.id);
                                          final ownerDevicesByDocId = {
                                            for (final od in ownerDevices) od.id: od,
                                          };

                                          final devicePlayerMap =
                                              await _buildTrainingDevicePlayerMap(
                                            training: training,
                                            ownerDevicesByDocId: ownerDevicesByDocId,
                                            seasonId: seasonId,
                                          );
                                          final trackerIdsToSend =
                                              _sortTrackerIds(devicePlayerMap.keys);

                                          if (!mounted) return;

                                          if (trackerIdsToSend.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  context.l10n.syncNoDeviceForTraining,
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await _openTrainingTrackerHub(
                                            training: training,
                                            trackerIdsToSend: trackerIdsToSend,
                                            devicePlayerMap: devicePlayerMap,
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('Erreur upload training: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            )
          ],
        );
  }
}