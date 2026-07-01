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

/// True when [GrintaPlayer.fonction] holds a staff role (new model).
bool hasExplicitGrintaStaffFonction(int? fonction) =>
    fonction != null &&
    fonction > 0 &&
    isStaffProfilePositionCode(fonction);

/// Staff role from explicit [fonction] or legacy medical code (24) in [positions].
///
/// Pitch codes 1–23 in [positions] are never interpreted as staff roles when
/// [fonction] is unset (codes 1–2 overlap educator/executive staff roles).
int? resolveGrintaStaffFonction({
  int? fonction,
  Iterable<int> positions = const [],
}) {
  if (hasExplicitGrintaStaffFonction(fonction)) {
    return fonction;
  }
  if (hasGrintaPitchPositionCodes(positions)) {
    return null;
  }
  for (final int code in positions) {
    if (code == positionCodeMedical) {
      return code;
    }
  }
  return null;
}

/// Legacy member-profile field roles (goalkeeper, defender, midfielder, forward).
bool isMemberProfileFieldPlayerRole(int code) =>
    code == positionCodeGoalkeeper ||
    code == positionCodeDefender ||
    code == positionCodeMidfielder ||
    code == positionCodeForward;

bool hasMemberProfileFieldPlayerRole(Iterable<int> codes) =>
    codes.any(isMemberProfileFieldPlayerRole);

/// True when the creator should be added to [Team.players] / [Team.grintaPlayers].
bool shouldAutoAddMemberProfileToTeamRoster(Iterable<int> positionCodes) =>
    hasMemberProfileFieldPlayerRole(positionCodes);

/// Pitch/field position from Grinta config (`config/playerPositions`), codes 1–23.
bool isGrintaPitchPositionCode(int code) =>
    code >= 1 && code <= grintaPlayerPositionCount;

bool hasGrintaPitchPositionCodes(Iterable<int> codes) =>
    codes.any(isGrintaPitchPositionCode);

/// On-pitch Grinta roles (codes 3–23). Codes 1–2 overlap staff profile roles
/// (educator, executive) and are not treated as definite field-player rows.
bool isDefiniteGrintaFieldPitchCode(int code) =>
    isGrintaPitchPositionCode(code) && code > positionCodeExecutive;

bool hasDefiniteGrintaFieldPitchCodes(Iterable<int> codes) =>
    codes.any(isDefiniteGrintaFieldPitchCode);

/// Classifies staff on a Grinta roster entry for UI lists and limits.
///
/// Staff roles live in [GrintaPlayer.fonction]. [positions] are pitch codes
/// (1–23) for field players only. Without explicit [fonction], any pitch code
/// in [positions] means field player (codes 1–2 overlap legacy staff roles).
/// Legacy medical staff may still use code 24 in [positions].
///
/// [listedInManagers] is ignored: `team.managers` grants manager permissions
/// only and must not move a member into the staff section.
bool isGrintaRosterStaff({
  required Iterable<int> positions,
  int? fonction,
  required bool listedInManagers,
}) {
  if (hasExplicitGrintaStaffFonction(fonction)) {
    return true;
  }
  if (hasGrintaPitchPositionCodes(positions)) {
    return false;
  }
  return positions.any((int code) => code == positionCodeMedical);
}

/// CRUD slot lookup for staff vs field-player [GrintaPlayer] rows (same
/// memberId may appear twice). Matches [isGrintaRosterStaff] except legacy
/// educator/executive rows stored only in [positions] without [fonction],
/// which require [managerIds] for disambiguation.
bool isGrintaStaffCrudEntry({
  required Iterable<int> positions,
  int? fonction,
  required String playerId,
  required Set<String> managerIds,
}) {
  if (hasExplicitGrintaStaffFonction(fonction)) {
    return true;
  }

  if (hasGrintaPitchPositionCodes(positions)) {
    return false;
  }

  if (positions.any((int code) => code == positionCodeMedical)) {
    return true;
  }

  final String trimmedPlayerId = playerId.trim();
  if (trimmedPlayerId.isEmpty || !managerIds.contains(trimmedPlayerId)) {
    return false;
  }

  final List<int> codes =
      positions.where((int code) => code > 0).toList(growable: false);
  if (codes.isEmpty) {
    return false;
  }

  return codes.every(
    (int code) =>
        code == positionCodeEducator || code == positionCodeExecutive,
  );
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

/// Selectable profile roles when creating or editing a member profile.
///
/// Distinct from [selectablePlayerPositionCodes] / [PlayerPositionsService]:
/// member profiles use legacy staff + field role codes (educator, executive,
/// goalkeeper, defender, midfielder, forward), not Grinta pitch codes 1–23.
const List<int> selectableMemberProfilePositionCodes = <int>[
  positionCodeEducator,
  positionCodeExecutive,
  positionCodeGoalkeeper,
  positionCodeDefender,
  positionCodeMidfielder,
  positionCodeForward,
];

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
