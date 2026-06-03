// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Grinta';

  @override
  String get heroTitle => 'Pilotez votre activité sportive simplement';

  @override
  String get heroSubtitle =>
      'Organisez vos événements, gérez vos membres et suivez votre activité depuis une interface claire, moderne et responsive.';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle => 'Connectez-vous pour accéder à votre espace.';

  @override
  String get email => 'Adresse email';

  @override
  String get emailHint => 'vous@exemple.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get emailAndPasswordRequired => 'Email et mot de passe requis';

  @override
  String get signInError => 'Erreur de connexion';

  @override
  String get userNotFound => 'Aucun utilisateur trouvé pour cet email';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get invalidEmail => 'Adresse email invalide';

  @override
  String get invalidCredential => 'Identifiants invalides';

  @override
  String get tooManyRequests => 'Trop de tentatives. Réessaie plus tard';

  @override
  String get userDisabled => 'Ce compte a été désactivé';

  @override
  String get unexpectedError => 'Erreur inattendue';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get or => 'ou';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get hasATeamCode => 'Je dispose d\'un code équipe';

  @override
  String get slide1Title => 'Gérez votre équipe';

  @override
  String get slide1Subtitle =>
      'Centralisez vos membres, vos informations et votre organisation dans une seule application.';

  @override
  String get slide2Title => 'Planifiez vos matchs';

  @override
  String get slide2Subtitle =>
      'Créez vos événements, convoquez vos joueurs et suivez facilement les disponibilités.';

  @override
  String get slide3Title => 'Suivez vos performances';

  @override
  String get slide3Subtitle =>
      'Consultez les statistiques, l’activité et les résultats depuis une interface claire.';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionOk => 'OK';

  @override
  String get actionYes => 'Oui';

  @override
  String get actionNo => 'Non';

  @override
  String get actionValidate => 'Valider';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionNew => 'Nouveau';

  @override
  String get actionChoosePeriod => 'Choisir une période';

  @override
  String get actionWeekPrevious => 'Semaine -';

  @override
  String get actionWeekNext => 'Semaine +';

  @override
  String get actionLoadBefore => 'Charger avant';

  @override
  String get actionLoadAfter => 'Charger après';

  @override
  String get actionToday => 'Aujourd’hui';

  @override
  String get actionLogout => 'Déconnexion';

  @override
  String get actionLogoutConfirmTitle => 'Déconnexion';

  @override
  String get actionLogoutConfirmMessage =>
      'Souhaites-tu vraiment te déconnecter ?';

  @override
  String get actionAddPlayer => 'Ajouter un joueur';

  @override
  String get actionAddStaff => 'Ajouter un staff';

  @override
  String get actionAddZone => 'Ajouter une zone';

  @override
  String get actionAddToCart => 'Ajouter au panier';

  @override
  String get actionBeginCheckout => 'Commencer le paiement';

  @override
  String get actionConnect => 'Connecter';

  @override
  String get actionDownload => 'Télécharger';

  @override
  String get actionEraseData => 'Effacer les données';

  @override
  String get actionChooseAsiFile => 'Choisir un fichier .asi';

  @override
  String get actionDefaultValues => 'Valeurs par défaut';

  @override
  String get actionRemoveCustomization => 'Supprimer la personnalisation';

  @override
  String get actionDisconnect => 'Déconnecter';

  @override
  String get actionAsiFile => 'Fichier .asi';

  @override
  String get actionWeekPreviousLong => 'Semaine précédente';

  @override
  String get actionWeekNextLong => 'Semaine suivante';

  @override
  String get entityTeam => 'Équipe';

  @override
  String entityTeamWithIndex(int index) {
    return 'Équipe $index';
  }

  @override
  String get entityTeams => 'Équipes';

  @override
  String get entityPlayer => 'Joueur';

  @override
  String get entityPlayers => 'Joueurs';

  @override
  String get entityPlayerUnknown => 'Joueur inconnu';

  @override
  String get entityPlayerNotSet => 'Joueur non renseigné';

  @override
  String get entityStaff => 'Staff';

  @override
  String get entityMatch => 'Match';

  @override
  String get entityMatches => 'Matchs';

  @override
  String get entityTraining => 'Entraînement';

  @override
  String get entityTrainings => 'Entraînements';

  @override
  String get entityField => 'Terrain';

  @override
  String get entityFieldUndefined => 'Terrain non défini';

  @override
  String get entitySeason => 'Saison';

  @override
  String get entityEvent => 'événement';

  @override
  String get entityEvents => 'événements';

  @override
  String get entityConversation => 'conversation';

  @override
  String get entityUser => 'utilisateur';

  @override
  String get entityProduct => 'Produit';

  @override
  String get entityCart => 'Panier';

  @override
  String get entityApplication => 'Application';

  @override
  String get entityMap => 'Carte';

  @override
  String get entityIndicator => 'Indicateur';

  @override
  String get entityDeviceId => 'Device ID';

  @override
  String get entityTracker => 'Tracker';

  @override
  String get entityTrackerId => 'id';

  @override
  String get entityName => 'nom';

  @override
  String get entityCode => 'Code';

  @override
  String get entityLabel => 'Libellé';

  @override
  String get entityMinSpeed => 'Vitesse min';

  @override
  String get entityMaxSpeed => 'Vitesse max';

  @override
  String get entityFullMatch => 'Match entier';

  @override
  String get entityFullMatchShort => 'Match complet';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navTeams => 'Équipes';

  @override
  String get navChat => 'Messagerie';

  @override
  String get navSync => 'Synchronisation';

  @override
  String get featureDiscoveryAgendaTitle => 'Découvrez l’agenda';

  @override
  String get featureDiscoveryAgendaMessage =>
      'Consultez vos matchs et entraînements à venir depuis l’onglet Agenda.';

  @override
  String get featureDiscoveryDiscover => 'Découvrir';

  @override
  String get featureDiscoveryDashboardTitle => 'Découvrez le tableau de bord';

  @override
  String get featureDiscoveryDashboardMessage =>
      'Suivez l’activité, les stats et les prochains événements depuis l’onglet Tableau de bord.';

  @override
  String get featureDiscoveryChatTitle => 'Découvrez la messagerie';

  @override
  String get featureDiscoveryChatMessage =>
      'Échangez avec votre équipe depuis l’onglet Messagerie.';

  @override
  String get featureDiscoverySyncTitle => 'Découvrez la synchronisation';

  @override
  String get featureDiscoverySyncMessage =>
      'Envoyez les données tracker et gérez les appareils depuis l’onglet Synchronisation.';

  @override
  String get featureDiscoveryTeamsTitle => 'Découvrez les équipes';

  @override
  String get featureDiscoveryTeamsMessage =>
      'Gérez les effectifs et les paramètres depuis la section Équipes.';

  @override
  String get featureDiscoveryFieldsTitle => 'Découvrez les terrains';

  @override
  String get featureDiscoveryFieldsMessage =>
      'Localisez les terrains pour l’analyse tracker depuis l’onglet Terrains.';

  @override
  String get featureDiscoveryCompoTitle => 'Découvrez la compo';

  @override
  String get featureDiscoveryCompoMessage =>
      'Créez et réutilisez des compositions depuis l’onglet Compo.';

  @override
  String get featureDiscoveryMatchCompoTitle => 'Onglet Compo';

  @override
  String get featureDiscoveryMatchCompoMessage =>
      'Consultez et modifiez la composition du match dans l’onglet Compo.';

  @override
  String get featureDiscoveryMatchTacticalTitle => 'Onglet Schéma tactique';

  @override
  String get featureDiscoveryMatchTacticalMessage =>
      'Placez les joueurs sur le terrain dans l’onglet Schéma tactique.';

  @override
  String get featureDiscoveryMatchHighlightsTitle => 'Onglet Temps forts';

  @override
  String get featureDiscoveryMatchHighlightsMessage =>
      'Revoyez les moments clés dans l’onglet Temps forts.';

  @override
  String get featureDiscoveryMatchStatsTitle => 'Onglet Statistiques';

  @override
  String get featureDiscoveryMatchStatsMessage =>
      'Explorez les stats tracker et heatmaps dans l’onglet Statistiques.';

  @override
  String get featureDiscoveryDismiss => 'Fermer';

  @override
  String get navFields => 'Terrains';

  @override
  String get navCompo => 'Compo';

  @override
  String get navStatistics => 'Statistiques';

  @override
  String get navOverview => 'Vue d’ensemble';

  @override
  String get navNavigation => 'Navigation';

  @override
  String get tabCompo => 'Compo';

  @override
  String get tabTacticalSchema => 'Schéma tactique';

  @override
  String get tabTacticalSchemaShort => 'Schéma';

  @override
  String get matchTacticalSchemaConvocation => 'Convoquer des joueurs';

  @override
  String get matchTacticalSchemaConvocationHint =>
      'Optionnel — limite le choix sur le terrain aux joueurs convoqués';

  @override
  String get matchTacticalSchemaSubstitutes => 'Remplaçants';

  @override
  String get matchTacticalSchemaAddSubstitute => 'Ajouter un remplaçant';

  @override
  String get matchTacticalSchemaNoSubstitutes => 'Aucun remplaçant';

  @override
  String get matchTacticalSchemaPickPlayer => 'Choisir un joueur';

  @override
  String get matchTacticalSchemaClearSlot => 'Retirer du poste';

  @override
  String get matchTacticalSchemaSaved => 'Schéma tactique enregistré';

  @override
  String get matchTacticalSchemaEmpty => 'Aucun schéma tactique pour ce match';

  @override
  String get matchTacticalSchemaUnavailable =>
      'Schéma tactique indisponible pour ce match';

  @override
  String get matchTacticalSchemaNoTeam =>
      'Impossible d\'identifier l\'équipe liée à ce match.';

  @override
  String get tabHighlights => 'Temps forts';

  @override
  String get tabStats => 'Statistiques';

  @override
  String get tabStarters => 'Titulaires';

  @override
  String get tabSubstitutes => 'Remplaçants';

  @override
  String get tabSynthesis => 'Synthèse';

  @override
  String get tabSpeedZones => 'Zones de vitesse';

  @override
  String get tabFieldZones => 'Zones de terrain';

  @override
  String get tabHalfTimeComparison => 'Comparaison mi-temps';

  @override
  String get tabDistanceTimeline => 'Timeline distance';

  @override
  String get tabHeatmap => 'Carte de chaleur';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get periodMonth => 'Mois';

  @override
  String get periodCustom => 'Période';

  @override
  String get periodPrep => 'Prépa physique';

  @override
  String get periodPostponed => 'Reporté';

  @override
  String periodMatchDay(String day) {
    return 'Journée $day';
  }

  @override
  String periodSelectedWeek(String range) {
    return 'Semaine sélectionnée : $range';
  }

  @override
  String get periodUndefined => 'Aucune période définie';

  @override
  String get hintSearchTeam => 'Rechercher une équipe';

  @override
  String get hintSearchUser => 'Rechercher un utilisateur';

  @override
  String get hintSearchAddress => 'Rechercher une adresse ou un stade';

  @override
  String get hintSelectSeason => 'Sélectionner une saison';

  @override
  String get hintFieldName => 'Nom du terrain';

  @override
  String get hintCompoType => 'Type de composition';

  @override
  String get hintMetric => 'Indicateur';

  @override
  String get hintDeviceIdExample => 'Exemple : tracker_001';

  @override
  String get hintSpeedZoneMaxEmpty => 'Laisser vide pour la dernière zone';

  @override
  String get emptyNoData => 'Aucune donnée disponible';

  @override
  String get emptyNoEvent => 'Aucun événement';

  @override
  String get emptyNoConversation => 'Aucune conversation';

  @override
  String get emptyNoHighlights => 'Aucun temps fort';

  @override
  String get emptyNoCompo =>
      'Aucune composition n’a été trouvée pour ce match.';

  @override
  String get emptyNoStarters => 'Aucun titulaire renseigné.';

  @override
  String get emptyNoSubstitutes => 'Aucun remplaçant renseigné.';

  @override
  String get emptyNoTracker => 'Aucun tracker sélectionné';

  @override
  String get emptyNoTrackers => 'Aucun tracker à afficher';

  @override
  String get emptyNoDeviceId => 'Aucun deviceId disponible';

  @override
  String get emptyNoFileSelected => 'Aucun fichier sélectionné';

  @override
  String get emptyNoSpeedZone => 'Aucune zone de vitesse disponible.';

  @override
  String get emptyNoFieldZoneData =>
      'Aucune donnée de zone terrain disponible.';

  @override
  String get emptyNoDistanceTimeline =>
      'Aucune timeline de distance disponible.';

  @override
  String get emptyNoStatsForMatch => 'Aucune donnée trouvée pour ce match.';

  @override
  String get emptyNoStatsTeamAnalysis =>
      'Aucune donnée trouvée dans TRACKER_TeamAnalysis pour ce match.';

  @override
  String get emptyNoPendingMatch => 'Aucun match en attente.';

  @override
  String get emptyNoPendingTraining =>
      'Aucun entraînement avec tracker en attente.';

  @override
  String get emptyNoTeamFound => 'Aucune équipe trouvée';

  @override
  String get emptyNoTeamAvailable => 'Aucune équipe disponible';

  @override
  String get emptyNoTeamForSeason => 'Aucune équipe trouvée pour cette saison.';

  @override
  String get emptyNoTeamForStats =>
      'Aucune équipe disponible pour afficher les statistiques.';

  @override
  String get emptyNoPlayerForTeam => 'Aucun joueur trouvé pour cette équipe.';

  @override
  String get trainingPlayersRecap => 'Récapitulatif';

  @override
  String get trainingPlayersLoading => 'Chargement des joueurs…';

  @override
  String get trainingPlayersClose => 'Fermer';

  @override
  String get presencePresent => 'Présent(e)';

  @override
  String get presenceInjured => 'Blessé(e)';

  @override
  String get presenceExcused => 'Excusé(e)';

  @override
  String get presenceAbsent => 'Absent(e)';

  @override
  String get presenceLate => 'En retard';

  @override
  String get presenceUnknown => '—';

  @override
  String get trainingPlayersAddPlayer => 'Ajouter un joueur';

  @override
  String get trainingPlayersAddPlayerTitle => 'Choisir un joueur';

  @override
  String get trainingPlayersNoCandidates =>
      'Tous les joueurs de l\'équipe sont déjà inscrits.';

  @override
  String get trainingPlayersChangePresence => 'Modifier la présence';

  @override
  String get trainingPlayersAssignTracker => 'Affecter un capteur';

  @override
  String get trainingPlayersNoTrackerAvailable => 'Aucun capteur disponible.';

  @override
  String get trainingPlayersSelectTracker => 'Capteur';

  @override
  String get emptyNoStaffForTeam => 'Aucun staff trouvé pour cette équipe.';

  @override
  String get emptyNoPlayerSelected => 'Aucun joueur sélectionné.';

  @override
  String get emptyNoCurrentSeason => 'Aucune saison en cours disponible.';

  @override
  String get emptyNoUserFound => 'Aucun utilisateur trouvé';

  @override
  String get emptyNoUserAvailable => 'Aucun utilisateur disponible';

  @override
  String get emptyNoConnectedDevice => 'Aucun périphérique connecté';

  @override
  String get emptyNoMatchToShow => 'Aucun match à afficher.';

  @override
  String get emptyNoCompoType => 'Aucun type de composition n’a été trouvé.';

  @override
  String get emptyNoAnalysis => 'Aucune analyse disponible';

  @override
  String get emptyNoStats => 'Aucune statistique disponible';

  @override
  String get emptyNoPlayersInStats =>
      'Les statistiques existent mais aucun score joueur n’est disponible.';

  @override
  String get emptyHeatmap => 'Heatmap indisponible';

  @override
  String emptyNoSvgForPeriod(String period) {
    return 'Aucune image SVG trouvée pour $period.';
  }

  @override
  String errorGeneric(String details) {
    return 'Erreur : $details';
  }

  @override
  String errorLoadingResource(String resource) {
    return 'Erreur lors du chargement de $resource.';
  }

  @override
  String errorFilteringResource(String resource) {
    return 'Erreur lors du filtrage de $resource.';
  }

  @override
  String errorComputingStats(String resource) {
    return 'Erreur lors du calcul des statistiques de $resource.';
  }

  @override
  String errorSaving(String details) {
    return 'Erreur lors de l’enregistrement : $details';
  }

  @override
  String errorLogout(String details) {
    return 'Erreur lors de la déconnexion : $details';
  }

  @override
  String get errorStreamConnection => 'Connexion Stream impossible';

  @override
  String get sessionReplacedOnAnotherDevice =>
      'Votre session a été ouverte sur un autre appareil. Veuillez vous reconnecter.';

  @override
  String get errorOpenAnalysis =>
      'Impossible d’ouvrir l’analyse : eventId ou trackerId manquant.';

  @override
  String get errorAgendaLoad => 'Impossible de charger l’agenda';

  @override
  String errorTeamParamsLoad(String details) {
    return 'Erreur de chargement des paramètres : $details';
  }

  @override
  String get errorSaveTeamIdEmpty => 'Impossible de sauvegarder : teamId vide.';

  @override
  String errorDeleteFailed(String details) {
    return 'Erreur lors de la suppression : $details';
  }

  @override
  String get errorLoadingTitle => 'Erreur de chargement';

  @override
  String get errorCompositionTitle => 'Erreur composition';

  @override
  String get errorPlayerTitle => 'Erreur joueur';

  @override
  String get errorPlayersTitle => 'Erreur joueurs';

  @override
  String get errorTrackerTitle => 'Erreur tracker';

  @override
  String get errorMatchNotIdentified => 'Match non identifié';

  @override
  String get errorPlayerNotIdentified => 'Joueur non identifié';

  @override
  String get errorPlayerNotFound => 'Joueur introuvable';

  @override
  String get errorPlayerNotFoundInMatch => 'Joueur non trouvé';

  @override
  String get errorStatsUnavailable => 'Statistiques indisponibles';

  @override
  String get errorNoStats => 'Aucune statistique';

  @override
  String get errorNoStatsForPlayer =>
      'Impossible de charger les statistiques du joueur.';

  @override
  String get errorPlayerNotFoundMessage =>
      'Impossible de retrouver le joueur sélectionné.';

  @override
  String get errorNoTrackerData =>
      'Aucune donnée tracker trouvée pour ce match.';

  @override
  String get errorNoTrackerStats =>
      'Impossible de charger les statistiques tracker sans identifiant de match.';

  @override
  String get errorNoTrackerAnalysis =>
      'Impossible de trouver les données tracker de ce joueur.';

  @override
  String get errorMatchIdMissing => 'Identifiant du match manquant.';

  @override
  String errorChatCreate(String details) {
    return 'Erreur lors de la création : $details';
  }

  @override
  String get errorCompoTitle => 'Erreur';

  @override
  String get errorNoCompoTitle => 'Aucune composition';

  @override
  String get successSettingsSaved => 'Paramètres enregistrés avec succès.';

  @override
  String get successGpsCopied => 'GPS copié.';

  @override
  String get successDefaultsLoaded =>
      'Valeurs par défaut chargées dans le formulaire.';

  @override
  String successConversionDone(int count) {
    return 'Conversion terminée - $count ligne(s) retenue(s)';
  }

  @override
  String get infoReadOnly => 'Lecture seule';

  @override
  String get infoWebShellOnly =>
      'Ce shell est prévu pour Flutter Web uniquement.';

  @override
  String get settingsLanguageLabel => 'Langue';

  @override
  String get themeDarkModeLabel => 'Mode sombre';

  @override
  String get themeEnableDarkModeTooltip => 'Activer le mode sombre';

  @override
  String get themeDisableDarkModeTooltip => 'Désactiver le mode sombre';

  @override
  String get infoParameters => 'Paramètres';

  @override
  String get infoUserNotConnected => 'Utilisateur non connecté.';

  @override
  String get dialogCloseSyncTitle => 'Clôturer la synchronisation';

  @override
  String get dialogCloseSyncMessage =>
      'Souhaitez-vous clôturer la synchronisation ?';

  @override
  String get dialogDeleteCustomizationTitle =>
      'Supprimer la personnalisation ?';

  @override
  String get dialogDeleteAssignmentTitle => 'Supprimer l’affectation';

  @override
  String get dialogNewConversation => 'Nouvelle conversation';

  @override
  String get dialogAsiConversionTitle => 'Conversion ASI vers CSV';

  @override
  String get syncMatchesToSync => 'Matchs à synchroniser';

  @override
  String get syncNoDeviceForTraining =>
      'Aucun device trouvé pour cet entraînement';

  @override
  String get syncNoDeviceForMatch => 'Aucun capteur trouvé pour ce match';

  @override
  String get statsWins => 'Victoires';

  @override
  String get statsLosses => 'Défaites';

  @override
  String get statsDraws => 'Nuls';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsMaxSpeed => 'Vitesse max';

  @override
  String get statsAvgSpeed => 'Vitesse moy.';

  @override
  String get statsWorkload => 'Workload';

  @override
  String get statsFatigue => 'Fatigue';

  @override
  String get statsDuration => 'Durée';

  @override
  String get statsSprints => 'Sprints';

  @override
  String get statsHighAccel => 'Acc. hautes';

  @override
  String get statsHighSpeedTime => 'Haute vitesse';

  @override
  String get statsHighSpeedTimeShort => 'Tps haute vitesse';

  @override
  String get statsMaxAccel => 'Acc. max';

  @override
  String get statsAxisSpeed => 'Vitesse (km/h)';

  @override
  String get statsAxisTime => 'Temps (s)';

  @override
  String get statsAxisAcceleration => 'Accélération (m/s²)';

  @override
  String get statsScore => 'score';

  @override
  String statsPlayersCount(int count) {
    return '$count joueurs';
  }

  @override
  String statsAvgWorkload(String value) {
    return 'Charge Moy. $value';
  }

  @override
  String statsAvgDistance(String value) {
    return 'Distance Moy. $value';
  }

  @override
  String statsAvgMaxSpeed(String value) {
    return 'Vitesse max Moy. $value';
  }

  @override
  String statsZScore(String sign, String value) {
    return 'zScore $sign$value';
  }

  @override
  String get statsMaxAccelSample => 'Accélération max: 4m/s2';

  @override
  String get speedZoneWalk => 'Marche';

  @override
  String get speedZoneJogging => 'Jogging';

  @override
  String get speedZoneRun => 'Course';

  @override
  String get speedZoneHighIntensity => 'Haute intensité';

  @override
  String get speedZoneSprint => 'Sprint';

  @override
  String get highlightKickoff => 'Coup d’envoi';

  @override
  String get highlightFullTime => 'Fin du match';

  @override
  String get substitutionOut => 'Sortie';

  @override
  String get substitutionIn => 'Entrée';

  @override
  String get teamParamsPerformanceTitle => 'Paramètres performance';

  @override
  String get teamParamsSpeedSprints => 'Vitesse & sprints';

  @override
  String get teamParamsIntensity => 'Intensité';

  @override
  String get teamParamsGpsTimeline => 'GPS / validation / timeline';

  @override
  String get teamParamsSpeedZones => 'Zones de vitesse';

  @override
  String get teamParamsMinOneZone => 'Il faut conserver au moins une zone.';

  @override
  String get teamParamsAddSpeedZone => 'Ajoute au moins une zone de vitesse.';

  @override
  String get teamParamsSprintThreshold => 'Seuil sprint (km/h)';

  @override
  String get teamParamsSprintMinAccel => 'Accélération mini pour sprint';

  @override
  String get teamParamsSprintMinDuration => 'Durée mini sprint';

  @override
  String get teamParamsSpeedMinDuration => 'Durée mini vitesse validée';

  @override
  String get teamParamsHighAccelThreshold => 'Seuil forte accélération';

  @override
  String get teamParamsHighAccelMinDuration => 'Durée mini forte accélération';

  @override
  String get teamParamsMaxStepDistance => 'Distance max acceptée par pas';

  @override
  String get teamParamsMaxPlausibleSpeed => 'Vitesse max plausible';

  @override
  String get teamParamsMaxPlausibleAccel => 'Accélération max plausible';

  @override
  String get teamParamsMinDeltaTime => 'Delta temps mini';

  @override
  String get teamParamsMaxDeltaTime => 'Delta temps maxi';

  @override
  String get teamParamsSmoothingWindow => 'Fenêtre de lissage';

  @override
  String get teamParamsTimelineBucket => 'Bucket timeline';

  @override
  String teamMembersPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs',
      one: '1 joueur',
    );
    return '$_temp0';
  }

  @override
  String teamMembersStaff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staffs',
      one: '1 staff',
    );
    return '$_temp0';
  }

  @override
  String get fieldTooltipZoomIn => 'Agrandir tout le terrain';

  @override
  String get fieldTooltipZoomOut => 'Réduire tout le terrain';

  @override
  String get fieldTooltipLengthUp => 'Augmenter la longueur';

  @override
  String get fieldTooltipLengthDown => 'Réduire la longueur';

  @override
  String get fieldTooltipWidthUp => 'Augmenter la largeur';

  @override
  String get fieldTooltipWidthDown => 'Réduire la largeur';

  @override
  String get fieldTooltipRotateLeft => 'Tourner à gauche';

  @override
  String get fieldTooltipRotateRight => 'Tourner à droite';

  @override
  String get fieldTooltipMap => 'Carte';

  @override
  String get fieldTooltipSatellite => 'Satellite';

  @override
  String get fieldLocateCorners => 'Localiser les coins';

  @override
  String get fieldSnackbarLocationDisabled => 'La localisation est désactivée.';

  @override
  String get fieldSnackbarAllowLocation =>
      'Autorise la localisation pour centrer la carte.';

  @override
  String get fieldSnackbarGpsFailed =>
      'Impossible de récupérer la position actuelle.';

  @override
  String get fieldSnackbarEnterAddress =>
      'Saisis une adresse ou un nom de stade.';

  @override
  String get fieldSnackbarMapNotReady => 'La carte n’est pas encore prête.';

  @override
  String get fieldSnackbarAddressNotFound => 'Adresse introuvable.';

  @override
  String fieldSnackbarAddressNotFoundWithStatus(String status) {
    return 'Adresse introuvable : $status';
  }

  @override
  String get fieldSnackbarGeocodingFailed =>
      'Impossible de rechercher cette adresse. Vérifie la clé et l’API Geocoding.';

  @override
  String get fieldSnackbarPlaceInMap =>
      'Place le terrain entièrement dans la carte.';

  @override
  String get fieldSnackbarGpsConvertFailed =>
      'Impossible de convertir les coins en positions GPS.';

  @override
  String get fieldHelpGestures =>
      'Terrain : glisser déplacer • 2 doigts zoom/tourner • trackpad : scroll zoom, ⇧ tourner, ⌥ largeur, ⇧⌥ longueur';

  @override
  String get compoNotFoundTitle => 'Composition non renseignée';

  @override
  String get compoTypeEmptyTitle => 'Aucune composition';

  @override
  String get matchStatsUnavailableTitle => 'Statistiques indisponibles';

  @override
  String get sensorNotFoundTitle => 'Capteur non trouvé';

  @override
  String get sensorNotFoundMessage =>
      'Aucun capteur n’est associé à ce joueur pour ce match.';

  @override
  String get matchHomeJersey => 'Maillot domicile';

  @override
  String get matchCartTitle => 'Votre panier';

  @override
  String get matchCartOneItem => '1 article - 49,90 €';

  @override
  String get asiSelectFile => 'Veuillez sélectionner un fichier .asi';

  @override
  String get asiEnterDeviceId => 'Veuillez renseigner le deviceId';

  @override
  String get asiCannotReadFile => 'Impossible de lire le fichier sélectionné';

  @override
  String get asiFileMismatch =>
      'Le fichier ne correspond pas au tracker sélectionné';

  @override
  String get asiTrackerUnknown => 'Tracker non reconnu';

  @override
  String asiFilePickError(String details) {
    return 'Erreur lors de la sélection du fichier : $details';
  }

  @override
  String asiConversionError(String details) {
    return 'Erreur pendant la conversion : $details';
  }

  @override
  String get asiAnalysisFailed => 'Analyse impossible';

  @override
  String get playerSynthesisTitle => 'Synthèse joueur';

  @override
  String get playerSynthesisTabTitle => 'Synthèse';

  @override
  String teamsListCount(int count) {
    return '$count équipe(s)';
  }

  @override
  String teamsListCountFiltered(int filtered, int total) {
    return '$filtered / $total';
  }

  @override
  String get teamsListNoResults => 'Aucune équipe trouvée';

  @override
  String get teamsListNoTeams => 'Aucune équipe disponible';

  @override
  String get navHome => 'Accueil';

  @override
  String get myTeams => 'Mes équipes';

  @override
  String get syncTrainingsToSync => 'Entraînements à synchroniser';

  @override
  String get chatSelectConversation => 'Sélectionne une conversation';

  @override
  String get chatStartNewHint =>
      'Appuie sur \"Nouveau\" pour démarrer un chat.';

  @override
  String get chatTryAnotherName => 'Essaie avec un autre nom.';

  @override
  String get chatUsersAppearHere => 'Les autres utilisateurs apparaîtront ici.';

  @override
  String get matchDetailTitle => 'Détail du match';

  @override
  String get matchDetailVenueTitle => 'Lieu du match';

  @override
  String get matchDetailTrackerKitTitle => 'Sélection du kit';

  @override
  String get matchDetailTrackerKitLabel => 'Trackers';

  @override
  String get matchDetailTrackerKitComingSoon => 'À venir';

  @override
  String playerAgeYears(int age) {
    return '$age ans';
  }

  @override
  String get playerAgeUnknown => 'Âge non renseigné';

  @override
  String get dateUndefined => 'Date non définie';

  @override
  String matchDateTimeAt(String date, String time) {
    return '$date à $time';
  }

  @override
  String get entityComposition => 'Composition';

  @override
  String get entityDetails => 'Détails';

  @override
  String get entityHeatmap => 'Heatmap';

  @override
  String get entityPeriods => 'Périodes';

  @override
  String get tabHighlightsShort => 'Temps';

  @override
  String get emptyNoHighlightsMessage =>
      'Les buts, cartons et changements apparaîtront ici.';

  @override
  String get highlightTypeGoal => 'But';

  @override
  String get highlightTypeSubstitution => 'Changement';

  @override
  String get highlightTypeYellowCard => 'Carton jaune';

  @override
  String get highlightTypeRedCard => 'Carton rouge';

  @override
  String get highlightTypeOwnGoal => 'But contre son camp';

  @override
  String get highlightTypePenalty => 'Penalty';

  @override
  String get highlightTypeGeneric => 'Temps fort';

  @override
  String highlightSubstitutionOut(String player) {
    return '$player sort';
  }

  @override
  String highlightSubstitutionIn(String incoming, String outgoing) {
    return '$incoming remplace $outgoing';
  }

  @override
  String get errorNoPlayersTitle => 'Aucun joueur';

  @override
  String get matchTrackerDataAvailable =>
      'Les données tracker sont disponibles.';

  @override
  String get matchTrackerDataPending =>
      'Les données tracker ne sont pas encore importées.';

  @override
  String get errorPlayerNoTrackerMatch =>
      'Ce joueur n’a pas de données tracker pour ce match.';

  @override
  String get trackerSyncTitle => 'Synchronisation des capteurs';

  @override
  String get trackerAvailableSensors => 'Capteurs disponibles';

  @override
  String trackerCount(int count) {
    return '$count tracker(s)';
  }

  @override
  String get trackerAlreadySyncedTitle => 'Synchronisation déjà effectuée';

  @override
  String get trackerAlreadySyncedMessage =>
      'Le capteur a déjà été synchronisé pour cette session.';

  @override
  String get trackerStatusSelected => 'Sélectionné';

  @override
  String get trackerStatusSynced => 'Synchronisé';

  @override
  String get trackerStatusOpen => 'Ouvrir';

  @override
  String get trackerSelectForActions =>
      'Sélectionne un tracker pour afficher les actions de connexion, téléchargement et effacement.';

  @override
  String get trackerSelectedLabel => 'Tracker sélectionné';

  @override
  String get trackerLogsPlaceholder => 'Les logs apparaîtront ici.';

  @override
  String get trackerNoDataOnDevice => 'Aucune donnée sur ce capteur.';

  @override
  String get trackerNoDataOnDeviceTitle =>
      'Capteur connecté — aucune séance à importer';

  @override
  String get trackerNoDataOnDeviceDetails =>
      'Le capteur a confirmé 0 octet de séance (pas une erreur de connexion). Activité non enregistrée sur le pod, ou données déjà effacées. Enregistrez une séance sur l’Inspirit, puis recliquez « Télécharger ».';

  @override
  String get trackerDownloadFailedTitle => 'Échec du téléchargement';

  @override
  String get trackerDownloadBusyHint =>
      'Assurez-vous qu’aucune autre instance de Grinta soit ouverte.';

  @override
  String get trackerDownloadPrepareSession =>
      'Préparation USB avant téléchargement (équivalent Déconnecter puis Connecter)…';

  @override
  String get uploadTrackerLoading => 'Chargement...';

  @override
  String get uploadTrackerDownloadData => 'Télécharger les données';

  @override
  String get syncFieldGeolocationPromptTitle => 'Géolocaliser le terrain ?';

  @override
  String get syncFieldGeolocationPromptMessage =>
      'Les coordonnées GPS du terrain ne sont pas renseignées. Souhaitez-vous les définir avant de télécharger les données tracker ?';

  @override
  String get trackerUsbAuthorizeHint =>
      'Aucun Inspirit autorisé pour ce site. Une fenêtre Chrome va s’ouvrir : cliquez sur « Inspirit_00 » (ou votre modèle), puis le bouton « Connecter » — ne fermez pas la fenêtre.';

  @override
  String get trackerUsbPopupCancelled =>
      'Popup Chrome fermée ou aucun appareil choisi. Branchez le tracker, recliquez « Connecter » et sélectionnez-le dans la liste.';

  @override
  String get trackerUsbPhysicalReconnect =>
      'Session USB expirée (câble débranché ou capteur réinitialisé). Rebranchez le tracker si besoin, puis recliquez « Connecter » — une fenêtre Chrome peut s’ouvrir pour le resélectionner.';

  @override
  String trackerDeviceName(String name) {
    return 'Périphérique : $name';
  }

  @override
  String get asiImportTitle => 'Importer un fichier .asi';

  @override
  String get asiImportSubtitle =>
      'Sélectionne un fichier, vérifie le deviceId, puis lance la conversion.';

  @override
  String get asiFileSelectedLabel => 'Fichier sélectionné';

  @override
  String get asiImportFileHeader => 'Import fichier ASI';

  @override
  String get actionConvertToCsv => 'Convertir en CSV';

  @override
  String get asiConverting => 'Conversion en cours...';

  @override
  String get asiPeriodsOne => '1 période transmise';

  @override
  String asiPeriodsMany(int count) {
    return '$count période(s) transmise(s) - les 2 premières seront utilisées pour les mi-temps';
  }

  @override
  String get statsUnitKm => 'km';

  @override
  String get statsUnitKmh => 'km/h';

  @override
  String get statsUnitCount => 'nb';

  @override
  String get statsUnitSeconds => 'sec';

  @override
  String get statsUnitMps2 => 'm/s²';

  @override
  String get loadingSession => 'Chargement de la session...';

  @override
  String get loadingStats => 'Chargement des statistiques...';

  @override
  String get dashboardMyManagedTeams => 'Mes équipes managées';

  @override
  String get dashboardMatchListTitle => 'Liste des matchs';

  @override
  String periodCustomRange(String start, String end) {
    return 'du $start au $end';
  }

  @override
  String statsPresenceRate(String value) {
    return 'Tx de présence: ($value) %';
  }

  @override
  String get statsDoneSingular => 'réalisé';

  @override
  String get statsDonePlural => 'réalisés';

  @override
  String get statsPlannedSingular => 'planifié';

  @override
  String get statsPlannedPlural => 'planifiés';

  @override
  String get actionDayPrevious => 'Jour précédent';

  @override
  String get actionDayNext => 'Jour suivant';

  @override
  String get actionMonthPrevious => 'Mois précédent';

  @override
  String get actionMonthNext => 'Mois suivant';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionSaving => 'Enregistrement...';

  @override
  String periodLoaded(String range) {
    return 'Période chargée : $range';
  }

  @override
  String get agendaLegend => 'Légende';

  @override
  String agendaOverviewEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matchs',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryTrainings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entraînements',
      one: '1 entraînement',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryPrepas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prépas',
      one: '1 prépa',
    );
    return '$_temp0';
  }

  @override
  String get agendaTrackerStatsTitle => 'Statistiques tracker';

  @override
  String get teamDetailBackToTeams => 'Retour aux équipes';

  @override
  String teamDetailAverageAge(String age) {
    return 'Moyenne d\'âge: $age ans';
  }

  @override
  String get teamDetailConfirmDeleteTitle => 'Confirmer la suppression';

  @override
  String teamDetailConfirmRemoveStaff(String playerName) {
    return 'Confirmez-vous la suppression du staff de $playerName ?';
  }

  @override
  String teamDetailConfirmRemovePlayerTeam(String playerName) {
    return 'Confirmez-vous la suppression de l\'équipe du joueur $playerName ?';
  }

  @override
  String teamDetailPlayerRemoved(String playerName) {
    return '$playerName a été supprimé.';
  }

  @override
  String teamDetailPlayerTeamRemoved(String playerName) {
    return 'L\'équipe du joueur $playerName a été supprimé.';
  }

  @override
  String get teamDetailColumnAge => 'Âge';

  @override
  String get teamDetailColumnPosition => 'Poste';

  @override
  String get teamDetailColumnHeight => 'Taille';

  @override
  String get teamDetailColumnWeight => 'Poids';

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
    return 'Voulez-vous supprimer l\'affectation du tracker « $trackerName » ?';
  }

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleExecutive => 'Dirigeant';

  @override
  String get positionEducator => 'Educateur/Entraineur';

  @override
  String get positionExecutive => 'Dirigeant';

  @override
  String get positionGoalkeeper => 'Gardien de but';

  @override
  String get positionDefender => 'Défenseur';

  @override
  String get positionMidfielder => 'Milieu';

  @override
  String get positionForward => 'Attaquant';

  @override
  String get teamParamsCustomThresholds => 'Seuils personnalisés';

  @override
  String get teamParamsDefaultThresholds => 'Seuils par défaut';

  @override
  String get teamParamsBackToTeam => 'Retour à l\'équipe';

  @override
  String get teamParamsDeleteCustomizationBody =>
      'Les paramètres spécifiques de cette équipe seront supprimés. L\'équipe utilisera alors les paramètres par défaut.';

  @override
  String get teamParamsCustomizationRemoved =>
      'Personnalisation supprimée. Les paramètres par défaut seront utilisés.';

  @override
  String teamParamsZoneMaxGreaterThanMin(String label) {
    return 'La zone \"$label\" doit avoir une borne max supérieure à la borne min.';
  }

  @override
  String get teamParamsOnlyLastZoneEmptyMax =>
      'Seule la dernière zone peut avoir une borne max vide.';

  @override
  String teamParamsZonesOverlap(String zoneA, String zoneB) {
    return 'Les zones \"$zoneA\" et \"$zoneB\" se chevauchent.';
  }

  @override
  String get teamParamsCustomizeZonesHint =>
      'Tu peux personnaliser librement les zones utilisées pour le calcul du temps passé dans chaque zone.';

  @override
  String get teamParamsZonesReadOnly =>
      'Consultation seule : les zones de vitesse ne sont pas modifiables.';

  @override
  String get teamParamsInvalidInteger => 'Valeur entière invalide';

  @override
  String get teamParamsInvalidNumber => 'Valeur numérique invalide';

  @override
  String teamParamsZoneTitle(int index) {
    return 'Zone $index';
  }

  @override
  String get hintRequiredField => 'Champ requis';

  @override
  String get fieldSnackbarGoogleMapsKeyMissing =>
      'Clé Google Maps manquante pour la recherche d\'adresse.';

  @override
  String get fieldMapModeHelp => 'Mode carte : déplace ou zoome la carte';

  @override
  String get fieldSideLeft => 'Côté gauche';

  @override
  String get fieldSideRight => 'Côté droit';

  @override
  String get fieldEstimatedAddress => 'Adresse estimée';

  @override
  String get fieldAddressUnavailable =>
      'Adresse postale indisponible pour cette position.';

  @override
  String get fieldGpsPositionsTitle => 'Positions GPS du terrain';

  @override
  String get fieldAverageLength => 'Longueur moyenne';

  @override
  String get fieldAverageWidth => 'Largeur moyenne';

  @override
  String get trackerParamDefault => 'Param défaut';

  @override
  String trackerParamTeam(String teamId) {
    return 'Param équipe $teamId';
  }

  @override
  String get halfFirst => '1ère mi-temps';

  @override
  String get halfSecond => '2ème mi-temps';

  @override
  String halfNth(int index) {
    return '$indexème mi-temps';
  }

  @override
  String get halfFirstShort => '1ère';

  @override
  String get halfSecondShort => '2ème';

  @override
  String get halfMatchShort => 'Match';

  @override
  String get tabSpeedZonesShort => 'Vitesse';

  @override
  String get fieldZoneAttackLeftShort => 'Att. gauche';

  @override
  String get fieldZoneAttackRightShort => 'Att. droite';

  @override
  String get fieldZoneMidLeftShort => 'Mil. gauche';

  @override
  String get fieldZoneMidRightShort => 'Mil. droite';

  @override
  String get fieldZoneDefenseLeftShort => 'Déf. gauche';

  @override
  String get fieldZoneDefenseRightShort => 'Déf. droite';

  @override
  String get fieldZoneAttackLeft => 'Attaque gauche';

  @override
  String get fieldZoneAttackRight => 'Attaque droite';

  @override
  String get fieldZoneMidLeft => 'Milieu gauche';

  @override
  String get fieldZoneMidRight => 'Milieu droite';

  @override
  String get fieldZoneDefenseLeft => 'Défense gauche';

  @override
  String get fieldZoneDefenseRight => 'Défense droite';

  @override
  String get halfFirstUnavailable => '1ère mi-temps indisponible';

  @override
  String get halfSecondUnavailable => '2ème mi-temps indisponible';

  @override
  String asiHeatmapPointCount(int count, String period) {
    return '$count point(s) - $period';
  }

  @override
  String metricsEvolutionTitle(String metric) {
    return 'Évolution - $metric';
  }

  @override
  String trainingOnDate(String date) {
    return 'Entraînement du $date';
  }
}
