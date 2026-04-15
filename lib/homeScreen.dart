import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/answerService.dart';
import 'package:grinta/services/effectivesService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/tracker/tracker_hub_page.dart';
import 'package:grinta/widget/uploadTrackerButton.dart';
import 'package:provider/provider.dart';

import './provider/current_season_provider.dart';
import './services/teamService.dart';
import '../model/team.dart';
import './util/app_theme.dart';
import '../model/match.dart' as match_model;
import 'model/answer.dart';
import 'model/matchCompo.dart';
import 'model/season.dart';
import 'model/training.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  String? _selectedTeamId;

  Season? currentSeason;

  Future<void> _logOpenProduct() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'open_product',
      parameters: {
        'source': 'home',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    currentSeason = context.watch<CurrentSeasonProvider>().currentSeason;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Accueil",
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

          Card(
            color: colors.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saison en cours',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSeason?.name ?? 'Aucune saison courante',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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

  void addDevices(List<PlayerCompo>? players, List<String> devices) {
    if (players == null) return;

    for (final mc in players) {
      final name = mc.customName?.trim();
      if (name != null && name.isNotEmpty) {
        devices.add(name);
      }
    }
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
            'Mes équipes',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune saison en cours disponible.',
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
            'Mes équipes',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisateur non connecté.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<Team>>(
      stream: _teamService.streamTeamsBySeasonIdAndManager(
        seasonId: seasonId,
        userId: userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes équipes',
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

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes équipes',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur lors du chargement des équipes.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.danger,
                ),
              ),
            ],
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes équipes',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune équipe trouvée pour cette saison.',
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
              'Mes équipes',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisir une équipe de la saison en cours',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
              ),
              decoration: InputDecoration(
                labelText: 'Équipe',
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
            Text(
              'Matchs à traiter',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<match_model.Match>>(
              stream: _matchService.streamMatchesToUploadTrackerData(
                selectedValue,
              ),
              builder: (context, matchSnapshot) {
                if (matchSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    ),
                  );
                }

                if (matchSnapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Erreur lors du chargement des matchs.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  );
                }

                final matches = matchSnapshot.data ?? <match_model.Match>[];

                if (matches.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'Aucun match en attente.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
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

                                    final List<String> devices = [];
                                    final Map<String,String> devicePlayerMap = {};

                                    void addDevices(List<PlayerCompo>? players) {
                                      if (players == null) return;

                                      for (final mc in players) {
                                        final name = mc.customName?.trim();
                                        if (name != null && name.isNotEmpty) {
                                          devices.add(name);
                                          devicePlayerMap[name] = mc.playerID!;
                                        }
                                      }
                                    }

                                    addDevices(matchCompo.goalkeeper);
                                    addDevices(matchCompo.defender);
                                    addDevices(matchCompo.midfielder);
                                    addDevices(matchCompo.midfielderAttaking);
                                    addDevices(matchCompo.midfielderDefensive);
                                    addDevices(matchCompo.stricker);
                                    addDevices(matchCompo.substitute);

                                    final trackerIdsToSend = List<String>.unmodifiable(
                                      List<String>.from(devices)
                                        ..removeWhere((e) => e.trim().isEmpty)
                                        ..sort((a, b) => int.parse(a).compareTo(int.parse(b))),
                                    );

                                    if (!mounted) return;

                                    await Navigator.push(
                                      this.context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackerHubPage(
                                          trackerIds: trackerIdsToSend,
                                          eventId: match.id!,
                                          isMatch: true,
                                          fieldGpsCorners: match.fieldGpsCorners,
                                          devicePlayerMap: devicePlayerMap,
                                          ownerId: match.ownerId!,
                                        ),
                                      ),
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
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Entrainements à traiter',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Training>>(
              stream: TrainingService().streamTrainingsToUploadTrackerData(
                selectedValue,
              ),
              builder: (context, trainingSnapshot) {
                if (trainingSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    ),
                  );
                }

                if (trainingSnapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Erreur lors du chargement des entraînements.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  );
                }

                final trainings = trainingSnapshot.data ?? <Training>[];

                if (trainings.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'Aucun entraînement avec tracker en attente.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
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
                              'Entraînement',
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

                                  print('trainingId=${training.trainingId} - date${training.dateTg}');
                                  final owner = await OwnerService().getOwnerById(training.ownerId!);
                                  if (owner != null && owner.typeTracker == "inspirit") {
                                    final ownerDevices =
                                    await DeviceOwnerService().getByOwnerId(owner.id);

                                    final Map<String, DeviceOwner> ownerDevicesMap = {};
                                    for (var od in ownerDevices) {
                                      ownerDevicesMap[od.id] = od;
                                    }
                                    final Set<String> devices = <String>{};
                                    final Map<String,String> devicePlayerMap = {};

                                    final answers = await AnswerService().getAnswersByObjectId(training.trainingId!);
                                    Map<String,Answer> answersMap = {};
                                    for(var a in answers) {
                                      answersMap[a.playerTraining!.playerId!] = a;
                                    }
                                    for (var pt in training.playerTraining) {

                                      bool isPresent = false;

                                      if(answersMap[pt.playerId] == null) {
                                        if(pt.presenceType == PresenceType.present || pt.presenceType == PresenceType.late) {
                                          isPresent = true;
                                        }
                                      } else {
                                        Answer? answer = answersMap[pt.playerId];
                                        if(answer != null) {
                                          if(answer.playerTraining!.presenceType == PresenceType.present || answer.playerTraining!.presenceType == PresenceType.late) {
                                            isPresent = true;
                                          }
                                        }

                                      }

                                      if (isPresent) {
                                        if (pt.deviceId == null || pt.deviceId!.isEmpty) {
                                          final effective =
                                          await EffectivesService().getEffectivesByMemberAndSeason(
                                            memberId: pt.playerId!,
                                            seasonId: currentSeason!.ref!.id,
                                          );
                                          if (effective != null && effective.trackers != null) {
                                            for (var d in effective.trackers!) {
                                              final deviceOwner = ownerDevicesMap[d];
                                              final customName = deviceOwner?.customName;

                                              if (customName != null &&
                                                  customName.trim().isNotEmpty) {
                                                devices.add(customName.trim());
                                                devicePlayerMap[customName.trim()] = pt.playerId!;
                                                break;
                                              }
                                            }
                                          }
                                        } else {
                                          final deviceOwner = ownerDevicesMap[pt.deviceId!];
                                          final customName = deviceOwner?.customName;

                                          if (customName != null &&
                                              customName.trim().isNotEmpty) {
                                            devices.add(customName.trim());
                                            devicePlayerMap[customName.trim()] = pt.playerId!;
                                          }
                                        }
                                      }
                                    }

                                    final trackerIdsToSend = devices.toList()
                                      ..sort((a, b) {
                                        final intA = int.tryParse(a);
                                        final intB = int.tryParse(b);

                                        if (intA != null && intB != null) {
                                          return intA.compareTo(intB);
                                        }

                                        return a.compareTo(b);
                                      });

                                    if (!mounted) return;

                                    if (trackerIdsToSend.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Aucun device trouvé pour cet entraînement',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await Navigator.push(
                                      this.context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackerHubPage(
                                          trackerIds: trackerIdsToSend,
                                          eventId: training.docId!,
                                          isMatch: false,
                                          fieldGpsCorners: null,
                                          devicePlayerMap: devicePlayerMap,
                                          ownerId: training.ownerId!,
                                        ),
                                      ),
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
                );
              },
            )
          ],
        );
      },
    );
  }
}