import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/last_results.dart';
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
}
