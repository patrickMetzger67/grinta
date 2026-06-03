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
  String get or => 'O';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get hasATeamCode => 'Ho un codice squadra';

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
  String get actionLogout => 'Disconnetti';

  @override
  String get actionLogoutConfirmTitle => 'Disconnetti';

  @override
  String get actionLogoutConfirmMessage => 'Vuoi davvero disconnetterti?';

  @override
  String get actionAddPlayer => 'Aggiungi un giocatore';

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
  String get tabCompo => 'Composizione';

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
  String get dialogCloseSyncTitle => 'Chiudi la sincronizzazione';

  @override
  String get dialogCloseSyncMessage => 'Vuoi chiudere la sincronizzazione?';

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
  String get matchDetailTitle => 'Dettagli della partita';

  @override
  String get matchDetailVenueTitle => 'Luogo della partita';

  @override
  String get matchDetailTrackerKitTitle => 'Sélection du kit';

  @override
  String get matchDetailTrackerKitLabel => 'Trackers';

  @override
  String get matchDetailTrackerKitComingSoon => 'À venir';

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
  String get highlightTypeGoal => 'Scopo';

  @override
  String get highlightTypeSubstitution => 'Modifica';

  @override
  String get highlightTypeYellowCard => 'Cartellino giallo';

  @override
  String get highlightTypeRedCard => 'Cartellino rosso';

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
  String get roleCoach => 'Allenatore';

  @override
  String get roleExecutive => 'Dirigente';

  @override
  String get positionEducator => 'Educatore/Allenatore';

  @override
  String get positionExecutive => 'Dirigente';

  @override
  String get positionGoalkeeper => 'Portiere';

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
}
