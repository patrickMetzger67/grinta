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
  String get noAccountYet => 'Don\'t have an account?';

  @override
  String get createOneLink => 'Create one';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get passwordRequirements =>
      'Password must be at least 8 characters and include an uppercase letter, a digit, and a special character.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String get or => 'Or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithMeta => 'Continue with Meta';

  @override
  String get hasATeamCode => 'I have a team code';

  @override
  String get hasInvitationCodeQuestion => 'Do you have an invitation code?';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get invitationCodeHint => 'Enter your code';

  @override
  String get invitationNotFound => 'Invitation code not found';

  @override
  String get invitationNotFoundContinuePrompt =>
      'This code does not exist. Would you like to continue by creating your player profile?';

  @override
  String get invitationAlreadyUsed =>
      'This invitation code has already been used';

  @override
  String invitationSentBy(String firstName, String lastName) {
    return 'The invitation was sent to you by $firstName $lastName';
  }

  @override
  String get signupWithoutInvitationComingSoon => 'Feature coming soon';

  @override
  String get emailAlreadyInUse =>
      'An account already exists with this email address';

  @override
  String get invitationCodeRequired =>
      'Please enter and validate an invitation code';

  @override
  String get invitationChoiceRequired =>
      'Please indicate whether you have an invitation code';

  @override
  String get memberProfileTitle => 'Your profile';

  @override
  String get memberFirstName => 'First name';

  @override
  String get memberLastName => 'Last name';

  @override
  String get memberEmail => 'Email';

  @override
  String get memberEmailOptional => 'Email (optional)';

  @override
  String get memberPhone => 'Phone';

  @override
  String get memberPhoneOptional => 'Phone (optional)';

  @override
  String get memberEmailInvalid => 'Please enter a valid email address';

  @override
  String get memberPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get memberPhoneRequired =>
      'Phone number is required for player invitations';

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Your coach invites you to join $appName. Your code: $code.\niPhone: $appleStoreUrl\nAndroid: $googlePlayUrl';
  }

  @override
  String get memberInvitationSmsFailed =>
      'Member added, but the invitation SMS could not be sent.';

  @override
  String get memberAddedToTeamNotificationTitle => 'Team update';

  @override
  String memberAddedToTeamNotificationBody(String teamName) {
    return 'Your coach added you to $teamName.';
  }

  @override
  String get invitationAccepted => 'Invitation accepted';

  @override
  String get invitationPending => 'Invitation pending';

  @override
  String get memberAppAccountLinked => 'App account linked';

  @override
  String get memberBirthDate => 'Date of birth';

  @override
  String get memberBirthDateOptional => 'Date of birth (optional)';

  @override
  String get memberBirthPlace => 'Place of birth';

  @override
  String get memberBirthPlaceOptional => 'Place of birth (optional)';

  @override
  String get memberNationality => 'Nationality';

  @override
  String get memberNationalityHint => 'Select a nationality';

  @override
  String get memberNationalitySearch => 'Search nationality';

  @override
  String get memberPositions => 'Positions';

  @override
  String get memberPositionsHint => 'Select one or more positions (optional)';

  @override
  String get memberFirstNameRequired => 'First name is required';

  @override
  String get memberLastNameRequired => 'Last name is required';

  @override
  String get memberBirthPlaceRequired => 'Place of birth is required';

  @override
  String get memberNationalityRequired => 'Nationality is required';

  @override
  String get memberContactRequired =>
      'Please provide at least an email address or a phone number';

  @override
  String get memberProfileIncomplete => 'Please complete your profile';

  @override
  String get memberProfileSubmit => 'Create my profile';

  @override
  String get memberProfileUpdateSuccess => 'Profile updated';

  @override
  String memberProfileUpdateError(String error) {
    return 'Could not update profile: $error';
  }

  @override
  String get memberProfileChangePhoto => 'Change photo';

  @override
  String get memberProfileTakePhoto => 'Take photo';

  @override
  String get memberProfileChooseFromGallery => 'Choose from gallery';

  @override
  String memberProfilePhotoUploadError(String error) {
    return 'Could not update photo: $error';
  }

  @override
  String get errorEditProfileUnavailable => 'No profile available to edit';

  @override
  String get createTeamPromptQuestion => 'Would you like to create a team?';

  @override
  String get createTeamPromptLater => 'Later';

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
  String get actionEditProfile => 'Edit profile';

  @override
  String get settingsMyUnavailabilities => 'My unavailabilities';

  @override
  String get myUnavailabilitiesNoPlayer =>
      'No player profile linked to your account.';

  @override
  String get myUnavailabilitiesNoSeason =>
      'No season selected. Choose a season from the account menu.';

  @override
  String get actionCreateNewProfile => 'Create a new profile';

  @override
  String get actionLogout => 'Disconnect';

  @override
  String get actionLogoutConfirmTitle => 'Disconnect';

  @override
  String get actionLogoutConfirmMessage => 'Do you really want to log out?';

  @override
  String get actionCreateTeam => 'Create a team';

  @override
  String get teamCreationAttachClubQuestion =>
      'Would you like to attach this team to a club?';

  @override
  String get teamCreationSelectClub => 'Select a club';

  @override
  String get teamCreationClubRequired => 'Please select a club';

  @override
  String get teamCreationSelectClubTeams => 'Select club teams';

  @override
  String get teamCreationNoClubTeams => 'No engaged teams';

  @override
  String teamCreationSelectedClubTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams selected',
      one: '1 team selected',
      zero: 'No teams selected',
    );
    return '$_temp0';
  }

  @override
  String teamCreationClubTeamCompetitionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count competitions',
      one: '1 competition',
    );
    return '$_temp0';
  }

  @override
  String get teamCreationSoccerType => 'Football type';

  @override
  String get teamCreationNoClubWarningTitle => 'Warning';

  @override
  String get teamCreationNoClubWarning =>
      'This team is not linked to a club or competition. In that case, calendar and results are not fetched automatically.';

  @override
  String equipeCompetitionsSheetTitle(String teamName) {
    return 'Competitions — $teamName';
  }

  @override
  String fffCompetitionPhaseLabel(int phase) {
    return 'Phase $phase';
  }

  @override
  String fffCompetitionGroupeLabel(int groupe) {
    return 'Group $groupe';
  }

  @override
  String get hintSearchClub => 'Search for a club';

  @override
  String get hintSearchClubTeam => 'Search for a team';

  @override
  String get actionAddPlayer => 'Add a player';

  @override
  String get actionCreatePlayer => 'Create a player';

  @override
  String get actionEditPlayer => 'Edit player';

  @override
  String get actionEditStaff => 'Edit staff';

  @override
  String get addPlayerPositionRequired => 'Please select a position';

  @override
  String get addPlayerHeightCmOptional => 'Height (cm, optional)';

  @override
  String get addPlayerWeightKgOptional => 'Weight (kg, optional)';

  @override
  String get addPlayerHeightInvalid => 'Enter a height between 50 and 250 cm';

  @override
  String get addPlayerWeightInvalid => 'Enter a weight between 20 and 200 kg';

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
  String get navNotifications => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage => 'You have no unread notifications.';

  @override
  String get notificationsMarkAsRead => 'Mark as read';

  @override
  String get notificationsMarkAsReadError =>
      'Could not mark notification as read.';

  @override
  String get notificationsConvocationMatchDetails => 'Match details';

  @override
  String get notificationsConvocationPresent => 'I\'ll be there';

  @override
  String get notificationsConvocationAbsent => 'Not attending';

  @override
  String get notificationsConvocationAbsentDialogTitle => 'Reason for absence';

  @override
  String get notificationsConvocationAbsentMessageHint =>
      'Explain why you cannot attend';

  @override
  String get notificationsConvocationAbsentConfirm => 'Confirm';

  @override
  String get notificationsConvocationAbsentMessageRequired =>
      'Please enter a message.';

  @override
  String get notificationsConvocationActionError =>
      'Could not respond to the call-up.';

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
  String get navSettings => 'Settings';

  @override
  String get tabCompo => 'Composition';

  @override
  String get tabConvocations => 'Call-ups';

  @override
  String get tabConvocationsShort => 'Calls';

  @override
  String get matchConvocationsSaved => 'Call-ups saved';

  @override
  String get matchConvocationsUnavailable =>
      'Call-ups unavailable for this match';

  @override
  String get matchPlayerUnavailableOnMatchDate => 'Unavailable on match date';

  @override
  String get matchPlayerCannotConvokeUnavailable =>
      'This player is unavailable on the match date and cannot be called up.';

  @override
  String get matchConvocationsStatusPresent => 'Confirmed';

  @override
  String get matchConvocationsStatusPending => 'Awaiting response';

  @override
  String get matchConvocationsSendAction => 'Send call-ups';

  @override
  String get matchConvocationsSendTitle => 'Send call-ups';

  @override
  String matchConvocationsSendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players called up',
      one: '1 player called up',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendMessage => 'Message';

  @override
  String get matchConvocationsSendMessageHint =>
      'Additional information for players';

  @override
  String get matchConvocationsSendMessageRequired => 'Enter a message';

  @override
  String get matchConvocationsSendTime => 'Call-up time';

  @override
  String get matchConvocationsSendAddress => 'Call-up address';

  @override
  String get matchConvocationsSendAddressHint => 'Meeting point';

  @override
  String get matchConvocationsSendAddressRequired => 'Enter an address';

  @override
  String get matchConvocationsSendSubmit => 'Send';

  @override
  String matchConvocationsSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count call-ups sent',
      one: '1 call-up sent',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoAccount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players without a linked account',
      one: '1 player without a linked account',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players without a push notification',
      one: '1 player without a push notification',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendNoRecipients =>
      'No called-up player has a linked Grinta account.';

  @override
  String matchConvocationsSendError(String error) {
    return 'Send failed: $error';
  }

  @override
  String get matchConvocationsSendErrorAuth => 'Sign in to send call-ups.';

  @override
  String matchConvocationsSendDateTimeValue(String date, String time) {
    return '$date at $time';
  }

  @override
  String matchConvocationsSendMatchLine(String opponent) {
    return 'Match: $opponent';
  }

  @override
  String matchConvocationsSendTimeLine(String time) {
    return 'Time: $time';
  }

  @override
  String matchConvocationsSendAddressLine(String address) {
    return 'Address: $address';
  }

  @override
  String matchConvocationNotificationTitle(String opponent) {
    return 'Call-up · $opponent';
  }

  @override
  String matchConvocationFeedbackNotificationTitle(String opponent) {
    return 'Call-up response · $opponent';
  }

  @override
  String matchConvocationNotificationBody(String opponent, String time) {
    return '$opponent · Meet at $time';
  }

  @override
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message) {
    return '$opponent · Meet at $time · $message';
  }

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
  String get matchTacticalSchemaJerseyNumber => 'Jersey number';

  @override
  String get matchTacticalSchemaPlayerAssignment => 'Player assignment';

  @override
  String get matchTacticalSchemaJerseyNumberRequired =>
      'Enter a jersey number (1 to 99).';

  @override
  String get matchTacticalSchemaNoJerseyNumberAvailable =>
      'No jersey numbers available (all numbers from 1 to 99 are already assigned).';

  @override
  String get matchTacticalSchemaRemoveFromCompo => 'Remove from lineup?';

  @override
  String get matchTacticalSchemaRemoveFromCompoMessage =>
      'This player will be removed from the tactical setup (position and substitutes).';

  @override
  String get matchTacticalSchemaRemoveFromCompoConfirm => 'Remove';

  @override
  String get matchTacticalSchemaSensorRequired => 'Select an available sensor.';

  @override
  String get matchTacticalSchemaNoPlayerAvailable =>
      'No players available — everyone eligible is already on the lineup.';

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
  String get hintSearchMember => 'Search for a member';

  @override
  String get memberSearchPrompt => 'Type a first or last name to search';

  @override
  String get memberAlreadyOnTeamRoster =>
      'This member is already on the team roster';

  @override
  String get memberAlreadyPlayer =>
      'This member is already on the team as a player';

  @override
  String get memberAlreadyStaff =>
      'This member is already on the team as staff';

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
  String get matchDetailTrackerKitTitle => 'Kit selection';

  @override
  String get matchDetailTrackerKitLabel => 'Trackers';

  @override
  String get matchDetailTrackerKitComingSoon => 'Coming soon';

  @override
  String get matchDetailTrackerKitWithTracker => 'With tracker';

  @override
  String get matchDetailTrackerKitWithoutTracker => 'Without tracker';

  @override
  String get matchDetailTrackerKitSelectLabel => 'Kit';

  @override
  String get matchDetailTrackerKitNoOwners =>
      'No kit configured for this team.';

  @override
  String get matchDetailTrackerKitSignInRequired => 'Sign in to select a kit.';

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
  String get matchHighlightsSourceFmi => 'FMI highlights';

  @override
  String get matchHighlightsSourceGrinta => 'Grinta highlights';

  @override
  String get matchHighlightsGrintaPlaceholderMessage =>
      'To be detailed together later.';

  @override
  String get matchGrintaHighlightsAddAction => 'Add highlight';

  @override
  String get matchGrintaHighlightsPickTypeTitle => 'Choose highlight type';

  @override
  String get matchGrintaHighlightsPickTimeEventTitle => 'Choose time event';

  @override
  String get matchGrintaHighlightsEmptyMessage =>
      'Start with kick-off using the + button.';

  @override
  String get matchGrintaHighlightsDetailsComingSoon =>
      'Details for this highlight are coming soon.';

  @override
  String get matchGrintaHighlightsActionTimeEvent => 'Time event';

  @override
  String get matchGrintaHighlightsAllTimeEventsRecorded =>
      'All time events have already been recorded for this match.';

  @override
  String get matchGrintaHighlightDeleteConfirmTitle => 'Delete highlight?';

  @override
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel) {
    return 'Are you sure you want to delete \"$highlightLabel\"? This action is permanent.';
  }

  @override
  String get matchGrintaHighlightDeleted => 'Highlight deleted';

  @override
  String get matchGoalAddTitle => 'Record a goal';

  @override
  String get matchGoalPickTeamTitle => 'Which team scored?';

  @override
  String get matchGoalPickScorerTitle => 'Scorer';

  @override
  String get matchGoalPickAssisterTitle => 'Assister (optional)';

  @override
  String get matchGoalNoAssister => 'No assister';

  @override
  String get matchGoalOpponentJerseyTitle => 'Scorer jersey number (optional)';

  @override
  String get matchGoalOpponentJerseyHint => 'e.g. 10';

  @override
  String get matchGoalScorerRequired => 'Select a scorer.';

  @override
  String get matchGoalInvalidJerseyNumber => 'Enter a valid jersey number.';

  @override
  String get matchGoalMinuteTitle => 'Minute';

  @override
  String get matchGoalMinuteHint => 'e.g. 67';

  @override
  String get matchGoalInvalidMinute => 'Enter a minute of at least 1.';

  @override
  String get matchGoalSelectScorer => 'Select a scorer';

  @override
  String get matchGoalSelectAssister => 'Select an assister';

  @override
  String get matchCardYellowAddTitle => 'Record a yellow card';

  @override
  String get matchCardRedAddTitle => 'Record a red card';

  @override
  String get matchCardPickTeamTitle => 'Which team received the card?';

  @override
  String get matchCardPickPlayerTitle => 'Player';

  @override
  String get matchCardSelectPlayer => 'Select a player';

  @override
  String get matchCardPlayerRequired => 'Select a player.';

  @override
  String get matchCardOpponentJerseyTitle => 'Player jersey number (optional)';

  @override
  String get matchCardOpponentJerseyHint => 'e.g. 10';

  @override
  String get matchSubstitutionAddTitle => 'Record a substitution';

  @override
  String get matchSubstitutionPickTeamTitle => 'Which team made the change?';

  @override
  String get matchSubstitutionPickOutgoingTitle => 'Player off';

  @override
  String get matchSubstitutionPickIncomingTitle => 'Player on';

  @override
  String get matchSubstitutionSelectOutgoing => 'Select player off';

  @override
  String get matchSubstitutionSelectIncoming => 'Select player on';

  @override
  String get matchSubstitutionOutgoingRequired =>
      'Select the player coming off.';

  @override
  String get matchSubstitutionIncomingRequired =>
      'Select the player coming on.';

  @override
  String get matchSubstitutionSamePlayerError =>
      'The two players must be different.';

  @override
  String get matchSubstitutionOpponentOutgoingJerseyTitle =>
      'Player off jersey number (optional)';

  @override
  String get matchSubstitutionOpponentIncomingJerseyTitle =>
      'Player on jersey number (optional)';

  @override
  String highlightGoalScored(String scorer) {
    return 'Goal — $scorer';
  }

  @override
  String get highlightTimeHalfTime => 'Half-time';

  @override
  String get highlightTimeSecondHalf => 'Second half';

  @override
  String get highlightTimeStartExtraTime => 'Extra time';

  @override
  String get highlightTypeGoal => 'Aim';

  @override
  String get highlightTypeSubstitution => 'Change';

  @override
  String get highlightTypeYellowCard => 'Yellow card';

  @override
  String get highlightTypeRedCard => 'Red card';

  @override
  String highlightYellowCardShown(String player) {
    return 'Yellow card — $player';
  }

  @override
  String highlightRedCardShown(String player) {
    return 'Red card — $player';
  }

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
  String get agendaAddEventTitle => 'Create';

  @override
  String get agendaAddEventMatch => 'A match';

  @override
  String get agendaAddEventTraining => 'A training session';

  @override
  String get agendaAddEventPersonalSport => 'A personal sports activity';

  @override
  String get agendaAddEventPersonalSportHint => 'Running, preparation, …';

  @override
  String get agendaAddEventNonSport => 'A non-sporting event / activity';

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
  String get teamDetailColumnApp => 'App';

  @override
  String get teamDetailPlayerDetailsTitle => 'Player details';

  @override
  String get teamDetailGrantManager => 'Grant manager rights';

  @override
  String get teamDetailRevokeManager => 'Revoke manager rights';

  @override
  String get teamDetailRemoveFromTeam => 'Remove';

  @override
  String get teamDetailTrackerOwnersTitle => 'GPS trackers';

  @override
  String get teamDetailTrackerOwnersEmpty =>
      'No tracker kit available for your account.';

  @override
  String teamDetailTrackerOwnerType(String type) {
    return 'Type: $type';
  }

  @override
  String get teamDetailTrackerOwnersSaved => 'Tracker kits updated.';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleExecutive => 'Executive';

  @override
  String get grintaStaffRoleEducator => 'Coach / Educator';

  @override
  String get grintaStaffRoleMedical => 'Medical';

  @override
  String get grintaStaffRoleExecutive => 'Executive';

  @override
  String get addStaffRoleLabel => 'Role';

  @override
  String get addStaffRoleHint => 'Select a role';

  @override
  String get addStaffRoleRequired => 'Please select a role';

  @override
  String get positionEducator => 'Educator/Coach';

  @override
  String get positionExecutive => 'Manager/Executive';

  @override
  String get positionGoalkeeper => 'Goalkeeper';

  @override
  String get positionCenterBack => 'Center back';

  @override
  String get positionCenterBackLeft => 'Left center back';

  @override
  String get positionCenterBackRight => 'Right center back';

  @override
  String get positionLeftDefender => 'Left defender';

  @override
  String get positionRightDefender => 'Right defender';

  @override
  String get positionLeftBack => 'Left back';

  @override
  String get positionRightBack => 'Right back';

  @override
  String get positionLeftPiston => 'Left wing-back';

  @override
  String get positionRightPiston => 'Right wing-back';

  @override
  String get positionDefensiveMidfielder => 'Defensive midfielder';

  @override
  String get positionCentralMidfielder => 'Central midfielder';

  @override
  String get positionBoxToBoxMidfielder => 'Box-to-box midfielder';

  @override
  String get positionLeftMidfielder => 'Left midfielder';

  @override
  String get positionRightMidfielder => 'Right midfielder';

  @override
  String get positionAttackingMidfielder => 'Attacking midfielder';

  @override
  String get positionPlaymaker => 'Playmaker';

  @override
  String get positionLeftWinger => 'Left winger';

  @override
  String get positionRightWinger => 'Right winger';

  @override
  String get positionSecondStriker => 'Second striker';

  @override
  String get positionCenterForward => 'Center forward';

  @override
  String get positionStriker => 'Striker';

  @override
  String get positionAttacker => 'Forward';

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

  @override
  String get subscriptionPaywallTitle => 'Upgrade to Grinta Premium';

  @override
  String get subscriptionPaywallSubtitle =>
      'Unlock all features for tracking your teams and your players.';

  @override
  String get subscriptionPaywallLater => 'Later';

  @override
  String get subscriptionOfferingCoach => 'Coach';

  @override
  String get subscriptionOfferingPlayer => 'Player';

  @override
  String get subscriptionTierCoachBasic => 'Coach Basic';

  @override
  String get subscriptionTierCoachBasicDesc =>
      'Essential team management: calendar, roster, and basic stats.';

  @override
  String get subscriptionTierCoachElite => 'Coach Elite';

  @override
  String get subscriptionTierCoachEliteDesc =>
      'Advanced analytics, tactical lineups, and full coach tools.';

  @override
  String get subscriptionTierCoachPro => 'Coach Pro';

  @override
  String get subscriptionTierCoachProDesc =>
      'Everything in Elite, plus GPS tracker, heatmaps, and pro exports.';

  @override
  String get subscriptionTierPlayer => 'Player';

  @override
  String get subscriptionTierPlayerDesc =>
      'Track your performance, personal stats, and progress.';

  @override
  String get subscriptionPerMonth => '/month';

  @override
  String get subscriptionPerYear => '/year';

  @override
  String get subscriptionBillingMonthly => 'Monthly';

  @override
  String get subscriptionBillingYearly => 'Yearly';

  @override
  String get subscriptionAnnualSavings => '2 months free';

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String get subscriptionTierActive => 'Active subscription';

  @override
  String get subscriptionRestorePurchases => 'Restore purchases';

  @override
  String get subscriptionAutoRenewLegal =>
      'Subscription renews automatically. You can cancel anytime in your App Store or Google Play account settings.';

  @override
  String get subscriptionStoreUnavailable =>
      'In-app purchases are not available on this platform.';

  @override
  String get subscriptionAlreadyActive =>
      'You already have an active subscription.';

  @override
  String get subscriptionProductNotFound =>
      'Product not found. Check RevenueCat configuration.';

  @override
  String get subscriptionOfferingsUnavailable =>
      'Subscription plans could not be loaded. Check your connection and RevenueCat web offering, then try again.';

  @override
  String get subscriptionPurchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get subscriptionRestoreNone => 'No purchases to restore.';

  @override
  String get subscriptionRestoreFailed => 'Restore failed.';

  @override
  String get subscriptionPromptTitle => 'Go Premium';

  @override
  String get subscriptionPromptMessage =>
      'Access all Grinta features with a plan tailored to your profile.';

  @override
  String get subscriptionPromptAction => 'View plans';

  @override
  String get subscriptionMenu => 'Subscription';

  @override
  String get subscriptionDetailsTitle => 'Subscription';

  @override
  String get subscriptionTier => 'Plan';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Renews on $date';
  }

  @override
  String get subscriptionNone => 'No active subscription';

  @override
  String subscriptionTrialEnds(String date) {
    return 'Trial ends on $date';
  }

  @override
  String get subscriptionPeriodLabel => 'Period';

  @override
  String get subscriptionRenewalLabel => 'Renewal';

  @override
  String get subscriptionBillingPeriodMonthly => 'Monthly';

  @override
  String get subscriptionBillingPeriodYearly => 'Yearly';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionChangePlan => 'Change plan';

  @override
  String get subscriptionChangePlanTitle => 'Change your plan';

  @override
  String get subscriptionChangePlanSubtitle =>
      'Switch between Coach and Player, change tier, or update your billing period.';

  @override
  String get subscriptionChangePlanConfirm => 'Confirm change';

  @override
  String get subscriptionCurrentPlan => 'Current plan';

  @override
  String get subscriptionPlanChanged => 'Your subscription has been updated.';

  @override
  String subscriptionLimitMaxTeamsReached(int max) {
    return 'You have reached the maximum number of teams ($max) for your subscription.';
  }

  @override
  String subscriptionLimitMaxPlayersReached(int max) {
    return 'You have reached the maximum number of players ($max) for this team.';
  }

  @override
  String get subscriptionLimitPlayerTierOnlySelf =>
      'Your Player subscription only allows you to add yourself to a team.';

  @override
  String subscriptionLimitMaxProfilesReached(int max) {
    return 'You have reached the maximum number of profiles ($max) for your subscription.';
  }

  @override
  String get subscriptionLimitProfileUpgradeTitle => 'Additional profiles';

  @override
  String get subscriptionLimitProfileUpgradeMessage =>
      'Upgrade to a paid subscription to create additional profiles.';

  @override
  String get subscriptionLimitProfileCoachBasicTitle => 'Additional profiles';

  @override
  String get subscriptionLimitProfileCoachBasicMessage =>
      'Upgrade to Elite or Pro to create up to 3 profiles.';

  @override
  String get subscriptionLimitProfilePremiumBadge => 'Premium';

  @override
  String get subscriptionLimitTeamUpgradeTitle => 'Additional teams';

  @override
  String get subscriptionLimitTeamUpgradeMessage =>
      'Upgrade to a Player subscription to create more teams and manage your roster.';

  @override
  String get subscriptionLimitTeamCoachBasicTitle => 'Additional teams';

  @override
  String get subscriptionLimitTeamCoachBasicMessage =>
      'Upgrade to Elite or Pro to create more teams.';

  @override
  String get subscriptionLimitTeamDetailBlockedTitle => 'Team management';

  @override
  String get subscriptionLimitTeamDetailBlockedMessage =>
      'Upgrade to a Player subscription to access team details and manage your roster.';

  @override
  String get subscriptionLimitTeamCreatedFreePlayer =>
      'Your team has been created. Upgrade to access team details.';

  @override
  String get trialStatusTitle => 'Free trial';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String get shopTitle => 'Grinta Shop';

  @override
  String get shopPromoTitle => 'Shop offer';

  @override
  String get shopPromoCta => 'View offer';

  @override
  String get shopBrowseAll => 'Browse shop';

  @override
  String get shopLoadError => 'Unable to load the shop.';

  @override
  String get shopRetry => 'Retry';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String get legalTermsOfService => 'Terms of Service';

  @override
  String get actionDeleteAccount => 'Delete account';

  @override
  String get actionDeleteAccountConfirmTitle => 'Delete account?';

  @override
  String get actionDeleteAccountConfirmMessage =>
      'This action is permanent. Your account, member profile, and associated data will be deleted.';

  @override
  String errorDeleteAccount(String details) {
    return 'Unable to delete account: $details';
  }

  @override
  String get errorDeleteAccountRequiresRecentLogin =>
      'For security, please sign out, sign in again, then retry account deletion.';

  @override
  String get actionDeleteTeam => 'Delete team';

  @override
  String get teamDeleteConfirmTitle => 'Delete team?';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return 'Are you sure you want to delete \"$teamName\"? This action is permanent. All team-related data (members, matches, statistics, etc.) will be deleted.';
  }

  @override
  String teamDeleteSuccess(String teamName) {
    return 'Team \"$teamName\" has been deleted.';
  }

  @override
  String get calendarSyncToggleLabel => 'Calendar sync';

  @override
  String get calendarSyncToggleSubtitle =>
      'Auto-updates when agenda opens (max once every 15 min)';

  @override
  String get calendarSyncWebSubtitle =>
      'Download an ICS file to import into your calendar';

  @override
  String get calendarSyncWebRedownloadHint =>
      'Tap to download the calendar file again';

  @override
  String get calendarSyncWebDownloaded =>
      'Calendar file downloaded. Import it into your calendar app.';

  @override
  String get calendarSyncPermissionDenied =>
      'Calendar access was denied. Enable it in your device settings.';

  @override
  String get calendarSyncCalendarCreationFailed =>
      'Could not create the Grinta calendar on this device.';

  @override
  String get calendarSyncEnableFailed =>
      'Calendar sync could not be enabled. Please try again.';

  @override
  String get calendarSyncForceNow => 'Sync now';

  @override
  String get calendarSyncForceSuccess => 'Calendar synced.';

  @override
  String get calendarSyncForceFailed => 'Sync failed. Please try again.';

  @override
  String get createTrainingTitle => 'New training session';

  @override
  String get createTrainingTeam => 'Team';

  @override
  String get createTrainingTeamRequired => 'Select a team';

  @override
  String get createTrainingDate => 'Date';

  @override
  String get createTrainingTime => 'Time';

  @override
  String get createTrainingDuration => 'Duration';

  @override
  String createTrainingDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createTrainingRecurrent => 'Recurring';

  @override
  String get createTrainingRecurrentDays => 'Day(s) of the week';

  @override
  String get createTrainingRecurrentDaysRequired => 'Select at least one day';

  @override
  String get createTrainingRecurrentFrom => 'From';

  @override
  String get createTrainingRecurrentTo => 'To';

  @override
  String get createTrainingRecurrentInvalidRange =>
      'End date must not be before start date';

  @override
  String get createTrainingWithTracker => 'With GPS tracker';

  @override
  String get createTrainingSelectOwner => 'Tracker kit (owner)';

  @override
  String get createTrainingOwnerRequired => 'Select a tracker owner';

  @override
  String get createTrainingNoOwners =>
      'No tracker kit is assigned to this team.';

  @override
  String get createTrainingNoManagedTeams =>
      'You do not manage any team for this season.';

  @override
  String createTrainingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trainings created',
      one: '1 training created',
    );
    return '$_temp0';
  }

  @override
  String get createTrainingError =>
      'Could not create the training. Please try again.';

  @override
  String get createTrainingSubmit => 'Create training';

  @override
  String get createTrainingRecurrentConfirmTitle => 'Recurring training';

  @override
  String get createTrainingRecurrentConfirmMessage =>
      'Do you want to create the recurring sessions?';

  @override
  String get editTrainingTitle => 'Edit training';

  @override
  String get editTrainingSubmit => 'Save changes';

  @override
  String get editTrainingSaved => 'Training updated';

  @override
  String get editTrainingError =>
      'Could not update the training. Please try again.';

  @override
  String get trainingDeleteConfirmTitle => 'Delete training?';

  @override
  String get trainingDeleteConfirmMessage =>
      'Are you sure you want to delete this training? This action is permanent.';

  @override
  String get trainingDeleted => 'Training deleted';

  @override
  String get trainingDeleteError =>
      'Could not delete the training. Please try again.';

  @override
  String get finishTrainingTitle => 'Finish training';

  @override
  String get trainingFinishConfirmTitle => 'Finish training?';

  @override
  String get trainingFinishConfirmMessage =>
      'Unavailable players marked as present will be set to absent. Do you want to finish this training?';

  @override
  String get trainingFinished => 'Training finished';

  @override
  String get trainingFinishError =>
      'Could not finish the training. Please try again.';

  @override
  String get createMatchTitle => 'New match';

  @override
  String get createMatchTeam => 'Team';

  @override
  String get createMatchTeamRequired => 'Select a team';

  @override
  String get createMatchHome => 'Home match';

  @override
  String get createMatchFriendly => 'Friendly match';

  @override
  String get createMatchDate => 'Date';

  @override
  String get createMatchTime => 'Time';

  @override
  String get createMatchDuration => 'Duration';

  @override
  String createMatchDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createMatchOpponent => 'Opponent';

  @override
  String get createMatchSelectOpponentClub => 'Search for a club';

  @override
  String get createMatchClubNotFound => 'Club not found';

  @override
  String get createMatchOpponentNameManual => 'Opponent name';

  @override
  String get createMatchOpponentRequired => 'Enter the opponent';

  @override
  String get createMatchVenue => 'Venue / field address';

  @override
  String get createMatchWithTracker => 'With GPS tracker';

  @override
  String get createMatchSelectOwner => 'Tracker kit (owner)';

  @override
  String get createMatchOwnerRequired => 'Select a tracker owner';

  @override
  String get createMatchNoOwners => 'No tracker kit is assigned to this team.';

  @override
  String get createMatchNoManagedTeams =>
      'You do not manage any team for this season.';

  @override
  String get createMatchSaved => 'Match created';

  @override
  String get createMatchError =>
      'Could not create the match. Please try again.';

  @override
  String get createMatchSubmit => 'Create match';

  @override
  String get editMatchTitle => 'Edit match';

  @override
  String get editMatchSubmit => 'Save changes';

  @override
  String get editMatchSaved => 'Match updated';

  @override
  String get editMatchError => 'Could not update the match. Please try again.';

  @override
  String get matchDeleteConfirmTitle => 'Delete match?';

  @override
  String get matchDeleteConfirmMessage =>
      'Are you sure you want to delete this match? This action is permanent.';

  @override
  String get matchRemoveFromTeamConfirmTitle => 'Remove match from calendar?';

  @override
  String get matchRemoveFromTeamConfirmMessage =>
      'This will remove the match from your team\'s calendar. The match will remain for other teams.';

  @override
  String get matchDeleted => 'Match deleted';

  @override
  String get matchRemovedFromTeam => 'Match removed from your team\'s calendar';

  @override
  String get matchDeleteError =>
      'Could not delete the match. Please try again.';

  @override
  String get teamDetailManageUnavailabilities => 'Manage unavailabilities';

  @override
  String get manageUnavailabilitiesTitle => 'Unavailabilities';

  @override
  String get manageUnavailabilitiesEmpty =>
      'No unavailabilities for this season.';

  @override
  String get manageUnavailabilitiesAdd => 'Add unavailability';

  @override
  String get manageUnavailabilitiesEditTitle => 'Edit unavailability';

  @override
  String get manageUnavailabilitiesFromDate => 'From';

  @override
  String get manageUnavailabilitiesToDate => 'To';

  @override
  String get manageUnavailabilitiesType => 'Type';

  @override
  String get manageUnavailabilitiesDetails => 'Details';

  @override
  String get manageUnavailabilitiesDetailsHint => 'Optional details';

  @override
  String get manageUnavailabilitiesVisible => 'Visible to team';

  @override
  String get manageUnavailabilitiesVisibleHint =>
      'If disabled, only managers can see this entry';

  @override
  String manageUnavailabilitiesDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get manageUnavailabilitiesHidden => 'Hidden';

  @override
  String get manageUnavailabilitiesSaved => 'Unavailability saved';

  @override
  String get manageUnavailabilitiesDeleted => 'Unavailability deleted';

  @override
  String get manageUnavailabilitiesError =>
      'Could not save unavailability. Please try again.';

  @override
  String get manageUnavailabilitiesDeleteError =>
      'Could not delete unavailability. Please try again.';

  @override
  String get manageUnavailabilitiesDeleteConfirmTitle =>
      'Delete unavailability?';

  @override
  String get manageUnavailabilitiesDeleteConfirmMessage =>
      'This action is permanent.';

  @override
  String get manageUnavailabilitiesInvalidRange =>
      'End date must not be before start date';

  @override
  String get manageUnavailabilitiesTypeRequired => 'Please select a type';

  @override
  String get unavailabilityTypeHoliday => 'Holiday';

  @override
  String get unavailabilityTypeUnwell => 'Unwell';

  @override
  String get unavailabilityTypeInjured => 'Injured';

  @override
  String get unavailabilityTypeOther => 'Other';

  @override
  String teamStatsScreenTitle(String teamName) {
    return 'Statistics — $teamName';
  }

  @override
  String get teamStatsTabAnalysis => 'Analysis';

  @override
  String get teamStatsTabCalendars => 'Calendars';

  @override
  String get teamStatsCompetitionFilterLabel => 'Competitions';

  @override
  String get teamStatsOpponentFilterLabel => 'Club';

  @override
  String get teamStatsNoOpponents => 'No clubs in this competition';

  @override
  String get teamStatsTabTrainings => 'Training sessions';

  @override
  String get teamStatsTabOpponents => 'Opponents';

  @override
  String get teamStatsSubTabMatches => 'Matches';

  @override
  String get teamStatsSubTabRanking => 'Standings';

  @override
  String get teamStatsSubTabGoals => 'Goals';

  @override
  String get teamStatsSubTabPlayers => 'Players';

  @override
  String get teamStatsSubTabTypicalTeam => 'Typical team';

  @override
  String get teamStatsTypicalTeamStartersSection => 'Probable starters';

  @override
  String get teamStatsTypicalTeamSubstitutesSection => 'Probable substitutes';

  @override
  String teamStatsTypicalTeamStartsLabel(int starts, int total) {
    return '$starts/$total starts';
  }

  @override
  String teamStatsTypicalTeamSubsLabel(int subs, int total) {
    return '$subs/$total as sub';
  }

  @override
  String get teamStatsTypicalTeamNoData =>
      'No lineup data available for this opponent';

  @override
  String teamStatsTypicalTeamIncompleteStarters(int count) {
    return 'Only $count players with starter data';
  }

  @override
  String teamStatsTypicalTeamMatchesBasis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches with lineup data',
      one: '1 match with lineup data',
    );
    return 'Based on $_temp0';
  }

  @override
  String get teamStatsRankingAtDate => 'Current';

  @override
  String get teamStatsRankingEvolution => 'Trend';

  @override
  String get teamStatsRankingNoData =>
      'No standings available for this competition';

  @override
  String get teamStatsRankingSelectCompetition =>
      'Select a competition to view standings';

  @override
  String get teamStatsRankingColumnRank => '#';

  @override
  String get teamStatsRankingColumnTeam => 'Team';

  @override
  String get teamStatsRankingColumnPts => 'Pts';

  @override
  String get teamStatsRankingColumnPlayed => 'P';

  @override
  String get teamStatsRankingColumnWon => 'W';

  @override
  String get teamStatsRankingColumnDrawn => 'D';

  @override
  String get teamStatsRankingColumnLost => 'L';

  @override
  String get teamStatsRankingColumnDiff => '+/-';

  @override
  String get teamStatsRankingAddClubs => 'Compare clubs';

  @override
  String get teamStatsRankingSelectClubsTitle => 'Select clubs to compare';

  @override
  String get teamStatsRankingOwnTeamLabel => 'Your team';

  @override
  String teamStatsRankingTooltipRank(String rank) {
    return 'Rank $rank';
  }

  @override
  String get teamStatsAllCompetitions => 'All competitions';

  @override
  String get teamStatsContentComingSoon => 'Content coming soon';

  @override
  String get teamStatsNoCompetitions => 'No competitions available';

  @override
  String get teamStatsPlayerComingSoon => 'Player view coming soon';

  @override
  String get teamStatsPeriodFullSeason => 'Full season';

  @override
  String get teamStatsPeriodFirstHalf => 'First half';

  @override
  String get teamStatsPeriodSecondHalf => 'Second half';

  @override
  String get teamStatsNoPlayedMatches => 'No played matches in this period';

  @override
  String teamStatsWdlMatchesDialogTitle(String outcome, String period) {
    return '$outcome — $period';
  }

  @override
  String get teamStatsTrendLabel => 'Trend';

  @override
  String get teamStatsTrendUp => 'Improving';

  @override
  String get teamStatsTrendDown => 'Declining';

  @override
  String get teamStatsTrendFlat => 'Stable';

  @override
  String get teamStatsTrendInsufficientData => 'Not enough match data';

  @override
  String get teamStatsGoalsScored => 'Goals scored';

  @override
  String get teamStatsGoalsConceded => 'Goals conceded';

  @override
  String get teamStatsGoalsTrendScored => 'Goals scored';

  @override
  String get teamStatsGoalsTrendConceded => 'Goals conceded';

  @override
  String teamStatsGoalsAvgPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString/match';
  }

  @override
  String teamStatsGoalsMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String teamStatsAvgPointsPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString';
  }

  @override
  String get teamStatsPlayersColumnPlayer => 'Player';

  @override
  String get teamStatsPlayersColumnConvocations => 'Convo';

  @override
  String get teamStatsPlayersColumnStarts => 'Starts';

  @override
  String get teamStatsPlayersColumnPlayTime => 'Mins';

  @override
  String get teamStatsPlayersColumnGoals => 'Goals';

  @override
  String get teamStatsPlayersNoData => 'No player data for this period';

  @override
  String teamStatsPlayersPlayTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teamStatsAllMonths => 'All months';

  @override
  String teamStatsTrainingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count training sessions',
      one: '1 training session',
    );
    return '$_temp0';
  }

  @override
  String get teamStatsTrainingsAttendanceRate => 'Attendance rate';

  @override
  String teamStatsTrainingsAttendanceRateValue(String value) {
    return '$value %';
  }

  @override
  String get teamStatsTrainingsNoData =>
      'No past training sessions in this period';

  @override
  String get teamStatsTrainingsNoSeasonMonths =>
      'No months available for this season';

  @override
  String get teamStatsTrainingsColumnPresent => 'Pres.';

  @override
  String get teamStatsTrainingsColumnAbsent => 'Abs.';

  @override
  String get teamStatsTrainingsColumnAttendanceRate => 'Rate';

  @override
  String get teamStatsTrainingsPlayersNoData =>
      'No player data for this period';

  @override
  String get teamStatsTrainingsGlobalSection => 'Team';

  @override
  String get teamStatsTrainingsPersonalSection => 'My stats';

  @override
  String get teamStatsCalendarNoMatchdays => 'No matches for this competition';

  @override
  String get teamStatsCalendarNoMatchesForMatchday =>
      'No matches for this matchday';

  @override
  String get teamStatsCalendarDatesLabel => 'Dates';

  @override
  String get teamStatsCalendarNoMatchDates => 'No dates scheduled';

  @override
  String get teamStatsCalendarDateSeparator => ', ';
}
