import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/last_results.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/last_results_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';

void main() {
  group('lastResultsDocumentId', () {
    test('joins clubId and competitionId', () {
      expect(lastResultsDocumentId('500554', '450652'), '500554_450652');
    });

    test('parses the document id back', () {
      final key = parseLastResultsDocumentId('500554_450652');
      expect(key?.clubId, '500554');
      expect(key?.competitionId, '450652');
    });
  });

  group('LastResults toMap / fromMap', () {
    test('round-trips the scrape payload', () {
      final kickoff = Timestamp.fromDate(DateTime.utc(2026, 3, 15, 15));
      final updatedAt = Timestamp.fromDate(DateTime.utc(2026, 3, 16, 8, 30));
      final original = LastResults(
        clubId: '500554',
        competitionId: '450652',
        updatedAt: updatedAt,
        results: [
          LastResultEntry(
            outcome: MatchOutcome.draw,
            matchId: 'm1',
            timestamp: kickoff,
          ),
          LastResultEntry(
            outcome: MatchOutcome.loss,
            matchId: 'm2',
            timestamp: kickoff,
          ),
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm3'),
        ],
      );

      final parsed = LastResults.fromMap(original.toMap());

      expect(parsed.clubId, '500554');
      expect(parsed.competitionId, '450652');
      expect(parsed.documentId, '500554_450652');
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.results, hasLength(3));
      expect(parsed.results[0].outcome, MatchOutcome.draw);
      expect(parsed.results[1].outcome, MatchOutcome.loss);
      expect(parsed.results[2].outcome, MatchOutcome.win);
      expect(parsed.results[0].matchId, 'm1');
      expect(parsed.hasSameResultsAs(original), isTrue);
    });
  });

  group('clubIdForLastResults', () {
    test('uses match.clubs[0/1] and ignores affiliation', () {
      final match = Match(
        affiliationTeam1: '500554',
        affiliationTeam2: '500123',
        competitionID: '450652',
        clubs: ['club-a', 'club-b'],
      );

      expect(clubIdForLastResults(match, MatchSide.team1), 'club-a');
      expect(clubIdForLastResults(match, MatchSide.team2), 'club-b');
    });

    test('returns null when clubs[i] is missing, even with affiliation', () {
      final match = Match(
        affiliationTeam1: '500554',
        affiliationTeam2: '500123',
        competitionID: '450652',
      );

      expect(clubIdForLastResults(match, MatchSide.team1), isNull);
      expect(clubIdForLastResults(match, MatchSide.team2), isNull);
    });
  });

  group('lastResultsKeyForMatchSide', () {
    test('builds clubId_competitionId from clubs[]', () {
      final match = Match(
        affiliationTeam1: '500554',
        competitionID: '450652',
        clubs: ['club-a', 'club-b'],
      );

      final key = lastResultsKeyForMatchSide(match, MatchSide.team1);
      expect(key?.documentId, 'club-a_450652');
    });

    test('returns null when club or competition is missing', () {
      expect(
        lastResultsKeyForMatchSide(
          Match(affiliationTeam1: '500554', clubs: ['club-a']),
          MatchSide.team1,
        ),
        isNull,
      );
      expect(
        lastResultsKeyForMatchSide(
          Match(competitionID: '450652', affiliationTeam1: '500554'),
          MatchSide.team1,
        ),
        isNull,
      );
    });
  });

  group('lastResultsDisplaySlots', () {
    test('pads empties on the right up to 5', () {
      final slots = lastResultsDisplaySlots([
        const LastResultEntry(outcome: MatchOutcome.win),
        const LastResultEntry(outcome: MatchOutcome.draw),
        const LastResultEntry(outcome: MatchOutcome.loss),
      ]);

      expect(slots, hasLength(5));
      expect(slots[0], MatchOutcome.win);
      expect(slots[1], MatchOutcome.draw);
      expect(slots[2], MatchOutcome.loss);
      expect(slots[3], isNull);
      expect(slots[4], isNull);
    });

    test('keeps oldest to newest for a full form', () {
      final slots = lastResultsDisplaySlots([
        const LastResultEntry(outcome: MatchOutcome.win),
        const LastResultEntry(outcome: MatchOutcome.win),
        const LastResultEntry(outcome: MatchOutcome.draw),
        const LastResultEntry(outcome: MatchOutcome.loss),
        const LastResultEntry(outcome: MatchOutcome.win),
      ]);

      expect(slots, [
        MatchOutcome.win,
        MatchOutcome.win,
        MatchOutcome.draw,
        MatchOutcome.loss,
        MatchOutcome.win,
      ]);
    });
  });

  group('lastResultsHighlightIndex', () {
    test('rings the current match when it is in the results', () {
      final index = lastResultsHighlightIndex(
        results: const [
          LastResultEntry(outcome: MatchOutcome.draw, matchId: 'm1'),
          LastResultEntry(outcome: MatchOutcome.loss, matchId: 'm2'),
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm3'),
        ],
        highlightMatchId: 'm2',
      );

      expect(index, 1);
    });

    test('rings the most recent slot when the match is not in results', () {
      final index = lastResultsHighlightIndex(
        results: const [
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm1'),
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm2'),
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm3'),
        ],
        highlightMatchId: 'upcoming',
      );

      expect(index, 2);
    });

    test('returns null when there are no results', () {
      expect(
        lastResultsHighlightIndex(results: const [], highlightMatchId: 'm1'),
        isNull,
      );
    });
  });
}
