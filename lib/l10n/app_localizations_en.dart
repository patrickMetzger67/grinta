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
  String get memberEmailRequired => 'Email is required for member invitations';

  @override
  String invitationEmailSubject(String appName) {
    return 'Your coach invites you to join $appName';
  }

  @override
  String invitationEmailIntro(String appName) {
    return 'Your coach invites you to join $appName';
  }

  @override
  String get invitationEmailCodeLabel => 'Your invitation code';

  @override
  String get invitationEmailDownloadIos => 'Download on iPhone';

  @override
  String get invitationEmailDownloadAndroid => 'Download on Android';

  @override
  String invitationEmailFooter(String appName) {
    return 'You received this email because a coach added you on $appName. If you were not expecting this message, you can ignore it.';
  }

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Your coach invites you to join $appName. Your code: $code.\niPhone: $appleStoreUrl\nAndroid: $googlePlayUrl';
  }

  @override
  String sessionReportEmailSubject(
      String appName, String eventLabel, String title) {
    return '$appName — $eventLabel report: $title';
  }

  @override
  String sessionReportEmailIntro(String appName) {
    return 'Here is your $appName statistics report';
  }

  @override
  String get sessionReportEmailEventMatch => 'match';

  @override
  String get sessionReportEmailEventTraining => 'training';

  @override
  String get sessionReportEmailDetailsLabel => 'Report details';

  @override
  String get sessionReportEmailTypeLabel => 'Type';

  @override
  String get sessionReportEmailTitleLabel => 'Session';

  @override
  String get sessionReportEmailDateLabel => 'Date';

  @override
  String get sessionReportEmailTeamLabel => 'Team';

  @override
  String get sessionReportEmailPlayersLabel => 'Players';

  @override
  String get sessionReportEmailAvgWorkloadLabel => 'Average workload';

  @override
  String sessionReportEmailDateLine(String date) {
    return 'Date: $date';
  }

  @override
  String sessionReportEmailTeamLine(String team) {
    return 'Team: $team';
  }

  @override
  String sessionReportEmailPlayersLine(int count) {
    return 'Players with data: $count';
  }

  @override
  String get sessionReportEmailAttachmentHint =>
      'The tracker statistics PDF report is attached to this email.';

  @override
  String get sessionReportEmailDownloadHint =>
      'Download the PDF report using the button below.';

  @override
  String get sessionReportEmailDownloadButton => 'Download PDF';

  @override
  String sessionReportEmailDownloadLine(String url) {
    return 'Download the PDF: $url';
  }

  @override
  String get sessionReportEmailAskAddress =>
      'Tell me which email address should receive the PDF report.';

  @override
  String get sessionReportEmailNoSessionYesterday =>
      'I could not find any session for that period.';

  @override
  String get sessionReportEmailPeriodUnclear =>
      'Please specify the period (yesterday, today…) for the report.';

  @override
  String sessionReportEmailFooter(String appName) {
    return 'You received this email because a session report was generated from $appName. If you were not expecting this message, you can ignore it.';
  }

  @override
  String get sessionReportEmailDialogTitle => 'Send PDF report';

  @override
  String get sessionReportEmailDialogMessage =>
      'Select one or more managers who should receive the statistics report (PDF).';

  @override
  String get sessionReportEmailDialogHint => 'you@example.com';

  @override
  String get sessionReportEmailDialogSend => 'Send';

  @override
  String get sessionReportEmailDialogCancel => 'Cancel';

  @override
  String get sessionReportEmailActionTooltip => 'Email PDF report';

  @override
  String get sessionReportEmailActionLabel => 'PDF report';

  @override
  String sessionReportEmailSuccess(String email) {
    return 'Report sent to $email';
  }

  @override
  String sessionReportEmailSuccessCount(int count) {
    return 'Report sent to $count recipients';
  }

  @override
  String sessionReportEmailSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get sessionReportEmailSelectAll => 'Select all';

  @override
  String get sessionReportEmailDeselectAll => 'Deselect all';

  @override
  String get sessionReportEmailNoManagers =>
      'No managers with an email address found for this team.';

  @override
  String get sessionReportEmailManualOnlyMessage =>
      'Enter one or more email addresses that should receive the report (separated by ;).';

  @override
  String get sessionReportEmailAdditionalLabel => 'Additional addresses';

  @override
  String get sessionReportEmailManualHint =>
      'you@example.com; other@example.com';

  @override
  String get sessionReportEmailManualHelper =>
      'Multiple addresses: separate them with a semicolon (;).';

  @override
  String get sessionReportEmailNoSelection =>
      'Select a manager or enter at least one email address.';

  @override
  String get sessionReportEmailFailed => 'Could not send the PDF report.';

  @override
  String get sessionReportEmailNoStats =>
      'No tracker statistics are available to generate this report.';

  @override
  String get sessionReportEmailInvalid => 'Invalid email address.';

  @override
  String get memberInvitationEmailFailed =>
      'Member added, but the invitation email could not be sent.';

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
  String get resendInvitationTooltip => 'Resend invitation email';

  @override
  String get resendInvitationNoEmailTooltip =>
      'Add an email address to send an invitation';

  @override
  String get resendInvitationSuccess => 'Invitation email sent';

  @override
  String get resendInvitationFailed => 'Could not send the invitation email';

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
  String get teamCreationSelectCountry => 'Select a country';

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
  String get hintSearchMember => 'Search by name or email';

  @override
  String get memberSearchPrompt =>
      'Type a first name, last name, or email address to search';

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
  String get dialogCloseSyncTitle => 'Permanently close synchronization';

  @override
  String get dialogCloseSyncMessage =>
      'Do you want to permanently close synchronization? Yes: this screen will no longer be available. No: leave without closing.';

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
  String get asiFileEmptyOrNoData =>
      'The .asi file is empty or contains no usable data.';

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
  String get teamStreamChannelSynced => 'Stream group active';

  @override
  String get teamStreamChannelPending => 'Stream group not synced yet';

  @override
  String get teamStreamChannelCreateTitle => 'Create Stream group?';

  @override
  String teamStreamChannelCreateMessage(String teamName) {
    return 'Create the Stream group for team $teamName? Players and staff will be added automatically.';
  }

  @override
  String get teamStreamChannelCreateConfirm => 'Create';

  @override
  String get teamStreamChannelCreateLoading => 'Creating Stream group…';

  @override
  String teamStreamChannelCreateSuccess(String teamName) {
    return 'Stream group created for $teamName.';
  }

  @override
  String teamStreamChannelCreateError(String details) {
    return 'Could not create Stream group: $details';
  }

  @override
  String get teamStreamChannelCreateNotManager =>
      'Only managers can create the Stream group.';

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
  String get chatChannelMembersTitle => 'Members';

  @override
  String get chatMessageReadByTitle => 'Read by';

  @override
  String get chatMessageNotReadYet => 'Not read yet';

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
  String get trackerAllSensorsSynced => 'All sensors have been synchronized';

  @override
  String get trackerSensorsRemaining => 'To synchronize';

  @override
  String get trackerSensorsAlreadySynced => 'Already synchronized';

  @override
  String trackerSyncedProgress(int synced, int total) {
    return '$synced/$total synchronized';
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
  String get entityPersonalSports => 'Individual sports activities';

  @override
  String get dashboardPersonalSportsListTitle => 'Sports activities list';

  @override
  String get emptyNoPersonalSportToShow => 'No sports activities to show';

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
  String get agendaAllDayLabel => 'All day';

  @override
  String get coachWorkloadAnalysisFabTooltip => 'Player workload analysis';

  @override
  String get coachWorkloadAnalysisTitle => 'Workload analysis';

  @override
  String get coachWorkloadTeaserHeadline => 'Compare your players’ workload';

  @override
  String get coachWorkloadTeaserBody =>
      'Team + individual recap for the period, workload indicators and activity list. Available with Coach Pro.';

  @override
  String get coachWorkloadTeaserCta => 'Discover Coach Pro';

  @override
  String get coachWorkloadCompareHint =>
      'Compare players at a glance, then open the detail.';

  @override
  String get coachWorkloadNoManagedTeam => 'No managed team for this season.';

  @override
  String get coachWorkloadLoadError => 'Unable to load analysis.';

  @override
  String get coachWorkloadEmptyPlayers => 'No players to show.';

  @override
  String get coachWorkloadEmptyActivities => 'No activities in this period.';

  @override
  String get coachWorkloadPlayerRecapTitle => 'Workload summary';

  @override
  String get coachWorkloadActivitiesTitle => 'Activities';

  @override
  String coachWorkloadMetricSessions(int count) {
    return '$count trainings';
  }

  @override
  String coachWorkloadMetricMatches(int count) {
    return '$count matches';
  }

  @override
  String coachWorkloadMetricPersonalSports(int count) {
    return '$count personal';
  }

  @override
  String coachWorkloadMetricKm(String value) {
    return '$value km';
  }

  @override
  String get coachWorkloadReportEmailActionTooltip => 'Send PDF report';

  @override
  String get coachWorkloadReportEmailDialogTitle =>
      'Send workload analysis (PDF)';

  @override
  String get coachWorkloadReportEmpty => 'No data to export for this period.';

  @override
  String coachWorkloadReportEmailSubject(String team, String period) {
    return 'Grinta — Workload analysis $team ($period)';
  }

  @override
  String get coachWorkloadReportEmailGreeting => 'Hello,';

  @override
  String coachWorkloadReportEmailIntro(String team, String period) {
    return 'Here is the workload analysis for $team over $period.';
  }

  @override
  String get coachWorkloadReportEmailDownload => 'Download PDF';

  @override
  String coachWorkloadReportEmailText(String team, String period, String url) {
    return 'Workload analysis — $team\nPeriod: $period\nPDF: $url';
  }

  @override
  String coachWorkloadMetricLoad(String value) {
    return 'Load $value';
  }

  @override
  String coachWorkloadMetricVolume(int minutes) {
    return '$minutes min';
  }

  @override
  String coachWorkloadMetricPresence(String value) {
    return 'Attendance $value';
  }

  @override
  String coachWorkloadBreakdown(int trainings, int matches, int personal) {
    return '$trainings workouts · $matches matches · $personal personal sports';
  }

  @override
  String get agendaCoachPlayersFabTooltip => 'Players — personal activities';

  @override
  String get agendaCoachPlayersTitle => 'Players’ sports activities';

  @override
  String get agendaCoachPlayersSubtitle =>
      'Show personal sport activities with coach visibility in the agenda.';

  @override
  String get agendaCoachPlayersTeam => 'Team';

  @override
  String get agendaCoachPlayersPlayers => 'Players';

  @override
  String get agendaCoachPlayersNoTeams => 'No managed team for this season.';

  @override
  String get agendaCoachPlayersLoadError => 'Could not load players.';

  @override
  String get agendaCoachPlayersEmptyRoster => 'No players in this team.';

  @override
  String get agendaCoachPlayersClear => 'Clear selection';

  @override
  String get agendaFilterFabTooltip => 'Filter agenda';

  @override
  String get agendaFilterTitle => 'Filter agenda';

  @override
  String get agendaFilterTypesSection => 'Event types';

  @override
  String get agendaFilterTeamsSection => 'Teams';

  @override
  String get agendaFilterNoTeams => 'No teams available for this season.';

  @override
  String get agendaFilterSelectAllTeams => 'Select all';

  @override
  String get agendaFilterSelectNoneTeams => 'Narrow selection';

  @override
  String get agendaFilterApply => 'Apply';

  @override
  String get agendaFilterActiveBanner => 'Filter active';

  @override
  String get agendaFilterActiveBannerDetail =>
      'Some teams or types are hidden.';

  @override
  String get agendaFilterClear => 'Clear filter';

  @override
  String agendaEventSummaryNonSport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get createPersonalSportTitle => 'New sports activity';

  @override
  String get createPersonalSportDate => 'Date';

  @override
  String get createPersonalSportTime => 'Time';

  @override
  String get createPersonalSportManualEntry => 'Manual entry';

  @override
  String get createPersonalSportManualEntryHint =>
      'Enter duration, distance and pace manually';

  @override
  String get createPersonalSportImportHint =>
      'Import an activity from a connected app';

  @override
  String get createPersonalSportDuration => 'Time';

  @override
  String get createPersonalSportDistance => 'Distance';

  @override
  String get createPersonalSportPace => 'Pace';

  @override
  String get createPersonalSportTapToSet => 'Tap to set';

  @override
  String get createPersonalSportType => 'Activity type';

  @override
  String get createPersonalSportTypeRequired => 'Choose an activity type';

  @override
  String get createPersonalSportImportSource => 'App / device';

  @override
  String get createPersonalSportPolarActivity => 'Polar activity';

  @override
  String get createPersonalSportWhoopActivity => 'Whoop activity';

  @override
  String get createPersonalSportWhoopDeployRequired =>
      'Whoop import is not deployed yet. Run firebase deploy for whoopListActivities and whoopImportActivity.';

  @override
  String get createPersonalSportWhoopLoadError =>
      'Could not load Whoop activities. Check the connection and try again.';

  @override
  String get createPersonalSportWhoopNoImportable =>
      'No Whoop workouts to import.';

  @override
  String get createPersonalSportAppleActivity => 'Apple Fitness activity';

  @override
  String get createPersonalSportAppleIosOnly =>
      'Apple Fitness import is available on iPhone only.';

  @override
  String get createPersonalSportAppleLoadError =>
      'Could not load Apple Fitness workouts. Check Health permissions and try again.';

  @override
  String get createPersonalSportAppleNoImportable =>
      'No Apple Fitness workouts to import. Record a session in Fitness / Health, allow Grinta access, then retry.';

  @override
  String get createPersonalSportGoogleActivity => 'Google Health activity';

  @override
  String get createPersonalSportGoogleAndroidOnly =>
      'Google Health import is available on Android only. On iPhone, use Apple Fitness.';

  @override
  String get createPersonalSportGoogleLoadError =>
      'Could not load Google Health workouts. Check Health Connect permissions and try again.';

  @override
  String get createPersonalSportGoogleNoImportable =>
      'No Google Health workouts to import. Record a session in Google Health / Fit, allow Grinta in Health Connect, then retry.';

  @override
  String get createPersonalSportPolarDeployRequired =>
      'Polar import is not deployed yet. Run firebase deploy for polarListActivities and polarImportActivity.';

  @override
  String get createPersonalSportPolarLoadError =>
      'Could not load Polar activities. Check the connection and try again.';

  @override
  String get createPersonalSportPolarNoImportable =>
      'No Polar Flow training session to import. In Polar Flow, confirm the session is a Training (not only continuous HR), synced after connecting Grinta, then retry.';

  @override
  String get createPersonalSportStravaActivity => 'Strava activity';

  @override
  String get createPersonalSportNoImportable => 'No activities to import';

  @override
  String get createPersonalSportNoConnectedApps =>
      'No connected app. Connect Strava, Polar, Whoop, Apple Fitness or Google Health in Devices / Apps.';

  @override
  String get createPersonalSportImportRequired =>
      'Select an activity to import';

  @override
  String get createPersonalSportNotes => 'Note';

  @override
  String get createPersonalSportVisibility => 'Visibility';

  @override
  String get createPersonalSportVisibilityPrivate => 'Private';

  @override
  String get createPersonalSportVisibilityCoach => 'Coach';

  @override
  String get createPersonalSportVisibilityTeam => 'Team';

  @override
  String get createPersonalSportSubmit => 'Create activity';

  @override
  String get createPersonalSportUseMyGps => 'Use my GPS';

  @override
  String get createPersonalSportUseMyGpsHint =>
      'Recover duration, distance and pace from your GPS sensor (Intense)';

  @override
  String get createPersonalSportGpsDevice => 'GPS sensor';

  @override
  String get createPersonalSportGpsMetricsHint =>
      'Duration, distance and pace will be calculated from sensor sync (from start time until now).';

  @override
  String get createPersonalSportGpsSubmit => 'Sync and create';

  @override
  String get createPersonalSportGpsDeviceRequired => 'Select a GPS sensor.';

  @override
  String get createPersonalSportGpsStartInFuture =>
      'Start time must be earlier than now.';

  @override
  String get createPersonalSportGpsNoData =>
      'There is no data to sync. Check the date and start time of your session.';

  @override
  String get createPersonalSportGpsManualEntryQuestion =>
      'Would you like to enter the data manually?';

  @override
  String get createPersonalSportGpsSyncError =>
      'Unable to sync GPS. Please try again.';

  @override
  String get sessionPersonalDataTitle => 'My data';

  @override
  String get sessionPersonalDataSubtitle =>
      'Attach your GPS or a connected app to this session (no team tracker assigned).';

  @override
  String get sessionPersonalDataGpsHint =>
      'Sync your Intense GPS sensor and generate a heatmap when the pitch is positioned.';

  @override
  String get sessionPersonalDataGpsSubmit => 'Sync my data';

  @override
  String get sessionPersonalDataAppSubmit => 'Attach activity';

  @override
  String get sessionPersonalDataSaved => 'Data attached to the session.';

  @override
  String get sessionPersonalDataError =>
      'Unable to attach data. Please try again.';

  @override
  String get sessionPersonalDataAuthRequired =>
      'Sign in with a player profile to attach data.';

  @override
  String get sessionPersonalDataSwitchToAppsQuestion =>
      'Would you like to choose a connected app / device?';

  @override
  String get createPersonalSportSaved => 'Activity created';

  @override
  String get createPersonalSportError =>
      'Could not create the activity. Please try again.';

  @override
  String get createPersonalSportAuthRequired =>
      'Sign in to create an activity.';

  @override
  String get editPersonalSportTitle => 'Edit activity';

  @override
  String get editPersonalSportSubmit => 'Save';

  @override
  String get editPersonalSportSaved => 'Activity updated';

  @override
  String get editPersonalSportError =>
      'Could not update the activity. Please try again.';

  @override
  String get viewPersonalSportTitle => 'Sports activity';

  @override
  String get deletePersonalSportConfirmTitle => 'Delete activity?';

  @override
  String deletePersonalSportConfirmMessage(String title) {
    return '“$title” will be permanently deleted.';
  }

  @override
  String get deletePersonalSportDeleted => 'Activity deleted';

  @override
  String get deletePersonalSportError =>
      'Could not delete the activity. Please try again.';

  @override
  String get personalSportMetricDistance => 'Distance';

  @override
  String get personalSportMetricAvgPace => 'Avg pace';

  @override
  String get personalSportMetricDuration => 'Duration';

  @override
  String get personalSportMetricCalories => 'Calories';

  @override
  String get personalSportMetricAvgHeartRate => 'Avg HR';

  @override
  String get personalSportUnitKcal => 'kcal';

  @override
  String get personalSportUnitBpm => 'bpm';

  @override
  String get createNonSportEventTitle => 'New event / activity';

  @override
  String get createNonSportEventTitleField => 'Title';

  @override
  String get createNonSportEventTitleRequired => 'Enter a title';

  @override
  String get createNonSportEventDate => 'Date';

  @override
  String get createNonSportEventTime => 'Time';

  @override
  String get createNonSportEventAllDay => 'All day';

  @override
  String get createNonSportEventStartDate => 'Start date';

  @override
  String get createNonSportEventStartTime => 'Start time';

  @override
  String get createNonSportEventEndDate => 'End date';

  @override
  String get createNonSportEventEndTime => 'End time';

  @override
  String get createNonSportEventInvalidRange => 'End must be after start.';

  @override
  String get editNonSportEventTitle => 'Edit event';

  @override
  String get editNonSportEventSubmit => 'Save';

  @override
  String get editNonSportEventSaved => 'Event updated';

  @override
  String get editNonSportEventError =>
      'Could not update the event. Please try again.';

  @override
  String get deleteNonSportEventConfirmTitle => 'Delete event?';

  @override
  String deleteNonSportEventConfirmMessage(String title) {
    return '“$title” will be permanently deleted, including related notifications.';
  }

  @override
  String get deleteNonSportEventDeleted => 'Event deleted';

  @override
  String get deleteNonSportEventError =>
      'Could not delete the event. Please try again.';

  @override
  String get createNonSportEventLocation => 'Location';

  @override
  String get createNonSportEventLocationHint => 'Address or meeting place';

  @override
  String get createNonSportEventInviteTeams => 'Invite one or more teams';

  @override
  String get createNonSportEventSelectMembers => 'Select members';

  @override
  String createNonSportEventSelectedMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members selected',
      one: '1 member selected',
    );
    return '$_temp0';
  }

  @override
  String get createNonSportEventNoTeamMembers => 'No members in this team.';

  @override
  String get createNonSportEventInviteOthers => 'Invite other profiles';

  @override
  String get createNonSportEventAddProfile => 'Add a profile';

  @override
  String get createNonSportEventInvitees => 'Invitees';

  @override
  String get createNonSportEventNoInvitees => 'No invitees yet.';

  @override
  String get createNonSportEventNoTeams =>
      'No teams available for this season.';

  @override
  String get createNonSportEventSubmit => 'Create event';

  @override
  String get createNonSportEventSaved => 'Event created';

  @override
  String get createNonSportEventError =>
      'Could not create the event. Please try again.';

  @override
  String get createNonSportEventInviteStatusSent => 'Notification sent';

  @override
  String get createNonSportEventInviteStatusNoAccount =>
      'No linked user account';

  @override
  String get createNonSportEventInviteStatusPending => 'Pending';

  @override
  String get createNonSportEventInviteStatusError => 'Notification failed';

  @override
  String get createNonSportEventNotificationTitle => 'New event';

  @override
  String createNonSportEventNotificationBody(String title, String when) {
    return '$title — $when';
  }

  @override
  String createNonSportEventNotificationBodyWithLocation(
      String title, String when, String location) {
    return '$title — $when — $location';
  }

  @override
  String get nonSportEventInviteesTitle => 'Invitations';

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
  String get teamDetailTrackerCoachProRequiredTitle => 'GPS trackers';

  @override
  String get teamDetailTrackerCoachProRequiredMessage =>
      'Linking GPS tracker kits to a team requires a Coach Pro subscription.';

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
  String get teamEditNameTitle => 'Edit team';

  @override
  String get teamEditNameSuccess => 'Team updated.';

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
  String get settingsDevicesSection => 'Devices/Applications';

  @override
  String get settingsDevicesClose => 'Close';

  @override
  String get settingsDevicesSync => 'Sync';

  @override
  String get settingsDevicesConnectedTitle => 'Connected devices/applications';

  @override
  String get settingsDevicesConnectedStatus => 'Connected';

  @override
  String get settingsDevicesDisconnect => 'Disconnect';

  @override
  String get settingsDevicesNoConnected =>
      'No devices or applications connected';

  @override
  String get settingsDevicesAddTitle => 'Add a connection';

  @override
  String get settingsDevicesAddFabTooltip => 'Add a connection';

  @override
  String get settingsDevicesAllConnected =>
      'All available devices/applications are already connected';

  @override
  String settingsDevicesBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connected devices/applications',
      one: '1 connected device/application',
      zero: 'No connected devices/applications',
    );
    return '$_temp0';
  }

  @override
  String get wearableDeviceTypeLabel => 'Device/application type';

  @override
  String get wearableDeviceWhoop => 'Whoop';

  @override
  String get wearableDeviceStrava => 'Strava';

  @override
  String get wearableDevicePolar => 'Polar';

  @override
  String get wearableDeviceFitbit => 'Fitbit';

  @override
  String get wearableDeviceAppleHealth => 'Apple Fitness';

  @override
  String get wearableDeviceGoogleHealthConnect => 'Google Health';

  @override
  String get whoopConnectToggleLabel => 'Whoop sync';

  @override
  String get whoopConnectToggleSubtitle =>
      'Connect your Whoop account to import recovery, sleep, and workouts';

  @override
  String get whoopConnectToggleConnectedSubtitle =>
      'Whoop connected — data sync coming in Phase 2';

  @override
  String get whoopConnectSuccess => 'Whoop account connected.';

  @override
  String get whoopAccountHintGuidance =>
      'Your Whoop email can differ from your Grinta account. Enter the Whoop account to use, then sign in with that account on the Whoop page.';

  @override
  String get whoopAccountHintLabel => 'Whoop account';

  @override
  String get whoopAccountHintPlaceholder => 'Whoop email';

  @override
  String get whoopAccountHintRequired =>
      'Enter your Whoop account (email) before continuing.';

  @override
  String get whoopConnectContinue => 'Continue to Whoop';

  @override
  String get whoopConnectFailed =>
      'Whoop connection failed. Check that Whoop Cloud Functions are deployed and WHOOP_CLIENT_ID / WHOOP_CLIENT_SECRET secrets are configured.';

  @override
  String get whoopConnectLaunchFailed =>
      'Could not open the Whoop sign-in page.';

  @override
  String get whoopConnectAuthRequired => 'Sign in to Grinta to connect Whoop.';

  @override
  String get whoopDisconnectFailed => 'Whoop disconnect failed.';

  @override
  String get whoopCoachVisibilityTitle => 'Coach visibility';

  @override
  String get whoopCoachVisibilitySubtitle =>
      'Allow your coach to see this data type';

  @override
  String get whoopCoachVisibilitySaveFailed =>
      'Could not save Whoop preferences.';

  @override
  String get whoopMetricRecovery => 'Recovery';

  @override
  String get whoopMetricCycles => 'Cycles';

  @override
  String get whoopMetricSleep => 'Sleep';

  @override
  String get whoopMetricWorkout => 'Workouts';

  @override
  String get whoopMetricProfile => 'Profile';

  @override
  String get whoopMetricBodyMeasurement => 'Body measurements';

  @override
  String get whoopCoachConnectTitle => 'Whoop';

  @override
  String whoopCoachConnectSubtitle(String playerName) {
    return 'Connect Whoop for $playerName';
  }

  @override
  String get whoopCoachConnectAction => 'Connect';

  @override
  String whoopCoachConnectConnectedSubtitle(String playerName) {
    return 'Whoop connected for $playerName';
  }

  @override
  String get stravaConnectToggleSubtitle =>
      'Connect your Strava account to import activities and workouts';

  @override
  String get stravaConnectToggleConnectedSubtitle =>
      'Strava connected — data sync coming in Phase 2';

  @override
  String get stravaAccountHintGuidance =>
      'Your Strava email can differ from your Grinta account. Enter the Strava account to use, then sign in with that account on the Strava page.';

  @override
  String get stravaAccountHintLabel => 'Strava account';

  @override
  String get stravaAccountHintPlaceholder => 'Strava email or username';

  @override
  String get stravaAccountHintRequired =>
      'Enter your Strava account (email or username) before continuing.';

  @override
  String get stravaConnectContinue => 'Continue to Strava';

  @override
  String get stravaConnectSuccess => 'Strava account connected.';

  @override
  String get stravaConnectFailed =>
      'Strava connection failed. Check that Strava Cloud Functions are deployed and STRAVA_CLIENT_ID / STRAVA_CLIENT_SECRET secrets are configured.';

  @override
  String get stravaConnectLaunchFailed =>
      'Could not open the Strava sign-in page.';

  @override
  String get stravaConnectAuthRequired =>
      'Sign in to Grinta to connect Strava.';

  @override
  String get stravaDisconnectFailed => 'Strava disconnect failed.';

  @override
  String get stravaCoachVisibilitySaveFailed =>
      'Could not save Strava preferences.';

  @override
  String get stravaMetricActivities => 'Activities';

  @override
  String get stravaMetricProfile => 'Profile';

  @override
  String stravaCoachConnectSubtitle(String playerName) {
    return 'Connect Strava for $playerName';
  }

  @override
  String stravaCoachConnectConnectedSubtitle(String playerName) {
    return 'Strava connected for $playerName';
  }

  @override
  String get polarConnectToggleSubtitle =>
      'Connect your Polar account to import training, sleep, and heart rate data from Loop or Verity Sense via Polar Flow';

  @override
  String get polarConnectToggleConnectedSubtitle =>
      'Polar connected — data sync coming in Phase 2';

  @override
  String get polarAccountHintGuidance =>
      'Your Polar Flow email can differ from your Grinta account. Enter the Polar account to use, then sign in with that account on the Polar page.';

  @override
  String get polarAccountHintLabel => 'Polar account';

  @override
  String get polarAccountHintPlaceholder => 'Polar Flow email';

  @override
  String get polarAccountHintRequired =>
      'Enter your Polar account (email) before continuing.';

  @override
  String get polarConnectContinue => 'Continue to Polar';

  @override
  String get polarConnectSuccess => 'Polar account connected.';

  @override
  String get polarConnectFailed => 'Polar connection failed. Please try again.';

  @override
  String get polarConnectLaunchFailed =>
      'Could not open the Polar sign-in page.';

  @override
  String get polarConnectAuthRequired => 'Sign in to Grinta to connect Polar.';

  @override
  String get polarDisconnectFailed => 'Polar disconnect failed.';

  @override
  String get polarCoachVisibilityTitle => 'Coach visibility';

  @override
  String get polarCoachVisibilitySubtitle =>
      'Allow your coach to see this data type';

  @override
  String get polarCoachVisibilitySaveFailed =>
      'Could not save Polar preferences.';

  @override
  String get polarMetricTraining => 'Training / workouts';

  @override
  String get polarMetricSleep => 'Sleep';

  @override
  String get polarMetricRecoveryHr => 'Recovery / heart rate';

  @override
  String get polarMetricProfile => 'Profile';

  @override
  String get polarMetricBody => 'Body measurements';

  @override
  String polarCoachConnectSubtitle(String playerName) {
    return 'Connect Polar for $playerName';
  }

  @override
  String polarCoachConnectConnectedSubtitle(String playerName) {
    return 'Polar connected for $playerName';
  }

  @override
  String get fitbitConnectToggleSubtitle =>
      'Connect your Fitbit account to import activity, heart rate, sleep, and weight data from your Fitbit bracelet via Fitbit cloud';

  @override
  String get fitbitConnectToggleConnectedSubtitle =>
      'Fitbit connected — data sync coming in Phase 2';

  @override
  String get fitbitConnectSuccess => 'Fitbit account connected.';

  @override
  String get fitbitConnectFailed =>
      'Fitbit connection failed. Please try again.';

  @override
  String get fitbitConnectLaunchFailed =>
      'Could not open the Fitbit sign-in page.';

  @override
  String get fitbitConnectAuthRequired =>
      'Sign in to Grinta to connect Fitbit.';

  @override
  String get fitbitDisconnectFailed => 'Fitbit disconnect failed.';

  @override
  String get fitbitCoachVisibilityTitle => 'Coach visibility';

  @override
  String get fitbitCoachVisibilitySubtitle =>
      'Allow your coach to see this data type';

  @override
  String get fitbitCoachVisibilitySaveFailed =>
      'Could not save Fitbit preferences.';

  @override
  String get fitbitMetricActivity => 'Activity / workouts / steps';

  @override
  String get fitbitMetricHeartrate => 'Heart rate';

  @override
  String get fitbitMetricSleep => 'Sleep';

  @override
  String get fitbitMetricProfile => 'Profile';

  @override
  String get fitbitMetricBody => 'Weight / body';

  @override
  String fitbitCoachConnectSubtitle(String playerName) {
    return 'Connect Fitbit for $playerName';
  }

  @override
  String fitbitCoachConnectConnectedSubtitle(String playerName) {
    return 'Fitbit connected for $playerName';
  }

  @override
  String get appleHealthConnectToggleSubtitle =>
      'Connect Apple Fitness to import workouts, heart rate, and active energy from the Health app (iOS only)';

  @override
  String get appleHealthConnectToggleConnectedSubtitle =>
      'Apple Fitness connected — full workout sync coming in Phase 2';

  @override
  String get appleHealthConnectSuccess => 'Apple Fitness connected.';

  @override
  String get appleHealthConnectFailed =>
      'Apple Fitness connection failed. Please try again.';

  @override
  String get appleHealthConnectDenied =>
      'Health access was denied. Enable it in Settings → Health → Data Access & Devices → Grinta.';

  @override
  String get appleHealthConnectAuthRequired =>
      'Sign in to Grinta to connect Apple Fitness.';

  @override
  String get appleHealthIosOnlyMessage =>
      'Apple Fitness is available on iPhone only. Health data is read on-device via Apple HealthKit.';

  @override
  String get appleHealthDisconnectFailed => 'Apple Fitness disconnect failed.';

  @override
  String get appleHealthCoachVisibilityTitle => 'Coach visibility';

  @override
  String get appleHealthCoachVisibilitySubtitle =>
      'Allow your coach to see this data type';

  @override
  String get appleHealthCoachVisibilitySaveFailed =>
      'Could not save Apple Fitness preferences.';

  @override
  String get appleHealthMetricActivity => 'Workouts / activity';

  @override
  String get appleHealthMetricHeartrate => 'Heart rate';

  @override
  String get appleHealthMetricActiveEnergy => 'Active energy';

  @override
  String get appleHealthMetricSleep => 'Sleep';

  @override
  String appleHealthCoachConnectSubtitle(String playerName) {
    return 'Connect Apple Fitness for $playerName';
  }

  @override
  String appleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Apple Fitness connected for $playerName';
  }

  @override
  String get googleHealthConnectToggleSubtitle =>
      'Connect Google Health to import workouts, heart rate, and active energy from Health Connect (Android only)';

  @override
  String get googleHealthConnectToggleConnectedSubtitle =>
      'Google Health connected — workout sync available';

  @override
  String get googleHealthConnectSuccess => 'Google Health connected.';

  @override
  String get googleHealthConnectFailed =>
      'Google Health connection failed. Please try again.';

  @override
  String get googleHealthConnectDenied =>
      'Health Connect access was denied. Enable it in Health Connect → App permissions → Grinta.';

  @override
  String get googleHealthConnectAuthRequired =>
      'Sign in to Grinta to connect Google Health.';

  @override
  String get googleHealthAndroidOnlyMessage =>
      'Google Health is available on Android only (on-device via Health Connect). On iPhone, use Apple Fitness.';

  @override
  String get googleHealthDisconnectFailed => 'Google Health disconnect failed.';

  @override
  String get googleHealthCoachVisibilityTitle => 'Coach visibility';

  @override
  String get googleHealthCoachVisibilitySubtitle =>
      'Allow your coach to see this data type';

  @override
  String get googleHealthCoachVisibilitySaveFailed =>
      'Could not save Google Health preferences.';

  @override
  String get googleHealthMetricActivity => 'Workouts / activity';

  @override
  String get googleHealthMetricHeartrate => 'Heart rate';

  @override
  String get googleHealthMetricActiveEnergy => 'Active energy';

  @override
  String get googleHealthMetricSleep => 'Sleep';

  @override
  String googleHealthCoachConnectSubtitle(String playerName) {
    return 'Connect Google Health for $playerName';
  }

  @override
  String googleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Google Health connected for $playerName';
  }

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
  String get trainingDeleteRecurrentTitle => 'Delete recurring training?';

  @override
  String get trainingDeleteRecurrentMessage =>
      'Do you want to delete all occurrences in this series?';

  @override
  String get trainingDeleteThisOccurrence => 'This occurrence only';

  @override
  String get trainingDeleteAllOccurrences => 'All occurrences';

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
      'Do you want to finish this training?';

  @override
  String get trainingFinished => 'Training finished';

  @override
  String get trainingFinishError =>
      'Could not finish the training. Please try again.';

  @override
  String get trainingIntenseFinishTitle => 'Recovering sensor data';

  @override
  String get trainingIntenseFinishMessage =>
      'Recovering data for present players with an assigned tracker. Do not close this window.';

  @override
  String get trainingIntenseResyncButton => 'Re sync';

  @override
  String get trainingIntenseResyncTitle => 'Re-sync sensor data';

  @override
  String get trainingIntenseResyncMessage =>
      'Re-fetching tracker data for the full training window (start → end). Do not close this window.';

  @override
  String get trainingIntenseResyncSuccess => 'Sensor data re-synced.';

  @override
  String get trainingIntenseFinishSyncing => 'Sync in progress…';

  @override
  String get trainingIntenseFinishStagePending => 'Pending';

  @override
  String get trainingIntenseFinishStageFetching => 'Fetching raw data…';

  @override
  String get trainingIntenseFinishStageConverting => 'Converting data…';

  @override
  String get trainingIntenseFinishStageAnalyzing => 'Analyzing…';

  @override
  String get trainingIntenseFinishStageDone => 'Done';

  @override
  String get trainingIntenseFinishStageError => 'Error';

  @override
  String get trainingIntenseFinishNoTrackers =>
      'No present player has an assigned tracker. You can finish the training without recovery.';

  @override
  String get trainingIntenseFinishPartialError =>
      'Some recoveries failed. Fix the issue and retry.';

  @override
  String get intenseLiveTitle => 'Live';

  @override
  String get intenseLiveOpenTooltip => 'View live tracker data';

  @override
  String get intenseLiveSelectPlayer => 'Select a player';

  @override
  String get intenseLiveNoPlayers =>
      'No present player with an assigned tracker';

  @override
  String get intenseLiveRefresh => 'Refresh';

  @override
  String intenseLiveLastUpdate(String time) {
    return 'Updated at $time';
  }

  @override
  String get tabLive => 'Live';

  @override
  String get tabLiveShort => 'Live';

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
  String get createMatchSelectField => 'Club field';

  @override
  String get createMatchFieldNotGeolocatedTitle => 'Field not geolocated';

  @override
  String get createMatchFieldNotGeolocatedMessage =>
      'This field is not geolocated. Would you like to do it now? This is required to generate heatmaps.';

  @override
  String get createMatchSurface => 'Playing surface';

  @override
  String get createMatchSurfaceSynthetic => 'Artificial turf';

  @override
  String get createMatchSurfaceNatural => 'Natural grass';

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

  @override
  String get askDiegoTitle => 'Ask Gio';

  @override
  String get askDiegoWelcome =>
      'Hi! I\'m Gio. I can help with your schedule, next opponent, or team statistics. Ask a question or use the microphone.';

  @override
  String get askDiegoInputHint => 'Ask Gio…';

  @override
  String get askDiegoSend => 'Send';

  @override
  String get askDiegoListen => 'Listen to response';

  @override
  String get askDiegoOpenScreen => 'Open';

  @override
  String get askDiegoOpenOpponentStats => 'View opponent stats';

  @override
  String get askDiegoStartListening => 'Dictate a question';

  @override
  String get askDiegoStopListening => 'Stop listening';

  @override
  String get askDiegoSpeechUnavailable =>
      'Speech recognition is not available on this device.';

  @override
  String get askDiegoSpeechPermissionDenied =>
      'Microphone or speech recognition permission denied. Enable it in Settings.';

  @override
  String askDiegoSpeechError(String reason) {
    return 'Speech recognition failed: $reason';
  }

  @override
  String get askDiegoEmptyResponse => 'I don\'t have an answer right now.';

  @override
  String get askDiegoCloseSpeedDial => 'Close';

  @override
  String askDiegoNavigationUnknown(String route) {
    return 'Unknown navigation: $route';
  }

  @override
  String get askDiegoNavigationAgendaHint =>
      'Open the Agenda tab to view your calendar.';

  @override
  String get askDiegoNavigationMatchMissing =>
      'Match id missing for navigation.';

  @override
  String get askDiegoNavigationMatchNotFound => 'Match not found.';

  @override
  String get askDiegoNavigationNoTeam => 'No team selected.';

  @override
  String get askDiegoNavigationOpponentsManagerOnly =>
      'Opponent statistics are for coaches only.';

  @override
  String get askDiegoNavigationOpponentsPremiumOnly =>
      'Opponent statistics require a subscription.';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsRemindersSubtitle =>
      'Local reminders for training and matches.';

  @override
  String get settingsRemindersEnabled => 'Enable reminders';

  @override
  String get settingsQuietDaysLabel => 'Quiet days';

  @override
  String get settingsQuietHoursLabel => 'Quiet hours';

  @override
  String get settingsQuietHoursStart => 'Start';

  @override
  String get settingsQuietHoursEnd => 'End';

  @override
  String get settingsMorningReminderHour => 'Morning reminder time';

  @override
  String get reminderWeekdayMon => 'Mon';

  @override
  String get reminderWeekdayTue => 'Tue';

  @override
  String get reminderWeekdayWed => 'Wed';

  @override
  String get reminderWeekdayThu => 'Thu';

  @override
  String get reminderWeekdayFri => 'Fri';

  @override
  String get reminderWeekdaySat => 'Sat';

  @override
  String get reminderWeekdaySun => 'Sun';

  @override
  String get reminderTrainingTitle => 'Training today';

  @override
  String reminderTrainingBody(String time) {
    return 'Training today at $time — tell your coach if you are absent';
  }

  @override
  String get reminderMatchOpponentStatsTitle => 'Match today';

  @override
  String reminderMatchOpponentStatsBody(String time, String opponent) {
    return 'Today at $time you play $opponent — discover their stats';
  }

  @override
  String get trainingPresenceConfirmPresent => 'I will attend';

  @override
  String get trainingPresenceConfirmAbsent => 'I will be absent';

  @override
  String get trainingPresenceConfirmedPresent => 'Attendance confirmed';

  @override
  String get trainingPresenceConfirmedAbsent => 'Absence reported';

  @override
  String get matchDetailOpponentStats => 'Opponent stats';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle => 'Platform administration tools.';

  @override
  String get adminPromoCodesSection => 'Promo codes';

  @override
  String get adminPromoCodesSectionDesc =>
      'Create and manage subscription promo codes.';

  @override
  String get adminPromoCodesTitle => 'Promo codes';

  @override
  String get adminPromoCodeCreate => 'Create code';

  @override
  String get adminPromoCodesLoadError => 'Unable to load promo codes.';

  @override
  String get adminPromoCodesEmpty => 'No promo codes yet.';

  @override
  String get adminPromoCodeUpdateFailed => 'Unable to update promo code.';

  @override
  String get adminPromoCodeCreated => 'Promo code created.';

  @override
  String adminPromoCodeEntitlementLabel(String entitlement) {
    return 'Entitlement: $entitlement';
  }

  @override
  String adminPromoCodeUsageLabel(int used, int max) {
    return 'Uses: $used / $max';
  }

  @override
  String adminPromoCodeDurationLabel(int days) {
    return 'Duration: $days days';
  }

  @override
  String adminPromoCodeTeamLabel(String teamId) {
    return 'Club: $teamId';
  }

  @override
  String adminPromoCodeExpiresLabel(String date) {
    return 'Expires: $date';
  }

  @override
  String get adminPromoCodeStatusInactive => 'Inactive';

  @override
  String get adminPromoCodeStatusExpired => 'Expired';

  @override
  String get adminPromoCodeStatusExhausted => 'Exhausted';

  @override
  String get adminPromoCodeStatusActive => 'Active';

  @override
  String get adminPromoCodeFieldCode => 'Code';

  @override
  String get adminPromoCodeFieldCodeInvalid =>
      'Code must be at least 4 characters.';

  @override
  String get adminPromoCodeFieldEntitlement => 'Entitlement';

  @override
  String get adminPromoCodeFieldMaxUses => 'Maximum uses';

  @override
  String get adminPromoCodeFieldMaxUsesInvalid =>
      'Enter a number greater than 0.';

  @override
  String get adminPromoCodeFieldDurationDays => 'Subscription duration (days)';

  @override
  String get adminPromoCodeFieldDurationDaysInvalid =>
      'Enter a number greater than 0.';

  @override
  String get adminPromoCodeFieldTeamId => 'Club ID (optional)';

  @override
  String get adminPromoCodeFieldTeamIdHint =>
      'Restrict redemption to members of this club.';

  @override
  String get adminPromoCodeFieldExpiresOptional => 'Set expiry date (optional)';

  @override
  String get adminPromoCodeAlreadyExists => 'This promo code already exists.';

  @override
  String get adminPromoCodeCreateFailed => 'Unable to create promo code.';

  @override
  String get adminPromoCodePermissionDenied =>
      'Admin access is required to manage promo codes.';

  @override
  String get adminPromoCodeAuthRequired =>
      'You must be signed in to create promo codes.';

  @override
  String get adminPromoCodeActions => 'Actions';

  @override
  String get adminPromoCodeEdit => 'Edit';

  @override
  String get adminPromoCodeEditTitle => 'Edit promo code';

  @override
  String get adminPromoCodeDelete => 'Delete';

  @override
  String get adminPromoCodeDeleteConfirmTitle => 'Delete promo code?';

  @override
  String adminPromoCodeDeleteConfirmMessage(String code) {
    return 'Do you really want to delete code $code? This action is permanent.';
  }

  @override
  String get adminPromoCodeDeleted => 'Promo code deleted.';

  @override
  String get adminPromoCodeDeleteFailed => 'Unable to delete promo code.';

  @override
  String get adminPromoCodeUpdated => 'Promo code updated.';

  @override
  String get adminPromoCodeSave => 'Save';

  @override
  String get adminPromoCodeFieldCodeReadOnly => 'The code cannot be changed.';

  @override
  String adminPromoCodeFieldMaxUsesBelowUsed(int used) {
    return 'Maximum uses must be at least $used (already redeemed).';
  }

  @override
  String get adminPromoCodeFieldActive => 'Active';

  @override
  String get adminPromoCodeClearExpiry => 'Remove expiry date';

  @override
  String get adminPromoCodeNotFound => 'Promo code not found.';

  @override
  String get adminTrackerOwnersSection => 'Tracker owners';

  @override
  String get adminTrackerOwnersSectionDesc =>
      'Create and manage tracker owners.';

  @override
  String get adminTrackerOwnersTitle => 'Tracker owners';

  @override
  String get adminTrackerOwnersEmpty => 'No tracker owners yet.';

  @override
  String get adminTrackerOwnersLoadError => 'Unable to load tracker owners.';

  @override
  String get adminTrackerOwnerCreate => 'Add owner';

  @override
  String get adminTrackerOwnerCreateTitle => 'Add owner';

  @override
  String get adminTrackerOwnerEditTitle => 'Edit owner';

  @override
  String get adminTrackerOwnerFieldName => 'Name';

  @override
  String get adminTrackerOwnerFieldEmail => 'Email';

  @override
  String get adminTrackerOwnerFieldFirstname => 'First name';

  @override
  String get adminTrackerOwnerFieldLastname => 'Last name';

  @override
  String get adminTrackerOwnerFieldActive => 'Active';

  @override
  String get adminTrackerOwnerFieldIndividual => 'Individual owner';

  @override
  String get adminTrackerOwnerFieldIndividualHint =>
      'Enable if this owner is a person (not a club / team).';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Tracker type';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, cloud stream)';

  @override
  String get adminTrackerOwnerTypePolar => 'Polar (BLE team kit)';

  @override
  String get adminTrackerOwnerFieldRequired => 'Required field';

  @override
  String get adminTrackerOwnerFieldEmailInvalid => 'Invalid email';

  @override
  String get adminTrackerOwnerStatusActive => 'Active';

  @override
  String get adminTrackerOwnerStatusInactive => 'Inactive';

  @override
  String get adminTrackerOwnerSave => 'Save';

  @override
  String get adminTrackerOwnerDelete => 'Delete';

  @override
  String get adminTrackerOwnerDeleteConfirmTitle => 'Delete owner?';

  @override
  String adminTrackerOwnerDeleteConfirmMessage(String name) {
    return 'Do you really want to delete $name? This action is permanent.';
  }

  @override
  String get adminTrackerOwnerCreated => 'Owner created.';

  @override
  String get adminTrackerOwnerUpdated => 'Owner updated.';

  @override
  String get adminTrackerOwnerDeleted => 'Owner deleted.';

  @override
  String get adminTrackerOwnerSaveFailed => 'Unable to save owner.';

  @override
  String get adminTrackerOwnerDeleteFailed => 'Unable to delete owner.';

  @override
  String get adminTrackerOwnerPermissionDenied =>
      'Admin access is required to manage tracker owners.';

  @override
  String get adminTrackerDevicesSection => 'Tracker management';

  @override
  String get adminTrackerDevicesSectionDesc =>
      'Sync, assign and manage tracker devices.';

  @override
  String get adminTrackerFieldsSection => 'Field management';

  @override
  String get adminTrackerFieldsSectionDesc =>
      'Trace and save pitch GPS corners for heatmaps.';

  @override
  String get adminTrackerFieldsTitle => 'Fields';

  @override
  String get adminTrackerFieldsEmpty => 'No fields for this club.';

  @override
  String get adminTrackerFieldsLoadError => 'Unable to load fields.';

  @override
  String get adminTrackerFieldsCreate => 'New field';

  @override
  String get adminTrackerFieldsSaved => 'Field saved.';

  @override
  String get adminTrackerFieldsSaveFailed => 'Unable to save the field.';

  @override
  String get adminTrackerFieldsAuthRequired => 'Sign in to save a field.';

  @override
  String get adminTrackerFieldsSelectClubFirst =>
      'Select a club to show its fields.';

  @override
  String get adminTrackerFieldsChangeClub => 'Change club';

  @override
  String get adminTrackerFieldsGpsReady => 'GPS ready';

  @override
  String get adminTrackerFieldsGpsMissing => 'GPS missing';

  @override
  String get adminTrackerFieldsDeleteConfirmTitle => 'Delete field?';

  @override
  String adminTrackerFieldsDeleteConfirmMessage(String fieldName) {
    return 'Are you sure you want to delete \"$fieldName\"? This action is permanent.';
  }

  @override
  String get adminTrackerFieldsDeleted => 'Field deleted.';

  @override
  String get adminTrackerFieldsDeleteFailed => 'Unable to delete the field.';

  @override
  String get adminTrackerDevicesTitle => 'Tracker management';

  @override
  String get adminTrackerDevicesManageAction => 'Tracker management';

  @override
  String get adminTrackerDevicesShowUnassigned => 'Show unassigned devices';

  @override
  String get adminTrackerDevicesSelectOwner => 'Select an owner';

  @override
  String get adminTrackerDevicesResetFilter => 'Reset';

  @override
  String get adminTrackerDevicesEmpty => 'No devices';

  @override
  String get adminTrackerDevicesEmptySubtitle =>
      'No documents in TRACKER_Device.';

  @override
  String get adminTrackerDevicesLoadError => 'Unable to load devices.';

  @override
  String adminTrackerDevicesSource(String provider) {
    return 'Source: $provider';
  }

  @override
  String adminTrackerDevicesSerial(String serial) {
    return 'Serial: $serial';
  }

  @override
  String adminTrackerDevicesUpdatedAt(String date) {
    return 'Updated: $date';
  }

  @override
  String get adminTrackerDevicesStatusActive => 'Active';

  @override
  String get adminTrackerDevicesStatusInactive => 'Inactive';

  @override
  String get adminTrackerDevicesAssign => 'Assign';

  @override
  String get adminTrackerDevicesUnassign => 'Unassign';

  @override
  String get adminTrackerDevicesAssignTitle => 'Assign a device';

  @override
  String get adminTrackerDevicesCustomName => 'Custom name (optional)';

  @override
  String get adminTrackerDevicesCustomNameHint =>
      'Jersey number or label, e.g. 7';

  @override
  String get adminTrackerDevicesCancel => 'Cancel';

  @override
  String get adminTrackerDevicesValidate => 'Confirm';

  @override
  String get adminTrackerDevicesSelectOwnerRequired =>
      'Please select an owner.';

  @override
  String get adminTrackerDevicesAssignSuccess => 'Assignment saved.';

  @override
  String get adminTrackerDevicesUnassignSuccess => 'Device unassigned.';

  @override
  String adminTrackerDevicesError(String error) {
    return 'Error: $error';
  }

  @override
  String get adminTrackerDevicesSyncInspirit => 'Sync Inspirit';

  @override
  String get adminTrackerDevicesSyncFootbar => 'Sync Footbar';

  @override
  String get adminTrackerDevicesAddPolar => 'Add Polar';

  @override
  String get adminTrackerDevicesAddPolarChrome => 'Add via Chrome Bluetooth';

  @override
  String get adminTrackerDevicesAddPolarManual => 'Enter ID manually';

  @override
  String get adminPolarBleScanTitle => 'Scan Polar sensors';

  @override
  String get adminPolarBleScanSheetSubtitle =>
      'List nearby Polar devices and connect one by one';

  @override
  String get adminPolarBleScanHint =>
      'Turn on the sensors nearby, then connect each one and add it to the kit with a custom name.';

  @override
  String get adminPolarBleScanSearching => 'Searching for Polar sensors…';

  @override
  String get adminPolarBleScanEmpty =>
      'No Polar sensor found. Check Bluetooth and that the sensors are on.';

  @override
  String get adminPolarBleScanUnsupported =>
      'Polar BLE scan is only available on iOS and Android.';

  @override
  String get adminPolarBleScanConnect => 'Connect';

  @override
  String get adminPolarBleScanConnecting => 'Connecting…';

  @override
  String get adminPolarBleScanConnected => 'Connected';

  @override
  String get adminPolarBleScanAddToKit => 'Add to kit';

  @override
  String get adminPolarBleScanStop => 'Stop scan';

  @override
  String get adminPolarBleScanRestart => 'Scan again';

  @override
  String adminPolarBleScanConnectError(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get polarImportTitle => 'Polar import (cardio)';

  @override
  String get polarImportSensorsHeader => 'Session Polar sensors';

  @override
  String get polarImportHint =>
      'Quit Polar Flow, put the Verity Sense in sensor mode (blue LED / optical heart), then import over Bluetooth. If iOS already shows the sensor as Connected, forget it in Settings → Bluetooth.';

  @override
  String get polarImportSelectSensor =>
      'Select a sensor to import cardio data.';

  @override
  String get polarImportStatusPending => 'To import';

  @override
  String get polarImportStatusDone => 'Imported';

  @override
  String get polarImportUntitledPlayer => 'Player';

  @override
  String polarImportDeviceLine(
      String deviceId, String deviceType, String customName) {
    return 'Polar $deviceId · $deviceType · $customName';
  }

  @override
  String get polarImportBleAction => 'Import via Bluetooth';

  @override
  String get polarImportBleUnavailable =>
      'Polar Bluetooth import is available on iOS/Android. On the web, use manual entry.';

  @override
  String get polarImportManualAction => 'Manual entry';

  @override
  String get polarImportManualTitle => 'Polar cardio entry';

  @override
  String get polarImportManualSubtitle =>
      'Enter duration and HR (calories / steps optional for Loop).';

  @override
  String get polarImportFieldDurationMin => 'Duration (minutes)';

  @override
  String get polarImportFieldAvgHr => 'Avg HR (bpm)';

  @override
  String get polarImportFieldMaxHr => 'Max HR (bpm)';

  @override
  String get polarImportFieldMinHr => 'Min HR (bpm)';

  @override
  String get polarImportFieldCalories => 'Calories (kcal, optional)';

  @override
  String get polarImportFieldDistanceM => 'Distance (m, optional)';

  @override
  String get polarImportFieldSteps => 'Steps (optional)';

  @override
  String get polarImportMissingPlayer => 'No player linked to this sensor.';

  @override
  String polarImportSuccess(String avgHr, String minutes) {
    return 'Import OK — avg HR $avgHr · $minutes min';
  }

  @override
  String get polarImportBleTimeoutHint =>
      'Polar BLE connection timed out. Quit Polar Flow, forget the sensor in Settings → Bluetooth if it stays Connected, wake the Verity Sense in sensor mode (blue LED), then retry.';

  @override
  String polarImportBleError(String error) {
    return 'Polar import failed: $error';
  }

  @override
  String get polarAnalysisEmptyMessage =>
      'No Polar cardio analysis for this player on this session.';

  @override
  String get polarAnalysisEmptyTeamMessage =>
      'No Polar cardio analysis imported for this session. Import sensors from Sync.';

  @override
  String get polarAnalysisTeamTitle => 'Polar cardio analysis';

  @override
  String polarAnalysisTeamCount(int count) {
    return '$count player(s)';
  }

  @override
  String get polarAnalysisColDevice => 'Sensor';

  @override
  String get polarAnalysisColHighIntensity => 'Z4+Z5';

  @override
  String polarAnalysisDeviceLine(String deviceId, String deviceType) {
    return 'Polar $deviceId · $deviceType';
  }

  @override
  String get polarAnalysisHrZonesTab => 'HR zones';

  @override
  String get polarAnalysisDuration => 'Duration';

  @override
  String polarAnalysisDurationDetail(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get polarAnalysisAvgHr => 'Avg HR';

  @override
  String get polarAnalysisMaxHr => 'Max HR';

  @override
  String get polarAnalysisMinHr => 'Min HR';

  @override
  String get polarAnalysisSamples => 'Samples';

  @override
  String get polarAnalysisCalories => 'Calories';

  @override
  String get polarAnalysisSteps => 'Steps';

  @override
  String get polarAnalysisUnitMin => 'min';

  @override
  String get polarAnalysisUnitBpm => 'bpm';

  @override
  String get polarAnalysisUnitKcal => 'kcal';

  @override
  String polarAnalysisZoneLabel(String zone) {
    return '$zone';
  }

  @override
  String get polarAnalysisNoZones => 'No zone breakdown for this import.';

  @override
  String get polarAnalysisTrainingZonesTitle => 'Training zones';

  @override
  String polarAnalysisHrTimelineHint(int minutes) {
    return 'Average synthesis every $minutes min';
  }

  @override
  String get polarAnalysisHrTimelineEmpty =>
      'HR curve unavailable — re-import the sensor to generate the 5-min synthesis.';

  @override
  String get polarAnalysisAxisPercent => '%';

  @override
  String get polarImportMissingSeason =>
      'Season not found to import Polar sensors.';

  @override
  String get polarImportAgendaAction => 'Import Polar data';

  @override
  String get polarAnalysisAgendaAction => 'View Polar analysis';

  @override
  String get adminTrackerDevicesAddPolarTitle => 'Add a Polar sensor';

  @override
  String get adminTrackerDevicesAddPolarDeviceId => 'Polar device ID';

  @override
  String get adminTrackerDevicesAddPolarDeviceIdHint =>
      'Printed on the sensor, or last part of BLE name (e.g. Polar H10 1C709B20 → 1C709B20)';

  @override
  String get adminTrackerDevicesAddPolarChromeUnsupported =>
      'Web Bluetooth requires Chrome (HTTPS or localhost).';

  @override
  String get adminTrackerDevicesAddPolarChromeCancelled =>
      'Bluetooth selection cancelled.';

  @override
  String get adminTrackerDevicesAddPolarChromeNoId =>
      'Could not read the Polar ID from the BLE name. Enter the ID printed on the sensor.';

  @override
  String adminTrackerDevicesAddPolarChromeSuccess(
      String deviceId, String deviceType) {
    return 'Polar $deviceId ($deviceType) added.';
  }

  @override
  String get adminTrackerDevicesAddPolarDeviceType => 'Sensor type';

  @override
  String get adminTrackerDevicesAddPolarDeviceName => 'Display name (optional)';

  @override
  String get adminTrackerDevicesAddPolarSuccess =>
      'Polar sensor added to inventory.';

  @override
  String get adminTrackerDevicesAddPolarDeviceIdRequired =>
      'Polar device ID is required.';

  @override
  String get adminTrackerDevicesPolarTypeH10 => 'H10';

  @override
  String get adminTrackerDevicesPolarTypeH9 => 'H9';

  @override
  String get adminTrackerDevicesPolarTypeVeritySense => 'Verity Sense';

  @override
  String get adminTrackerDevicesPolarTypeOh1 => 'OH1';

  @override
  String get adminTrackerDevicesPolarTypeOther => 'Other';

  @override
  String get adminTrackerDevicesSyncInProgress => 'Syncing...';

  @override
  String get adminTrackerDevicesSyncInspiritInProgress =>
      'Inspirit sync (insiders) in progress...';

  @override
  String get adminTrackerDevicesSyncFootbarInProgress =>
      'Footbar sync in progress...';

  @override
  String adminTrackerDevicesSyncInspiritSuccess(int count) {
    return 'Inspirit sync: $count device(s) updated.';
  }

  @override
  String adminTrackerDevicesSyncInspiritError(String error) {
    return 'Inspirit sync error: $error';
  }

  @override
  String get adminTrackerDevicesPermissionDenied =>
      'Admin access is required to manage devices.';

  @override
  String get adminStreamGroupsSection => 'Messaging - Groups';

  @override
  String get adminStreamGroupsSectionDesc =>
      'List and delete GetStream team chat groups.';

  @override
  String get adminStreamGroupsTitle => 'Messaging - Groups';

  @override
  String get adminStreamGroupsEmpty => 'No chat groups';

  @override
  String get adminStreamGroupsEmptySubtitle =>
      'No team channels found on GetStream.';

  @override
  String get adminStreamGroupsLoadError => 'Unable to load chat groups.';

  @override
  String get adminStreamGroupsRefresh => 'Refresh';

  @override
  String adminStreamGroupsCid(String cid) {
    return 'CID: $cid';
  }

  @override
  String adminStreamGroupsMemberCount(int count) {
    return '$count members';
  }

  @override
  String adminStreamGroupsLastMessageAt(String date) {
    return 'Last message: $date';
  }

  @override
  String get adminStreamGroupsDelete => 'Delete';

  @override
  String get adminStreamGroupsCancel => 'Cancel';

  @override
  String get adminStreamGroupsDeleteConfirmTitle => 'Delete group?';

  @override
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid) {
    return 'Do you really want to delete group $name ($cid)? This action is permanent.';
  }

  @override
  String get adminStreamGroupsDeleted => 'Group deleted.';

  @override
  String get adminStreamGroupsDeleteFailed => 'Unable to delete group.';

  @override
  String get adminStreamGroupsPermissionDenied =>
      'Admin access is required to manage chat groups.';

  @override
  String get adminSeasonsSection => 'Seasons';

  @override
  String get adminSeasonsSectionDesc => 'List and manage platform seasons.';

  @override
  String get adminSeasonsTitle => 'Seasons';

  @override
  String get adminSeasonsEmpty => 'No seasons yet.';

  @override
  String get adminSeasonsLoadError => 'Unable to load seasons.';

  @override
  String get adminSeasonCreate => 'Add season';

  @override
  String get adminSeasonEditTitle => 'Edit season';

  @override
  String get adminSeasonCreated => 'Season created.';

  @override
  String get adminSeasonUpdated => 'Season updated.';

  @override
  String get adminSeasonCreateFailed => 'Unable to create season.';

  @override
  String get adminSeasonUpdateFailed => 'Unable to update season.';

  @override
  String get adminSeasonUnnamed => 'Unnamed season';

  @override
  String get adminSeasonCurrentBadge => 'Current';

  @override
  String get adminSeasonNewVersionBadge => 'New version';

  @override
  String adminSeasonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String adminSeasonClubLabel(String clubName) {
    return 'Club: $clubName';
  }

  @override
  String adminSeasonAffiliateLabel(String number) {
    return 'Affiliate no.: $number';
  }

  @override
  String get adminSeasonFieldName => 'Name';

  @override
  String get adminSeasonFieldNameReadOnly =>
      'Season name cannot be changed after creation.';

  @override
  String get adminSeasonFieldRequired => 'This field is required.';

  @override
  String get adminSeasonFieldStartDate => 'Start date';

  @override
  String get adminSeasonFieldEndDate => 'End date';

  @override
  String adminSeasonDateSelected(String date) {
    return 'Selected: $date';
  }

  @override
  String get adminSeasonFieldClubName => 'Club name';

  @override
  String get adminSeasonFieldAffiliateNumber => 'Affiliate number';

  @override
  String get adminSeasonFieldCurrent => 'Current season';

  @override
  String get adminSeasonFieldCurrentHint =>
      'Only one season can be current at a time.';

  @override
  String get adminSeasonFieldNewVersion => 'New version';

  @override
  String get adminSeasonChangeDefaultTitle => 'Change current season?';

  @override
  String adminSeasonChangeDefaultMessage(String seasonName) {
    return '\"$seasonName\" is currently the default season. Do you want to replace it?';
  }

  @override
  String get adminSeasonChangeDefaultConfirm => 'Change default';

  @override
  String get promoCodeMenuLabel => 'Promo code';

  @override
  String get promoCodeDialogValidate => 'Validate';

  @override
  String get promoCodeRedeemTitle => 'Have a promo code?';

  @override
  String get promoCodeRedeemHint => 'Enter your code';

  @override
  String get promoCodeRedeemAction => 'Redeem';

  @override
  String get promoCodeRedeemEmpty => 'Please enter a promo code.';

  @override
  String promoCodeRedeemSuccess(int days, String entitlement) {
    return 'Promo code applied: $days days of $entitlement.';
  }

  @override
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days) {
    return '$entitlement active until $expiresAt ($days days granted).';
  }

  @override
  String get promoCodeRedeemSyncPending =>
      'Code registered on the server, but the subscription is not visible yet. Open Settings → Subscription in a moment, or sign out and back in.';

  @override
  String get promoCodeRedeemRcUnavailable =>
      'Code registered on the server, but RevenueCat is not configured on this device (check API keys). Try on iOS or web, or relaunch with dart_defines.json.';

  @override
  String get promoCodeRedeemNotFound => 'Promo code not found.';

  @override
  String get promoCodeRedeemInvalid => 'This promo code is no longer valid.';

  @override
  String get promoCodeRedeemInactive => 'This promo code is inactive.';

  @override
  String get promoCodeRedeemExpired => 'This promo code has expired.';

  @override
  String get promoCodeRedeemAlreadyRedeemed =>
      'You have already redeemed this promo code.';

  @override
  String get promoCodeRedeemExhausted =>
      'This promo code has reached its usage limit.';

  @override
  String get promoCodeRedeemTeamMismatch =>
      'This promo code is reserved for another club.';

  @override
  String get promoCodeRedeemUnauthenticated =>
      'You must be signed in to redeem a promo code.';

  @override
  String get promoCodeRedeemFailed => 'Unable to redeem promo code.';

  @override
  String get playerFeelingPrompt => 'How do you feel?';

  @override
  String get playerFeelingNotifTitle => 'Session recap';

  @override
  String get playerFeelingNotifBody =>
      'Check your stats and tell us how you feel.';

  @override
  String get playerFeelingRecapTitle => 'Your recap';

  @override
  String get playerFeelingRecapSubtitle => 'Your session data';

  @override
  String get playerFeelingSubmitAction => 'Submit';

  @override
  String get playerFeelingUpdateAction => 'Update';

  @override
  String get playerFeelingSaved => 'Thanks, your feeling was saved.';

  @override
  String get playerFeelingSaveError => 'Unable to save your feeling.';

  @override
  String get playerFeelingLoadError => 'Could not load the recap.';

  @override
  String get sessionHealthExportPromptTitle => 'Export session';

  @override
  String get sessionHealthExportPromptApple =>
      'Would you like to see this data in Apple Fitness?';

  @override
  String get sessionHealthExportPromptGoogle =>
      'Would you like to see this data in Google Health?';

  @override
  String get sessionHealthExportSuccessApple =>
      'Session added to Apple Fitness.';

  @override
  String get sessionHealthExportSuccessGoogle =>
      'Session added to Google Health.';

  @override
  String get sessionHealthExportFailed =>
      'Could not export the session. Please try again.';

  @override
  String get sessionHealthExportConnectFailed =>
      'Could not connect Health. Check permissions and try again.';

  @override
  String get sessionHealthExportTitleMatch => 'Grinta match';

  @override
  String get sessionHealthExportTitleTraining => 'Grinta training';

  @override
  String get forgotPasswordTitle => 'Forgotten password';

  @override
  String get forgotPasswordMessage =>
      'Enter the email address for your account. We will send you a link to reset your password.';

  @override
  String get forgotPasswordSendAction => 'Send link';

  @override
  String get forgotPasswordSent => 'A password reset email has been sent.';

  @override
  String get forgotPasswordFailed => 'Unable to send the password reset email.';

  @override
  String get pendingInvitationNotificationTitle => 'Pending invitation';

  @override
  String pendingInvitationNotificationBody(String teamName) {
    return 'Your coach invited you to $teamName. Enter the code from the email to join the team.';
  }

  @override
  String get pendingInvitationAcceptTitle => 'Invitation code';

  @override
  String get pendingInvitationAcceptMessage =>
      'Enter the code from the email to link this invitation to your account.';

  @override
  String get pendingInvitationAcceptSuccess =>
      'Invitation accepted. The team is now available in your profile.';

  @override
  String get pendingInvitationAcceptNeedAuth =>
      'Sign in to accept this invitation.';

  @override
  String get playerSeasonSummaryTitle => 'Player sheet';

  @override
  String get playerSeasonSummaryTabUnavailabilities => 'Unavailabilities';

  @override
  String get playerSeasonSummaryTeamMatches => 'Team matches';

  @override
  String get playerSeasonSummaryTeamTrainings => 'Team trainings';

  @override
  String get playerSeasonSummaryTrackerAverages =>
      'Performance indicators (average)';

  @override
  String get playerSeasonSummaryNoTrackerData =>
      'No sensor data for this period';

  @override
  String playerSeasonSummaryAgeValue(int age) {
    return '$age yrs';
  }

  @override
  String playerSeasonSummaryHwMeasuredAt(String date) {
    return 'Measurements on $date';
  }

  @override
  String get preferredFootLabel => 'Preferred foot';

  @override
  String get preferredFootHint => 'Select preferred foot';

  @override
  String get preferredFootUnspecified => 'Not set';

  @override
  String get preferredFootLeft => 'Left';

  @override
  String get preferredFootRight => 'Right';

  @override
  String get preferredFootBoth => 'Both';

  @override
  String get playerSeasonSummaryPreferredFootSaved => 'Preferred foot updated.';

  @override
  String get wearableDeviceGpsInsidersIntense => 'GPS Insiders Intense';

  @override
  String get intenseGpsSerialGuidance =>
      'Enter the serial number printed on the GPS Insiders Intense tracker.';

  @override
  String get intenseGpsSerialLabel => 'Serial number';

  @override
  String get intenseGpsSerialPlaceholder => 'Serial number';

  @override
  String get intenseGpsSerialRequired =>
      'Enter the serial number before continuing.';

  @override
  String get intenseGpsTrackerNotFound => 'Tracker not found';

  @override
  String get intenseGpsTrackerAlreadyAssigned =>
      'This tracker is already assigned';

  @override
  String get intenseGpsConnectSuccess => 'GPS Insiders Intense tracker linked.';

  @override
  String get intenseGpsConnectFailed =>
      'Could not link the GPS tracker. Please try again.';

  @override
  String get intenseGpsDisconnectFailed => 'GPS tracker disconnect failed.';

  @override
  String get intenseGpsMissingEmail =>
      'The player profile needs an email to link a GPS tracker.';

  @override
  String get intenseGpsConnectToggleConnectedSubtitle =>
      'GPS Insiders Intense connected';

  @override
  String get whoopAnalysisTitle => 'Whoop analysis';

  @override
  String get whoopAnalysisStrain => 'Activity strain';

  @override
  String get whoopAnalysisAvgHr => 'Avg HR';

  @override
  String get whoopAnalysisMaxHr => 'Max HR';

  @override
  String get whoopAnalysisDuration => 'Duration';

  @override
  String get whoopAnalysisCalories => 'Calories';

  @override
  String get whoopAnalysisAltitude => 'Elevation';

  @override
  String get whoopAnalysisHrZonesTitle => 'Heart rate zones';

  @override
  String get whoopAnalysisNoZones =>
      'No zone breakdown for this import. Re-import the Whoop activity.';

  @override
  String whoopAnalysisZoneLabel(int zone) {
    return 'Zone $zone';
  }

  @override
  String whoopAnalysisZoneAboveBpm(int bpm) {
    return '$bpm+ bpm';
  }

  @override
  String whoopAnalysisZoneBpmRange(int min, int max) {
    return '$min – $max bpm';
  }
}
