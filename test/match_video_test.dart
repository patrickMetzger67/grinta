import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/match_video.dart';

void main() {
  group('Match.videoUrl', () {
    test('is kept in memory and omitted from Firestore toMap', () {
      final match = Match(
        id: 'match-1',
        team1: 'A',
        team2: 'B',
        videoUrl: 'https://example.com/clip.mp4',
      );
      expect(match.videoUrl, 'https://example.com/clip.mp4');
      expect(match.toMap().containsKey('videoUrl'), isFalse);
      expect(match.toMap()[keyMatchUrl], isNull);
    });
  });

  group('MatchVideo', () {
    test('round-trips detections and kit colors', () {
      final video = MatchVideo(
        id: 'mv-1',
        matchId: 'match-1',
        videoUrl: 'https://example.com/clip.mp4',
        team1KitColor: 0xFF1E4DB7,
        team2KitColor: 0xFFFFFFFF,
        refereeKitColor: 0xFFD4FF00,
        detections: const [
          MatchVideoDetection(
            kind: MatchVideoObjectKind.person,
            left: 0.1,
            top: 0.2,
            width: 0.05,
            height: 0.12,
            score: 0.8,
            atMs: 32000,
            jerseyNumber: 7,
            teamId: 'team-a',
          ),
          MatchVideoDetection(
            kind: MatchVideoObjectKind.ball,
            left: 0.5,
            top: 0.5,
            width: 0.02,
            height: 0.02,
            score: 0.6,
            atMs: 32000,
          ),
        ],
      );

      final restored = MatchVideo.fromMap(video.toMap());
      expect(restored.matchId, 'match-1');
      expect(restored.videoUrl, 'https://example.com/clip.mp4');
      expect(restored.team1.kitColor, 0xFF1E4DB7);
      expect(restored.team2.kitColor, 0xFFFFFFFF);
      expect(matchVideoColorToHex(restored.team1KitColor), '#1E4DB7');
      expect(matchVideoColorToHex(restored.team2KitColor), '#FFFFFF');
      expect(matchVideoColorToHex(restored.refereeKitColor), '#D4FF00');
      expect(restored.toMap()['team1'], containsPair('kitColor', '#1E4DB7'));
      expect(restored.toMap()['team2'], containsPair('kitColor', '#FFFFFF'));
      expect(restored.detections, hasLength(2));
      expect(restored.detections.first.kind, MatchVideoObjectKind.person);
      expect(restored.detections.first.jerseyNumber, 7);
      expect(restored.detections.last.kind, MatchVideoObjectKind.ball);
    });

    test('applyMatch copies team names, ids and keeps kit colors', () {
      final video = MatchVideo(
        team1KitColor: 0xFF1E4DB7,
        team2KitColor: 0xFFFFFFFF,
      );
      video.applyMatch(
        Match(
          id: 'm1',
          team1: 'Grinta FC',
          team2: 'Adversaire',
          teamID: 'team-a',
          teams: <dynamic>['team-a', 'team-b'],
        ),
      );
      expect(video.matchId, 'm1');
      expect(video.team1.name, 'Grinta FC');
      expect(video.team1.teamId, 'team-a');
      expect(video.team1.kitColor, 0xFF1E4DB7);
      expect(video.team2.name, 'Adversaire');
      expect(video.team2.teamId, 'team-b');
      expect(video.team2.kitColor, 0xFFFFFFFF);
    });
  });

  group('matchVideoColorFromHex', () {
    test('parses rgb and argb hex', () {
      expect(matchVideoColorFromHex('#1E4DB7'), 0xFF1E4DB7);
      expect(matchVideoColorFromHex('FFFFFFFF'), 0xFFFFFFFF);
      expect(matchVideoColorFromHex('bad'), isNull);
    });
  });
}
