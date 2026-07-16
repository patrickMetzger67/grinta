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
  String get noAccountYet => 'Vous n\'avez pas de compte ?';

  @override
  String get createOneLink => 'Créez-en un';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get passwordRequirements =>
      'Le mot de passe doit contenir au moins 8 caractères, une majuscule, un chiffre et un caractère spécial.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signInLink => 'Se connecter';

  @override
  String get or => 'ou';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithMeta => 'Continuer avec Meta';

  @override
  String get hasATeamCode => 'Je dispose d\'un code équipe';

  @override
  String get hasInvitationCodeQuestion => 'Avez-vous un code d\'invitation ?';

  @override
  String get invitationCode => 'Code d\'invitation';

  @override
  String get invitationCodeHint => 'Saisissez votre code';

  @override
  String get invitationNotFound => 'Code invitation non trouvé';

  @override
  String get invitationNotFoundContinuePrompt =>
      'Code inexistant, souhaitez-vous poursuivre en créant votre profil joueur ?';

  @override
  String get invitationAlreadyUsed =>
      'Ce code d\'invitation a déjà été utilisé';

  @override
  String invitationSentBy(String firstName, String lastName) {
    return 'L\'invitation vous a été envoyée par $firstName $lastName';
  }

  @override
  String get signupWithoutInvitationComingSoon => 'Fonctionnalité à venir';

  @override
  String get emailAlreadyInUse =>
      'Un compte existe déjà avec cette adresse email';

  @override
  String get invitationCodeRequired =>
      'Veuillez saisir et valider un code d\'invitation';

  @override
  String get invitationChoiceRequired =>
      'Veuillez indiquer si vous avez un code d\'invitation';

  @override
  String get memberProfileTitle => 'Votre profil';

  @override
  String get memberFirstName => 'Prénom';

  @override
  String get memberLastName => 'Nom';

  @override
  String get memberEmail => 'E-mail';

  @override
  String get memberEmailOptional => 'E-mail (facultatif)';

  @override
  String get memberPhone => 'Téléphone';

  @override
  String get memberPhoneOptional => 'Téléphone (facultatif)';

  @override
  String get memberEmailInvalid => 'Veuillez saisir une adresse e-mail valide';

  @override
  String get memberPhoneInvalid =>
      'Veuillez saisir un numéro de téléphone valide';

  @override
  String get memberPhoneRequired =>
      'Le numéro de téléphone est requis pour les invitations';

  @override
  String get memberEmailRequired => 'L\'e-mail est requis pour les invitations';

  @override
  String invitationEmailSubject(String appName) {
    return 'Ton coach t\'invite à rejoindre $appName';
  }

  @override
  String invitationEmailIntro(String appName) {
    return 'Ton coach t\'invite à rejoindre $appName';
  }

  @override
  String get invitationEmailCodeLabel => 'Ton code d\'invitation';

  @override
  String get invitationEmailDownloadIos => 'Télécharger sur iPhone';

  @override
  String get invitationEmailDownloadAndroid => 'Télécharger sur Android';

  @override
  String invitationEmailFooter(String appName) {
    return 'Tu as reçu cet e-mail parce qu\'un coach t\'a ajouté sur $appName. Si tu n\'attendais pas ce message, tu peux l\'ignorer.';
  }

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Ton coach t\'invite à rejoindre $appName. Ton code : $code.\niPhone : $appleStoreUrl\nAndroid : $googlePlayUrl';
  }

  @override
  String get memberInvitationEmailFailed =>
      'Membre ajouté, mais l\'envoi de l\'e-mail d\'invitation a échoué.';

  @override
  String get memberAddedToTeamNotificationTitle => 'Mise à jour d\'équipe';

  @override
  String memberAddedToTeamNotificationBody(String teamName) {
    return 'Ton coach t\'a ajouté à $teamName.';
  }

  @override
  String get invitationAccepted => 'Invitation acceptée';

  @override
  String get invitationPending => 'Invitation en attente';

  @override
  String get memberAppAccountLinked => 'Compte application lié';

  @override
  String get resendInvitationTooltip => 'Renvoyer l\'e-mail d\'invitation';

  @override
  String get resendInvitationNoEmailTooltip =>
      'Ajoutez une adresse e-mail pour envoyer une invitation';

  @override
  String get resendInvitationSuccess => 'E-mail d\'invitation envoyé';

  @override
  String get resendInvitationFailed =>
      'Impossible d\'envoyer l\'e-mail d\'invitation';

  @override
  String get memberBirthDate => 'Date de naissance';

  @override
  String get memberBirthDateOptional => 'Date de naissance (facultatif)';

  @override
  String get memberBirthPlace => 'Lieu de naissance';

  @override
  String get memberBirthPlaceOptional => 'Lieu de naissance (facultatif)';

  @override
  String get memberNationality => 'Nationalité';

  @override
  String get memberNationalityHint => 'Sélectionnez une nationalité';

  @override
  String get memberNationalitySearch => 'Rechercher une nationalité';

  @override
  String get memberPositions => 'Postes';

  @override
  String get memberPositionsHint =>
      'Sélectionnez un ou plusieurs postes (facultatif)';

  @override
  String get memberFirstNameRequired => 'Le prénom est obligatoire';

  @override
  String get memberLastNameRequired => 'Le nom est obligatoire';

  @override
  String get memberBirthPlaceRequired => 'Le lieu de naissance est obligatoire';

  @override
  String get memberNationalityRequired => 'La nationalité est obligatoire';

  @override
  String get memberContactRequired =>
      'Renseignez au moins un email ou un numéro de téléphone';

  @override
  String get memberProfileIncomplete => 'Veuillez compléter votre profil';

  @override
  String get memberProfileSubmit => 'Créer mon profil';

  @override
  String get memberProfileUpdateSuccess => 'Profil mis à jour';

  @override
  String memberProfileUpdateError(String error) {
    return 'Impossible de mettre à jour le profil : $error';
  }

  @override
  String get memberProfileChangePhoto => 'Changer la photo';

  @override
  String get memberProfileTakePhoto => 'Prendre une photo';

  @override
  String get memberProfileChooseFromGallery => 'Choisir dans la galerie';

  @override
  String memberProfilePhotoUploadError(String error) {
    return 'Impossible de mettre à jour la photo : $error';
  }

  @override
  String get errorEditProfileUnavailable =>
      'Aucun profil disponible à modifier';

  @override
  String get createTeamPromptQuestion => 'Souhaitez-vous créer une équipe ?';

  @override
  String get createTeamPromptLater => 'Plus tard';

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
  String get actionEditProfile => 'Modifier mon profil';

  @override
  String get settingsMyUnavailabilities => 'Mes indisponibilités';

  @override
  String get myUnavailabilitiesNoPlayer =>
      'Aucun profil joueur lié à ton compte.';

  @override
  String get myUnavailabilitiesNoSeason =>
      'Aucune saison sélectionnée. Choisis une saison dans le menu compte.';

  @override
  String get actionCreateNewProfile => 'Créer un nouveau profil';

  @override
  String get actionLogout => 'Déconnexion';

  @override
  String get actionLogoutConfirmTitle => 'Déconnexion';

  @override
  String get actionLogoutConfirmMessage =>
      'Souhaites-tu vraiment te déconnecter ?';

  @override
  String get actionCreateTeam => 'Créer une équipe';

  @override
  String get teamCreationAttachClubQuestion =>
      'Souhaitez-vous attacher cette équipe à un club ?';

  @override
  String get teamCreationSelectClub => 'Sélectionner un club';

  @override
  String get teamCreationClubRequired => 'Veuillez sélectionner un club';

  @override
  String get teamCreationSelectClubTeams => 'Sélectionner des équipes';

  @override
  String get teamCreationNoClubTeams => 'Aucune équipe engagée';

  @override
  String teamCreationSelectedClubTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count équipes sélectionnées',
      one: '1 équipe sélectionnée',
      zero: 'Aucune équipe sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String teamCreationClubTeamCompetitionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compétitions',
      one: '1 compétition',
    );
    return '$_temp0';
  }

  @override
  String get teamCreationSoccerType => 'Type de football';

  @override
  String get teamCreationNoClubWarningTitle => 'Avertissement';

  @override
  String get teamCreationNoClubWarning =>
      'L\'équipe n\'est pas liée à un club ni à une compétition. Dans ce cas, vous n\'avez pas de récupération automatique du calendrier et des résultats.';

  @override
  String equipeCompetitionsSheetTitle(String teamName) {
    return 'Compétitions — $teamName';
  }

  @override
  String fffCompetitionPhaseLabel(int phase) {
    return 'Phase $phase';
  }

  @override
  String fffCompetitionGroupeLabel(int groupe) {
    return 'Groupe $groupe';
  }

  @override
  String get hintSearchClub => 'Rechercher un club';

  @override
  String get hintSearchClubTeam => 'Rechercher une équipe';

  @override
  String get actionAddPlayer => 'Ajouter un joueur';

  @override
  String get actionCreatePlayer => 'Créer un joueur';

  @override
  String get actionEditPlayer => 'Modifier le joueur';

  @override
  String get actionEditStaff => 'Modifier le staff';

  @override
  String get addPlayerPositionRequired => 'Veuillez sélectionner un poste';

  @override
  String get addPlayerHeightCmOptional => 'Taille (cm, facultatif)';

  @override
  String get addPlayerWeightKgOptional => 'Poids (kg, facultatif)';

  @override
  String get addPlayerHeightInvalid =>
      'Saisissez une taille entre 50 et 250 cm';

  @override
  String get addPlayerWeightInvalid => 'Saisissez un poids entre 20 et 200 kg';

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
  String get navNotifications => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptyMessage =>
      'Vous n\'avez aucune notification non lue.';

  @override
  String get notificationsMarkAsRead => 'Marquer comme lue';

  @override
  String get notificationsMarkAsReadError =>
      'Impossible de marquer la notification comme lue.';

  @override
  String get notificationsConvocationMatchDetails => 'Détails du match';

  @override
  String get notificationsConvocationPresent => 'Je serai présent';

  @override
  String get notificationsConvocationAbsent => 'Pas présent';

  @override
  String get notificationsConvocationAbsentDialogTitle => 'Motif d\'absence';

  @override
  String get notificationsConvocationAbsentMessageHint =>
      'Expliquez pourquoi vous ne serez pas présent';

  @override
  String get notificationsConvocationAbsentConfirm => 'Confirmer';

  @override
  String get notificationsConvocationAbsentMessageRequired =>
      'Veuillez saisir un message.';

  @override
  String get notificationsConvocationActionError =>
      'Impossible de répondre à la convocation.';

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
  String get navSettings => 'Réglages';

  @override
  String get tabCompo => 'Compo';

  @override
  String get tabConvocations => 'Convocations';

  @override
  String get tabConvocationsShort => 'Convo';

  @override
  String get matchConvocationsSaved => 'Convocations enregistrées';

  @override
  String get matchConvocationsUnavailable =>
      'Convocations indisponibles pour ce match';

  @override
  String get matchPlayerUnavailableOnMatchDate =>
      'Indisponible à la date du match';

  @override
  String get matchPlayerCannotConvokeUnavailable =>
      'Ce joueur est indisponible à la date de la rencontre et ne peut pas être convoqué.';

  @override
  String get matchConvocationsStatusPresent => 'Présent confirmé';

  @override
  String get matchConvocationsStatusPending => 'En attente de réponse';

  @override
  String get matchConvocationsSendAction => 'Envoyer les convocations';

  @override
  String get matchConvocationsSendTitle => 'Envoyer les convocations';

  @override
  String matchConvocationsSendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs convoqués',
      one: '1 joueur convoqué',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendMessage => 'Message';

  @override
  String get matchConvocationsSendMessageHint =>
      'Informations complémentaires pour les joueurs';

  @override
  String get matchConvocationsSendMessageRequired => 'Saisis un message';

  @override
  String get matchConvocationsSendTime => 'Heure de convocation';

  @override
  String get matchConvocationsSendAddress => 'Adresse de convocation';

  @override
  String get matchConvocationsSendAddressHint => 'Lieu de rendez-vous';

  @override
  String get matchConvocationsSendAddressRequired => 'Saisis une adresse';

  @override
  String get matchConvocationsSendSubmit => 'Envoyer';

  @override
  String matchConvocationsSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convocations envoyées',
      one: '1 convocation envoyée',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoAccount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs sans compte lié',
      one: '1 joueur sans compte lié',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs sans notification push',
      one: '1 joueur sans notification push',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendNoRecipients =>
      'Aucun joueur convoqué n\'a de compte Grinta lié.';

  @override
  String matchConvocationsSendError(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get matchConvocationsSendErrorAuth =>
      'Connecte-toi pour envoyer les convocations.';

  @override
  String matchConvocationsSendDateTimeValue(String date, String time) {
    return '$date à $time';
  }

  @override
  String matchConvocationsSendMatchLine(String opponent) {
    return 'Match : $opponent';
  }

  @override
  String matchConvocationsSendTimeLine(String time) {
    return 'Heure : $time';
  }

  @override
  String matchConvocationsSendAddressLine(String address) {
    return 'Adresse : $address';
  }

  @override
  String matchConvocationNotificationTitle(String opponent) {
    return 'Convocation · $opponent';
  }

  @override
  String matchConvocationFeedbackNotificationTitle(String opponent) {
    return 'Réponse convocation · $opponent';
  }

  @override
  String matchConvocationNotificationBody(String opponent, String time) {
    return '$opponent · RDV $time';
  }

  @override
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message) {
    return '$opponent · RDV $time · $message';
  }

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
  String get matchTacticalSchemaJerseyNumber => 'Numéro de maillot';

  @override
  String get matchTacticalSchemaPlayerAssignment => 'Affectation du joueur';

  @override
  String get matchTacticalSchemaJerseyNumberRequired =>
      'Indiquez un numéro de maillot (1 à 99).';

  @override
  String get matchTacticalSchemaNoJerseyNumberAvailable =>
      'Aucun numéro de maillot disponible (tous les numéros de 1 à 99 sont déjà attribués).';

  @override
  String get matchTacticalSchemaRemoveFromCompo => 'Retirer de la compo ?';

  @override
  String get matchTacticalSchemaRemoveFromCompoMessage =>
      'Ce joueur sera retiré du schéma tactique (poste et remplaçants).';

  @override
  String get matchTacticalSchemaRemoveFromCompoConfirm => 'Retirer';

  @override
  String get matchTacticalSchemaSensorRequired =>
      'Sélectionnez un capteur disponible.';

  @override
  String get matchTacticalSchemaNoPlayerAvailable =>
      'Aucun joueur disponible — tous les joueurs éligibles sont déjà sur la compo.';

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
  String get hintSearchMember => 'Rechercher un membre';

  @override
  String get memberSearchPrompt =>
      'Saisissez un prénom ou un nom pour rechercher';

  @override
  String get memberAlreadyOnTeamRoster =>
      'Ce membre fait déjà partie de l\'effectif';

  @override
  String get memberAlreadyPlayer => 'Ce membre fait déjà partie des joueurs';

  @override
  String get memberAlreadyStaff => 'Ce membre fait déjà partie du staff';

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
      zero: '0 joueurs',
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
      zero: '0 staff',
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
  String get asiFileEmptyOrNoData =>
      'Le fichier .asi est vide ou ne contient aucune donnée exploitable.';

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
  String get teamStreamChannelSynced => 'Groupe Stream actif';

  @override
  String get teamStreamChannelPending => 'Groupe Stream non synchronisé';

  @override
  String get teamStreamChannelCreateTitle => 'Créer le groupe Stream ?';

  @override
  String teamStreamChannelCreateMessage(String teamName) {
    return 'Créer le groupe Stream pour l\'équipe $teamName ? Les joueurs et le staff seront ajoutés automatiquement.';
  }

  @override
  String get teamStreamChannelCreateConfirm => 'Créer';

  @override
  String get teamStreamChannelCreateLoading => 'Création du groupe Stream…';

  @override
  String teamStreamChannelCreateSuccess(String teamName) {
    return 'Groupe Stream créé pour $teamName.';
  }

  @override
  String teamStreamChannelCreateError(String details) {
    return 'Impossible de créer le groupe Stream : $details';
  }

  @override
  String get teamStreamChannelCreateNotManager =>
      'Seuls les managers peuvent créer le groupe Stream.';

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
  String get chatChannelMembersTitle => 'Membres';

  @override
  String get chatMessageReadByTitle => 'Lu par';

  @override
  String get chatMessageNotReadYet => 'Pas encore lu';

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
  String get matchDetailTrackerKitWithTracker => 'Avec tracker';

  @override
  String get matchDetailTrackerKitWithoutTracker => 'Sans tracker';

  @override
  String get matchDetailTrackerKitSelectLabel => 'Kit';

  @override
  String get matchDetailTrackerKitNoOwners =>
      'Aucun kit configuré pour cette équipe.';

  @override
  String get matchDetailTrackerKitSignInRequired =>
      'Connectez-vous pour sélectionner un kit.';

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
  String get matchHighlightsSourceFmi => 'Temps forts de la FMI';

  @override
  String get matchHighlightsSourceGrinta => 'Temps forts Grinta';

  @override
  String get matchHighlightsGrintaPlaceholderMessage =>
      'À détailler ensemble après.';

  @override
  String get matchGrintaHighlightsAddAction => 'Ajouter un temps fort';

  @override
  String get matchGrintaHighlightsPickTypeTitle =>
      'Choisir le type de temps fort';

  @override
  String get matchGrintaHighlightsPickTimeEventTitle => 'Choisir l\'événement';

  @override
  String get matchGrintaHighlightsEmptyMessage =>
      'Commencez par le coup d\'envoi avec le bouton +.';

  @override
  String get matchGrintaHighlightsDetailsComingSoon =>
      'Le détail de ce temps fort arrive bientôt.';

  @override
  String get matchGrintaHighlightsActionTimeEvent => 'Événement de temps';

  @override
  String get matchGrintaHighlightsAllTimeEventsRecorded =>
      'Tous les événements de temps ont déjà été enregistrés pour ce match.';

  @override
  String get matchGrintaHighlightDeleteConfirmTitle =>
      'Supprimer ce temps fort ?';

  @override
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel) {
    return 'Voulez-vous vraiment supprimer « $highlightLabel » ? Cette action est définitive.';
  }

  @override
  String get matchGrintaHighlightDeleted => 'Temps fort supprimé';

  @override
  String get matchGoalAddTitle => 'Enregistrer un but';

  @override
  String get matchGoalPickTeamTitle => 'Quelle équipe a marqué ?';

  @override
  String get matchGoalPickScorerTitle => 'Buteur';

  @override
  String get matchGoalPickAssisterTitle => 'Passeur décisif (optionnel)';

  @override
  String get matchGoalNoAssister => 'Sans passeur';

  @override
  String get matchGoalOpponentJerseyTitle => 'Numéro du buteur (optionnel)';

  @override
  String get matchGoalOpponentJerseyHint => 'ex. 10';

  @override
  String get matchGoalScorerRequired => 'Sélectionnez un buteur.';

  @override
  String get matchGoalInvalidJerseyNumber =>
      'Saisissez un numéro de maillot valide.';

  @override
  String get matchGoalMinuteTitle => 'Minute';

  @override
  String get matchGoalMinuteHint => 'ex. 67';

  @override
  String get matchGoalInvalidMinute => 'Saisissez une minute d\'au moins 1.';

  @override
  String get matchGoalSelectScorer => 'Choisir un buteur';

  @override
  String get matchGoalSelectAssister => 'Choisir un passeur';

  @override
  String get matchCardYellowAddTitle => 'Enregistrer un carton jaune';

  @override
  String get matchCardRedAddTitle => 'Enregistrer un carton rouge';

  @override
  String get matchCardPickTeamTitle => 'Quelle équipe reçoit le carton ?';

  @override
  String get matchCardPickPlayerTitle => 'Joueur';

  @override
  String get matchCardSelectPlayer => 'Choisir un joueur';

  @override
  String get matchCardPlayerRequired => 'Sélectionnez un joueur.';

  @override
  String get matchCardOpponentJerseyTitle => 'Numéro du joueur (optionnel)';

  @override
  String get matchCardOpponentJerseyHint => 'ex. 10';

  @override
  String get matchSubstitutionAddTitle => 'Enregistrer un changement';

  @override
  String get matchSubstitutionPickTeamTitle =>
      'Quelle équipe effectue le changement ?';

  @override
  String get matchSubstitutionPickOutgoingTitle => 'Joueur sortant';

  @override
  String get matchSubstitutionPickIncomingTitle => 'Joueur entrant';

  @override
  String get matchSubstitutionSelectOutgoing => 'Choisir le joueur sortant';

  @override
  String get matchSubstitutionSelectIncoming => 'Choisir le joueur entrant';

  @override
  String get matchSubstitutionOutgoingRequired =>
      'Sélectionnez le joueur sortant.';

  @override
  String get matchSubstitutionIncomingRequired =>
      'Sélectionnez le joueur entrant.';

  @override
  String get matchSubstitutionSamePlayerError =>
      'Les deux joueurs doivent être différents.';

  @override
  String get matchSubstitutionOpponentOutgoingJerseyTitle =>
      'Numéro du joueur sortant (optionnel)';

  @override
  String get matchSubstitutionOpponentIncomingJerseyTitle =>
      'Numéro du joueur entrant (optionnel)';

  @override
  String highlightGoalScored(String scorer) {
    return 'But — $scorer';
  }

  @override
  String get highlightTimeHalfTime => 'Mi-temps';

  @override
  String get highlightTimeSecondHalf => 'Deuxième mi-temps';

  @override
  String get highlightTimeStartExtraTime => 'Prolongations';

  @override
  String get highlightTypeGoal => 'But';

  @override
  String get highlightTypeSubstitution => 'Changement';

  @override
  String get highlightTypeYellowCard => 'Carton jaune';

  @override
  String get highlightTypeRedCard => 'Carton rouge';

  @override
  String highlightYellowCardShown(String player) {
    return 'Carton jaune — $player';
  }

  @override
  String highlightRedCardShown(String player) {
    return 'Carton rouge — $player';
  }

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
  String get agendaAddEventTitle => 'Créer';

  @override
  String get agendaAddEventMatch => 'Une rencontre / match';

  @override
  String get agendaAddEventTraining => 'Une session d\'entraînement';

  @override
  String get agendaAddEventPersonalSport => 'Une activité sportive personnelle';

  @override
  String get agendaAddEventPersonalSportHint => 'Running, préparation, …';

  @override
  String get agendaAddEventNonSport => 'Un évènement / activité non sportive';

  @override
  String get agendaAllDayLabel => 'Journée entière';

  @override
  String agendaEventSummaryNonSport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 activité',
      other: '$count activités',
    );
    return '$_temp0';
  }

  @override
  String get createNonSportEventTitle => 'Nouvel évènement / activité';

  @override
  String get createNonSportEventTitleField => 'Titre';

  @override
  String get createNonSportEventTitleRequired => 'Indiquez un titre';

  @override
  String get createNonSportEventDate => 'Date';

  @override
  String get createNonSportEventTime => 'Heure';

  @override
  String get createNonSportEventAllDay => 'Journée entière';

  @override
  String get createNonSportEventStartDate => 'Date de début';

  @override
  String get createNonSportEventStartTime => 'Heure de début';

  @override
  String get createNonSportEventEndDate => 'Date de fin';

  @override
  String get createNonSportEventEndTime => 'Heure de fin';

  @override
  String get createNonSportEventInvalidRange => 'La fin doit être après le début.';

  @override
  String get editNonSportEventTitle => 'Modifier l\'évènement';

  @override
  String get editNonSportEventSubmit => 'Enregistrer';

  @override
  String get editNonSportEventSaved => 'Évènement mis à jour';

  @override
  String get editNonSportEventError => 'Impossible de modifier l\'évènement. Réessayez.';

  @override
  String get deleteNonSportEventConfirmTitle => 'Supprimer l\'évènement ?';

  @override
  String deleteNonSportEventConfirmMessage(String title) {
    return '« $title » sera définitivement supprimé, ainsi que les notifications associées.';
  }

  @override
  String get deleteNonSportEventDeleted => 'Évènement supprimé';

  @override
  String get deleteNonSportEventError => 'Impossible de supprimer l\'évènement. Réessayez.';


  @override
  String get createNonSportEventLocation => 'Lieu';

  @override
  String get createNonSportEventLocationHint => 'Adresse ou lieu de rendez-vous';

  @override
  String get createNonSportEventInviteTeams => 'Inviter une ou plusieurs équipes';

  @override
  String get createNonSportEventSelectMembers => 'Sélectionner les membres';

  @override
  String createNonSportEventSelectedMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 membre sélectionné',
      other: '$count membres sélectionnés',
    );
    return '$_temp0';
  }

  @override
  String get createNonSportEventNoTeamMembers => 'Aucun membre dans cette équipe.';

  @override
  String get createNonSportEventInviteOthers => 'Inviter d\'autres profils';

  @override
  String get createNonSportEventAddProfile => 'Ajouter un profil';

  @override
  String get createNonSportEventInvitees => 'Invités';

  @override
  String get createNonSportEventNoInvitees => 'Aucun invité pour le moment.';

  @override
  String get createNonSportEventNoTeams => 'Aucune équipe disponible pour cette saison.';

  @override
  String get createNonSportEventSubmit => 'Créer l\'évènement';

  @override
  String get createNonSportEventSaved => 'Évènement créé';

  @override
  String get createNonSportEventError => 'Impossible de créer l\'évènement. Réessayez.';

  @override
  String get createNonSportEventInviteStatusSent => 'Notification envoyée';

  @override
  String get createNonSportEventInviteStatusNoAccount => 'Pas de compte utilisateur lié';

  @override
  String get createNonSportEventInviteStatusPending => 'En attente';

  @override
  String get createNonSportEventInviteStatusError => 'Échec de notification';

  @override
  String get createNonSportEventNotificationTitle => 'Nouvel évènement';

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
  String get teamDetailColumnApp => 'App';

  @override
  String get teamDetailPlayerDetailsTitle => 'Détails du joueur';

  @override
  String get teamDetailGrantManager => 'Accorder les droits manager';

  @override
  String get teamDetailRevokeManager => 'Retirer les droits manager';

  @override
  String get teamDetailRemoveFromTeam => 'Retirer';

  @override
  String get teamDetailTrackerOwnersTitle => 'Trackers GPS';

  @override
  String get teamDetailTrackerOwnersEmpty =>
      'Aucun kit tracker disponible pour votre compte.';

  @override
  String teamDetailTrackerOwnerType(String type) {
    return 'Type : $type';
  }

  @override
  String get teamDetailTrackerOwnersSaved => 'Kits tracker mis à jour.';

  @override
  String get teamDetailTrackerCoachProRequiredTitle => 'Trackers GPS';

  @override
  String get teamDetailTrackerCoachProRequiredMessage =>
      'L\'association de kits tracker GPS à une équipe nécessite un abonnement Coach Pro.';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleExecutive => 'Dirigeant';

  @override
  String get grintaStaffRoleEducator => 'Entraîneur / Éducateur';

  @override
  String get grintaStaffRoleMedical => 'Médical';

  @override
  String get grintaStaffRoleExecutive => 'Dirigeant';

  @override
  String get addStaffRoleLabel => 'Fonction';

  @override
  String get addStaffRoleHint => 'Choisir une fonction';

  @override
  String get addStaffRoleRequired => 'Veuillez choisir une fonction';

  @override
  String get positionEducator => 'Educateur/Entraineur';

  @override
  String get positionExecutive => 'Dirigeant';

  @override
  String get positionGoalkeeper => 'Gardien';

  @override
  String get positionCenterBack => 'Défenseur central';

  @override
  String get positionCenterBackLeft => 'Défenseur central gauche';

  @override
  String get positionCenterBackRight => 'Défenseur central droit';

  @override
  String get positionLeftDefender => 'Défenseur gauche';

  @override
  String get positionRightDefender => 'Défenseur droit';

  @override
  String get positionLeftBack => 'Latéral gauche';

  @override
  String get positionRightBack => 'Latéral droit';

  @override
  String get positionLeftPiston => 'Piston gauche';

  @override
  String get positionRightPiston => 'Piston droit';

  @override
  String get positionDefensiveMidfielder => 'Milieu défensif';

  @override
  String get positionCentralMidfielder => 'Milieu central';

  @override
  String get positionBoxToBoxMidfielder => 'Milieu relayeur';

  @override
  String get positionLeftMidfielder => 'Milieu gauche';

  @override
  String get positionRightMidfielder => 'Milieu droit';

  @override
  String get positionAttackingMidfielder => 'Milieu offensif';

  @override
  String get positionPlaymaker => 'Meneur de jeu';

  @override
  String get positionLeftWinger => 'Ailier gauche';

  @override
  String get positionRightWinger => 'Ailier droit';

  @override
  String get positionSecondStriker => 'Second attaquant';

  @override
  String get positionCenterForward => 'Avant-centre';

  @override
  String get positionStriker => 'Buteur';

  @override
  String get positionAttacker => 'Attaquant';

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

  @override
  String get subscriptionPaywallTitle => 'Passez à Grinta Premium';

  @override
  String get subscriptionPaywallSubtitle =>
      'Débloquez toutes les fonctionnalités pour le suivi de vos équipes et de vos joueurs';

  @override
  String get subscriptionPaywallLater => 'Plus tard';

  @override
  String get subscriptionOfferingCoach => 'Entraîneur';

  @override
  String get subscriptionOfferingPlayer => 'Joueur';

  @override
  String get subscriptionTierCoachBasic => 'Coach Basic';

  @override
  String get subscriptionTierCoachBasicDesc =>
      'Gestion d\'équipe essentielle : agenda, effectif et statistiques de base.';

  @override
  String get subscriptionTierCoachElite => 'Coach Elite';

  @override
  String get subscriptionTierCoachEliteDesc =>
      'Analyses avancées, compositions tactiques et outils coach complets.';

  @override
  String get subscriptionTierCoachPro => 'Coach Pro';

  @override
  String get subscriptionTierCoachProDesc =>
      'Tout Elite, plus tracker GPS, heatmaps et exports pro.';

  @override
  String get subscriptionTierPlayer => 'Joueur';

  @override
  String get subscriptionTierPlayerDesc =>
      'Suivez vos performances, stats personnelles et progression.';

  @override
  String get subscriptionPerMonth => '/mois';

  @override
  String get subscriptionPerYear => '/an';

  @override
  String get subscriptionBillingMonthly => 'Mensuel';

  @override
  String get subscriptionBillingYearly => 'Annuel';

  @override
  String get subscriptionAnnualSavings => '2 mois offerts';

  @override
  String get subscriptionSubscribe => 'S\'abonner';

  @override
  String get subscriptionTierActive => 'Abonnement actif';

  @override
  String get subscriptionRestorePurchases => 'Restaurer les achats';

  @override
  String get subscriptionAutoRenewLegal =>
      'L\'abonnement se renouvelle automatiquement. Vous pouvez l\'annuler à tout moment dans les réglages de votre compte App Store ou Google Play.';

  @override
  String get subscriptionStoreUnavailable =>
      'Les achats intégrés ne sont pas disponibles sur cette plateforme.';

  @override
  String get subscriptionAlreadyActive => 'Vous avez déjà un abonnement actif.';

  @override
  String get subscriptionProductNotFound =>
      'Produit introuvable. Vérifiez la configuration RevenueCat.';

  @override
  String get subscriptionOfferingsUnavailable =>
      'Les offres d\'abonnement n\'ont pas pu être chargées. Vérifiez votre connexion et l\'offering web RevenueCat, puis réessayez.';

  @override
  String get subscriptionPurchaseFailed => 'L\'achat a échoué. Réessayez.';

  @override
  String get subscriptionRestoreNone => 'Aucun achat à restaurer.';

  @override
  String get subscriptionRestoreFailed => 'La restauration a échoué.';

  @override
  String get subscriptionPromptTitle => 'Passez à Premium';

  @override
  String get subscriptionPromptMessage =>
      'Accédez à toutes les fonctionnalités Grinta avec un abonnement adapté à votre profil.';

  @override
  String get subscriptionPromptAction => 'Voir les offres';

  @override
  String get subscriptionMenu => 'Abonnement';

  @override
  String get subscriptionDetailsTitle => 'Abonnement';

  @override
  String get subscriptionTier => 'Formule';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get subscriptionNone => 'Aucun abonnement actif';

  @override
  String subscriptionTrialEnds(String date) {
    return 'Fin de l\'essai le $date';
  }

  @override
  String get subscriptionPeriodLabel => 'Période';

  @override
  String get subscriptionRenewalLabel => 'Renouvellement';

  @override
  String get subscriptionBillingPeriodMonthly => 'Mensuel';

  @override
  String get subscriptionBillingPeriodYearly => 'Annuel';

  @override
  String get subscriptionStatusActive => 'Actif';

  @override
  String get subscriptionChangePlan => 'Changer de formule';

  @override
  String get subscriptionChangePlanTitle => 'Modifier votre abonnement';

  @override
  String get subscriptionChangePlanSubtitle =>
      'Passez de Joueur à Coach, changez de formule ou modifiez la période de facturation.';

  @override
  String get subscriptionChangePlanConfirm => 'Confirmer le changement';

  @override
  String get subscriptionCurrentPlan => 'Formule actuelle';

  @override
  String get subscriptionPlanChanged => 'Votre abonnement a été mis à jour.';

  @override
  String subscriptionLimitMaxTeamsReached(int max) {
    return 'Vous avez atteint le nombre maximum d\'équipes ($max) pour votre abonnement.';
  }

  @override
  String subscriptionLimitMaxPlayersReached(int max) {
    return 'Vous avez atteint le nombre maximum de joueurs ($max) pour cette équipe.';
  }

  @override
  String get subscriptionLimitPlayerTierOnlySelf =>
      'Votre abonnement Joueur ne permet d\'ajouter que votre propre profil à une équipe.';

  @override
  String subscriptionLimitMaxProfilesReached(int max) {
    return 'Vous avez atteint le nombre maximum de profils ($max) pour votre abonnement.';
  }

  @override
  String get subscriptionLimitProfileUpgradeTitle => 'Profils supplémentaires';

  @override
  String get subscriptionLimitProfileUpgradeMessage =>
      'Passez à un abonnement payant pour créer des profils supplémentaires.';

  @override
  String get subscriptionLimitProfileCoachBasicTitle =>
      'Profils supplémentaires';

  @override
  String get subscriptionLimitProfileCoachBasicMessage =>
      'Passez à la formule Elite ou Pro pour créer jusqu\'à 3 profils.';

  @override
  String get subscriptionLimitProfilePremiumBadge => 'Premium';

  @override
  String get subscriptionLimitTeamUpgradeTitle => 'Équipes supplémentaires';

  @override
  String get subscriptionLimitTeamUpgradeMessage =>
      'Passez à l\'abonnement Joueur pour créer plus d\'équipes et gérer votre effectif.';

  @override
  String get subscriptionLimitTeamCoachBasicTitle => 'Équipes supplémentaires';

  @override
  String get subscriptionLimitTeamCoachBasicMessage =>
      'Passez à la formule Elite ou Pro pour créer plus d\'équipes.';

  @override
  String get subscriptionLimitTeamDetailBlockedTitle => 'Gestion d\'équipe';

  @override
  String get subscriptionLimitTeamDetailBlockedMessage =>
      'Passez à l\'abonnement Joueur pour accéder aux détails de l\'équipe et gérer votre effectif.';

  @override
  String get subscriptionLimitTeamCreatedFreePlayer =>
      'Votre équipe a été créée. Passez à l\'abonnement payant pour accéder aux détails.';

  @override
  String get trialStatusTitle => 'Essai gratuit';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String get shopTitle => 'Boutique Grinta';

  @override
  String get shopPromoTitle => 'Offre boutique';

  @override
  String get shopPromoCta => 'Voir l\'offre';

  @override
  String get shopBrowseAll => 'Voir la boutique';

  @override
  String get shopLoadError => 'Impossible de charger la boutique.';

  @override
  String get shopRetry => 'Réessayer';

  @override
  String get legalPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get legalTermsOfService => 'Conditions d\'utilisation';

  @override
  String get actionDeleteAccount => 'Supprimer mon compte';

  @override
  String get actionDeleteAccountConfirmTitle => 'Supprimer le compte ?';

  @override
  String get actionDeleteAccountConfirmMessage =>
      'Cette action est définitive. Votre compte, votre profil membre et vos données associées seront supprimés.';

  @override
  String errorDeleteAccount(String details) {
    return 'Impossible de supprimer le compte : $details';
  }

  @override
  String get errorDeleteAccountRequiresRecentLogin =>
      'Pour des raisons de sécurité, reconnectez-vous puis réessayez.';

  @override
  String get actionDeleteTeam => 'Supprimer l\'équipe';

  @override
  String get teamDeleteConfirmTitle => 'Supprimer l\'équipe ?';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return 'Voulez-vous vraiment supprimer « $teamName » ? Cette action est définitive. Toutes les données liées à l\'équipe (membres, matchs, statistiques, etc.) seront supprimées.';
  }

  @override
  String teamDeleteSuccess(String teamName) {
    return 'L\'équipe « $teamName » a été supprimée.';
  }

  @override
  String get teamEditNameTitle => 'Modifier le nom de l\'équipe';

  @override
  String get teamEditNameSuccess => 'Nom de l\'équipe mis à jour.';

  @override
  String get calendarSyncToggleLabel => 'Sync. calendrier';

  @override
  String get calendarSyncToggleSubtitle =>
      'Mise à jour auto à l\'ouverture de l\'agenda (max 1×/15 min)';

  @override
  String get calendarSyncWebSubtitle =>
      'Télécharge un fichier ICS à importer dans ton calendrier';

  @override
  String get calendarSyncWebRedownloadHint =>
      'Appuie pour télécharger à nouveau le fichier calendrier';

  @override
  String get calendarSyncWebDownloaded =>
      'Fichier calendrier téléchargé. Importe-le dans ton application de calendrier.';

  @override
  String get calendarSyncPermissionDenied =>
      'L\'accès au calendrier a été refusé. Activez-le dans les réglages de l\'appareil.';

  @override
  String get calendarSyncCalendarCreationFailed =>
      'Impossible de créer le calendrier Grinta sur cet appareil.';

  @override
  String get calendarSyncEnableFailed =>
      'La synchronisation du calendrier n\'a pas pu être activée. Réessayez.';

  @override
  String get calendarSyncForceNow => 'Synchroniser maintenant';

  @override
  String get calendarSyncForceSuccess => 'Calendrier synchronisé.';

  @override
  String get calendarSyncForceFailed =>
      'La synchronisation a échoué. Réessayez.';

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
  String get createTrainingTitle => 'Nouvelle session d\'entraînement';

  @override
  String get createTrainingTeam => 'Équipe';

  @override
  String get createTrainingTeamRequired => 'Sélectionnez une équipe';

  @override
  String get createTrainingDate => 'Date';

  @override
  String get createTrainingTime => 'Heure';

  @override
  String get createTrainingDuration => 'Durée';

  @override
  String createTrainingDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createTrainingRecurrent => 'Récurrent';

  @override
  String get createTrainingRecurrentDays => 'Jour(s) de la semaine';

  @override
  String get createTrainingRecurrentDaysRequired =>
      'Sélectionnez au moins un jour';

  @override
  String get createTrainingRecurrentFrom => 'De';

  @override
  String get createTrainingRecurrentTo => 'À';

  @override
  String get createTrainingRecurrentInvalidRange =>
      'La date de fin ne peut pas être antérieure à la date de début';

  @override
  String get createTrainingWithTracker => 'Avec tracker GPS';

  @override
  String get createTrainingSelectOwner => 'Kit tracker (propriétaire)';

  @override
  String get createTrainingOwnerRequired =>
      'Sélectionnez un propriétaire tracker';

  @override
  String get createTrainingNoOwners =>
      'Aucun kit tracker n\'est assigné à cette équipe.';

  @override
  String get createTrainingNoManagedTeams =>
      'Vous ne gérez aucune équipe pour cette saison.';

  @override
  String createTrainingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entraînements créés',
      one: '1 entraînement créé',
    );
    return '$_temp0';
  }

  @override
  String get createTrainingError =>
      'Impossible de créer l\'entraînement. Réessayez.';

  @override
  String get createTrainingSubmit => 'Créer l\'entraînement';

  @override
  String get createTrainingRecurrentConfirmTitle => 'Entraînement récurrent';

  @override
  String get createTrainingRecurrentConfirmMessage =>
      'Souhaitez-vous créer les récurrences ?';

  @override
  String get editTrainingTitle => 'Modifier l\'entraînement';

  @override
  String get editTrainingSubmit => 'Enregistrer';

  @override
  String get editTrainingSaved => 'Entraînement modifié';

  @override
  String get editTrainingError =>
      'Impossible de modifier l\'entraînement. Réessayez.';

  @override
  String get trainingDeleteConfirmTitle => 'Supprimer l\'entraînement ?';

  @override
  String get trainingDeleteConfirmMessage =>
      'Voulez-vous vraiment supprimer cet entraînement ? Cette action est définitive.';

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
  String get trainingDeleted => 'Entraînement supprimé';

  @override
  String get trainingDeleteError =>
      'Impossible de supprimer l\'entraînement. Réessayez.';

  @override
  String get finishTrainingTitle => 'Terminer l\'entraînement';

  @override
  String get trainingFinishConfirmTitle => 'Terminer l\'entraînement ?';

  @override
  String get trainingFinishConfirmMessage =>
      'Les joueurs indisponibles encore marqués présents seront passés absents. Voulez-vous terminer cet entraînement ?';

  @override
  String get trainingFinished => 'Entraînement terminé';

  @override
  String get trainingFinishError =>
      'Impossible de terminer l\'entraînement. Réessayez.';

  @override
  String get trainingIntenseFinishTitle => 'Récupération des données capteurs';

  @override
  String get trainingIntenseFinishMessage =>
      'Récupération des données des joueurs présents avec capteur assigné. Ne fermez pas cette fenêtre.';

  @override
  String get trainingIntenseFinishSyncing => 'Synchronisation en cours…';

  @override
  String get trainingIntenseFinishStagePending => 'En attente';

  @override
  String get trainingIntenseFinishStageFetching =>
      'Récupération des données brutes…';

  @override
  String get trainingIntenseFinishStageConverting => 'Conversion des données…';

  @override
  String get trainingIntenseFinishStageAnalyzing => 'Analyse en cours…';

  @override
  String get trainingIntenseFinishStageDone => 'Terminé';

  @override
  String get trainingIntenseFinishStageError => 'Erreur';

  @override
  String get trainingIntenseFinishNoTrackers =>
      'Aucun joueur présent n\'a de capteur assigné. Vous pouvez terminer l\'entraînement sans récupération.';

  @override
  String get trainingIntenseFinishPartialError =>
      'Certaines récupérations ont échoué. Corrigez le problème puis réessayez.';

  @override
  String get intenseLiveTitle => 'Live';

  @override
  String get intenseLiveOpenTooltip => 'Voir le live capteurs';

  @override
  String get intenseLiveSelectPlayer => 'Sélectionner un joueur';

  @override
  String get intenseLiveNoPlayers =>
      'Aucun joueur présent avec capteur assigné';

  @override
  String get intenseLiveRefresh => 'Actualiser';

  @override
  String intenseLiveLastUpdate(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String get tabLive => 'Live';

  @override
  String get tabLiveShort => 'Live';

  @override
  String get createMatchTitle => 'Nouvelle rencontre';

  @override
  String get createMatchTeam => 'Équipe';

  @override
  String get createMatchTeamRequired => 'Sélectionnez une équipe';

  @override
  String get createMatchHome => 'Rencontre à domicile';

  @override
  String get createMatchFriendly => 'Match amical';

  @override
  String get createMatchDate => 'Date';

  @override
  String get createMatchTime => 'Heure';

  @override
  String get createMatchDuration => 'Durée';

  @override
  String createMatchDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createMatchOpponent => 'Adversaire';

  @override
  String get createMatchSelectOpponentClub => 'Rechercher un club';

  @override
  String get createMatchClubNotFound => 'Club non trouvé';

  @override
  String get createMatchOpponentNameManual => 'Nom de l\'adversaire';

  @override
  String get createMatchOpponentRequired => 'Indiquez l\'adversaire';

  @override
  String get createMatchVenue => 'Lieu / adresse du terrain';

  @override
  String get createMatchSurface => 'Surface de jeu';

  @override
  String get createMatchSurfaceSynthetic => 'Synthétique';

  @override
  String get createMatchSurfaceNatural => 'Pelouse naturelle';

  @override
  String get createMatchWithTracker => 'Avec tracker GPS';

  @override
  String get createMatchSelectOwner => 'Kit tracker (propriétaire)';

  @override
  String get createMatchOwnerRequired => 'Sélectionnez un propriétaire tracker';

  @override
  String get createMatchNoOwners =>
      'Aucun kit tracker n\'est assigné à cette équipe.';

  @override
  String get createMatchNoManagedTeams =>
      'Vous ne gérez aucune équipe pour cette saison.';

  @override
  String get createMatchSaved => 'Rencontre créée';

  @override
  String get createMatchError => 'Impossible de créer la rencontre. Réessayez.';

  @override
  String get createMatchSubmit => 'Créer la rencontre';

  @override
  String get editMatchTitle => 'Modifier la rencontre';

  @override
  String get editMatchSubmit => 'Enregistrer';

  @override
  String get editMatchSaved => 'Rencontre modifiée';

  @override
  String get editMatchError =>
      'Impossible de modifier la rencontre. Réessayez.';

  @override
  String get matchDeleteConfirmTitle => 'Supprimer la rencontre ?';

  @override
  String get matchDeleteConfirmMessage =>
      'Voulez-vous vraiment supprimer cette rencontre ? Cette action est définitive.';

  @override
  String get matchRemoveFromTeamConfirmTitle =>
      'Retirer la rencontre du calendrier ?';

  @override
  String get matchRemoveFromTeamConfirmMessage =>
      'Cette action retire la rencontre du calendrier de votre équipe. La rencontre restera visible pour les autres équipes.';

  @override
  String get matchDeleted => 'Rencontre supprimée';

  @override
  String get matchRemovedFromTeam =>
      'Rencontre retirée du calendrier de votre équipe';

  @override
  String get matchDeleteError =>
      'Impossible de supprimer la rencontre. Réessayez.';

  @override
  String get teamDetailManageUnavailabilities => 'Gérer les indisponibilités';

  @override
  String get manageUnavailabilitiesTitle => 'Indisponibilités';

  @override
  String get manageUnavailabilitiesEmpty =>
      'Aucune indisponibilité pour cette saison.';

  @override
  String get manageUnavailabilitiesAdd => 'Ajouter une indisponibilité';

  @override
  String get manageUnavailabilitiesEditTitle => 'Modifier l\'indisponibilité';

  @override
  String get manageUnavailabilitiesFromDate => 'Du';

  @override
  String get manageUnavailabilitiesToDate => 'Au';

  @override
  String get manageUnavailabilitiesType => 'Type';

  @override
  String get manageUnavailabilitiesDetails => 'Détails';

  @override
  String get manageUnavailabilitiesDetailsHint => 'Détails optionnels';

  @override
  String get manageUnavailabilitiesVisible => 'Visible par l\'équipe';

  @override
  String get manageUnavailabilitiesVisibleHint =>
      'Si désactivé, seuls les managers voient cette entrée';

  @override
  String manageUnavailabilitiesDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get manageUnavailabilitiesHidden => 'Masqué';

  @override
  String get manageUnavailabilitiesSaved => 'Indisponibilité enregistrée';

  @override
  String get manageUnavailabilitiesDeleted => 'Indisponibilité supprimée';

  @override
  String get manageUnavailabilitiesError =>
      'Impossible d\'enregistrer l\'indisponibilité. Veuillez réessayer.';

  @override
  String get manageUnavailabilitiesDeleteError =>
      'Impossible de supprimer l\'indisponibilité. Veuillez réessayer.';

  @override
  String get manageUnavailabilitiesDeleteConfirmTitle =>
      'Supprimer l\'indisponibilité ?';

  @override
  String get manageUnavailabilitiesDeleteConfirmMessage =>
      'Cette action est définitive.';

  @override
  String get manageUnavailabilitiesInvalidRange =>
      'La date de fin ne peut pas être antérieure à la date de début';

  @override
  String get manageUnavailabilitiesTypeRequired => 'Veuillez choisir un type';

  @override
  String get unavailabilityTypeHoliday => 'Vacances';

  @override
  String get unavailabilityTypeUnwell => 'Malade';

  @override
  String get unavailabilityTypeInjured => 'Blessé';

  @override
  String get unavailabilityTypeOther => 'Autre motif';

  @override
  String teamStatsScreenTitle(String teamName) {
    return 'Statistiques — $teamName';
  }

  @override
  String get teamStatsTabAnalysis => 'Analyse';

  @override
  String get teamStatsTabCalendars => 'Calendriers';

  @override
  String get teamStatsCompetitionFilterLabel => 'Compétitions';

  @override
  String get teamStatsOpponentFilterLabel => 'Club';

  @override
  String get teamStatsNoOpponents => 'Aucun club dans cette compétition';

  @override
  String get teamStatsTabTrainings => 'Entraînements';

  @override
  String get teamStatsTabOpponents => 'Adversaires';

  @override
  String get teamStatsSubTabMatches => 'Rencontres';

  @override
  String get teamStatsSubTabRanking => 'Classement';

  @override
  String get teamStatsSubTabGoals => 'Buts';

  @override
  String get teamStatsSubTabPlayers => 'Joueurs';

  @override
  String get teamStatsSubTabTypicalTeam => 'Equipe type';

  @override
  String get teamStatsTypicalTeamStartersSection => 'Titulaires probables';

  @override
  String get teamStatsTypicalTeamSubstitutesSection => 'Remplaçants probables';

  @override
  String teamStatsTypicalTeamStartsLabel(int starts, int total) {
    return '$starts/$total titularisations';
  }

  @override
  String teamStatsTypicalTeamSubsLabel(int subs, int total) {
    return '$subs/$total remplacements';
  }

  @override
  String get teamStatsTypicalTeamNoData =>
      'Aucune donnée de composition disponible pour cet adversaire';

  @override
  String teamStatsTypicalTeamIncompleteStarters(int count) {
    return 'Seulement $count joueurs avec des données de titularisation';
  }

  @override
  String teamStatsTypicalTeamMatchesBasis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matchs avec composition',
      one: '1 match avec composition',
    );
    return 'Basé sur $_temp0';
  }

  @override
  String get teamStatsRankingAtDate => 'A date';

  @override
  String get teamStatsRankingEvolution => 'Evolution';

  @override
  String get teamStatsRankingNoData =>
      'Aucun classement disponible pour cette compétition';

  @override
  String get teamStatsRankingSelectCompetition =>
      'Sélectionnez une compétition pour afficher le classement';

  @override
  String get teamStatsRankingColumnRank => '#';

  @override
  String get teamStatsRankingColumnTeam => 'Equipe';

  @override
  String get teamStatsRankingColumnPts => 'Pts';

  @override
  String get teamStatsRankingColumnPlayed => 'J';

  @override
  String get teamStatsRankingColumnWon => 'G';

  @override
  String get teamStatsRankingColumnDrawn => 'N';

  @override
  String get teamStatsRankingColumnLost => 'P';

  @override
  String get teamStatsRankingColumnDiff => '+/-';

  @override
  String get teamStatsRankingAddClubs => 'Comparer des clubs';

  @override
  String get teamStatsRankingSelectClubsTitle =>
      'Sélectionner des clubs à comparer';

  @override
  String get teamStatsRankingOwnTeamLabel => 'Votre équipe';

  @override
  String teamStatsRankingTooltipRank(String rank) {
    return 'Rang $rank';
  }

  @override
  String get teamStatsAllCompetitions => 'Toutes les compétitions';

  @override
  String get teamStatsContentComingSoon => 'Contenu à venir';

  @override
  String get teamStatsNoCompetitions => 'Aucune compétition disponible';

  @override
  String get teamStatsPlayerComingSoon => 'Vue joueur à venir';

  @override
  String get teamStatsPeriodFullSeason => 'Saison complète';

  @override
  String get teamStatsPeriodFirstHalf => '1ère partie';

  @override
  String get teamStatsPeriodSecondHalf => '2ème partie';

  @override
  String get teamStatsNoPlayedMatches => 'Aucun match joué sur cette période';

  @override
  String teamStatsWdlMatchesDialogTitle(String outcome, String period) {
    return '$outcome — $period';
  }

  @override
  String get teamStatsTrendLabel => 'Tendance';

  @override
  String get teamStatsTrendUp => 'En progression';

  @override
  String get teamStatsTrendDown => 'En baisse';

  @override
  String get teamStatsTrendFlat => 'Stable';

  @override
  String get teamStatsTrendInsufficientData => 'Données insuffisantes';

  @override
  String get teamStatsGoalsScored => 'Buts marqués';

  @override
  String get teamStatsGoalsConceded => 'Buts encaissés';

  @override
  String get teamStatsGoalsTrendScored => 'Buts marqués';

  @override
  String get teamStatsGoalsTrendConceded => 'Buts encaissés';

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
      other: '$count matchs',
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
  String get teamStatsPlayersColumnPlayer => 'Joueur';

  @override
  String get teamStatsPlayersColumnConvocations => 'Convo';

  @override
  String get teamStatsPlayersColumnStarts => 'Titu.';

  @override
  String get teamStatsPlayersColumnPlayTime => 'Tps jeu';

  @override
  String get teamStatsPlayersColumnGoals => 'Buts';

  @override
  String get teamStatsPlayersNoData => 'Aucune donnée joueur sur cette période';

  @override
  String teamStatsPlayersPlayTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teamStatsAllMonths => 'Tous les mois';

  @override
  String teamStatsTrainingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entraînements',
      one: '1 entraînement',
    );
    return '$_temp0';
  }

  @override
  String get teamStatsTrainingsAttendanceRate => 'Taux de présence';

  @override
  String teamStatsTrainingsAttendanceRateValue(String value) {
    return '$value %';
  }

  @override
  String get teamStatsTrainingsNoData =>
      'Aucun entraînement passé sur cette période';

  @override
  String get teamStatsTrainingsNoSeasonMonths =>
      'Aucun mois disponible pour cette saison';

  @override
  String get teamStatsTrainingsColumnPresent => 'Prés.';

  @override
  String get teamStatsTrainingsColumnAbsent => 'Abs.';

  @override
  String get teamStatsTrainingsColumnAttendanceRate => 'Taux';

  @override
  String get teamStatsTrainingsPlayersNoData =>
      'Aucune donnée joueur sur cette période';

  @override
  String get teamStatsTrainingsGlobalSection => 'Équipe';

  @override
  String get teamStatsTrainingsPersonalSection => 'Mes stats';

  @override
  String get teamStatsCalendarNoMatchdays =>
      'Aucun match pour cette compétition';

  @override
  String get teamStatsCalendarNoMatchesForMatchday =>
      'Aucun match pour cette journée';

  @override
  String get teamStatsCalendarDatesLabel => 'Dates';

  @override
  String get teamStatsCalendarNoMatchDates => 'Aucune date programmée';

  @override
  String get teamStatsCalendarDateSeparator => ', ';

  @override
  String get askDiegoTitle => 'Ask Gio';

  @override
  String get askDiegoWelcome =>
      'Bonjour ! Je suis Gio. Je peux vous aider avec votre agenda, votre prochain adversaire ou les statistiques de votre équipe. Posez-moi une question ou utilisez le micro.';

  @override
  String get askDiegoInputHint => 'Demandez à Gio…';

  @override
  String get askDiegoSend => 'Envoyer';

  @override
  String get askDiegoListen => 'Écouter la réponse';

  @override
  String get askDiegoOpenScreen => 'Ouvrir';

  @override
  String get askDiegoOpenOpponentStats => 'Voir les stats adversaire';

  @override
  String get askDiegoStartListening => 'Dicter une question';

  @override
  String get askDiegoStopListening => 'Arrêter l\'écoute';

  @override
  String get askDiegoSpeechUnavailable =>
      'La reconnaissance vocale n\'est pas disponible sur cet appareil.';

  @override
  String get askDiegoSpeechPermissionDenied =>
      'Autorisation micro ou reconnaissance vocale refusée. Activez-la dans Réglages.';

  @override
  String askDiegoSpeechError(String reason) {
    return 'Échec de la reconnaissance vocale : $reason';
  }

  @override
  String get askDiegoEmptyResponse => 'Je n\'ai pas de réponse pour le moment.';

  @override
  String get askDiegoCloseSpeedDial => 'Fermer';

  @override
  String askDiegoNavigationUnknown(String route) {
    return 'Navigation non reconnue : $route';
  }

  @override
  String get askDiegoNavigationAgendaHint =>
      'Ouvrez l\'onglet Agenda pour voir votre calendrier.';

  @override
  String get askDiegoNavigationMatchMissing =>
      'Identifiant de match manquant pour la navigation.';

  @override
  String get askDiegoNavigationMatchNotFound => 'Match introuvable.';

  @override
  String get askDiegoNavigationNoTeam => 'Aucune équipe sélectionnée.';

  @override
  String get askDiegoNavigationOpponentsManagerOnly =>
      'Les statistiques adversaires sont réservées aux entraîneurs.';

  @override
  String get askDiegoNavigationOpponentsPremiumOnly =>
      'Les statistiques adversaires nécessitent un abonnement.';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsRemindersSubtitle =>
      'Rappels locaux pour entraînements et matchs.';

  @override
  String get settingsRemindersEnabled => 'Activer les rappels';

  @override
  String get settingsQuietDaysLabel => 'Jours silencieux';

  @override
  String get settingsQuietHoursLabel => 'Heures silencieuses';

  @override
  String get settingsQuietHoursStart => 'Début';

  @override
  String get settingsQuietHoursEnd => 'Fin';

  @override
  String get settingsMorningReminderHour => 'Heure du rappel matinal';

  @override
  String get reminderWeekdayMon => 'Lun';

  @override
  String get reminderWeekdayTue => 'Mar';

  @override
  String get reminderWeekdayWed => 'Mer';

  @override
  String get reminderWeekdayThu => 'Jeu';

  @override
  String get reminderWeekdayFri => 'Ven';

  @override
  String get reminderWeekdaySat => 'Sam';

  @override
  String get reminderWeekdaySun => 'Dim';

  @override
  String get reminderTrainingTitle => 'Entraînement aujourd\'hui';

  @override
  String reminderTrainingBody(String time) {
    return 'Entraînement aujourd\'hui à $time, préviens ton coach si tu es absent';
  }

  @override
  String get reminderMatchOpponentStatsTitle => 'Match aujourd\'hui';

  @override
  String reminderMatchOpponentStatsBody(String time, String opponent) {
    return 'Aujourd\'hui à $time, tu rencontres $opponent — découvre ses statistiques';
  }

  @override
  String get trainingPresenceConfirmPresent => 'Je serai présent';

  @override
  String get trainingPresenceConfirmAbsent => 'Je serai absent';

  @override
  String get trainingPresenceConfirmedPresent => 'Présence confirmée';

  @override
  String get trainingPresenceConfirmedAbsent => 'Absence signalée';

  @override
  String get matchDetailOpponentStats => 'Stats adversaire';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle => 'Outils d\'administration de la plateforme.';

  @override
  String get adminPromoCodesSection => 'Codes promo';

  @override
  String get adminPromoCodesSectionDesc =>
      'Créer et gérer les codes promo d\'abonnement.';

  @override
  String get adminPromoCodesTitle => 'Codes promo';

  @override
  String get adminPromoCodeCreate => 'Créer un code';

  @override
  String get adminPromoCodesLoadError =>
      'Impossible de charger les codes promo.';

  @override
  String get adminPromoCodesEmpty => 'Aucun code promo pour le moment.';

  @override
  String get adminPromoCodeUpdateFailed =>
      'Impossible de mettre à jour le code promo.';

  @override
  String get adminPromoCodeCreated => 'Code promo créé.';

  @override
  String adminPromoCodeEntitlementLabel(String entitlement) {
    return 'Droit : $entitlement';
  }

  @override
  String adminPromoCodeUsageLabel(int used, int max) {
    return 'Utilisations : $used / $max';
  }

  @override
  String adminPromoCodeDurationLabel(int days) {
    return 'Durée : $days jours';
  }

  @override
  String adminPromoCodeTeamLabel(String teamId) {
    return 'Club : $teamId';
  }

  @override
  String adminPromoCodeExpiresLabel(String date) {
    return 'Expire le : $date';
  }

  @override
  String get adminPromoCodeStatusInactive => 'Inactif';

  @override
  String get adminPromoCodeStatusExpired => 'Expiré';

  @override
  String get adminPromoCodeStatusExhausted => 'Épuisé';

  @override
  String get adminPromoCodeStatusActive => 'Actif';

  @override
  String get adminPromoCodeFieldCode => 'Code';

  @override
  String get adminPromoCodeFieldCodeInvalid =>
      'Le code doit contenir au moins 4 caractères.';

  @override
  String get adminPromoCodeFieldEntitlement => 'Droit';

  @override
  String get adminPromoCodeFieldMaxUses => 'Nombre d\'utilisations max.';

  @override
  String get adminPromoCodeFieldMaxUsesInvalid =>
      'Saisissez un nombre supérieur à 0.';

  @override
  String get adminPromoCodeFieldDurationDays => 'Durée d\'abonnement (jours)';

  @override
  String get adminPromoCodeFieldDurationDaysInvalid =>
      'Saisissez un nombre supérieur à 0.';

  @override
  String get adminPromoCodeFieldTeamId => 'ID club (optionnel)';

  @override
  String get adminPromoCodeFieldTeamIdHint =>
      'Limiter l\'utilisation aux membres de ce club.';

  @override
  String get adminPromoCodeFieldExpiresOptional =>
      'Définir une date d\'expiration (optionnel)';

  @override
  String get adminPromoCodeAlreadyExists => 'Ce code promo existe déjà.';

  @override
  String get adminPromoCodeCreateFailed => 'Impossible de créer le code promo.';

  @override
  String get adminPromoCodePermissionDenied =>
      'Un accès admin est requis pour gérer les codes promo.';

  @override
  String get adminPromoCodeAuthRequired =>
      'Vous devez être connecté pour créer un code promo.';

  @override
  String get adminPromoCodeActions => 'Actions';

  @override
  String get adminPromoCodeEdit => 'Modifier';

  @override
  String get adminPromoCodeEditTitle => 'Modifier le code promo';

  @override
  String get adminPromoCodeDelete => 'Supprimer';

  @override
  String get adminPromoCodeDeleteConfirmTitle => 'Supprimer le code promo ?';

  @override
  String adminPromoCodeDeleteConfirmMessage(String code) {
    return 'Voulez-vous vraiment supprimer le code $code ? Cette action est définitive.';
  }

  @override
  String get adminPromoCodeDeleted => 'Code promo supprimé.';

  @override
  String get adminPromoCodeDeleteFailed =>
      'Impossible de supprimer le code promo.';

  @override
  String get adminPromoCodeUpdated => 'Code promo mis à jour.';

  @override
  String get adminPromoCodeSave => 'Enregistrer';

  @override
  String get adminPromoCodeFieldCodeReadOnly =>
      'Le code ne peut pas être modifié.';

  @override
  String adminPromoCodeFieldMaxUsesBelowUsed(int used) {
    return 'Le nombre max. doit être au moins $used (déjà utilisé).';
  }

  @override
  String get adminPromoCodeFieldActive => 'Actif';

  @override
  String get adminPromoCodeClearExpiry => 'Supprimer la date d\'expiration';

  @override
  String get adminPromoCodeNotFound => 'Code promo introuvable.';

  @override
  String get adminTrackerOwnersSection => 'Propriétaires trackers';

  @override
  String get adminTrackerOwnersSectionDesc =>
      'Créer et gérer les propriétaires de trackers.';

  @override
  String get adminTrackerOwnersTitle => 'Propriétaires trackers';

  @override
  String get adminTrackerOwnersEmpty => 'Aucun propriétaire pour le moment.';

  @override
  String get adminTrackerOwnersLoadError =>
      'Impossible de charger les propriétaires.';

  @override
  String get adminTrackerOwnerCreate => 'Ajouter un propriétaire';

  @override
  String get adminTrackerOwnerCreateTitle => 'Ajouter un propriétaire';

  @override
  String get adminTrackerOwnerEditTitle => 'Modifier le propriétaire';

  @override
  String get adminTrackerOwnerFieldName => 'Nom';

  @override
  String get adminTrackerOwnerFieldEmail => 'Email';

  @override
  String get adminTrackerOwnerFieldFirstname => 'Prénom';

  @override
  String get adminTrackerOwnerFieldLastname => 'Nom de famille';

  @override
  String get adminTrackerOwnerFieldActive => 'Actif';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Type de tracker';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, flux cloud)';

  @override
  String get adminTrackerOwnerFieldRequired => 'Champ obligatoire';

  @override
  String get adminTrackerOwnerFieldEmailInvalid => 'Email invalide';

  @override
  String get adminTrackerOwnerStatusActive => 'Actif';

  @override
  String get adminTrackerOwnerStatusInactive => 'Inactif';

  @override
  String get adminTrackerOwnerSave => 'Enregistrer';

  @override
  String get adminTrackerOwnerDelete => 'Supprimer';

  @override
  String get adminTrackerOwnerDeleteConfirmTitle =>
      'Supprimer le propriétaire ?';

  @override
  String adminTrackerOwnerDeleteConfirmMessage(String name) {
    return 'Voulez-vous vraiment supprimer $name ? Cette action est définitive.';
  }

  @override
  String get adminTrackerOwnerCreated => 'Propriétaire créé.';

  @override
  String get adminTrackerOwnerUpdated => 'Propriétaire mis à jour.';

  @override
  String get adminTrackerOwnerDeleted => 'Propriétaire supprimé.';

  @override
  String get adminTrackerOwnerSaveFailed =>
      'Impossible d\'enregistrer le propriétaire.';

  @override
  String get adminTrackerOwnerDeleteFailed =>
      'Impossible de supprimer le propriétaire.';

  @override
  String get adminTrackerOwnerPermissionDenied =>
      'Un accès administrateur est requis pour gérer les propriétaires.';

  @override
  String get adminTrackerDevicesSection => 'Gestion des trackers';

  @override
  String get adminTrackerDevicesSectionDesc =>
      'Synchroniser, affecter et gérer les devices trackers.';

  @override
  String get adminTrackerDevicesTitle => 'Gestion des trackers';

  @override
  String get adminTrackerDevicesManageAction => 'Gestion des trackers';

  @override
  String get adminTrackerDevicesShowUnassigned =>
      'Afficher les devices sans affectation';

  @override
  String get adminTrackerDevicesSelectOwner => 'Sélectionner un responsable';

  @override
  String get adminTrackerDevicesResetFilter => 'Réinitialiser';

  @override
  String get adminTrackerDevicesEmpty => 'Aucun device';

  @override
  String get adminTrackerDevicesEmptySubtitle =>
      'Aucun document dans TRACKER_Device.';

  @override
  String get adminTrackerDevicesLoadError =>
      'Impossible de charger les devices.';

  @override
  String adminTrackerDevicesSource(String provider) {
    return 'Source : $provider';
  }

  @override
  String adminTrackerDevicesSerial(String serial) {
    return 'Serial : $serial';
  }

  @override
  String adminTrackerDevicesUpdatedAt(String date) {
    return 'Maj : $date';
  }

  @override
  String get adminTrackerDevicesStatusActive => 'Actif';

  @override
  String get adminTrackerDevicesStatusInactive => 'Inactif';

  @override
  String get adminTrackerDevicesAssign => 'Affecter';

  @override
  String get adminTrackerDevicesUnassign => 'Désaffecter';

  @override
  String get adminTrackerDevicesAssignTitle => 'Affecter un device';

  @override
  String get adminTrackerDevicesCustomName => 'Nom (optionnel)';

  @override
  String get adminTrackerDevicesCancel => 'Annuler';

  @override
  String get adminTrackerDevicesValidate => 'Valider';

  @override
  String get adminTrackerDevicesSelectOwnerRequired =>
      'Veuillez sélectionner un responsable.';

  @override
  String get adminTrackerDevicesAssignSuccess => 'Affectation enregistrée.';

  @override
  String get adminTrackerDevicesUnassignSuccess =>
      'Désaffectation enregistrée.';

  @override
  String adminTrackerDevicesError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get adminTrackerDevicesSyncInspirit => 'Sync Inspirit';

  @override
  String get adminTrackerDevicesSyncFootbar => 'Sync Footbar';

  @override
  String get adminTrackerDevicesSyncInProgress => 'Synchronisation...';

  @override
  String get adminTrackerDevicesSyncInspiritInProgress =>
      'Sync Inspirit (insiders) en cours...';

  @override
  String get adminTrackerDevicesSyncFootbarInProgress =>
      'Sync Footbar en cours...';

  @override
  String adminTrackerDevicesSyncInspiritSuccess(int count) {
    return 'Sync Inspirit : $count device(s) mis à jour.';
  }

  @override
  String adminTrackerDevicesSyncInspiritError(String error) {
    return 'Erreur Sync Inspirit : $error';
  }

  @override
  String get adminTrackerDevicesPermissionDenied =>
      'Un accès administrateur est requis pour gérer les devices.';

  @override
  String get adminStreamGroupsSection => 'Messagerie - Groupe';

  @override
  String get adminStreamGroupsSectionDesc =>
      'Lister et supprimer les groupes de chat GetStream des équipes.';

  @override
  String get adminStreamGroupsTitle => 'Messagerie - Groupe';

  @override
  String get adminStreamGroupsEmpty => 'Aucun groupe';

  @override
  String get adminStreamGroupsEmptySubtitle =>
      'Aucun canal d\'équipe trouvé sur GetStream.';

  @override
  String get adminStreamGroupsLoadError => 'Impossible de charger les groupes.';

  @override
  String get adminStreamGroupsRefresh => 'Actualiser';

  @override
  String adminStreamGroupsCid(String cid) {
    return 'CID : $cid';
  }

  @override
  String adminStreamGroupsMemberCount(int count) {
    return '$count membres';
  }

  @override
  String adminStreamGroupsLastMessageAt(String date) {
    return 'Dernier message : $date';
  }

  @override
  String get adminStreamGroupsDelete => 'Supprimer';

  @override
  String get adminStreamGroupsCancel => 'Annuler';

  @override
  String get adminStreamGroupsDeleteConfirmTitle => 'Supprimer le groupe ?';

  @override
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid) {
    return 'Voulez-vous vraiment supprimer le groupe $name ($cid) ? Cette action est définitive.';
  }

  @override
  String get adminStreamGroupsDeleted => 'Groupe supprimé.';

  @override
  String get adminStreamGroupsDeleteFailed =>
      'Impossible de supprimer le groupe.';

  @override
  String get adminStreamGroupsPermissionDenied =>
      'Un accès administrateur est requis pour gérer les groupes.';

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
  String get promoCodeMenuLabel => 'Code promo';

  @override
  String get promoCodeDialogValidate => 'Valider';

  @override
  String get promoCodeRedeemTitle => 'Vous avez un code promo ?';

  @override
  String get promoCodeRedeemHint => 'Saisissez votre code';

  @override
  String get promoCodeRedeemAction => 'Utiliser';

  @override
  String get promoCodeRedeemEmpty => 'Veuillez saisir un code promo.';

  @override
  String promoCodeRedeemSuccess(int days, String entitlement) {
    return 'Code promo appliqué : $days jours de $entitlement.';
  }

  @override
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days) {
    return '$entitlement actif jusqu\'au $expiresAt ($days jours offerts).';
  }

  @override
  String get promoCodeRedeemSyncPending =>
      'Code enregistré côté serveur, mais l\'abonnement n\'apparaît pas encore. Ouvrez Réglages → Abonnement dans un instant, ou déconnectez-vous puis reconnectez-vous.';

  @override
  String get promoCodeRedeemRcUnavailable =>
      'Code enregistré côté serveur, mais RevenueCat n\'est pas configuré sur cet appareil (vérifiez les clés API). Essayez sur iOS ou web, ou relancez avec dart_defines.json.';

  @override
  String get promoCodeRedeemNotFound => 'Code promo introuvable.';

  @override
  String get promoCodeRedeemInvalid => 'Ce code promo n\'est plus valide.';

  @override
  String get promoCodeRedeemInactive => 'Ce code promo n\'est plus actif.';

  @override
  String get promoCodeRedeemExpired => 'Ce code promo a expiré.';

  @override
  String get promoCodeRedeemAlreadyRedeemed =>
      'Vous avez déjà utilisé ce code promo.';

  @override
  String get promoCodeRedeemExhausted =>
      'Ce code promo a atteint sa limite d\'utilisation.';

  @override
  String get promoCodeRedeemTeamMismatch =>
      'Ce code promo est réservé à un autre club.';

  @override
  String get promoCodeRedeemUnauthenticated =>
      'Vous devez être connecté pour utiliser un code promo.';

  @override
  String get promoCodeRedeemFailed => 'Impossible d\'utiliser le code promo.';
}
