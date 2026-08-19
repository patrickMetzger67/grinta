import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/analyze_video_storage_service.dart';
import 'package:grinta/services/analyze_video_tactics.dart';
import 'package:grinta/widget/analyze_video/analyze_mp4_player.dart';

void main() {
  group('sanitizeDebugVideoFilename', () {
    test('keeps a simple mp4 name', () {
      expect(sanitizeDebugVideoFilename('clip.mp4'), 'clip.mp4');
    });

    test('replaces unsafe characters and lowercases the extension', () {
      expect(
        sanitizeDebugVideoFilename('Match 12/03 (A).MP4'),
        'Match_12_03_A.mp4',
      );
    });

    test('falls back when the base name is empty', () {
      expect(sanitizeDebugVideoFilename('*** .mp4'), 'video.mp4');
    });
  });

  group('buildDebugVideoStoragePath', () {
    test('uses video/{uid}/{timestamp}_{safeName}', () {
      expect(
        buildDebugVideoStoragePath(
          uid: 'user-1',
          originalName: 'My Clip.mp4',
          timestampMs: 1700000000000,
        ),
        'video/user-1/1700000000000_My_Clip.mp4',
      );
    });
  });

  group('validation helpers', () {
    test('accepts mp4 filenames only', () {
      expect(isDebugVideoMp4Filename('a.mp4'), isTrue);
      expect(isDebugVideoMp4Filename('a.MP4'), isTrue);
      expect(isDebugVideoMp4Filename('a.mov'), isFalse);
      expect(isDebugVideoMp4Filename('a.mp4.txt'), isFalse);
    });

    test('enforces the 200 MB limit', () {
      expect(isDebugVideoWithinSizeLimit(1), isTrue);
      expect(isDebugVideoWithinSizeLimit(kDebugVideoMaxBytes), isTrue);
      expect(isDebugVideoWithinSizeLimit(kDebugVideoMaxBytes + 1), isFalse);
      expect(isDebugVideoWithinSizeLimit(0), isFalse);
    });
  });

  group('tacticsStoragePathForVideo', () {
    test('sits next to the mp4 in the same folder', () {
      expect(
        tacticsStoragePathForVideo(
          buildDebugVideoStoragePath(
            uid: 'user-1',
            originalName: 'My Clip.mp4',
            timestampMs: 1700000000000,
          ),
        ),
        'video/user-1/1700000000000_My_Clip.tactics.json',
      );
    });
  });

  group('formatDebugVideoTime', () {
    test('formats minutes and seconds', () {
      expect(formatDebugVideoTime(const Duration(seconds: 9)), '0:09');
      expect(formatDebugVideoTime(const Duration(seconds: 32)), '0:32');
      expect(formatDebugVideoTime(const Duration(minutes: 1, seconds: 5)), '1:05');
    });

    test('includes hours when needed', () {
      expect(
        formatDebugVideoTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });
}
