// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Grinta';

  @override
  String get heroTitle => 'Verwalten Sie Ihre sportliche Aktivität einfach';

  @override
  String get heroSubtitle =>
      'Organisieren Sie Ihre Veranstaltungen, verwalten Sie Ihre Mitglieder und überwachen Sie Ihre Aktivitäten über eine übersichtliche, moderne und reaktionsfähige Oberfläche.';

  @override
  String get loginTitle => 'Verbindung';

  @override
  String get loginSubtitle =>
      'Melden Sie sich an, um auf Ihren Bereich zuzugreifen.';

  @override
  String get email => 'E-Mail-Adresse';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Passwort';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get signIn => 'Einloggen';

  @override
  String get emailAndPasswordRequired => 'E-Mail und Passwort erforderlich';

  @override
  String get signInError => 'Verbindungsfehler';

  @override
  String get userNotFound => 'Für diese E-Mail wurden keine Benutzer gefunden';

  @override
  String get wrongPassword => 'Falsches Passwort';

  @override
  String get invalidEmail => 'Ungültige E-Mail-Adresse';

  @override
  String get invalidCredential => 'Ungültige Bezeichner';

  @override
  String get tooManyRequests =>
      'Zu viele Versuche. Versuchen Sie es später noch einmal';

  @override
  String get userDisabled => 'Dieses Konto wurde deaktiviert';

  @override
  String get unexpectedError => 'Unerwarteter Fehler';

  @override
  String get createAccount => 'Ein Konto erstellen';

  @override
  String get noAccountYet => 'Sie haben noch kein Konto?';

  @override
  String get createOneLink => 'Erstellen Sie eines';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get passwordRequirements =>
      'Das Passwort muss mindestens 8 Zeichen lang sein und einen Großbuchstaben, eine Ziffer und ein Sonderzeichen enthalten.';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get alreadyHaveAccount => 'Sie haben bereits ein Konto?';

  @override
  String get signInLink => 'Einloggen';

  @override
  String get or => 'Oder';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get continueWithApple => 'Weiter mit Apple';

  @override
  String get continueWithMeta => 'Weiter mit Meta';

  @override
  String get hasATeamCode => 'Ich habe einen Teamcode';

  @override
  String get hasInvitationCodeQuestion => 'Haben Sie einen Einladungscode?';

  @override
  String get invitationCode => 'Einladungscode';

  @override
  String get invitationCodeHint => 'Code eingeben';

  @override
  String get invitationNotFound => 'Einladungscode nicht gefunden';

  @override
  String get invitationNotFoundContinuePrompt =>
      'Dieser Code existiert nicht. Möchten Sie fortfahren und Ihr Spielerprofil erstellen?';

  @override
  String get invitationAlreadyUsed =>
      'Dieser Einladungscode wurde bereits verwendet';

  @override
  String invitationSentBy(String firstName, String lastName) {
    return 'Die Einladung wurde Ihnen von $firstName $lastName gesendet';
  }

  @override
  String get signupWithoutInvitationComingSoon =>
      'Funktion demnächst verfügbar';

  @override
  String get emailAlreadyInUse =>
      'Ein Konto mit dieser E-Mail-Adresse existiert bereits';

  @override
  String get invitationCodeRequired =>
      'Bitte geben Sie einen Einladungscode ein und validieren Sie ihn';

  @override
  String get invitationChoiceRequired =>
      'Bitte geben Sie an, ob Sie einen Einladungscode haben';

  @override
  String get memberProfileTitle => 'Ihr Profil';

  @override
  String get memberFirstName => 'Vorname';

  @override
  String get memberLastName => 'Nachname';

  @override
  String get memberEmail => 'E-Mail';

  @override
  String get memberEmailOptional => 'E-Mail (optional)';

  @override
  String get memberPhone => 'Telefon';

  @override
  String get memberPhoneOptional => 'Telefon (optional)';

  @override
  String get memberEmailInvalid =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get memberPhoneInvalid =>
      'Bitte geben Sie eine gültige Telefonnummer ein';

  @override
  String get memberPhoneRequired =>
      'Telefonnummer ist für Spielereinladungen erforderlich';

  @override
  String get memberEmailRequired => 'E-Mail ist für Einladungen erforderlich';

  @override
  String invitationEmailSubject(String appName) {
    return 'Dein Coach lädt dich ein, $appName beizutreten';
  }

  @override
  String invitationEmailIntro(String appName) {
    return 'Dein Coach lädt dich ein, $appName beizutreten';
  }

  @override
  String get invitationEmailCodeLabel => 'Dein Einladungscode';

  @override
  String get invitationEmailDownloadIos => 'Für iPhone herunterladen';

  @override
  String get invitationEmailDownloadAndroid => 'Für Android herunterladen';

  @override
  String invitationEmailFooter(String appName) {
    return 'Du hast diese E-Mail erhalten, weil ein Coach dich auf $appName hinzugefügt hat. Wenn du diese Nachricht nicht erwartet hast, kannst du sie ignorieren.';
  }

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Dein Coach lädt dich ein, $appName beizutreten. Dein Code: $code.\niPhone: $appleStoreUrl\nAndroid: $googlePlayUrl';
  }

  @override
  String get memberInvitationEmailFailed =>
      'Mitglied hinzugefügt, aber die Einladungs-E-Mail konnte nicht gesendet werden.';

  @override
  String get memberAddedToTeamNotificationTitle => 'Team-Update';

  @override
  String memberAddedToTeamNotificationBody(String teamName) {
    return 'Dein Coach hat dich zu $teamName hinzugefügt.';
  }

  @override
  String get invitationAccepted => 'Einladung angenommen';

  @override
  String get invitationPending => 'Einladung ausstehend';

  @override
  String get memberAppAccountLinked => 'App-Konto verknüpft';

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
  String get memberBirthDate => 'Geburtsdatum';

  @override
  String get memberBirthDateOptional => 'Geburtsdatum (optional)';

  @override
  String get memberBirthPlace => 'Geburtsort';

  @override
  String get memberBirthPlaceOptional => 'Geburtsort (optional)';

  @override
  String get memberNationality => 'Nationalität';

  @override
  String get memberNationalityHint => 'Nationalität auswählen';

  @override
  String get memberNationalitySearch => 'Nationalität suchen';

  @override
  String get memberPositions => 'Positionen';

  @override
  String get memberPositionsHint =>
      'Eine oder mehrere Positionen auswählen (optional)';

  @override
  String get memberFirstNameRequired => 'Vorname ist erforderlich';

  @override
  String get memberLastNameRequired => 'Nachname ist erforderlich';

  @override
  String get memberBirthPlaceRequired => 'Geburtsort ist erforderlich';

  @override
  String get memberNationalityRequired => 'Nationalität ist erforderlich';

  @override
  String get memberContactRequired =>
      'Bitte geben Sie mindestens eine E-Mail-Adresse oder Telefonnummer an';

  @override
  String get memberProfileIncomplete => 'Bitte vervollständigen Sie Ihr Profil';

  @override
  String get memberProfileSubmit => 'Mein Profil erstellen';

  @override
  String get memberProfileUpdateSuccess => 'Profil aktualisiert';

  @override
  String memberProfileUpdateError(String error) {
    return 'Profil konnte nicht aktualisiert werden: $error';
  }

  @override
  String get memberProfileChangePhoto => 'Foto ändern';

  @override
  String get memberProfileTakePhoto => 'Foto aufnehmen';

  @override
  String get memberProfileChooseFromGallery => 'Aus Galerie wählen';

  @override
  String memberProfilePhotoUploadError(String error) {
    return 'Foto konnte nicht aktualisiert werden: $error';
  }

  @override
  String get errorEditProfileUnavailable =>
      'Kein Profil zum Bearbeiten verfügbar';

  @override
  String get createTeamPromptQuestion => 'Möchten Sie ein Team erstellen?';

  @override
  String get createTeamPromptLater => 'Später';

  @override
  String get slide1Title => 'Verwalten Sie Ihr Team';

  @override
  String get slide1Subtitle =>
      'Zentralisieren Sie Ihre Mitglieder, Informationen und Organisation in einer einzigen Anwendung.';

  @override
  String get slide2Title => 'Planen Sie Ihre Spiele';

  @override
  String get slide2Subtitle =>
      'Erstellen Sie Ihre Events, rufen Sie Ihre Spieler zusammen und verfolgen Sie ganz einfach die Verfügbarkeit.';

  @override
  String get slide3Title => 'Verfolgen Sie Ihre Leistung';

  @override
  String get slide3Subtitle =>
      'Zeigen Sie Statistiken, Aktivitäten und Ergebnisse über eine übersichtliche Oberfläche an.';

  @override
  String get actionCancel => 'Stornieren';

  @override
  String get actionDelete => 'LÖSCHEN';

  @override
  String get actionRetry => 'Versuchen Sie es erneut';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionOk => 'Okay';

  @override
  String get actionYes => 'Ja';

  @override
  String get actionNo => 'NEIN';

  @override
  String get actionValidate => 'Zur Validierung';

  @override
  String get actionCopy => 'Kopie';

  @override
  String get actionReset => 'Zurücksetzen';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionNew => 'Neu';

  @override
  String get actionChoosePeriod => 'Wählen Sie einen Zeitraum';

  @override
  String get actionWeekPrevious => 'Woche -';

  @override
  String get actionWeekNext => 'Woche +';

  @override
  String get actionLoadBefore => 'Vorwärts laden';

  @override
  String get actionLoadAfter => 'Danach laden';

  @override
  String get actionToday => 'Heute';

  @override
  String get actionEditProfile => 'Profil bearbeiten';

  @override
  String get settingsMyUnavailabilities => 'Meine Abwesenheiten';

  @override
  String get myUnavailabilitiesNoPlayer =>
      'Kein Spielerprofil mit deinem Konto verknüpft.';

  @override
  String get myUnavailabilitiesNoSeason =>
      'Keine Saison ausgewählt. Wähle eine Saison im Kontomenü.';

  @override
  String get actionCreateNewProfile => 'Neues Profil erstellen';

  @override
  String get actionLogout => 'Trennen';

  @override
  String get actionLogoutConfirmTitle => 'Trennen';

  @override
  String get actionLogoutConfirmMessage =>
      'Möchten Sie sich wirklich abmelden?';

  @override
  String get actionCreateTeam => 'Team erstellen';

  @override
  String get teamCreationAttachClubQuestion =>
      'Möchten Sie dieses Team einem Verein zuordnen?';

  @override
  String get teamCreationSelectClub => 'Verein auswählen';

  @override
  String get teamCreationClubRequired => 'Bitte wählen Sie einen Verein aus';

  @override
  String get teamCreationSelectClubTeams => 'Vereinsmannschaften auswählen';

  @override
  String get teamCreationNoClubTeams => 'Keine engagierten Mannschaften';

  @override
  String teamCreationSelectedClubTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mannschaften ausgewählt',
      one: '1 Mannschaft ausgewählt',
      zero: 'Keine Mannschaft ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String teamCreationClubTeamCompetitionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wettbewerbe',
      one: '1 Wettbewerb',
    );
    return '$_temp0';
  }

  @override
  String get teamCreationSoccerType => 'Fußballtyp';

  @override
  String get teamCreationNoClubWarningTitle => 'Warnung';

  @override
  String get teamCreationNoClubWarning =>
      'Dieses Team ist weder einem Verein noch einem Wettbewerb zugeordnet. In diesem Fall werden Spielplan und Ergebnisse nicht automatisch abgerufen.';

  @override
  String equipeCompetitionsSheetTitle(String teamName) {
    return 'Wettbewerbe — $teamName';
  }

  @override
  String fffCompetitionPhaseLabel(int phase) {
    return 'Phase $phase';
  }

  @override
  String fffCompetitionGroupeLabel(int groupe) {
    return 'Gruppe $groupe';
  }

  @override
  String get hintSearchClub => 'Verein suchen';

  @override
  String get hintSearchClubTeam => 'Mannschaft suchen';

  @override
  String get actionAddPlayer => 'Fügen Sie einen Spieler hinzu';

  @override
  String get actionCreatePlayer => 'Spieler erstellen';

  @override
  String get actionEditPlayer => 'Spieler bearbeiten';

  @override
  String get actionEditStaff => 'Betreuer bearbeiten';

  @override
  String get addPlayerPositionRequired => 'Bitte wählen Sie eine Position';

  @override
  String get addPlayerHeightCmOptional => 'Größe (cm, optional)';

  @override
  String get addPlayerWeightKgOptional => 'Gewicht (kg, optional)';

  @override
  String get addPlayerHeightInvalid =>
      'Geben Sie eine Größe zwischen 50 und 250 cm ein';

  @override
  String get addPlayerWeightInvalid =>
      'Geben Sie ein Gewicht zwischen 20 und 200 kg ein';

  @override
  String get actionAddStaff => 'Fügen Sie einen Stab hinzu';

  @override
  String get actionAddZone => 'Fügen Sie einen Bereich hinzu';

  @override
  String get actionAddToCart => 'In den Warenkorb legen';

  @override
  String get actionBeginCheckout => 'Zahlung starten';

  @override
  String get actionConnect => 'Verbinden';

  @override
  String get actionDownload => 'Herunterladen';

  @override
  String get actionEraseData => 'Daten löschen';

  @override
  String get actionChooseAsiFile => 'Wählen Sie eine .asi-Datei';

  @override
  String get actionDefaultValues => 'Standardwerte';

  @override
  String get actionRemoveCustomization => 'Personalisierung entfernen';

  @override
  String get actionDisconnect => 'Trennen';

  @override
  String get actionAsiFile => '.asi-Datei';

  @override
  String get actionWeekPreviousLong => 'Vorherige Woche';

  @override
  String get actionWeekNextLong => 'Nächste Woche';

  @override
  String get entityTeam => 'Team';

  @override
  String entityTeamWithIndex(int index) {
    return 'Team $index';
  }

  @override
  String get entityTeams => 'Mannschaften';

  @override
  String get entityPlayer => 'Spieler';

  @override
  String get entityPlayers => 'Spieler';

  @override
  String get entityPlayerUnknown => 'Unbekannter Spieler';

  @override
  String get entityPlayerNotSet => 'Spieler nicht informiert';

  @override
  String get entityStaff => 'Personal';

  @override
  String get entityMatch => 'Übereinstimmen';

  @override
  String get entityMatches => 'Streichhölzer';

  @override
  String get entityTraining => 'Ausbildung';

  @override
  String get entityTrainings => 'Trainingseinheiten';

  @override
  String get entityField => 'Boden';

  @override
  String get entityFieldUndefined => 'Undefiniertes Land';

  @override
  String get entitySeason => 'Jahreszeit';

  @override
  String get entityEvent => 'Ereignis';

  @override
  String get entityEvents => 'Ereignisse';

  @override
  String get entityConversation => 'Gespräch';

  @override
  String get entityUser => 'Benutzer';

  @override
  String get entityProduct => 'Produkt';

  @override
  String get entityCart => 'Korb';

  @override
  String get entityApplication => 'Anwendung';

  @override
  String get entityMap => 'Karte';

  @override
  String get entityIndicator => 'Indikator';

  @override
  String get entityDeviceId => 'Geräte-ID';

  @override
  String get entityTracker => 'Tracker';

  @override
  String get entityTrackerId => 'Ausweis';

  @override
  String get entityName => 'Name';

  @override
  String get entityCode => 'Code';

  @override
  String get entityLabel => 'Wortlaut';

  @override
  String get entityMinSpeed => 'Mindestgeschwindigkeit';

  @override
  String get entityMaxSpeed => 'Höchstgeschwindigkeit';

  @override
  String get entityFullMatch => 'Ganzes Spiel';

  @override
  String get entityFullMatchShort => 'Vollständige Übereinstimmung';

  @override
  String get navDashboard => 'Armaturenbrett';

  @override
  String get navAgenda => 'Tagebuch';

  @override
  String get navTeams => 'Mannschaften';

  @override
  String get navChat => 'Nachrichten';

  @override
  String get navSync => 'Synchronisation';

  @override
  String get navNotifications => 'Benachrichtigungen';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsEmptyTitle => 'Keine Benachrichtigungen';

  @override
  String get notificationsEmptyMessage =>
      'Sie haben keine ungelesenen Benachrichtigungen.';

  @override
  String get notificationsMarkAsRead => 'Als gelesen markieren';

  @override
  String get notificationsMarkAsReadError =>
      'Benachrichtigung konnte nicht als gelesen markiert werden.';

  @override
  String get notificationsConvocationMatchDetails => 'Spieldetails';

  @override
  String get notificationsConvocationPresent => 'Ich werde anwesend sein';

  @override
  String get notificationsConvocationAbsent => 'Nicht anwesend';

  @override
  String get notificationsConvocationAbsentDialogTitle =>
      'Grund für die Abwesenheit';

  @override
  String get notificationsConvocationAbsentMessageHint =>
      'Erklären Sie, warum Sie nicht teilnehmen können';

  @override
  String get notificationsConvocationAbsentConfirm => 'Bestätigen';

  @override
  String get notificationsConvocationAbsentMessageRequired =>
      'Bitte geben Sie eine Nachricht ein.';

  @override
  String get notificationsConvocationActionError =>
      'Antwort auf die Einberufung fehlgeschlagen.';

  @override
  String get featureDiscoveryAgendaTitle => 'Kalender entdecken';

  @override
  String get featureDiscoveryAgendaMessage =>
      'Sehen Sie kommende Spiele und Trainings im Agenda-Tab.';

  @override
  String get featureDiscoveryDiscover => 'Entdecken';

  @override
  String get featureDiscoveryDashboardTitle => 'Dashboard entdecken';

  @override
  String get featureDiscoveryDashboardMessage =>
      'Verfolgen Sie Aktivität, Statistiken und Termine im Dashboard-Tab.';

  @override
  String get featureDiscoveryChatTitle => 'Nachrichten entdecken';

  @override
  String get featureDiscoveryChatMessage =>
      'Chatten Sie mit Ihrem Team im Nachrichten-Tab.';

  @override
  String get featureDiscoverySyncTitle => 'Synchronisation entdecken';

  @override
  String get featureDiscoverySyncMessage =>
      'Laden Sie Tracker-Daten hoch und verwalten Sie Geräte im Sync-Tab.';

  @override
  String get featureDiscoveryTeamsTitle => 'Teams entdecken';

  @override
  String get featureDiscoveryTeamsMessage =>
      'Verwalten Sie Kader und Einstellungen im Bereich Teams.';

  @override
  String get featureDiscoveryFieldsTitle => 'Plätze entdecken';

  @override
  String get featureDiscoveryFieldsMessage =>
      'Orten Sie Spielfelder für die Tracker-Analyse im Tab Plätze.';

  @override
  String get featureDiscoveryCompoTitle => 'Aufstellungen entdecken';

  @override
  String get featureDiscoveryCompoMessage =>
      'Erstellen und nutzen Sie Aufstellungen im Tab Aufstellung.';

  @override
  String get featureDiscoveryMatchCompoTitle => 'Tab Aufstellung';

  @override
  String get featureDiscoveryMatchCompoMessage =>
      'Sehen und bearbeiten Sie die Aufstellung im Tab Aufstellung.';

  @override
  String get featureDiscoveryMatchTacticalTitle => 'Tab Taktik';

  @override
  String get featureDiscoveryMatchTacticalMessage =>
      'Platzieren Sie Spieler auf dem Feld im Tab Taktik.';

  @override
  String get featureDiscoveryMatchHighlightsTitle => 'Tab Highlights';

  @override
  String get featureDiscoveryMatchHighlightsMessage =>
      'Sehen Sie Schlüsselmomente im Tab Highlights.';

  @override
  String get featureDiscoveryMatchStatsTitle => 'Tab Statistiken';

  @override
  String get featureDiscoveryMatchStatsMessage =>
      'Erkunden Sie Tracker-Stats und Heatmaps im Tab Statistiken.';

  @override
  String get featureDiscoveryDismiss => 'Schließen';

  @override
  String get navFields => 'Land';

  @override
  String get navCompo => 'Zusammensetzung';

  @override
  String get navStatistics => 'Statistiken';

  @override
  String get navOverview => 'Überblick';

  @override
  String get navNavigation => 'Navigation';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get tabCompo => 'Zusammensetzung';

  @override
  String get tabConvocations => 'Einberufungen';

  @override
  String get tabConvocationsShort => 'Einber.';

  @override
  String get matchConvocationsSaved => 'Einberufungen gespeichert';

  @override
  String get matchConvocationsUnavailable =>
      'Einberufungen für dieses Spiel nicht verfügbar';

  @override
  String get matchPlayerUnavailableOnMatchDate => 'Am Spieltag nicht verfügbar';

  @override
  String get matchPlayerCannotConvokeUnavailable =>
      'Dieser Spieler ist am Spieltag nicht verfügbar und kann nicht einberufen werden.';

  @override
  String get matchConvocationsStatusPresent => 'Anwesenheit bestätigt';

  @override
  String get matchConvocationsStatusPending => 'Antwort ausstehend';

  @override
  String get matchConvocationsSendAction => 'Einberufungen senden';

  @override
  String get matchConvocationsSendTitle => 'Einberufungen senden';

  @override
  String matchConvocationsSendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler einberufen',
      one: '1 Spieler einberufen',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendMessage => 'Nachricht';

  @override
  String get matchConvocationsSendMessageHint =>
      'Zusätzliche Informationen für die Spieler';

  @override
  String get matchConvocationsSendMessageRequired => 'Gib eine Nachricht ein';

  @override
  String get matchConvocationsSendTime => 'Treffzeit';

  @override
  String get matchConvocationsSendAddress => 'Treffpunkt';

  @override
  String get matchConvocationsSendAddressHint => 'Treffpunkt-Adresse';

  @override
  String get matchConvocationsSendAddressRequired => 'Gib eine Adresse ein';

  @override
  String get matchConvocationsSendSubmit => 'Senden';

  @override
  String matchConvocationsSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einberufungen gesendet',
      one: '1 Einberufung gesendet',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoAccount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler ohne verknüpftes Konto',
      one: '1 Spieler ohne verknüpftes Konto',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler ohne Push-Benachrichtigung',
      one: '1 Spieler ohne Push-Benachrichtigung',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendNoRecipients =>
      'Kein einberufener Spieler hat ein verknüpftes Grinta-Konto.';

  @override
  String matchConvocationsSendError(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get matchConvocationsSendErrorAuth =>
      'Melde dich an, um Einberufungen zu senden.';

  @override
  String matchConvocationsSendDateTimeValue(String date, String time) {
    return '$date um $time';
  }

  @override
  String matchConvocationsSendMatchLine(String opponent) {
    return 'Spiel: $opponent';
  }

  @override
  String matchConvocationsSendTimeLine(String time) {
    return 'Zeit: $time';
  }

  @override
  String matchConvocationsSendAddressLine(String address) {
    return 'Adresse: $address';
  }

  @override
  String matchConvocationNotificationTitle(String opponent) {
    return 'Einberufung · $opponent';
  }

  @override
  String matchConvocationFeedbackNotificationTitle(String opponent) {
    return 'Antwort Einberufung · $opponent';
  }

  @override
  String matchConvocationNotificationBody(String opponent, String time) {
    return '$opponent · Treffpunkt $time';
  }

  @override
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message) {
    return '$opponent · Treffpunkt $time · $message';
  }

  @override
  String get tabTacticalSchema => 'Taktisches Schema';

  @override
  String get tabTacticalSchemaShort => 'Schema';

  @override
  String get matchTacticalSchemaConvocation => 'Spieler einberufen';

  @override
  String get matchTacticalSchemaConvocationHint =>
      'Optional — beschränkt die Auswahl auf einberufene Spieler';

  @override
  String get matchTacticalSchemaSubstitutes => 'Ersatzspieler';

  @override
  String get matchTacticalSchemaAddSubstitute => 'Ersatz hinzufügen';

  @override
  String get matchTacticalSchemaNoSubstitutes => 'Keine Ersatzspieler';

  @override
  String get matchTacticalSchemaPickPlayer => 'Spieler wählen';

  @override
  String get matchTacticalSchemaClearSlot => 'Vom Posten entfernen';

  @override
  String get matchTacticalSchemaSaved => 'Taktisches Schema gespeichert';

  @override
  String get matchTacticalSchemaEmpty =>
      'Kein taktisches Schema für dieses Spiel';

  @override
  String get matchTacticalSchemaUnavailable =>
      'Taktisches Schema für dieses Spiel nicht verfügbar';

  @override
  String get matchTacticalSchemaNoTeam =>
      'Das mit diesem Spiel verknüpfte Team konnte nicht ermittelt werden.';

  @override
  String get matchTacticalSchemaJerseyNumber => 'Trikotnummer';

  @override
  String get matchTacticalSchemaPlayerAssignment => 'Spielerzuweisung';

  @override
  String get matchTacticalSchemaJerseyNumberRequired =>
      'Geben Sie eine Trikotnummer ein (1 bis 99).';

  @override
  String get matchTacticalSchemaNoJerseyNumberAvailable =>
      'Keine Trikotnummer verfügbar (alle Nummern von 1 bis 99 sind bereits vergeben).';

  @override
  String get matchTacticalSchemaRemoveFromCompo =>
      'Aus der Aufstellung entfernen?';

  @override
  String get matchTacticalSchemaRemoveFromCompoMessage =>
      'Dieser Spieler wird aus dem taktischen Schema entfernt (Position und Ersatzspieler).';

  @override
  String get matchTacticalSchemaRemoveFromCompoConfirm => 'Entfernen';

  @override
  String get matchTacticalSchemaSensorRequired =>
      'Wählen Sie einen verfügbaren Sensor.';

  @override
  String get matchTacticalSchemaNoPlayerAvailable =>
      'Keine Spieler verfügbar — alle berechtigten Spieler sind bereits in der Aufstellung.';

  @override
  String get tabHighlights => 'Höhepunkte';

  @override
  String get tabStats => 'Statistiken';

  @override
  String get tabStarters => 'Inhaber';

  @override
  String get tabSubstitutes => 'Ersatz';

  @override
  String get tabSynthesis => 'Zusammenfassung';

  @override
  String get tabSpeedZones => 'Geschwindigkeitszonen';

  @override
  String get tabFieldZones => 'Feldbereiche';

  @override
  String get tabHalfTimeComparison => 'Halbzeitvergleich';

  @override
  String get tabDistanceTimeline => 'Timeline-Entfernung';

  @override
  String get tabHeatmap => 'Wärmekarte';

  @override
  String get periodWeek => 'Woche';

  @override
  String get periodMonth => 'Monat';

  @override
  String get periodCustom => 'Zeitraum';

  @override
  String get periodPrep => 'Körperliche Vorbereitung';

  @override
  String get periodPostponed => 'Verschoben';

  @override
  String periodMatchDay(String day) {
    return 'Spieltag $day';
  }

  @override
  String periodSelectedWeek(String range) {
    return 'Ausgewählte Woche: $range';
  }

  @override
  String get periodUndefined => 'Kein definierter Zeitraum';

  @override
  String get hintSearchTeam => 'Finden Sie ein Team';

  @override
  String get hintSearchMember => 'Mitglied suchen';

  @override
  String get memberSearchPrompt => 'Vorname oder Nachname eingeben';

  @override
  String get memberAlreadyOnTeamRoster =>
      'Dieses Mitglied ist bereits im Kader';

  @override
  String get memberAlreadyPlayer =>
      'Dieses Mitglied ist bereits als Spieler im Team';

  @override
  String get memberAlreadyStaff =>
      'Dieses Mitglied ist bereits als Betreuer im Team';

  @override
  String get hintSearchUser => 'Nach einem Benutzer suchen';

  @override
  String get hintSearchAddress =>
      'Suchen Sie nach einer Adresse oder einem Stadion';

  @override
  String get hintSelectSeason => 'Wählen Sie eine Saison aus';

  @override
  String get hintFieldName => 'Landname';

  @override
  String get hintCompoType => 'Art der Komposition';

  @override
  String get hintMetric => 'Indikator';

  @override
  String get hintDeviceIdExample => 'Beispiel: tracker_001';

  @override
  String get hintSpeedZoneMaxEmpty =>
      'Lassen Sie für den letzten Bereich das Feld leer';

  @override
  String get emptyNoData => 'Keine Daten verfügbar';

  @override
  String get emptyNoEvent => 'Keine Veranstaltungen';

  @override
  String get emptyNoConversation => 'Kein Gespräch';

  @override
  String get emptyNoHighlights => 'Keine Highlights';

  @override
  String get emptyNoCompo =>
      'Für dieses Spiel wurden keine Aufstellungen gefunden.';

  @override
  String get emptyNoStarters => 'Kein Inhaber angegeben.';

  @override
  String get emptyNoSubstitutes => 'Kein Ersatz angegeben.';

  @override
  String get emptyNoTracker => 'Kein Tracker ausgewählt';

  @override
  String get emptyNoTrackers => 'Keine Tracker zum Anzeigen';

  @override
  String get emptyNoDeviceId => 'Keine Geräte-ID verfügbar';

  @override
  String get emptyNoFileSelected => 'Keine Dateien ausgewählt';

  @override
  String get emptyNoSpeedZone => 'Keine Geschwindigkeitszone verfügbar.';

  @override
  String get emptyNoFieldZoneData => 'Keine Geländezonendaten verfügbar.';

  @override
  String get emptyNoDistanceTimeline =>
      'Keine Entfernungszeitleiste verfügbar.';

  @override
  String get emptyNoStatsForMatch =>
      'Für dieses Spiel wurden keine Daten gefunden.';

  @override
  String get emptyNoStatsTeamAnalysis =>
      'Für dieses Spiel wurden keine Daten in TRACKER_TeamAnalysis gefunden.';

  @override
  String get emptyNoPendingMatch => 'Keine ausstehenden Spiele.';

  @override
  String get emptyNoPendingTraining => 'Kein Training mit Tracker ausstehend.';

  @override
  String get emptyNoTeamFound => 'Keine Teams gefunden';

  @override
  String get emptyNoTeamAvailable => 'Keine Teams verfügbar';

  @override
  String get emptyNoTeamForSeason =>
      'Für diese Saison wurden keine Teams gefunden.';

  @override
  String get emptyNoTeamForStats =>
      'Es sind keine Teams zum Anzeigen von Statistiken verfügbar.';

  @override
  String get emptyNoPlayerForTeam =>
      'Für dieses Team wurden keine Spieler gefunden.';

  @override
  String get trainingPlayersRecap => 'Zusammenfassung';

  @override
  String get trainingPlayersLoading => 'Spieler werden geladen…';

  @override
  String get trainingPlayersClose => 'Schließen';

  @override
  String get presencePresent => 'Anwesend';

  @override
  String get presenceInjured => 'Verletzt';

  @override
  String get presenceExcused => 'Entschuldigt';

  @override
  String get presenceAbsent => 'Abwesend';

  @override
  String get presenceLate => 'Verspätet';

  @override
  String get presenceUnknown => '—';

  @override
  String get trainingPlayersAddPlayer => 'Spieler hinzufügen';

  @override
  String get trainingPlayersAddPlayerTitle => 'Spieler wählen';

  @override
  String get trainingPlayersNoCandidates =>
      'Alle Spieler des Teams sind bereits eingetragen.';

  @override
  String get trainingPlayersChangePresence => 'Anwesenheit ändern';

  @override
  String get trainingPlayersAssignTracker => 'Tracker zuweisen';

  @override
  String get trainingPlayersNoTrackerAvailable => 'Kein Tracker verfügbar.';

  @override
  String get trainingPlayersSelectTracker => 'Tracker';

  @override
  String get emptyNoStaffForTeam =>
      'Für dieses Team wurden keine Mitarbeiter gefunden.';

  @override
  String get emptyNoPlayerSelected => 'Keine Spieler ausgewählt.';

  @override
  String get emptyNoCurrentSeason => 'Keine aktuelle Saison verfügbar.';

  @override
  String get emptyNoUserFound => 'Keine Benutzer gefunden';

  @override
  String get emptyNoUserAvailable => 'Keine Benutzer verfügbar';

  @override
  String get emptyNoConnectedDevice => 'Keine Geräte angeschlossen';

  @override
  String get emptyNoMatchToShow => 'Keine Übereinstimmungen zum Anzeigen.';

  @override
  String get emptyNoCompoType => 'Es wurde kein Kompositionstyp gefunden.';

  @override
  String get emptyNoAnalysis => 'Keine Analyse verfügbar';

  @override
  String get emptyNoStats => 'Keine Statistiken verfügbar';

  @override
  String get emptyNoPlayersInStats =>
      'Statistiken sind vorhanden, es ist jedoch kein Spielerstand verfügbar.';

  @override
  String get emptyHeatmap => 'Heatmap nicht verfügbar';

  @override
  String emptyNoSvgForPeriod(String period) {
    return 'Kein SVG-Bild für $period gefunden.';
  }

  @override
  String errorGeneric(String details) {
    return 'Fehler: $details';
  }

  @override
  String errorLoadingResource(String resource) {
    return 'Fehler beim Laden von $resource.';
  }

  @override
  String errorFilteringResource(String resource) {
    return 'Fehler beim Filtern von $resource.';
  }

  @override
  String errorComputingStats(String resource) {
    return 'Fehler bei der Statistikberechnung für $resource.';
  }

  @override
  String errorSaving(String details) {
    return 'Fehler beim Speichern: $details';
  }

  @override
  String errorLogout(String details) {
    return 'Fehler beim Abmelden: $details';
  }

  @override
  String get errorStreamConnection =>
      'Es kann keine Verbindung zum Stream hergestellt werden';

  @override
  String get sessionReplacedOnAnotherDevice =>
      'Ihre Sitzung wurde auf einem anderen Gerät geöffnet. Bitte melden Sie sich erneut an.';

  @override
  String get errorOpenAnalysis =>
      'Analyse kann nicht geöffnet werden: Ereignis-ID oder Tracker-ID fehlt.';

  @override
  String get errorAgendaLoad => 'Kalender kann nicht geladen werden';

  @override
  String errorTeamParamsLoad(String details) {
    return 'Fehler beim Laden der Einstellungen: $details';
  }

  @override
  String get errorSaveTeamIdEmpty => 'Speichern nicht möglich: leere Team-ID.';

  @override
  String errorDeleteFailed(String details) {
    return 'Fehler beim Löschen: $details';
  }

  @override
  String get errorLoadingTitle => 'Fehler beim Laden';

  @override
  String get errorCompositionTitle => 'Kompositionsfehler';

  @override
  String get errorPlayerTitle => 'Spielerfehler';

  @override
  String get errorPlayersTitle => 'Spielerfehler';

  @override
  String get errorTrackerTitle => 'Tracker-Fehler';

  @override
  String get errorMatchNotIdentified => 'Unbekannte Übereinstimmung';

  @override
  String get errorPlayerNotIdentified => 'Unbekannter Spieler';

  @override
  String get errorPlayerNotFound => 'Spieler nicht gefunden';

  @override
  String get errorPlayerNotFoundInMatch => 'Spieler nicht gefunden';

  @override
  String get errorStatsUnavailable => 'Statistiken nicht verfügbar';

  @override
  String get errorNoStats => 'Keine Statistik';

  @override
  String get errorNoStatsForPlayer =>
      'Spielerstatistiken können nicht geladen werden.';

  @override
  String get errorPlayerNotFoundMessage =>
      'Der ausgewählte Spieler konnte nicht gefunden werden.';

  @override
  String get errorNoTrackerData =>
      'Für dieses Spiel wurden keine Trackerdaten gefunden.';

  @override
  String get errorNoTrackerStats =>
      'Ohne Match-ID können Tracker-Statistiken nicht geladen werden.';

  @override
  String get errorNoTrackerAnalysis =>
      'Es konnten keine Tracker-Daten für diesen Player gefunden werden.';

  @override
  String get errorMatchIdMissing => 'Fehlende Match-ID.';

  @override
  String errorChatCreate(String details) {
    return 'Fehler beim Erstellen: $details';
  }

  @override
  String get errorCompoTitle => 'Fehler';

  @override
  String get errorNoCompoTitle => 'Keine Komposition';

  @override
  String get successSettingsSaved => 'Einstellungen erfolgreich gespeichert.';

  @override
  String get successGpsCopied => 'GPS kopiert.';

  @override
  String get successDefaultsLoaded => 'In das Formular geladene Standardwerte.';

  @override
  String successConversionDone(int count) {
    return 'Konvertierung abgeschlossen - $count Zeile(n) übernommen';
  }

  @override
  String get infoReadOnly => 'Nur lesen';

  @override
  String get infoWebShellOnly => 'Diese Shell ist nur für Flutter Web gedacht.';

  @override
  String get settingsLanguageLabel => 'Sprache';

  @override
  String get themeDarkModeLabel => 'Dunkler Modus';

  @override
  String get themeEnableDarkModeTooltip => 'Dunklen Modus aktivieren';

  @override
  String get themeDisableDarkModeTooltip => 'Dunklen Modus deaktivieren';

  @override
  String get infoParameters => 'Einstellungen';

  @override
  String get infoUserNotConnected => 'Benutzer nicht angemeldet.';

  @override
  String get dialogCloseSyncTitle => 'Synchronisierung endgültig schließen';

  @override
  String get dialogCloseSyncMessage =>
      'Möchten Sie die Synchronisierung endgültig schließen? Ja: dieser Bildschirm ist nicht mehr verfügbar. Nein: ohne Schließen verlassen.';

  @override
  String get dialogDeleteCustomizationTitle => 'Personalisierung entfernen?';

  @override
  String get dialogDeleteAssignmentTitle => 'Zuordnung löschen';

  @override
  String get dialogNewConversation => 'Neues Gespräch';

  @override
  String get dialogAsiConversionTitle => 'ASI-zu-CSV-Konvertierung';

  @override
  String get syncMatchesToSync => 'Zu synchronisierende Übereinstimmungen';

  @override
  String get syncNoDeviceForTraining =>
      'Für dieses Training wurden keine Geräte gefunden';

  @override
  String get syncNoDeviceForMatch =>
      'Für dieses Spiel wurden keine Geräte gefunden';

  @override
  String get statsWins => 'Siege';

  @override
  String get statsLosses => 'Niederlagen';

  @override
  String get statsDraws => 'Dummies';

  @override
  String get statsDistance => 'Distanz';

  @override
  String get statsMaxSpeed => 'Höchstgeschwindigkeit';

  @override
  String get statsAvgSpeed => 'Durchschnittliche Geschwindigkeit';

  @override
  String get statsWorkload => 'Arbeitsbelastung';

  @override
  String get statsFatigue => 'Ermüdung';

  @override
  String get statsDuration => 'Dauer';

  @override
  String get statsSprints => 'Sprints';

  @override
  String get statsHighAccel => 'Acc. hoch';

  @override
  String get statsHighSpeedTime => 'Hohe Geschwindigkeit';

  @override
  String get statsHighSpeedTimeShort => 'Hochgeschwindigkeitszeit';

  @override
  String get statsMaxAccel => 'Acc. max';

  @override
  String get statsAxisSpeed => 'Geschwindigkeit (km/h)';

  @override
  String get statsAxisTime => 'Mal)';

  @override
  String get statsAxisAcceleration => 'Beschleunigung (m/s²)';

  @override
  String get statsScore => 'Punktzahl';

  @override
  String statsPlayersCount(int count) {
    return '$count Spieler';
  }

  @override
  String statsAvgWorkload(String value) {
    return 'Ø Belastung $value';
  }

  @override
  String statsAvgDistance(String value) {
    return 'Ø Distanz $value';
  }

  @override
  String statsAvgMaxSpeed(String value) {
    return 'Ø Max.-Geschw. $value';
  }

  @override
  String statsZScore(String sign, String value) {
    return 'zScore $sign$value';
  }

  @override
  String get statsMaxAccelSample => 'Maximale Beschleunigung: 4 m/s2';

  @override
  String get speedZoneWalk => 'Gehen';

  @override
  String get speedZoneJogging => 'Jogging';

  @override
  String get speedZoneRun => 'Wettrennen';

  @override
  String get speedZoneHighIntensity => 'Hohe Intensität';

  @override
  String get speedZoneSprint => 'Sprint';

  @override
  String get highlightKickoff => 'Beginnen';

  @override
  String get highlightFullTime => 'Ende des Spiels';

  @override
  String get substitutionOut => 'Ausfahrt';

  @override
  String get substitutionIn => 'Eingang';

  @override
  String get teamParamsPerformanceTitle => 'Leistungseinstellungen';

  @override
  String get teamParamsSpeedSprints => 'Geschwindigkeit & Sprints';

  @override
  String get teamParamsIntensity => 'Intensität';

  @override
  String get teamParamsGpsTimeline => 'GPS / Validierung / Zeitleiste';

  @override
  String get teamParamsSpeedZones => 'Geschwindigkeitszonen';

  @override
  String get teamParamsMinOneZone =>
      'Mindestens ein Bereich muss erhalten bleiben.';

  @override
  String get teamParamsAddSpeedZone =>
      'Fügt mindestens eine Geschwindigkeitszone hinzu.';

  @override
  String get teamParamsSprintThreshold => 'Sprintschwelle (km/h)';

  @override
  String get teamParamsSprintMinAccel => 'Mini-Beschleunigung für den Sprint';

  @override
  String get teamParamsSprintMinDuration => 'Dauer des Minisprints';

  @override
  String get teamParamsSpeedMinDuration =>
      'Mindestgeschwindigkeitsdauer validiert';

  @override
  String get teamParamsHighAccelThreshold => 'Starke Beschleunigungsschwelle';

  @override
  String get teamParamsHighAccelMinDuration =>
      'Minidauer starke Beschleunigung';

  @override
  String get teamParamsMaxStepDistance =>
      'Maximal zulässige Entfernung pro Schritt';

  @override
  String get teamParamsMaxPlausibleSpeed =>
      'Maximale plausible Geschwindigkeit';

  @override
  String get teamParamsMaxPlausibleAccel => 'Maximale plausible Beschleunigung';

  @override
  String get teamParamsMinDeltaTime => 'Minimales Zeitdelta';

  @override
  String get teamParamsMaxDeltaTime => 'Maximales Zeitdelta';

  @override
  String get teamParamsSmoothingWindow => 'Glättungsfenster';

  @override
  String get teamParamsTimelineBucket => 'Bucket-Zeitleiste';

  @override
  String teamMembersPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler',
      one: '1 Spieler',
    );
    return '$_temp0';
  }

  @override
  String teamMembersStaff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Staff-Mitglieder',
      one: '1 Staff-Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get fieldTooltipZoomIn => 'Vergrößern Sie das gesamte Gelände';

  @override
  String get fieldTooltipZoomOut => 'Alles Gelände einstürzen lassen';

  @override
  String get fieldTooltipLengthUp => 'Länge erhöhen';

  @override
  String get fieldTooltipLengthDown => 'Länge reduzieren';

  @override
  String get fieldTooltipWidthUp => 'Breite vergrößern';

  @override
  String get fieldTooltipWidthDown => 'Breite reduzieren';

  @override
  String get fieldTooltipRotateLeft => 'Biegen Sie links ab';

  @override
  String get fieldTooltipRotateRight => 'Biegen Sie rechts ab';

  @override
  String get fieldTooltipMap => 'Karte';

  @override
  String get fieldTooltipSatellite => 'Satellit';

  @override
  String get fieldLocateCorners => 'Lokalisieren Sie Ecken';

  @override
  String get fieldSnackbarLocationDisabled =>
      'Die Standortverfolgung ist deaktiviert.';

  @override
  String get fieldSnackbarAllowLocation =>
      'Ermöglicht dem Standort, die Karte zu zentrieren.';

  @override
  String get fieldSnackbarGpsFailed =>
      'Die aktuelle Position kann nicht abgerufen werden.';

  @override
  String get fieldSnackbarEnterAddress =>
      'Geben Sie eine Adresse oder einen Stadionnamen ein.';

  @override
  String get fieldSnackbarMapNotReady => 'Die Karte ist noch nicht fertig.';

  @override
  String get fieldSnackbarAddressNotFound => 'Adresse nicht gefunden.';

  @override
  String fieldSnackbarAddressNotFoundWithStatus(String status) {
    return 'Adresse nicht gefunden: $status';
  }

  @override
  String get fieldSnackbarGeocodingFailed =>
      'Die Suche nach dieser Adresse ist nicht möglich. Überprüft den Schlüssel und die Geocoding-API.';

  @override
  String get fieldSnackbarPlaceInMap =>
      'Platziert das Gelände vollständig auf der Karte.';

  @override
  String get fieldSnackbarGpsConvertFailed =>
      'Ecken können nicht in GPS-Positionen umgewandelt werden.';

  @override
  String get fieldHelpGestures =>
      'Gelände: Ziehen, Bewegen, Zoomen/Drehen mit 2 Fingern, Trackpad: Scrollen, Zoomen, Drehen, Breite, Länge';

  @override
  String get compoNotFoundTitle => 'Zusammensetzung nicht angegeben';

  @override
  String get compoTypeEmptyTitle => 'Keine Komposition';

  @override
  String get matchStatsUnavailableTitle => 'Statistiken nicht verfügbar';

  @override
  String get sensorNotFoundTitle => 'Sensor nicht gefunden';

  @override
  String get sensorNotFoundMessage =>
      'Für dieses Spiel sind diesem Spieler keine Sensoren zugeordnet.';

  @override
  String get matchHomeJersey => 'Heimtrikot';

  @override
  String get matchCartTitle => 'Ihr Warenkorb';

  @override
  String get matchCartOneItem => '1 Artikel – 49,90 €';

  @override
  String get asiSelectFile => 'Bitte wählen Sie eine .asi-Datei aus';

  @override
  String get asiEnterDeviceId => 'Bitte geben Sie die Geräte-ID ein';

  @override
  String get asiCannotReadFile =>
      'Die ausgewählte Datei kann nicht abgespielt werden';

  @override
  String get asiFileEmptyOrNoData =>
      'Die .asi-Datei ist leer oder enthält keine verwertbaren Daten.';

  @override
  String get asiFileMismatch =>
      'Die Datei passt nicht zum ausgewählten Tracker';

  @override
  String get asiTrackerUnknown => 'Tracker nicht erkannt';

  @override
  String asiFilePickError(String details) {
    return 'Fehler bei der Dateiauswahl: $details';
  }

  @override
  String asiConversionError(String details) {
    return 'Fehler bei der Konvertierung: $details';
  }

  @override
  String get asiAnalysisFailed => 'Analyse nicht möglich';

  @override
  String get playerSynthesisTitle => 'Spielerzusammenfassung';

  @override
  String get playerSynthesisTabTitle => 'Zusammenfassung';

  @override
  String teamsListCount(int count) {
    return '$count Team(s)';
  }

  @override
  String teamsListCountFiltered(int filtered, int total) {
    return '$filtered / $total';
  }

  @override
  String get teamsListNoResults => 'Keine Teams gefunden';

  @override
  String get teamsListNoTeams => 'Keine Teams verfügbar';

  @override
  String get teamStreamChannelSynced => 'Stream-Gruppe aktiv';

  @override
  String get teamStreamChannelPending =>
      'Stream-Gruppe noch nicht synchronisiert';

  @override
  String get teamStreamChannelCreateTitle => 'Stream-Gruppe erstellen?';

  @override
  String teamStreamChannelCreateMessage(String teamName) {
    return 'Stream-Gruppe für Team $teamName erstellen? Spieler und Staff werden automatisch hinzugefügt.';
  }

  @override
  String get teamStreamChannelCreateConfirm => 'Erstellen';

  @override
  String get teamStreamChannelCreateLoading => 'Stream-Gruppe wird erstellt…';

  @override
  String teamStreamChannelCreateSuccess(String teamName) {
    return 'Stream-Gruppe für $teamName erstellt.';
  }

  @override
  String teamStreamChannelCreateError(String details) {
    return 'Stream-Gruppe konnte nicht erstellt werden: $details';
  }

  @override
  String get teamStreamChannelCreateNotManager =>
      'Nur Manager können die Stream-Gruppe erstellen.';

  @override
  String get navHome => 'Willkommen';

  @override
  String get myTeams => 'Meine Teams';

  @override
  String get syncTrainingsToSync => 'Trainings zum Synchronisieren';

  @override
  String get chatSelectConversation => 'Wählen Sie eine Konversation aus';

  @override
  String get chatStartNewHint =>
      'Klicken Sie auf „Neu“, um einen Chat zu starten.';

  @override
  String get chatTryAnotherName => 'Versuchen Sie es mit einem anderen Namen.';

  @override
  String get chatUsersAppearHere => 'Andere Benutzer werden hier angezeigt.';

  @override
  String get chatChannelMembersTitle => 'Mitglieder';

  @override
  String get chatMessageReadByTitle => 'Gelesen von';

  @override
  String get chatMessageNotReadYet => 'Noch nicht gelesen';

  @override
  String get matchDetailTitle => 'Spieldetails';

  @override
  String get matchDetailVenueTitle => 'Spielort';

  @override
  String get matchDetailTrackerKitTitle => 'Kit-Auswahl';

  @override
  String get matchDetailTrackerKitLabel => 'Tracker';

  @override
  String get matchDetailTrackerKitComingSoon => 'Demnächst';

  @override
  String get matchDetailTrackerKitWithTracker => 'Mit Tracker';

  @override
  String get matchDetailTrackerKitWithoutTracker => 'Ohne Tracker';

  @override
  String get matchDetailTrackerKitSelectLabel => 'Kit';

  @override
  String get matchDetailTrackerKitNoOwners =>
      'Kein Kit für dieses Team konfiguriert.';

  @override
  String get matchDetailTrackerKitSignInRequired =>
      'Melden Sie sich an, um ein Kit auszuwählen.';

  @override
  String playerAgeYears(int age) {
    return '$age Jahre';
  }

  @override
  String get playerAgeUnknown => 'Alter nicht angegeben';

  @override
  String get dateUndefined => 'Datum nicht definiert';

  @override
  String matchDateTimeAt(String date, String time) {
    return '$date um $time';
  }

  @override
  String get entityComposition => 'Zusammensetzung';

  @override
  String get entityDetails => 'Details';

  @override
  String get entityHeatmap => 'Heatmap';

  @override
  String get entityPeriods => 'Perioden';

  @override
  String get tabHighlightsShort => 'Zeit';

  @override
  String get emptyNoHighlightsMessage =>
      'Tore, Karten und Auswechslungen werden hier angezeigt.';

  @override
  String get matchHighlightsSourceFmi => 'FMI-Höhepunkte';

  @override
  String get matchHighlightsSourceGrinta => 'Grinta-Höhepunkte';

  @override
  String get matchHighlightsGrintaPlaceholderMessage =>
      'Wird gemeinsam später ausgearbeitet.';

  @override
  String get matchGrintaHighlightsAddAction => 'Highlight hinzufügen';

  @override
  String get matchGrintaHighlightsPickTypeTitle => 'Highlight-Typ wählen';

  @override
  String get matchGrintaHighlightsPickTimeEventTitle => 'Zeitereignis wählen';

  @override
  String get matchGrintaHighlightsEmptyMessage =>
      'Beginnen Sie mit dem Anstoß über die +-Schaltfläche.';

  @override
  String get matchGrintaHighlightsDetailsComingSoon =>
      'Details zu diesem Highlight folgen bald.';

  @override
  String get matchGrintaHighlightsActionTimeEvent => 'Zeitereignis';

  @override
  String get matchGrintaHighlightsAllTimeEventsRecorded =>
      'Alle Zeitereignisse wurden für dieses Spiel bereits erfasst.';

  @override
  String get matchGrintaHighlightDeleteConfirmTitle => 'Highlight löschen?';

  @override
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel) {
    return 'Möchten Sie \"$highlightLabel\" wirklich löschen? Diese Aktion ist endgültig.';
  }

  @override
  String get matchGrintaHighlightDeleted => 'Highlight gelöscht';

  @override
  String get matchGoalAddTitle => 'Tor erfassen';

  @override
  String get matchGoalPickTeamTitle => 'Welches Team hat getroffen?';

  @override
  String get matchGoalPickScorerTitle => 'Torschütze';

  @override
  String get matchGoalPickAssisterTitle => 'Vorlagengeber (optional)';

  @override
  String get matchGoalNoAssister => 'Kein Vorlagengeber';

  @override
  String get matchGoalOpponentJerseyTitle =>
      'Trikotnummer des Torschützen (optional)';

  @override
  String get matchGoalOpponentJerseyHint => 'z. B. 10';

  @override
  String get matchGoalScorerRequired => 'Wählen Sie einen Torschützen.';

  @override
  String get matchGoalInvalidJerseyNumber =>
      'Geben Sie eine gültige Trikotnummer ein.';

  @override
  String get matchGoalMinuteTitle => 'Minute';

  @override
  String get matchGoalMinuteHint => 'z. B. 67';

  @override
  String get matchGoalInvalidMinute =>
      'Geben Sie eine Minute von mindestens 1 ein.';

  @override
  String get matchGoalSelectScorer => 'Torschützen wählen';

  @override
  String get matchGoalSelectAssister => 'Vorlagengeber wählen';

  @override
  String get matchCardYellowAddTitle => 'Gelbe Karte erfassen';

  @override
  String get matchCardRedAddTitle => 'Rote Karte erfassen';

  @override
  String get matchCardPickTeamTitle => 'Welches Team erhält die Karte?';

  @override
  String get matchCardPickPlayerTitle => 'Spieler';

  @override
  String get matchCardSelectPlayer => 'Spieler wählen';

  @override
  String get matchCardPlayerRequired => 'Wählen Sie einen Spieler.';

  @override
  String get matchCardOpponentJerseyTitle =>
      'Trikotnummer des Spielers (optional)';

  @override
  String get matchCardOpponentJerseyHint => 'z. B. 10';

  @override
  String get matchSubstitutionAddTitle => 'Wechsel erfassen';

  @override
  String get matchSubstitutionPickTeamTitle => 'Welches Team wechselt?';

  @override
  String get matchSubstitutionPickOutgoingTitle => 'Spieler raus';

  @override
  String get matchSubstitutionPickIncomingTitle => 'Spieler rein';

  @override
  String get matchSubstitutionSelectOutgoing => 'Spieler raus wählen';

  @override
  String get matchSubstitutionSelectIncoming => 'Spieler rein wählen';

  @override
  String get matchSubstitutionOutgoingRequired =>
      'Wähle den ausgewechselten Spieler.';

  @override
  String get matchSubstitutionIncomingRequired =>
      'Wähle den eingewechselten Spieler.';

  @override
  String get matchSubstitutionSamePlayerError =>
      'Die beiden Spieler müssen unterschiedlich sein.';

  @override
  String get matchSubstitutionOpponentOutgoingJerseyTitle =>
      'Trikotnummer raus (optional)';

  @override
  String get matchSubstitutionOpponentIncomingJerseyTitle =>
      'Trikotnummer rein (optional)';

  @override
  String highlightGoalScored(String scorer) {
    return 'Tor — $scorer';
  }

  @override
  String get highlightTimeHalfTime => 'Halbzeit';

  @override
  String get highlightTimeSecondHalf => 'Zweite Halbzeit';

  @override
  String get highlightTimeStartExtraTime => 'Verlängerung';

  @override
  String get highlightTypeGoal => 'Ziel';

  @override
  String get highlightTypeSubstitution => 'Ändern';

  @override
  String get highlightTypeYellowCard => 'Gelbe Karte';

  @override
  String get highlightTypeRedCard => 'Rote Karte';

  @override
  String highlightYellowCardShown(String player) {
    return 'Gelbe Karte — $player';
  }

  @override
  String highlightRedCardShown(String player) {
    return 'Rote Karte — $player';
  }

  @override
  String get highlightTypeOwnGoal => 'Eigentor';

  @override
  String get highlightTypePenalty => 'Strafe';

  @override
  String get highlightTypeGeneric => 'Hervorheben';

  @override
  String highlightSubstitutionOut(String player) {
    return '$player raus';
  }

  @override
  String highlightSubstitutionIn(String incoming, String outgoing) {
    return '$incoming ersetzt $outgoing';
  }

  @override
  String get errorNoPlayersTitle => 'Keine Spieler';

  @override
  String get matchTrackerDataAvailable => 'Trackerdaten sind verfügbar.';

  @override
  String get matchTrackerDataPending =>
      'Die Trackerdaten sind noch nicht importiert.';

  @override
  String get errorPlayerNoTrackerMatch =>
      'Dieser Spieler hat keine Trackerdaten für dieses Spiel.';

  @override
  String get trackerSyncTitle => 'Sensorsynchronisation';

  @override
  String get trackerAvailableSensors => 'Sensoren verfügbar';

  @override
  String trackerCount(int count) {
    return '$count Tracker';
  }


  @override
  String get trackerAllSensorsSynced => 'Alle Sensoren wurden synchronisiert';

  @override
  String get trackerSensorsRemaining => 'Noch zu synchronisieren';

  @override
  String get trackerSensorsAlreadySynced => 'Bereits synchronisiert';

  @override
  String trackerSyncedProgress(int synced, int total) {
    return '$synced/$total synchronisiert';
  }

  @override
  String get trackerAlreadySyncedTitle =>
      'Synchronisierung bereits durchgeführt';

  @override
  String get trackerAlreadySyncedMessage =>
      'Der Sensor wurde für diese Sitzung bereits synchronisiert.';

  @override
  String get trackerStatusSelected => 'Ausgewählt';

  @override
  String get trackerStatusSynced => 'Synchronisiert';

  @override
  String get trackerStatusOpen => 'Offen';

  @override
  String get trackerSelectForActions =>
      'Wählt einen Tracker aus, um Anmelde-, Download- und Löschaktionen anzuzeigen.';

  @override
  String get trackerSelectedLabel => 'Tracker ausgewählt';

  @override
  String get trackerLogsPlaceholder => 'Die Protokolle werden hier angezeigt.';

  @override
  String get trackerNoDataOnDevice => 'Keine Daten auf diesem Sensor.';

  @override
  String get trackerNoDataOnDeviceTitle =>
      'Sensor verbunden — keine Einheit zum Import';

  @override
  String get trackerNoDataOnDeviceDetails =>
      'USB-Verbindung OK (UUID OK), aber der Pod hat keine aufgezeichnete Einheit: keine Aktivität gestartet oder Daten bereits gelöscht. Nehmen Sie eine Einheit auf dem Inspirit auf und laden Sie erneut herunter.';

  @override
  String get trackerDownloadFailedTitle => 'Download fehlgeschlagen';

  @override
  String get trackerDownloadBusyHint =>
      'Stellen Sie sicher, dass keine andere Grinta-Instanz geöffnet ist.';

  @override
  String get trackerDownloadPrepareSession =>
      'USB-Vorbereitung vor dem Download (wie Trennen und erneut Verbinden)…';

  @override
  String get uploadTrackerLoading => 'Wird geladen...';

  @override
  String get uploadTrackerDownloadData => 'Daten herunterladen';

  @override
  String get syncFieldGeolocationPromptTitle => 'Spielfeld geolokalisieren?';

  @override
  String get syncFieldGeolocationPromptMessage =>
      'Die GPS-Koordinaten des Spielfelds sind nicht hinterlegt. Möchten Sie sie vor dem Herunterladen der Tracker-Daten festlegen?';

  @override
  String get trackerUsbAuthorizeHint =>
      'Kein Inspirit für diese Website autorisiert. Ein Chrome-Dialog öffnet sich: Inspirit wählen, dann „Verbinden“ — Dialog nicht schließen.';

  @override
  String get trackerUsbPopupCancelled =>
      'Chrome-Dialog geschlossen oder kein Gerät gewählt. Tracker anschließen, erneut „Verbinden“ und in der Liste auswählen.';

  @override
  String get trackerUsbPhysicalReconnect =>
      'USB-Sitzung abgelaufen (Kabel getrennt oder Sensor zurückgesetzt). Tracker ggf. wieder anschließen, dann erneut „Verbinden“ — Chrome kann erneut nach Auswahl fragen.';

  @override
  String trackerDeviceName(String name) {
    return 'Gerät: $name';
  }

  @override
  String get asiImportTitle => 'Importieren Sie eine .asi-Datei';

  @override
  String get asiImportSubtitle =>
      'Wählen Sie eine Datei aus, überprüfen Sie die Geräte-ID und starten Sie dann die Konvertierung.';

  @override
  String get asiFileSelectedLabel => 'Ausgewählte Datei';

  @override
  String get asiImportFileHeader => 'ASI-Datei importieren';

  @override
  String get actionConvertToCsv => 'In CSV konvertieren';

  @override
  String get asiConverting => 'Konvertierung läuft...';

  @override
  String get asiPeriodsOne => '1 Periode übertragen';

  @override
  String asiPeriodsMany(int count) {
    return '$count Periode(n) übermittelt - die ersten 2 werden für die Halbzeiten verwendet';
  }

  @override
  String get statsUnitKm => 'km';

  @override
  String get statsUnitKmh => 'km/h';

  @override
  String get statsUnitCount => 'nb';

  @override
  String get statsUnitSeconds => 'trocken';

  @override
  String get statsUnitMps2 => 'm/s²';

  @override
  String get loadingSession => 'Sitzung wird geladen...';

  @override
  String get loadingStats => 'Statistiken werden geladen...';

  @override
  String get dashboardMyManagedTeams => 'Meine verwalteten Teams';

  @override
  String get dashboardMatchListTitle => 'Liste der Übereinstimmungen';

  @override
  String periodCustomRange(String start, String end) {
    return 'vom $start bis $end';
  }

  @override
  String statsPresenceRate(String value) {
    return 'Anwesenheitsquote: ($value) %';
  }

  @override
  String get statsDoneSingular => 'realisiert';

  @override
  String get statsDonePlural => 'gemacht';

  @override
  String get statsPlannedSingular => 'geplant';

  @override
  String get statsPlannedPlural => 'geplant';

  @override
  String get actionDayPrevious => 'Vorheriger Tag';

  @override
  String get actionDayNext => 'Am nächsten Tag';

  @override
  String get actionMonthPrevious => 'Vorheriger Monat';

  @override
  String get actionMonthNext => 'Nächsten Monat';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionSaving => 'Anmeldung...';

  @override
  String periodLoaded(String range) {
    return 'Zeitraum geladen: $range';
  }

  @override
  String get agendaAddEventTitle => 'Erstellen';

  @override
  String get agendaAddEventMatch => 'Ein Spiel / Match';

  @override
  String get agendaAddEventTraining => 'Eine Trainingseinheit';

  @override
  String get agendaAddEventPersonalSport => 'Eine persönliche Sportaktivität';

  @override
  String get agendaAddEventPersonalSportHint => 'Laufen, Vorbereitung, …';

  @override
  String get agendaAddEventNonSport =>

  @override
  String get agendaAllDayLabel => 'All day';

  @override
  String agendaEventSummaryNonSport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 activity',
      other: '$count activities',
    );
    return '$_temp0';
  }

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
  String get editNonSportEventError => 'Could not update the event. Please try again.';

  @override
  String get deleteNonSportEventConfirmTitle => 'Delete event?';

  @override
  String deleteNonSportEventConfirmMessage(String title) {
    return '“$title” will be permanently deleted, including related notifications.';
  }

  @override
  String get deleteNonSportEventDeleted => 'Event deleted';

  @override
  String get deleteNonSportEventError => 'Could not delete the event. Please try again.';


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
      one: '1 member selected',
      other: '$count members selected',
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
  String get createNonSportEventNoTeams => 'No teams available for this season.';

  @override
  String get createNonSportEventSubmit => 'Create event';

  @override
  String get createNonSportEventSaved => 'Event created';

  @override
  String get createNonSportEventError => 'Could not create the event. Please try again.';

  @override
  String get createNonSportEventInviteStatusSent => 'Notification sent';

  @override
  String get createNonSportEventInviteStatusNoAccount => 'No linked user account';

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
  String createNonSportEventNotificationBodyWithLocation(String title, String when, String location) {
    return '$title — $when — $location';
  }

  @override
  String get nonSportEventInviteesTitle => 'Invitations';

      'Ein nicht-sportliches Ereignis / Aktivität';

  @override
  String get agendaLegend => 'Legende';

  @override
  String agendaOverviewEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ereignisse',
      one: '1 Ereignis',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele',
      one: '1 Spiel',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryTrainings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainings',
      one: '1 Training',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryPrepas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorbereitungen',
      one: '1 Vorbereitung',
    );
    return '$_temp0';
  }

  @override
  String get agendaTrackerStatsTitle => 'Tracker-Statistiken';

  @override
  String get teamDetailBackToTeams => 'Zurück zu den Teams';

  @override
  String teamDetailAverageAge(String age) {
    return 'Durchschnittsalter: $age Jahre';
  }

  @override
  String get teamDetailConfirmDeleteTitle => 'Bestätigen Sie den Löschvorgang';

  @override
  String teamDetailConfirmRemoveStaff(String playerName) {
    return 'Staff $playerName wirklich entfernen?';
  }

  @override
  String teamDetailConfirmRemovePlayerTeam(String playerName) {
    return 'Spieler $playerName aus dem Team entfernen?';
  }

  @override
  String teamDetailPlayerRemoved(String playerName) {
    return '$playerName wurde entfernt.';
  }

  @override
  String teamDetailPlayerTeamRemoved(String playerName) {
    return '$playerName wurde aus dem Team entfernt.';
  }

  @override
  String get teamDetailColumnAge => 'Alter';

  @override
  String get teamDetailColumnPosition => 'Position';

  @override
  String get teamDetailColumnHeight => 'Größe';

  @override
  String get teamDetailColumnWeight => 'Gewicht';

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
    return 'Zuweisung des Trackers „$trackerName“ entfernen?';
  }

  @override
  String get teamDetailColumnApp => 'App';

  @override
  String get teamDetailPlayerDetailsTitle => 'Spielerdetails';

  @override
  String get teamDetailGrantManager => 'Managerrechte erteilen';

  @override
  String get teamDetailRevokeManager => 'Managerrechte entziehen';

  @override
  String get teamDetailRemoveFromTeam => 'Entfernen';

  @override
  String get teamDetailTrackerOwnersTitle => 'GPS-Tracker';

  @override
  String get teamDetailTrackerOwnersEmpty =>
      'Kein Tracker-Kit für Ihr Konto verfügbar.';

  @override
  String teamDetailTrackerOwnerType(String type) {
    return 'Typ: $type';
  }

  @override
  String get teamDetailTrackerOwnersSaved => 'Tracker-Kits aktualisiert.';

  @override
  String get teamDetailTrackerCoachProRequiredTitle => 'GPS-Tracker';

  @override
  String get teamDetailTrackerCoachProRequiredMessage =>
      'Das Verknüpfen von GPS-Tracker-Kits mit einem Team erfordert ein Coach Pro-Abo.';

  @override
  String get roleCoach => 'Trainer';

  @override
  String get roleExecutive => 'Funktionär';

  @override
  String get grintaStaffRoleEducator => 'Trainer / Erzieher';

  @override
  String get grintaStaffRoleMedical => 'Medizinisch';

  @override
  String get grintaStaffRoleExecutive => 'Funktionär';

  @override
  String get addStaffRoleLabel => 'Funktion';

  @override
  String get addStaffRoleHint => 'Funktion wählen';

  @override
  String get addStaffRoleRequired => 'Bitte wählen Sie eine Funktion';

  @override
  String get positionEducator => 'Betreuer/Trainer';

  @override
  String get positionExecutive => 'Funktionär';

  @override
  String get positionGoalkeeper => 'Torwart';

  @override
  String get positionCenterBack => 'Innenverteidiger';

  @override
  String get positionCenterBackLeft => 'Linker Innenverteidiger';

  @override
  String get positionCenterBackRight => 'Rechter Innenverteidiger';

  @override
  String get positionLeftDefender => 'Linker Verteidiger';

  @override
  String get positionRightDefender => 'Rechter Verteidiger';

  @override
  String get positionLeftBack => 'Linksverteidiger';

  @override
  String get positionRightBack => 'Rechtsverteidiger';

  @override
  String get positionLeftPiston => 'Linker Flügelspieler';

  @override
  String get positionRightPiston => 'Rechter Flügelspieler';

  @override
  String get positionDefensiveMidfielder => 'Defensives Mittelfeld';

  @override
  String get positionCentralMidfielder => 'Zentrales Mittelfeld';

  @override
  String get positionBoxToBoxMidfielder => 'Box-to-Box-Mittelfeldspieler';

  @override
  String get positionLeftMidfielder => 'Linkes Mittelfeld';

  @override
  String get positionRightMidfielder => 'Rechtes Mittelfeld';

  @override
  String get positionAttackingMidfielder => 'Offensives Mittelfeld';

  @override
  String get positionPlaymaker => 'Spielmacher';

  @override
  String get positionLeftWinger => 'Linksaußen';

  @override
  String get positionRightWinger => 'Rechtsaußen';

  @override
  String get positionSecondStriker => 'Zweiter Stürmer';

  @override
  String get positionCenterForward => 'Mittelstürmer';

  @override
  String get positionStriker => 'Torschütze';

  @override
  String get positionAttacker => 'Stürmer';

  @override
  String get positionDefender => 'Verteidiger';

  @override
  String get positionMidfielder => 'Mittelfeld';

  @override
  String get positionForward => 'Stürmer';

  @override
  String get teamParamsCustomThresholds => 'Benutzerdefinierte Schwellenwerte';

  @override
  String get teamParamsDefaultThresholds => 'Standardschwellenwerte';

  @override
  String get teamParamsBackToTeam => 'Zurück zum Team';

  @override
  String get teamParamsDeleteCustomizationBody =>
      'Die spezifischen Einstellungen für dieses Team werden gelöscht. Das Team verwendet dann die Standardeinstellungen.';

  @override
  String get teamParamsCustomizationRemoved =>
      'Personalisierung entfernt. Es werden die Standardeinstellungen verwendet.';

  @override
  String teamParamsZoneMaxGreaterThanMin(String label) {
    return 'Zone \"$label\" muss eine obere Grenze über der unteren Grenze haben.';
  }

  @override
  String get teamParamsOnlyLastZoneEmptyMax =>
      'Nur die letzte Zone kann ein leeres Max-Terminal haben.';

  @override
  String teamParamsZonesOverlap(String zoneA, String zoneB) {
    return 'Die Zonen \"$zoneA\" und \"$zoneB\" überschneiden sich.';
  }

  @override
  String get teamParamsCustomizeZonesHint =>
      'Sie können die verwendeten Zonen frei anpassen, um die in jeder Zone verbrachte Zeit zu berechnen.';

  @override
  String get teamParamsZonesReadOnly =>
      'Nur nach Rücksprache: Geschwindigkeitszonen können nicht geändert werden.';

  @override
  String get teamParamsInvalidInteger => 'Ungültiger ganzzahliger Wert';

  @override
  String get teamParamsInvalidNumber => 'Ungültiger numerischer Wert';

  @override
  String teamParamsZoneTitle(int index) {
    return 'Zone $index';
  }

  @override
  String get hintRequiredField => 'Erforderliches Feld';

  @override
  String get fieldSnackbarGoogleMapsKeyMissing =>
      'Fehlender Google Maps-Schlüssel für die Adresssuche.';

  @override
  String get fieldMapModeHelp => 'Kartenmodus: Verschiebt oder zoomt die Karte';

  @override
  String get fieldSideLeft => 'Linke Seite';

  @override
  String get fieldSideRight => 'Rechte Seite';

  @override
  String get fieldEstimatedAddress => 'Geschätzte Adresse';

  @override
  String get fieldAddressUnavailable =>
      'Für diese Stelle ist keine Postanschrift verfügbar.';

  @override
  String get fieldGpsPositionsTitle => 'GPS-Geländepositionen';

  @override
  String get fieldAverageLength => 'Durchschnittliche Länge';

  @override
  String get fieldAverageWidth => 'Durchschnittliche Breite';

  @override
  String get trackerParamDefault => 'Standardeinstellung';

  @override
  String trackerParamTeam(String teamId) {
    return 'Team-Param $teamId';
  }

  @override
  String get halfFirst => '1. Hälfte';

  @override
  String get halfSecond => '2. Hälfte';

  @override
  String halfNth(int index) {
    return '$index. Halbzeit';
  }

  @override
  String get halfFirstShort => '1';

  @override
  String get halfSecondShort => '2';

  @override
  String get halfMatchShort => 'Übereinstimmen';

  @override
  String get tabSpeedZonesShort => 'Geschwindigkeit';

  @override
  String get fieldZoneAttackLeftShort => 'Att. LINKS';

  @override
  String get fieldZoneAttackRightShort => 'Att. RECHTS';

  @override
  String get fieldZoneMidLeftShort => 'Mil. LINKS';

  @override
  String get fieldZoneMidRightShort => 'Mil. RECHTS';

  @override
  String get fieldZoneDefenseLeftShort => 'Def. LINKS';

  @override
  String get fieldZoneDefenseRightShort => 'Def. RECHTS';

  @override
  String get fieldZoneAttackLeft => 'Linker Angriff';

  @override
  String get fieldZoneAttackRight => 'Rechter Angriff';

  @override
  String get fieldZoneMidLeft => 'Linker Mittelfeldspieler';

  @override
  String get fieldZoneMidRight => 'Rechts in der Mitte';

  @override
  String get fieldZoneDefenseLeft => 'Linke Verteidigung';

  @override
  String get fieldZoneDefenseRight => 'Rechte Verteidigung';

  @override
  String get halfFirstUnavailable => '1. Halbzeit nicht verfügbar';

  @override
  String get halfSecondUnavailable => '2. Hälfte nicht verfügbar';

  @override
  String asiHeatmapPointCount(int count, String period) {
    return '$count Punkt(e) - $period';
  }

  @override
  String metricsEvolutionTitle(String metric) {
    return 'Verlauf - $metric';
  }

  @override
  String trainingOnDate(String date) {
    return 'Training am $date';
  }

  @override
  String get subscriptionPaywallTitle => 'Upgrade auf Grinta Premium';

  @override
  String get subscriptionPaywallSubtitle =>
      'Schalten Sie alle Funktionen für die Verfolgung Ihrer Teams und Spieler frei.';

  @override
  String get subscriptionPaywallLater => 'Später';

  @override
  String get subscriptionOfferingCoach => 'Trainer';

  @override
  String get subscriptionOfferingPlayer => 'Spieler';

  @override
  String get subscriptionTierCoachBasic => 'Coach Basic';

  @override
  String get subscriptionTierCoachBasicDesc =>
      'Wesentliches Teammanagement: Kalender, Kader und Basis-Statistiken.';

  @override
  String get subscriptionTierCoachElite => 'Coach Elite';

  @override
  String get subscriptionTierCoachEliteDesc =>
      'Erweiterte Analysen, taktische Aufstellungen und volle Coach-Tools.';

  @override
  String get subscriptionTierCoachPro => 'Coach Pro';

  @override
  String get subscriptionTierCoachProDesc =>
      'Alles aus Elite plus GPS-Tracker, Heatmaps und Pro-Exporte.';

  @override
  String get subscriptionTierPlayer => 'Spieler';

  @override
  String get subscriptionTierPlayerDesc =>
      'Verfolgen Sie Ihre Leistung, persönliche Stats und Fortschritt.';

  @override
  String get subscriptionPerMonth => '/Monat';

  @override
  String get subscriptionPerYear => '/Jahr';

  @override
  String get subscriptionBillingMonthly => 'Monatlich';

  @override
  String get subscriptionBillingYearly => 'Jährlich';

  @override
  String get subscriptionAnnualSavings => '2 Monate gratis';

  @override
  String get subscriptionSubscribe => 'Abonnieren';

  @override
  String get subscriptionTierActive => 'Aktives Abonnement';

  @override
  String get subscriptionRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get subscriptionAutoRenewLegal =>
      'Das Abonnement verlängert sich automatisch. Sie können jederzeit in den Einstellungen von App Store oder Google Play kündigen.';

  @override
  String get subscriptionStoreUnavailable =>
      'In-App-Käufe sind auf dieser Plattform nicht verfügbar.';

  @override
  String get subscriptionAlreadyActive =>
      'Sie haben bereits ein aktives Abonnement.';

  @override
  String get subscriptionProductNotFound =>
      'Produkt nicht gefunden. RevenueCat-Konfiguration prüfen.';

  @override
  String get subscriptionOfferingsUnavailable =>
      'Abonnement-Angebote konnten nicht geladen werden. Verbindung und RevenueCat-Web-Offering prüfen und erneut versuchen.';

  @override
  String get subscriptionPurchaseFailed =>
      'Kauf fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get subscriptionRestoreNone => 'Keine Käufe zum Wiederherstellen.';

  @override
  String get subscriptionRestoreFailed => 'Wiederherstellung fehlgeschlagen.';

  @override
  String get subscriptionPromptTitle => 'Premium werden';

  @override
  String get subscriptionPromptMessage =>
      'Nutzen Sie alle Grinta-Funktionen mit einem passenden Abonnement.';

  @override
  String get subscriptionPromptAction => 'Angebote ansehen';

  @override
  String get subscriptionMenu => 'Abonnement';

  @override
  String get subscriptionDetailsTitle => 'Abonnement';

  @override
  String get subscriptionTier => 'Tarif';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Verlängert am $date';
  }

  @override
  String get subscriptionNone => 'Kein aktives Abonnement';

  @override
  String subscriptionTrialEnds(String date) {
    return 'Test endet am $date';
  }

  @override
  String get subscriptionPeriodLabel => 'Zeitraum';

  @override
  String get subscriptionRenewalLabel => 'Verlängerung';

  @override
  String get subscriptionBillingPeriodMonthly => 'Monatlich';

  @override
  String get subscriptionBillingPeriodYearly => 'Jährlich';

  @override
  String get subscriptionStatusActive => 'Aktiv';

  @override
  String get subscriptionChangePlan => 'Tarif wechseln';

  @override
  String get subscriptionChangePlanTitle => 'Abonnement ändern';

  @override
  String get subscriptionChangePlanSubtitle =>
      'Wechseln Sie zwischen Coach und Spieler, ändern Sie die Stufe oder den Abrechnungszeitraum.';

  @override
  String get subscriptionChangePlanConfirm => 'Änderung bestätigen';

  @override
  String get subscriptionCurrentPlan => 'Aktueller Tarif';

  @override
  String get subscriptionPlanChanged => 'Ihr Abonnement wurde aktualisiert.';

  @override
  String subscriptionLimitMaxTeamsReached(int max) {
    return 'Sie haben die maximale Anzahl an Teams ($max) für Ihr Abonnement erreicht.';
  }

  @override
  String subscriptionLimitMaxPlayersReached(int max) {
    return 'Sie haben die maximale Anzahl an Spielern ($max) für dieses Team erreicht.';
  }

  @override
  String get subscriptionLimitPlayerTierOnlySelf =>
      'Mit Ihrem Spieler-Abo können Sie nur Ihr eigenes Profil zu einem Team hinzufügen.';

  @override
  String subscriptionLimitMaxProfilesReached(int max) {
    return 'Sie haben die maximale Anzahl an Profilen ($max) für Ihr Abonnement erreicht.';
  }

  @override
  String get subscriptionLimitProfileUpgradeTitle => 'Zusätzliche Profile';

  @override
  String get subscriptionLimitProfileUpgradeMessage =>
      'Wechseln Sie zu einem kostenpflichtigen Abonnement, um zusätzliche Profile zu erstellen.';

  @override
  String get subscriptionLimitProfileCoachBasicTitle => 'Zusätzliche Profile';

  @override
  String get subscriptionLimitProfileCoachBasicMessage =>
      'Wechseln Sie zu Elite oder Pro, um bis zu 3 Profile zu erstellen.';

  @override
  String get subscriptionLimitProfilePremiumBadge => 'Premium';

  @override
  String get subscriptionLimitTeamUpgradeTitle => 'Zusätzliche Teams';

  @override
  String get subscriptionLimitTeamUpgradeMessage =>
      'Wechseln Sie zum Spieler-Abonnement, um weitere Teams zu erstellen und Ihren Kader zu verwalten.';

  @override
  String get subscriptionLimitTeamCoachBasicTitle => 'Zusätzliche Teams';

  @override
  String get subscriptionLimitTeamCoachBasicMessage =>
      'Wechseln Sie zu Elite oder Pro, um weitere Teams zu erstellen.';

  @override
  String get subscriptionLimitTeamDetailBlockedTitle => 'Teamverwaltung';

  @override
  String get subscriptionLimitTeamDetailBlockedMessage =>
      'Wechseln Sie zum Spieler-Abonnement, um auf Teamdetails zuzugreifen und Ihren Kader zu verwalten.';

  @override
  String get subscriptionLimitTeamCreatedFreePlayer =>
      'Ihr Team wurde erstellt. Upgraden Sie, um auf die Teamdetails zuzugreifen.';

  @override
  String get trialStatusTitle => 'Kostenlose Testphase';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage verbleibend',
      one: '1 Tag verbleibend',
    );
    return '$_temp0';
  }

  @override
  String get shopTitle => 'Grinta Shop';

  @override
  String get shopPromoTitle => 'Shop-Angebot';

  @override
  String get shopPromoCta => 'Angebot ansehen';

  @override
  String get shopBrowseAll => 'Shop durchsuchen';

  @override
  String get shopLoadError => 'Der Shop konnte nicht geladen werden.';

  @override
  String get shopRetry => 'Erneut versuchen';

  @override
  String get legalPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get legalTermsOfService => 'Nutzungsbedingungen';

  @override
  String get actionDeleteAccount => 'Konto löschen';

  @override
  String get actionDeleteAccountConfirmTitle => 'Konto löschen?';

  @override
  String get actionDeleteAccountConfirmMessage =>
      'Diese Aktion ist endgültig. Ihr Konto, Ihr Mitgliederprofil und zugehörige Daten werden gelöscht.';

  @override
  String errorDeleteAccount(String details) {
    return 'Konto konnte nicht gelöscht werden: $details';
  }

  @override
  String get errorDeleteAccountRequiresRecentLogin =>
      'Aus Sicherheitsgründen melden Sie sich ab, erneut an und versuchen Sie es dann erneut.';

  @override
  String get actionDeleteTeam => 'Team löschen';

  @override
  String get teamDeleteConfirmTitle => 'Team löschen?';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return 'Möchten Sie „$teamName“ wirklich löschen? Diese Aktion ist endgültig. Alle teambezogenen Daten (Mitglieder, Spiele, Statistiken usw.) werden gelöscht.';
  }

  @override
  String teamDeleteSuccess(String teamName) {
    return 'Team „$teamName“ wurde gelöscht.';
  }

  @override
  String get teamEditNameTitle => 'Modifier le nom de l\'équipe';

  @override
  String get teamEditNameSuccess => 'Nom de l\'équipe mis à jour.';

  @override
  String get calendarSyncToggleLabel => 'Kalender-Sync';

  @override
  String get calendarSyncToggleSubtitle =>
      'Aktualisierung beim Öffnen der Agenda (max. 1×/15 Min.)';

  @override
  String get calendarSyncWebSubtitle =>
      'ICS-Datei herunterladen und in den Kalender importieren';

  @override
  String get calendarSyncWebRedownloadHint =>
      'Tippen, um die Kalenderdatei erneut herunterzuladen';

  @override
  String get calendarSyncWebDownloaded =>
      'Kalenderdatei heruntergeladen. Importiere sie in deine Kalender-App.';

  @override
  String get calendarSyncPermissionDenied =>
      'Kalenderzugriff wurde verweigert. Aktivieren Sie ihn in den Geräteeinstellungen.';

  @override
  String get calendarSyncCalendarCreationFailed =>
      'Der Grinta-Kalender konnte auf diesem Gerät nicht erstellt werden.';

  @override
  String get calendarSyncEnableFailed =>
      'Kalendersynchronisation konnte nicht aktiviert werden. Bitte versuchen Sie es erneut.';

  @override
  String get calendarSyncForceNow => 'Jetzt synchronisieren';

  @override
  String get calendarSyncForceSuccess => 'Kalender synchronisiert.';

  @override
  String get calendarSyncForceFailed =>
      'Synchronisation fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get settingsDevicesSection => 'Appareils/Applications';

  @override
  String get settingsDevicesClose => 'Fermer';

  @override
  String get settingsDevicesSync => 'Synchroniser';

  @override
  String get settingsDevicesConnectedTitle =>
      'Appareils/applications connectés';

  @override
  String get settingsDevicesConnectedStatus => 'Connecté';

  @override
  String get settingsDevicesDisconnect => 'Déconnecter';

  @override
  String get settingsDevicesNoConnected =>
      'Aucun appareil ou application connecté';

  @override
  String settingsDevicesBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils/applications connectés',
      one: '1 appareil/application connecté',
      zero: 'Aucun appareil/application connecté',
    );
    return '$_temp0';
  }

  @override
  String get wearableDeviceTypeLabel => 'Type d\'appareil/application';

  @override
  String get wearableDeviceWhoop => 'Whoop';

  @override
  String get wearableDeviceStrava => 'Strava';

  @override
  String get wearableDevicePolar => 'Polar';

  @override
  String get wearableDeviceFitbit => 'Fitbit';

  @override
  String get wearableDeviceAppleHealth => 'Apple Forme';

  @override
  String get wearableDeviceGoogleHealthConnect => 'Google Fit / Health Connect';

  @override
  String get whoopConnectToggleLabel => 'Sync. Whoop';

  @override
  String get whoopConnectToggleSubtitle =>
      'Connecte ton compte Whoop pour importer récupération, sommeil et entraînements';

  @override
  String get whoopConnectToggleConnectedSubtitle =>
      'Whoop connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get whoopConnectSuccess => 'Compte Whoop connecté.';

  @override
  String get whoopConnectFailed => 'La connexion Whoop a échoué. Réessayez.';

  @override
  String get whoopConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Whoop.';

  @override
  String get whoopConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Whoop.';

  @override
  String get whoopDisconnectFailed => 'La déconnexion Whoop a échoué.';

  @override
  String get whoopCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get whoopCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get whoopCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Whoop.';

  @override
  String get whoopMetricRecovery => 'Récupération';

  @override
  String get whoopMetricCycles => 'Cycles';

  @override
  String get whoopMetricSleep => 'Sommeil';

  @override
  String get whoopMetricWorkout => 'Entraînements';

  @override
  String get whoopMetricProfile => 'Profil';

  @override
  String get whoopMetricBodyMeasurement => 'Mensurations';

  @override
  String get whoopCoachConnectTitle => 'Whoop';

  @override
  String whoopCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Whoop de $playerName';
  }

  @override
  String get whoopCoachConnectAction => 'Connecter';

  @override
  String whoopCoachConnectConnectedSubtitle(String playerName) {
    return 'Whoop connecté pour $playerName';
  }

  @override
  String get stravaConnectToggleSubtitle =>
      'Connecte ton compte Strava pour importer activités et entraînements';

  @override
  String get stravaConnectToggleConnectedSubtitle =>
      'Strava connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get stravaConnectSuccess => 'Compte Strava connecté.';

  @override
  String get stravaConnectFailed => 'La connexion Strava a échoué. Réessayez.';

  @override
  String get stravaConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Strava.';

  @override
  String get stravaConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Strava.';

  @override
  String get stravaDisconnectFailed => 'La déconnexion Strava a échoué.';

  @override
  String get stravaCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Strava.';

  @override
  String get stravaMetricActivities => 'Activités';

  @override
  String get stravaMetricProfile => 'Profil';

  @override
  String stravaCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Strava de $playerName';
  }

  @override
  String stravaCoachConnectConnectedSubtitle(String playerName) {
    return 'Strava connecté pour $playerName';
  }

  @override
  String get polarConnectToggleSubtitle =>
      'Connecte ton compte Polar pour importer entraînements, sommeil et fréquence cardiaque depuis Loop ou Verity Sense via Polar Flow';

  @override
  String get polarConnectToggleConnectedSubtitle =>
      'Polar connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get polarConnectSuccess => 'Compte Polar connecté.';

  @override
  String get polarConnectFailed => 'La connexion Polar a échoué. Réessayez.';

  @override
  String get polarConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Polar.';

  @override
  String get polarConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Polar.';

  @override
  String get polarDisconnectFailed => 'La déconnexion Polar a échoué.';

  @override
  String get polarCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get polarCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get polarCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Polar.';

  @override
  String get polarMetricTraining => 'Entraînements';

  @override
  String get polarMetricSleep => 'Sommeil';

  @override
  String get polarMetricRecoveryHr => 'Récupération / fréquence cardiaque';

  @override
  String get polarMetricProfile => 'Profil';

  @override
  String get polarMetricBody => 'Mensurations';

  @override
  String polarCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Polar de $playerName';
  }

  @override
  String polarCoachConnectConnectedSubtitle(String playerName) {
    return 'Polar connecté pour $playerName';
  }

  @override
  String get fitbitConnectToggleSubtitle =>
      'Connecte ton compte Fitbit pour importer activité, fréquence cardiaque, sommeil et poids depuis ton bracelet via le cloud Fitbit';

  @override
  String get fitbitConnectToggleConnectedSubtitle =>
      'Fitbit connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get fitbitConnectSuccess => 'Compte Fitbit connecté.';

  @override
  String get fitbitConnectFailed => 'La connexion Fitbit a échoué. Réessayez.';

  @override
  String get fitbitConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Fitbit.';

  @override
  String get fitbitConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Fitbit.';

  @override
  String get fitbitDisconnectFailed => 'La déconnexion Fitbit a échoué.';

  @override
  String get fitbitCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get fitbitCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get fitbitCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Fitbit.';

  @override
  String get fitbitMetricActivity => 'Activité / entraînements / pas';

  @override
  String get fitbitMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get fitbitMetricSleep => 'Sommeil';

  @override
  String get fitbitMetricProfile => 'Profil';

  @override
  String get fitbitMetricBody => 'Poids / mensurations';

  @override
  String fitbitCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Fitbit de $playerName';
  }

  @override
  String fitbitCoachConnectConnectedSubtitle(String playerName) {
    return 'Fitbit connecté pour $playerName';
  }

  @override
  String get appleHealthConnectToggleSubtitle =>
      'Connecte Apple Forme pour importer entraînements, fréquence cardiaque et énergie active depuis l\'app Santé (iOS uniquement)';

  @override
  String get appleHealthConnectToggleConnectedSubtitle =>
      'Apple Forme connecté — synchronisation complète des entraînements à venir (Phase 2)';

  @override
  String get appleHealthConnectSuccess => 'Apple Forme connecté.';

  @override
  String get appleHealthConnectFailed =>
      'La connexion Apple Forme a échoué. Réessayez.';

  @override
  String get appleHealthConnectDenied =>
      'L\'accès Santé a été refusé. Active-le dans Réglages → Santé → Accès aux données et appareils → Grinta.';

  @override
  String get appleHealthConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Apple Forme.';

  @override
  String get appleHealthIosOnlyMessage =>
      'Apple Forme est disponible uniquement sur iPhone. Les données sont lues sur l\'appareil via Apple HealthKit.';

  @override
  String get appleHealthDisconnectFailed =>
      'La déconnexion Apple Forme a échoué.';

  @override
  String get appleHealthCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get appleHealthCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get appleHealthCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Apple Forme.';

  @override
  String get appleHealthMetricActivity => 'Entraînements / activité';

  @override
  String get appleHealthMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get appleHealthMetricActiveEnergy => 'Énergie active';

  @override
  String get appleHealthMetricSleep => 'Sommeil';

  @override
  String appleHealthCoachConnectSubtitle(String playerName) {
    return 'Connecter Apple Forme pour $playerName';
  }

  @override
  String appleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Apple Forme connecté pour $playerName';
  }

  @override
  String get googleHealthConnectToggleSubtitle =>
      'Connecte Google Fit pour importer entraînements, fréquence cardiaque et énergie active depuis Health Connect (Android uniquement)';

  @override
  String get googleHealthConnectToggleConnectedSubtitle =>
      'Google Fit / Health Connect connecté — synchronisation complète des entraînements à venir (Phase 2)';

  @override
  String get googleHealthConnectSuccess =>
      'Google Fit / Health Connect connecté.';

  @override
  String get googleHealthConnectFailed =>
      'La connexion Google Fit / Health Connect a échoué. Réessayez.';

  @override
  String get googleHealthConnectDenied =>
      'L\'accès Health Connect a été refusé. Active-le dans Health Connect → Autorisations des applis → Grinta.';

  @override
  String get googleHealthConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Google Fit / Health Connect.';

  @override
  String get googleHealthAndroidOnlyMessage =>
      'Google Fit / Health Connect est disponible uniquement sur Android. Les données sont lues sur l\'appareil via Health Connect.';

  @override
  String get googleHealthDisconnectFailed =>
      'La déconnexion Google Fit / Health Connect a échoué.';

  @override
  String get googleHealthCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get googleHealthCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get googleHealthCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Google Fit / Health Connect.';

  @override
  String get googleHealthMetricActivity => 'Entraînements / activité';

  @override
  String get googleHealthMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get googleHealthMetricActiveEnergy => 'Énergie active';

  @override
  String get googleHealthMetricSleep => 'Sommeil';

  @override
  String googleHealthCoachConnectSubtitle(String playerName) {
    return 'Connecter Google Fit / Health Connect pour $playerName';
  }

  @override
  String googleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Google Fit / Health Connect connecté pour $playerName';
  }

  @override
  String get createTrainingTitle => 'Neue Trainingseinheit';

  @override
  String get createTrainingTeam => 'Team';

  @override
  String get createTrainingTeamRequired => 'Team auswählen';

  @override
  String get createTrainingDate => 'Datum';

  @override
  String get createTrainingTime => 'Uhrzeit';

  @override
  String get createTrainingDuration => 'Dauer';

  @override
  String createTrainingDurationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get createTrainingRecurrent => 'Wiederkehrend';

  @override
  String get createTrainingRecurrentDays => 'Wochentag(e)';

  @override
  String get createTrainingRecurrentDaysRequired =>
      'Mindestens einen Tag auswählen';

  @override
  String get createTrainingRecurrentFrom => 'Von';

  @override
  String get createTrainingRecurrentTo => 'Bis';

  @override
  String get createTrainingRecurrentInvalidRange =>
      'Das Enddatum darf nicht vor dem Startdatum liegen';

  @override
  String get createTrainingWithTracker => 'Mit GPS-Tracker';

  @override
  String get createTrainingSelectOwner => 'Tracker-Kit (Besitzer)';

  @override
  String get createTrainingOwnerRequired => 'Tracker-Besitzer auswählen';

  @override
  String get createTrainingNoOwners =>
      'Diesem Team ist kein Tracker-Kit zugewiesen.';

  @override
  String get createTrainingNoManagedTeams =>
      'Sie verwalten in dieser Saison kein Team.';

  @override
  String createTrainingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainings erstellt',
      one: '1 Training erstellt',
    );
    return '$_temp0';
  }

  @override
  String get createTrainingError =>
      'Training konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get createTrainingSubmit => 'Training erstellen';

  @override
  String get createTrainingRecurrentConfirmTitle => 'Wiederkehrendes Training';

  @override
  String get createTrainingRecurrentConfirmMessage =>
      'Möchten Sie die Wiederholungen erstellen?';

  @override
  String get editTrainingTitle => 'Training bearbeiten';

  @override
  String get editTrainingSubmit => 'Speichern';

  @override
  String get editTrainingSaved => 'Training aktualisiert';

  @override
  String get editTrainingError =>
      'Training konnte nicht aktualisiert werden. Bitte erneut versuchen.';

  @override
  String get trainingDeleteConfirmTitle => 'Training löschen?';

  @override
  String get trainingDeleteConfirmMessage =>
      'Möchten Sie dieses Training wirklich löschen? Diese Aktion ist endgültig.';

  @override
  String get trainingDeleteRecurrentTitle =>
      'Supprimer l\'entraînement récurrent ?';

  @override
  String get trainingDeleteRecurrentMessage =>
      'Souhaitez-vous supprimer toutes les récurrences de cette série ?';

  @override
  String get trainingDeleteThisOccurrence => 'Cette occurrence uniquement';

  @override
  String get trainingDeleteAllOccurrences => 'Toutes les occurrences';

  @override
  String get trainingDeleted => 'Training gelöscht';

  @override
  String get trainingDeleteError =>
      'Training konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get finishTrainingTitle => 'Training beenden';

  @override
  String get trainingFinishConfirmTitle => 'Training beenden?';

  @override
  String get trainingFinishConfirmMessage =>
      'Nicht verfügbare Spieler, die als anwesend markiert sind, werden als abwesend gesetzt. Möchten Sie dieses Training beenden?';

  @override
  String get trainingFinished => 'Training beendet';

  @override
  String get trainingFinishError =>
      'Training konnte nicht beendet werden. Bitte erneut versuchen.';

  @override
  String get trainingIntenseFinishTitle => 'Sensordaten werden abgerufen';

  @override
  String get trainingIntenseFinishMessage =>
      'Daten der anwesenden Spieler mit zugewiesenem Tracker werden abgerufen. Fenster nicht schließen.';

  @override
  String get trainingIntenseResyncButton => 'Re sync';

  @override
  String get trainingIntenseResyncTitle => 'Sensordaten erneut synchronisieren';

  @override
  String get trainingIntenseResyncMessage => 'Sensordaten für das gesamte Trainingsfenster (Start → Ende) werden erneut abgerufen. Fenster nicht schließen.';

  @override
  String get trainingIntenseResyncSuccess => 'Sensordaten erneut synchronisiert.';



  @override
  String get trainingIntenseFinishSyncing => 'Synchronisierung läuft…';

  @override
  String get trainingIntenseFinishStagePending => 'Ausstehend';

  @override
  String get trainingIntenseFinishStageFetching => 'Rohdaten werden abgerufen…';

  @override
  String get trainingIntenseFinishStageConverting =>
      'Daten werden konvertiert…';

  @override
  String get trainingIntenseFinishStageAnalyzing => 'Analyse läuft…';

  @override
  String get trainingIntenseFinishStageDone => 'Fertig';

  @override
  String get trainingIntenseFinishStageError => 'Fehler';

  @override
  String get trainingIntenseFinishNoTrackers =>
      'Kein anwesender Spieler hat einen Tracker. Training kann ohne Abruf beendet werden.';

  @override
  String get trainingIntenseFinishPartialError =>
      'Einige Abrufe sind fehlgeschlagen. Problem beheben und erneut versuchen.';

  @override
  String get intenseLiveTitle => 'Live';

  @override
  String get intenseLiveOpenTooltip => 'Live-Trackerdaten anzeigen';

  @override
  String get intenseLiveSelectPlayer => 'Spieler auswählen';

  @override
  String get intenseLiveNoPlayers =>
      'Kein anwesender Spieler mit zugewiesenem Tracker';

  @override
  String get intenseLiveRefresh => 'Aktualisieren';

  @override
  String intenseLiveLastUpdate(String time) {
    return 'Aktualisiert um $time';
  }

  @override
  String get tabLive => 'Live';

  @override
  String get tabLiveShort => 'Live';

  @override
  String get createMatchTitle => 'Neues Spiel';

  @override
  String get createMatchTeam => 'Mannschaft';

  @override
  String get createMatchTeamRequired => 'Mannschaft auswählen';

  @override
  String get createMatchHome => 'Heimspiel';

  @override
  String get createMatchFriendly => 'Freundschaftsspiel';

  @override
  String get createMatchDate => 'Datum';

  @override
  String get createMatchTime => 'Uhrzeit';

  @override
  String get createMatchDuration => 'Dauer';

  @override
  String createMatchDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createMatchOpponent => 'Gegner';

  @override
  String get createMatchSelectOpponentClub => 'Verein suchen';

  @override
  String get createMatchClubNotFound => 'Verein nicht gefunden';

  @override
  String get createMatchOpponentNameManual => 'Name des Gegners';

  @override
  String get createMatchOpponentRequired => 'Gegner angeben';

  @override
  String get createMatchVenue => 'Spielort / Feldadresse';

  @override
  String get createMatchSurface => 'Spielfläche';

  @override
  String get createMatchSurfaceSynthetic => 'Kunstrasen';

  @override
  String get createMatchSurfaceNatural => 'Naturrasen';

  @override
  String get createMatchWithTracker => 'Mit GPS-Tracker';

  @override
  String get createMatchSelectOwner => 'Tracker-Kit (Eigentümer)';

  @override
  String get createMatchOwnerRequired => 'Tracker-Eigentümer auswählen';

  @override
  String get createMatchNoOwners =>
      'Dieser Mannschaft ist kein Tracker-Kit zugewiesen.';

  @override
  String get createMatchNoManagedTeams =>
      'Sie verwalten in dieser Saison keine Mannschaft.';

  @override
  String get createMatchSaved => 'Spiel erstellt';

  @override
  String get createMatchError =>
      'Spiel konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get createMatchSubmit => 'Spiel erstellen';

  @override
  String get editMatchTitle => 'Spiel bearbeiten';

  @override
  String get editMatchSubmit => 'Speichern';

  @override
  String get editMatchSaved => 'Spiel aktualisiert';

  @override
  String get editMatchError =>
      'Spiel konnte nicht aktualisiert werden. Bitte erneut versuchen.';

  @override
  String get matchDeleteConfirmTitle => 'Spiel löschen?';

  @override
  String get matchDeleteConfirmMessage =>
      'Möchten Sie dieses Spiel wirklich löschen? Diese Aktion ist endgültig.';

  @override
  String get matchRemoveFromTeamConfirmTitle =>
      'Spiel aus dem Kalender entfernen?';

  @override
  String get matchRemoveFromTeamConfirmMessage =>
      'Das Spiel wird aus dem Kalender Ihrer Mannschaft entfernt. Für andere Mannschaften bleibt es sichtbar.';

  @override
  String get matchDeleted => 'Spiel gelöscht';

  @override
  String get matchRemovedFromTeam =>
      'Spiel aus dem Kalender Ihrer Mannschaft entfernt';

  @override
  String get matchDeleteError =>
      'Spiel konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get teamDetailManageUnavailabilities => 'Abwesenheiten verwalten';

  @override
  String get manageUnavailabilitiesTitle => 'Abwesenheiten';

  @override
  String get manageUnavailabilitiesEmpty =>
      'Keine Abwesenheiten in dieser Saison.';

  @override
  String get manageUnavailabilitiesAdd => 'Abwesenheit hinzufügen';

  @override
  String get manageUnavailabilitiesEditTitle => 'Abwesenheit bearbeiten';

  @override
  String get manageUnavailabilitiesFromDate => 'Von';

  @override
  String get manageUnavailabilitiesToDate => 'Bis';

  @override
  String get manageUnavailabilitiesType => 'Typ';

  @override
  String get manageUnavailabilitiesDetails => 'Details';

  @override
  String get manageUnavailabilitiesDetailsHint => 'Optionale Details';

  @override
  String get manageUnavailabilitiesVisible => 'Für das Team sichtbar';

  @override
  String get manageUnavailabilitiesVisibleHint =>
      'Wenn deaktiviert, sehen nur Manager diesen Eintrag';

  @override
  String manageUnavailabilitiesDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get manageUnavailabilitiesHidden => 'Ausgeblendet';

  @override
  String get manageUnavailabilitiesSaved => 'Abwesenheit gespeichert';

  @override
  String get manageUnavailabilitiesDeleted => 'Abwesenheit gelöscht';

  @override
  String get manageUnavailabilitiesError =>
      'Abwesenheit konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get manageUnavailabilitiesDeleteError =>
      'Abwesenheit konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get manageUnavailabilitiesDeleteConfirmTitle => 'Abwesenheit löschen?';

  @override
  String get manageUnavailabilitiesDeleteConfirmMessage =>
      'Diese Aktion ist endgültig.';

  @override
  String get manageUnavailabilitiesInvalidRange =>
      'Das Enddatum darf nicht vor dem Startdatum liegen';

  @override
  String get manageUnavailabilitiesTypeRequired => 'Bitte einen Typ auswählen';

  @override
  String get unavailabilityTypeHoliday => 'Urlaub';

  @override
  String get unavailabilityTypeUnwell => 'Krank';

  @override
  String get unavailabilityTypeInjured => 'Verletzt';

  @override
  String get unavailabilityTypeOther => 'Sonstiges';

  @override
  String teamStatsScreenTitle(String teamName) {
    return 'Statistiken — $teamName';
  }

  @override
  String get teamStatsTabAnalysis => 'Analyse';

  @override
  String get teamStatsTabCalendars => 'Kalender';

  @override
  String get teamStatsCompetitionFilterLabel => 'Wettbewerbe';

  @override
  String get teamStatsOpponentFilterLabel => 'Club';

  @override
  String get teamStatsNoOpponents => 'Keine Clubs in diesem Wettbewerb';

  @override
  String get teamStatsTabTrainings => 'Trainingseinheiten';

  @override
  String get teamStatsTabOpponents => 'Gegner';

  @override
  String get teamStatsSubTabMatches => 'Spiele';

  @override
  String get teamStatsSubTabRanking => 'Tabelle';

  @override
  String get teamStatsSubTabGoals => 'Tore';

  @override
  String get teamStatsSubTabPlayers => 'Spieler';

  @override
  String get teamStatsSubTabTypicalTeam => 'Typisches Team';

  @override
  String get teamStatsTypicalTeamStartersSection => 'Wahrscheinliche Startelf';

  @override
  String get teamStatsTypicalTeamSubstitutesSection =>
      'Wahrscheinliche Ersatzspieler';

  @override
  String teamStatsTypicalTeamStartsLabel(int starts, int total) {
    return '$starts/$total Starts';
  }

  @override
  String teamStatsTypicalTeamSubsLabel(int subs, int total) {
    return '$subs/$total als Einwechselspieler';
  }

  @override
  String get teamStatsTypicalTeamNoData =>
      'Keine Aufstellungsdaten für diesen Gegner verfügbar';

  @override
  String teamStatsTypicalTeamIncompleteStarters(int count) {
    return 'Nur $count Spieler mit Startelf-Daten';
  }

  @override
  String teamStatsTypicalTeamMatchesBasis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spielen mit Aufstellung',
      one: '1 Spiel mit Aufstellung',
    );
    return 'Basierend auf $_temp0';
  }

  @override
  String get teamStatsRankingAtDate => 'Aktuell';

  @override
  String get teamStatsRankingEvolution => 'Entwicklung';

  @override
  String get teamStatsRankingNoData =>
      'Keine Tabelle für diesen Wettbewerb verfügbar';

  @override
  String get teamStatsRankingSelectCompetition =>
      'Wählen Sie einen Wettbewerb, um die Tabelle anzuzeigen';

  @override
  String get teamStatsRankingColumnRank => '#';

  @override
  String get teamStatsRankingColumnTeam => 'Team';

  @override
  String get teamStatsRankingColumnPts => 'Pkt';

  @override
  String get teamStatsRankingColumnPlayed => 'Sp';

  @override
  String get teamStatsRankingColumnWon => 'S';

  @override
  String get teamStatsRankingColumnDrawn => 'U';

  @override
  String get teamStatsRankingColumnLost => 'N';

  @override
  String get teamStatsRankingColumnDiff => '+/-';

  @override
  String get teamStatsRankingAddClubs => 'Vereine vergleichen';

  @override
  String get teamStatsRankingSelectClubsTitle =>
      'Vereine zum Vergleich auswählen';

  @override
  String get teamStatsRankingOwnTeamLabel => 'Ihr Team';

  @override
  String teamStatsRankingTooltipRank(String rank) {
    return 'Rang $rank';
  }

  @override
  String get teamStatsAllCompetitions => 'Alle Wettbewerbe';

  @override
  String get teamStatsContentComingSoon => 'Inhalt folgt in Kürze';

  @override
  String get teamStatsNoCompetitions => 'Keine Wettbewerbe verfügbar';

  @override
  String get teamStatsPlayerComingSoon => 'Spieleransicht folgt in Kürze';

  @override
  String get teamStatsPeriodFullSeason => 'Gesamte Saison';

  @override
  String get teamStatsPeriodFirstHalf => '1. Halbjahr';

  @override
  String get teamStatsPeriodSecondHalf => '2. Halbjahr';

  @override
  String get teamStatsNoPlayedMatches =>
      'Keine gespielten Spiele in diesem Zeitraum';

  @override
  String teamStatsWdlMatchesDialogTitle(String outcome, String period) {
    return '$outcome — $period';
  }

  @override
  String get teamStatsTrendLabel => 'Trend';

  @override
  String get teamStatsTrendUp => 'Verbesserung';

  @override
  String get teamStatsTrendDown => 'Rückgang';

  @override
  String get teamStatsTrendFlat => 'Stabil';

  @override
  String get teamStatsTrendInsufficientData => 'Unzureichende Daten';

  @override
  String get teamStatsGoalsScored => 'Erzielte Tore';

  @override
  String get teamStatsGoalsConceded => 'Kassierte Tore';

  @override
  String get teamStatsGoalsTrendScored => 'Erzielte Tore';

  @override
  String get teamStatsGoalsTrendConceded => 'Kassierte Tore';

  @override
  String teamStatsGoalsAvgPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString/Spiel';
  }

  @override
  String teamStatsGoalsMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele',
      one: '1 Spiel',
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
  String get teamStatsPlayersColumnPlayer => 'Spieler';

  @override
  String get teamStatsPlayersColumnConvocations => 'Convo';

  @override
  String get teamStatsPlayersColumnStarts => 'Start';

  @override
  String get teamStatsPlayersColumnPlayTime => 'Spielz.';

  @override
  String get teamStatsPlayersColumnGoals => 'Tore';

  @override
  String get teamStatsPlayersNoData => 'Keine Spielerdaten für diesen Zeitraum';

  @override
  String teamStatsPlayersPlayTimeMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get teamStatsAllMonths => 'Alle Monate';

  @override
  String teamStatsTrainingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainingseinheiten',
      one: '1 Trainingseinheit',
    );
    return '$_temp0';
  }

  @override
  String get teamStatsTrainingsAttendanceRate => 'Anwesenheitsquote';

  @override
  String teamStatsTrainingsAttendanceRateValue(String value) {
    return '$value %';
  }

  @override
  String get teamStatsTrainingsNoData =>
      'Keine vergangenen Trainingseinheiten in diesem Zeitraum';

  @override
  String get teamStatsTrainingsNoSeasonMonths =>
      'Keine Monate für diese Saison verfügbar';

  @override
  String get teamStatsTrainingsColumnPresent => 'Anw.';

  @override
  String get teamStatsTrainingsColumnAbsent => 'Fehl.';

  @override
  String get teamStatsTrainingsColumnAttendanceRate => 'Quote';

  @override
  String get teamStatsTrainingsPlayersNoData =>
      'Keine Spielerdaten für diesen Zeitraum';

  @override
  String get teamStatsTrainingsGlobalSection => 'Team';

  @override
  String get teamStatsTrainingsPersonalSection => 'Meine Stats';

  @override
  String get teamStatsCalendarNoMatchdays =>
      'Keine Spiele für diesen Wettbewerb';

  @override
  String get teamStatsCalendarNoMatchesForMatchday =>
      'Keine Spiele an diesem Spieltag';

  @override
  String get teamStatsCalendarDatesLabel => 'Termine';

  @override
  String get teamStatsCalendarNoMatchDates => 'Keine Termine geplant';

  @override
  String get teamStatsCalendarDateSeparator => ', ';

  @override
  String get askDiegoTitle => 'Ask Gio';

  @override
  String get askDiegoWelcome =>
      'Hallo! Ich bin Gio. Ich kann bei Ihrem Spielplan, dem nächsten Gegner oder Teamstatistiken helfen.';

  @override
  String get askDiegoInputHint => 'Frag Gio…';

  @override
  String get askDiegoSend => 'Senden';

  @override
  String get askDiegoListen => 'Antwort anhören';

  @override
  String get askDiegoOpenScreen => 'Öffnen';

  @override
  String get askDiegoOpenOpponentStats => 'Gegnerstatistiken anzeigen';

  @override
  String get askDiegoStartListening => 'Frage diktieren';

  @override
  String get askDiegoStopListening => 'Zuhören beenden';

  @override
  String get askDiegoSpeechUnavailable =>
      'Spracherkennung ist auf diesem Gerät nicht verfügbar.';

  @override
  String get askDiegoSpeechPermissionDenied =>
      'Mikrofon- oder Spracherkennungsberechtigung verweigert. In den Einstellungen aktivieren.';

  @override
  String askDiegoSpeechError(String reason) {
    return 'Spracherkennung fehlgeschlagen: $reason';
  }

  @override
  String get askDiegoEmptyResponse => 'Ich habe gerade keine Antwort.';

  @override
  String get askDiegoCloseSpeedDial => 'Schließen';

  @override
  String askDiegoNavigationUnknown(String route) {
    return 'Unbekannte Navigation: $route';
  }

  @override
  String get askDiegoNavigationAgendaHint =>
      'Öffnen Sie den Agenda-Tab, um Ihren Kalender zu sehen.';

  @override
  String get askDiegoNavigationMatchMissing => 'Spiel-ID für Navigation fehlt.';

  @override
  String get askDiegoNavigationMatchNotFound => 'Spiel nicht gefunden.';

  @override
  String get askDiegoNavigationNoTeam => 'Kein Team ausgewählt.';

  @override
  String get askDiegoNavigationOpponentsManagerOnly =>
      'Gegnerstatistiken sind nur für Trainer verfügbar.';

  @override
  String get askDiegoNavigationOpponentsPremiumOnly =>
      'Gegnerstatistiken erfordern ein Abonnement.';

  @override
  String get settingsNotificationsSection => 'Benachrichtigungen';

  @override
  String get settingsRemindersSubtitle =>
      'Lokale Erinnerungen für Training und Spiele.';

  @override
  String get settingsRemindersEnabled => 'Erinnerungen aktivieren';

  @override
  String get settingsQuietDaysLabel => 'Ruhetage';

  @override
  String get settingsQuietHoursLabel => 'Ruhezeiten';

  @override
  String get settingsQuietHoursStart => 'Beginn';

  @override
  String get settingsQuietHoursEnd => 'Ende';

  @override
  String get settingsMorningReminderHour => 'Morgenerinnerung';

  @override
  String get reminderWeekdayMon => 'Mo';

  @override
  String get reminderWeekdayTue => 'Di';

  @override
  String get reminderWeekdayWed => 'Mi';

  @override
  String get reminderWeekdayThu => 'Do';

  @override
  String get reminderWeekdayFri => 'Fr';

  @override
  String get reminderWeekdaySat => 'Sa';

  @override
  String get reminderWeekdaySun => 'So';

  @override
  String get reminderTrainingTitle => 'Training heute';

  @override
  String reminderTrainingBody(String time) {
    return 'Training heute um $time — informiere deinen Trainer bei Abwesenheit';
  }

  @override
  String get reminderMatchOpponentStatsTitle => 'Spiel heute';

  @override
  String reminderMatchOpponentStatsBody(String time, String opponent) {
    return 'Heute um $time triffst du auf $opponent — entdecke die Statistiken';
  }

  @override
  String get trainingPresenceConfirmPresent => 'Ich bin anwesend';

  @override
  String get trainingPresenceConfirmAbsent => 'Ich bin abwesend';

  @override
  String get trainingPresenceConfirmedPresent => 'Anwesenheit bestätigt';

  @override
  String get trainingPresenceConfirmedAbsent => 'Abwesenheit gemeldet';

  @override
  String get matchDetailOpponentStats => 'Gegnerstatistiken';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle => 'Plattform-Verwaltungstools.';

  @override
  String get adminPromoCodesSection => 'Promo-Codes';

  @override
  String get adminPromoCodesSectionDesc =>
      'Abonnement-Promo-Codes erstellen und verwalten.';

  @override
  String get adminPromoCodesTitle => 'Promo-Codes';

  @override
  String get adminPromoCodeCreate => 'Code erstellen';

  @override
  String get adminPromoCodesLoadError =>
      'Promo-Codes konnten nicht geladen werden.';

  @override
  String get adminPromoCodesEmpty => 'Noch keine Promo-Codes vorhanden.';

  @override
  String get adminPromoCodeUpdateFailed =>
      'Promo-Code konnte nicht aktualisiert werden.';

  @override
  String get adminPromoCodeCreated => 'Promo-Code erstellt.';

  @override
  String adminPromoCodeEntitlementLabel(String entitlement) {
    return 'Berechtigung: $entitlement';
  }

  @override
  String adminPromoCodeUsageLabel(int used, int max) {
    return 'Nutzungen: $used / $max';
  }

  @override
  String adminPromoCodeDurationLabel(int days) {
    return 'Dauer: $days Tage';
  }

  @override
  String adminPromoCodeTeamLabel(String teamId) {
    return 'Verein: $teamId';
  }

  @override
  String adminPromoCodeExpiresLabel(String date) {
    return 'Läuft ab am: $date';
  }

  @override
  String get adminPromoCodeStatusInactive => 'Inaktiv';

  @override
  String get adminPromoCodeStatusExpired => 'Abgelaufen';

  @override
  String get adminPromoCodeStatusExhausted => 'Aufgebraucht';

  @override
  String get adminPromoCodeStatusActive => 'Aktiv';

  @override
  String get adminPromoCodeFieldCode => 'Code';

  @override
  String get adminPromoCodeFieldCodeInvalid =>
      'Der Code muss mindestens 4 Zeichen haben.';

  @override
  String get adminPromoCodeFieldEntitlement => 'Berechtigung';

  @override
  String get adminPromoCodeFieldMaxUses => 'Maximale Nutzungen';

  @override
  String get adminPromoCodeFieldMaxUsesInvalid =>
      'Geben Sie eine Zahl größer als 0 ein.';

  @override
  String get adminPromoCodeFieldDurationDays => 'Abo-Dauer (Tage)';

  @override
  String get adminPromoCodeFieldDurationDaysInvalid =>
      'Geben Sie eine Zahl größer als 0 ein.';

  @override
  String get adminPromoCodeFieldTeamId => 'Vereins-ID (optional)';

  @override
  String get adminPromoCodeFieldTeamIdHint =>
      'Einlösung auf Mitglieder dieses Vereins beschränken.';

  @override
  String get adminPromoCodeFieldExpiresOptional =>
      'Ablaufdatum festlegen (optional)';

  @override
  String get adminPromoCodeAlreadyExists =>
      'Dieser Promo-Code existiert bereits.';

  @override
  String get adminPromoCodeCreateFailed =>
      'Promo-Code konnte nicht erstellt werden.';

  @override
  String get adminPromoCodePermissionDenied =>
      'Admin-Zugriff ist erforderlich, um Promo-Codes zu verwalten.';

  @override
  String get adminPromoCodeAuthRequired =>
      'Sie müssen angemeldet sein, um Promo-Codes zu erstellen.';

  @override
  String get adminPromoCodeActions => 'Aktionen';

  @override
  String get adminPromoCodeEdit => 'Bearbeiten';

  @override
  String get adminPromoCodeEditTitle => 'Promo-Code bearbeiten';

  @override
  String get adminPromoCodeDelete => 'Löschen';

  @override
  String get adminPromoCodeDeleteConfirmTitle => 'Promo-Code löschen?';

  @override
  String adminPromoCodeDeleteConfirmMessage(String code) {
    return 'Möchten Sie den Code $code wirklich löschen? Diese Aktion ist endgültig.';
  }

  @override
  String get adminPromoCodeDeleted => 'Promo-Code gelöscht.';

  @override
  String get adminPromoCodeDeleteFailed =>
      'Promo-Code konnte nicht gelöscht werden.';

  @override
  String get adminPromoCodeUpdated => 'Promo-Code aktualisiert.';

  @override
  String get adminPromoCodeSave => 'Speichern';

  @override
  String get adminPromoCodeFieldCodeReadOnly =>
      'Der Code kann nicht geändert werden.';

  @override
  String adminPromoCodeFieldMaxUsesBelowUsed(int used) {
    return 'Die maximale Nutzung muss mindestens $used betragen (bereits eingelöst).';
  }

  @override
  String get adminPromoCodeFieldActive => 'Aktiv';

  @override
  String get adminPromoCodeClearExpiry => 'Ablaufdatum entfernen';

  @override
  String get adminPromoCodeNotFound => 'Promo-Code nicht gefunden.';

  @override
  String get adminTrackerOwnersSection => 'Tracker-Besitzer';

  @override
  String get adminTrackerOwnersSectionDesc =>
      'Tracker-Besitzer erstellen und verwalten.';

  @override
  String get adminTrackerOwnersTitle => 'Tracker-Besitzer';

  @override
  String get adminTrackerOwnersEmpty => 'Noch keine Besitzer.';

  @override
  String get adminTrackerOwnersLoadError =>
      'Besitzer konnten nicht geladen werden.';

  @override
  String get adminTrackerOwnerCreate => 'Besitzer hinzufügen';

  @override
  String get adminTrackerOwnerCreateTitle => 'Besitzer hinzufügen';

  @override
  String get adminTrackerOwnerEditTitle => 'Besitzer bearbeiten';

  @override
  String get adminTrackerOwnerFieldName => 'Name';

  @override
  String get adminTrackerOwnerFieldEmail => 'E-Mail';

  @override
  String get adminTrackerOwnerFieldFirstname => 'Vorname';

  @override
  String get adminTrackerOwnerFieldLastname => 'Nachname';

  @override
  String get adminTrackerOwnerFieldActive => 'Aktiv';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Tracker-Typ';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, Cloud-Stream)';

  @override
  String get adminTrackerOwnerFieldRequired => 'Pflichtfeld';

  @override
  String get adminTrackerOwnerFieldEmailInvalid => 'Ungültige E-Mail';

  @override
  String get adminTrackerOwnerStatusActive => 'Aktiv';

  @override
  String get adminTrackerOwnerStatusInactive => 'Inaktiv';

  @override
  String get adminTrackerOwnerSave => 'Speichern';

  @override
  String get adminTrackerOwnerDelete => 'Löschen';

  @override
  String get adminTrackerOwnerDeleteConfirmTitle => 'Besitzer löschen?';

  @override
  String adminTrackerOwnerDeleteConfirmMessage(String name) {
    return 'Möchtest du $name wirklich löschen? Diese Aktion ist endgültig.';
  }

  @override
  String get adminTrackerOwnerCreated => 'Besitzer erstellt.';

  @override
  String get adminTrackerOwnerUpdated => 'Besitzer aktualisiert.';

  @override
  String get adminTrackerOwnerDeleted => 'Besitzer gelöscht.';

  @override
  String get adminTrackerOwnerSaveFailed =>
      'Besitzer konnte nicht gespeichert werden.';

  @override
  String get adminTrackerOwnerDeleteFailed =>
      'Besitzer konnte nicht gelöscht werden.';

  @override
  String get adminTrackerOwnerPermissionDenied =>
      'Für die Verwaltung der Tracker-Besitzer ist Administratorzugriff erforderlich.';

  @override
  String get adminTrackerDevicesSection => 'Tracker-Verwaltung';

  @override
  String get adminTrackerDevicesSectionDesc =>
      'Tracker-Geräte synchronisieren, zuweisen und verwalten.';

  @override
  String get adminTrackerDevicesTitle => 'Tracker-Verwaltung';

  @override
  String get adminTrackerDevicesManageAction => 'Tracker-Verwaltung';

  @override
  String get adminTrackerDevicesShowUnassigned =>
      'Nicht zugewiesene Geräte anzeigen';

  @override
  String get adminTrackerDevicesSelectOwner => 'Verantwortlichen auswählen';

  @override
  String get adminTrackerDevicesResetFilter => 'Zurücksetzen';

  @override
  String get adminTrackerDevicesEmpty => 'Keine Geräte';

  @override
  String get adminTrackerDevicesEmptySubtitle =>
      'Keine Dokumente in TRACKER_Device.';

  @override
  String get adminTrackerDevicesLoadError =>
      'Geräte konnten nicht geladen werden.';

  @override
  String adminTrackerDevicesSource(String provider) {
    return 'Quelle: $provider';
  }

  @override
  String adminTrackerDevicesSerial(String serial) {
    return 'Seriennummer: $serial';
  }

  @override
  String adminTrackerDevicesUpdatedAt(String date) {
    return 'Aktualisiert: $date';
  }

  @override
  String get adminTrackerDevicesStatusActive => 'Aktiv';

  @override
  String get adminTrackerDevicesStatusInactive => 'Inaktiv';

  @override
  String get adminTrackerDevicesAssign => 'Zuweisen';

  @override
  String get adminTrackerDevicesUnassign => 'Zuweisung aufheben';

  @override
  String get adminTrackerDevicesAssignTitle => 'Gerät zuweisen';

  @override
  String get adminTrackerDevicesCustomName => 'Name (optional)';

  @override
  String get adminTrackerDevicesCancel => 'Abbrechen';

  @override
  String get adminTrackerDevicesValidate => 'Bestätigen';

  @override
  String get adminTrackerDevicesSelectOwnerRequired =>
      'Bitte wählen Sie einen Verantwortlichen aus.';

  @override
  String get adminTrackerDevicesAssignSuccess => 'Zuweisung gespeichert.';

  @override
  String get adminTrackerDevicesUnassignSuccess => 'Zuweisung aufgehoben.';

  @override
  String adminTrackerDevicesError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get adminTrackerDevicesSyncInspirit => 'Inspirit synchronisieren';

  @override
  String get adminTrackerDevicesSyncFootbar => 'Footbar synchronisieren';

  @override
  String get adminTrackerDevicesSyncInProgress => 'Synchronisierung...';

  @override
  String get adminTrackerDevicesSyncInspiritInProgress =>
      'Inspirit-Sync (Insiders) läuft...';

  @override
  String get adminTrackerDevicesSyncFootbarInProgress =>
      'Footbar-Sync läuft...';

  @override
  String adminTrackerDevicesSyncInspiritSuccess(int count) {
    return 'Inspirit-Sync: $count Gerät(e) aktualisiert.';
  }

  @override
  String adminTrackerDevicesSyncInspiritError(String error) {
    return 'Inspirit-Sync-Fehler: $error';
  }

  @override
  String get adminTrackerDevicesPermissionDenied =>
      'Für die Verwaltung der Geräte ist Administratorzugriff erforderlich.';

  @override
  String get adminStreamGroupsSection => 'Messaging - Gruppen';

  @override
  String get adminStreamGroupsSectionDesc =>
      'GetStream-Team-Chatgruppen auflisten und löschen.';

  @override
  String get adminStreamGroupsTitle => 'Messaging - Gruppen';

  @override
  String get adminStreamGroupsEmpty => 'Keine Chatgruppen';

  @override
  String get adminStreamGroupsEmptySubtitle =>
      'Keine Teamkanäle auf GetStream gefunden.';

  @override
  String get adminStreamGroupsLoadError =>
      'Chatgruppen konnten nicht geladen werden.';

  @override
  String get adminStreamGroupsRefresh => 'Aktualisieren';

  @override
  String adminStreamGroupsCid(String cid) {
    return 'CID: $cid';
  }

  @override
  String adminStreamGroupsMemberCount(int count) {
    return '$count Mitglieder';
  }

  @override
  String adminStreamGroupsLastMessageAt(String date) {
    return 'Letzte Nachricht: $date';
  }

  @override
  String get adminStreamGroupsDelete => 'Löschen';

  @override
  String get adminStreamGroupsCancel => 'Abbrechen';

  @override
  String get adminStreamGroupsDeleteConfirmTitle => 'Gruppe löschen?';

  @override
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid) {
    return 'Möchten Sie die Gruppe $name ($cid) wirklich löschen? Diese Aktion ist endgültig.';
  }

  @override
  String get adminStreamGroupsDeleted => 'Gruppe gelöscht.';

  @override
  String get adminStreamGroupsDeleteFailed =>
      'Gruppe konnte nicht gelöscht werden.';

  @override
  String get adminStreamGroupsPermissionDenied =>
      'Für die Verwaltung der Chatgruppen ist Administratorzugriff erforderlich.';

  @override
  String get adminSeasonsSection => 'Saisons';

  @override
  String get adminSeasonsSectionDesc =>
      'Lister et gérer les saisons de la plateforme.';

  @override
  String get adminSeasonsTitle => 'Saisons';

  @override
  String get adminSeasonsEmpty => 'Aucune saison pour le moment.';

  @override
  String get adminSeasonsLoadError => 'Impossible de charger les saisons.';

  @override
  String get adminSeasonCreate => 'Ajouter une saison';

  @override
  String get adminSeasonEditTitle => 'Modifier la saison';

  @override
  String get adminSeasonCreated => 'Saison créée.';

  @override
  String get adminSeasonUpdated => 'Saison mise à jour.';

  @override
  String get adminSeasonCreateFailed => 'Impossible de créer la saison.';

  @override
  String get adminSeasonUpdateFailed =>
      'Impossible de mettre à jour la saison.';

  @override
  String get adminSeasonUnnamed => 'Saison sans nom';

  @override
  String get adminSeasonCurrentBadge => 'Actuelle';

  @override
  String get adminSeasonNewVersionBadge => 'Nouvelle version';

  @override
  String adminSeasonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String adminSeasonClubLabel(String clubName) {
    return 'Club : $clubName';
  }

  @override
  String adminSeasonAffiliateLabel(String number) {
    return 'N° affilié : $number';
  }

  @override
  String get adminSeasonFieldName => 'Nom';

  @override
  String get adminSeasonFieldNameReadOnly =>
      'Le nom de la saison ne peut pas être modifié après création.';

  @override
  String get adminSeasonFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get adminSeasonFieldStartDate => 'Date de début';

  @override
  String get adminSeasonFieldEndDate => 'Date de fin';

  @override
  String adminSeasonDateSelected(String date) {
    return 'Sélection : $date';
  }

  @override
  String get adminSeasonFieldClubName => 'Nom du club';

  @override
  String get adminSeasonFieldAffiliateNumber => 'Numéro d\'affilié';

  @override
  String get adminSeasonFieldCurrent => 'Saison actuelle';

  @override
  String get adminSeasonFieldCurrentHint =>
      'Une seule saison peut être actuelle à la fois.';

  @override
  String get adminSeasonFieldNewVersion => 'Nouvelle version';

  @override
  String get adminSeasonChangeDefaultTitle => 'Changer la saison actuelle ?';

  @override
  String adminSeasonChangeDefaultMessage(String seasonName) {
    return '« $seasonName » est actuellement la saison par défaut. Voulez-vous la remplacer ?';
  }

  @override
  String get adminSeasonChangeDefaultConfirm => 'Changer la saison par défaut';

  @override
  String get promoCodeMenuLabel => 'Promo-Code';

  @override
  String get promoCodeDialogValidate => 'Einlösen';

  @override
  String get promoCodeRedeemTitle => 'Haben Sie einen Promo-Code?';

  @override
  String get promoCodeRedeemHint => 'Code eingeben';

  @override
  String get promoCodeRedeemAction => 'Einlösen';

  @override
  String get promoCodeRedeemEmpty => 'Bitte geben Sie einen Promo-Code ein.';

  @override
  String promoCodeRedeemSuccess(int days, String entitlement) {
    return 'Promo-Code angewendet: $days Tage $entitlement.';
  }

  @override
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days) {
    return '$entitlement aktiv bis $expiresAt ($days Tage geschenkt).';
  }

  @override
  String get promoCodeRedeemSyncPending =>
      'Code serverseitig registriert, aber das Abo ist noch nicht sichtbar. Öffne gleich Einstellungen → Abonnement oder melde dich ab und wieder an.';

  @override
  String get promoCodeRedeemRcUnavailable =>
      'Code serverseitig registriert, aber RevenueCat ist auf diesem Gerät nicht konfiguriert (API-Schlüssel prüfen). Auf iOS oder Web testen oder mit dart_defines.json neu starten.';

  @override
  String get promoCodeRedeemNotFound => 'Promo-Code nicht gefunden.';

  @override
  String get promoCodeRedeemInvalid =>
      'Dieser Promo-Code ist nicht mehr gültig.';

  @override
  String get promoCodeRedeemInactive => 'Dieser Promo-Code ist inaktiv.';

  @override
  String get promoCodeRedeemExpired => 'Dieser Promo-Code ist abgelaufen.';

  @override
  String get promoCodeRedeemAlreadyRedeemed =>
      'Sie haben diesen Promo-Code bereits eingelöst.';

  @override
  String get promoCodeRedeemExhausted =>
      'Dieser Promo-Code hat sein Nutzungslimit erreicht.';

  @override
  String get promoCodeRedeemTeamMismatch =>
      'Dieser Promo-Code ist einem anderen Verein vorbehalten.';

  @override
  String get promoCodeRedeemUnauthenticated =>
      'Sie müssen angemeldet sein, um einen Promo-Code einzulösen.';

  @override
  String get promoCodeRedeemFailed =>
      'Promo-Code konnte nicht eingelöst werden.';
}
