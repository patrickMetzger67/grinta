import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/screen/team_param_screen.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_theme.dart';

import '../services/effectivesService.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({
    super.key,
    required this.team,
    required this.seasonId,
    this.categoryLabel,
    this.genderLabel,
    this.thresholdCards = const [],
    this.effectivesService,
  });

  final Team team;
  final String? seasonId;

  /// Ex: "U11"
  final String? categoryLabel;

  /// Ex: "Hommes"
  final String? genderLabel;

  /// Petites cartes à droite dans le header.
  final List<TeamThresholdCardData> thresholdCards;

  final EffectivesService? effectivesService;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late final PlayerService _playerService;
  late final EffectivesService _effectivesService;
  late Future<List<_TeamMemberVm>> _future;

  @override
  void initState() {
    super.initState();
    _playerService = PlayerService();
    _effectivesService = widget.effectivesService ?? EffectivesService();
    _future = _loadMembers();
  }

  Future<List<_TeamMemberVm>> _loadMembers() async {
    final String? seasonId = widget.seasonId;
    final String? teamId = widget.team.keyTeam;
    final List<dynamic> rawPlayers = (widget.team.players ?? const []);

    if (seasonId == null || seasonId.isEmpty || teamId == null || teamId.isEmpty) {
      return <_TeamMemberVm>[];
    }

    final List<String> memberIds = rawPlayers
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final List<_TeamMemberVm?> rows = await Future.wait(
      memberIds.map((memberId) async {
        try {
          final Player? player = await _playerService.getPlayerById(memberId);
          if (player == null) return null;

          final Effectives? effectives = await _effectivesService.getEffectivesByMemberIdAndTeamId(memberId, teamId,);

          return _TeamMemberVm(
            player: player,
            effectives: effectives,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    final List<_TeamMemberVm> data =
    rows.whereType<_TeamMemberVm>().toList();

    data.sort((a, b) {
      final int orderA = a.effectives?.order ?? 999999;
      final int orderB = b.effectives?.order ?? 999999;
      if (orderA != orderB) return orderA.compareTo(orderB);

      return _displayName(a.player)
          .toLowerCase()
          .compareTo(_displayName(b.player).toLowerCase());
    });

    return data;
  }

  double _averagePlayersAge(List<_TeamMemberVm> rows) {
    final List<int> ages = rows.where((r) {
      print('r=${r.player.lastName} - ${r.effectives?.type}');
      final int type = r.effectives?.type ?? 0;
      return type == 0;
    }).map((r) {
      final String age = _buildAge(r.player);
      return int.tryParse(age) ?? -1;
    }).where((age) => age >= 0).toList();

    if (ages.isEmpty) return 0;

    final int total = ages.reduce((a, b) => a + b);
    return total / ages.length;
  }

  int _playersCount(List<_TeamMemberVm> rows) {
    return rows.where((r) {
      print('r=${r.player.lastName} - ${r.effectives?.type}');
      final int type = r.effectives?.type ?? 0;
      return type == 0;
    }).length;
  }

  int _staffsCount(List<_TeamMemberVm> rows) {
    return rows.where((r) {
      final int type = r.effectives?.type ?? 1;
      return type != 0;
    }).length;
  }

  String _displayName(Player player) {
    final String first = player.firstName ?? '';
    final String last = player.lastName ?? '';
    final String value = '$first $last'.trim();
    return value.isEmpty ? 'Joueur' : value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FutureBuilder<List<_TeamMemberVm>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              );
            }

            final List<_TeamMemberVm> rows = snapshot.data ?? <_TeamMemberVm>[];
            final int playersCount = _playersCount(rows);
            final int staffsCount = _staffsCount(rows);
            final double averageAge = _averagePlayersAge(rows);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    rows: rows,
                    playersCount: playersCount,
                    staffsCount: staffsCount,
                    averageAge: averageAge
                  ),
                  const SizedBox(height: 24),
                  _buildRosterCard(context, rows),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, {
        required List<_TeamMemberVm> rows,
        required int playersCount,
        required int staffsCount,
        required double averageAge,
      }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final String title =
    (widget.team.name ?? '').trim().isEmpty ? 'Équipe' : widget.team.name!.trim();

    final List<Widget> chips = <Widget>[
      if ((widget.categoryLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.categoryLabel!.trim()),
      if ((widget.genderLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.genderLabel!.trim()),
      _InfoChip(label: '$playersCount joueur${playersCount > 1 ? 's' : ''}'),
      _InfoChip(label: '$staffsCount staff${staffsCount > 1 ? 's' : ''}'),
      _InfoChip(label: "Moyenne d'âge: ${averageAge.toStringAsFixed(0)} ans"),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.secondary.withValues(alpha: 0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stacked = constraints.maxWidth < 1050;

          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: stacked ? 0 : 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Text(
                          title,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _HeaderSquareIconButton(
                          icon: Icons.edit_outlined,
                          onTap: () {},
                        ),
                        _HeaderSquareIconButton(
                          icon: Icons.delete_outline_rounded,
                          onTap: () {},
                        ),
                        _HeaderSquareIconButton(
                          icon: Icons.tune_rounded,
                          onTap: () async {
                            final updated = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => TeamParamScreen(team: widget.team),
                              ),
                            );

                            if (updated == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: chips,
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Retour aux équipes',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, List<_TeamMemberVm> rows) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                Icon(
                  Icons.groups_2_rounded,
                  color: colors.secondary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Effectif',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Ajouter un joueur'),
                ),
              ],
            ),
          ),
          _buildTableHeader(context),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucun joueur trouvé pour cette équipe.',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            ...List.generate(
              rows.length,
                  (index) => _buildRow(
                context,
                row: rows[index],
                odd: index.isOdd,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          _headerCell('Joueur', flex: 4, textTheme: textTheme),
          _headerCell('', flex: 1, textTheme: textTheme),
          _headerCell('Age', flex: 1, textTheme: textTheme, center: true),
          _headerCell('Poste', flex: 2, textTheme: textTheme, center: true),
          _headerCell('Taille', flex: 2, textTheme: textTheme, center: true),
          _headerCell('Poids', flex: 2, textTheme: textTheme, center: true),
          _headerCell('Tracker', flex: 2, textTheme: textTheme, center: true),
        ],
      ),
    );
  }

  Widget _headerCell(
      String label, {
        required int flex,
        required TextTheme textTheme,
        bool center = false,
      }) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, {
        required _TeamMemberVm row,
        required bool odd,
      }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Player player = row.player;
    final Effectives? effectives = row.effectives;

    final String playerName = _displayName(player);
    final String position = getStrPosition(effectives?.position ?? 0);
    final String taille =
    (effectives?.taille ?? 0) > 0 ? '${effectives!.taille} cm' : '-';
    final String poids =
    (effectives?.poids ?? 0) > 0 ? '${effectives!.poids} kg' : '-';
    final String tracker = (effectives?.trackers != null &&
        effectives!.trackers!.isNotEmpty)
        ? effectives.trackers!.first
        : '-';

    final String age = _buildAge(player);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: odd
            ? colors.background.withValues(alpha: 0.45)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _PlayerPhoto(player: player),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleGhostButton(
                      icon: Icons.edit_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(width: 6),
                    _CircleGhostButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          _valueCell(age, flex: 1, center: true),
          _valueCell(position, flex: 2, center: true),
          _valueCell(taille, flex: 2, center: true),
          _valueCell(poids, flex: 2, center: true),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                tracker,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: tracker == '-' ? colors.textSecondary : colors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildAge(Player player) {
    final DateTime? birthDate = _getBirthDate(player);
    if (birthDate == null) return '-';

    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;

    if (
    now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)
    ) {
      age--;
    }

    return age.toString();
  }

  DateTime? _getBirthDate(Player player) {
    final String? raw = player.birthDay;

    if (raw == null || raw.trim().isEmpty) return null;

    final List<String> parts = raw.trim().split('/');
    if (parts.length != 3) return null;

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Widget _valueCell(
      String value, {
        required int flex,
        bool center = false,
      }) {

    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ),
    );
  }
}

class TeamThresholdCardData {
  const TeamThresholdCardData({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _TeamMemberVm {
  const _TeamMemberVm({
    required this.player,
    required this.effectives,
  });

  final Player player;
  final Effectives? effectives;
}

class _PlayerPhoto extends StatelessWidget {
  const _PlayerPhoto({
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final PlayerService playerService = PlayerService();

    return FutureBuilder<String>(
      future: playerService.getUrlPlayer(player, "portrait_1920x1920.jpg"),
      builder: (context, photoSnapshot) {
        final String? imageUrl = photoSnapshot.data;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            backgroundImage: NetworkImage(imageUrl),
          );
        }

        final String initials = _initials(
          player.firstName ?? '',
          player.lastName ?? '',
        );

        return CircleAvatar(
          radius: 18,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  String _initials(String firstName, String lastName) {
    final String f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final String l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    final String value = '$f$l';
    return value.isEmpty ? '?' : value;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFFFB27A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderSquareIconButton extends StatelessWidget {
  const _HeaderSquareIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF232A3B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CircleGhostButton extends StatelessWidget {
  const _CircleGhostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.data,
  });

  final TeamThresholdCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            data.value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFFB27A),
            ),
          ),
        ],
      ),
    );
  }
}