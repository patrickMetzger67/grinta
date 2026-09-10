import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/team_fine_scale.dart';
import 'package:grinta/model/team_fine_type.dart';
import 'package:grinta/util/team_fine_access.dart';
import 'package:grinta/util/team_fine_amount.dart';

void main() {
  group('parseFineAmount', () {
    test('parses comma and period decimals', () {
      expect(parseFineAmount('5,50'), 5.5);
      expect(parseFineAmount('5.50'), 5.5);
      expect(parseFineAmount('10'), 10);
      expect(parseFineAmount('5,00 €'), 5);
      expect(parseFineAmount('  2.5  '), 2.5);
    });

    test('parses thousands separators', () {
      expect(parseFineAmount('1.234,50'), 1234.5);
      expect(parseFineAmount('1,234.50'), 1234.5);
    });

    test('returns null for empty or invalid input', () {
      expect(parseFineAmount(null), isNull);
      expect(parseFineAmount(''), isNull);
      expect(parseFineAmount('abc'), isNull);
    });
  });

  group('formatFineAmount', () {
    test('formats two decimals with euro sign', () {
      expect(formatFineAmount(5), '5,00 €');
      expect(formatFineAmount(5.5), '5,50 €');
      expect(formatFineAmount(12.99), '12,99 €');
    });
  });

  group('TeamFineType', () {
    test('fromMap round-trips name and team', () {
      const original = TeamFineType(
        id: 'type-1',
        teamId: 'team-1',
        name: 'Retard',
      );
      final restored = TeamFineType.fromMap(
        original.toMap(includeTimestamps: false),
        id: 'type-1',
      );
      expect(restored.teamId, 'team-1');
      expect(restored.name, 'Retard');
    });
  });

  group('TeamFineScale', () {
    test('fromMap round-trips decimal amount', () {
      const original = TeamFineScale(
        id: 'scale-1',
        teamId: 'team-1',
        typeId: 'type-1',
        typeName: 'Retard',
        amount: 7.5,
        createdByUserId: 'uid-1',
        createdByMemberId: 'p1',
      );
      final restored = TeamFineScale.fromMap(
        original.toMap(includeTimestamps: false),
        id: 'scale-1',
      );
      expect(restored.amount, 7.5);
      expect(restored.typeName, 'Retard');
      expect(restored.createdByMemberId, 'p1');
    });

    test('fineAmountFrom accepts int and string', () {
      expect(fineAmountFrom(5), 5);
      expect(fineAmountFrom(5.25), 5.25);
      expect(fineAmountFrom('3,5'), 3.5);
    });
  });

  group('canManageTeamFines', () {
    test('managers always have access', () {
      final team = Team(
        keyTeam: 'team-1',
        name: 'U18',
        finesManagerMemberId: 'p-other',
      );
      expect(
        canManageTeamFines(
          team: team,
          isTeamManager: true,
          selectedPlayerId: 'p1',
        ),
        isTrue,
      );
    });

    test('designated player has access', () {
      final team = Team(
        keyTeam: 'team-1',
        name: 'U18',
        finesManagerMemberId: 'p1',
      );
      expect(
        canManageTeamFines(
          team: team,
          isTeamManager: false,
          selectedPlayerId: 'p1',
        ),
        isTrue,
      );
    });

    test('other players do not have access', () {
      final team = Team(
        keyTeam: 'team-1',
        name: 'U18',
        finesManagerMemberId: 'p1',
      );
      expect(
        canManageTeamFines(
          team: team,
          isTeamManager: false,
          selectedPlayerId: 'p2',
        ),
        isFalse,
      );
    });

    test('lookup ids match designated member', () {
      final team = Team(
        keyTeam: 'team-1',
        name: 'U18',
        finesManagerMemberId: 'legacy-id',
      );
      expect(
        isTeamFinesManager(
          team,
          selectedPlayerId: 'p1',
          lookupIds: <String>{'p1', 'legacy-id'},
        ),
        isTrue,
      );
    });
  });
}
