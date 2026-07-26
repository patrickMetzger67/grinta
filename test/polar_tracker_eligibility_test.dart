import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/util/polar_tracker_eligibility.dart';

Owner _owner({
  required String typeTracker,
  bool isActive = true,
  bool withSyncing = true,
}) {
  return Owner(
    name: 'Kit',
    typeTracker: typeTracker,
    isActive: isActive,
    withSyncing: withSyncing,
    email: 'kit@example.com',
    firstname: 'Kit',
    lastname: 'Owner',
    uidCreate: 'u1',
    uidUpdate: 'u1',
  );
}

void main() {
  group('TrackerOwner polar type', () {
    test('typeTrackers includes polar', () {
      expect(TrackerOwner.typeTrackers, contains(TrackerOwner.typePolar));
    });

    test('withSyncingForType is true for polar (BLE live)', () {
      expect(TrackerOwner.withSyncingForType(TrackerOwner.typePolar), isTrue);
    });

    test('isPolarType is case-insensitive', () {
      expect(TrackerOwner.isPolarType('polar'), isTrue);
      expect(TrackerOwner.isPolarType('Polar'), isTrue);
      expect(TrackerOwner.isPolarType('inspirit'), isFalse);
      expect(TrackerOwner.isPolarType(null), isFalse);
    });
  });

  group('ownerUsesPolarTeamKit', () {
    test('returns true for polar owners', () {
      expect(ownerUsesPolarTeamKit(_owner(typeTracker: 'polar')), isTrue);
    });

    test('returns false for inspirit / intense', () {
      expect(ownerUsesPolarTeamKit(_owner(typeTracker: 'inspirit')), isFalse);
      expect(ownerUsesPolarTeamKit(_owner(typeTracker: 'intense')), isFalse);
    });
  });
}
