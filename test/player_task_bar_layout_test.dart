import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_task_access.dart';
import 'package:grinta/util/player_task_bar_layout.dart';
import 'package:grinta/widget/agenda_player_task_bars.dart';

PlayerTask _task({
  required String id,
  required DateTime start,
  required DateTime end,
  String typeName = 'Matériel',
  String teamId = 'team-1',
  List<String> assignees = const <String>['p1'],
  List<String> access = const <String>['p1', 'manager'],
}) {
  return PlayerTask(
    id: id,
    typeId: 'type-$typeName',
    typeName: typeName,
    typeColor: 0xFFF95C1B,
    startAt: start,
    endAt: DateTime(end.year, end.month, end.day, 23, 59, 59),
    teamId: teamId,
    assigneeMemberIds: assignees,
    accessMemberIds: access,
    createdByUserId: 'uid-manager',
    createdByMemberId: 'manager',
  );
}

void main() {
  group('PlayerTask model', () {
    test('fromMap round-trips dates, assignees and color', () {
      final start = DateTime(2026, 9, 7);
      final end = DateTime(2026, 9, 13, 23, 59, 59);
      final original = _task(id: 't1', start: start, end: DateTime(2026, 9, 13));

      final restored = PlayerTask.fromMap(
        original.toMap(includeTimestamps: false),
        id: 't1',
      );

      expect(restored.typeName, 'Matériel');
      expect(restored.assigneeMemberIds, ['p1']);
      expect(restored.accessMemberIds, ['p1', 'manager']);
      expect(restored.startDay, DateUtils.dateOnly(start));
      expect(restored.endDay, DateUtils.dateOnly(end));
      expect(restored.barLabel, 'Matériel');
    });

    test('barLabel includes optional note', () {
      final task = _task(
        id: 't1',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
      ).copyWith(title: 'Plots');
      expect(task.barLabel, 'Matériel · Plots');
    });

    test('player bar keeps type and optional note', () {
      final task = _task(
        id: 't1',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        assignees: const <String>['p1', 'p2', 'p3'],
      ).copyWith(title: 'Plots');
      expect(
        playerTaskAgendaBarLabel(
          task,
          isManager: false,
          teamName: 'Séniors 2',
        ),
        'Matériel · Plots',
      );
    });

    test('manager bar is team, task and assignee count', () {
      final task = _task(
        id: 't1',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        assignees: const <String>['p1', 'p2', 'p3'],
      );
      expect(
        playerTaskAgendaBarLabel(
          task,
          isManager: true,
          teamName: 'Séniors 2',
        ),
        'Séniors 2 - Matériel - 3',
      );
    });

    test('manager bar includes note in the task name', () {
      final task = _task(
        id: 't1',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        assignees: const <String>['p1', 'p2'],
      ).copyWith(title: 'Plots');
      expect(
        playerTaskAgendaBarLabel(
          task,
          isManager: true,
          teamName: 'Séniors 2',
        ),
        'Séniors 2 - Matériel · Plots - 2',
      );
    });

    test('manager bar omits blank team name', () {
      final task = _task(
        id: 't1',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
      );
      expect(
        playerTaskAgendaBarLabel(task, isManager: true, teamName: '  '),
        'Matériel - 1',
      );
    });

    test('occursOnDay covers inclusive multi-day range', () {
      final task = _task(
        id: 'week',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 13),
      );
      expect(task.occursOnDay(DateTime(2026, 9, 7)), isTrue);
      expect(task.occursOnDay(DateTime(2026, 9, 10)), isTrue);
      expect(task.occursOnDay(DateTime(2026, 9, 13)), isTrue);
      expect(task.occursOnDay(DateTime(2026, 9, 6)), isFalse);
      expect(task.occursOnDay(DateTime(2026, 9, 14)), isFalse);
    });
  });

  group('layoutPlayerTaskBars', () {
    test('week-long task spans Monday to Sunday as one bar', () {
      final weekStart = DateTime(2026, 9, 7); // Monday
      final task = _task(
        id: 'week',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 13),
        typeName: 'Maillots',
      );

      final spans = layoutPlayerTaskBars(
        tasks: [task],
        weekStart: DateTime(2026, 9, 9),
      );

      expect(spans, hasLength(1));
      expect(spans.single.startColumn, 0);
      expect(spans.single.endColumn, 6);
      expect(spans.single.lane, 0);
      expect(spans.single.columnSpan, 7);
    });

    test('clips a task that starts before the visible week', () {
      final task = _task(
        id: 'clip',
        start: DateTime(2026, 9, 4),
        end: DateTime(2026, 9, 9),
      );

      final spans = layoutPlayerTaskBars(
        tasks: [task],
        weekStart: DateTime(2026, 9, 7),
      );

      expect(spans.single.startColumn, 0);
      expect(spans.single.endColumn, 2); // Wednesday
    });

    test('overlapping tasks stack on separate lanes', () {
      final week = _task(
        id: 'week',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 13),
        typeName: 'Matériel',
      );
      final mid = _task(
        id: 'wed',
        start: DateTime(2026, 9, 9),
        end: DateTime(2026, 9, 10),
        typeName: 'Maillots',
      );

      final spans = layoutPlayerTaskBars(
        tasks: [week, mid],
        weekStart: DateTime(2026, 9, 7),
      );

      expect(playerTaskBarLaneCount(spans), 2);
      final weekSpan = spans.firstWhere((s) => s.task.id == 'week');
      final midSpan = spans.firstWhere((s) => s.task.id == 'wed');
      expect(weekSpan.lane, isNot(midSpan.lane));
      expect(midSpan.startColumn, 2);
      expect(midSpan.endColumn, 3);
    });

    test('non-overlapping same-week tasks share a lane', () {
      final mon = _task(
        id: 'mon',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
      );
      final fri = _task(
        id: 'fri',
        start: DateTime(2026, 9, 11),
        end: DateTime(2026, 9, 11),
        typeName: 'Maillots',
      );

      final spans = layoutPlayerTaskBars(
        tasks: [mon, fri],
        weekStart: DateTime(2026, 9, 7),
      );

      expect(playerTaskBarLaneCount(spans), 1);
      expect(spans.every((s) => s.lane == 0), isTrue);
    });
  });

  group('playerTaskTeamNameFromTeams', () {
    test('resolves display name from keyTeam', () {
      final team = Team(keyTeam: 'team-1', name: 'Séniors 2');
      expect(
        playerTaskTeamNameFromTeams('team-1', [team]),
        'Séniors 2',
      );
      expect(playerTaskTeamNameFromTeams('other', [team]), '');
    });
  });

  group('applyPlayerTaskTeamFilter', () {
    test('keeps unscoped and matching team tasks', () {
      final a = _task(
        id: 'a',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        teamId: 'alpha',
      );
      final b = _task(
        id: 'b',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        teamId: 'beta',
      );
      final personal = _task(
        id: 'p',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        teamId: '',
      );

      final filtered = applyPlayerTaskTeamFilter(
        [a, b, personal],
        {'alpha'},
      );
      expect(filtered.map((t) => t.id), ['a', 'p']);
    });
  });

  group('playerTasksVisibleToMember', () {
    test('shows assigned and created tasks only', () {
      final assigned = _task(
        id: 'assigned',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        assignees: const <String>['player-a'],
        access: const <String>['player-a', 'manager'],
      );
      final other = _task(
        id: 'other',
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
        assignees: const <String>['player-b'],
        access: const <String>['player-b', 'manager'],
      );

      final visible = playerTasksVisibleToMember(
        [assigned, other],
        'player-a',
      );
      expect(visible.map((t) => t.id), ['assigned']);
    });
  });

  testWidgets('week-long task paints a bar under the date strip', (
    WidgetTester tester,
  ) async {
    final task = _task(
      id: 'week',
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 13),
      typeName: 'Maillots',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        home: Scaffold(
          body: AgendaPlayerTaskBars(
            tasks: [task],
            weekStart: DateTime(2026, 9, 7),
            onTaskTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Maillots'), findsOneWidget);
    expect(find.byIcon(AgendaPlayerTaskBars.assigneeCountIcon), findsNothing);
    expect(_barChipColor(tester), AppColors.light.primary);
  });

  testWidgets('agenda task bar uses Créer primary, not type/success green', (
    WidgetTester tester,
  ) async {
    final task = _task(
      id: 'week',
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 13),
      typeName: 'Maillots',
    ).copyWith(typeColor: AppColors.light.success.toARGB32());

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        home: Scaffold(
          body: AgendaPlayerTaskBars(
            tasks: [task],
            weekStart: DateTime(2026, 9, 7),
            onTaskTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Maillots'), findsOneWidget);
    expect(_barChipColor(tester), AppColors.light.primary);
    expect(_barChipColor(tester), isNot(AppColors.light.success));
  });

  testWidgets('manager week bar shows team, task, count and people icon', (
    WidgetTester tester,
  ) async {
    final task = _task(
      id: 'week',
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 13),
      assignees: const <String>['p1', 'p2', 'p3'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        home: Scaffold(
          body: AgendaPlayerTaskBars(
            tasks: [task],
            weekStart: DateTime(2026, 9, 7),
            onTaskTap: (_) {},
            labelFor: (PlayerTask t) => playerTaskAgendaBarLabel(
              t,
              isManager: true,
              teamName: 'Séniors 2',
            ),
            showAssigneeIcon: (_) => true,
          ),
        ),
      ),
    );

    expect(find.text('Séniors 2 - Matériel - 3'), findsOneWidget);
    expect(find.text('Matériel'), findsNothing);
    expect(find.byIcon(AgendaPlayerTaskBars.assigneeCountIcon), findsOneWidget);
    expect(_barChipColor(tester), AppColors.light.primary);
  });
}

Color _barChipColor(WidgetTester tester) {
  final Finder chip = find.ancestor(
    of: find.byType(InkWell),
    matching: find.byType(Material),
  );
  return tester.widget<Material>(chip.first).color ?? const Color(0x00000000);
}
