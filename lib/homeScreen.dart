import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/tracker/tracker_hub_view.dart';
import 'package:provider/provider.dart';

import './provider/current_season_provider.dart';
import './services/teamService.dart';
import '../model/team.dart';
import './util/app_theme.dart';
import 'main.dart';
import '../model/match.dart' as match_model;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  String? _selectedTeamId;

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
    final app = MyApp.of(context);
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final currentSeason = context.watch<CurrentSeasonProvider>().currentSeason;
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

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
            child: SwitchListTile(
              activeThumbColor: Colors.white,
              activeTrackColor: colors.primary,
              inactiveThumbColor: colors.textSecondary,
              inactiveTrackColor: colors.border,
              title: Text(
                "Mode sombre",
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Activer ou désactiver le thème sombre",
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              value: app.isDarkMode,
              onChanged: (value) {
                app.toggleTheme(value);
              },
            ),
          ),

          const SizedBox(height: 16),

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

          if (kIsWeb) ...[
            const SizedBox(height: 16),
            Card(
              color: colors.card,
              child: ListTile(
                leading: Icon(Icons.usb, color: colors.primary),
                title: Text(
                  'ASI Downloader (USB Chrome)',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                subtitle: Text(
                  'Accès USB via WebUSB (Chrome uniquement)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrackerHubView(
                        trackerIds: [
                          'TRACKER_001',
                          'TRACKER_002',
                          'TRACKER_003',
                          'TRACKER_004',
                          'TRACKER_005',
                          'TRACKER_006',
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          Card(
            color: colors.card,
            child: ListTile(
              leading: Icon(Icons.file_open_outlined, color: colors.primary),
              title: Text(
                'Convertisseur ASI vers CSV',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              subtitle: Text(
                'Sélectionner un fichier .asi et lancer la conversion',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/asi-converter');
              },
            ),
          ),

          const SizedBox(height: 16),

          Card(
            color: colors.card,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenue',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exemple avec Firebase Analytics.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _logOpenProduct();

                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/product');
                    },
                    child: const Text('Aller vers produit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              'Matchs tracker à traiter',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<match_model.Match>>(
              stream: _matchService.streamMatchesToUploadTrackerData(selectedValue,),
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
                      'Aucun match avec tracker en attente.',
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Tracker à uploader',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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