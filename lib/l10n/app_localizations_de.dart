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
  String sessionReportEmailSubject(
      String appName, String eventLabel, String title) {
    return '$appName — Bericht $eventLabel: $title';
  }

  @override
  String sessionReportEmailIntro(String appName) {
    return 'Hier ist dein Statistikbericht von $appName';
  }

  @override
  String get sessionReportEmailEventMatch => 'Spiel';

  @override
  String get sessionReportEmailEventTraining => 'Training';

  @override
  String get sessionReportEmailDetailsLabel => 'Berichtsdetails';

  @override
  String get sessionReportEmailTypeLabel => 'Typ';

  @override
  String get sessionReportEmailTitleLabel => 'Einheit';

  @override
  String get sessionReportEmailDateLabel => 'Datum';

  @override
  String get sessionReportEmailTeamLabel => 'Team';

  @override
  String get sessionReportEmailPlayersLabel => 'Spieler';

  @override
  String get sessionReportEmailAvgWorkloadLabel => 'Durchschn. Workload';

  @override
  String sessionReportEmailDateLine(String date) {
    return 'Datum: $date';
  }

  @override
  String sessionReportEmailTeamLine(String team) {
    return 'Team: $team';
  }

  @override
  String sessionReportEmailPlayersLine(int count) {
    return 'Spieler mit Daten: $count';
  }

  @override
  String get sessionReportEmailAttachmentHint =>
      'Der Tracker-Statistikbericht als PDF ist dieser E-Mail angehängt.';

  @override
  String get sessionReportEmailDownloadHint =>
      'Lade den PDF-Bericht über die Schaltfläche unten herunter.';

  @override
  String get sessionReportEmailDownloadButton => 'PDF herunterladen';

  @override
  String sessionReportEmailDownloadLine(String url) {
    return 'PDF herunterladen: $url';
  }

  @override
  String get sessionReportEmailAskAddress =>
      'Nenne mir die E-Mail-Adresse für den PDF-Bericht.';

  @override
  String get sessionReportEmailNoSessionYesterday =>
      'Für diesen Zeitraum wurde keine Einheit gefunden.';

  @override
  String get sessionReportEmailPeriodUnclear =>
      'Bitte gib den Zeitraum an (gestern, heute…) für den Bericht.';

  @override
  String sessionReportEmailFooter(String appName) {
    return 'Du hast diese E-Mail erhalten, weil ein Sitzungsbericht aus $appName erstellt wurde. Wenn du diese Nachricht nicht erwartet hast, kannst du sie ignorieren.';
  }

  @override
  String get sessionReportEmailDialogTitle => 'PDF-Bericht senden';

  @override
  String get sessionReportEmailDialogMessage =>
      'Wähle einen oder mehrere Manager aus, die den Statistikbericht (PDF) erhalten sollen.';

  @override
  String get sessionReportEmailDialogHint => 'du@beispiel.com';

  @override
  String get sessionReportEmailDialogSend => 'Senden';

  @override
  String get sessionReportEmailDialogCancel => 'Abbrechen';

  @override
  String get sessionReportEmailActionTooltip => 'PDF-Bericht per E-Mail senden';

  @override
  String get sessionReportEmailActionLabel => 'PDF-Bericht';

  @override
  String sessionReportEmailSuccess(String email) {
    return 'Bericht an $email gesendet';
  }

  @override
  String sessionReportEmailSuccessCount(int count) {
    return 'Bericht an $count Empfänger gesendet';
  }

  @override
  String sessionReportEmailSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get sessionReportEmailSelectAll => 'Alle auswählen';

  @override
  String get sessionReportEmailDeselectAll => 'Auswahl aufheben';

  @override
  String get sessionReportEmailNoManagers =>
      'Keine Manager mit E-Mail-Adresse für dieses Team gefunden.';

  @override
  String get sessionReportEmailManualOnlyMessage =>
      'Gib eine oder mehrere E-Mail-Adressen ein, die den Bericht erhalten sollen (getrennt durch ;).';

  @override
  String get sessionReportEmailAdditionalLabel => 'Weitere Adressen';

  @override
  String get sessionReportEmailManualHint =>
      'du@beispiel.com; andere@beispiel.com';

  @override
  String get sessionReportEmailManualHelper =>
      'Mehrere Adressen: mit Semikolon (;) trennen.';

  @override
  String get sessionReportEmailNoSelection =>
      'Wähle einen Manager oder gib mindestens eine E-Mail-Adresse ein.';

  @override
  String get sessionReportEmailFailed =>
      'Der PDF-Bericht konnte nicht gesendet werden.';

  @override
  String get sessionReportEmailNoStats =>
      'Keine Tracker-Statistiken verfügbar, um diesen Bericht zu erstellen.';

  @override
  String get sessionReportEmailInvalid => 'Ungültige E-Mail-Adresse.';

  @override
  String get memberInvitationEmailFailed =>
      'Mitglied hinzugefügt, aber die Einladungs-E-Mail konnte nicht gesendet werden.';

  @override
  String get memberInvitationEmailSent => 'Einladungs-E-Mail gesendet';

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
  String get resendInvitationTooltip => 'Einladungs-E-Mail erneut senden';

  @override
  String get resendInvitationAction => 'Einladung erneut senden';

  @override
  String get resendInvitationNoEmailTooltip =>
      'E-Mail-Adresse hinzufügen, um eine Einladung zu senden';

  @override
  String get resendInvitationSuccess => 'Einladungs-E-Mail gesendet';

  @override
  String get resendInvitationFailed =>
      'Einladungs-E-Mail konnte nicht gesendet werden';

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
  String get teamCreationSelectCountry => 'Land auswählen';

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
  String get hintSearchMember => 'Nach Name oder E-Mail suchen';

  @override
  String get memberSearchPrompt => 'Vorname, Nachname oder E-Mail eingeben';

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
  String get entityPersonalSports => 'Individuelle Sportaktivitäten';

  @override
  String get dashboardPersonalSportsListTitle => 'Liste der Sportaktivitäten';

  @override
  String get emptyNoPersonalSportToShow =>
      'Keine Sportaktivitäten zum Anzeigen';

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
      'Ein nicht-sportliches Ereignis / Aktivität';

  @override
  String get agendaAllDayLabel => 'All day';

  @override
  String get coachWorkloadAnalysisFabTooltip => 'Belastungsanalyse Spieler';

  @override
  String get coachWorkloadAnalysisTitle => 'Belastungsanalyse';

  @override
  String get coachWorkloadTeaserHeadline =>
      'Vergleiche die Belastung deiner Spieler';

  @override
  String get coachWorkloadTeaserBody =>
      'Team- + Einzelübersicht für den Zeitraum, Belastungskennzahlen und Aktivitätsliste. Verfügbar mit Coach Pro.';

  @override
  String get coachWorkloadTeaserCta => 'Coach Pro entdecken';

  @override
  String get coachWorkloadCompareHint =>
      'Vergleiche Spieler auf einen Blick und öffne dann die Details.';

  @override
  String get coachWorkloadNoManagedTeam =>
      'Kein betreutes Team in dieser Saison.';

  @override
  String get coachWorkloadLoadError => 'Analyse konnte nicht geladen werden.';

  @override
  String get coachWorkloadEmptyPlayers => 'Keine Spieler zum Anzeigen.';

  @override
  String get coachWorkloadEmptyActivities =>
      'Keine Aktivitäten in diesem Zeitraum.';

  @override
  String get coachWorkloadPlayerRecapTitle => 'Belastungsübersicht';

  @override
  String get coachWorkloadActivitiesTitle => 'Aktivitäten';

  @override
  String coachWorkloadMetricSessions(int count) {
    return '$count Trainings';
  }

  @override
  String coachWorkloadMetricMatches(int count) {
    return '$count Spiele';
  }

  @override
  String coachWorkloadMetricPersonalSports(int count) {
    return '$count Eigenakt.';
  }

  @override
  String coachWorkloadMetricKm(String value) {
    return '$value km';
  }

  @override
  String get coachWorkloadReportEmailActionTooltip => 'PDF-Bericht senden';

  @override
  String get coachWorkloadReportEmailDialogTitle =>
      'Belastungsanalyse senden (PDF)';

  @override
  String get coachWorkloadReportEmpty =>
      'Keine Daten zum Exportieren in diesem Zeitraum.';

  @override
  String coachWorkloadReportEmailSubject(String team, String period) {
    return 'Grinta — Belastungsanalyse $team ($period)';
  }

  @override
  String get coachWorkloadReportEmailGreeting => 'Hallo,';

  @override
  String coachWorkloadReportEmailIntro(String team, String period) {
    return 'Hier ist die Belastungsanalyse für $team im Zeitraum $period.';
  }

  @override
  String get coachWorkloadReportEmailDownload => 'PDF herunterladen';

  @override
  String coachWorkloadReportEmailText(String team, String period, String url) {
    return 'Belastungsanalyse — $team\nZeitraum: $period\nPDF: $url';
  }

  @override
  String coachWorkloadMetricLoad(String value) {
    return 'Last $value';
  }

  @override
  String coachWorkloadMetricVolume(int minutes) {
    return '$minutes Min.';
  }

  @override
  String coachWorkloadMetricPresence(String value) {
    return 'Anwesenheit $value';
  }

  @override
  String coachWorkloadBreakdown(int trainings, int matches, int personal) {
    return '$trainings Trainings · $matches Spiele · $personal Eigenaktivität';
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
  String get agendaFilterFabTooltip => 'Agenda filtern';

  @override
  String get agendaFilterTitle => 'Agenda filtern';

  @override
  String get agendaFilterTypesSection => 'Ereignistypen';

  @override
  String get agendaFilterTeamsSection => 'Teams';

  @override
  String get agendaFilterNoTeams => 'Keine Teams für diese Saison verfügbar.';

  @override
  String get agendaFilterSelectAllTeams => 'Alle auswählen';

  @override
  String get agendaFilterSelectNoneTeams => 'Auswahl eingrenzen';

  @override
  String get agendaFilterApply => 'Anwenden';

  @override
  String get agendaFilterActiveBanner => 'Filter aktiv';

  @override
  String get agendaFilterActiveBannerDetail =>
      'Einige Teams oder Typen sind ausgeblendet.';

  @override
  String get agendaFilterClear => 'Filter löschen';

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
  String get createPersonalSportUseMyGps => 'Mein GPS verwenden';

  @override
  String get createPersonalSportUseMyGpsHint =>
      'Dauer, Distanz und Tempo vom GPS-Sensor (Intense) abrufen';

  @override
  String get createPersonalSportGpsDevice => 'GPS-Sensor';

  @override
  String get createPersonalSportGpsMetricsHint =>
      'Dauer, Distanz und Tempo werden aus der Sensor-Synchronisierung berechnet (von Startzeit bis jetzt).';

  @override
  String get createPersonalSportGpsSubmit => 'Synchronisieren und erstellen';

  @override
  String get createPersonalSportGpsDeviceRequired => 'Wähle einen GPS-Sensor.';

  @override
  String get createPersonalSportGpsStartInFuture =>
      'Die Startzeit muss vor jetzt liegen.';

  @override
  String get createPersonalSportGpsNoData =>
      'Es gibt keine Daten zum Synchronisieren. Prüfe Datum und Startzeit deiner Session.';

  @override
  String get createPersonalSportGpsManualEntryQuestion =>
      'Möchtest du die Daten manuell eingeben?';

  @override
  String get createPersonalSportGpsSyncError =>
      'GPS-Synchronisierung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get sessionPersonalDataTitle => 'Meine Daten';

  @override
  String get sessionPersonalDataSubtitle =>
      'Verknüpfe dein GPS oder eine verbundene App mit dieser Einheit (kein Team-Tracker zugewiesen).';

  @override
  String get sessionPersonalDataGpsHint =>
      'Synchronisiere deinen Intense-GPS-Sensor und erzeuge eine Heatmap, wenn das Feld positioniert ist.';

  @override
  String get sessionPersonalDataGpsSubmit => 'Meine Daten synchronisieren';

  @override
  String get sessionPersonalDataAppSubmit => 'Aktivität verknüpfen';

  @override
  String get sessionPersonalDataSaved => 'Daten mit der Einheit verknüpft.';

  @override
  String get sessionPersonalDataError =>
      'Daten konnten nicht verknüpft werden. Bitte erneut versuchen.';

  @override
  String get sessionPersonalDataAuthRequired =>
      'Melde dich mit einem Spielerprofil an, um Daten zu verknüpfen.';

  @override
  String get sessionPersonalDataSwitchToAppsQuestion =>
      'Möchtest du eine verbundene App / ein Gerät wählen?';

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
    return 'Test bis $date. Sie können sich jetzt abonnieren.';
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
  String get teamEditNameTitle => 'Team bearbeiten';

  @override
  String get teamEditNameSuccess => 'Team aktualisiert.';

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
  String get settingsDevicesSection => 'Geräte/Anwendungen';

  @override
  String get settingsDevicesClose => 'Schließen';

  @override
  String get settingsDevicesSync => 'Synchronisieren';

  @override
  String get settingsDevicesConnectedTitle => 'Verbundene Geräte/Anwendungen';

  @override
  String get settingsDevicesConnectedStatus => 'Verbunden';

  @override
  String get settingsDevicesDisconnect => 'Trennen';

  @override
  String get settingsDevicesNoConnected =>
      'Keine Geräte oder Anwendungen verbunden';

  @override
  String get settingsDevicesAddTitle => 'Verbindung hinzufügen';

  @override
  String get settingsDevicesAddFabTooltip => 'Verbindung hinzufügen';

  @override
  String get settingsDevicesAllConnected =>
      'Alle verfügbaren Geräte/Anwendungen sind bereits verbunden';

  @override
  String settingsDevicesBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verbundene Geräte/Anwendungen',
      one: '1 verbundenes Gerät/Anwendung',
      zero: 'Keine verbundenen Geräte/Anwendungen',
    );
    return '$_temp0';
  }

  @override
  String get wearableDeviceTypeLabel => 'Gerät-/Anwendungstyp';

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
  String get whoopConnectToggleLabel => 'Whoop-Sync';

  @override
  String get whoopConnectToggleSubtitle =>
      'Verbinde dein Whoop-Konto, um Erholung, Schlaf und Workouts zu importieren';

  @override
  String get whoopConnectToggleConnectedSubtitle =>
      'Whoop verbunden — Datensync folgt in Phase 2';

  @override
  String get whoopConnectSuccess => 'Whoop-Konto verbunden.';

  @override
  String get whoopAccountHintGuidance =>
      'Deine Whoop-E-Mail kann sich von deinem Grinta-Konto unterscheiden. Gib das Whoop-Konto ein und melde dich damit auf der Whoop-Seite an.';

  @override
  String get whoopAccountHintLabel => 'Whoop-Konto';

  @override
  String get whoopAccountHintPlaceholder => 'Whoop-E-Mail';

  @override
  String get whoopAccountHintRequired =>
      'Gib dein Whoop-Konto (E-Mail) ein, bevor du fortfährst.';

  @override
  String get whoopConnectContinue => 'Weiter zu Whoop';

  @override
  String get whoopConnectFailed =>
      'Whoop-Verbindung fehlgeschlagen. Prüfe, ob die Whoop Cloud Functions bereitgestellt sind und die Secrets WHOOP_CLIENT_ID / WHOOP_CLIENT_SECRET konfiguriert sind.';

  @override
  String get whoopConnectLaunchFailed =>
      'Die Whoop-Anmeldeseite konnte nicht geöffnet werden.';

  @override
  String get whoopConnectAuthRequired =>
      'Melde dich bei Grinta an, um Whoop zu verbinden.';

  @override
  String get whoopDisconnectFailed => 'Trennen von Whoop fehlgeschlagen.';

  @override
  String get whoopCoachVisibilityTitle => 'Sichtbarkeit für den Coach';

  @override
  String get whoopCoachVisibilitySubtitle =>
      'Erlaube deinem Coach, diesen Datentyp zu sehen';

  @override
  String get whoopCoachVisibilitySaveFailed =>
      'Whoop-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get whoopMetricRecovery => 'Erholung';

  @override
  String get whoopMetricCycles => 'Zyklen';

  @override
  String get whoopMetricSleep => 'Schlaf';

  @override
  String get whoopMetricWorkout => 'Workouts';

  @override
  String get whoopMetricProfile => 'Profil';

  @override
  String get whoopMetricBodyMeasurement => 'Körpermaße';

  @override
  String get whoopCoachConnectTitle => 'Whoop';

  @override
  String whoopCoachConnectSubtitle(String playerName) {
    return 'Whoop für $playerName verbinden';
  }

  @override
  String get whoopCoachConnectAction => 'Verbinden';

  @override
  String whoopCoachConnectConnectedSubtitle(String playerName) {
    return 'Whoop verbunden für $playerName';
  }

  @override
  String get stravaConnectToggleSubtitle =>
      'Verbinde dein Strava-Konto, um Aktivitäten und Workouts zu importieren';

  @override
  String get stravaConnectToggleConnectedSubtitle =>
      'Strava verbunden — Datensync folgt in Phase 2';

  @override
  String get stravaAccountHintGuidance =>
      'Deine Strava-E-Mail kann sich von deinem Grinta-Konto unterscheiden. Gib das Strava-Konto ein und melde dich damit auf der Strava-Seite an.';

  @override
  String get stravaAccountHintLabel => 'Strava-Konto';

  @override
  String get stravaAccountHintPlaceholder => 'Strava-E-Mail oder Benutzername';

  @override
  String get stravaAccountHintRequired =>
      'Gib dein Strava-Konto (E-Mail oder Benutzername) ein, bevor du fortfährst.';

  @override
  String get stravaConnectContinue => 'Weiter zu Strava';

  @override
  String get stravaConnectSuccess => 'Strava-Konto verbunden.';

  @override
  String get stravaConnectFailed =>
      'Strava-Verbindung fehlgeschlagen. Prüfe, ob die Strava Cloud Functions bereitgestellt sind und die Secrets STRAVA_CLIENT_ID / STRAVA_CLIENT_SECRET konfiguriert sind.';

  @override
  String get stravaConnectLaunchFailed =>
      'Die Strava-Anmeldeseite konnte nicht geöffnet werden.';

  @override
  String get stravaConnectAuthRequired =>
      'Melde dich bei Grinta an, um Strava zu verbinden.';

  @override
  String get stravaDisconnectFailed => 'Trennen von Strava fehlgeschlagen.';

  @override
  String get stravaCoachVisibilitySaveFailed =>
      'Strava-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get stravaMetricActivities => 'Aktivitäten';

  @override
  String get stravaMetricProfile => 'Profil';

  @override
  String stravaCoachConnectSubtitle(String playerName) {
    return 'Strava für $playerName verbinden';
  }

  @override
  String stravaCoachConnectConnectedSubtitle(String playerName) {
    return 'Strava verbunden für $playerName';
  }

  @override
  String get polarConnectToggleSubtitle =>
      'Verbinde dein Polar-Konto, um Training, Schlaf und Herzfrequenz von Loop oder Verity Sense über Polar Flow zu importieren';

  @override
  String get polarConnectToggleConnectedSubtitle =>
      'Polar verbunden — Datensync folgt in Phase 2';

  @override
  String get polarAccountHintGuidance =>
      'Deine Polar-Flow-E-Mail kann sich von deinem Grinta-Konto unterscheiden. Gib das Polar-Konto ein und melde dich damit auf der Polar-Seite an.';

  @override
  String get polarAccountHintLabel => 'Polar-Konto';

  @override
  String get polarAccountHintPlaceholder => 'Polar-Flow-E-Mail';

  @override
  String get polarAccountHintRequired =>
      'Gib dein Polar-Konto (E-Mail) ein, bevor du fortfährst.';

  @override
  String get polarConnectContinue => 'Weiter zu Polar';

  @override
  String get polarConnectSuccess => 'Polar-Konto verbunden.';

  @override
  String get polarConnectFailed =>
      'Polar-Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get polarConnectLaunchFailed =>
      'Die Polar-Anmeldeseite konnte nicht geöffnet werden.';

  @override
  String get polarConnectAuthRequired =>
      'Melde dich bei Grinta an, um Polar zu verbinden.';

  @override
  String get polarDisconnectFailed => 'Trennen von Polar fehlgeschlagen.';

  @override
  String get polarCoachVisibilityTitle => 'Sichtbarkeit für den Coach';

  @override
  String get polarCoachVisibilitySubtitle =>
      'Erlaube deinem Coach, diesen Datentyp zu sehen';

  @override
  String get polarCoachVisibilitySaveFailed =>
      'Polar-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get polarMetricTraining => 'Training / Workouts';

  @override
  String get polarMetricSleep => 'Schlaf';

  @override
  String get polarMetricRecoveryHr => 'Erholung / Herzfrequenz';

  @override
  String get polarMetricProfile => 'Profil';

  @override
  String get polarMetricBody => 'Körpermaße';

  @override
  String polarCoachConnectSubtitle(String playerName) {
    return 'Polar für $playerName verbinden';
  }

  @override
  String polarCoachConnectConnectedSubtitle(String playerName) {
    return 'Polar verbunden für $playerName';
  }

  @override
  String get fitbitConnectToggleSubtitle =>
      'Verbinde dein Fitbit-Konto, um Aktivität, Herzfrequenz, Schlaf und Gewicht von deinem Fitbit-Armband über die Fitbit-Cloud zu importieren';

  @override
  String get fitbitConnectToggleConnectedSubtitle =>
      'Fitbit verbunden — Datensync folgt in Phase 2';

  @override
  String get fitbitConnectSuccess => 'Fitbit-Konto verbunden.';

  @override
  String get fitbitConnectFailed =>
      'Fitbit-Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get fitbitConnectLaunchFailed =>
      'Die Fitbit-Anmeldeseite konnte nicht geöffnet werden.';

  @override
  String get fitbitConnectAuthRequired =>
      'Melde dich bei Grinta an, um Fitbit zu verbinden.';

  @override
  String get fitbitDisconnectFailed => 'Trennen von Fitbit fehlgeschlagen.';

  @override
  String get fitbitCoachVisibilityTitle => 'Sichtbarkeit für den Coach';

  @override
  String get fitbitCoachVisibilitySubtitle =>
      'Erlaube deinem Coach, diesen Datentyp zu sehen';

  @override
  String get fitbitCoachVisibilitySaveFailed =>
      'Fitbit-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get fitbitMetricActivity => 'Aktivität / Workouts / Schritte';

  @override
  String get fitbitMetricHeartrate => 'Herzfrequenz';

  @override
  String get fitbitMetricSleep => 'Schlaf';

  @override
  String get fitbitMetricProfile => 'Profil';

  @override
  String get fitbitMetricBody => 'Gewicht / Körper';

  @override
  String fitbitCoachConnectSubtitle(String playerName) {
    return 'Fitbit für $playerName verbinden';
  }

  @override
  String fitbitCoachConnectConnectedSubtitle(String playerName) {
    return 'Fitbit verbunden für $playerName';
  }

  @override
  String get appleHealthConnectToggleSubtitle =>
      'Verbinde Apple Fitness, um Workouts, Herzfrequenz und aktive Energie aus der Health-App zu importieren (nur iOS)';

  @override
  String get appleHealthConnectToggleConnectedSubtitle =>
      'Apple Fitness verbunden — vollständiger Workout-Sync folgt in Phase 2';

  @override
  String get appleHealthConnectSuccess => 'Apple Fitness verbunden.';

  @override
  String get appleHealthConnectFailed =>
      'Apple-Fitness-Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get appleHealthConnectDenied =>
      'Health-Zugriff wurde verweigert. Aktiviere ihn unter Einstellungen → Health → Datenzugriff & Geräte → Grinta.';

  @override
  String get appleHealthConnectAuthRequired =>
      'Melde dich bei Grinta an, um Apple Fitness zu verbinden.';

  @override
  String get appleHealthIosOnlyMessage =>
      'Apple Fitness ist nur auf dem iPhone verfügbar. Health-Daten werden auf dem Gerät über Apple HealthKit gelesen.';

  @override
  String get appleHealthDisconnectFailed =>
      'Trennen von Apple Fitness fehlgeschlagen.';

  @override
  String get appleHealthCoachVisibilityTitle => 'Sichtbarkeit für den Coach';

  @override
  String get appleHealthCoachVisibilitySubtitle =>
      'Erlaube deinem Coach, diesen Datentyp zu sehen';

  @override
  String get appleHealthCoachVisibilitySaveFailed =>
      'Apple-Fitness-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get appleHealthMetricActivity => 'Workouts / Aktivität';

  @override
  String get appleHealthMetricHeartrate => 'Herzfrequenz';

  @override
  String get appleHealthMetricActiveEnergy => 'Aktive Energie';

  @override
  String get appleHealthMetricSleep => 'Schlaf';

  @override
  String appleHealthCoachConnectSubtitle(String playerName) {
    return 'Apple Fitness für $playerName verbinden';
  }

  @override
  String appleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Apple Fitness verbunden für $playerName';
  }

  @override
  String get googleHealthConnectToggleSubtitle =>
      'Verbinde Google Health, um Workouts, Herzfrequenz und aktive Energie aus Health Connect zu importieren (nur Android)';

  @override
  String get googleHealthConnectToggleConnectedSubtitle =>
      'Google Health verbunden — Workout-Sync verfügbar';

  @override
  String get googleHealthConnectSuccess => 'Google Health verbunden.';

  @override
  String get googleHealthConnectFailed =>
      'Google-Health-Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get googleHealthConnectDenied =>
      'Health-Connect-Zugriff wurde verweigert. Aktiviere ihn unter Health Connect → App-Berechtigungen → Grinta.';

  @override
  String get googleHealthConnectAuthRequired =>
      'Melde dich bei Grinta an, um Google Health zu verbinden.';

  @override
  String get googleHealthAndroidOnlyMessage =>
      'Google Health ist nur auf Android verfügbar (auf dem Gerät über Health Connect). Auf dem iPhone nutze Apple Fitness.';

  @override
  String get googleHealthDisconnectFailed =>
      'Trennen von Google Health fehlgeschlagen.';

  @override
  String get googleHealthCoachVisibilityTitle => 'Sichtbarkeit für den Coach';

  @override
  String get googleHealthCoachVisibilitySubtitle =>
      'Erlaube deinem Coach, diesen Datentyp zu sehen';

  @override
  String get googleHealthCoachVisibilitySaveFailed =>
      'Google-Health-Einstellungen konnten nicht gespeichert werden.';

  @override
  String get googleHealthMetricActivity => 'Workouts / Aktivität';

  @override
  String get googleHealthMetricHeartrate => 'Herzfrequenz';

  @override
  String get googleHealthMetricActiveEnergy => 'Aktive Energie';

  @override
  String get googleHealthMetricSleep => 'Schlaf';

  @override
  String googleHealthCoachConnectSubtitle(String playerName) {
    return 'Google Health für $playerName verbinden';
  }

  @override
  String googleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Google Health verbunden für $playerName';
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
      'Wiederkehrendes Training löschen?';

  @override
  String get trainingDeleteRecurrentMessage =>
      'Möchtest du alle Termine dieser Serie löschen?';

  @override
  String get trainingDeleteThisOccurrence => 'Nur diesen Termin';

  @override
  String get trainingDeleteAllOccurrences => 'Alle Termine';

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
      'Möchten Sie dieses Training beenden?';

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
  String get trainingIntenseResyncMessage =>
      'Sensordaten für das gesamte Trainingsfenster (Start → Ende) werden erneut abgerufen. Fenster nicht schließen.';

  @override
  String get trainingIntenseResyncSuccess =>
      'Sensordaten erneut synchronisiert.';

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
  String get createMatchSelectField => 'Vereinsplatz';

  @override
  String get createMatchFieldNotGeolocatedTitle => 'Platz nicht geolokalisiert';

  @override
  String get createMatchFieldNotGeolocatedMessage =>
      'Dieser Platz ist nicht geolokalisiert. Möchtest du das jetzt tun? So entstehen platzgenaue Heatmaps; sonst wird die GPS-Satellitenansicht genutzt.';

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
  String get adminTrackerOwnerFieldIndividual => 'Individueller Besitzer';

  @override
  String get adminTrackerOwnerFieldIndividualHint =>
      'Aktivieren, wenn dieser Besitzer eine Person ist (kein Club / Team).';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Tracker-Typ';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, Cloud-Stream)';

  @override
  String get adminTrackerOwnerTypePolar => 'Polar (BLE-Team-Kit)';

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
  String get adminTrackerFieldsSection => 'Platz-Verwaltung';

  @override
  String get adminTrackerFieldsSectionDesc =>
      'GPS-Ecken der Plätze für Heatmaps erfassen und speichern.';

  @override
  String get adminTrackerFieldsTitle => 'Plätze';

  @override
  String get adminTrackerFieldsEmpty => 'Keine Plätze für diesen Verein.';

  @override
  String get adminTrackerFieldsLoadError =>
      'Plätze konnten nicht geladen werden.';

  @override
  String get adminTrackerFieldsCreate => 'Neuer Platz';

  @override
  String get adminTrackerFieldsSaved => 'Platz gespeichert.';

  @override
  String get adminTrackerFieldsSaveFailed =>
      'Platz konnte nicht gespeichert werden.';

  @override
  String get adminTrackerFieldsAuthRequired =>
      'Melde dich an, um einen Platz zu speichern.';

  @override
  String get adminTrackerFieldsSelectClubFirst =>
      'Wähle einen Verein, um dessen Plätze anzuzeigen.';

  @override
  String get adminTrackerFieldsChangeClub => 'Verein wechseln';

  @override
  String get adminTrackerFieldsGpsReady => 'GPS OK';

  @override
  String get adminTrackerFieldsGpsMissing => 'GPS fehlt';

  @override
  String get adminTrackerFieldsDeleteConfirmTitle => 'Platz löschen?';

  @override
  String adminTrackerFieldsDeleteConfirmMessage(String fieldName) {
    return 'Möchtest du „$fieldName“ wirklich löschen? Diese Aktion ist endgültig.';
  }

  @override
  String get adminTrackerFieldsDeleted => 'Platz gelöscht.';

  @override
  String get adminTrackerFieldsDeleteFailed =>
      'Platz konnte nicht gelöscht werden.';

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
  String get adminTrackerDevicesCustomName =>
      'Benutzerdefinierter Name (optional)';

  @override
  String get adminTrackerDevicesCustomNameHint =>
      'Trikotnummer oder Label, z. B. 7';

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
  String get adminTrackerDevicesAddPolar => 'Polar hinzufügen';

  @override
  String get adminTrackerDevicesAddPolarChrome =>
      'Über Chrome Bluetooth hinzufügen';

  @override
  String get adminTrackerDevicesAddPolarManual => 'ID manuell eingeben';

  @override
  String get adminPolarBleScanTitle => 'Polar-Sensoren scannen';

  @override
  String get adminPolarBleScanSheetSubtitle =>
      'Nahe Polar-Geräte auflisten und einzeln verbinden';

  @override
  String get adminPolarBleScanHint =>
      'Schalte die Sensoren in der Nähe ein, verbinde dich mit jedem und füge ihn mit einem eigenen Namen zum Kit hinzu.';

  @override
  String get adminPolarBleScanSearching => 'Suche nach Polar-Sensoren…';

  @override
  String get adminPolarBleScanEmpty =>
      'Kein Polar-Sensor gefunden. Bluetooth prüfen und Sensoren einschalten.';

  @override
  String get adminPolarBleScanUnsupported =>
      'Polar-BLE-Scan ist nur auf iOS und Android verfügbar.';

  @override
  String get adminPolarBleScanConnect => 'Verbinden';

  @override
  String get adminPolarBleScanConnecting => 'Verbindung…';

  @override
  String get adminPolarBleScanConnected => 'Verbunden';

  @override
  String get adminPolarBleScanAddToKit => 'Zum Kit hinzufügen';

  @override
  String get adminPolarBleScanStop => 'Scan stoppen';

  @override
  String get adminPolarBleScanRestart => 'Erneut scannen';

  @override
  String adminPolarBleScanConnectError(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String get polarImportTitle => 'Polar-Import (Cardio)';

  @override
  String get polarImportSensorsHeader => 'Polar-Sensoren der Einheit';

  @override
  String get polarImportHint =>
      'Schließe Polar Flow, setze den Verity Sense in den Sensormodus (blaue LED / optisches Herz) und importiere per Bluetooth. Zeigt iOS den Sensor bereits als „Verbunden“, entferne ihn unter Einstellungen → Bluetooth.';

  @override
  String get polarImportSelectSensor =>
      'Wähle einen Sensor für den Cardio-Import.';

  @override
  String get polarImportStatusPending => 'Zu importieren';

  @override
  String get polarImportStatusDone => 'Importiert';

  @override
  String get polarImportUntitledPlayer => 'Spieler';

  @override
  String polarImportDeviceLine(
      String deviceId, String deviceType, String customName) {
    return 'Polar $deviceId · $deviceType · $customName';
  }

  @override
  String get polarImportBleAction => 'Per Bluetooth importieren';

  @override
  String get polarImportBleUnavailable =>
      'Polar-Bluetooth-Import ist unter iOS/Android verfügbar. Im Web manuelle Eingabe nutzen.';

  @override
  String get polarImportManualAction => 'Manuelle Eingabe';

  @override
  String get polarImportManualTitle => 'Polar-Cardio eingeben';

  @override
  String get polarImportManualSubtitle =>
      'Dauer und HF eingeben (Kalorien / Schritte optional für Loop).';

  @override
  String get polarImportFieldDurationMin => 'Dauer (Minuten)';

  @override
  String get polarImportFieldAvgHr => 'HF Mittel (bpm)';

  @override
  String get polarImportFieldMaxHr => 'HF Max (bpm)';

  @override
  String get polarImportFieldMinHr => 'HF Min (bpm)';

  @override
  String get polarImportFieldCalories => 'Kalorien (kcal, optional)';

  @override
  String get polarImportFieldDistanceM => 'Distanz (m, optional)';

  @override
  String get polarImportFieldSteps => 'Schritte (optional)';

  @override
  String get polarImportMissingPlayer =>
      'Kein Spieler mit diesem Sensor verknüpft.';

  @override
  String polarImportSuccess(String avgHr, String minutes) {
    return 'Import OK — HF Mittel $avgHr · $minutes Min';
  }

  @override
  String get polarImportBleTimeoutHint =>
      'Polar-BLE-Verbindung abgelaufen. Schließe Polar Flow, entferne den Sensor unter Einstellungen → Bluetooth falls er „Verbunden“ bleibt, wecke den Verity Sense im Sensormodus (blaue LED) und versuche es erneut.';

  @override
  String polarImportBleError(String error) {
    return 'Polar-Import fehlgeschlagen: $error';
  }

  @override
  String get polarAnalysisEmptyMessage =>
      'Keine Polar-Cardioanalyse für diesen Spieler in dieser Einheit.';

  @override
  String get polarAnalysisEmptyTeamMessage =>
      'Keine Polar-Cardioanalyse für diese Einheit importiert. Sensoren unter Sync importieren.';

  @override
  String get polarAnalysisTeamTitle => 'Polar-Cardioanalyse';

  @override
  String polarAnalysisTeamCount(int count) {
    return '$count Spieler';
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
  String get polarAnalysisHrZonesTab => 'HF-Zonen';

  @override
  String get polarAnalysisDuration => 'Dauer';

  @override
  String polarAnalysisDurationDetail(int minutes, int seconds) {
    return '$minutes Min $seconds s';
  }

  @override
  String get polarAnalysisAvgHr => 'HF Mittel';

  @override
  String get polarAnalysisMaxHr => 'HF Max';

  @override
  String get polarAnalysisMinHr => 'HF Min';

  @override
  String get polarAnalysisSamples => 'Samples';

  @override
  String get polarAnalysisCalories => 'Kalorien';

  @override
  String get polarAnalysisSteps => 'Schritte';

  @override
  String get polarAnalysisUnitMin => 'Min';

  @override
  String get polarAnalysisUnitBpm => 'bpm';

  @override
  String get polarAnalysisUnitKcal => 'kcal';

  @override
  String polarAnalysisZoneLabel(String zone) {
    return '$zone';
  }

  @override
  String get polarAnalysisNoZones => 'Keine Zonenverteilung für diesen Import.';

  @override
  String get polarAnalysisTrainingZonesTitle => 'Trainingszonen';

  @override
  String polarAnalysisHrTimelineHint(int minutes) {
    return 'Durchschnitt alle $minutes Min';
  }

  @override
  String get polarAnalysisHrTimelineEmpty =>
      'HF-Kurve nicht verfügbar — Sensor erneut importieren, um die 5-Min-Synthese zu erzeugen.';

  @override
  String get polarAnalysisAxisPercent => '%';

  @override
  String get polarImportMissingSeason =>
      'Saison nicht gefunden, um Polar-Sensoren zu importieren.';

  @override
  String get polarImportAgendaAction => 'Polar-Daten importieren';

  @override
  String get polarAnalysisAgendaAction => 'Polar-Analyse anzeigen';

  @override
  String get adminTrackerDevicesAddPolarTitle => 'Polar-Sensor hinzufügen';

  @override
  String get adminTrackerDevicesAddPolarDeviceId => 'Polar-Geräte-ID';

  @override
  String get adminTrackerDevicesAddPolarDeviceIdHint =>
      'Auf dem Sensor gedruckt, oder Ende des BLE-Namens (z. B. Polar H10 1C709B20 → 1C709B20)';

  @override
  String get adminTrackerDevicesAddPolarChromeUnsupported =>
      'Web Bluetooth erfordert Chrome (HTTPS oder localhost).';

  @override
  String get adminTrackerDevicesAddPolarChromeCancelled =>
      'Bluetooth-Auswahl abgebrochen.';

  @override
  String get adminTrackerDevicesAddPolarChromeNoId =>
      'Polar-ID konnte nicht aus dem BLE-Namen gelesen werden. Gib die auf dem Sensor gedruckte ID ein.';

  @override
  String adminTrackerDevicesAddPolarChromeSuccess(
      String deviceId, String deviceType) {
    return 'Polar $deviceId ($deviceType) hinzugefügt.';
  }

  @override
  String get adminTrackerDevicesAddPolarDeviceType => 'Sensortyp';

  @override
  String get adminTrackerDevicesAddPolarDeviceName => 'Anzeigename (optional)';

  @override
  String get adminTrackerDevicesAddPolarSuccess =>
      'Polar-Sensor zum Inventar hinzugefügt.';

  @override
  String get adminTrackerDevicesAddPolarDeviceIdRequired =>
      'Polar-Geräte-ID ist erforderlich.';

  @override
  String get adminTrackerDevicesPolarTypeH10 => 'H10';

  @override
  String get adminTrackerDevicesPolarTypeH9 => 'H9';

  @override
  String get adminTrackerDevicesPolarTypeVeritySense => 'Verity Sense';

  @override
  String get adminTrackerDevicesPolarTypeOh1 => 'OH1';

  @override
  String get adminTrackerDevicesPolarTypeOther => 'Sonstiges';

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
      'Plattform-Saisons auflisten und verwalten.';

  @override
  String get adminSeasonsTitle => 'Saisons';

  @override
  String get adminSeasonsEmpty => 'Noch keine Saisons.';

  @override
  String get adminSeasonsLoadError => 'Saisons konnten nicht geladen werden.';

  @override
  String get adminSeasonCreate => 'Saison hinzufügen';

  @override
  String get adminSeasonEditTitle => 'Saison bearbeiten';

  @override
  String get adminSeasonCreated => 'Saison erstellt.';

  @override
  String get adminSeasonUpdated => 'Saison aktualisiert.';

  @override
  String get adminSeasonCreateFailed => 'Saison konnte nicht erstellt werden.';

  @override
  String get adminSeasonUpdateFailed =>
      'Saison konnte nicht aktualisiert werden.';

  @override
  String get adminSeasonUnnamed => 'Unbenannte Saison';

  @override
  String get adminSeasonCurrentBadge => 'Aktuell';

  @override
  String get adminSeasonNewVersionBadge => 'Neue Version';

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
    return 'Mitgliedsnr.: $number';
  }

  @override
  String get adminSeasonFieldName => 'Name';

  @override
  String get adminSeasonFieldNameReadOnly =>
      'Der Saisonname kann nach der Erstellung nicht geändert werden.';

  @override
  String get adminSeasonFieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get adminSeasonFieldStartDate => 'Startdatum';

  @override
  String get adminSeasonFieldEndDate => 'Enddatum';

  @override
  String adminSeasonDateSelected(String date) {
    return 'Ausgewählt: $date';
  }

  @override
  String get adminSeasonFieldClubName => 'Clubname';

  @override
  String get adminSeasonFieldAffiliateNumber => 'Mitgliedsnummer';

  @override
  String get adminSeasonFieldCurrent => 'Aktuelle Saison';

  @override
  String get adminSeasonFieldCurrentHint =>
      'Nur eine Saison kann gleichzeitig aktuell sein.';

  @override
  String get adminSeasonFieldNewVersion => 'Neue Version';

  @override
  String get adminSeasonChangeDefaultTitle => 'Aktuelle Saison ändern?';

  @override
  String adminSeasonChangeDefaultMessage(String seasonName) {
    return '„$seasonName“ ist derzeit die Standardsaison. Möchtest du sie ersetzen?';
  }

  @override
  String get adminSeasonChangeDefaultConfirm => 'Standard ändern';

  @override
  String get adminYoutubeSection => 'YouTube / Tipps';

  @override
  String get adminYoutubeSectionDesc =>
      'YouTube-Kanal, Tipps-Playlist und hervorgehobene Videos konfigurieren.';

  @override
  String get adminYoutubeTitle => 'YouTube / Tipps';

  @override
  String get adminYoutubeSubtitle =>
      'Dokument config/youtube — Kanal, Playlist, Videoliste und Spezialvideos.';

  @override
  String get adminYoutubeSave => 'Speichern';

  @override
  String get adminYoutubeSaved => 'YouTube-Konfiguration gespeichert.';

  @override
  String get adminYoutubeSaveFailed =>
      'YouTube-Konfiguration konnte nicht gespeichert werden.';

  @override
  String get adminYoutubePermissionDenied =>
      'Admin-Zugriff ist erforderlich, um YouTube zu verwalten.';

  @override
  String get adminYoutubeLoadError =>
      'YouTube-Konfiguration konnte nicht geladen werden.';

  @override
  String get adminYoutubeRetry => 'Erneut versuchen';

  @override
  String get adminYoutubeChannelSection => 'Kanal';

  @override
  String get adminYoutubeFeaturedSection => 'Hervorgehobene Videos';

  @override
  String get adminYoutubeVideosSection => 'Tipps-Videoliste';

  @override
  String get adminYoutubeVideosEmpty =>
      'Noch keine Videos. Füge Tipps der Kanal-Playlist hinzu.';

  @override
  String get adminYoutubeFieldChannelId => 'Kanal-ID';

  @override
  String get adminYoutubeFieldChannelIdHint => 'z. B. UCxxxxxxxx';

  @override
  String get adminYoutubeFieldChannelUrl => 'Kanal-URL';

  @override
  String get adminYoutubeFieldChannelUrlHint =>
      'https://www.youtube.com/@Grinta';

  @override
  String get adminYoutubeFieldPlaylistId => 'Tipps-Playlist-ID';

  @override
  String get adminYoutubeFieldPlaylistIdHint => 'z. B. PLxxxxxxxx';

  @override
  String get adminYoutubeFieldTopVideo => 'Video der Woche (topVideo)';

  @override
  String get adminYoutubeFieldWelcomePlayer =>
      'Willkommen Spieler (welcomePlayer)';

  @override
  String get adminYoutubeFieldWelcomeCoach => 'Willkommen Coach (welcomeCoach)';

  @override
  String get adminYoutubeFieldVideoIdOrUrl => 'Video-ID oder URL';

  @override
  String get adminYoutubeFieldVideoIdHint =>
      'YouTube-ID oder youtube.com / youtu.be Link';

  @override
  String get adminYoutubeFieldVideoIdInvalid =>
      'Gib eine gültige YouTube-ID oder URL ein.';

  @override
  String get adminYoutubeFieldTitle => 'Titel';

  @override
  String get adminYoutubeFieldTitleRequired => 'Titel ist erforderlich.';

  @override
  String get adminYoutubeFieldDescription => 'Beschreibung (optional)';

  @override
  String get adminYoutubeFieldThumbnailUrl => 'Vorschaubild-URL (optional)';

  @override
  String get adminYoutubeFeaturedNone => 'Keine';

  @override
  String get adminYoutubeAddVideo => 'Video hinzufügen';

  @override
  String get adminYoutubeAddVideoTitle => 'Tipp hinzufügen';

  @override
  String get adminYoutubeEditVideo => 'Bearbeiten';

  @override
  String get adminYoutubeEditVideoTitle => 'Video bearbeiten';

  @override
  String get adminYoutubeUpdateVideo => 'Aktualisieren';

  @override
  String get adminYoutubeDeleteVideo => 'Löschen';

  @override
  String get adminYoutubeDeleteVideoTitle => 'Video löschen?';

  @override
  String adminYoutubeDeleteVideoMessage(String title) {
    return '„$title“ aus der Tipps-Liste entfernen?';
  }

  @override
  String get adminYoutubeBadgeTop => 'Woche';

  @override
  String get adminYoutubeBadgeWelcomePlayer => 'Willkommen Spieler';

  @override
  String get adminYoutubeBadgeWelcomeCoach => 'Willkommen Coach';

  @override
  String get youtubeTopVideoTitle => 'Tipp der Woche';

  @override
  String get youtubeTopVideoMessage =>
      'Entdecke den neuen Grinta-Tipp. Du kannst ihn hier ansehen oder überspringen.';

  @override
  String get youtubeTopVideoWatch => 'Ansehen';

  @override
  String get youtubeTopVideoSkip => 'Überspringen';

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
  String get promoCodeRedeemGrantFailed =>
      'Der Code ist gültig, aber die Freischaltung ist fehlgeschlagen (RevenueCat-Konfiguration). Bitte erneut versuchen oder den Support kontaktieren.';

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

  @override
  String get playerFeelingPrompt => 'Wie fühlst du dich?';

  @override
  String get playerFeelingNotifTitle => 'Session-Zusammenfassung';

  @override
  String get playerFeelingNotifBody =>
      'Sieh dir deine Stats an und sag uns, wie du dich fühlst.';

  @override
  String get playerFeelingRecapTitle => 'Dein Recap';

  @override
  String get playerFeelingRecapSubtitle => 'Deine Session-Daten';

  @override
  String get playerFeelingSubmitAction => 'Senden';

  @override
  String get playerFeelingUpdateAction => 'Aktualisieren';

  @override
  String get playerFeelingSaved => 'Danke, dein Gefühl wurde gespeichert.';

  @override
  String get playerFeelingSaveError =>
      'Gefühl konnte nicht gespeichert werden.';

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
  String get forgotPasswordTitle => 'Passwort vergessen';

  @override
  String get forgotPasswordMessage =>
      'Geben Sie die E-Mail-Adresse Ihres Kontos ein. Wir senden Ihnen einen Link zum Zurücksetzen Ihres Passworts.';

  @override
  String get forgotPasswordSendAction => 'Link senden';

  @override
  String get forgotPasswordSent =>
      'Eine E-Mail zum Zurücksetzen des Passworts wurde gesendet.';

  @override
  String get forgotPasswordFailed =>
      'Die E-Mail zum Zurücksetzen konnte nicht gesendet werden.';

  @override
  String get pendingInvitationNotificationTitle => 'Ausstehende Einladung';

  @override
  String pendingInvitationNotificationBody(String teamName) {
    return 'Dein Trainer lädt dich zu $teamName ein. Gib den Code aus der E-Mail ein, um dem Team beizutreten.';
  }

  @override
  String get pendingInvitationAcceptTitle => 'Einladungscode';

  @override
  String get pendingInvitationAcceptMessage =>
      'Gib den Code aus der E-Mail ein, um diese Einladung mit deinem Konto zu verknüpfen.';

  @override
  String get pendingInvitationAcceptSuccess =>
      'Einladung angenommen. Das Team ist jetzt in deinem Profil verfügbar.';

  @override
  String get pendingInvitationAcceptNeedAuth =>
      'Melde dich an, um diese Einladung anzunehmen.';

  @override
  String get playerSeasonSummaryTitle => 'Spielerkarte';

  @override
  String get playerSeasonSummaryTabUnavailabilities => 'Ausfälle';

  @override
  String get playerSeasonSummaryTeamMatches => 'Teamspiele';

  @override
  String get playerSeasonSummaryTeamTrainings => 'Teamtrainings';

  @override
  String get playerSeasonSummaryTrackerAverages =>
      'Leistungsindikatoren (Durchschnitt)';

  @override
  String get playerSeasonSummaryNoTrackerData =>
      'Keine Sensordaten für diesen Zeitraum';

  @override
  String playerSeasonSummaryAgeValue(int age) {
    return '$age J.';
  }

  @override
  String playerSeasonSummaryHwMeasuredAt(String date) {
    return 'Maße am $date';
  }

  @override
  String get preferredFootLabel => 'Starker Fuß';

  @override
  String get preferredFootHint => 'Starken Fuß wählen';

  @override
  String get preferredFootUnspecified => 'Nicht angegeben';

  @override
  String get preferredFootLeft => 'Links';

  @override
  String get preferredFootRight => 'Rechts';

  @override
  String get preferredFootBoth => 'Beide';

  @override
  String get playerSeasonSummaryPreferredFootSaved =>
      'Starker Fuß aktualisiert.';

  @override
  String get wearableDeviceGpsInsidersIntense => 'GPS Insiders Intense';

  @override
  String get intenseGpsSerialGuidance =>
      'Gib die auf dem GPS Insiders Intense Tracker aufgedruckte Seriennummer ein.';

  @override
  String get intenseGpsSerialLabel => 'Seriennummer';

  @override
  String get intenseGpsSerialPlaceholder => 'Seriennummer';

  @override
  String get intenseGpsSerialRequired =>
      'Gib die Seriennummer ein, bevor du fortfährst.';

  @override
  String get intenseGpsTrackerNotFound => 'Tracker nicht vorhanden';

  @override
  String get intenseGpsTrackerAlreadyAssigned =>
      'Dieser Tracker ist bereits zugewiesen';

  @override
  String get intenseGpsConnectSuccess =>
      'GPS Insiders Intense Tracker verknüpft.';

  @override
  String get intenseGpsConnectFailed =>
      'Tracker konnte nicht verknüpft werden. Bitte erneut versuchen.';

  @override
  String get intenseGpsDisconnectFailed =>
      'Trennen des GPS-Trackers fehlgeschlagen.';

  @override
  String get intenseGpsMissingEmail =>
      'Das Spielerprofil benötigt eine E-Mail, um einen GPS-Tracker zu verknüpfen.';

  @override
  String get intenseGpsConnectToggleConnectedSubtitle =>
      'GPS Insiders Intense verbunden';

  @override
  String get whoopAnalysisTitle => 'Whoop-Analyse';

  @override
  String get whoopAnalysisStrain => 'Aktivitäts-Strain';

  @override
  String get whoopAnalysisAvgHr => 'Ø HF';

  @override
  String get whoopAnalysisMaxHr => 'Max. HF';

  @override
  String get whoopAnalysisDuration => 'Dauer';

  @override
  String get whoopAnalysisCalories => 'Kalorien';

  @override
  String get whoopAnalysisAltitude => 'Höhenmeter';

  @override
  String get whoopAnalysisHrZonesTitle => 'Herzfrequenzzonen';

  @override
  String get whoopAnalysisNoZones =>
      'Keine Zonenverteilung für diesen Import. Whoop-Aktivität erneut importieren.';

  @override
  String whoopAnalysisZoneLabel(int zone) {
    return 'Zone $zone';
  }

  @override
  String whoopAnalysisZoneAboveBpm(int bpm) {
    return 'ab $bpm bpm';
  }

  @override
  String whoopAnalysisZoneBpmRange(int min, int max) {
    return '$min – $max bpm';
  }
}
