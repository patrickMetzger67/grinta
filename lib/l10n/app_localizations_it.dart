// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Grinta';

  @override
  String get heroTitle => 'Gestisci la tua attività sportiva in modo semplice';

  @override
  String get heroSubtitle =>
      'Organizza i tuoi eventi, gestisci i tuoi membri e monitora la tua attività da un\'interfaccia chiara, moderna e reattiva.';

  @override
  String get loginTitle => 'Connessione';

  @override
  String get loginSubtitle => 'Effettua il login per accedere al tuo spazio.';

  @override
  String get email => 'Indirizzo e-mail';

  @override
  String get emailHint => 'tu@esempio.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get signIn => 'Login';

  @override
  String get emailAndPasswordRequired => 'E-mail e password richieste';

  @override
  String get signInError => 'Errore di connessione';

  @override
  String get userNotFound => 'Nessun utente trovato per questa email';

  @override
  String get wrongPassword => 'Password errata';

  @override
  String get invalidEmail => 'Indirizzo e-mail non valido';

  @override
  String get invalidCredential => 'Identificatori non validi';

  @override
  String get tooManyRequests => 'Troppi tentativi. Riprova più tardi';

  @override
  String get userDisabled => 'Questo account è stato disattivato';

  @override
  String get unexpectedError => 'Errore imprevisto';

  @override
  String get createAccount => 'Creare un account';

  @override
  String get noAccountYet => 'Non hai un account?';

  @override
  String get createOneLink => 'Creane uno';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get passwordRequirements =>
      'La password deve contenere almeno 8 caratteri, una lettera maiuscola, una cifra e un carattere speciale.';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get alreadyHaveAccount => 'Hai già un account?';

  @override
  String get signInLink => 'Login';

  @override
  String get or => 'O';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithMeta => 'Continua con Meta';

  @override
  String get hasATeamCode => 'Ho un codice squadra';

  @override
  String get hasInvitationCodeQuestion => 'Hai un codice di invito?';

  @override
  String get invitationCode => 'Codice di invito';

  @override
  String get invitationCodeHint => 'Inserisci il tuo codice';

  @override
  String get invitationNotFound => 'Codice di invito non trovato';

  @override
  String get invitationNotFoundContinuePrompt =>
      'Questo codice non esiste. Vuoi continuare creando il tuo profilo giocatore?';

  @override
  String get invitationAlreadyUsed =>
      'Questo codice di invito è già stato utilizzato';

  @override
  String invitationSentBy(String firstName, String lastName) {
    return 'L\'invito ti è stato inviato da $firstName $lastName';
  }

  @override
  String get signupWithoutInvitationComingSoon => 'Funzionalità in arrivo';

  @override
  String get emailAlreadyInUse =>
      'Esiste già un account con questo indirizzo email';

  @override
  String get invitationCodeRequired =>
      'Inserisci e convalida un codice di invito';

  @override
  String get invitationChoiceRequired => 'Indica se hai un codice di invito';

  @override
  String get memberProfileTitle => 'Il tuo profilo';

  @override
  String get memberFirstName => 'Nome';

  @override
  String get memberLastName => 'Cognome';

  @override
  String get memberEmail => 'E-mail';

  @override
  String get memberEmailOptional => 'E-mail (facoltativa)';

  @override
  String get memberPhone => 'Telefono';

  @override
  String get memberPhoneOptional => 'Telefono (facoltativo)';

  @override
  String get memberEmailInvalid => 'Inserisci un indirizzo e-mail valido';

  @override
  String get memberPhoneInvalid => 'Inserisci un numero di telefono valido';

  @override
  String get memberPhoneRequired =>
      'Il numero di telefono è obbligatorio per gli inviti';

  @override
  String get memberEmailRequired => 'L\'e-mail è obbligatoria per gli inviti';

  @override
  String invitationEmailSubject(String appName) {
    return 'Il tuo allenatore ti invita a unirti a $appName';
  }

  @override
  String invitationEmailIntro(String appName) {
    return 'Il tuo allenatore ti invita a unirti a $appName';
  }

  @override
  String get invitationEmailCodeLabel => 'Il tuo codice di invito';

  @override
  String get invitationEmailDownloadIos => 'Scarica su iPhone';

  @override
  String get invitationEmailDownloadAndroid => 'Scarica su Android';

  @override
  String invitationEmailFooter(String appName) {
    return 'Hai ricevuto questa e-mail perché un allenatore ti ha aggiunto su $appName. Se non ti aspettavi questo messaggio, puoi ignorarlo.';
  }

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Il tuo allenatore ti invita a unirti a $appName. Il tuo codice: $code.\niPhone: $appleStoreUrl\nAndroid: $googlePlayUrl';
  }

  @override
  String sessionReportEmailSubject(
      String appName, String eventLabel, String title) {
    return '$appName — Report $eventLabel: $title';
  }

  @override
  String sessionReportEmailIntro(String appName) {
    return 'Ecco il tuo report statistico $appName';
  }

  @override
  String get sessionReportEmailEventMatch => 'partita';

  @override
  String get sessionReportEmailEventTraining => 'allenamento';

  @override
  String get sessionReportEmailDetailsLabel => 'Dettagli del report';

  @override
  String get sessionReportEmailTypeLabel => 'Tipo';

  @override
  String get sessionReportEmailTitleLabel => 'Sessione';

  @override
  String get sessionReportEmailDateLabel => 'Data';

  @override
  String get sessionReportEmailTeamLabel => 'Squadra';

  @override
  String get sessionReportEmailPlayersLabel => 'Giocatori';

  @override
  String get sessionReportEmailAvgWorkloadLabel => 'Workload medio';

  @override
  String sessionReportEmailDateLine(String date) {
    return 'Data: $date';
  }

  @override
  String sessionReportEmailTeamLine(String team) {
    return 'Squadra: $team';
  }

  @override
  String sessionReportEmailPlayersLine(int count) {
    return 'Giocatori con dati: $count';
  }

  @override
  String get sessionReportEmailAttachmentHint =>
      'Il report PDF delle statistiche tracker è allegato a questa e-mail.';

  @override
  String get sessionReportEmailDownloadHint =>
      'Scarica il report PDF con il pulsante qui sotto.';

  @override
  String get sessionReportEmailDownloadButton => 'Scarica PDF';

  @override
  String sessionReportEmailDownloadLine(String url) {
    return 'Scarica il PDF: $url';
  }

  @override
  String get sessionReportEmailAskAddress =>
      'Indicami l\'indirizzo e-mail a cui inviare il report PDF.';

  @override
  String get sessionReportEmailNoSessionYesterday =>
      'Non ho trovato alcuna sessione per quel periodo.';

  @override
  String get sessionReportEmailPeriodUnclear =>
      'Precisa il periodo (ieri, oggi…) per il report.';

  @override
  String sessionReportEmailFooter(String appName) {
    return 'Hai ricevuto questa e-mail perché è stato generato un report di sessione da $appName. Se non ti aspettavi questo messaggio, puoi ignorarlo.';
  }

  @override
  String get sessionReportEmailDialogTitle => 'Invia report PDF';

  @override
  String get sessionReportEmailDialogMessage =>
      'Seleziona uno o più manager che riceveranno il report statistico (PDF).';

  @override
  String get sessionReportEmailDialogHint => 'tu@esempio.com';

  @override
  String get sessionReportEmailDialogSend => 'Invia';

  @override
  String get sessionReportEmailDialogCancel => 'Annulla';

  @override
  String get sessionReportEmailActionTooltip => 'Invia report PDF via e-mail';

  @override
  String get sessionReportEmailActionLabel => 'Report PDF';

  @override
  String sessionReportEmailSuccess(String email) {
    return 'Report inviato a $email';
  }

  @override
  String sessionReportEmailSuccessCount(int count) {
    return 'Report inviato a $count destinatari';
  }

  @override
  String sessionReportEmailSelectedCount(int count) {
    return '$count selezionato/i';
  }

  @override
  String get sessionReportEmailSelectAll => 'Seleziona tutto';

  @override
  String get sessionReportEmailDeselectAll => 'Deseleziona tutto';

  @override
  String get sessionReportEmailNoManagers =>
      'Nessun manager con e-mail trovato per questa squadra.';

  @override
  String get sessionReportEmailManualOnlyMessage =>
      'Inserisci uno o più indirizzi e-mail che riceveranno il report (separati da ;).';

  @override
  String get sessionReportEmailAdditionalLabel => 'Indirizzi aggiuntivi';

  @override
  String get sessionReportEmailManualHint =>
      'tu@esempio.com; altro@esempio.com';

  @override
  String get sessionReportEmailManualHelper =>
      'Più indirizzi: separali con un punto e virgola (;).';

  @override
  String get sessionReportEmailNoSelection =>
      'Seleziona un manager o inserisci almeno un indirizzo e-mail.';

  @override
  String get sessionReportEmailFailed => 'Impossibile inviare il report PDF.';

  @override
  String get sessionReportEmailNoStats =>
      'Nessuna statistica tracker disponibile per generare questo report.';

  @override
  String get sessionReportEmailInvalid => 'Indirizzo e-mail non valido.';

  @override
  String get memberInvitationEmailFailed =>
      'Membro aggiunto, ma non è stato possibile inviare l\'e-mail di invito.';

  @override
  String get memberAddedToTeamNotificationTitle => 'Aggiornamento squadra';

  @override
  String memberAddedToTeamNotificationBody(String teamName) {
    return 'Il tuo allenatore ti ha aggiunto a $teamName.';
  }

  @override
  String get invitationAccepted => 'Invito accettato';

  @override
  String get invitationPending => 'Invito in attesa';

  @override
  String get memberAppAccountLinked => 'Account app collegato';

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
  String get memberBirthDate => 'Data di nascita';

  @override
  String get memberBirthDateOptional => 'Data di nascita (facoltativa)';

  @override
  String get memberBirthPlace => 'Luogo di nascita';

  @override
  String get memberBirthPlaceOptional => 'Luogo di nascita (facoltativo)';

  @override
  String get memberNationality => 'Nazionalità';

  @override
  String get memberNationalityHint => 'Seleziona una nazionalità';

  @override
  String get memberNationalitySearch => 'Cerca nazionalità';

  @override
  String get memberPositions => 'Ruoli';

  @override
  String get memberPositionsHint => 'Seleziona uno o più ruoli (facoltativo)';

  @override
  String get memberFirstNameRequired => 'Il nome è obbligatorio';

  @override
  String get memberLastNameRequired => 'Il cognome è obbligatorio';

  @override
  String get memberBirthPlaceRequired => 'Il luogo di nascita è obbligatorio';

  @override
  String get memberNationalityRequired => 'La nazionalità è obbligatoria';

  @override
  String get memberContactRequired =>
      'Inserisci almeno un indirizzo e-mail o un numero di telefono';

  @override
  String get memberProfileIncomplete => 'Completa il tuo profilo';

  @override
  String get memberProfileSubmit => 'Crea il mio profilo';

  @override
  String get memberProfileUpdateSuccess => 'Profilo aggiornato';

  @override
  String memberProfileUpdateError(String error) {
    return 'Impossibile aggiornare il profilo: $error';
  }

  @override
  String get memberProfileChangePhoto => 'Cambia foto';

  @override
  String get memberProfileTakePhoto => 'Scatta una foto';

  @override
  String get memberProfileChooseFromGallery => 'Scegli dalla galleria';

  @override
  String memberProfilePhotoUploadError(String error) {
    return 'Impossibile aggiornare la foto: $error';
  }

  @override
  String get errorEditProfileUnavailable =>
      'Nessun profilo disponibile da modificare';

  @override
  String get createTeamPromptQuestion => 'Vuoi creare una squadra?';

  @override
  String get createTeamPromptLater => 'Più tardi';

  @override
  String get slide1Title => 'Gestisci la tua squadra';

  @override
  String get slide1Subtitle =>
      'Centralizza i tuoi membri, le informazioni e l\'organizzazione in un\'unica applicazione.';

  @override
  String get slide2Title => 'Pianifica le tue partite';

  @override
  String get slide2Subtitle =>
      'Crea i tuoi eventi, convoca i tuoi giocatori e monitora facilmente la disponibilità.';

  @override
  String get slide3Title => 'Tieni traccia delle tue prestazioni';

  @override
  String get slide3Subtitle =>
      'Visualizza statistiche, attività e risultati da un\'interfaccia chiara.';

  @override
  String get actionCancel => 'Cancellare';

  @override
  String get actionDelete => 'ELIMINARE';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionClose => 'Vicino';

  @override
  String get actionOk => 'Va bene';

  @override
  String get actionYes => 'SÌ';

  @override
  String get actionNo => 'NO';

  @override
  String get actionValidate => 'Per convalidare';

  @override
  String get actionCopy => 'Copia';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionBack => 'Indietro';

  @override
  String get actionNew => 'Nuovo';

  @override
  String get actionChoosePeriod => 'Scegli un periodo';

  @override
  String get actionWeekPrevious => 'Settimana -';

  @override
  String get actionWeekNext => 'Settimana +';

  @override
  String get actionLoadBefore => 'Carica in avanti';

  @override
  String get actionLoadAfter => 'Carica dopo';

  @override
  String get actionToday => 'Oggi';

  @override
  String get actionEditProfile => 'Modifica profilo';

  @override
  String get settingsMyUnavailabilities => 'Le mie indisponibilità';

  @override
  String get myUnavailabilitiesNoPlayer =>
      'Nessun profilo giocatore collegato al tuo account.';

  @override
  String get myUnavailabilitiesNoSeason =>
      'Nessuna stagione selezionata. Scegli una stagione dal menu account.';

  @override
  String get actionCreateNewProfile => 'Crea un nuovo profilo';

  @override
  String get actionLogout => 'Disconnetti';

  @override
  String get actionLogoutConfirmTitle => 'Disconnetti';

  @override
  String get actionLogoutConfirmMessage => 'Vuoi davvero disconnetterti?';

  @override
  String get actionCreateTeam => 'Crea una squadra';

  @override
  String get teamCreationAttachClubQuestion =>
      'Vuoi collegare questa squadra a un club?';

  @override
  String get teamCreationSelectClub => 'Seleziona un club';

  @override
  String get teamCreationClubRequired => 'Seleziona un club';

  @override
  String get teamCreationSelectClubTeams => 'Seleziona le squadre del club';

  @override
  String get teamCreationNoClubTeams => 'Nessuna squadra iscritta';

  @override
  String teamCreationSelectedClubTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count squadre selezionate',
      one: '1 squadra selezionata',
      zero: 'Nessuna squadra selezionata',
    );
    return '$_temp0';
  }

  @override
  String teamCreationClubTeamCompetitionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count competizioni',
      one: '1 competizione',
    );
    return '$_temp0';
  }

  @override
  String get teamCreationSoccerType => 'Tipo di calcio';

  @override
  String get teamCreationNoClubWarningTitle => 'Avviso';

  @override
  String get teamCreationNoClubWarning =>
      'Questa squadra non è collegata a un club né a una competizione. In questo caso, calendario e risultati non vengono recuperati automaticamente.';

  @override
  String equipeCompetitionsSheetTitle(String teamName) {
    return 'Competizioni — $teamName';
  }

  @override
  String fffCompetitionPhaseLabel(int phase) {
    return 'Fase $phase';
  }

  @override
  String fffCompetitionGroupeLabel(int groupe) {
    return 'Gruppo $groupe';
  }

  @override
  String get hintSearchClub => 'Cerca un club';

  @override
  String get hintSearchClubTeam => 'Cerca una squadra';

  @override
  String get actionAddPlayer => 'Aggiungi un giocatore';

  @override
  String get actionCreatePlayer => 'Crea un giocatore';

  @override
  String get actionEditPlayer => 'Modifica giocatore';

  @override
  String get actionEditStaff => 'Modifica staff';

  @override
  String get addPlayerPositionRequired => 'Seleziona una posizione';

  @override
  String get addPlayerHeightCmOptional => 'Altezza (cm, facoltativa)';

  @override
  String get addPlayerWeightKgOptional => 'Peso (kg, facoltativo)';

  @override
  String get addPlayerHeightInvalid => 'Inserisci un\'altezza tra 50 e 250 cm';

  @override
  String get addPlayerWeightInvalid => 'Inserisci un peso tra 20 e 200 kg';

  @override
  String get actionAddStaff => 'Aggiungi un rigo';

  @override
  String get actionAddZone => 'Aggiungi un\'area';

  @override
  String get actionAddToCart => 'Aggiungi al carrello';

  @override
  String get actionBeginCheckout => 'Inizia il pagamento';

  @override
  String get actionConnect => 'Collegare';

  @override
  String get actionDownload => 'Scaricamento';

  @override
  String get actionEraseData => 'Cancella dati';

  @override
  String get actionChooseAsiFile => 'Scegli un file .asi';

  @override
  String get actionDefaultValues => 'Valori predefiniti';

  @override
  String get actionRemoveCustomization => 'Rimuovi la personalizzazione';

  @override
  String get actionDisconnect => 'Disconnetti';

  @override
  String get actionAsiFile => 'file .asi';

  @override
  String get actionWeekPreviousLong => 'La settimana precedente';

  @override
  String get actionWeekNextLong => 'La prossima settimana';

  @override
  String get entityTeam => 'squadra';

  @override
  String entityTeamWithIndex(int index) {
    return 'Squadra $index';
  }

  @override
  String get entityTeams => 'squadre';

  @override
  String get entityPlayer => 'Giocatore';

  @override
  String get entityPlayers => 'Giocatori';

  @override
  String get entityPlayerUnknown => 'Giocatore sconosciuto';

  @override
  String get entityPlayerNotSet => 'Giocatore non informato';

  @override
  String get entityStaff => 'Personale';

  @override
  String get entityMatch => 'Incontro';

  @override
  String get entityMatches => 'Partite';

  @override
  String get entityTraining => 'Formazione';

  @override
  String get entityTrainings => 'Allenamenti';

  @override
  String get entityField => 'Terra';

  @override
  String get entityFieldUndefined => 'Terreno indefinito';

  @override
  String get entitySeason => 'Stagione';

  @override
  String get entityEvent => 'evento';

  @override
  String get entityEvents => 'eventi';

  @override
  String get entityConversation => 'conversazione';

  @override
  String get entityUser => 'utente';

  @override
  String get entityProduct => 'Prodotto';

  @override
  String get entityCart => 'Cestino';

  @override
  String get entityApplication => 'Applicazione';

  @override
  String get entityMap => 'Mappa';

  @override
  String get entityIndicator => 'Indicatore';

  @override
  String get entityDeviceId => 'ID del dispositivo';

  @override
  String get entityTracker => 'Localizzatore';

  @override
  String get entityTrackerId => 'id';

  @override
  String get entityName => 'nome';

  @override
  String get entityCode => 'Codice';

  @override
  String get entityLabel => 'Formulazione';

  @override
  String get entityMinSpeed => 'Velocità minima';

  @override
  String get entityMaxSpeed => 'Velocità massima';

  @override
  String get entityFullMatch => 'Intera partita';

  @override
  String get entityFullMatchShort => 'Partita completa';

  @override
  String get navDashboard => 'Pannello di controllo';

  @override
  String get navAgenda => 'Diario';

  @override
  String get navTeams => 'squadre';

  @override
  String get navChat => 'Messaggi';

  @override
  String get navSync => 'Sincronizzazione';

  @override
  String get navNotifications => 'Notifiche';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsEmptyTitle => 'Nessuna notifica';

  @override
  String get notificationsEmptyMessage => 'Non hai notifiche non lette.';

  @override
  String get notificationsMarkAsRead => 'Segna come letta';

  @override
  String get notificationsMarkAsReadError =>
      'Impossibile segnare la notifica come letta.';

  @override
  String get notificationsConvocationMatchDetails => 'Dettagli partita';

  @override
  String get notificationsConvocationPresent => 'Sarò presente';

  @override
  String get notificationsConvocationAbsent => 'Non presente';

  @override
  String get notificationsConvocationAbsentDialogTitle =>
      'Motivo dell\'assenza';

  @override
  String get notificationsConvocationAbsentMessageHint =>
      'Spiega perché non potrai partecipare';

  @override
  String get notificationsConvocationAbsentConfirm => 'Conferma';

  @override
  String get notificationsConvocationAbsentMessageRequired =>
      'Inserisci un messaggio.';

  @override
  String get notificationsConvocationActionError =>
      'Impossibile rispondere alla convocazione.';

  @override
  String get featureDiscoveryAgendaTitle => 'Scopri l’agenda';

  @override
  String get featureDiscoveryAgendaMessage =>
      'Consulta partite e allenamenti in arrivo dalla scheda Agenda.';

  @override
  String get featureDiscoveryDiscover => 'Scopri';

  @override
  String get featureDiscoveryDashboardTitle => 'Scopri la dashboard';

  @override
  String get featureDiscoveryDashboardMessage =>
      'Segui attività, statistiche e prossimi eventi dalla scheda Dashboard.';

  @override
  String get featureDiscoveryChatTitle => 'Scopri la messaggistica';

  @override
  String get featureDiscoveryChatMessage =>
      'Chatta con la squadra dalla scheda Messaggistica.';

  @override
  String get featureDiscoverySyncTitle => 'Scopri la sincronizzazione';

  @override
  String get featureDiscoverySyncMessage =>
      'Carica i dati tracker e gestisci i dispositivi dalla scheda Sincronizzazione.';

  @override
  String get featureDiscoveryTeamsTitle => 'Scopri le squadre';

  @override
  String get featureDiscoveryTeamsMessage =>
      'Gestisci rose e impostazioni dalla sezione Squadre.';

  @override
  String get featureDiscoveryFieldsTitle => 'Scopri i campi';

  @override
  String get featureDiscoveryFieldsMessage =>
      'Localizza i campi per l’analisi tracker dalla scheda Campi.';

  @override
  String get featureDiscoveryCompoTitle => 'Scopri le composizioni';

  @override
  String get featureDiscoveryCompoMessage =>
      'Crea e riutilizza formazioni dalla scheda Composizione.';

  @override
  String get featureDiscoveryMatchCompoTitle => 'Scheda Composizione';

  @override
  String get featureDiscoveryMatchCompoMessage =>
      'Visualizza e modifica la formazione nella scheda Composizione.';

  @override
  String get featureDiscoveryMatchTacticalTitle => 'Scheda Schema tattico';

  @override
  String get featureDiscoveryMatchTacticalMessage =>
      'Posiziona i giocatori in campo nella scheda Schema tattico.';

  @override
  String get featureDiscoveryMatchHighlightsTitle => 'Scheda Highlights';

  @override
  String get featureDiscoveryMatchHighlightsMessage =>
      'Rivedi i momenti chiave nella scheda Highlights.';

  @override
  String get featureDiscoveryMatchStatsTitle => 'Scheda Statistiche';

  @override
  String get featureDiscoveryMatchStatsMessage =>
      'Esplora statistiche tracker e heatmap nella scheda Statistiche.';

  @override
  String get featureDiscoveryDismiss => 'Chiudi';

  @override
  String get navFields => 'Terra';

  @override
  String get navCompo => 'Composizione';

  @override
  String get navStatistics => 'Statistiche';

  @override
  String get navOverview => 'Panoramica';

  @override
  String get navNavigation => 'Navigazione';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get tabCompo => 'Composizione';

  @override
  String get tabConvocations => 'Convocazioni';

  @override
  String get tabConvocationsShort => 'Convoc.';

  @override
  String get matchConvocationsSaved => 'Convocazioni salvate';

  @override
  String get matchConvocationsUnavailable =>
      'Convocazioni non disponibili per questa partita';

  @override
  String get matchPlayerUnavailableOnMatchDate =>
      'Non disponibile alla data della partita';

  @override
  String get matchPlayerCannotConvokeUnavailable =>
      'Questo giocatore non è disponibile alla data della partita e non può essere convocato.';

  @override
  String get matchConvocationsStatusPresent => 'Presenza confermata';

  @override
  String get matchConvocationsStatusPending => 'In attesa di risposta';

  @override
  String get matchConvocationsSendAction => 'Invia convocazioni';

  @override
  String get matchConvocationsSendTitle => 'Invia convocazioni';

  @override
  String matchConvocationsSendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giocatori convocati',
      one: '1 giocatore convocato',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendMessage => 'Messaggio';

  @override
  String get matchConvocationsSendMessageHint =>
      'Informazioni aggiuntive per i giocatori';

  @override
  String get matchConvocationsSendMessageRequired => 'Inserisci un messaggio';

  @override
  String get matchConvocationsSendTime => 'Ora di convocazione';

  @override
  String get matchConvocationsSendAddress => 'Indirizzo di convocazione';

  @override
  String get matchConvocationsSendAddressHint => 'Punto di ritrovo';

  @override
  String get matchConvocationsSendAddressRequired => 'Inserisci un indirizzo';

  @override
  String get matchConvocationsSendSubmit => 'Invia';

  @override
  String matchConvocationsSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convocazioni inviate',
      one: '1 convocazione inviata',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoAccount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giocatori senza account collegato',
      one: '1 giocatore senza account collegato',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giocatori senza notifica push',
      one: '1 giocatore senza notifica push',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendNoRecipients =>
      'Nessun giocatore convocato ha un account Grinta collegato.';

  @override
  String matchConvocationsSendError(String error) {
    return 'Invio non riuscito: $error';
  }

  @override
  String get matchConvocationsSendErrorAuth =>
      'Accedi per inviare le convocazioni.';

  @override
  String matchConvocationsSendDateTimeValue(String date, String time) {
    return '$date alle $time';
  }

  @override
  String matchConvocationsSendMatchLine(String opponent) {
    return 'Partita: $opponent';
  }

  @override
  String matchConvocationsSendTimeLine(String time) {
    return 'Ora: $time';
  }

  @override
  String matchConvocationsSendAddressLine(String address) {
    return 'Indirizzo: $address';
  }

  @override
  String matchConvocationNotificationTitle(String opponent) {
    return 'Convocazione · $opponent';
  }

  @override
  String matchConvocationFeedbackNotificationTitle(String opponent) {
    return 'Risposta convocazione · $opponent';
  }

  @override
  String matchConvocationNotificationBody(String opponent, String time) {
    return '$opponent · Appuntamento alle $time';
  }

  @override
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message) {
    return '$opponent · Appuntamento alle $time · $message';
  }

  @override
  String get tabTacticalSchema => 'Schema tattico';

  @override
  String get tabTacticalSchemaShort => 'Schema';

  @override
  String get matchTacticalSchemaConvocation => 'Convocare giocatori';

  @override
  String get matchTacticalSchemaConvocationHint =>
      'Opzionale — limita la scelta ai convocati';

  @override
  String get matchTacticalSchemaSubstitutes => 'Riserve';

  @override
  String get matchTacticalSchemaAddSubstitute => 'Aggiungi riserva';

  @override
  String get matchTacticalSchemaNoSubstitutes => 'Nessuna riserva';

  @override
  String get matchTacticalSchemaPickPlayer => 'Scegli giocatore';

  @override
  String get matchTacticalSchemaClearSlot => 'Rimuovi dal ruolo';

  @override
  String get matchTacticalSchemaSaved => 'Schema tattico salvato';

  @override
  String get matchTacticalSchemaEmpty =>
      'Nessuno schema tattico per questa partita';

  @override
  String get matchTacticalSchemaUnavailable =>
      'Schema tattico non disponibile per questa partita';

  @override
  String get matchTacticalSchemaNoTeam =>
      'Impossibile identificare la squadra collegata a questa partita.';

  @override
  String get matchTacticalSchemaJerseyNumber => 'Numero di maglia';

  @override
  String get matchTacticalSchemaPlayerAssignment => 'Assegnazione giocatore';

  @override
  String get matchTacticalSchemaJerseyNumberRequired =>
      'Inserisci un numero di maglia (da 1 a 99).';

  @override
  String get matchTacticalSchemaNoJerseyNumberAvailable =>
      'Nessun numero di maglia disponibile (tutti i numeri da 1 a 99 sono già assegnati).';

  @override
  String get matchTacticalSchemaRemoveFromCompo => 'Rimuovere dalla compo?';

  @override
  String get matchTacticalSchemaRemoveFromCompoMessage =>
      'Questo giocatore verrà rimosso dallo schema tattico (ruolo e riserve).';

  @override
  String get matchTacticalSchemaRemoveFromCompoConfirm => 'Rimuovi';

  @override
  String get matchTacticalSchemaSensorRequired =>
      'Seleziona un sensore disponibile.';

  @override
  String get matchTacticalSchemaNoPlayerAvailable =>
      'Nessun giocatore disponibile — tutti i giocatori idonei sono già in compo.';

  @override
  String get tabHighlights => 'Punti salienti';

  @override
  String get tabStats => 'Statistiche';

  @override
  String get tabStarters => 'Titolari';

  @override
  String get tabSubstitutes => 'Sostituti';

  @override
  String get tabSynthesis => 'Riepilogo';

  @override
  String get tabSpeedZones => 'Zone di velocità';

  @override
  String get tabFieldZones => 'Aree di campo';

  @override
  String get tabHalfTimeComparison => 'Confronto a metà tempo';

  @override
  String get tabDistanceTimeline => 'Distanza temporale';

  @override
  String get tabHeatmap => 'Mappa termica';

  @override
  String get periodWeek => 'Settimana';

  @override
  String get periodMonth => 'Mese';

  @override
  String get periodCustom => 'Periodo';

  @override
  String get periodPrep => 'Preparazione fisica';

  @override
  String get periodPostponed => 'Rinviato';

  @override
  String periodMatchDay(String day) {
    return 'Giornata $day';
  }

  @override
  String periodSelectedWeek(String range) {
    return 'Settimana selezionata: $range';
  }

  @override
  String get periodUndefined => 'Nessun periodo definito';

  @override
  String get hintSearchTeam => 'Trova una squadra';

  @override
  String get hintSearchMember => 'Cerca un membro';

  @override
  String get memberSearchPrompt => 'Digita nome o cognome per cercare';

  @override
  String get memberAlreadyOnTeamRoster =>
      'Questo membro fa già parte della rosa';

  @override
  String get memberAlreadyPlayer =>
      'Questo membro è già in squadra come giocatore';

  @override
  String get memberAlreadyStaff => 'Questo membro è già in squadra come staff';

  @override
  String get hintSearchUser => 'Cerca un utente';

  @override
  String get hintSearchAddress => 'Cerca un indirizzo o uno stadio';

  @override
  String get hintSelectSeason => 'Seleziona una stagione';

  @override
  String get hintFieldName => 'Nome del terreno';

  @override
  String get hintCompoType => 'Tipo di composizione';

  @override
  String get hintMetric => 'Indicatore';

  @override
  String get hintDeviceIdExample => 'Esempio: tracker_001';

  @override
  String get hintSpeedZoneMaxEmpty => 'Lascia vuoto per l\'ultima area';

  @override
  String get emptyNoData => 'Nessun dato disponibile';

  @override
  String get emptyNoEvent => 'Nessun evento';

  @override
  String get emptyNoConversation => 'Nessuna conversazione';

  @override
  String get emptyNoHighlights => 'Nessun punto saliente';

  @override
  String get emptyNoCompo =>
      'Non sono state trovate formazioni per questa partita.';

  @override
  String get emptyNoStarters => 'Nessun titolare specificato.';

  @override
  String get emptyNoSubstitutes => 'Nessuna sostituzione indicata.';

  @override
  String get emptyNoTracker => 'Nessun tracker selezionato';

  @override
  String get emptyNoTrackers => 'Nessun tracker da visualizzare';

  @override
  String get emptyNoDeviceId => 'Nessun ID dispositivo disponibile';

  @override
  String get emptyNoFileSelected => 'Nessun file selezionato';

  @override
  String get emptyNoSpeedZone => 'Nessuna zona di velocità disponibile.';

  @override
  String get emptyNoFieldZoneData =>
      'Nessun dato disponibile sulla zona del terreno.';

  @override
  String get emptyNoDistanceTimeline =>
      'Nessuna cronologia delle distanze disponibile.';

  @override
  String get emptyNoStatsForMatch => 'Nessun dato trovato per questa partita.';

  @override
  String get emptyNoStatsTeamAnalysis =>
      'Nessun dato trovato in TRACKER_TeamAnalysis per questa partita.';

  @override
  String get emptyNoPendingMatch => 'Nessuna corrispondenza in sospeso.';

  @override
  String get emptyNoPendingTraining =>
      'Nessun allenamento con tracker in sospeso.';

  @override
  String get emptyNoTeamFound => 'Nessuna squadra trovata';

  @override
  String get emptyNoTeamAvailable => 'Nessuna squadra disponibile';

  @override
  String get emptyNoTeamForSeason =>
      'Nessuna squadra trovata per questa stagione.';

  @override
  String get emptyNoTeamForStats =>
      'Nessuna squadra disponibile per visualizzare le statistiche.';

  @override
  String get emptyNoPlayerForTeam =>
      'Nessun giocatore trovato per questa squadra.';

  @override
  String get trainingPlayersRecap => 'Riepilogo';

  @override
  String get trainingPlayersLoading => 'Caricamento giocatori…';

  @override
  String get trainingPlayersClose => 'Chiudi';

  @override
  String get presencePresent => 'Presente';

  @override
  String get presenceInjured => 'Infortunato/a';

  @override
  String get presenceExcused => 'Giustificato/a';

  @override
  String get presenceAbsent => 'Assente';

  @override
  String get presenceLate => 'In ritardo';

  @override
  String get presenceUnknown => '—';

  @override
  String get trainingPlayersAddPlayer => 'Aggiungi giocatore';

  @override
  String get trainingPlayersAddPlayerTitle => 'Scegli giocatore';

  @override
  String get trainingPlayersNoCandidates =>
      'Tutti i giocatori della squadra sono già iscritti.';

  @override
  String get trainingPlayersChangePresence => 'Modifica presenza';

  @override
  String get trainingPlayersAssignTracker => 'Assegna tracker';

  @override
  String get trainingPlayersNoTrackerAvailable => 'Nessun tracker disponibile.';

  @override
  String get trainingPlayersSelectTracker => 'Tracker';

  @override
  String get emptyNoStaffForTeam => 'Nessuno staff trovato per questa squadra.';

  @override
  String get emptyNoPlayerSelected => 'Nessun giocatore selezionato.';

  @override
  String get emptyNoCurrentSeason => 'Nessuna stagione attuale disponibile.';

  @override
  String get emptyNoUserFound => 'Nessun utente trovato';

  @override
  String get emptyNoUserAvailable => 'Nessun utente disponibile';

  @override
  String get emptyNoConnectedDevice => 'Nessun dispositivo connesso';

  @override
  String get emptyNoMatchToShow => 'Nessuna corrispondenza da visualizzare.';

  @override
  String get emptyNoCompoType => 'Nessun tipo di composizione trovato.';

  @override
  String get emptyNoAnalysis => 'Nessuna analisi disponibile';

  @override
  String get emptyNoStats => 'Nessuna statistica disponibile';

  @override
  String get emptyNoPlayersInStats =>
      'Esistono statistiche ma non è disponibile il punteggio del giocatore.';

  @override
  String get emptyHeatmap => 'Mappa termica non disponibile';

  @override
  String emptyNoSvgForPeriod(String period) {
    return 'Nessuna immagine SVG trovata per $period.';
  }

  @override
  String errorGeneric(String details) {
    return 'Errore: $details';
  }

  @override
  String errorLoadingResource(String resource) {
    return 'Errore durante il caricamento di $resource.';
  }

  @override
  String errorFilteringResource(String resource) {
    return 'Errore durante il filtraggio di $resource.';
  }

  @override
  String errorComputingStats(String resource) {
    return 'Errore nel calcolo delle statistiche di $resource.';
  }

  @override
  String errorSaving(String details) {
    return 'Errore durante il salvataggio: $details';
  }

  @override
  String errorLogout(String details) {
    return 'Errore durante la disconnessione: $details';
  }

  @override
  String get errorStreamConnection => 'Impossibile connettersi allo streaming';

  @override
  String get sessionReplacedOnAnotherDevice =>
      'La tua sessione è stata aperta su un altro dispositivo. Accedi di nuovo.';

  @override
  String get errorOpenAnalysis =>
      'Impossibile aprire l\'analisi: eventId o trackerId mancante.';

  @override
  String get errorAgendaLoad => 'Impossibile caricare il calendario';

  @override
  String errorTeamParamsLoad(String details) {
    return 'Errore nel caricamento dei parametri: $details';
  }

  @override
  String get errorSaveTeamIdEmpty => 'Impossibile salvare: teamId vuoto.';

  @override
  String errorDeleteFailed(String details) {
    return 'Errore durante l\'eliminazione: $details';
  }

  @override
  String get errorLoadingTitle => 'Errore di caricamento';

  @override
  String get errorCompositionTitle => 'Errore di composizione';

  @override
  String get errorPlayerTitle => 'Errore del giocatore';

  @override
  String get errorPlayersTitle => 'Errore del giocatore';

  @override
  String get errorTrackerTitle => 'Errore del localizzatore';

  @override
  String get errorMatchNotIdentified => 'Corrispondenza non identificata';

  @override
  String get errorPlayerNotIdentified => 'Giocatore non identificato';

  @override
  String get errorPlayerNotFound => 'Giocatore non trovato';

  @override
  String get errorPlayerNotFoundInMatch => 'Giocatore non trovato';

  @override
  String get errorStatsUnavailable => 'Statistiche non disponibili';

  @override
  String get errorNoStats => 'Nessuna statistica';

  @override
  String get errorNoStatsForPlayer =>
      'Impossibile caricare le statistiche del giocatore.';

  @override
  String get errorPlayerNotFoundMessage =>
      'Impossibile trovare il giocatore selezionato.';

  @override
  String get errorNoTrackerData =>
      'Nessun dato tracker trovato per questa corrispondenza.';

  @override
  String get errorNoTrackerStats =>
      'Impossibile caricare le statistiche del tracker senza ID corrispondenza.';

  @override
  String get errorNoTrackerAnalysis =>
      'Impossibile trovare i dati del tracker per questo giocatore.';

  @override
  String get errorMatchIdMissing => 'ID corrispondenza mancante.';

  @override
  String errorChatCreate(String details) {
    return 'Errore durante la creazione: $details';
  }

  @override
  String get errorCompoTitle => 'Errore';

  @override
  String get errorNoCompoTitle => 'Nessuna composizione';

  @override
  String get successSettingsSaved => 'Impostazioni salvate con successo.';

  @override
  String get successGpsCopied => 'GPS copiato.';

  @override
  String get successDefaultsLoaded => 'Valori predefiniti caricati nel modulo.';

  @override
  String successConversionDone(int count) {
    return 'Conversione completata - $count riga/e conservata/e';
  }

  @override
  String get infoReadOnly => 'Sola lettura';

  @override
  String get infoWebShellOnly => 'Questa shell è destinata solo a Flutter Web.';

  @override
  String get settingsLanguageLabel => 'Lingua';

  @override
  String get themeDarkModeLabel => 'Modalità scura';

  @override
  String get themeEnableDarkModeTooltip => 'Attiva modalità scura';

  @override
  String get themeDisableDarkModeTooltip => 'Disattiva modalità scura';

  @override
  String get infoParameters => 'Impostazioni';

  @override
  String get infoUserNotConnected => 'Utente non loggato.';

  @override
  String get dialogCloseSyncTitle =>
      'Chiudi definitivamente la sincronizzazione';

  @override
  String get dialogCloseSyncMessage =>
      'Vuoi chiudere definitivamente la sincronizzazione? Sì: questa schermata non sarà più disponibile. No: esci senza chiudere.';

  @override
  String get dialogDeleteCustomizationTitle =>
      'Rimuovere la personalizzazione?';

  @override
  String get dialogDeleteAssignmentTitle => 'Elimina compito';

  @override
  String get dialogNewConversation => 'Nuova conversazione';

  @override
  String get dialogAsiConversionTitle => 'Conversione da ASI a CSV';

  @override
  String get syncMatchesToSync => 'Corrispondenze da sincronizzare';

  @override
  String get syncNoDeviceForTraining =>
      'Nessun dispositivo trovato per questo allenamento';

  @override
  String get syncNoDeviceForMatch =>
      'Nessun dispositivo trovato per questa partita';

  @override
  String get statsWins => 'Vittorie';

  @override
  String get statsLosses => 'Sconfitte';

  @override
  String get statsDraws => 'Manichini';

  @override
  String get statsDistance => 'Distanza';

  @override
  String get statsMaxSpeed => 'Velocità massima';

  @override
  String get statsAvgSpeed => 'Velocità media';

  @override
  String get statsWorkload => 'Carico di lavoro';

  @override
  String get statsFatigue => 'Fatica';

  @override
  String get statsDuration => 'Durata';

  @override
  String get statsSprints => 'Sprint';

  @override
  String get statsHighAccel => 'acc. alto';

  @override
  String get statsHighSpeedTime => 'Ad alta velocità';

  @override
  String get statsHighSpeedTimeShort => 'Tempo ad alta velocità';

  @override
  String get statsMaxAccel => 'acc. massimo';

  @override
  String get statsAxisSpeed => 'Velocità (km/ora)';

  @override
  String get statsAxisTime => 'Volte)';

  @override
  String get statsAxisAcceleration => 'Accelerazione (m/s²)';

  @override
  String get statsScore => 'punto';

  @override
  String statsPlayersCount(int count) {
    return '$count giocatori';
  }

  @override
  String statsAvgWorkload(String value) {
    return 'Carico medio $value';
  }

  @override
  String statsAvgDistance(String value) {
    return 'Distanza media $value';
  }

  @override
  String statsAvgMaxSpeed(String value) {
    return 'Vel. max media $value';
  }

  @override
  String statsZScore(String sign, String value) {
    return 'zScore $sign$value';
  }

  @override
  String get statsMaxAccelSample => 'Accelerazione massima: 4 m/s2';

  @override
  String get speedZoneWalk => 'Camminare';

  @override
  String get speedZoneJogging => 'Jogging';

  @override
  String get speedZoneRun => 'Gara';

  @override
  String get speedZoneHighIntensity => 'Alta intensità';

  @override
  String get speedZoneSprint => 'Sprint';

  @override
  String get highlightKickoff => 'Calcio d\'inizio';

  @override
  String get highlightFullTime => 'Fine della partita';

  @override
  String get substitutionOut => 'Uscita';

  @override
  String get substitutionIn => 'Entrata';

  @override
  String get teamParamsPerformanceTitle => 'Impostazioni delle prestazioni';

  @override
  String get teamParamsSpeedSprints => 'Velocità e sprint';

  @override
  String get teamParamsIntensity => 'Intensità';

  @override
  String get teamParamsGpsTimeline => 'GPS/convalida/sequenza temporale';

  @override
  String get teamParamsSpeedZones => 'Zone di velocità';

  @override
  String get teamParamsMinOneZone => 'Almeno un\'area deve essere preservata.';

  @override
  String get teamParamsAddSpeedZone => 'Aggiunge almeno una zona di velocità.';

  @override
  String get teamParamsSprintThreshold => 'Soglia sprint (km/h)';

  @override
  String get teamParamsSprintMinAccel => 'Mini accelerazione per lo sprint';

  @override
  String get teamParamsSprintMinDuration => 'Durata del mini sprint';

  @override
  String get teamParamsSpeedMinDuration =>
      'Durata della velocità minima convalidata';

  @override
  String get teamParamsHighAccelThreshold => 'Forte soglia di accelerazione';

  @override
  String get teamParamsHighAccelMinDuration =>
      'Mini durata forte accelerazione';

  @override
  String get teamParamsMaxStepDistance =>
      'Distanza massima accettata per passo';

  @override
  String get teamParamsMaxPlausibleSpeed => 'Velocità massima plausibile';

  @override
  String get teamParamsMaxPlausibleAccel => 'Massima accelerazione plausibile';

  @override
  String get teamParamsMinDeltaTime => 'Delta temporale minimo';

  @override
  String get teamParamsMaxDeltaTime => 'Delta temporale massimo';

  @override
  String get teamParamsSmoothingWindow => 'Finestra di lisciatura';

  @override
  String get teamParamsTimelineBucket => 'Cronologia del secchio';

  @override
  String teamMembersPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giocatori',
      one: '1 giocatore',
    );
    return '$_temp0';
  }

  @override
  String teamMembersStaff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri staff',
      one: '1 membro staff',
    );
    return '$_temp0';
  }

  @override
  String get fieldTooltipZoomIn => 'Ingrandisci l\'intero terreno';

  @override
  String get fieldTooltipZoomOut => 'Collassa tutto il terreno';

  @override
  String get fieldTooltipLengthUp => 'Aumenta la lunghezza';

  @override
  String get fieldTooltipLengthDown => 'Ridurre la lunghezza';

  @override
  String get fieldTooltipWidthUp => 'Aumenta la larghezza';

  @override
  String get fieldTooltipWidthDown => 'Ridurre la larghezza';

  @override
  String get fieldTooltipRotateLeft => 'Girare a sinistra';

  @override
  String get fieldTooltipRotateRight => 'Girare a destra';

  @override
  String get fieldTooltipMap => 'Mappa';

  @override
  String get fieldTooltipSatellite => 'Satellitare';

  @override
  String get fieldLocateCorners => 'Individua gli angoli';

  @override
  String get fieldSnackbarLocationDisabled =>
      'Il rilevamento della posizione è disabilitato.';

  @override
  String get fieldSnackbarAllowLocation =>
      'Consente alla posizione di centrare la mappa.';

  @override
  String get fieldSnackbarGpsFailed =>
      'Impossibile recuperare la posizione corrente.';

  @override
  String get fieldSnackbarEnterAddress =>
      'Inserisci un indirizzo o il nome dello stadio.';

  @override
  String get fieldSnackbarMapNotReady => 'La mappa non è ancora pronta.';

  @override
  String get fieldSnackbarAddressNotFound => 'Indirizzo non trovato.';

  @override
  String fieldSnackbarAddressNotFoundWithStatus(String status) {
    return 'Indirizzo non trovato: $status';
  }

  @override
  String get fieldSnackbarGeocodingFailed =>
      'Impossibile cercare questo indirizzo. Controlla la chiave e l\'API di geocodifica.';

  @override
  String get fieldSnackbarPlaceInMap =>
      'Posiziona interamente il terreno sulla mappa.';

  @override
  String get fieldSnackbarGpsConvertFailed =>
      'Impossibile convertire gli angoli in posizioni GPS.';

  @override
  String get fieldHelpGestures =>
      'Campo: trascina per spostare • 2 dita zoom/ruota • trackpad: scroll zoom, Maiusc ruota, Opzione larghezza, Maiusc+Opzione lunghezza';

  @override
  String get compoNotFoundTitle => 'Composizione non specificata';

  @override
  String get compoTypeEmptyTitle => 'Nessuna composizione';

  @override
  String get matchStatsUnavailableTitle => 'Statistiche non disponibili';

  @override
  String get sensorNotFoundTitle => 'Sensore non trovato';

  @override
  String get sensorNotFoundMessage =>
      'Non ci sono sensori associati a questo giocatore per questa partita.';

  @override
  String get matchHomeJersey => 'Maglia da casa';

  @override
  String get matchCartTitle => 'Il tuo cestino';

  @override
  String get matchCartOneItem => '1 articolo - € 49,90';

  @override
  String get asiSelectFile => 'Seleziona un file .asi';

  @override
  String get asiEnterDeviceId => 'Inserisci l\'ID dispositivo';

  @override
  String get asiCannotReadFile => 'Impossibile riprodurre il file selezionato';

  @override
  String get asiFileEmptyOrNoData =>
      'Il file .asi è vuoto o non contiene dati utilizzabili.';

  @override
  String get asiFileMismatch =>
      'Il file non corrisponde al tracker selezionato';

  @override
  String get asiTrackerUnknown => 'Localizzatore non riconosciuto';

  @override
  String asiFilePickError(String details) {
    return 'Errore nella selezione del file: $details';
  }

  @override
  String asiConversionError(String details) {
    return 'Errore durante la conversione: $details';
  }

  @override
  String get asiAnalysisFailed => 'Analisi impossibile';

  @override
  String get playerSynthesisTitle => 'Riepilogo del giocatore';

  @override
  String get playerSynthesisTabTitle => 'Riepilogo';

  @override
  String teamsListCount(int count) {
    return '$count squadra/e';
  }

  @override
  String teamsListCountFiltered(int filtered, int total) {
    return '$filtered / $total';
  }

  @override
  String get teamsListNoResults => 'Nessuna squadra trovata';

  @override
  String get teamsListNoTeams => 'Nessuna squadra disponibile';

  @override
  String get teamStreamChannelSynced => 'Gruppo Stream attivo';

  @override
  String get teamStreamChannelPending => 'Gruppo Stream non sincronizzato';

  @override
  String get teamStreamChannelCreateTitle => 'Creare il gruppo Stream?';

  @override
  String teamStreamChannelCreateMessage(String teamName) {
    return 'Creare il gruppo Stream per la squadra $teamName? Giocatori e staff verranno aggiunti automaticamente.';
  }

  @override
  String get teamStreamChannelCreateConfirm => 'Crea';

  @override
  String get teamStreamChannelCreateLoading => 'Creazione del gruppo Stream…';

  @override
  String teamStreamChannelCreateSuccess(String teamName) {
    return 'Gruppo Stream creato per $teamName.';
  }

  @override
  String teamStreamChannelCreateError(String details) {
    return 'Impossibile creare il gruppo Stream: $details';
  }

  @override
  String get teamStreamChannelCreateNotManager =>
      'Solo i manager possono creare il gruppo Stream.';

  @override
  String get navHome => 'Benvenuto';

  @override
  String get myTeams => 'Le mie squadre';

  @override
  String get syncTrainingsToSync => 'Allenamenti da sincronizzare';

  @override
  String get chatSelectConversation => 'Seleziona una conversazione';

  @override
  String get chatStartNewHint => 'Premi \"Nuovo\" per avviare una chat.';

  @override
  String get chatTryAnotherName => 'Prova un altro nome.';

  @override
  String get chatUsersAppearHere => 'Gli altri utenti appariranno qui.';

  @override
  String get chatChannelMembersTitle => 'Membri';

  @override
  String get chatMessageReadByTitle => 'Letto da';

  @override
  String get chatMessageNotReadYet => 'Non ancora letto';

  @override
  String get matchDetailTitle => 'Dettagli della partita';

  @override
  String get matchDetailVenueTitle => 'Luogo della partita';

  @override
  String get matchDetailTrackerKitTitle => 'Selezione del kit';

  @override
  String get matchDetailTrackerKitLabel => 'Tracker';

  @override
  String get matchDetailTrackerKitComingSoon => 'In arrivo';

  @override
  String get matchDetailTrackerKitWithTracker => 'Con tracker';

  @override
  String get matchDetailTrackerKitWithoutTracker => 'Senza tracker';

  @override
  String get matchDetailTrackerKitSelectLabel => 'Kit';

  @override
  String get matchDetailTrackerKitNoOwners =>
      'Nessun kit configurato per questa squadra.';

  @override
  String get matchDetailTrackerKitSignInRequired =>
      'Accedi per selezionare un kit.';

  @override
  String playerAgeYears(int age) {
    return '$age anni';
  }

  @override
  String get playerAgeUnknown => 'Età non indicata';

  @override
  String get dateUndefined => 'Data non definita';

  @override
  String matchDateTimeAt(String date, String time) {
    return '$date alle $time';
  }

  @override
  String get entityComposition => 'Composizione';

  @override
  String get entityDetails => 'Dettagli';

  @override
  String get entityHeatmap => 'Mappa termica';

  @override
  String get entityPeriods => 'Periodi';

  @override
  String get tabHighlightsShort => 'Tempo';

  @override
  String get emptyNoHighlightsMessage =>
      'Gol, cartellini e sostituzioni appariranno qui.';

  @override
  String get matchHighlightsSourceFmi => 'Punti salienti FMI';

  @override
  String get matchHighlightsSourceGrinta => 'Punti salienti Grinta';

  @override
  String get matchHighlightsGrintaPlaceholderMessage =>
      'Da definire insieme in seguito.';

  @override
  String get matchGrintaHighlightsAddAction => 'Aggiungi momento saliente';

  @override
  String get matchGrintaHighlightsPickTypeTitle =>
      'Scegli il tipo di momento saliente';

  @override
  String get matchGrintaHighlightsPickTimeEventTitle =>
      'Scegli l\'evento temporale';

  @override
  String get matchGrintaHighlightsEmptyMessage =>
      'Inizia con il calcio d\'inizio con il pulsante +.';

  @override
  String get matchGrintaHighlightsDetailsComingSoon =>
      'I dettagli di questo momento saliente arriveranno presto.';

  @override
  String get matchGrintaHighlightsActionTimeEvent => 'Evento temporale';

  @override
  String get matchGrintaHighlightsAllTimeEventsRecorded =>
      'Tutti gli eventi temporali sono già stati registrati per questa partita.';

  @override
  String get matchGrintaHighlightDeleteConfirmTitle =>
      'Eliminare il momento saliente?';

  @override
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel) {
    return 'Vuoi davvero eliminare \"$highlightLabel\"? Questa azione è permanente.';
  }

  @override
  String get matchGrintaHighlightDeleted => 'Momento saliente eliminato';

  @override
  String get matchGoalAddTitle => 'Registra un gol';

  @override
  String get matchGoalPickTeamTitle => 'Quale squadra ha segnato?';

  @override
  String get matchGoalPickScorerTitle => 'Marcatore';

  @override
  String get matchGoalPickAssisterTitle => 'Assistman (opzionale)';

  @override
  String get matchGoalNoAssister => 'Nessun assist';

  @override
  String get matchGoalOpponentJerseyTitle =>
      'Numero di maglia del marcatore (opzionale)';

  @override
  String get matchGoalOpponentJerseyHint => 'es. 10';

  @override
  String get matchGoalScorerRequired => 'Seleziona un marcatore.';

  @override
  String get matchGoalInvalidJerseyNumber =>
      'Inserisci un numero di maglia valido.';

  @override
  String get matchGoalMinuteTitle => 'Minuto';

  @override
  String get matchGoalMinuteHint => 'es. 67';

  @override
  String get matchGoalInvalidMinute => 'Inserisci un minuto di almeno 1.';

  @override
  String get matchGoalSelectScorer => 'Scegli marcatore';

  @override
  String get matchGoalSelectAssister => 'Scegli assistman';

  @override
  String get matchCardYellowAddTitle => 'Registra cartellino giallo';

  @override
  String get matchCardRedAddTitle => 'Registra cartellino rosso';

  @override
  String get matchCardPickTeamTitle => 'Quale squadra riceve il cartellino?';

  @override
  String get matchCardPickPlayerTitle => 'Giocatore';

  @override
  String get matchCardSelectPlayer => 'Scegli giocatore';

  @override
  String get matchCardPlayerRequired => 'Seleziona un giocatore.';

  @override
  String get matchCardOpponentJerseyTitle =>
      'Numero di maglia del giocatore (opzionale)';

  @override
  String get matchCardOpponentJerseyHint => 'es. 10';

  @override
  String get matchSubstitutionAddTitle => 'Registra un cambio';

  @override
  String get matchSubstitutionPickTeamTitle =>
      'Quale squadra effettua il cambio?';

  @override
  String get matchSubstitutionPickOutgoingTitle => 'Giocatore uscente';

  @override
  String get matchSubstitutionPickIncomingTitle => 'Giocatore entrante';

  @override
  String get matchSubstitutionSelectOutgoing => 'Scegli il giocatore uscente';

  @override
  String get matchSubstitutionSelectIncoming => 'Scegli il giocatore entrante';

  @override
  String get matchSubstitutionOutgoingRequired =>
      'Seleziona il giocatore uscente.';

  @override
  String get matchSubstitutionIncomingRequired =>
      'Seleziona il giocatore entrante.';

  @override
  String get matchSubstitutionSamePlayerError =>
      'I due giocatori devono essere diversi.';

  @override
  String get matchSubstitutionOpponentOutgoingJerseyTitle =>
      'Numero del giocatore uscente (opzionale)';

  @override
  String get matchSubstitutionOpponentIncomingJerseyTitle =>
      'Numero del giocatore entrante (opzionale)';

  @override
  String highlightGoalScored(String scorer) {
    return 'Gol — $scorer';
  }

  @override
  String get highlightTimeHalfTime => 'Intervallo';

  @override
  String get highlightTimeSecondHalf => 'Secondo tempo';

  @override
  String get highlightTimeStartExtraTime => 'Tempi supplementari';

  @override
  String get highlightTypeGoal => 'Scopo';

  @override
  String get highlightTypeSubstitution => 'Modifica';

  @override
  String get highlightTypeYellowCard => 'Cartellino giallo';

  @override
  String get highlightTypeRedCard => 'Cartellino rosso';

  @override
  String highlightYellowCardShown(String player) {
    return 'Cartellino giallo — $player';
  }

  @override
  String highlightRedCardShown(String player) {
    return 'Cartellino rosso — $player';
  }

  @override
  String get highlightTypeOwnGoal => 'Autogol';

  @override
  String get highlightTypePenalty => 'Pena';

  @override
  String get highlightTypeGeneric => 'Evidenziare';

  @override
  String highlightSubstitutionOut(String player) {
    return 'Esce $player';
  }

  @override
  String highlightSubstitutionIn(String incoming, String outgoing) {
    return '$incoming sostituisce $outgoing';
  }

  @override
  String get errorNoPlayersTitle => 'Nessun giocatore';

  @override
  String get matchTrackerDataAvailable =>
      'I dati del tracker sono disponibili.';

  @override
  String get matchTrackerDataPending =>
      'I dati del tracker non sono ancora importati.';

  @override
  String get errorPlayerNoTrackerMatch =>
      'Questo giocatore non ha dati di tracciamento per questa partita.';

  @override
  String get trackerSyncTitle => 'Sincronizzazione del sensore';

  @override
  String get trackerAvailableSensors => 'Sensori disponibili';

  @override
  String trackerCount(int count) {
    return '$count tracker';
  }

  @override
  String get trackerAllSensorsSynced =>
      'Tutti i sensori sono stati sincronizzati';

  @override
  String get trackerSensorsRemaining => 'Da sincronizzare';

  @override
  String get trackerSensorsAlreadySynced => 'Già sincronizzati';

  @override
  String trackerSyncedProgress(int synced, int total) {
    return '$synced/$total sincronizzati';
  }

  @override
  String get trackerAlreadySyncedTitle => 'Sincronizzazione già eseguita';

  @override
  String get trackerAlreadySyncedMessage =>
      'Il sensore è già stato sincronizzato per questa sessione.';

  @override
  String get trackerStatusSelected => 'Selezionato';

  @override
  String get trackerStatusSynced => 'Sincronizzato';

  @override
  String get trackerStatusOpen => 'Aprire';

  @override
  String get trackerSelectForActions =>
      'Seleziona un tracker per visualizzare le azioni di accesso, download e cancellazione.';

  @override
  String get trackerSelectedLabel => 'Localizzatore selezionato';

  @override
  String get trackerLogsPlaceholder => 'I registri verranno visualizzati qui.';

  @override
  String get trackerNoDataOnDevice => 'Nessun dato su questo sensore.';

  @override
  String get trackerNoDataOnDeviceTitle =>
      'Sensore connesso — nessuna sessione da importare';

  @override
  String get trackerNoDataOnDeviceDetails =>
      'Connessione USB riuscita (UUID OK), ma il pod non ha sessioni registrate: attività non avviata o dati già cancellati. Registra una sessione sull’Inspirit, poi clicca di nuovo «Scarica».';

  @override
  String get trackerDownloadFailedTitle => 'Download non riuscito';

  @override
  String get trackerDownloadBusyHint =>
      'Assicurati che non ci sia un’altra istanza di Grinta aperta.';

  @override
  String get trackerDownloadPrepareSession =>
      'Preparazione USB prima del download (come Disconnetti e riconnetti)…';

  @override
  String get uploadTrackerLoading => 'Caricamento...';

  @override
  String get uploadTrackerDownloadData => 'Scaricare i dati';

  @override
  String get syncFieldGeolocationPromptTitle => 'Geolocalizzare il campo?';

  @override
  String get syncFieldGeolocationPromptMessage =>
      'Le coordinate GPS del campo non sono impostate. Vuoi definirle prima di scaricare i dati del tracker?';

  @override
  String get trackerUsbAuthorizeHint =>
      'Nessun Inspirit autorizzato per questo sito. Si aprirà Chrome: seleziona il dispositivo Inspirit, poi «Connetti» — non chiudere la finestra.';

  @override
  String get trackerUsbPopupCancelled =>
      'Finestra Chrome chiusa o nessun dispositivo scelto. Collega il tracker, clicca di nuovo «Connetti» e selezionalo nell’elenco.';

  @override
  String get trackerUsbPhysicalReconnect =>
      'Sessione USB scaduta (cavo scollegato o sensore resettato). Ricollega il tracker se serve, poi clicca «Connetti» — Chrome può chiedere di selezionarlo di nuovo.';

  @override
  String trackerDeviceName(String name) {
    return 'Dispositivo: $name';
  }

  @override
  String get asiImportTitle => 'Importa un file .asi';

  @override
  String get asiImportSubtitle =>
      'Seleziona un file, controlla il deviceId, quindi avvia la conversione.';

  @override
  String get asiFileSelectedLabel => 'File selezionato';

  @override
  String get asiImportFileHeader => 'Importa file ASI';

  @override
  String get actionConvertToCsv => 'Converti in CSV';

  @override
  String get asiConverting => 'Conversione in corso...';

  @override
  String get asiPeriodsOne => '1 periodo trasmesso';

  @override
  String asiPeriodsMany(int count) {
    return '$count periodo/i inviato/i - i primi 2 saranno usati per i tempi';
  }

  @override
  String get statsUnitKm => 'km';

  @override
  String get statsUnitKmh => 'km/ora';

  @override
  String get statsUnitCount => 'n.b';

  @override
  String get statsUnitSeconds => 'Asciutto';

  @override
  String get statsUnitMps2 => 'm/s²';

  @override
  String get loadingSession => 'Caricamento sessione...';

  @override
  String get loadingStats => 'Caricamento statistiche...';

  @override
  String get dashboardMyManagedTeams => 'I miei team gestiti';

  @override
  String get dashboardMatchListTitle => 'Elenco delle partite';

  @override
  String periodCustomRange(String start, String end) {
    return 'dal $start al $end';
  }

  @override
  String statsPresenceRate(String value) {
    return 'Tasso di presenza: ($value) %';
  }

  @override
  String get statsDoneSingular => 'realizzato';

  @override
  String get statsDonePlural => 'fatto';

  @override
  String get statsPlannedSingular => 'pianificato';

  @override
  String get statsPlannedPlural => 'pianificato';

  @override
  String get actionDayPrevious => 'Il giorno precedente';

  @override
  String get actionDayNext => 'Il giorno dopo';

  @override
  String get actionMonthPrevious => 'Mese precedente';

  @override
  String get actionMonthNext => 'Il mese prossimo';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionSaving => 'Registrazione...';

  @override
  String periodLoaded(String range) {
    return 'Periodo caricato: $range';
  }

  @override
  String get agendaAddEventTitle => 'Crea';

  @override
  String get agendaAddEventMatch => 'Una partita / incontro';

  @override
  String get agendaAddEventTraining => 'Una sessione di allenamento';

  @override
  String get agendaAddEventPersonalSport => 'Un\'attività sportiva personale';

  @override
  String get agendaAddEventPersonalSportHint => 'Corsa, preparazione, …';

  @override
  String get agendaAddEventNonSport => 'Un evento / attività non sportiva';

  @override
  String get agendaAllDayLabel => 'All day';

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
  String get agendaLegend => 'Leggenda';

  @override
  String agendaOverviewEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventi',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite',
      one: '1 partita',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryTrainings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allenamenti',
      one: '1 allenamento',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryPrepas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prep. fisiche',
      one: '1 prep. fisica',
    );
    return '$_temp0';
  }

  @override
  String get agendaTrackerStatsTitle => 'Statistiche del tracciatore';

  @override
  String get teamDetailBackToTeams => 'Torniamo alle squadre';

  @override
  String teamDetailAverageAge(String age) {
    return 'Età media: $age anni';
  }

  @override
  String get teamDetailConfirmDeleteTitle => 'Conferma l\'eliminazione';

  @override
  String teamDetailConfirmRemoveStaff(String playerName) {
    return 'Rimuovere lo staff $playerName?';
  }

  @override
  String teamDetailConfirmRemovePlayerTeam(String playerName) {
    return 'Rimuovere $playerName dalla squadra?';
  }

  @override
  String teamDetailPlayerRemoved(String playerName) {
    return '$playerName è stato rimosso.';
  }

  @override
  String teamDetailPlayerTeamRemoved(String playerName) {
    return '$playerName è stato rimosso dalla squadra.';
  }

  @override
  String get teamDetailColumnAge => 'Età';

  @override
  String get teamDetailColumnPosition => 'Ruolo';

  @override
  String get teamDetailColumnHeight => 'Altezza';

  @override
  String get teamDetailColumnWeight => 'Peso';

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
    return 'Rimuovere l\'assegnazione del tracker «$trackerName»?';
  }

  @override
  String get teamDetailColumnApp => 'App';

  @override
  String get teamDetailPlayerDetailsTitle => 'Dettagli giocatore';

  @override
  String get teamDetailGrantManager => 'Concedi diritti manager';

  @override
  String get teamDetailRevokeManager => 'Revoca diritti manager';

  @override
  String get teamDetailRemoveFromTeam => 'Rimuovi';

  @override
  String get teamDetailTrackerOwnersTitle => 'Tracker GPS';

  @override
  String get teamDetailTrackerOwnersEmpty =>
      'Nessun kit tracker disponibile per il tuo account.';

  @override
  String teamDetailTrackerOwnerType(String type) {
    return 'Tipo: $type';
  }

  @override
  String get teamDetailTrackerOwnersSaved => 'Kit tracker aggiornati.';

  @override
  String get teamDetailTrackerCoachProRequiredTitle => 'Tracker GPS';

  @override
  String get teamDetailTrackerCoachProRequiredMessage =>
      'Associare kit tracker GPS a una squadra richiede un abbonamento Coach Pro.';

  @override
  String get roleCoach => 'Allenatore';

  @override
  String get roleExecutive => 'Dirigente';

  @override
  String get grintaStaffRoleEducator => 'Allenatore / Educatore';

  @override
  String get grintaStaffRoleMedical => 'Medico';

  @override
  String get grintaStaffRoleExecutive => 'Dirigente';

  @override
  String get addStaffRoleLabel => 'Ruolo';

  @override
  String get addStaffRoleHint => 'Scegli un ruolo';

  @override
  String get addStaffRoleRequired => 'Seleziona un ruolo';

  @override
  String get positionEducator => 'Educatore/Allenatore';

  @override
  String get positionExecutive => 'Dirigente';

  @override
  String get positionGoalkeeper => 'Portiere';

  @override
  String get positionCenterBack => 'Difensore centrale';

  @override
  String get positionCenterBackLeft => 'Difensore centrale sinistro';

  @override
  String get positionCenterBackRight => 'Difensore centrale destro';

  @override
  String get positionLeftDefender => 'Difensore sinistro';

  @override
  String get positionRightDefender => 'Difensore destro';

  @override
  String get positionLeftBack => 'Terzino sinistro';

  @override
  String get positionRightBack => 'Terzino destro';

  @override
  String get positionLeftPiston => 'Esterno sinistro';

  @override
  String get positionRightPiston => 'Esterno destro';

  @override
  String get positionDefensiveMidfielder => 'Mediano';

  @override
  String get positionCentralMidfielder => 'Centrocampista centrale';

  @override
  String get positionBoxToBoxMidfielder => 'Centrocampista di ripiego';

  @override
  String get positionLeftMidfielder => 'Centrocampista sinistro';

  @override
  String get positionRightMidfielder => 'Centrocampista destro';

  @override
  String get positionAttackingMidfielder => 'Centrocampista offensivo';

  @override
  String get positionPlaymaker => 'Trequartista';

  @override
  String get positionLeftWinger => 'Ala sinistra';

  @override
  String get positionRightWinger => 'Ala destra';

  @override
  String get positionSecondStriker => 'Seconda punta';

  @override
  String get positionCenterForward => 'Centravanti';

  @override
  String get positionStriker => 'Finalizzatore';

  @override
  String get positionAttacker => 'Attaccante';

  @override
  String get positionDefender => 'Difensore';

  @override
  String get positionMidfielder => 'Centrocampista';

  @override
  String get positionForward => 'Attaccante';

  @override
  String get teamParamsCustomThresholds => 'Soglie personalizzate';

  @override
  String get teamParamsDefaultThresholds => 'Soglie predefinite';

  @override
  String get teamParamsBackToTeam => 'Torniamo alla squadra';

  @override
  String get teamParamsDeleteCustomizationBody =>
      'Le impostazioni specifiche per questa squadra verranno eliminate. Il team utilizzerà quindi le impostazioni predefinite.';

  @override
  String get teamParamsCustomizationRemoved =>
      'Personalizzazione rimossa. Verranno utilizzate le impostazioni predefinite.';

  @override
  String teamParamsZoneMaxGreaterThanMin(String label) {
    return 'La zona \"$label\" deve avere un massimo superiore al minimo.';
  }

  @override
  String get teamParamsOnlyLastZoneEmptyMax =>
      'Solo l\'ultima zona può avere un terminale max vuoto.';

  @override
  String teamParamsZonesOverlap(String zoneA, String zoneB) {
    return 'Le zone \"$zoneA\" e \"$zoneB\" si sovrappongono.';
  }

  @override
  String get teamParamsCustomizeZonesHint =>
      'Puoi personalizzare liberamente le zone utilizzate per calcolare il tempo trascorso in ciascuna zona.';

  @override
  String get teamParamsZonesReadOnly =>
      'Solo consultazione: le zone di velocità non possono essere modificate.';

  @override
  String get teamParamsInvalidInteger => 'Valore intero non valido';

  @override
  String get teamParamsInvalidNumber => 'Valore numerico non valido';

  @override
  String teamParamsZoneTitle(int index) {
    return 'Zona $index';
  }

  @override
  String get hintRequiredField => 'Campo obbligatorio';

  @override
  String get fieldSnackbarGoogleMapsKeyMissing =>
      'Chiave Google Maps mancante per la ricerca dell\'indirizzo.';

  @override
  String get fieldMapModeHelp =>
      'Modalità mappa: sposta o ingrandisce la mappa';

  @override
  String get fieldSideLeft => 'Lato sinistro';

  @override
  String get fieldSideRight => 'Lato destro';

  @override
  String get fieldEstimatedAddress => 'Indirizzo stimato';

  @override
  String get fieldAddressUnavailable =>
      'Indirizzo postale non disponibile per questa posizione.';

  @override
  String get fieldGpsPositionsTitle => 'Posizioni del terreno GPS';

  @override
  String get fieldAverageLength => 'Lunghezza media';

  @override
  String get fieldAverageWidth => 'Larghezza media';

  @override
  String get trackerParamDefault => 'Impostazione predefinita';

  @override
  String trackerParamTeam(String teamId) {
    return 'Param squadra $teamId';
  }

  @override
  String get halfFirst => '1a metà';

  @override
  String get halfSecond => '2a metà';

  @override
  String halfNth(int index) {
    return '$index° tempo';
  }

  @override
  String get halfFirstShort => '1°';

  @override
  String get halfSecondShort => '2°';

  @override
  String get halfMatchShort => 'Incontro';

  @override
  String get tabSpeedZonesShort => 'Velocità';

  @override
  String get fieldZoneAttackLeftShort => 'Avv. SINISTRA';

  @override
  String get fieldZoneAttackRightShort => 'Avv. GIUSTO';

  @override
  String get fieldZoneMidLeftShort => 'Mil. SINISTRA';

  @override
  String get fieldZoneMidRightShort => 'Mil. GIUSTO';

  @override
  String get fieldZoneDefenseLeftShort => 'sicuramente SINISTRA';

  @override
  String get fieldZoneDefenseRightShort => 'sicuramente GIUSTO';

  @override
  String get fieldZoneAttackLeft => 'Attacco sinistro';

  @override
  String get fieldZoneAttackRight => 'Attacco destro';

  @override
  String get fieldZoneMidLeft => 'Centrocampista sinistro';

  @override
  String get fieldZoneMidRight => 'Al centro giusto';

  @override
  String get fieldZoneDefenseLeft => 'Difesa sinistra';

  @override
  String get fieldZoneDefenseRight => 'Difesa giusta';

  @override
  String get halfFirstUnavailable => 'Primo tempo indisponibile';

  @override
  String get halfSecondUnavailable => '2° tempo indisponibile';

  @override
  String asiHeatmapPointCount(int count, String period) {
    return '$count punto/i - $period';
  }

  @override
  String metricsEvolutionTitle(String metric) {
    return 'Andamento - $metric';
  }

  @override
  String trainingOnDate(String date) {
    return 'Allenamento del $date';
  }

  @override
  String get subscriptionPaywallTitle => 'Passa a Grinta Premium';

  @override
  String get subscriptionPaywallSubtitle =>
      'Sblocca tutte le funzioni per il monitoraggio delle tue squadre e dei tuoi giocatori.';

  @override
  String get subscriptionPaywallLater => 'Più tardi';

  @override
  String get subscriptionOfferingCoach => 'Allenatore';

  @override
  String get subscriptionOfferingPlayer => 'Giocatore';

  @override
  String get subscriptionTierCoachBasic => 'Coach Basic';

  @override
  String get subscriptionTierCoachBasicDesc =>
      'Gestione squadra essenziale: calendario, rosa e statistiche base.';

  @override
  String get subscriptionTierCoachElite => 'Coach Elite';

  @override
  String get subscriptionTierCoachEliteDesc =>
      'Analisi avanzate, formazioni tattiche e strumenti coach completi.';

  @override
  String get subscriptionTierCoachPro => 'Coach Pro';

  @override
  String get subscriptionTierCoachProDesc =>
      'Tutto Elite, più tracker GPS, heatmap ed export pro.';

  @override
  String get subscriptionTierPlayer => 'Giocatore';

  @override
  String get subscriptionTierPlayerDesc =>
      'Monitora prestazioni, statistiche personali e progressi.';

  @override
  String get subscriptionPerMonth => '/mese';

  @override
  String get subscriptionPerYear => '/anno';

  @override
  String get subscriptionBillingMonthly => 'Mensile';

  @override
  String get subscriptionBillingYearly => 'Annuale';

  @override
  String get subscriptionAnnualSavings => '2 mesi gratis';

  @override
  String get subscriptionSubscribe => 'Abbonati';

  @override
  String get subscriptionTierActive => 'Abbonamento attivo';

  @override
  String get subscriptionRestorePurchases => 'Ripristina acquisti';

  @override
  String get subscriptionAutoRenewLegal =>
      'L\'abbonamento si rinnova automaticamente. Puoi annullarlo in qualsiasi momento nelle impostazioni App Store o Google Play.';

  @override
  String get subscriptionStoreUnavailable =>
      'Gli acquisti in-app non sono disponibili su questa piattaforma.';

  @override
  String get subscriptionAlreadyActive => 'Hai già un abbonamento attivo.';

  @override
  String get subscriptionProductNotFound =>
      'Prodotto non trovato. Verifica la configurazione RevenueCat.';

  @override
  String get subscriptionOfferingsUnavailable =>
      'Impossibile caricare i piani di abbonamento. Controlla la connessione e l\'offering web RevenueCat, poi riprova.';

  @override
  String get subscriptionPurchaseFailed => 'Acquisto non riuscito. Riprova.';

  @override
  String get subscriptionRestoreNone => 'Nessun acquisto da ripristinare.';

  @override
  String get subscriptionRestoreFailed => 'Ripristino non riuscito.';

  @override
  String get subscriptionPromptTitle => 'Passa a Premium';

  @override
  String get subscriptionPromptMessage =>
      'Accedi a tutte le funzioni Grinta con un piano adatto al tuo profilo.';

  @override
  String get subscriptionPromptAction => 'Vedi i piani';

  @override
  String get subscriptionMenu => 'Abbonamento';

  @override
  String get subscriptionDetailsTitle => 'Abbonamento';

  @override
  String get subscriptionTier => 'Piano';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Rinnovo il $date';
  }

  @override
  String get subscriptionNone => 'Nessun abbonamento attivo';

  @override
  String subscriptionTrialEnds(String date) {
    return 'Fine prova il $date';
  }

  @override
  String get subscriptionPeriodLabel => 'Periodo';

  @override
  String get subscriptionRenewalLabel => 'Rinnovo';

  @override
  String get subscriptionBillingPeriodMonthly => 'Mensile';

  @override
  String get subscriptionBillingPeriodYearly => 'Annuale';

  @override
  String get subscriptionStatusActive => 'Attivo';

  @override
  String get subscriptionChangePlan => 'Cambia piano';

  @override
  String get subscriptionChangePlanTitle => 'Modifica abbonamento';

  @override
  String get subscriptionChangePlanSubtitle =>
      'Passa da Giocatore a Coach, cambia livello o periodo di fatturazione.';

  @override
  String get subscriptionChangePlanConfirm => 'Conferma modifica';

  @override
  String get subscriptionCurrentPlan => 'Piano attuale';

  @override
  String get subscriptionPlanChanged =>
      'Il tuo abbonamento è stato aggiornato.';

  @override
  String subscriptionLimitMaxTeamsReached(int max) {
    return 'Hai raggiunto il numero massimo di squadre ($max) per il tuo abbonamento.';
  }

  @override
  String subscriptionLimitMaxPlayersReached(int max) {
    return 'Hai raggiunto il numero massimo di giocatori ($max) per questa squadra.';
  }

  @override
  String get subscriptionLimitPlayerTierOnlySelf =>
      'Il tuo abbonamento Giocatore consente di aggiungere solo il tuo profilo a una squadra.';

  @override
  String subscriptionLimitMaxProfilesReached(int max) {
    return 'Hai raggiunto il numero massimo di profili ($max) per il tuo abbonamento.';
  }

  @override
  String get subscriptionLimitProfileUpgradeTitle => 'Profili aggiuntivi';

  @override
  String get subscriptionLimitProfileUpgradeMessage =>
      'Passa a un abbonamento a pagamento per creare profili aggiuntivi.';

  @override
  String get subscriptionLimitProfileCoachBasicTitle => 'Profili aggiuntivi';

  @override
  String get subscriptionLimitProfileCoachBasicMessage =>
      'Passa a Elite o Pro per creare fino a 3 profili.';

  @override
  String get subscriptionLimitProfilePremiumBadge => 'Premium';

  @override
  String get subscriptionLimitTeamUpgradeTitle => 'Squadre aggiuntive';

  @override
  String get subscriptionLimitTeamUpgradeMessage =>
      'Passa all\'abbonamento Giocatore per creare più squadre e gestire la rosa.';

  @override
  String get subscriptionLimitTeamCoachBasicTitle => 'Squadre aggiuntive';

  @override
  String get subscriptionLimitTeamCoachBasicMessage =>
      'Passa a Elite o Pro per creare più squadre.';

  @override
  String get subscriptionLimitTeamDetailBlockedTitle => 'Gestione squadra';

  @override
  String get subscriptionLimitTeamDetailBlockedMessage =>
      'Passa all\'abbonamento Giocatore per accedere ai dettagli della squadra e gestire la rosa.';

  @override
  String get subscriptionLimitTeamCreatedFreePlayer =>
      'La tua squadra è stata creata. Passa all\'abbonamento a pagamento per accedere ai dettagli.';

  @override
  String get trialStatusTitle => 'Prova gratuita';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni rimanenti',
      one: '1 giorno rimanente',
    );
    return '$_temp0';
  }

  @override
  String get shopTitle => 'Shop Grinta';

  @override
  String get shopPromoTitle => 'Offerta shop';

  @override
  String get shopPromoCta => 'Vedi l\'offerta';

  @override
  String get shopBrowseAll => 'Sfoglia lo shop';

  @override
  String get shopLoadError => 'Impossibile caricare lo shop.';

  @override
  String get shopRetry => 'Riprova';

  @override
  String get legalPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get legalTermsOfService => 'Termini di servizio';

  @override
  String get actionDeleteAccount => 'Elimina account';

  @override
  String get actionDeleteAccountConfirmTitle => 'Eliminare l\'account?';

  @override
  String get actionDeleteAccountConfirmMessage =>
      'Questa azione è definitiva. Il tuo account, il profilo membro e i dati associati verranno eliminati.';

  @override
  String errorDeleteAccount(String details) {
    return 'Impossibile eliminare l\'account: $details';
  }

  @override
  String get errorDeleteAccountRequiresRecentLogin =>
      'Per sicurezza, esci, accedi di nuovo e riprova.';

  @override
  String get actionDeleteTeam => 'Elimina squadra';

  @override
  String get teamDeleteConfirmTitle => 'Eliminare la squadra?';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return 'Vuoi davvero eliminare «$teamName»? Questa azione è definitiva. Tutti i dati relativi alla squadra (membri, partite, statistiche, ecc.) verranno eliminati.';
  }

  @override
  String teamDeleteSuccess(String teamName) {
    return 'La squadra «$teamName» è stata eliminata.';
  }

  @override
  String get teamEditNameTitle => 'Modifier le nom de l\'équipe';

  @override
  String get teamEditNameSuccess => 'Nom de l\'équipe mis à jour.';

  @override
  String get calendarSyncToggleLabel => 'Sync. calendario';

  @override
  String get calendarSyncToggleSubtitle =>
      'Aggiornamento all\'apertura dell\'agenda (max 1×/15 min)';

  @override
  String get calendarSyncWebSubtitle =>
      'Scarica un file ICS da importare nel calendario';

  @override
  String get calendarSyncWebRedownloadHint =>
      'Tocca per scaricare di nuovo il file del calendario';

  @override
  String get calendarSyncWebDownloaded =>
      'File calendario scaricato. Importalo nella tua app calendario.';

  @override
  String get calendarSyncPermissionDenied =>
      'Accesso al calendario negato. Abilitalo nelle impostazioni del dispositivo.';

  @override
  String get calendarSyncCalendarCreationFailed =>
      'Impossibile creare il calendario Grinta su questo dispositivo.';

  @override
  String get calendarSyncEnableFailed =>
      'Impossibile attivare la sincronizzazione del calendario. Riprova.';

  @override
  String get calendarSyncForceNow => 'Sincronizza ora';

  @override
  String get calendarSyncForceSuccess => 'Calendario sincronizzato.';

  @override
  String get calendarSyncForceFailed =>
      'Sincronizzazione non riuscita. Riprova.';

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
  String get settingsDevicesAddTitle => 'Ajouter une connexion';

  @override
  String get settingsDevicesAddFabTooltip => 'Ajouter une connexion';

  @override
  String get settingsDevicesAllConnected =>
      'Tous les appareils/applications disponibles sont déjà connectés';

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
  String get createTrainingTitle => 'Nuova sessione di allenamento';

  @override
  String get createTrainingTeam => 'Squadra';

  @override
  String get createTrainingTeamRequired => 'Seleziona una squadra';

  @override
  String get createTrainingDate => 'Data';

  @override
  String get createTrainingTime => 'Ora';

  @override
  String get createTrainingDuration => 'Durata';

  @override
  String createTrainingDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createTrainingRecurrent => 'Ricorrente';

  @override
  String get createTrainingRecurrentDays => 'Giorno/i della settimana';

  @override
  String get createTrainingRecurrentDaysRequired =>
      'Seleziona almeno un giorno';

  @override
  String get createTrainingRecurrentFrom => 'Da';

  @override
  String get createTrainingRecurrentTo => 'A';

  @override
  String get createTrainingRecurrentInvalidRange =>
      'La data di fine non può essere precedente a quella di inizio';

  @override
  String get createTrainingWithTracker => 'Con tracker GPS';

  @override
  String get createTrainingSelectOwner => 'Kit tracker (proprietario)';

  @override
  String get createTrainingOwnerRequired => 'Seleziona un proprietario tracker';

  @override
  String get createTrainingNoOwners =>
      'Nessun kit tracker assegnato a questa squadra.';

  @override
  String get createTrainingNoManagedTeams =>
      'Non gestisci alcuna squadra in questa stagione.';

  @override
  String createTrainingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allenamenti creati',
      one: '1 allenamento creato',
    );
    return '$_temp0';
  }

  @override
  String get createTrainingError =>
      'Impossibile creare l\'allenamento. Riprova.';

  @override
  String get createTrainingSubmit => 'Crea allenamento';

  @override
  String get createTrainingRecurrentConfirmTitle => 'Allenamento ricorrente';

  @override
  String get createTrainingRecurrentConfirmMessage =>
      'Vuoi creare le ricorrenze?';

  @override
  String get editTrainingTitle => 'Modifica allenamento';

  @override
  String get editTrainingSubmit => 'Salva';

  @override
  String get editTrainingSaved => 'Allenamento aggiornato';

  @override
  String get editTrainingError =>
      'Impossibile aggiornare l\'allenamento. Riprova.';

  @override
  String get trainingDeleteConfirmTitle => 'Eliminare l\'allenamento?';

  @override
  String get trainingDeleteConfirmMessage =>
      'Vuoi davvero eliminare questo allenamento? Questa azione è definitiva.';

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
  String get trainingDeleted => 'Allenamento eliminato';

  @override
  String get trainingDeleteError =>
      'Impossibile eliminare l\'allenamento. Riprova.';

  @override
  String get finishTrainingTitle => 'Termina allenamento';

  @override
  String get trainingFinishConfirmTitle => 'Terminare l\'allenamento?';

  @override
  String get trainingFinishConfirmMessage =>
      'I giocatori non disponibili ancora segnati presenti saranno impostati come assenti. Vuoi terminare questo allenamento?';

  @override
  String get trainingFinished => 'Allenamento terminato';

  @override
  String get trainingFinishError =>
      'Impossibile terminare l\'allenamento. Riprova.';

  @override
  String get trainingIntenseFinishTitle => 'Recupero dati sensore';

  @override
  String get trainingIntenseFinishMessage =>
      'Recupero dati dei giocatori presenti con tracker assegnato. Non chiudere questa finestra.';

  @override
  String get trainingIntenseResyncButton => 'Re sync';

  @override
  String get trainingIntenseResyncTitle => 'Risincronizza dati sensori';

  @override
  String get trainingIntenseResyncMessage =>
      'Nuovo recupero dei dati tracker sull’intera finestra dell’allenamento (inizio → fine). Non chiudere questa finestra.';

  @override
  String get trainingIntenseResyncSuccess => 'Dati sensori risincronizzati.';

  @override
  String get trainingIntenseFinishSyncing => 'Sincronizzazione in corso…';

  @override
  String get trainingIntenseFinishStagePending => 'In attesa';

  @override
  String get trainingIntenseFinishStageFetching => 'Recupero dati grezzi…';

  @override
  String get trainingIntenseFinishStageConverting => 'Conversione dati…';

  @override
  String get trainingIntenseFinishStageAnalyzing => 'Analisi in corso…';

  @override
  String get trainingIntenseFinishStageDone => 'Completato';

  @override
  String get trainingIntenseFinishStageError => 'Errore';

  @override
  String get trainingIntenseFinishNoTrackers =>
      'Nessun giocatore presente ha un tracker assegnato. Puoi terminare l\'allenamento senza recupero.';

  @override
  String get trainingIntenseFinishPartialError =>
      'Alcuni recuperi non sono riusciti. Correggi il problema e riprova.';

  @override
  String get intenseLiveTitle => 'Live';

  @override
  String get intenseLiveOpenTooltip => 'Visualizza live tracker';

  @override
  String get intenseLiveSelectPlayer => 'Seleziona un giocatore';

  @override
  String get intenseLiveNoPlayers =>
      'Nessun giocatore presente con tracker assegnato';

  @override
  String get intenseLiveRefresh => 'Aggiorna';

  @override
  String intenseLiveLastUpdate(String time) {
    return 'Aggiornato alle $time';
  }

  @override
  String get tabLive => 'Live';

  @override
  String get tabLiveShort => 'Live';

  @override
  String get createMatchTitle => 'Nuova partita';

  @override
  String get createMatchTeam => 'Squadra';

  @override
  String get createMatchTeamRequired => 'Seleziona una squadra';

  @override
  String get createMatchHome => 'Partita in casa';

  @override
  String get createMatchFriendly => 'Partita amichevole';

  @override
  String get createMatchDate => 'Data';

  @override
  String get createMatchTime => 'Ora';

  @override
  String get createMatchDuration => 'Durata';

  @override
  String createMatchDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createMatchOpponent => 'Avversario';

  @override
  String get createMatchSelectOpponentClub => 'Cerca un club';

  @override
  String get createMatchClubNotFound => 'Club non trovato';

  @override
  String get createMatchOpponentNameManual => 'Nome dell\'avversario';

  @override
  String get createMatchOpponentRequired => 'Indica l\'avversario';

  @override
  String get createMatchVenue => 'Luogo / indirizzo del campo';

  @override
  String get createMatchSurface => 'Superficie di gioco';

  @override
  String get createMatchSurfaceSynthetic => 'Erba sintetica';

  @override
  String get createMatchSurfaceNatural => 'Erba naturale';

  @override
  String get createMatchWithTracker => 'Con tracker GPS';

  @override
  String get createMatchSelectOwner => 'Kit tracker (proprietario)';

  @override
  String get createMatchOwnerRequired => 'Seleziona un proprietario tracker';

  @override
  String get createMatchNoOwners =>
      'Nessun kit tracker assegnato a questa squadra.';

  @override
  String get createMatchNoManagedTeams =>
      'Non gestisci alcuna squadra in questa stagione.';

  @override
  String get createMatchSaved => 'Partita creata';

  @override
  String get createMatchError => 'Impossibile creare la partita. Riprova.';

  @override
  String get createMatchSubmit => 'Crea partita';

  @override
  String get editMatchTitle => 'Modifica partita';

  @override
  String get editMatchSubmit => 'Salva';

  @override
  String get editMatchSaved => 'Partita aggiornata';

  @override
  String get editMatchError => 'Impossibile aggiornare la partita. Riprova.';

  @override
  String get matchDeleteConfirmTitle => 'Eliminare la partita?';

  @override
  String get matchDeleteConfirmMessage =>
      'Vuoi davvero eliminare questa partita? Questa azione è definitiva.';

  @override
  String get matchRemoveFromTeamConfirmTitle =>
      'Rimuovere la partita dal calendario?';

  @override
  String get matchRemoveFromTeamConfirmMessage =>
      'Questa azione rimuoverà la partita dal calendario della tua squadra. La partita resterà visibile per le altre squadre.';

  @override
  String get matchDeleted => 'Partita eliminata';

  @override
  String get matchRemovedFromTeam =>
      'Partita rimossa dal calendario della tua squadra';

  @override
  String get matchDeleteError => 'Impossibile eliminare la partita. Riprova.';

  @override
  String get teamDetailManageUnavailabilities => 'Gestisci indisponibilità';

  @override
  String get manageUnavailabilitiesTitle => 'Indisponibilità';

  @override
  String get manageUnavailabilitiesEmpty =>
      'Nessuna indisponibilità per questa stagione.';

  @override
  String get manageUnavailabilitiesAdd => 'Aggiungi indisponibilità';

  @override
  String get manageUnavailabilitiesEditTitle => 'Modifica indisponibilità';

  @override
  String get manageUnavailabilitiesFromDate => 'Dal';

  @override
  String get manageUnavailabilitiesToDate => 'Al';

  @override
  String get manageUnavailabilitiesType => 'Tipo';

  @override
  String get manageUnavailabilitiesDetails => 'Dettagli';

  @override
  String get manageUnavailabilitiesDetailsHint => 'Dettagli opzionali';

  @override
  String get manageUnavailabilitiesVisible => 'Visibile al team';

  @override
  String get manageUnavailabilitiesVisibleHint =>
      'Se disattivato, solo i manager vedono questa voce';

  @override
  String manageUnavailabilitiesDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get manageUnavailabilitiesHidden => 'Nascosto';

  @override
  String get manageUnavailabilitiesSaved => 'Indisponibilità salvata';

  @override
  String get manageUnavailabilitiesDeleted => 'Indisponibilità eliminata';

  @override
  String get manageUnavailabilitiesError =>
      'Impossibile salvare l\'indisponibilità. Riprova.';

  @override
  String get manageUnavailabilitiesDeleteError =>
      'Impossibile eliminare l\'indisponibilità. Riprova.';

  @override
  String get manageUnavailabilitiesDeleteConfirmTitle =>
      'Eliminare l\'indisponibilità?';

  @override
  String get manageUnavailabilitiesDeleteConfirmMessage =>
      'Questa azione è definitiva.';

  @override
  String get manageUnavailabilitiesInvalidRange =>
      'La data di fine non può precedere quella di inizio';

  @override
  String get manageUnavailabilitiesTypeRequired => 'Seleziona un tipo';

  @override
  String get unavailabilityTypeHoliday => 'Vacanze';

  @override
  String get unavailabilityTypeUnwell => 'Malato';

  @override
  String get unavailabilityTypeInjured => 'Infortunato';

  @override
  String get unavailabilityTypeOther => 'Altro motivo';

  @override
  String teamStatsScreenTitle(String teamName) {
    return 'Statistiche — $teamName';
  }

  @override
  String get teamStatsTabAnalysis => 'Analisi';

  @override
  String get teamStatsTabCalendars => 'Calendari';

  @override
  String get teamStatsCompetitionFilterLabel => 'Competizioni';

  @override
  String get teamStatsOpponentFilterLabel => 'Club';

  @override
  String get teamStatsNoOpponents => 'Nessun club in questa competizione';

  @override
  String get teamStatsTabTrainings => 'Allenamenti';

  @override
  String get teamStatsTabOpponents => 'Avversari';

  @override
  String get teamStatsSubTabMatches => 'Partite';

  @override
  String get teamStatsSubTabRanking => 'Classifica';

  @override
  String get teamStatsSubTabGoals => 'Gol';

  @override
  String get teamStatsSubTabPlayers => 'Giocatori';

  @override
  String get teamStatsSubTabTypicalTeam => 'Formazione tipo';

  @override
  String get teamStatsTypicalTeamStartersSection => 'Titolari probabili';

  @override
  String get teamStatsTypicalTeamSubstitutesSection => 'Sostituti probabili';

  @override
  String teamStatsTypicalTeamStartsLabel(int starts, int total) {
    return '$starts/$total titolarizzazioni';
  }

  @override
  String teamStatsTypicalTeamSubsLabel(int subs, int total) {
    return '$subs/$total come subentrante';
  }

  @override
  String get teamStatsTypicalTeamNoData =>
      'Nessun dato di formazione disponibile per questo avversario';

  @override
  String teamStatsTypicalTeamIncompleteStarters(int count) {
    return 'Solo $count giocatori con dati da titolare';
  }

  @override
  String teamStatsTypicalTeamMatchesBasis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite con formazione',
      one: '1 partita con formazione',
    );
    return 'Basato su $_temp0';
  }

  @override
  String get teamStatsRankingAtDate => 'Attuale';

  @override
  String get teamStatsRankingEvolution => 'Evoluzione';

  @override
  String get teamStatsRankingNoData =>
      'Nessuna classifica disponibile per questa competizione';

  @override
  String get teamStatsRankingSelectCompetition =>
      'Seleziona una competizione per visualizzare la classifica';

  @override
  String get teamStatsRankingColumnRank => '#';

  @override
  String get teamStatsRankingColumnTeam => 'Squadra';

  @override
  String get teamStatsRankingColumnPts => 'Pt';

  @override
  String get teamStatsRankingColumnPlayed => 'G';

  @override
  String get teamStatsRankingColumnWon => 'V';

  @override
  String get teamStatsRankingColumnDrawn => 'P';

  @override
  String get teamStatsRankingColumnLost => 'S';

  @override
  String get teamStatsRankingColumnDiff => '+/-';

  @override
  String get teamStatsRankingAddClubs => 'Confronta club';

  @override
  String get teamStatsRankingSelectClubsTitle =>
      'Seleziona club da confrontare';

  @override
  String get teamStatsRankingOwnTeamLabel => 'La tua squadra';

  @override
  String teamStatsRankingTooltipRank(String rank) {
    return 'Posizione $rank';
  }

  @override
  String get teamStatsAllCompetitions => 'Tutte le competizioni';

  @override
  String get teamStatsContentComingSoon => 'Contenuto in arrivo';

  @override
  String get teamStatsNoCompetitions => 'Nessuna competizione disponibile';

  @override
  String get teamStatsPlayerComingSoon => 'Vista giocatore in arrivo';

  @override
  String get teamStatsPeriodFullSeason => 'Stagione completa';

  @override
  String get teamStatsPeriodFirstHalf => '1° semestre';

  @override
  String get teamStatsPeriodSecondHalf => '2° semestre';

  @override
  String get teamStatsNoPlayedMatches =>
      'Nessuna partita giocata in questo periodo';

  @override
  String teamStatsWdlMatchesDialogTitle(String outcome, String period) {
    return '$outcome — $period';
  }

  @override
  String get teamStatsTrendLabel => 'Tendenza';

  @override
  String get teamStatsTrendUp => 'In crescita';

  @override
  String get teamStatsTrendDown => 'In calo';

  @override
  String get teamStatsTrendFlat => 'Stabile';

  @override
  String get teamStatsTrendInsufficientData => 'Dati insufficienti';

  @override
  String get teamStatsGoalsScored => 'Gol segnati';

  @override
  String get teamStatsGoalsConceded => 'Gol subiti';

  @override
  String get teamStatsGoalsTrendScored => 'Gol segnati';

  @override
  String get teamStatsGoalsTrendConceded => 'Gol subiti';

  @override
  String teamStatsGoalsAvgPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString/partita';
  }

  @override
  String teamStatsGoalsMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite',
      one: '1 partita',
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
  String get teamStatsPlayersColumnPlayer => 'Giocatore';

  @override
  String get teamStatsPlayersColumnConvocations => 'Conv.';

  @override
  String get teamStatsPlayersColumnStarts => 'Titu.';

  @override
  String get teamStatsPlayersColumnPlayTime => 'T. gioco';

  @override
  String get teamStatsPlayersColumnGoals => 'Gol';

  @override
  String get teamStatsPlayersNoData =>
      'Nessun dato giocatore per questo periodo';

  @override
  String teamStatsPlayersPlayTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teamStatsAllMonths => 'Tutti i mesi';

  @override
  String teamStatsTrainingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allenamenti',
      one: '1 allenamento',
    );
    return '$_temp0';
  }

  @override
  String get teamStatsTrainingsAttendanceRate => 'Tasso di presenza';

  @override
  String teamStatsTrainingsAttendanceRateValue(String value) {
    return '$value %';
  }

  @override
  String get teamStatsTrainingsNoData =>
      'Nessun allenamento passato in questo periodo';

  @override
  String get teamStatsTrainingsNoSeasonMonths =>
      'Nessun mese disponibile per questa stagione';

  @override
  String get teamStatsTrainingsColumnPresent => 'Pres.';

  @override
  String get teamStatsTrainingsColumnAbsent => 'Ass.';

  @override
  String get teamStatsTrainingsColumnAttendanceRate => 'Tasso';

  @override
  String get teamStatsTrainingsPlayersNoData =>
      'Nessun dato giocatore per questo periodo';

  @override
  String get teamStatsTrainingsGlobalSection => 'Squadra';

  @override
  String get teamStatsTrainingsPersonalSection => 'Le mie stats';

  @override
  String get teamStatsCalendarNoMatchdays =>
      'Nessuna partita per questa competizione';

  @override
  String get teamStatsCalendarNoMatchesForMatchday =>
      'Nessuna partita per questa giornata';

  @override
  String get teamStatsCalendarDatesLabel => 'Date';

  @override
  String get teamStatsCalendarNoMatchDates => 'Nessuna data programmata';

  @override
  String get teamStatsCalendarDateSeparator => ', ';

  @override
  String get askDiegoTitle => 'Ask Gio';

  @override
  String get askDiegoWelcome =>
      'Ciao! Sono Gio. Posso aiutarti con l\'agenda, il prossimo avversario o le statistiche della squadra.';

  @override
  String get askDiegoInputHint => 'Chiedi a Gio…';

  @override
  String get askDiegoSend => 'Invia';

  @override
  String get askDiegoListen => 'Ascolta la risposta';

  @override
  String get askDiegoOpenScreen => 'Apri';

  @override
  String get askDiegoOpenOpponentStats => 'Vedi statistiche avversario';

  @override
  String get askDiegoStartListening => 'Detta una domanda';

  @override
  String get askDiegoStopListening => 'Interrompi ascolto';

  @override
  String get askDiegoSpeechUnavailable =>
      'Il riconoscimento vocale non è disponibile su questo dispositivo.';

  @override
  String get askDiegoSpeechPermissionDenied =>
      'Permesso microfono o riconoscimento vocale negato. Attivalo in Impostazioni.';

  @override
  String askDiegoSpeechError(String reason) {
    return 'Riconoscimento vocale non riuscito: $reason';
  }

  @override
  String get askDiegoEmptyResponse => 'Non ho una risposta al momento.';

  @override
  String get askDiegoCloseSpeedDial => 'Chiudi';

  @override
  String askDiegoNavigationUnknown(String route) {
    return 'Navigazione sconosciuta: $route';
  }

  @override
  String get askDiegoNavigationAgendaHint =>
      'Apri la scheda Agenda per vedere il calendario.';

  @override
  String get askDiegoNavigationMatchMissing =>
      'ID partita mancante per la navigazione.';

  @override
  String get askDiegoNavigationMatchNotFound => 'Partita non trovata.';

  @override
  String get askDiegoNavigationNoTeam => 'Nessuna squadra selezionata.';

  @override
  String get askDiegoNavigationOpponentsManagerOnly =>
      'Le statistiche avversari sono riservate agli allenatori.';

  @override
  String get askDiegoNavigationOpponentsPremiumOnly =>
      'Le statistiche avversari richiedono un abbonamento.';

  @override
  String get settingsNotificationsSection => 'Notifiche';

  @override
  String get settingsRemindersSubtitle =>
      'Promemoria locali per allenamenti e partite.';

  @override
  String get settingsRemindersEnabled => 'Attiva promemoria';

  @override
  String get settingsQuietDaysLabel => 'Giorni silenziosi';

  @override
  String get settingsQuietHoursLabel => 'Ore silenziose';

  @override
  String get settingsQuietHoursStart => 'Inizio';

  @override
  String get settingsQuietHoursEnd => 'Fine';

  @override
  String get settingsMorningReminderHour => 'Ora promemoria mattutino';

  @override
  String get reminderWeekdayMon => 'Lun';

  @override
  String get reminderWeekdayTue => 'Mar';

  @override
  String get reminderWeekdayWed => 'Mer';

  @override
  String get reminderWeekdayThu => 'Gio';

  @override
  String get reminderWeekdayFri => 'Ven';

  @override
  String get reminderWeekdaySat => 'Sab';

  @override
  String get reminderWeekdaySun => 'Dom';

  @override
  String get reminderTrainingTitle => 'Allenamento oggi';

  @override
  String reminderTrainingBody(String time) {
    return 'Allenamento oggi alle $time — avvisa l\'allenatore se sei assente';
  }

  @override
  String get reminderMatchOpponentStatsTitle => 'Partita oggi';

  @override
  String reminderMatchOpponentStatsBody(String time, String opponent) {
    return 'Oggi alle $time affronti $opponent — scopri le statistiche';
  }

  @override
  String get trainingPresenceConfirmPresent => 'Sarò presente';

  @override
  String get trainingPresenceConfirmAbsent => 'Sarò assente';

  @override
  String get trainingPresenceConfirmedPresent => 'Presenza confermata';

  @override
  String get trainingPresenceConfirmedAbsent => 'Assenza segnalata';

  @override
  String get matchDetailOpponentStats => 'Stats avversario';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle => 'Strumenti di amministrazione della piattaforma.';

  @override
  String get adminPromoCodesSection => 'Codici promo';

  @override
  String get adminPromoCodesSectionDesc =>
      'Crea e gestisci i codici promo per gli abbonamenti.';

  @override
  String get adminPromoCodesTitle => 'Codici promo';

  @override
  String get adminPromoCodeCreate => 'Crea codice';

  @override
  String get adminPromoCodesLoadError => 'Impossibile caricare i codici promo.';

  @override
  String get adminPromoCodesEmpty => 'Nessun codice promo al momento.';

  @override
  String get adminPromoCodeUpdateFailed =>
      'Impossibile aggiornare il codice promo.';

  @override
  String get adminPromoCodeCreated => 'Codice promo creato.';

  @override
  String adminPromoCodeEntitlementLabel(String entitlement) {
    return 'Diritto: $entitlement';
  }

  @override
  String adminPromoCodeUsageLabel(int used, int max) {
    return 'Utilizzi: $used / $max';
  }

  @override
  String adminPromoCodeDurationLabel(int days) {
    return 'Durata: $days giorni';
  }

  @override
  String adminPromoCodeTeamLabel(String teamId) {
    return 'Club: $teamId';
  }

  @override
  String adminPromoCodeExpiresLabel(String date) {
    return 'Scade il: $date';
  }

  @override
  String get adminPromoCodeStatusInactive => 'Inattivo';

  @override
  String get adminPromoCodeStatusExpired => 'Scaduto';

  @override
  String get adminPromoCodeStatusExhausted => 'Esaurito';

  @override
  String get adminPromoCodeStatusActive => 'Attivo';

  @override
  String get adminPromoCodeFieldCode => 'Codice';

  @override
  String get adminPromoCodeFieldCodeInvalid =>
      'Il codice deve contenere almeno 4 caratteri.';

  @override
  String get adminPromoCodeFieldEntitlement => 'Diritto';

  @override
  String get adminPromoCodeFieldMaxUses => 'Utilizzi massimi';

  @override
  String get adminPromoCodeFieldMaxUsesInvalid =>
      'Inserisci un numero maggiore di 0.';

  @override
  String get adminPromoCodeFieldDurationDays => 'Durata abbonamento (giorni)';

  @override
  String get adminPromoCodeFieldDurationDaysInvalid =>
      'Inserisci un numero maggiore di 0.';

  @override
  String get adminPromoCodeFieldTeamId => 'ID club (opzionale)';

  @override
  String get adminPromoCodeFieldTeamIdHint =>
      'Limita il riscatto ai membri di questo club.';

  @override
  String get adminPromoCodeFieldExpiresOptional =>
      'Imposta data di scadenza (opzionale)';

  @override
  String get adminPromoCodeAlreadyExists => 'Questo codice promo esiste già.';

  @override
  String get adminPromoCodeCreateFailed =>
      'Impossibile creare il codice promo.';

  @override
  String get adminPromoCodePermissionDenied =>
      'È necessario l\'accesso admin per gestire i codici promo.';

  @override
  String get adminPromoCodeAuthRequired =>
      'Devi essere connesso per creare un codice promo.';

  @override
  String get adminPromoCodeActions => 'Azioni';

  @override
  String get adminPromoCodeEdit => 'Modifica';

  @override
  String get adminPromoCodeEditTitle => 'Modifica codice promo';

  @override
  String get adminPromoCodeDelete => 'Elimina';

  @override
  String get adminPromoCodeDeleteConfirmTitle => 'Eliminare il codice promo?';

  @override
  String adminPromoCodeDeleteConfirmMessage(String code) {
    return 'Vuoi davvero eliminare il codice $code? Questa azione è definitiva.';
  }

  @override
  String get adminPromoCodeDeleted => 'Codice promo eliminato.';

  @override
  String get adminPromoCodeDeleteFailed =>
      'Impossibile eliminare il codice promo.';

  @override
  String get adminPromoCodeUpdated => 'Codice promo aggiornato.';

  @override
  String get adminPromoCodeSave => 'Salva';

  @override
  String get adminPromoCodeFieldCodeReadOnly =>
      'Il codice non può essere modificato.';

  @override
  String adminPromoCodeFieldMaxUsesBelowUsed(int used) {
    return 'Gli utilizzi massimi devono essere almeno $used (già riscattati).';
  }

  @override
  String get adminPromoCodeFieldActive => 'Attivo';

  @override
  String get adminPromoCodeClearExpiry => 'Rimuovi data di scadenza';

  @override
  String get adminPromoCodeNotFound => 'Codice promo non trovato.';

  @override
  String get adminTrackerOwnersSection => 'Proprietari tracker';

  @override
  String get adminTrackerOwnersSectionDesc =>
      'Crea e gestisci i proprietari dei tracker.';

  @override
  String get adminTrackerOwnersTitle => 'Proprietari tracker';

  @override
  String get adminTrackerOwnersEmpty => 'Ancora nessun proprietario.';

  @override
  String get adminTrackerOwnersLoadError =>
      'Impossibile caricare i proprietari.';

  @override
  String get adminTrackerOwnerCreate => 'Aggiungi proprietario';

  @override
  String get adminTrackerOwnerCreateTitle => 'Aggiungi proprietario';

  @override
  String get adminTrackerOwnerEditTitle => 'Modifica proprietario';

  @override
  String get adminTrackerOwnerFieldName => 'Nome';

  @override
  String get adminTrackerOwnerFieldEmail => 'Email';

  @override
  String get adminTrackerOwnerFieldFirstname => 'Nome';

  @override
  String get adminTrackerOwnerFieldLastname => 'Cognome';

  @override
  String get adminTrackerOwnerFieldActive => 'Attivo';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Tipo di tracker';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, streaming cloud)';

  @override
  String get adminTrackerOwnerFieldRequired => 'Campo obbligatorio';

  @override
  String get adminTrackerOwnerFieldEmailInvalid => 'Email non valida';

  @override
  String get adminTrackerOwnerStatusActive => 'Attivo';

  @override
  String get adminTrackerOwnerStatusInactive => 'Inattivo';

  @override
  String get adminTrackerOwnerSave => 'Salva';

  @override
  String get adminTrackerOwnerDelete => 'Elimina';

  @override
  String get adminTrackerOwnerDeleteConfirmTitle =>
      'Eliminare il proprietario?';

  @override
  String adminTrackerOwnerDeleteConfirmMessage(String name) {
    return 'Vuoi davvero eliminare $name? Questa azione è definitiva.';
  }

  @override
  String get adminTrackerOwnerCreated => 'Proprietario creato.';

  @override
  String get adminTrackerOwnerUpdated => 'Proprietario aggiornato.';

  @override
  String get adminTrackerOwnerDeleted => 'Proprietario eliminato.';

  @override
  String get adminTrackerOwnerSaveFailed =>
      'Impossibile salvare il proprietario.';

  @override
  String get adminTrackerOwnerDeleteFailed =>
      'Impossibile eliminare il proprietario.';

  @override
  String get adminTrackerOwnerPermissionDenied =>
      'È richiesto l\'accesso da amministratore per gestire i proprietari.';

  @override
  String get adminTrackerDevicesSection => 'Gestione tracker';

  @override
  String get adminTrackerDevicesSectionDesc =>
      'Sincronizza, assegna e gestisci i dispositivi tracker.';

  @override
  String get adminTrackerDevicesTitle => 'Gestione tracker';

  @override
  String get adminTrackerDevicesManageAction => 'Gestione tracker';

  @override
  String get adminTrackerDevicesShowUnassigned =>
      'Mostra dispositivi non assegnati';

  @override
  String get adminTrackerDevicesSelectOwner => 'Seleziona un responsabile';

  @override
  String get adminTrackerDevicesResetFilter => 'Reimposta';

  @override
  String get adminTrackerDevicesEmpty => 'Nessun dispositivo';

  @override
  String get adminTrackerDevicesEmptySubtitle =>
      'Nessun documento in TRACKER_Device.';

  @override
  String get adminTrackerDevicesLoadError =>
      'Impossibile caricare i dispositivi.';

  @override
  String adminTrackerDevicesSource(String provider) {
    return 'Fonte: $provider';
  }

  @override
  String adminTrackerDevicesSerial(String serial) {
    return 'Serial: $serial';
  }

  @override
  String adminTrackerDevicesUpdatedAt(String date) {
    return 'Aggiornato: $date';
  }

  @override
  String get adminTrackerDevicesStatusActive => 'Attivo';

  @override
  String get adminTrackerDevicesStatusInactive => 'Inattivo';

  @override
  String get adminTrackerDevicesAssign => 'Assegna';

  @override
  String get adminTrackerDevicesUnassign => 'Rimuovi assegnazione';

  @override
  String get adminTrackerDevicesAssignTitle => 'Assegna un dispositivo';

  @override
  String get adminTrackerDevicesCustomName => 'Nome (opzionale)';

  @override
  String get adminTrackerDevicesCancel => 'Annulla';

  @override
  String get adminTrackerDevicesValidate => 'Conferma';

  @override
  String get adminTrackerDevicesSelectOwnerRequired =>
      'Seleziona un responsabile.';

  @override
  String get adminTrackerDevicesAssignSuccess => 'Assegnazione salvata.';

  @override
  String get adminTrackerDevicesUnassignSuccess => 'Dispositivo rimosso.';

  @override
  String adminTrackerDevicesError(String error) {
    return 'Errore: $error';
  }

  @override
  String get adminTrackerDevicesSyncInspirit => 'Sync Inspirit';

  @override
  String get adminTrackerDevicesSyncFootbar => 'Sync Footbar';

  @override
  String get adminTrackerDevicesSyncInProgress => 'Sincronizzazione...';

  @override
  String get adminTrackerDevicesSyncInspiritInProgress =>
      'Sync Inspirit (insiders) in corso...';

  @override
  String get adminTrackerDevicesSyncFootbarInProgress =>
      'Sync Footbar in corso...';

  @override
  String adminTrackerDevicesSyncInspiritSuccess(int count) {
    return 'Sync Inspirit: $count dispositivo/i aggiornato/i.';
  }

  @override
  String adminTrackerDevicesSyncInspiritError(String error) {
    return 'Errore Sync Inspirit: $error';
  }

  @override
  String get adminTrackerDevicesPermissionDenied =>
      'È richiesto l\'accesso da amministratore per gestire i dispositivi.';

  @override
  String get adminStreamGroupsSection => 'Messaggistica - Gruppi';

  @override
  String get adminStreamGroupsSectionDesc =>
      'Elenca ed elimina i gruppi chat di squadra su GetStream.';

  @override
  String get adminStreamGroupsTitle => 'Messaggistica - Gruppi';

  @override
  String get adminStreamGroupsEmpty => 'Nessun gruppo chat';

  @override
  String get adminStreamGroupsEmptySubtitle =>
      'Nessun canale squadra trovato su GetStream.';

  @override
  String get adminStreamGroupsLoadError =>
      'Impossibile caricare i gruppi chat.';

  @override
  String get adminStreamGroupsRefresh => 'Aggiorna';

  @override
  String adminStreamGroupsCid(String cid) {
    return 'CID: $cid';
  }

  @override
  String adminStreamGroupsMemberCount(int count) {
    return '$count membri';
  }

  @override
  String adminStreamGroupsLastMessageAt(String date) {
    return 'Ultimo messaggio: $date';
  }

  @override
  String get adminStreamGroupsDelete => 'Elimina';

  @override
  String get adminStreamGroupsCancel => 'Annulla';

  @override
  String get adminStreamGroupsDeleteConfirmTitle => 'Eliminare il gruppo?';

  @override
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid) {
    return 'Vuoi davvero eliminare il gruppo $name ($cid)? Questa azione è permanente.';
  }

  @override
  String get adminStreamGroupsDeleted => 'Gruppo eliminato.';

  @override
  String get adminStreamGroupsDeleteFailed =>
      'Impossibile eliminare il gruppo.';

  @override
  String get adminStreamGroupsPermissionDenied =>
      'È richiesto l\'accesso da amministratore per gestire i gruppi chat.';

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
  String get promoCodeMenuLabel => 'Codice promo';

  @override
  String get promoCodeDialogValidate => 'Valida';

  @override
  String get promoCodeRedeemTitle => 'Hai un codice promo?';

  @override
  String get promoCodeRedeemHint => 'Inserisci il tuo codice';

  @override
  String get promoCodeRedeemAction => 'Riscatta';

  @override
  String get promoCodeRedeemEmpty => 'Inserisci un codice promo.';

  @override
  String promoCodeRedeemSuccess(int days, String entitlement) {
    return 'Codice promo applicato: $days giorni di $entitlement.';
  }

  @override
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days) {
    return '$entitlement attivo fino al $expiresAt ($days giorni offerti).';
  }

  @override
  String get promoCodeRedeemSyncPending =>
      'Codice registrato sul server, ma l\'abbonamento non è ancora visibile. Apri Impostazioni → Abbonamento tra poco, oppure esci e accedi di nuovo.';

  @override
  String get promoCodeRedeemRcUnavailable =>
      'Codice registrato sul server, ma RevenueCat non è configurato su questo dispositivo (controlla le chiavi API). Prova su iOS o web, o riavvia con dart_defines.json.';

  @override
  String get promoCodeRedeemNotFound => 'Codice promo non trovato.';

  @override
  String get promoCodeRedeemInvalid => 'Questo codice promo non è più valido.';

  @override
  String get promoCodeRedeemInactive => 'Questo codice promo non è attivo.';

  @override
  String get promoCodeRedeemExpired => 'Questo codice promo è scaduto.';

  @override
  String get promoCodeRedeemAlreadyRedeemed =>
      'Hai già riscattato questo codice promo.';

  @override
  String get promoCodeRedeemExhausted =>
      'Questo codice promo ha raggiunto il limite di utilizzo.';

  @override
  String get promoCodeRedeemTeamMismatch =>
      'Questo codice promo è riservato a un altro club.';

  @override
  String get promoCodeRedeemUnauthenticated =>
      'Devi essere connesso per riscattare un codice promo.';

  @override
  String get promoCodeRedeemFailed => 'Impossibile riscattare il codice promo.';

  @override
  String get playerFeelingPrompt => 'Come ti senti?';

  @override
  String get playerFeelingNotifTitle => 'Riepilogo sessione';

  @override
  String get playerFeelingNotifBody => 'Guarda le tue stats e dicci come ti senti.';

  @override
  String get playerFeelingRecapTitle => 'Il tuo riepilogo';

  @override
  String get playerFeelingRecapSubtitle => 'I tuoi dati di sessione';

  @override
  String get playerFeelingSubmitAction => 'Invia';

  @override
  String get playerFeelingUpdateAction => 'Aggiorna';

  @override
  String get playerFeelingSaved => 'Grazie, la tua sensazione è stata salvata.';

  @override
  String get playerFeelingSaveError => 'Impossibile salvare la sensazione.';

  @override
  String get playerFeelingLoadError => 'Impossibile caricare il riepilogo.';

  @override
  String get forgotPasswordTitle => 'Password dimenticata';

  @override
  String get forgotPasswordMessage => 'Inserisci l\'email del tuo account. Ti invieremo un link per reimpostare la password.';

  @override
  String get forgotPasswordSendAction => 'Invia link';

  @override
  String get forgotPasswordSent => 'È stata inviata un\'email per reimpostare la password.';

  @override
  String get forgotPasswordFailed => 'Impossibile inviare l\'email di reimpostazione.';
}
