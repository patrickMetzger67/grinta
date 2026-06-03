// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Grinta';

  @override
  String get heroTitle => 'Manage your sporting activity simply';

  @override
  String get heroSubtitle =>
      'Organize your events, manage your members and monitor your activity from a clear, modern and responsive interface.';

  @override
  String get loginTitle => 'Connection';

  @override
  String get loginSubtitle => 'Log in to access your space.';

  @override
  String get email => 'E-mail address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => 'Forgotten password?';

  @override
  String get signIn => 'Log in';

  @override
  String get emailAndPasswordRequired => 'Email and password required';

  @override
  String get signInError => 'Connection error';

  @override
  String get userNotFound => 'No users found for this email';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get invalidCredential => 'Invalid identifiers';

  @override
  String get tooManyRequests => 'Too many attempts. Try again later';

  @override
  String get userDisabled => 'This account has been deactivated';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get createAccount => 'Create an account';

  @override
  String get or => 'Or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get hasATeamCode => 'I have a team code';

  @override
  String get slide1Title => 'Manage your team';

  @override
  String get slide1Subtitle =>
      'Centralize your members, information and organization in a single application.';

  @override
  String get slide2Title => 'Plan your matches';

  @override
  String get slide2Subtitle =>
      'Create your events, summon your players and easily track availability.';

  @override
  String get slide3Title => 'Track your performance';

  @override
  String get slide3Subtitle =>
      'View statistics, activity and results from a clear interface.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'DELETE';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionClose => 'Close';

  @override
  String get actionOk => 'Okay';

  @override
  String get actionYes => 'Yes';

  @override
  String get actionNo => 'No';

  @override
  String get actionValidate => 'To validate';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNew => 'New';

  @override
  String get actionChoosePeriod => 'Choose a period';

  @override
  String get actionWeekPrevious => 'Week -';

  @override
  String get actionWeekNext => 'Week +';

  @override
  String get actionLoadBefore => 'Load forward';

  @override
  String get actionLoadAfter => 'Load after';

  @override
  String get actionToday => 'Today';

  @override
  String get actionLogout => 'Disconnect';

  @override
  String get actionLogoutConfirmTitle => 'Disconnect';

  @override
  String get actionLogoutConfirmMessage => 'Do you really want to log out?';

  @override
  String get actionAddPlayer => 'Add a player';

  @override
  String get actionAddStaff => 'Add a staff';

  @override
  String get actionAddZone => 'Add an area';

  @override
  String get actionAddToCart => 'Add to cart';

  @override
  String get actionBeginCheckout => 'Start payment';

  @override
  String get actionConnect => 'Connect';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionEraseData => 'Clear data';

  @override
  String get actionChooseAsiFile => 'Choose an .asi file';

  @override
  String get actionDefaultValues => 'Default values';

  @override
  String get actionRemoveCustomization => 'Remove personalization';

  @override
  String get actionDisconnect => 'Disconnect';

  @override
  String get actionAsiFile => '.asi file';

  @override
  String get actionWeekPreviousLong => 'Previous week';

  @override
  String get actionWeekNextLong => 'Next week';

  @override
  String get entityTeam => 'team';

  @override
  String entityTeamWithIndex(int index) {
    return 'Team $index';
  }

  @override
  String get entityTeams => 'teams';

  @override
  String get entityPlayer => 'Player';

  @override
  String get entityPlayers => 'Players';

  @override
  String get entityPlayerUnknown => 'Unknown player';

  @override
  String get entityPlayerNotSet => 'Player not informed';

  @override
  String get entityStaff => 'Staff';

  @override
  String get entityMatch => 'Match';

  @override
  String get entityMatches => 'Matches';

  @override
  String get entityTraining => 'Training';

  @override
  String get entityTrainings => 'Workouts';

  @override
  String get entityField => 'Ground';

  @override
  String get entityFieldUndefined => 'Undefined land';

  @override
  String get entitySeason => 'Season';

  @override
  String get entityEvent => 'event';

  @override
  String get entityEvents => 'events';

  @override
  String get entityConversation => 'conversation';

  @override
  String get entityUser => 'user';

  @override
  String get entityProduct => 'Product';

  @override
  String get entityCart => 'Basket';

  @override
  String get entityApplication => 'Application';

  @override
  String get entityMap => 'Map';

  @override
  String get entityIndicator => 'Indicator';

  @override
  String get entityDeviceId => 'Device ID';

  @override
  String get entityTracker => 'Tracker';

  @override
  String get entityTrackerId => 'id';

  @override
  String get entityName => 'name';

  @override
  String get entityCode => 'Code';

  @override
  String get entityLabel => 'Wording';

  @override
  String get entityMinSpeed => 'Min speed';

  @override
  String get entityMaxSpeed => 'Maximum speed';

  @override
  String get entityFullMatch => 'Whole match';

  @override
  String get entityFullMatchShort => 'Full match';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAgenda => 'Diary';

  @override
  String get navTeams => 'teams';

  @override
  String get navChat => 'Messaging';

  @override
  String get navSync => 'Synchronization';

  @override
  String get featureDiscoveryAgendaTitle => 'Discover the calendar';

  @override
  String get featureDiscoveryAgendaMessage =>
      'View upcoming matches and training sessions from the Agenda tab.';

  @override
  String get featureDiscoveryDiscover => 'Discover';

  @override
  String get featureDiscoveryDashboardTitle => 'Discover the dashboard';

  @override
  String get featureDiscoveryDashboardMessage =>
      'Track team activity, stats, and upcoming events from the Dashboard tab.';

  @override
  String get featureDiscoveryChatTitle => 'Discover messaging';

  @override
  String get featureDiscoveryChatMessage =>
      'Chat with your team from the Messaging tab.';

  @override
  String get featureDiscoverySyncTitle => 'Discover synchronization';

  @override
  String get featureDiscoverySyncMessage =>
      'Upload tracker data and manage devices from the Synchronization tab.';

  @override
  String get featureDiscoveryTeamsTitle => 'Discover teams';

  @override
  String get featureDiscoveryTeamsMessage =>
      'Manage rosters and team settings from the Teams section.';

  @override
  String get featureDiscoveryFieldsTitle => 'Discover field mapping';

  @override
  String get featureDiscoveryFieldsMessage =>
      'Localize pitches for tracker analysis from the Fields tab.';

  @override
  String get featureDiscoveryCompoTitle => 'Discover compositions';

  @override
  String get featureDiscoveryCompoMessage =>
      'Build and reuse lineups from the Composition tab.';

  @override
  String get featureDiscoveryMatchCompoTitle => 'Lineup tab';

  @override
  String get featureDiscoveryMatchCompoMessage =>
      'View and edit the match lineup in the Compo tab.';

  @override
  String get featureDiscoveryMatchTacticalTitle => 'Tactical setup tab';

  @override
  String get featureDiscoveryMatchTacticalMessage =>
      'Place players on the pitch in the Tactical setup tab.';

  @override
  String get featureDiscoveryMatchHighlightsTitle => 'Highlights tab';

  @override
  String get featureDiscoveryMatchHighlightsMessage =>
      'Review key moments in the Highlights tab.';

  @override
  String get featureDiscoveryMatchStatsTitle => 'Statistics tab';

  @override
  String get featureDiscoveryMatchStatsMessage =>
      'Explore tracker stats and heatmaps in the Statistics tab.';

  @override
  String get featureDiscoveryDismiss => 'Close';

  @override
  String get navFields => 'Land';

  @override
  String get navCompo => 'Composition';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navOverview => 'Overview';

  @override
  String get navNavigation => 'Navigation';

  @override
  String get tabCompo => 'Composition';

  @override
  String get tabTacticalSchema => 'Tactical setup';

  @override
  String get tabTacticalSchemaShort => 'Setup';

  @override
  String get matchTacticalSchemaConvocation => 'Call up players';

  @override
  String get matchTacticalSchemaConvocationHint =>
      'Optional — limits pitch selection to called-up players';

  @override
  String get matchTacticalSchemaSubstitutes => 'Substitutes';

  @override
  String get matchTacticalSchemaAddSubstitute => 'Add substitute';

  @override
  String get matchTacticalSchemaNoSubstitutes => 'No substitutes';

  @override
  String get matchTacticalSchemaPickPlayer => 'Choose a player';

  @override
  String get matchTacticalSchemaClearSlot => 'Remove from position';

  @override
  String get matchTacticalSchemaSaved => 'Tactical setup saved';

  @override
  String get matchTacticalSchemaEmpty => 'No tactical setup for this match';

  @override
  String get matchTacticalSchemaUnavailable =>
      'Tactical setup unavailable for this match';

  @override
  String get matchTacticalSchemaNoTeam =>
      'Unable to identify the team linked to this match.';

  @override
  String get tabHighlights => 'Highlights';

  @override
  String get tabStats => 'Statistics';

  @override
  String get tabStarters => 'Holders';

  @override
  String get tabSubstitutes => 'Substitutes';

  @override
  String get tabSynthesis => 'Summary';

  @override
  String get tabSpeedZones => 'Speed ​​zones';

  @override
  String get tabFieldZones => 'Field areas';

  @override
  String get tabHalfTimeComparison => 'Half-time comparison';

  @override
  String get tabDistanceTimeline => 'Timeline distance';

  @override
  String get tabHeatmap => 'Heat map';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodCustom => 'Period';

  @override
  String get periodPrep => 'Physical preparation';

  @override
  String get periodPostponed => 'Postponed';

  @override
  String periodMatchDay(String day) {
    return 'Matchday $day';
  }

  @override
  String periodSelectedWeek(String range) {
    return 'Selected week: $range';
  }

  @override
  String get periodUndefined => 'No defined period';

  @override
  String get hintSearchTeam => 'Find a team';

  @override
  String get hintSearchUser => 'Search for a user';

  @override
  String get hintSearchAddress => 'Search for an address or stadium';

  @override
  String get hintSelectSeason => 'Select a season';

  @override
  String get hintFieldName => 'Land name';

  @override
  String get hintCompoType => 'Type of composition';

  @override
  String get hintMetric => 'Indicator';

  @override
  String get hintDeviceIdExample => 'Example: tracker_001';

  @override
  String get hintSpeedZoneMaxEmpty => 'Leave blank for the last area';

  @override
  String get emptyNoData => 'No data available';

  @override
  String get emptyNoEvent => 'No events';

  @override
  String get emptyNoConversation => 'No conversation';

  @override
  String get emptyNoHighlights => 'No highlights';

  @override
  String get emptyNoCompo => 'No lineups have been found for this match.';

  @override
  String get emptyNoStarters => 'No holder specified.';

  @override
  String get emptyNoSubstitutes => 'No replacement indicated.';

  @override
  String get emptyNoTracker => 'No tracker selected';

  @override
  String get emptyNoTrackers => 'No trackers to display';

  @override
  String get emptyNoDeviceId => 'No deviceId available';

  @override
  String get emptyNoFileSelected => 'No files selected';

  @override
  String get emptyNoSpeedZone => 'No speed zone available.';

  @override
  String get emptyNoFieldZoneData => 'No terrain zone data available.';

  @override
  String get emptyNoDistanceTimeline => 'No distance timeline available.';

  @override
  String get emptyNoStatsForMatch => 'No data found for this match.';

  @override
  String get emptyNoStatsTeamAnalysis =>
      'No data found in TRACKER_TeamAnalysis for this match.';

  @override
  String get emptyNoPendingMatch => 'No pending matches.';

  @override
  String get emptyNoPendingTraining => 'No training with tracker pending.';

  @override
  String get emptyNoTeamFound => 'No teams found';

  @override
  String get emptyNoTeamAvailable => 'No teams available';

  @override
  String get emptyNoTeamForSeason => 'No teams found for this season.';

  @override
  String get emptyNoTeamForStats => 'No teams available to view statistics.';

  @override
  String get emptyNoPlayerForTeam => 'No players found for this team.';

  @override
  String get trainingPlayersRecap => 'Summary';

  @override
  String get trainingPlayersLoading => 'Loading players…';

  @override
  String get trainingPlayersClose => 'Close';

  @override
  String get presencePresent => 'Present';

  @override
  String get presenceInjured => 'Injured';

  @override
  String get presenceExcused => 'Excused';

  @override
  String get presenceAbsent => 'Absent';

  @override
  String get presenceLate => 'Late';

  @override
  String get presenceUnknown => '—';

  @override
  String get trainingPlayersAddPlayer => 'Add player';

  @override
  String get trainingPlayersAddPlayerTitle => 'Choose a player';

  @override
  String get trainingPlayersNoCandidates =>
      'All team players are already registered.';

  @override
  String get trainingPlayersChangePresence => 'Change attendance';

  @override
  String get trainingPlayersAssignTracker => 'Assign tracker';

  @override
  String get trainingPlayersNoTrackerAvailable => 'No tracker available.';

  @override
  String get trainingPlayersSelectTracker => 'Tracker';

  @override
  String get emptyNoStaffForTeam => 'No staff found for this team.';

  @override
  String get emptyNoPlayerSelected => 'No players selected.';

  @override
  String get emptyNoCurrentSeason => 'No current season available.';

  @override
  String get emptyNoUserFound => 'No users found';

  @override
  String get emptyNoUserAvailable => 'No users available';

  @override
  String get emptyNoConnectedDevice => 'No devices connected';

  @override
  String get emptyNoMatchToShow => 'No matches to display.';

  @override
  String get emptyNoCompoType => 'No composition type was found.';

  @override
  String get emptyNoAnalysis => 'No analysis available';

  @override
  String get emptyNoStats => 'No statistics available';

  @override
  String get emptyNoPlayersInStats =>
      'Statistics exist but no player score is available.';

  @override
  String get emptyHeatmap => 'Heatmap unavailable';

  @override
  String emptyNoSvgForPeriod(String period) {
    return 'No SVG image found for $period.';
  }

  @override
  String errorGeneric(String details) {
    return 'Error: $details';
  }

  @override
  String errorLoadingResource(String resource) {
    return 'Error loading $resource.';
  }

  @override
  String errorFilteringResource(String resource) {
    return 'Error filtering $resource.';
  }

  @override
  String errorComputingStats(String resource) {
    return 'Error computing $resource statistics.';
  }

  @override
  String errorSaving(String details) {
    return 'Error while saving: $details';
  }

  @override
  String errorLogout(String details) {
    return 'Error while signing out: $details';
  }

  @override
  String get errorStreamConnection => 'Unable to connect to Stream';

  @override
  String get sessionReplacedOnAnotherDevice =>
      'Your session was opened on another device. Please sign in again.';

  @override
  String get errorOpenAnalysis =>
      'Unable to open analysis: missing eventId or trackerId.';

  @override
  String get errorAgendaLoad => 'Unable to load calendar';

  @override
  String errorTeamParamsLoad(String details) {
    return 'Error loading settings: $details';
  }

  @override
  String get errorSaveTeamIdEmpty => 'Unable to save: empty teamId.';

  @override
  String errorDeleteFailed(String details) {
    return 'Error while deleting: $details';
  }

  @override
  String get errorLoadingTitle => 'Loading error';

  @override
  String get errorCompositionTitle => 'Composition error';

  @override
  String get errorPlayerTitle => 'Player error';

  @override
  String get errorPlayersTitle => 'Player error';

  @override
  String get errorTrackerTitle => 'Tracker error';

  @override
  String get errorMatchNotIdentified => 'Unidentified match';

  @override
  String get errorPlayerNotIdentified => 'Unidentified player';

  @override
  String get errorPlayerNotFound => 'Player not found';

  @override
  String get errorPlayerNotFoundInMatch => 'Player not found';

  @override
  String get errorStatsUnavailable => 'Statistics unavailable';

  @override
  String get errorNoStats => 'No statistics';

  @override
  String get errorNoStatsForPlayer => 'Unable to load player stats.';

  @override
  String get errorPlayerNotFoundMessage =>
      'Unable to find the selected player.';

  @override
  String get errorNoTrackerData => 'No tracker data found for this match.';

  @override
  String get errorNoTrackerStats =>
      'Unable to load tracker statistics without match ID.';

  @override
  String get errorNoTrackerAnalysis =>
      'Unable to find tracker data for this player.';

  @override
  String get errorMatchIdMissing => 'Missing match ID.';

  @override
  String errorChatCreate(String details) {
    return 'Error while creating: $details';
  }

  @override
  String get errorCompoTitle => 'Error';

  @override
  String get errorNoCompoTitle => 'No composition';

  @override
  String get successSettingsSaved => 'Settings saved successfully.';

  @override
  String get successGpsCopied => 'GPS copied.';

  @override
  String get successDefaultsLoaded => 'Default values ​​loaded into the form.';

  @override
  String successConversionDone(int count) {
    return 'Conversion complete - $count row(s) kept';
  }

  @override
  String get infoReadOnly => 'Read only';

  @override
  String get infoWebShellOnly => 'This shell is intended for Flutter Web only.';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get themeDarkModeLabel => 'Dark mode';

  @override
  String get themeEnableDarkModeTooltip => 'Enable dark mode';

  @override
  String get themeDisableDarkModeTooltip => 'Disable dark mode';

  @override
  String get infoParameters => 'Settings';

  @override
  String get infoUserNotConnected => 'User not logged in.';

  @override
  String get dialogCloseSyncTitle => 'Close synchronization';

  @override
  String get dialogCloseSyncMessage =>
      'Do you want to close the synchronization?';

  @override
  String get dialogDeleteCustomizationTitle => 'Remove personalization?';

  @override
  String get dialogDeleteAssignmentTitle => 'Delete assignment';

  @override
  String get dialogNewConversation => 'New conversation';

  @override
  String get dialogAsiConversionTitle => 'ASI to CSV conversion';

  @override
  String get syncMatchesToSync => 'Matches to sync';

  @override
  String get syncNoDeviceForTraining => 'No devices found for this workout';

  @override
  String get syncNoDeviceForMatch => 'No devices found for this match';

  @override
  String get statsWins => 'Victories';

  @override
  String get statsLosses => 'Defeats';

  @override
  String get statsDraws => 'Dummies';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsMaxSpeed => 'Maximum speed';

  @override
  String get statsAvgSpeed => 'Avg speed';

  @override
  String get statsWorkload => 'Workload';

  @override
  String get statsFatigue => 'Fatigue';

  @override
  String get statsDuration => 'Duration';

  @override
  String get statsSprints => 'Sprints';

  @override
  String get statsHighAccel => 'Acc. high';

  @override
  String get statsHighSpeedTime => 'High speed';

  @override
  String get statsHighSpeedTimeShort => 'High Speed ​​Time';

  @override
  String get statsMaxAccel => 'Acc. max';

  @override
  String get statsAxisSpeed => 'Speed ​​(km/h)';

  @override
  String get statsAxisTime => 'Time(s)';

  @override
  String get statsAxisAcceleration => 'Acceleration (m/s²)';

  @override
  String get statsScore => 'score';

  @override
  String statsPlayersCount(int count) {
    return '$count players';
  }

  @override
  String statsAvgWorkload(String value) {
    return 'Avg. load $value';
  }

  @override
  String statsAvgDistance(String value) {
    return 'Avg. distance $value';
  }

  @override
  String statsAvgMaxSpeed(String value) {
    return 'Avg. max speed $value';
  }

  @override
  String statsZScore(String sign, String value) {
    return 'zScore $sign$value';
  }

  @override
  String get statsMaxAccelSample => 'Max acceleration: 4m/s2';

  @override
  String get speedZoneWalk => 'Walk';

  @override
  String get speedZoneJogging => 'Jogging';

  @override
  String get speedZoneRun => 'Race';

  @override
  String get speedZoneHighIntensity => 'High intensity';

  @override
  String get speedZoneSprint => 'Sprint';

  @override
  String get highlightKickoff => 'Kick-off';

  @override
  String get highlightFullTime => 'End of the match';

  @override
  String get substitutionOut => 'Exit';

  @override
  String get substitutionIn => 'Entrance';

  @override
  String get teamParamsPerformanceTitle => 'Performance Settings';

  @override
  String get teamParamsSpeedSprints => 'Speed ​​& sprints';

  @override
  String get teamParamsIntensity => 'Intensity';

  @override
  String get teamParamsGpsTimeline => 'GPS / validation / timeline';

  @override
  String get teamParamsSpeedZones => 'Speed ​​zones';

  @override
  String get teamParamsMinOneZone => 'At least one area must be preserved.';

  @override
  String get teamParamsAddSpeedZone => 'Adds at least one speed zone.';

  @override
  String get teamParamsSprintThreshold => 'Sprint threshold (km/h)';

  @override
  String get teamParamsSprintMinAccel => 'Mini acceleration for sprint';

  @override
  String get teamParamsSprintMinDuration => 'Mini sprint duration';

  @override
  String get teamParamsSpeedMinDuration => 'Minimum speed duration validated';

  @override
  String get teamParamsHighAccelThreshold => 'Strong acceleration threshold';

  @override
  String get teamParamsHighAccelMinDuration =>
      'Mini duration strong acceleration';

  @override
  String get teamParamsMaxStepDistance => 'Max distance accepted per step';

  @override
  String get teamParamsMaxPlausibleSpeed => 'Maximum plausible speed';

  @override
  String get teamParamsMaxPlausibleAccel => 'Maximum plausible acceleration';

  @override
  String get teamParamsMinDeltaTime => 'Min time delta';

  @override
  String get teamParamsMaxDeltaTime => 'Maximum time delta';

  @override
  String get teamParamsSmoothingWindow => 'Smoothing window';

  @override
  String get teamParamsTimelineBucket => 'Bucket timeline';

  @override
  String teamMembersPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String teamMembersStaff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staff members',
      one: '1 staff member',
    );
    return '$_temp0';
  }

  @override
  String get fieldTooltipZoomIn => 'Enlarge the entire terrain';

  @override
  String get fieldTooltipZoomOut => 'Collapse all terrain';

  @override
  String get fieldTooltipLengthUp => 'Increase length';

  @override
  String get fieldTooltipLengthDown => 'Reduce length';

  @override
  String get fieldTooltipWidthUp => 'Increase width';

  @override
  String get fieldTooltipWidthDown => 'Reduce width';

  @override
  String get fieldTooltipRotateLeft => 'Turn left';

  @override
  String get fieldTooltipRotateRight => 'Turn right';

  @override
  String get fieldTooltipMap => 'Map';

  @override
  String get fieldTooltipSatellite => 'Satellite';

  @override
  String get fieldLocateCorners => 'Locate corners';

  @override
  String get fieldSnackbarLocationDisabled => 'Location tracking is disabled.';

  @override
  String get fieldSnackbarAllowLocation => 'Allows location to center the map.';

  @override
  String get fieldSnackbarGpsFailed => 'Unable to retrieve current position.';

  @override
  String get fieldSnackbarEnterAddress => 'Enter an address or stadium name.';

  @override
  String get fieldSnackbarMapNotReady => 'The map is not ready yet.';

  @override
  String get fieldSnackbarAddressNotFound => 'Address not found.';

  @override
  String fieldSnackbarAddressNotFoundWithStatus(String status) {
    return 'Address not found: $status';
  }

  @override
  String get fieldSnackbarGeocodingFailed =>
      'Unable to search for this address. Checks the key and the Geocoding API.';

  @override
  String get fieldSnackbarPlaceInMap =>
      'Places the terrain entirely in the map.';

  @override
  String get fieldSnackbarGpsConvertFailed =>
      'Unable to convert corners to GPS positions.';

  @override
  String get fieldHelpGestures =>
      'Field: drag to move • 2-finger zoom/rotate • trackpad: scroll zoom, Shift rotate, Option width, Shift+Option length';

  @override
  String get compoNotFoundTitle => 'Composition not specified';

  @override
  String get compoTypeEmptyTitle => 'No composition';

  @override
  String get matchStatsUnavailableTitle => 'Statistics unavailable';

  @override
  String get sensorNotFoundTitle => 'Sensor not found';

  @override
  String get sensorNotFoundMessage =>
      'There are no sensors associated with this player for this match.';

  @override
  String get matchHomeJersey => 'Home jersey';

  @override
  String get matchCartTitle => 'Your basket';

  @override
  String get matchCartOneItem => '1 item - €49.90';

  @override
  String get asiSelectFile => 'Please select an .asi file';

  @override
  String get asiEnterDeviceId => 'Please enter the deviceId';

  @override
  String get asiCannotReadFile => 'Unable to play selected file';

  @override
  String get asiFileMismatch => 'The file does not match the selected tracker';

  @override
  String get asiTrackerUnknown => 'Tracker not recognized';

  @override
  String asiFilePickError(String details) {
    return 'Error selecting file: $details';
  }

  @override
  String asiConversionError(String details) {
    return 'Error during conversion: $details';
  }

  @override
  String get asiAnalysisFailed => 'Analysis not possible';

  @override
  String get playerSynthesisTitle => 'Player summary';

  @override
  String get playerSynthesisTabTitle => 'Summary';

  @override
  String teamsListCount(int count) {
    return '$count team(s)';
  }

  @override
  String teamsListCountFiltered(int filtered, int total) {
    return '$filtered / $total';
  }

  @override
  String get teamsListNoResults => 'No teams found';

  @override
  String get teamsListNoTeams => 'No teams available';

  @override
  String get navHome => 'Welcome';

  @override
  String get myTeams => 'My teams';

  @override
  String get syncTrainingsToSync => 'Workouts to sync';

  @override
  String get chatSelectConversation => 'Select a conversation';

  @override
  String get chatStartNewHint => 'Press \"New\" to start a chat.';

  @override
  String get chatTryAnotherName => 'Try another name.';

  @override
  String get chatUsersAppearHere => 'Other users will appear here.';

  @override
  String get matchDetailTitle => 'Match details';

  @override
  String get matchDetailVenueTitle => 'Match venue';

  @override
  String get matchDetailTrackerKitTitle => 'Sélection du kit';

  @override
  String get matchDetailTrackerKitLabel => 'Trackers';

  @override
  String get matchDetailTrackerKitComingSoon => 'À venir';

  @override
  String playerAgeYears(int age) {
    return '$age years old';
  }

  @override
  String get playerAgeUnknown => 'Age not provided';

  @override
  String get dateUndefined => 'Date not defined';

  @override
  String matchDateTimeAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get entityComposition => 'Composition';

  @override
  String get entityDetails => 'Details';

  @override
  String get entityHeatmap => 'Heatmap';

  @override
  String get entityPeriods => 'Periods';

  @override
  String get tabHighlightsShort => 'Time';

  @override
  String get emptyNoHighlightsMessage =>
      'Goals, cards and substitutions will appear here.';

  @override
  String get highlightTypeGoal => 'Aim';

  @override
  String get highlightTypeSubstitution => 'Change';

  @override
  String get highlightTypeYellowCard => 'Yellow card';

  @override
  String get highlightTypeRedCard => 'Red card';

  @override
  String get highlightTypeOwnGoal => 'Own goal';

  @override
  String get highlightTypePenalty => 'Penalty';

  @override
  String get highlightTypeGeneric => 'Highlight';

  @override
  String highlightSubstitutionOut(String player) {
    return '$player off';
  }

  @override
  String highlightSubstitutionIn(String incoming, String outgoing) {
    return '$incoming replaces $outgoing';
  }

  @override
  String get errorNoPlayersTitle => 'No players';

  @override
  String get matchTrackerDataAvailable => 'Tracker data is available.';

  @override
  String get matchTrackerDataPending => 'The tracker data is not yet imported.';

  @override
  String get errorPlayerNoTrackerMatch =>
      'This player has no tracker data for this match.';

  @override
  String get trackerSyncTitle => 'Sensor Synchronization';

  @override
  String get trackerAvailableSensors => 'Sensors available';

  @override
  String trackerCount(int count) {
    return '$count tracker(s)';
  }

  @override
  String get trackerAlreadySyncedTitle => 'Synchronization already done';

  @override
  String get trackerAlreadySyncedMessage =>
      'The sensor has already been synced for this session.';

  @override
  String get trackerStatusSelected => 'Selected';

  @override
  String get trackerStatusSynced => 'Synchronized';

  @override
  String get trackerStatusOpen => 'Open';

  @override
  String get trackerSelectForActions =>
      'Selects a tracker to display login, download, and erase actions.';

  @override
  String get trackerSelectedLabel => 'Tracker selected';

  @override
  String get trackerLogsPlaceholder => 'The logs will appear here.';

  @override
  String get trackerNoDataOnDevice => 'No data on this sensor.';

  @override
  String get trackerNoDataOnDeviceTitle =>
      'Sensor connected — no session to import';

  @override
  String get trackerNoDataOnDeviceDetails =>
      'The sensor reported 0 bytes of session data (not a connection error). No activity recorded on the pod, or data already erased. Record a session on the Inspirit, then click Download again.';

  @override
  String get trackerDownloadFailedTitle => 'Download failed';

  @override
  String get trackerDownloadBusyHint =>
      'Make sure no other instance of Grinta is open.';

  @override
  String get trackerDownloadPrepareSession =>
      'Preparing USB before download (same as Disconnect then Connect)…';

  @override
  String get uploadTrackerLoading => 'Loading...';

  @override
  String get uploadTrackerDownloadData => 'Download data';

  @override
  String get syncFieldGeolocationPromptTitle => 'Geolocate the field?';

  @override
  String get syncFieldGeolocationPromptMessage =>
      'The field GPS coordinates are not set. Would you like to define them before downloading tracker data?';

  @override
  String get trackerUsbAuthorizeHint =>
      'No Inspirit authorized for this site. A Chrome dialog will open: click your Inspirit device, then \"Connect\" — do not close the dialog.';

  @override
  String get trackerUsbPopupCancelled =>
      'Chrome dialog closed or no device chosen. Plug in the tracker, click \"Connect\" again, and select it in the list.';

  @override
  String get trackerUsbPhysicalReconnect =>
      'USB session expired (cable unplugged or sensor reset). Replug the tracker if needed, then click Connect again — Chrome may ask you to select it again.';

  @override
  String trackerDeviceName(String name) {
    return 'Device: $name';
  }

  @override
  String get asiImportTitle => 'Import an .asi file';

  @override
  String get asiImportSubtitle =>
      'Select a file, check the deviceId, then start the conversion.';

  @override
  String get asiFileSelectedLabel => 'Selected file';

  @override
  String get asiImportFileHeader => 'Import ASI file';

  @override
  String get actionConvertToCsv => 'Convert to CSV';

  @override
  String get asiConverting => 'Conversion in progress...';

  @override
  String get asiPeriodsOne => '1 period transmitted';

  @override
  String asiPeriodsMany(int count) {
    return '$count period(s) sent - the first 2 will be used for halves';
  }

  @override
  String get statsUnitKm => 'km';

  @override
  String get statsUnitKmh => 'km/h';

  @override
  String get statsUnitCount => 'nb';

  @override
  String get statsUnitSeconds => 'dry';

  @override
  String get statsUnitMps2 => 'm/s²';

  @override
  String get loadingSession => 'Loading session...';

  @override
  String get loadingStats => 'Loading statistics...';

  @override
  String get dashboardMyManagedTeams => 'My managed teams';

  @override
  String get dashboardMatchListTitle => 'List of matches';

  @override
  String periodCustomRange(String start, String end) {
    return 'from $start to $end';
  }

  @override
  String statsPresenceRate(String value) {
    return 'Attendance rate: ($value) %';
  }

  @override
  String get statsDoneSingular => 'realized';

  @override
  String get statsDonePlural => 'made';

  @override
  String get statsPlannedSingular => 'planned';

  @override
  String get statsPlannedPlural => 'planned';

  @override
  String get actionDayPrevious => 'Previous day';

  @override
  String get actionDayNext => 'Next day';

  @override
  String get actionMonthPrevious => 'Previous month';

  @override
  String get actionMonthNext => 'Next month';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaving => 'Registration...';

  @override
  String periodLoaded(String range) {
    return 'Period loaded: $range';
  }

  @override
  String get agendaLegend => 'Legend';

  @override
  String agendaOverviewEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryTrainings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trainings',
      one: '1 training',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryPrepas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prep sessions',
      one: '1 prep session',
    );
    return '$_temp0';
  }

  @override
  String get agendaTrackerStatsTitle => 'Tracker statistics';

  @override
  String get teamDetailBackToTeams => 'Back to the teams';

  @override
  String teamDetailAverageAge(String age) {
    return 'Average age: $age years';
  }

  @override
  String get teamDetailConfirmDeleteTitle => 'Confirm deletion';

  @override
  String teamDetailConfirmRemoveStaff(String playerName) {
    return 'Remove staff member $playerName?';
  }

  @override
  String teamDetailConfirmRemovePlayerTeam(String playerName) {
    return 'Remove $playerName from the team?';
  }

  @override
  String teamDetailPlayerRemoved(String playerName) {
    return '$playerName has been removed.';
  }

  @override
  String teamDetailPlayerTeamRemoved(String playerName) {
    return '$playerName has been removed from the team.';
  }

  @override
  String get teamDetailColumnAge => 'Age';

  @override
  String get teamDetailColumnPosition => 'Position';

  @override
  String get teamDetailColumnHeight => 'Height';

  @override
  String get teamDetailColumnWeight => 'Weight';

  @override
  String teamDetailHeightCm(int value) {
    return '$value cm';
  }

  @override
  String teamDetailWeightKg(int value) {
    return '$value kg';
  }

  @override
  String teamDetailConfirmRemoveTracker(String trackerName) {
    return 'Remove tracker assignment for \"$trackerName\"?';
  }

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleExecutive => 'Executive';

  @override
  String get positionEducator => 'Educator/Coach';

  @override
  String get positionExecutive => 'Executive';

  @override
  String get positionGoalkeeper => 'Goalkeeper';

  @override
  String get positionDefender => 'Defender';

  @override
  String get positionMidfielder => 'Midfielder';

  @override
  String get positionForward => 'Forward';

  @override
  String get teamParamsCustomThresholds => 'Custom thresholds';

  @override
  String get teamParamsDefaultThresholds => 'Default thresholds';

  @override
  String get teamParamsBackToTeam => 'Back to the team';

  @override
  String get teamParamsDeleteCustomizationBody =>
      'The specific settings for this team will be deleted. The team will then use the default settings.';

  @override
  String get teamParamsCustomizationRemoved =>
      'Personalization removed. The default settings will be used.';

  @override
  String teamParamsZoneMaxGreaterThanMin(String label) {
    return 'Zone \"$label\" must have a max bound higher than the min bound.';
  }

  @override
  String get teamParamsOnlyLastZoneEmptyMax =>
      'Only the last zone can have an empty max terminal.';

  @override
  String teamParamsZonesOverlap(String zoneA, String zoneB) {
    return 'Zones \"$zoneA\" and \"$zoneB\" overlap.';
  }

  @override
  String get teamParamsCustomizeZonesHint =>
      'You can freely customize the zones used to calculate the time spent in each zone.';

  @override
  String get teamParamsZonesReadOnly =>
      'Consultation only: speed zones cannot be modified.';

  @override
  String get teamParamsInvalidInteger => 'Invalid integer value';

  @override
  String get teamParamsInvalidNumber => 'Invalid numeric value';

  @override
  String teamParamsZoneTitle(int index) {
    return 'Zone $index';
  }

  @override
  String get hintRequiredField => 'Required field';

  @override
  String get fieldSnackbarGoogleMapsKeyMissing =>
      'Missing Google Maps key for address search.';

  @override
  String get fieldMapModeHelp => 'Map mode: moves or zooms the map';

  @override
  String get fieldSideLeft => 'Left side';

  @override
  String get fieldSideRight => 'Right side';

  @override
  String get fieldEstimatedAddress => 'Estimated address';

  @override
  String get fieldAddressUnavailable =>
      'Postal address unavailable for this position.';

  @override
  String get fieldGpsPositionsTitle => 'GPS terrain positions';

  @override
  String get fieldAverageLength => 'Average length';

  @override
  String get fieldAverageWidth => 'Average width';

  @override
  String get trackerParamDefault => 'Default setting';

  @override
  String trackerParamTeam(String teamId) {
    return 'Team param $teamId';
  }

  @override
  String get halfFirst => '1st half';

  @override
  String get halfSecond => '2nd half';

  @override
  String halfNth(int index) {
    return '${index}th half';
  }

  @override
  String get halfFirstShort => '1st';

  @override
  String get halfSecondShort => '2nd';

  @override
  String get halfMatchShort => 'Match';

  @override
  String get tabSpeedZonesShort => 'Speed';

  @override
  String get fieldZoneAttackLeftShort => 'Att. LEFT';

  @override
  String get fieldZoneAttackRightShort => 'Att. RIGHT';

  @override
  String get fieldZoneMidLeftShort => 'Mil. LEFT';

  @override
  String get fieldZoneMidRightShort => 'Mil. RIGHT';

  @override
  String get fieldZoneDefenseLeftShort => 'Def. LEFT';

  @override
  String get fieldZoneDefenseRightShort => 'Def. RIGHT';

  @override
  String get fieldZoneAttackLeft => 'Left attack';

  @override
  String get fieldZoneAttackRight => 'Right attack';

  @override
  String get fieldZoneMidLeft => 'Left midfielder';

  @override
  String get fieldZoneMidRight => 'Right middle';

  @override
  String get fieldZoneDefenseLeft => 'Left defense';

  @override
  String get fieldZoneDefenseRight => 'Right defense';

  @override
  String get halfFirstUnavailable => '1st half unavailable';

  @override
  String get halfSecondUnavailable => '2nd half unavailable';

  @override
  String asiHeatmapPointCount(int count, String period) {
    return '$count point(s) - $period';
  }

  @override
  String metricsEvolutionTitle(String metric) {
    return 'Trend - $metric';
  }

  @override
  String trainingOnDate(String date) {
    return 'Training on $date';
  }
}
