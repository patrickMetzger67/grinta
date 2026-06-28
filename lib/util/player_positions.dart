import '../l10n/app_localizations.dart';

/// Legacy player field position codes (goaltimefootball / effectives).
const int positionCodeEducator = 1;
const int positionCodeExecutive = 2;
const int positionCodeGoalkeeper = 3;
const int positionCodeDefender = 4;
const int positionCodeMidfielder = 5;
const int positionCodeForward = 6;

/// Staff-only profile code (outside Grinta pitch range 1–23).
const int positionCodeMedical = 24;

/// Legacy profile role codes for staff (educator/coach, executive, or medical).
bool isStaffProfilePositionCode(int code) =>
    code == positionCodeEducator ||
    code == positionCodeExecutive ||
    code == positionCodeMedical;

/// Selectable staff role codes when adding or editing Grinta staff.
const List<int> grintaStaffRoleCodes = <int>[
  positionCodeEducator,
  positionCodeExecutive,
  positionCodeMedical,
];

bool hasStaffProfilePositionCodes(Iterable<int> codes) =>
    codes.any(isStaffProfilePositionCode);

/// Pitch/field position from Grinta config (`config/playerPositions`), codes 1–23.
bool isGrintaPitchPositionCode(int code) =>
    code >= 1 && code <= grintaPlayerPositionCount;

bool hasGrintaPitchPositionCodes(Iterable<int> codes) =>
    codes.any(isGrintaPitchPositionCode);

/// Classifies staff on a Grinta roster entry.
///
/// [positions] from [GrintaPlayer] may be pitch codes (1–23) or legacy profile
/// staff codes (1=educator, 2=executive). Codes 1 and 2 overlap both systems;
/// pitch codes always win unless the member is explicitly listed in
/// [listedInManagers] (team `managers` array).
bool isGrintaRosterStaff({
  required Iterable<int> positions,
  required bool listedInManagers,
}) {
  if (hasGrintaPitchPositionCodes(positions)) {
    final List<int> codes =
        positions.where((int code) => code > 0).toList(growable: false);
    if (codes.isNotEmpty &&
        codes.every(isStaffProfilePositionCode) &&
        listedInManagers) {
      return true;
    }
    return false;
  }
  if (hasStaffProfilePositionCodes(positions)) {
    return true;
  }
  return listedInManagers;
}

/// Localized label for a Grinta staff role profile code.
String grintaStaffRoleLabel(int code, AppLocalizations l10n) {
  switch (code) {
    case positionCodeEducator:
      return l10n.grintaStaffRoleEducator;
    case positionCodeExecutive:
      return l10n.grintaStaffRoleExecutive;
    case positionCodeMedical:
      return l10n.grintaStaffRoleMedical;
    default:
      return l10n.entityStaff;
  }
}

/// Grinta roster position codes (`config/playerPositions`), 1–23.
const int grintaPlayerPositionCount = 23;

const List<int> grintaPlayerPositionCodes = <int>[
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
];

/// Built-in fallback when Firestore `config/playerPositions` is missing.
const List<Map<String, Object>> defaultGrintaPlayerPositionEntries = <Map<String, Object>>[
  {'code': 1, 'order': 1, 'labelKey': 'positionGoalkeeper'},
  {'code': 2, 'order': 2, 'labelKey': 'positionCenterBack'},
  {'code': 3, 'order': 3, 'labelKey': 'positionCenterBackLeft'},
  {'code': 4, 'order': 4, 'labelKey': 'positionCenterBackRight'},
  {'code': 5, 'order': 5, 'labelKey': 'positionLeftDefender'},
  {'code': 6, 'order': 6, 'labelKey': 'positionRightDefender'},
  {'code': 7, 'order': 7, 'labelKey': 'positionLeftBack'},
  {'code': 8, 'order': 8, 'labelKey': 'positionRightBack'},
  {'code': 9, 'order': 9, 'labelKey': 'positionLeftPiston'},
  {'code': 10, 'order': 10, 'labelKey': 'positionRightPiston'},
  {'code': 11, 'order': 11, 'labelKey': 'positionDefensiveMidfielder'},
  {'code': 12, 'order': 12, 'labelKey': 'positionCentralMidfielder'},
  {'code': 13, 'order': 13, 'labelKey': 'positionBoxToBoxMidfielder'},
  {'code': 14, 'order': 14, 'labelKey': 'positionLeftMidfielder'},
  {'code': 15, 'order': 15, 'labelKey': 'positionRightMidfielder'},
  {'code': 16, 'order': 16, 'labelKey': 'positionAttackingMidfielder'},
  {'code': 17, 'order': 17, 'labelKey': 'positionPlaymaker'},
  {'code': 18, 'order': 18, 'labelKey': 'positionLeftWinger'},
  {'code': 19, 'order': 19, 'labelKey': 'positionRightWinger'},
  {'code': 20, 'order': 20, 'labelKey': 'positionSecondStriker'},
  {'code': 21, 'order': 21, 'labelKey': 'positionCenterForward'},
  {'code': 22, 'order': 22, 'labelKey': 'positionStriker'},
  {'code': 23, 'order': 23, 'labelKey': 'positionAttacker'},
];

/// Selectable codes when Firestore config is unavailable.
const List<int> selectablePlayerPositionCodes = grintaPlayerPositionCodes;

/// Legacy l10n labels for effectives / historical member profiles (codes 1–6).
String playerPositionLabel(int code, AppLocalizations l10n) {
  switch (code) {
    case positionCodeEducator:
      return l10n.positionEducator;
    case positionCodeExecutive:
      return l10n.positionExecutive;
    case positionCodeMedical:
      return l10n.grintaStaffRoleMedical;
    case positionCodeGoalkeeper:
      return l10n.positionGoalkeeper;
    case positionCodeDefender:
      return l10n.positionDefender;
    case positionCodeMidfielder:
      return l10n.positionMidfielder;
    case positionCodeForward:
      return l10n.positionForward;
    default:
      return l10n.entityPlayer;
  }
}

/// Resolves an optional Firestore [labelKey] against generated l10n getters.
String? playerPositionLabelFromKey(String? labelKey, AppLocalizations l10n) {
  final String key = labelKey?.trim() ?? '';
  if (key.isEmpty) {
    return null;
  }

  switch (key) {
    case 'positionEducator':
      return l10n.positionEducator;
    case 'positionExecutive':
      return l10n.positionExecutive;
    case 'positionGoalkeeper':
      return l10n.positionGoalkeeper;
    case 'positionCenterBack':
      return l10n.positionCenterBack;
    case 'positionCenterBackLeft':
      return l10n.positionCenterBackLeft;
    case 'positionCenterBackRight':
      return l10n.positionCenterBackRight;
    case 'positionLeftDefender':
      return l10n.positionLeftDefender;
    case 'positionRightDefender':
      return l10n.positionRightDefender;
    case 'positionLeftBack':
      return l10n.positionLeftBack;
    case 'positionRightBack':
      return l10n.positionRightBack;
    case 'positionLeftPiston':
      return l10n.positionLeftPiston;
    case 'positionRightPiston':
      return l10n.positionRightPiston;
    case 'positionDefensiveMidfielder':
      return l10n.positionDefensiveMidfielder;
    case 'positionCentralMidfielder':
      return l10n.positionCentralMidfielder;
    case 'positionBoxToBoxMidfielder':
      return l10n.positionBoxToBoxMidfielder;
    case 'positionLeftMidfielder':
      return l10n.positionLeftMidfielder;
    case 'positionRightMidfielder':
      return l10n.positionRightMidfielder;
    case 'positionAttackingMidfielder':
      return l10n.positionAttackingMidfielder;
    case 'positionPlaymaker':
      return l10n.positionPlaymaker;
    case 'positionLeftWinger':
      return l10n.positionLeftWinger;
    case 'positionRightWinger':
      return l10n.positionRightWinger;
    case 'positionSecondStriker':
      return l10n.positionSecondStriker;
    case 'positionCenterForward':
      return l10n.positionCenterForward;
    case 'positionStriker':
      return l10n.positionStriker;
    case 'positionAttacker':
      return l10n.positionAttacker;
    case 'positionDefender':
      return l10n.positionDefender;
    case 'positionMidfielder':
      return l10n.positionMidfielder;
    case 'positionForward':
      return l10n.positionForward;
    default:
      return null;
  }
}
