import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/training_creation_helper.dart';

/// Sentinel value for the "all months" filter option.
const String kTeamStatsAllMonthsValue = '__all__';

/// One selectable month in the trainings stats dropdown.
class TeamStatsMonthOption {
  const TeamStatsMonthOption({
    required this.value,
    required this.year,
    required this.month,
  });

  final String value;
  final int year;
  final int month;
}

/// Global training attendance stats for a filtered period.
class TeamTrainingGlobalStats {
  const TeamTrainingGlobalStats({
    required this.trainingCount,
    required this.attendanceRate,
    required this.trend,
  });

  final int trainingCount;
  final double? attendanceRate;
  final TeamTrainingAttendanceTrend trend;
}

/// Per-player attendance rate from marked sessions only (present + absent).
double? playerTrainingAttendanceRate({
  required int presentCount,
  required int absentCount,
}) {
  final marked = presentCount + absentCount;
  if (marked <= 0) {
    return null;
  }
  return (presentCount / marked) * 100;
}

/// Per-player training presence stats.
class TeamTrainingPlayerStats {
  const TeamTrainingPlayerStats({
    required this.playerId,
    required this.player,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.trends,
  });

  final String playerId;
  final Player? player;
  final int presentCount;
  final int absentCount;
  final double? attendanceRate;
  final TeamTrainingPlayerTrends trends;
}

class TeamTrainingPlayerTrends {
  const TeamTrainingPlayerTrends({
    this.present = TeamWdlTrendDirection.insufficientData,
    this.absent = TeamWdlTrendDirection.insufficientData,
    this.attendanceRate = TeamWdlTrendDirection.insufficientData,
  });

  final TeamWdlTrendDirection present;
  final TeamWdlTrendDirection absent;
  final TeamWdlTrendDirection attendanceRate;

  static TeamTrainingPlayerTrends compare({
    required int firstHalfPresent,
    required int firstHalfAbsent,
    required int secondHalfPresent,
    required int secondHalfAbsent,
  }) {
    return TeamTrainingPlayerTrends(
      present: _compareCounts(
        firstHalf: firstHalfPresent,
        secondHalf: secondHalfPresent,
        higherIsBetter: true,
      ),
      absent: _compareCounts(
        firstHalf: firstHalfAbsent,
        secondHalf: secondHalfAbsent,
        higherIsBetter: false,
      ),
      attendanceRate: TeamTrainingAttendanceTrend.compare(
        firstHalfRate: playerTrainingAttendanceRate(
          presentCount: firstHalfPresent,
          absentCount: firstHalfAbsent,
        ),
        secondHalfRate: playerTrainingAttendanceRate(
          presentCount: secondHalfPresent,
          absentCount: secondHalfAbsent,
        ),
      ).direction,
    );
  }

  static TeamWdlTrendDirection _compareCounts({
    required int firstHalf,
    required int secondHalf,
    required bool higherIsBetter,
  }) {
    if (firstHalf == 0 && secondHalf == 0) {
      return TeamWdlTrendDirection.insufficientData;
    }

    final diff = secondHalf - firstHalf;
    if (diff == 0) {
      return TeamWdlTrendDirection.flat;
    }

    final improved = higherIsBetter ? diff > 0 : diff < 0;
    return improved ? TeamWdlTrendDirection.up : TeamWdlTrendDirection.down;
  }
}

/// Trend comparing attendance rate between two halves of the filtered period.
class TeamTrainingAttendanceTrend {
  const TeamTrainingAttendanceTrend({
    required this.direction,
    this.firstHalfRate,
    this.secondHalfRate,
  });

  final TeamWdlTrendDirection direction;
  final double? firstHalfRate;
  final double? secondHalfRate;

  static TeamTrainingAttendanceTrend compare({
    required double? firstHalfRate,
    required double? secondHalfRate,
    double flatThreshold = 2.0,
  }) {
    if (firstHalfRate == null || secondHalfRate == null) {
      return const TeamTrainingAttendanceTrend(
        direction: TeamWdlTrendDirection.insufficientData,
      );
    }

    final diff = secondHalfRate - firstHalfRate;
    if (diff.abs() <= flatThreshold) {
      return TeamTrainingAttendanceTrend(
        direction: TeamWdlTrendDirection.flat,
        firstHalfRate: firstHalfRate,
        secondHalfRate: secondHalfRate,
      );
    }

    return TeamTrainingAttendanceTrend(
      direction: diff > 0
          ? TeamWdlTrendDirection.up
          : TeamWdlTrendDirection.down,
      firstHalfRate: firstHalfRate,
      secondHalfRate: secondHalfRate,
    );
  }
}

class TeamTrainingStatsResult {
  const TeamTrainingStatsResult({
    required this.monthOptions,
    required this.globalStats,
    required this.statsByPlayerId,
    required this.rosterPlayers,
  });

  final List<TeamStatsMonthOption> monthOptions;
  final TeamTrainingGlobalStats globalStats;
  final Map<String, TeamTrainingPlayerStats> statsByPlayerId;
  final List<Player> rosterPlayers;
}

class _TrainingAttendanceAccumulator {
  _TrainingAttendanceAccumulator({required this.playerId});

  final String playerId;
  int presentCount = 0;
  int absentCount = 0;
  int firstHalfPresent = 0;
  int firstHalfAbsent = 0;
  int secondHalfPresent = 0;
  int secondHalfAbsent = 0;
}

class _GlobalAttendanceAccumulator {
  int markedPresent = 0;
  int markedSlots = 0;
  int firstHalfPresent = 0;
  int firstHalfSlots = 0;
  int secondHalfPresent = 0;
  int secondHalfSlots = 0;
}

class TeamTrainingStatsService {
  TeamTrainingStatsService({
    TrainingService? trainingService,
    SeasonService? seasonService,
    TeamPlayersService? teamPlayersService,
  })  : _trainingService = trainingService ?? TrainingService(),
        _seasonService = seasonService ?? SeasonService(),
        _teamPlayersService = teamPlayersService ?? TeamPlayersService();

  final TrainingService _trainingService;
  final SeasonService _seasonService;
  final TeamPlayersService _teamPlayersService;

  String? _cacheKey;
  TeamTrainingStatsResult? _cachedResult;

  /// Builds month options for [seasonId] and computes stats for [monthValue].
  Future<TeamTrainingStatsResult> computeStatsForTeam({
    required Team team,
    required String seasonId,
    String monthValue = kTeamStatsAllMonthsValue,
    bool forceRefresh = false,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    final normalizedSeasonId = seasonId.trim();
    final normalizedMonth = monthValue.trim().isEmpty
        ? kTeamStatsAllMonthsValue
        : monthValue.trim();
    final key = '$teamId|$normalizedSeasonId|$normalizedMonth';

    if (!forceRefresh && _cacheKey == key && _cachedResult != null) {
      return _cachedResult!;
    }

    if (teamId.isEmpty || normalizedSeasonId.isEmpty) {
      return TeamTrainingStatsResult(
        monthOptions: const [],
        globalStats: TeamTrainingGlobalStats(
          trainingCount: 0,
          attendanceRate: null,
          trend: TeamTrainingAttendanceTrend.compare(
            firstHalfRate: null,
            secondHalfRate: null,
          ),
        ),
        statsByPlayerId: const {},
        rosterPlayers: const [],
      );
    }

    final season = await _seasonService.getSeasonById(normalizedSeasonId);
    final periods = resolveSeasonPeriodRanges(
      seasonId: normalizedSeasonId,
      season: season,
    );
    final monthOptions = _buildMonthOptions(periods.fullSeason);
    final rosterPlayers = await _teamPlayersService.loadPlayers(teamId: teamId);

    final trainings = await _loadPastTrainingsForTeam(
      teamId: teamId,
      seasonId: normalizedSeasonId,
      period: periods.fullSeason,
    );

    final filteredTrainings = _filterTrainingsByMonth(
      trainings: trainings,
      monthValue: normalizedMonth,
      monthOptions: monthOptions,
    );

    final trendRanges = _resolveTrendHalfRanges(
      monthValue: normalizedMonth,
      monthOptions: monthOptions,
      fullSeason: periods.fullSeason,
      firstHalf: periods.firstHalf,
      secondHalf: periods.secondHalf,
    );

    final globalAccumulator = _GlobalAttendanceAccumulator();
    final playerAccumulators = <String, _TrainingAttendanceAccumulator>{};

    for (final training in filteredTrainings) {
      final trainingDate = trainingDateForStats(training);
      if (trainingDate == null) {
        continue;
      }

      final isFirstHalf = trendRanges.firstHalf.contains(trainingDate);
      final isSecondHalf = trendRanges.secondHalf.contains(trainingDate);

      for (final playerTraining in training.playerTraining) {
        final playerId = playerTraining.playerId?.trim() ?? '';
        if (playerId.isEmpty) {
          continue;
        }

        final isPresent = _isPresent(playerTraining.presenceType);
        final isAbsent = _isAbsent(playerTraining.presenceType);
        final countsForTeamRate =
            isPresent || isAbsent || playerTraining.presenceType == null;

        if (countsForTeamRate) {
          globalAccumulator.markedSlots++;
          if (isPresent || playerTraining.presenceType == null) {
            globalAccumulator.markedPresent++;
          }
          if (isFirstHalf) {
            globalAccumulator.firstHalfSlots++;
            if (isPresent || playerTraining.presenceType == null) {
              globalAccumulator.firstHalfPresent++;
            }
          } else if (isSecondHalf) {
            globalAccumulator.secondHalfSlots++;
            if (isPresent || playerTraining.presenceType == null) {
              globalAccumulator.secondHalfPresent++;
            }
          }
        } else if (playerTraining.presenceType != null) {
          globalAccumulator.markedSlots++;
          if (isFirstHalf) {
            globalAccumulator.firstHalfSlots++;
          } else if (isSecondHalf) {
            globalAccumulator.secondHalfSlots++;
          }
        }

        final accumulator = playerAccumulators.putIfAbsent(
          playerId,
          () => _TrainingAttendanceAccumulator(playerId: playerId),
        );

        if (isPresent) {
          accumulator.presentCount++;
          if (isFirstHalf) {
            accumulator.firstHalfPresent++;
          } else if (isSecondHalf) {
            accumulator.secondHalfPresent++;
          }
        } else if (isAbsent) {
          accumulator.absentCount++;
          if (isFirstHalf) {
            accumulator.firstHalfAbsent++;
          } else if (isSecondHalf) {
            accumulator.secondHalfAbsent++;
          }
        }
      }
    }

    final globalStats = TeamTrainingGlobalStats(
      trainingCount: filteredTrainings.length,
      attendanceRate: _attendanceRate(
        present: globalAccumulator.markedPresent,
        total: globalAccumulator.markedSlots,
      ),
      trend: TeamTrainingAttendanceTrend.compare(
        firstHalfRate: _attendanceRate(
          present: globalAccumulator.firstHalfPresent,
          total: globalAccumulator.firstHalfSlots,
        ),
        secondHalfRate: _attendanceRate(
          present: globalAccumulator.secondHalfPresent,
          total: globalAccumulator.secondHalfSlots,
        ),
      ),
    );

    final playersById = <String, Player>{};
    for (final player in rosterPlayers) {
      final memberId = effectiveMemberId(player)?.trim() ?? '';
      if (memberId.isNotEmpty) {
        playersById[memberId] = player;
      }
    }

    final statsByPlayerId = <String, TeamTrainingPlayerStats>{};

    void addPlayerStats(String playerId, {Player? player}) {
      final normalizedId = playerId.trim();
      if (normalizedId.isEmpty || statsByPlayerId.containsKey(normalizedId)) {
        return;
      }

      final accumulator = playerAccumulators[normalizedId];
      final presentCount = accumulator?.presentCount ?? 0;
      final absentCount = accumulator?.absentCount ?? 0;
      final personalRate = playerTrainingAttendanceRate(
        presentCount: presentCount,
        absentCount: absentCount,
      );

      statsByPlayerId[normalizedId] = TeamTrainingPlayerStats(
        playerId: normalizedId,
        player: player ?? playersById[normalizedId],
        presentCount: presentCount,
        absentCount: absentCount,
        attendanceRate: personalRate,
        trends: TeamTrainingPlayerTrends.compare(
          firstHalfPresent: accumulator?.firstHalfPresent ?? 0,
          firstHalfAbsent: accumulator?.firstHalfAbsent ?? 0,
          secondHalfPresent: accumulator?.secondHalfPresent ?? 0,
          secondHalfAbsent: accumulator?.secondHalfAbsent ?? 0,
        ),
      );
    }

    for (final player in rosterPlayers) {
      final memberId = effectiveMemberId(player)?.trim() ?? '';
      if (memberId.isEmpty) {
        continue;
      }
      addPlayerStats(memberId, player: player);
    }

    for (final entry in playerAccumulators.entries) {
      addPlayerStats(entry.key);
    }

    final result = TeamTrainingStatsResult(
      monthOptions: monthOptions,
      globalStats: globalStats,
      statsByPlayerId: statsByPlayerId,
      rosterPlayers: rosterPlayers,
    );

    _cacheKey = key;
    _cachedResult = result;
    return result;
  }

  List<TeamStatsMonthOption> _buildMonthOptions(SeasonPeriodRange fullSeason) {
    final options = <TeamStatsMonthOption>[];
    var cursor = DateTime(fullSeason.start.year, fullSeason.start.month);
    final end = DateTime(fullSeason.end.year, fullSeason.end.month);

    while (!cursor.isAfter(end)) {
      options.add(
        TeamStatsMonthOption(
          value: _monthValue(cursor.year, cursor.month),
          year: cursor.year,
          month: cursor.month,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return options;
  }

  Future<List<Training>> _loadPastTrainingsForTeam({
    required String teamId,
    required String seasonId,
    required SeasonPeriodRange period,
  }) async {
    return loadPastTrainingsForTeamSeason(
      trainingService: _trainingService,
      teamId: teamId,
      seasonId: seasonId,
      period: period,
    );
  }

  List<Training> _filterTrainingsByMonth({
    required List<Training> trainings,
    required String monthValue,
    required List<TeamStatsMonthOption> monthOptions,
  }) {
    if (monthValue == kTeamStatsAllMonthsValue) {
      return trainings;
    }

    final option = _findMonthOption(monthOptions, monthValue);
    if (option == null) {
      return trainings;
    }

    return trainings.where((training) {
      final date = trainingDateForStats(training);
      if (date == null) {
        return false;
      }
      return date.year == option.year && date.month == option.month;
    }).toList();
  }

  ({
    SeasonPeriodRange firstHalf,
    SeasonPeriodRange secondHalf,
  }) _resolveTrendHalfRanges({
    required String monthValue,
    required List<TeamStatsMonthOption> monthOptions,
    required SeasonPeriodRange fullSeason,
    required SeasonPeriodRange firstHalf,
    required SeasonPeriodRange secondHalf,
  }) {
    if (monthValue == kTeamStatsAllMonthsValue) {
      return (firstHalf: firstHalf, secondHalf: secondHalf);
    }

    final option = _findMonthOption(monthOptions, monthValue);
    if (option == null) {
      return (firstHalf: firstHalf, secondHalf: secondHalf);
    }

    final monthStart = DateTime(option.year, option.month);
    final monthEnd = DateTime(option.year, option.month + 1, 0);
    final splitDay = monthEnd.day >= 15 ? 15 : monthEnd.day ~/ 2;

    return (
      firstHalf: SeasonPeriodRange(
        start: monthStart,
        end: DateTime(option.year, option.month, splitDay),
      ),
      secondHalf: SeasonPeriodRange(
        start: DateTime(option.year, option.month, splitDay + 1),
        end: monthEnd,
      ),
    );
  }

  TeamStatsMonthOption? _findMonthOption(
    List<TeamStatsMonthOption> options,
    String monthValue,
  ) {
    for (final option in options) {
      if (option.value == monthValue) {
        return option;
      }
    }
    return null;
  }

  String _monthValue(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  bool _isPresent(PresenceType? type) {
    return type == PresenceType.present || type == PresenceType.late;
  }

  bool _isAbsent(PresenceType? type) {
    return type == PresenceType.absent;
  }

  double? _attendanceRate({required int present, required int total}) {
    if (total <= 0) {
      return null;
    }
    return (present / total) * 100;
  }
}

/// Past trainings for [teamId] in [seasonId], within [period] (excludes future).
Future<List<Training>> loadPastTrainingsForTeamSeason({
  required TrainingService trainingService,
  required String teamId,
  required String seasonId,
  required SeasonPeriodRange period,
}) async {
  final start = Timestamp.fromDate(
    DateTime(period.start.year, period.start.month, period.start.day),
  );
  final end = Timestamp.fromDate(
    DateTime(
      period.end.year,
      period.end.month,
      period.end.day,
      23,
      59,
      59,
      999,
    ),
  );

  final trainings = await trainingService.getTrainingsByTeamIdBetweenDates(
    teamId: teamId,
    start: start,
    end: end,
  );

  final today = DateTime.now();
  final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

  return trainings.where((training) {
    final trainingSeasonId = training.seasonId?.trim() ?? '';
    if (trainingSeasonId.isNotEmpty && trainingSeasonId != seasonId) {
      return false;
    }

    final date = trainingDateForStats(training);
    if (date == null) {
      return false;
    }

    return !date.isAfter(todayEnd);
  }).toList()
    ..sort((a, b) {
      final dateA = trainingDateForStats(a);
      final dateB = trainingDateForStats(b);
      if (dateA == null || dateB == null) {
        return 0;
      }
      return dateA.compareTo(dateB);
    });
}

/// Calendar date for a training, used when filtering stats by period.
DateTime? trainingDateForStats(Training training) {
  if (training.dateTime != null) {
    return training.dateTime!.toDate();
  }
  return parseTrainingDateTg(training.dateTg);
}
