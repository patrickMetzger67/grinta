import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/app_localizations_effectives_extension.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/screen/team_param_screen.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamService.dart';
import '../../util/app_theme.dart';

import '../../model/tracker/owner.dart';
import '../../services/effectivesService.dart';
import '../../services/deviceService.dart';
import '../../services/ownerService.dart';
import '../../widget/playerPhoto.dart';

part 'team_detail_widgets.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({
    super.key,
    required this.team,
    required this.seasonId,
    this.categoryLabel,
    this.genderLabel,
    this.thresholdCards = const [],
    this.effectivesService,
    this.isManager=false,
  });

  final Team team;
  final String? seasonId;
  final String? categoryLabel;
  final String? genderLabel;
  final List<TeamThresholdCardData> thresholdCards;
  final EffectivesService? effectivesService;
  final bool isManager;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

enum _RosterSortColumn {
  player,
  age,
  position,
  height,
  weight,
  tracker,
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late final PlayerService _playerService;
  late final EffectivesService _effectivesService;
  late final DeviceOwnerService _deviceOwnerService;
  late final DeviceService _deviceService;
  late final OwnerService _ownerService;

  late Future<List<_TeamMemberVm>> _future;

  _RosterSortColumn? _sortColumn;
  bool _sortAscending = true;

  List<dynamic> rawPlayers = [];

  @override
  void initState() {
    super.initState();

    _playerService = PlayerService();
    _effectivesService = widget.effectivesService ?? EffectivesService();

    _deviceOwnerService = DeviceOwnerService();
    _deviceService = DeviceService();
    _ownerService = OwnerService();

    _future = _loadMembers();
  }

  Future<List<_TeamMemberVm>> _loadMembers() async {
    final String? seasonId = widget.seasonId;
    final String? teamId = widget.team.keyTeam;
    rawPlayers = widget.team.players ?? const <dynamic>[];

    if (seasonId == null ||
        seasonId.isEmpty ||
        teamId == null ||
        teamId.isEmpty) {
      return <_TeamMemberVm>[];
    }

    final List<String> memberIds = rawPlayers
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<_TeamMemberVm?> rows = await Future.wait(
      memberIds.map((memberId) async {
        try {
          final Player? player = await _playerService.getPlayerById(memberId);

          if (player == null) {
            return null;
          }

          final Effectives? effectives =
          await _effectivesService.getEffectivesByMemberIdAndTeamId(
            memberId,
            teamId,
          );

          final List<_TrackerChipVm> trackers = await _loadTrackers(
            effectives?.trackers,
          );

          return _TeamMemberVm(
            player: player,
            effectives: effectives,
            trackers: trackers,
          );
        } catch (e, stackTrace) {
          debugPrint('Erreur _loadMembers memberId=$memberId : $e');
          debugPrint('$stackTrace');
          return null;
        }
      }),
    );

    final List<_TeamMemberVm> data = rows.whereType<_TeamMemberVm>().toList();

    data.sort((a, b) {
      final int orderA = a.effectives?.order ?? 999999;
      final int orderB = b.effectives?.order ?? 999999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return a.player.lastName!.toLowerCase().compareTo(b.player.lastName!.toLowerCase());

    });

    return data;
  }

  Future<List<_TrackerChipVm>> _loadTrackers(List<dynamic>? trackerIds) async {

    if (trackerIds == null || trackerIds.isEmpty) {
      return <_TrackerChipVm>[];
    }

    final List<String> ids = trackerIds
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<_TrackerChipVm> result = <_TrackerChipVm>[];

    for (final String trackerId in ids) {
      final _TrackerChipVm? tracker = await _loadTrackerById(trackerId);

      if (tracker != null) {
        result.add(tracker);
      }
    }

    return result;
  }

  Future<_TrackerChipVm?> _loadTrackerById(String trackerId) async {
    try {
      final DeviceOwner? deviceOwner = await _deviceOwnerService.getById(trackerId);
      if (deviceOwner == null) {
        debugPrint('deviceOwner null pour trackerId=$trackerId');
        return null;
      }

      final String customName = deviceOwner.customName ?? '';

      final Owner? owner = await OwnerService().getOwnerById(deviceOwner.ownerId);

      if (owner == null || owner.name.isEmpty) {
        debugPrint('ownerId vide pour trackerId=$trackerId');
        return null;
      }
      final String label = <String>[
        if (customName.isNotEmpty) customName,
        if (owner.name.isNotEmpty) owner.name,
      ].join(' - ');

      debugPrint('label tracker=$label');

      if (label.isEmpty) {
        return null;
      }

      return _TrackerChipVm(
        id: trackerId,
        label: label,
      );
    } catch (e, stackTrace) {
      debugPrint('Erreur _loadTrackerById trackerId=$trackerId : $e');
      debugPrint('$stackTrace');
      return null;
    }
  }



  List<_TeamMemberVm> _playerRows(List<_TeamMemberVm> rows) {
    return rows.where((r) {
      final Effectives? effectives = r.effectives;

      if (effectives == null) {
        return false;
      }

      return effectives.type == 0;
    }).toList();
  }

  List<_TeamMemberVm> _staffRows(
    List<_TeamMemberVm> rows,
    AppLocalizations l10n,
  ) {
    final List<_TeamMemberVm> data = rows.where((r) {
      final Effectives? effectives = r.effectives;

      if (effectives == null) {
        return false;
      }

      return effectives.type != 0;
    }).toList();

    data.sort((a, b) {
      final int orderA = a.effectives?.order ?? 999999;
      final int orderB = b.effectives?.order ?? 999999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return _displayName(a.player, l10n)
          .toLowerCase()
          .compareTo(_displayName(b.player, l10n).toLowerCase());
    });

    return data;
  }

  double _averagePlayersAge(List<_TeamMemberVm> rows) {
    final List<int> ages = rows.where((r) {
      final Effectives? effectives = r.effectives;

      if (effectives == null) {
        return false;
      }

      return effectives.type == 0;
    }).map((r) {
      return _ageValue(r.player) ?? -1;
    }).where((age) {
      return age >= 0;
    }).toList();

    if (ages.isEmpty) {
      return 0;
    }

    final int total = ages.reduce((a, b) => a + b);

    return total / ages.length;
  }

  int _playersCount(List<_TeamMemberVm> rows) {
    return rows.where((r) {
      final Effectives? effectives = r.effectives;

      if (effectives == null) {
        return false;
      }

      return effectives.type == 0;
    }).length;
  }

  int _staffsCount(List<_TeamMemberVm> rows) {
    return rows.where((r) {
      final Effectives? effectives = r.effectives;

      if (effectives == null) {
        return false;
      }

      return effectives.type != 0;
    }).length;
  }

  String _displayName(Player player, AppLocalizations l10n) {
    final String first = player.firstName ?? '';
    final String last = player.lastName ?? '';
    final String value = '$first $last'.trim();

    return value.isEmpty ? l10n.entityPlayer : value;
  }

  void _onSort(_RosterSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<_TeamMemberVm> _sortedRosterRows(
    List<_TeamMemberVm> rows,
    AppLocalizations l10n,
  ) {
    final List<_TeamMemberVm> data = rows.where((r) {
      return r.effectives != null;
    }).toList();

    final _RosterSortColumn? column = _sortColumn;

    if (column == null) {
      return data;
    }

    data.sort((a, b) {
      int result = 0;

      switch (column) {
        case _RosterSortColumn.player:
          result = _compareText(
            _displayName(a.player, l10n),
            _displayName(b.player, l10n),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.age:
          result = _compareNullableInt(
            _ageValue(a.player),
            _ageValue(b.player),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.position:
          result = _compareText(
            getStrPosition(a.effectives?.position ?? 0, l10n),
            getStrPosition(b.effectives?.position ?? 0, l10n),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.height:
          result = _compareNullableInt(
            _positiveIntOrNull(a.effectives?.taille),
            _positiveIntOrNull(b.effectives?.taille),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.weight:
          result = _compareNullableInt(
            _positiveIntOrNull(a.effectives?.poids),
            _positiveIntOrNull(b.effectives?.poids),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.tracker:
          result = _compareText(
            _trackerValue(a),
            _trackerValue(b),
            ascending: _sortAscending,
          );
          break;
      }

      if (result != 0) {
        return result;
      }

      return _displayName(a.player, l10n)
          .toLowerCase()
          .compareTo(_displayName(b.player, l10n).toLowerCase());
    });

    return data;
  }

  int _compareText(
      String a,
      String b, {
        required bool ascending,
      }) {
    final String valueA = a.trim().toLowerCase();
    final String valueB = b.trim().toLowerCase();

    if (valueA.isEmpty && valueB.isEmpty) {
      return 0;
    }

    if (valueA.isEmpty) {
      return 1;
    }

    if (valueB.isEmpty) {
      return -1;
    }

    final int result = valueA.compareTo(valueB);

    return ascending ? result : -result;
  }

  int _compareNullableInt(
      int? a,
      int? b, {
        required bool ascending,
      }) {
    if (a == null && b == null) {
      return 0;
    }

    if (a == null) {
      return 1;
    }

    if (b == null) {
      return -1;
    }

    final int result = a.compareTo(b);

    return ascending ? result : -result;
  }

  int? _positiveIntOrNull(int? value) {
    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  int? _ageValue(Player player) {
    final DateTime? birthDate = _getBirthDate(player);

    if (birthDate == null) {
      return null;
    }

    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  String _trackerValue(_TeamMemberVm row) {
    if (row.trackers.isEmpty) {
      return '';
    }

    return row.trackers.map((tracker) => tracker.label).join(' ');
  }

  String _buildStaffRole(Effectives? effectives, AppLocalizations l10n) {
    if (effectives == null) {
      return l10n.entityStaff;
    }

    return l10n.staffRoleLabel(effectives.type ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
            final l10n = context.l10n;
            final List<_TeamMemberVm> playerRows = _playerRows(rows);
            final List<_TeamMemberVm> staffRows = _staffRows(rows, l10n);

            final int playersCount = _playersCount(rows);
            final int staffsCount = _staffsCount(rows);
            final double averageAge = _averagePlayersAge(playerRows);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    rows: rows,
                    playersCount: playersCount,
                    staffsCount: staffsCount,
                    averageAge: averageAge,
                  ),
                  const SizedBox(height: 24),
                  _buildRosterCard(context, playerRows),
                  const SizedBox(height: 24),
                  _buildStaffCard(context, staffRows),
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

    final l10n = context.l10n;
    final String title = (widget.team.name ?? '').trim().isEmpty
        ? l10n.entityTeam
        : widget.team.name!.trim();

    final List<Widget> chips = <Widget>[
      if ((widget.categoryLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.categoryLabel!.trim()),
      if ((widget.genderLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.genderLabel!.trim()),
      _InfoChip(label: l10n.teamMembersPlayers(playersCount)),
      _InfoChip(label: l10n.teamMembersStaff(staffsCount)),
      _InfoChip(
        label: l10n.teamDetailAverageAge(averageAge.toStringAsFixed(0)),
      ),
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
                        if(widget.isManager) ... [
                          _HeaderSquareIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () {},
                          ),
                          _HeaderSquareIconButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: () {},
                          ),
                        ],
                        _HeaderSquareIconButton(
                          icon: Icons.tune_rounded,
                          onTap: () async {
                            AnalyticsInteractions.logFeature(
                              AnalyticsFeatures.openTeamParam,
                              parameters: <String, Object>{
                                'is_manager': widget.isManager,
                              },
                            );
                            final bool? updated =
                            await Navigator.of(context).push<bool>(
                              analyticsMaterialRoute<bool>(
                                screenName: AnalyticsScreenNames.teamParam,
                                builder: (_) => TeamParamScreen(
                                  team: widget.team,
                                  isManager: widget.isManager,
                                ),
                              ),
                            );

                            if (updated == true && mounted) {
                              setState(() {
                                _future = _loadMembers();
                              });
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
                              l10n.teamDetailBackToTeams,
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
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final List<_TeamMemberVm> visibleRows = _sortedRosterRows(rows, l10n);

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
                  color: colors.primary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.entityPlayers,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if(widget.isManager) ... [
                  FilledButton(
                    onPressed: () {},
                    child: Text(l10n.actionAddPlayer),
                  ),
                ]

              ],
            ),
          ),
          _buildTableHeader(context),
          if (visibleRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.emptyNoPlayerForTeam,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            ...List.generate(
              visibleRows.length,
                  (index) => _buildRow(
                context,
                row: visibleRows[index],
                odd: index.isOdd,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, List<_TeamMemberVm> staffRows) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.entityStaff,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if(widget.isManager) ... [
                FilledButton(
                  onPressed: () {},
                  child: Text(l10n.actionAddStaff),
                ),
              ]
            ],
          ),
          const SizedBox(height: 24),
          if (staffRows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                l10n.emptyNoStaffForTeam,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth;

                if (constraints.maxWidth >= 1400) {
                  itemWidth = (constraints.maxWidth - 32) / 3;
                } else if (constraints.maxWidth >= 900) {
                  itemWidth = (constraints.maxWidth - 16) / 2;
                } else {
                  itemWidth = constraints.maxWidth;
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: staffRows.map((row) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildStaffMemberCard(context, row),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStaffMemberCard(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Player player = row.player;
    final l10n = context.l10n;
    final String name = _displayName(player, l10n);
    final String role = _buildStaffRole(row.effectives, l10n);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: [
          PlayerPhoto(
            player: player,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if(widget.isManager) ... [
            _CircleGhostButton(
              icon: Icons.delete_outline_rounded,
              onTap: () async {
                final l10n = context.l10n;
                final appColors = context.appColors;
                final playerName =
                    '${player.firstName} ${player.lastName}'.trim();

                final bool? confirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext dialogContext) {
                    final dialogL10n = dialogContext.l10n;
                    return AlertDialog(
                      backgroundColor: appColors.surface,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: appColors.border),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: appColors.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dialogL10n.teamDetailConfirmDeleteTitle,
                              style: TextStyle(
                                color: appColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        dialogL10n.teamDetailConfirmRemoveStaff(playerName),
                        style: TextStyle(
                          color: appColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: appColors.textSecondary,
                            side: BorderSide(color: appColors.border),
                          ),
                          child: Text(dialogL10n.actionCancel),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: appColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(dialogL10n.actionDelete),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  try {
                    await EffectivesService().deleteEffectives(row.effectives!);
                    // Mise a jour de l'equipe
                    List<dynamic>? rawManagers = widget.team.managers;
                    rawManagers?.remove(player.keyMember);
                    Team team = widget.team;
                    team.managers = rawManagers;
                    await TeamService().updateTeam(team);

                    if (!context.mounted) return;
                    setState(() {
                      // Rafraîchit la page après suppression
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.teamDetailPlayerRemoved(playerName),
                          style: TextStyle(color: appColors.textPrimary),
                        ),
                        backgroundColor: appColors.success,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.errorDeleteFailed(e.toString()),
                        ),
                        backgroundColor: appColors.danger,
                      ),
                    );
                  }
                }
              },
            ),
          ]

        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

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
          _headerCell(
            l10n.entityPlayer,
            flex: 4,
            textTheme: textTheme,
            sortColumn: _RosterSortColumn.player,
          ),
          if(widget.isManager) ...[
            _headerCell('', flex: 1, textTheme: textTheme),
          ],
          _headerCell(
            l10n.teamDetailColumnAge,
            flex: 1,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.age,
          ),
          _headerCell(
            l10n.teamDetailColumnPosition,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.position,
          ),
          _headerCell(
            l10n.teamDetailColumnHeight,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.height,
          ),
          _headerCell(
            l10n.teamDetailColumnWeight,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.weight,
          ),
          _headerCell(
            l10n.entityTracker,
            flex: 3,
            textTheme: textTheme,
            center: false,
            sortColumn: _RosterSortColumn.tracker,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
      String label, {
        required int flex,
        required TextTheme textTheme,
        bool center = false,
        _RosterSortColumn? sortColumn,
      }) {
    final colors = context.appColors;
    final bool sortable = sortColumn != null;
    final bool active = _sortColumn == sortColumn;

    final Widget content = Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Row(
        mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment:
        center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: active ? colors.primary : null,
              ),
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            Icon(
              active
                  ? (_sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 15,
              color: active ? colors.primary : colors.textSecondary,
            ),
          ],
        ],
      ),
    );

    return Expanded(
      flex: flex,
      child: sortable
          ? InkWell(
        onTap: () => _onSort(sortColumn),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      )
          : content,
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

    if (effectives == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final String playerName = _displayName(player, l10n);
    final String position = getStrPosition(effectives.position ?? 0, l10n);

    final String taille = (effectives.taille ?? 0) > 0
        ? l10n.teamDetailHeightCm(effectives.taille!)
        : '-';

    final String poids = (effectives.poids ?? 0) > 0
        ? l10n.teamDetailWeightKg(effectives.poids!)
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
                PlayerPhoto(player: player),
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
          if(widget.isManager) ... [
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
                        onTap: () async {
                          final l10n = context.l10n;
                          final appColors = context.appColors;

                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext dialogContext) {
                              final dialogL10n = dialogContext.l10n;
                              return AlertDialog(
                                backgroundColor: appColors.surface,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: appColors.border),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: appColors.danger,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        dialogL10n.teamDetailConfirmDeleteTitle,
                                        style: TextStyle(
                                          color: appColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  dialogL10n.teamDetailConfirmRemovePlayerTeam(
                                    playerName,
                                  ),
                                  style: TextStyle(
                                    color: appColors.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(false);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: appColors.textSecondary,
                                      side: BorderSide(color: appColors.border),
                                    ),
                                    child: Text(dialogL10n.actionCancel),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(true);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: appColors.danger,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: Text(dialogL10n.actionDelete),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            try {
                              await EffectivesService().deleteEffectives(effectives);

                              // Mise a jour de l'equipe
                              rawPlayers.remove(player.keyMember);
                              Team team = widget.team;
                              team.players = rawPlayers;
                              await TeamService().updateTeam(team);


                              if (!context.mounted) return;
                              setState(() {
                                // Rafraîchit la page après suppression
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.teamDetailPlayerTeamRemoved(playerName),
                                    style: TextStyle(color: appColors.textPrimary),
                                  ),
                                  backgroundColor: appColors.success,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.errorDeleteFailed(e.toString()),
                                  ),
                                  backgroundColor: appColors.danger,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          _valueCell(age, flex: 1, center: true),
          _valueCell(position, flex: 2, center: true),
          _valueCell(taille, flex: 2, center: true),
          _valueCell(poids, flex: 2, center: true),
          Expanded(
            flex: 3,
            child: _buildTrackerChipsCell(context, row),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerChipsCell(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (row.trackers.isEmpty)
            Text(
              '-',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),

          ...row.trackers.map((tracker) {

            return InputChip(
              label: Text(tracker.label),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: colors.surface,
              side: BorderSide(
                color: colors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              deleteIcon: widget.isManager
                  ? Icon(
                Icons.delete_outline,
                size: 18,
                color: colors.danger,
              )
                  : null,
              onDeleted: widget.isManager
                  ? () async {
                await _deleteTrackerAffectation(
                  context: context,
                  row: row,
                  tracker: tracker,
                );
              }
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }),
          if(widget.isManager) ... [
            _buildAddTrackerButton(
              context: context,
              row: row,
            ),
          ]

        ],
      ),
    );
  }
  Widget _buildAddTrackerButton({
    required BuildContext context,
    required _TeamMemberVm row,
  }) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await _addTrackerAffectation(
          context: context,
          row: row,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: colors.primary,
        ),
      ),
    );
  }
  Future<void> _addTrackerAffectation({
    required BuildContext context,
    required _TeamMemberVm row,
  }) async {
    // Ouvre ici un Dialog ou BottomSheet permettant de sélectionner
    // un tracker supplémentaire à affecter au joueur.

    // Exemple :
    //
    // final selectedTracker = await showModalBottomSheet<Tracker>(
    //   context: context,
    //   builder: (_) => TrackerSelectionBottomSheet(
    //     playerId: row.player.id,
    //     alreadyAssignedTrackers: row.trackers,
    //   ),
    // );
    //
    // if (selectedTracker == null) return;
    //
    // await trackerService.assignTrackerToPlayer(
    //   playerId: row.player.id,
    //   trackerId: selectedTracker.id,
    // );
    //
    // setState(() {});
  }

  Future<void> _deleteTrackerAffectation({
    required BuildContext context,
    required _TeamMemberVm row,
    required _TrackerChipVm tracker,
  }) async {
    final colors = context.appColors;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = dialogContext.l10n;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            dialogL10n.dialogDeleteAssignmentTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            dialogL10n.teamDetailConfirmRemoveTracker(tracker.label),
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                dialogL10n.actionCancel,
                style: TextStyle(
                  color: colors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                dialogL10n.actionDelete,
                style: TextStyle(
                  color: colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // À adapter avec ton service / ta collection Firestore.
    //
    // await trackerService.removeTrackerFromPlayer(
    //   playerId: row.player.id,
    //   trackerId: tracker.id,
    // );

    // setState(() {});
  }

  String _buildAge(Player player) {
    final DateTime? birthDate = _getBirthDate(player);

    if (birthDate == null) {
      return '-';
    }

    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age.toString();
  }

  DateTime? _getBirthDate(Player player) {
    final String? raw = player.birthDay;

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final List<String> parts = raw.trim().split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

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

