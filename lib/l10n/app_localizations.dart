import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Grinta'**
  String get appName;

  /// No description provided for @heroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pilotez votre activité sportive simplement'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Organisez vos événements, gérez vos membres et suivez votre activité depuis une interface claire, moderne et responsive.'**
  String get heroSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre espace.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @emailAndPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email et mot de passe requis'**
  String get emailAndPasswordRequired;

  /// No description provided for @signInError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get signInError;

  /// No description provided for @userNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé pour cet email'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get invalidEmail;

  /// No description provided for @invalidCredential.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides'**
  String get invalidCredential;

  /// No description provided for @tooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessaie plus tard'**
  String get tooManyRequests;

  /// No description provided for @userDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé'**
  String get userDisabled;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue'**
  String get unexpectedError;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de compte ?'**
  String get noAccountYet;

  /// No description provided for @createOneLink.
  ///
  /// In fr, this message translates to:
  /// **'Créez-en un'**
  String get createOneLink;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get confirmPasswordHint;

  /// No description provided for @passwordRequirements.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères, une majuscule, un chiffre et un caractère spécial.'**
  String get passwordRequirements;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signInLink;

  /// No description provided for @or.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithMeta.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Meta'**
  String get continueWithMeta;

  /// No description provided for @hasATeamCode.
  ///
  /// In fr, this message translates to:
  /// **'Je dispose d\'un code équipe'**
  String get hasATeamCode;

  /// No description provided for @hasInvitationCodeQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Avez-vous un code d\'invitation ?'**
  String get hasInvitationCodeQuestion;

  /// No description provided for @invitationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get invitationCode;

  /// No description provided for @invitationCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code'**
  String get invitationCodeHint;

  /// No description provided for @invitationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Code invitation non trouvé'**
  String get invitationNotFound;

  /// No description provided for @invitationNotFoundContinuePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Code inexistant, souhaitez-vous poursuivre en créant votre profil joueur ?'**
  String get invitationNotFoundContinuePrompt;

  /// No description provided for @invitationAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ce code d\'invitation a déjà été utilisé'**
  String get invitationAlreadyUsed;

  /// No description provided for @invitationSentBy.
  ///
  /// In fr, this message translates to:
  /// **'L\'invitation vous a été envoyée par {firstName} {lastName}'**
  String invitationSentBy(String firstName, String lastName);

  /// No description provided for @signupWithoutInvitationComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à venir'**
  String get signupWithoutInvitationComingSoon;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse email'**
  String get emailAlreadyInUse;

  /// No description provided for @invitationCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir et valider un code d\'invitation'**
  String get invitationCodeRequired;

  /// No description provided for @invitationChoiceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez indiquer si vous avez un code d\'invitation'**
  String get invitationChoiceRequired;

  /// No description provided for @memberProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil'**
  String get memberProfileTitle;

  /// No description provided for @memberFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get memberFirstName;

  /// No description provided for @memberLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get memberLastName;

  /// No description provided for @memberEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get memberEmail;

  /// No description provided for @memberEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'E-mail (facultatif)'**
  String get memberEmailOptional;

  /// No description provided for @memberPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get memberPhone;

  /// No description provided for @memberPhoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get memberPhoneOptional;

  /// No description provided for @memberEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir une adresse e-mail valide'**
  String get memberEmailInvalid;

  /// No description provided for @memberPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un numéro de téléphone valide'**
  String get memberPhoneInvalid;

  /// No description provided for @memberPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone est requis pour les invitations'**
  String get memberPhoneRequired;

  /// No description provided for @invitationSmsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach t\'invite à rejoindre {appName}. Ton code : {code}.\niPhone : {appleStoreUrl}\nAndroid : {googlePlayUrl}'**
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl);

  /// No description provided for @memberInvitationSmsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Membre ajouté, mais l\'envoi du SMS d\'invitation a échoué.'**
  String get memberInvitationSmsFailed;

  /// No description provided for @memberAddedToTeamNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour d\'équipe'**
  String get memberAddedToTeamNotificationTitle;

  /// No description provided for @memberAddedToTeamNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach t\'a ajouté à {teamName}.'**
  String memberAddedToTeamNotificationBody(String teamName);

  /// No description provided for @invitationAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Invitation acceptée'**
  String get invitationAccepted;

  /// No description provided for @invitationPending.
  ///
  /// In fr, this message translates to:
  /// **'Invitation en attente'**
  String get invitationPending;

  /// No description provided for @memberAppAccountLinked.
  ///
  /// In fr, this message translates to:
  /// **'Compte application lié'**
  String get memberAppAccountLinked;

  /// No description provided for @memberBirthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get memberBirthDate;

  /// No description provided for @memberBirthDateOptional.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance (facultatif)'**
  String get memberBirthDateOptional;

  /// No description provided for @memberBirthPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de naissance'**
  String get memberBirthPlace;

  /// No description provided for @memberBirthPlaceOptional.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de naissance (facultatif)'**
  String get memberBirthPlaceOptional;

  /// No description provided for @memberNationality.
  ///
  /// In fr, this message translates to:
  /// **'Nationalité'**
  String get memberNationality;

  /// No description provided for @memberNationalityHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une nationalité'**
  String get memberNationalityHint;

  /// No description provided for @memberNationalitySearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une nationalité'**
  String get memberNationalitySearch;

  /// No description provided for @memberPositions.
  ///
  /// In fr, this message translates to:
  /// **'Postes'**
  String get memberPositions;

  /// No description provided for @memberPositionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un ou plusieurs postes (facultatif)'**
  String get memberPositionsHint;

  /// No description provided for @memberFirstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom est obligatoire'**
  String get memberFirstNameRequired;

  /// No description provided for @memberLastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get memberLastNameRequired;

  /// No description provided for @memberBirthPlaceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le lieu de naissance est obligatoire'**
  String get memberBirthPlaceRequired;

  /// No description provided for @memberNationalityRequired.
  ///
  /// In fr, this message translates to:
  /// **'La nationalité est obligatoire'**
  String get memberNationalityRequired;

  /// No description provided for @memberContactRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez au moins un email ou un numéro de téléphone'**
  String get memberContactRequired;

  /// No description provided for @memberProfileIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez compléter votre profil'**
  String get memberProfileIncomplete;

  /// No description provided for @memberProfileSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon profil'**
  String get memberProfileSubmit;

  /// No description provided for @memberProfileUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get memberProfileUpdateSuccess;

  /// No description provided for @memberProfileUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le profil : {error}'**
  String memberProfileUpdateError(String error);

  /// No description provided for @memberProfileChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get memberProfileChangePhoto;

  /// No description provided for @memberProfileTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get memberProfileTakePhoto;

  /// No description provided for @memberProfileChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get memberProfileChooseFromGallery;

  /// No description provided for @memberProfilePhotoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour la photo : {error}'**
  String memberProfilePhotoUploadError(String error);

  /// No description provided for @errorEditProfileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil disponible à modifier'**
  String get errorEditProfileUnavailable;

  /// No description provided for @createTeamPromptQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous créer une équipe ?'**
  String get createTeamPromptQuestion;

  /// No description provided for @createTeamPromptLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get createTeamPromptLater;

  /// No description provided for @slide1Title.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre équipe'**
  String get slide1Title;

  /// No description provided for @slide1Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Centralisez vos membres, vos informations et votre organisation dans une seule application.'**
  String get slide1Subtitle;

  /// No description provided for @slide2Title.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez vos matchs'**
  String get slide2Title;

  /// No description provided for @slide2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez vos événements, convoquez vos joueurs et suivez facilement les disponibilités.'**
  String get slide2Subtitle;

  /// No description provided for @slide3Title.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos performances'**
  String get slide3Title;

  /// No description provided for @slide3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les statistiques, l’activité et les résultats depuis une interface claire.'**
  String get slide3Subtitle;

  /// No description provided for @actionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get actionDelete;

  /// No description provided for @actionRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get actionClose;

  /// No description provided for @actionOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get actionYes;

  /// No description provided for @actionNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get actionNo;

  /// No description provided for @actionValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get actionValidate;

  /// No description provided for @actionCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get actionCopy;

  /// No description provided for @actionReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get actionReset;

  /// No description provided for @actionBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get actionBack;

  /// No description provided for @actionNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get actionNew;

  /// No description provided for @actionChoosePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une période'**
  String get actionChoosePeriod;

  /// No description provided for @actionWeekPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Semaine -'**
  String get actionWeekPrevious;

  /// No description provided for @actionWeekNext.
  ///
  /// In fr, this message translates to:
  /// **'Semaine +'**
  String get actionWeekNext;

  /// No description provided for @actionLoadBefore.
  ///
  /// In fr, this message translates to:
  /// **'Charger avant'**
  String get actionLoadBefore;

  /// No description provided for @actionLoadAfter.
  ///
  /// In fr, this message translates to:
  /// **'Charger après'**
  String get actionLoadAfter;

  /// No description provided for @actionToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get actionToday;

  /// No description provided for @actionEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get actionEditProfile;

  /// No description provided for @actionCreateNewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau profil'**
  String get actionCreateNewProfile;

  /// No description provided for @actionLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get actionLogout;

  /// No description provided for @actionLogoutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get actionLogoutConfirmTitle;

  /// No description provided for @actionLogoutConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaites-tu vraiment te déconnecter ?'**
  String get actionLogoutConfirmMessage;

  /// No description provided for @actionCreateTeam.
  ///
  /// In fr, this message translates to:
  /// **'Créer une équipe'**
  String get actionCreateTeam;

  /// No description provided for @teamCreationAttachClubQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous attacher cette équipe à un club ?'**
  String get teamCreationAttachClubQuestion;

  /// No description provided for @teamCreationSelectClub.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un club'**
  String get teamCreationSelectClub;

  /// No description provided for @teamCreationClubRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un club'**
  String get teamCreationClubRequired;

  /// No description provided for @teamCreationSelectClubTeams.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner des équipes'**
  String get teamCreationSelectClubTeams;

  /// No description provided for @teamCreationNoClubTeams.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe engagée'**
  String get teamCreationNoClubTeams;

  /// No description provided for @teamCreationSelectedClubTeamsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune équipe sélectionnée} =1{1 équipe sélectionnée} other{{count} équipes sélectionnées}}'**
  String teamCreationSelectedClubTeamsCount(int count);

  /// No description provided for @teamCreationClubTeamCompetitionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 compétition} other{{count} compétitions}}'**
  String teamCreationClubTeamCompetitionsCount(int count);

  /// No description provided for @teamCreationSoccerType.
  ///
  /// In fr, this message translates to:
  /// **'Type de football'**
  String get teamCreationSoccerType;

  /// No description provided for @teamCreationNoClubWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get teamCreationNoClubWarningTitle;

  /// No description provided for @teamCreationNoClubWarning.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe n\'est pas liée à un club ni à une compétition. Dans ce cas, vous n\'avez pas de récupération automatique du calendrier et des résultats.'**
  String get teamCreationNoClubWarning;

  /// No description provided for @equipeCompetitionsSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compétitions — {teamName}'**
  String equipeCompetitionsSheetTitle(String teamName);

  /// No description provided for @fffCompetitionPhaseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Phase {phase}'**
  String fffCompetitionPhaseLabel(int phase);

  /// No description provided for @fffCompetitionGroupeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Groupe {groupe}'**
  String fffCompetitionGroupeLabel(int groupe);

  /// No description provided for @hintSearchClub.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un club'**
  String get hintSearchClub;

  /// No description provided for @hintSearchClubTeam.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une équipe'**
  String get hintSearchClubTeam;

  /// No description provided for @actionAddPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get actionAddPlayer;

  /// No description provided for @actionCreatePlayer.
  ///
  /// In fr, this message translates to:
  /// **'Créer un joueur'**
  String get actionCreatePlayer;

  /// No description provided for @actionEditPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le joueur'**
  String get actionEditPlayer;

  /// No description provided for @actionEditStaff.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le staff'**
  String get actionEditStaff;

  /// No description provided for @addPlayerPositionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un poste'**
  String get addPlayerPositionRequired;

  /// No description provided for @addPlayerHeightCmOptional.
  ///
  /// In fr, this message translates to:
  /// **'Taille (cm, facultatif)'**
  String get addPlayerHeightCmOptional;

  /// No description provided for @addPlayerWeightKgOptional.
  ///
  /// In fr, this message translates to:
  /// **'Poids (kg, facultatif)'**
  String get addPlayerWeightKgOptional;

  /// No description provided for @addPlayerHeightInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une taille entre 50 et 250 cm'**
  String get addPlayerHeightInvalid;

  /// No description provided for @addPlayerWeightInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un poids entre 20 et 200 kg'**
  String get addPlayerWeightInvalid;

  /// No description provided for @actionAddStaff.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un staff'**
  String get actionAddStaff;

  /// No description provided for @actionAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une zone'**
  String get actionAddZone;

  /// No description provided for @actionAddToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get actionAddToCart;

  /// No description provided for @actionBeginCheckout.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le paiement'**
  String get actionBeginCheckout;

  /// No description provided for @actionConnect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter'**
  String get actionConnect;

  /// No description provided for @actionDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get actionDownload;

  /// No description provided for @actionEraseData.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les données'**
  String get actionEraseData;

  /// No description provided for @actionChooseAsiFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier .asi'**
  String get actionChooseAsiFile;

  /// No description provided for @actionDefaultValues.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs par défaut'**
  String get actionDefaultValues;

  /// No description provided for @actionRemoveCustomization.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la personnalisation'**
  String get actionRemoveCustomization;

  /// No description provided for @actionDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get actionDisconnect;

  /// No description provided for @actionAsiFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier .asi'**
  String get actionAsiFile;

  /// No description provided for @actionWeekPreviousLong.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get actionWeekPreviousLong;

  /// No description provided for @actionWeekNextLong.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get actionWeekNextLong;

  /// No description provided for @entityTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get entityTeam;

  /// No description provided for @entityTeamWithIndex.
  ///
  /// In fr, this message translates to:
  /// **'Équipe {index}'**
  String entityTeamWithIndex(int index);

  /// No description provided for @entityTeams.
  ///
  /// In fr, this message translates to:
  /// **'Équipes'**
  String get entityTeams;

  /// No description provided for @entityPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get entityPlayer;

  /// No description provided for @entityPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get entityPlayers;

  /// No description provided for @entityPlayerUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Joueur inconnu'**
  String get entityPlayerUnknown;

  /// No description provided for @entityPlayerNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Joueur non renseigné'**
  String get entityPlayerNotSet;

  /// No description provided for @entityStaff.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get entityStaff;

  /// No description provided for @entityMatch.
  ///
  /// In fr, this message translates to:
  /// **'Match'**
  String get entityMatch;

  /// No description provided for @entityMatches.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get entityMatches;

  /// No description provided for @entityTraining.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get entityTraining;

  /// No description provided for @entityTrainings.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements'**
  String get entityTrainings;

  /// No description provided for @entityField.
  ///
  /// In fr, this message translates to:
  /// **'Terrain'**
  String get entityField;

  /// No description provided for @entityFieldUndefined.
  ///
  /// In fr, this message translates to:
  /// **'Terrain non défini'**
  String get entityFieldUndefined;

  /// No description provided for @entitySeason.
  ///
  /// In fr, this message translates to:
  /// **'Saison'**
  String get entitySeason;

  /// No description provided for @entityEvent.
  ///
  /// In fr, this message translates to:
  /// **'événement'**
  String get entityEvent;

  /// No description provided for @entityEvents.
  ///
  /// In fr, this message translates to:
  /// **'événements'**
  String get entityEvents;

  /// No description provided for @entityConversation.
  ///
  /// In fr, this message translates to:
  /// **'conversation'**
  String get entityConversation;

  /// No description provided for @entityUser.
  ///
  /// In fr, this message translates to:
  /// **'utilisateur'**
  String get entityUser;

  /// No description provided for @entityProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get entityProduct;

  /// No description provided for @entityCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get entityCart;

  /// No description provided for @entityApplication.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get entityApplication;

  /// No description provided for @entityMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get entityMap;

  /// No description provided for @entityIndicator.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur'**
  String get entityIndicator;

  /// No description provided for @entityDeviceId.
  ///
  /// In fr, this message translates to:
  /// **'Device ID'**
  String get entityDeviceId;

  /// No description provided for @entityTracker.
  ///
  /// In fr, this message translates to:
  /// **'Tracker'**
  String get entityTracker;

  /// No description provided for @entityTrackerId.
  ///
  /// In fr, this message translates to:
  /// **'id'**
  String get entityTrackerId;

  /// No description provided for @entityName.
  ///
  /// In fr, this message translates to:
  /// **'nom'**
  String get entityName;

  /// No description provided for @entityCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get entityCode;

  /// No description provided for @entityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get entityLabel;

  /// No description provided for @entityMinSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse min'**
  String get entityMinSpeed;

  /// No description provided for @entityMaxSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse max'**
  String get entityMaxSpeed;

  /// No description provided for @entityFullMatch.
  ///
  /// In fr, this message translates to:
  /// **'Match entier'**
  String get entityFullMatch;

  /// No description provided for @entityFullMatchShort.
  ///
  /// In fr, this message translates to:
  /// **'Match complet'**
  String get entityFullMatchShort;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get navDashboard;

  /// No description provided for @navAgenda.
  ///
  /// In fr, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navTeams.
  ///
  /// In fr, this message translates to:
  /// **'Équipes'**
  String get navTeams;

  /// No description provided for @navChat.
  ///
  /// In fr, this message translates to:
  /// **'Messagerie'**
  String get navChat;

  /// No description provided for @navSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get navSync;

  /// No description provided for @featureDiscoveryAgendaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez l’agenda'**
  String get featureDiscoveryAgendaTitle;

  /// No description provided for @featureDiscoveryAgendaMessage.
  ///
  /// In fr, this message translates to:
  /// **'Consultez vos matchs et entraînements à venir depuis l’onglet Agenda.'**
  String get featureDiscoveryAgendaMessage;

  /// No description provided for @featureDiscoveryDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get featureDiscoveryDiscover;

  /// No description provided for @featureDiscoveryDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez le tableau de bord'**
  String get featureDiscoveryDashboardTitle;

  /// No description provided for @featureDiscoveryDashboardMessage.
  ///
  /// In fr, this message translates to:
  /// **'Suivez l’activité, les stats et les prochains événements depuis l’onglet Tableau de bord.'**
  String get featureDiscoveryDashboardMessage;

  /// No description provided for @featureDiscoveryChatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez la messagerie'**
  String get featureDiscoveryChatTitle;

  /// No description provided for @featureDiscoveryChatMessage.
  ///
  /// In fr, this message translates to:
  /// **'Échangez avec votre équipe depuis l’onglet Messagerie.'**
  String get featureDiscoveryChatMessage;

  /// No description provided for @featureDiscoverySyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez la synchronisation'**
  String get featureDiscoverySyncTitle;

  /// No description provided for @featureDiscoverySyncMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez les données tracker et gérez les appareils depuis l’onglet Synchronisation.'**
  String get featureDiscoverySyncMessage;

  /// No description provided for @featureDiscoveryTeamsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les équipes'**
  String get featureDiscoveryTeamsTitle;

  /// No description provided for @featureDiscoveryTeamsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Gérez les effectifs et les paramètres depuis la section Équipes.'**
  String get featureDiscoveryTeamsMessage;

  /// No description provided for @featureDiscoveryFieldsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les terrains'**
  String get featureDiscoveryFieldsTitle;

  /// No description provided for @featureDiscoveryFieldsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Localisez les terrains pour l’analyse tracker depuis l’onglet Terrains.'**
  String get featureDiscoveryFieldsMessage;

  /// No description provided for @featureDiscoveryCompoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez la compo'**
  String get featureDiscoveryCompoTitle;

  /// No description provided for @featureDiscoveryCompoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez et réutilisez des compositions depuis l’onglet Compo.'**
  String get featureDiscoveryCompoMessage;

  /// No description provided for @featureDiscoveryMatchCompoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Onglet Compo'**
  String get featureDiscoveryMatchCompoTitle;

  /// No description provided for @featureDiscoveryMatchCompoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Consultez et modifiez la composition du match dans l’onglet Compo.'**
  String get featureDiscoveryMatchCompoMessage;

  /// No description provided for @featureDiscoveryMatchTacticalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Onglet Schéma tactique'**
  String get featureDiscoveryMatchTacticalTitle;

  /// No description provided for @featureDiscoveryMatchTacticalMessage.
  ///
  /// In fr, this message translates to:
  /// **'Placez les joueurs sur le terrain dans l’onglet Schéma tactique.'**
  String get featureDiscoveryMatchTacticalMessage;

  /// No description provided for @featureDiscoveryMatchHighlightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Onglet Temps forts'**
  String get featureDiscoveryMatchHighlightsTitle;

  /// No description provided for @featureDiscoveryMatchHighlightsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Revoyez les moments clés dans l’onglet Temps forts.'**
  String get featureDiscoveryMatchHighlightsMessage;

  /// No description provided for @featureDiscoveryMatchStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Onglet Statistiques'**
  String get featureDiscoveryMatchStatsTitle;

  /// No description provided for @featureDiscoveryMatchStatsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les stats tracker et heatmaps dans l’onglet Statistiques.'**
  String get featureDiscoveryMatchStatsMessage;

  /// No description provided for @featureDiscoveryDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get featureDiscoveryDismiss;

  /// No description provided for @navFields.
  ///
  /// In fr, this message translates to:
  /// **'Terrains'**
  String get navFields;

  /// No description provided for @navCompo.
  ///
  /// In fr, this message translates to:
  /// **'Compo'**
  String get navCompo;

  /// No description provided for @navStatistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get navStatistics;

  /// No description provided for @navOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d’ensemble'**
  String get navOverview;

  /// No description provided for @navNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation'**
  String get navNavigation;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @tabCompo.
  ///
  /// In fr, this message translates to:
  /// **'Compo'**
  String get tabCompo;

  /// No description provided for @tabTacticalSchema.
  ///
  /// In fr, this message translates to:
  /// **'Schéma tactique'**
  String get tabTacticalSchema;

  /// No description provided for @tabTacticalSchemaShort.
  ///
  /// In fr, this message translates to:
  /// **'Schéma'**
  String get tabTacticalSchemaShort;

  /// No description provided for @matchTacticalSchemaConvocation.
  ///
  /// In fr, this message translates to:
  /// **'Convoquer des joueurs'**
  String get matchTacticalSchemaConvocation;

  /// No description provided for @matchTacticalSchemaConvocationHint.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel — limite le choix sur le terrain aux joueurs convoqués'**
  String get matchTacticalSchemaConvocationHint;

  /// No description provided for @matchTacticalSchemaSubstitutes.
  ///
  /// In fr, this message translates to:
  /// **'Remplaçants'**
  String get matchTacticalSchemaSubstitutes;

  /// No description provided for @matchTacticalSchemaAddSubstitute.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un remplaçant'**
  String get matchTacticalSchemaAddSubstitute;

  /// No description provided for @matchTacticalSchemaNoSubstitutes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remplaçant'**
  String get matchTacticalSchemaNoSubstitutes;

  /// No description provided for @matchTacticalSchemaPickPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un joueur'**
  String get matchTacticalSchemaPickPlayer;

  /// No description provided for @matchTacticalSchemaClearSlot.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du poste'**
  String get matchTacticalSchemaClearSlot;

  /// No description provided for @matchTacticalSchemaSaved.
  ///
  /// In fr, this message translates to:
  /// **'Schéma tactique enregistré'**
  String get matchTacticalSchemaSaved;

  /// No description provided for @matchTacticalSchemaEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun schéma tactique pour ce match'**
  String get matchTacticalSchemaEmpty;

  /// No description provided for @matchTacticalSchemaUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Schéma tactique indisponible pour ce match'**
  String get matchTacticalSchemaUnavailable;

  /// No description provided for @matchTacticalSchemaNoTeam.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'identifier l\'équipe liée à ce match.'**
  String get matchTacticalSchemaNoTeam;

  /// No description provided for @matchTacticalSchemaJerseyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de maillot'**
  String get matchTacticalSchemaJerseyNumber;

  /// No description provided for @matchTacticalSchemaPlayerAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Affectation du joueur'**
  String get matchTacticalSchemaPlayerAssignment;

  /// No description provided for @matchTacticalSchemaJerseyNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un numéro de maillot (1 à 99).'**
  String get matchTacticalSchemaJerseyNumberRequired;

  /// No description provided for @matchTacticalSchemaNoJerseyNumberAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun numéro de maillot disponible (tous les numéros de 1 à 99 sont déjà attribués).'**
  String get matchTacticalSchemaNoJerseyNumberAvailable;

  /// No description provided for @matchTacticalSchemaRemoveFromCompo.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la compo ?'**
  String get matchTacticalSchemaRemoveFromCompo;

  /// No description provided for @matchTacticalSchemaRemoveFromCompoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce joueur sera retiré du schéma tactique (poste et remplaçants).'**
  String get matchTacticalSchemaRemoveFromCompoMessage;

  /// No description provided for @matchTacticalSchemaRemoveFromCompoConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get matchTacticalSchemaRemoveFromCompoConfirm;

  /// No description provided for @matchTacticalSchemaSensorRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un capteur disponible.'**
  String get matchTacticalSchemaSensorRequired;

  /// No description provided for @matchTacticalSchemaNoPlayerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur disponible — tous les joueurs éligibles sont déjà sur la compo.'**
  String get matchTacticalSchemaNoPlayerAvailable;

  /// No description provided for @tabHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Temps forts'**
  String get tabHighlights;

  /// No description provided for @tabStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get tabStats;

  /// No description provided for @tabStarters.
  ///
  /// In fr, this message translates to:
  /// **'Titulaires'**
  String get tabStarters;

  /// No description provided for @tabSubstitutes.
  ///
  /// In fr, this message translates to:
  /// **'Remplaçants'**
  String get tabSubstitutes;

  /// No description provided for @tabSynthesis.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse'**
  String get tabSynthesis;

  /// No description provided for @tabSpeedZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones de vitesse'**
  String get tabSpeedZones;

  /// No description provided for @tabFieldZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones de terrain'**
  String get tabFieldZones;

  /// No description provided for @tabHalfTimeComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison mi-temps'**
  String get tabHalfTimeComparison;

  /// No description provided for @tabDistanceTimeline.
  ///
  /// In fr, this message translates to:
  /// **'Timeline distance'**
  String get tabDistanceTimeline;

  /// No description provided for @tabHeatmap.
  ///
  /// In fr, this message translates to:
  /// **'Carte de chaleur'**
  String get tabHeatmap;

  /// No description provided for @periodWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get periodMonth;

  /// No description provided for @periodCustom.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get periodCustom;

  /// No description provided for @periodPrep.
  ///
  /// In fr, this message translates to:
  /// **'Prépa physique'**
  String get periodPrep;

  /// No description provided for @periodPostponed.
  ///
  /// In fr, this message translates to:
  /// **'Reporté'**
  String get periodPostponed;

  /// No description provided for @periodMatchDay.
  ///
  /// In fr, this message translates to:
  /// **'Journée {day}'**
  String periodMatchDay(String day);

  /// No description provided for @periodSelectedWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine sélectionnée : {range}'**
  String periodSelectedWeek(String range);

  /// No description provided for @periodUndefined.
  ///
  /// In fr, this message translates to:
  /// **'Aucune période définie'**
  String get periodUndefined;

  /// No description provided for @hintSearchTeam.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une équipe'**
  String get hintSearchTeam;

  /// No description provided for @hintSearchMember.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un membre'**
  String get hintSearchMember;

  /// No description provided for @memberSearchPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un prénom ou un nom pour rechercher'**
  String get memberSearchPrompt;

  /// No description provided for @memberAlreadyOnTeamRoster.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre fait déjà partie de l\'effectif'**
  String get memberAlreadyOnTeamRoster;

  /// No description provided for @memberAlreadyPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre fait déjà partie des joueurs'**
  String get memberAlreadyPlayer;

  /// No description provided for @memberAlreadyStaff.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre fait déjà partie du staff'**
  String get memberAlreadyStaff;

  /// No description provided for @hintSearchUser.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un utilisateur'**
  String get hintSearchUser;

  /// No description provided for @hintSearchAddress.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une adresse ou un stade'**
  String get hintSearchAddress;

  /// No description provided for @hintSelectSeason.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une saison'**
  String get hintSelectSeason;

  /// No description provided for @hintFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du terrain'**
  String get hintFieldName;

  /// No description provided for @hintCompoType.
  ///
  /// In fr, this message translates to:
  /// **'Type de composition'**
  String get hintCompoType;

  /// No description provided for @hintMetric.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur'**
  String get hintMetric;

  /// No description provided for @hintDeviceIdExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : tracker_001'**
  String get hintDeviceIdExample;

  /// No description provided for @hintSpeedZoneMaxEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Laisser vide pour la dernière zone'**
  String get hintSpeedZoneMaxEmpty;

  /// No description provided for @emptyNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get emptyNoData;

  /// No description provided for @emptyNoEvent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement'**
  String get emptyNoEvent;

  /// No description provided for @emptyNoConversation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get emptyNoConversation;

  /// No description provided for @emptyNoHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Aucun temps fort'**
  String get emptyNoHighlights;

  /// No description provided for @emptyNoCompo.
  ///
  /// In fr, this message translates to:
  /// **'Aucune composition n’a été trouvée pour ce match.'**
  String get emptyNoCompo;

  /// No description provided for @emptyNoStarters.
  ///
  /// In fr, this message translates to:
  /// **'Aucun titulaire renseigné.'**
  String get emptyNoStarters;

  /// No description provided for @emptyNoSubstitutes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remplaçant renseigné.'**
  String get emptyNoSubstitutes;

  /// No description provided for @emptyNoTracker.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tracker sélectionné'**
  String get emptyNoTracker;

  /// No description provided for @emptyNoTrackers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tracker à afficher'**
  String get emptyNoTrackers;

  /// No description provided for @emptyNoDeviceId.
  ///
  /// In fr, this message translates to:
  /// **'Aucun deviceId disponible'**
  String get emptyNoDeviceId;

  /// No description provided for @emptyNoFileSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier sélectionné'**
  String get emptyNoFileSelected;

  /// No description provided for @emptyNoSpeedZone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone de vitesse disponible.'**
  String get emptyNoSpeedZone;

  /// No description provided for @emptyNoFieldZoneData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de zone terrain disponible.'**
  String get emptyNoFieldZoneData;

  /// No description provided for @emptyNoDistanceTimeline.
  ///
  /// In fr, this message translates to:
  /// **'Aucune timeline de distance disponible.'**
  String get emptyNoDistanceTimeline;

  /// No description provided for @emptyNoStatsForMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée trouvée pour ce match.'**
  String get emptyNoStatsForMatch;

  /// No description provided for @emptyNoStatsTeamAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée trouvée dans TRACKER_TeamAnalysis pour ce match.'**
  String get emptyNoStatsTeamAnalysis;

  /// No description provided for @emptyNoPendingMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match en attente.'**
  String get emptyNoPendingMatch;

  /// No description provided for @emptyNoPendingTraining.
  ///
  /// In fr, this message translates to:
  /// **'Aucun entraînement avec tracker en attente.'**
  String get emptyNoPendingTraining;

  /// No description provided for @emptyNoTeamFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe trouvée'**
  String get emptyNoTeamFound;

  /// No description provided for @emptyNoTeamAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe disponible'**
  String get emptyNoTeamAvailable;

  /// No description provided for @emptyNoTeamForSeason.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe trouvée pour cette saison.'**
  String get emptyNoTeamForSeason;

  /// No description provided for @emptyNoTeamForStats.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe disponible pour afficher les statistiques.'**
  String get emptyNoTeamForStats;

  /// No description provided for @emptyNoPlayerForTeam.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur trouvé pour cette équipe.'**
  String get emptyNoPlayerForTeam;

  /// No description provided for @trainingPlayersRecap.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get trainingPlayersRecap;

  /// No description provided for @trainingPlayersLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des joueurs…'**
  String get trainingPlayersLoading;

  /// No description provided for @trainingPlayersClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get trainingPlayersClose;

  /// No description provided for @presencePresent.
  ///
  /// In fr, this message translates to:
  /// **'Présent(e)'**
  String get presencePresent;

  /// No description provided for @presenceInjured.
  ///
  /// In fr, this message translates to:
  /// **'Blessé(e)'**
  String get presenceInjured;

  /// No description provided for @presenceExcused.
  ///
  /// In fr, this message translates to:
  /// **'Excusé(e)'**
  String get presenceExcused;

  /// No description provided for @presenceAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absent(e)'**
  String get presenceAbsent;

  /// No description provided for @presenceLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get presenceLate;

  /// No description provided for @presenceUnknown.
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get presenceUnknown;

  /// No description provided for @trainingPlayersAddPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get trainingPlayersAddPlayer;

  /// No description provided for @trainingPlayersAddPlayerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un joueur'**
  String get trainingPlayersAddPlayerTitle;

  /// No description provided for @trainingPlayersNoCandidates.
  ///
  /// In fr, this message translates to:
  /// **'Tous les joueurs de l\'équipe sont déjà inscrits.'**
  String get trainingPlayersNoCandidates;

  /// No description provided for @trainingPlayersChangePresence.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la présence'**
  String get trainingPlayersChangePresence;

  /// No description provided for @trainingPlayersAssignTracker.
  ///
  /// In fr, this message translates to:
  /// **'Affecter un capteur'**
  String get trainingPlayersAssignTracker;

  /// No description provided for @trainingPlayersNoTrackerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capteur disponible.'**
  String get trainingPlayersNoTrackerAvailable;

  /// No description provided for @trainingPlayersSelectTracker.
  ///
  /// In fr, this message translates to:
  /// **'Capteur'**
  String get trainingPlayersSelectTracker;

  /// No description provided for @emptyNoStaffForTeam.
  ///
  /// In fr, this message translates to:
  /// **'Aucun staff trouvé pour cette équipe.'**
  String get emptyNoStaffForTeam;

  /// No description provided for @emptyNoPlayerSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur sélectionné.'**
  String get emptyNoPlayerSelected;

  /// No description provided for @emptyNoCurrentSeason.
  ///
  /// In fr, this message translates to:
  /// **'Aucune saison en cours disponible.'**
  String get emptyNoCurrentSeason;

  /// No description provided for @emptyNoUserFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé'**
  String get emptyNoUserFound;

  /// No description provided for @emptyNoUserAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur disponible'**
  String get emptyNoUserAvailable;

  /// No description provided for @emptyNoConnectedDevice.
  ///
  /// In fr, this message translates to:
  /// **'Aucun périphérique connecté'**
  String get emptyNoConnectedDevice;

  /// No description provided for @emptyNoMatchToShow.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match à afficher.'**
  String get emptyNoMatchToShow;

  /// No description provided for @emptyNoCompoType.
  ///
  /// In fr, this message translates to:
  /// **'Aucun type de composition n’a été trouvé.'**
  String get emptyNoCompoType;

  /// No description provided for @emptyNoAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Aucune analyse disponible'**
  String get emptyNoAnalysis;

  /// No description provided for @emptyNoStats.
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique disponible'**
  String get emptyNoStats;

  /// No description provided for @emptyNoPlayersInStats.
  ///
  /// In fr, this message translates to:
  /// **'Les statistiques existent mais aucun score joueur n’est disponible.'**
  String get emptyNoPlayersInStats;

  /// No description provided for @emptyHeatmap.
  ///
  /// In fr, this message translates to:
  /// **'Heatmap indisponible'**
  String get emptyHeatmap;

  /// No description provided for @emptyNoSvgForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image SVG trouvée pour {period}.'**
  String emptyNoSvgForPeriod(String period);

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {details}'**
  String errorGeneric(String details);

  /// No description provided for @errorLoadingResource.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement de {resource}.'**
  String errorLoadingResource(String resource);

  /// No description provided for @errorFilteringResource.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du filtrage de {resource}.'**
  String errorFilteringResource(String resource);

  /// No description provided for @errorComputingStats.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du calcul des statistiques de {resource}.'**
  String errorComputingStats(String resource);

  /// No description provided for @errorSaving.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’enregistrement : {details}'**
  String errorSaving(String details);

  /// No description provided for @errorLogout.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la déconnexion : {details}'**
  String errorLogout(String details);

  /// No description provided for @errorStreamConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Stream impossible'**
  String get errorStreamConnection;

  /// No description provided for @sessionReplacedOnAnotherDevice.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a été ouverte sur un autre appareil. Veuillez vous reconnecter.'**
  String get sessionReplacedOnAnotherDevice;

  /// No description provided for @errorOpenAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir l’analyse : eventId ou trackerId manquant.'**
  String get errorOpenAnalysis;

  /// No description provided for @errorAgendaLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’agenda'**
  String get errorAgendaLoad;

  /// No description provided for @errorTeamParamsLoad.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement des paramètres : {details}'**
  String errorTeamParamsLoad(String details);

  /// No description provided for @errorSaveTeamIdEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de sauvegarder : teamId vide.'**
  String get errorSaveTeamIdEmpty;

  /// No description provided for @errorDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression : {details}'**
  String errorDeleteFailed(String details);

  /// No description provided for @errorLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get errorLoadingTitle;

  /// No description provided for @errorCompositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur composition'**
  String get errorCompositionTitle;

  /// No description provided for @errorPlayerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur joueur'**
  String get errorPlayerTitle;

  /// No description provided for @errorPlayersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur joueurs'**
  String get errorPlayersTitle;

  /// No description provided for @errorTrackerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur tracker'**
  String get errorTrackerTitle;

  /// No description provided for @errorMatchNotIdentified.
  ///
  /// In fr, this message translates to:
  /// **'Match non identifié'**
  String get errorMatchNotIdentified;

  /// No description provided for @errorPlayerNotIdentified.
  ///
  /// In fr, this message translates to:
  /// **'Joueur non identifié'**
  String get errorPlayerNotIdentified;

  /// No description provided for @errorPlayerNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Joueur introuvable'**
  String get errorPlayerNotFound;

  /// No description provided for @errorPlayerNotFoundInMatch.
  ///
  /// In fr, this message translates to:
  /// **'Joueur non trouvé'**
  String get errorPlayerNotFoundInMatch;

  /// No description provided for @errorStatsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques indisponibles'**
  String get errorStatsUnavailable;

  /// No description provided for @errorNoStats.
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique'**
  String get errorNoStats;

  /// No description provided for @errorNoStatsForPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les statistiques du joueur.'**
  String get errorNoStatsForPlayer;

  /// No description provided for @errorPlayerNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retrouver le joueur sélectionné.'**
  String get errorPlayerNotFoundMessage;

  /// No description provided for @errorNoTrackerData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée tracker trouvée pour ce match.'**
  String get errorNoTrackerData;

  /// No description provided for @errorNoTrackerStats.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les statistiques tracker sans identifiant de match.'**
  String get errorNoTrackerStats;

  /// No description provided for @errorNoTrackerAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de trouver les données tracker de ce joueur.'**
  String get errorNoTrackerAnalysis;

  /// No description provided for @errorMatchIdMissing.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant du match manquant.'**
  String get errorMatchIdMissing;

  /// No description provided for @errorChatCreate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création : {details}'**
  String errorChatCreate(String details);

  /// No description provided for @errorCompoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get errorCompoTitle;

  /// No description provided for @errorNoCompoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune composition'**
  String get errorNoCompoTitle;

  /// No description provided for @successSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés avec succès.'**
  String get successSettingsSaved;

  /// No description provided for @successGpsCopied.
  ///
  /// In fr, this message translates to:
  /// **'GPS copié.'**
  String get successGpsCopied;

  /// No description provided for @successDefaultsLoaded.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs par défaut chargées dans le formulaire.'**
  String get successDefaultsLoaded;

  /// No description provided for @successConversionDone.
  ///
  /// In fr, this message translates to:
  /// **'Conversion terminée - {count} ligne(s) retenue(s)'**
  String successConversionDone(int count);

  /// No description provided for @infoReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get infoReadOnly;

  /// No description provided for @infoWebShellOnly.
  ///
  /// In fr, this message translates to:
  /// **'Ce shell est prévu pour Flutter Web uniquement.'**
  String get infoWebShellOnly;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageLabel;

  /// No description provided for @themeDarkModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get themeDarkModeLabel;

  /// No description provided for @themeEnableDarkModeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Activer le mode sombre'**
  String get themeEnableDarkModeTooltip;

  /// No description provided for @themeDisableDarkModeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le mode sombre'**
  String get themeDisableDarkModeTooltip;

  /// No description provided for @infoParameters.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get infoParameters;

  /// No description provided for @infoUserNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non connecté.'**
  String get infoUserNotConnected;

  /// No description provided for @dialogCloseSyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer la synchronisation'**
  String get dialogCloseSyncTitle;

  /// No description provided for @dialogCloseSyncMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous clôturer la synchronisation ?'**
  String get dialogCloseSyncMessage;

  /// No description provided for @dialogDeleteCustomizationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la personnalisation ?'**
  String get dialogDeleteCustomizationTitle;

  /// No description provided for @dialogDeleteAssignmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’affectation'**
  String get dialogDeleteAssignmentTitle;

  /// No description provided for @dialogNewConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get dialogNewConversation;

  /// No description provided for @dialogAsiConversionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conversion ASI vers CSV'**
  String get dialogAsiConversionTitle;

  /// No description provided for @syncMatchesToSync.
  ///
  /// In fr, this message translates to:
  /// **'Matchs à synchroniser'**
  String get syncMatchesToSync;

  /// No description provided for @syncNoDeviceForTraining.
  ///
  /// In fr, this message translates to:
  /// **'Aucun device trouvé pour cet entraînement'**
  String get syncNoDeviceForTraining;

  /// No description provided for @syncNoDeviceForMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capteur trouvé pour ce match'**
  String get syncNoDeviceForMatch;

  /// No description provided for @statsWins.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get statsWins;

  /// No description provided for @statsLosses.
  ///
  /// In fr, this message translates to:
  /// **'Défaites'**
  String get statsLosses;

  /// No description provided for @statsDraws.
  ///
  /// In fr, this message translates to:
  /// **'Nuls'**
  String get statsDraws;

  /// No description provided for @statsDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get statsDistance;

  /// No description provided for @statsMaxSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse max'**
  String get statsMaxSpeed;

  /// No description provided for @statsAvgSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse moy.'**
  String get statsAvgSpeed;

  /// No description provided for @statsWorkload.
  ///
  /// In fr, this message translates to:
  /// **'Workload'**
  String get statsWorkload;

  /// No description provided for @statsFatigue.
  ///
  /// In fr, this message translates to:
  /// **'Fatigue'**
  String get statsFatigue;

  /// No description provided for @statsDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get statsDuration;

  /// No description provided for @statsSprints.
  ///
  /// In fr, this message translates to:
  /// **'Sprints'**
  String get statsSprints;

  /// No description provided for @statsHighAccel.
  ///
  /// In fr, this message translates to:
  /// **'Acc. hautes'**
  String get statsHighAccel;

  /// No description provided for @statsHighSpeedTime.
  ///
  /// In fr, this message translates to:
  /// **'Haute vitesse'**
  String get statsHighSpeedTime;

  /// No description provided for @statsHighSpeedTimeShort.
  ///
  /// In fr, this message translates to:
  /// **'Tps haute vitesse'**
  String get statsHighSpeedTimeShort;

  /// No description provided for @statsMaxAccel.
  ///
  /// In fr, this message translates to:
  /// **'Acc. max'**
  String get statsMaxAccel;

  /// No description provided for @statsAxisSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse (km/h)'**
  String get statsAxisSpeed;

  /// No description provided for @statsAxisTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps (s)'**
  String get statsAxisTime;

  /// No description provided for @statsAxisAcceleration.
  ///
  /// In fr, this message translates to:
  /// **'Accélération (m/s²)'**
  String get statsAxisAcceleration;

  /// No description provided for @statsScore.
  ///
  /// In fr, this message translates to:
  /// **'score'**
  String get statsScore;

  /// No description provided for @statsPlayersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} joueurs'**
  String statsPlayersCount(int count);

  /// No description provided for @statsAvgWorkload.
  ///
  /// In fr, this message translates to:
  /// **'Charge Moy. {value}'**
  String statsAvgWorkload(String value);

  /// No description provided for @statsAvgDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance Moy. {value}'**
  String statsAvgDistance(String value);

  /// No description provided for @statsAvgMaxSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse max Moy. {value}'**
  String statsAvgMaxSpeed(String value);

  /// No description provided for @statsZScore.
  ///
  /// In fr, this message translates to:
  /// **'zScore {sign}{value}'**
  String statsZScore(String sign, String value);

  /// No description provided for @statsMaxAccelSample.
  ///
  /// In fr, this message translates to:
  /// **'Accélération max: 4m/s2'**
  String get statsMaxAccelSample;

  /// No description provided for @speedZoneWalk.
  ///
  /// In fr, this message translates to:
  /// **'Marche'**
  String get speedZoneWalk;

  /// No description provided for @speedZoneJogging.
  ///
  /// In fr, this message translates to:
  /// **'Jogging'**
  String get speedZoneJogging;

  /// No description provided for @speedZoneRun.
  ///
  /// In fr, this message translates to:
  /// **'Course'**
  String get speedZoneRun;

  /// No description provided for @speedZoneHighIntensity.
  ///
  /// In fr, this message translates to:
  /// **'Haute intensité'**
  String get speedZoneHighIntensity;

  /// No description provided for @speedZoneSprint.
  ///
  /// In fr, this message translates to:
  /// **'Sprint'**
  String get speedZoneSprint;

  /// No description provided for @highlightKickoff.
  ///
  /// In fr, this message translates to:
  /// **'Coup d’envoi'**
  String get highlightKickoff;

  /// No description provided for @highlightFullTime.
  ///
  /// In fr, this message translates to:
  /// **'Fin du match'**
  String get highlightFullTime;

  /// No description provided for @substitutionOut.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get substitutionOut;

  /// No description provided for @substitutionIn.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get substitutionIn;

  /// No description provided for @teamParamsPerformanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres performance'**
  String get teamParamsPerformanceTitle;

  /// No description provided for @teamParamsSpeedSprints.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse & sprints'**
  String get teamParamsSpeedSprints;

  /// No description provided for @teamParamsIntensity.
  ///
  /// In fr, this message translates to:
  /// **'Intensité'**
  String get teamParamsIntensity;

  /// No description provided for @teamParamsGpsTimeline.
  ///
  /// In fr, this message translates to:
  /// **'GPS / validation / timeline'**
  String get teamParamsGpsTimeline;

  /// No description provided for @teamParamsSpeedZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones de vitesse'**
  String get teamParamsSpeedZones;

  /// No description provided for @teamParamsMinOneZone.
  ///
  /// In fr, this message translates to:
  /// **'Il faut conserver au moins une zone.'**
  String get teamParamsMinOneZone;

  /// No description provided for @teamParamsAddSpeedZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins une zone de vitesse.'**
  String get teamParamsAddSpeedZone;

  /// No description provided for @teamParamsSprintThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil sprint (km/h)'**
  String get teamParamsSprintThreshold;

  /// No description provided for @teamParamsSprintMinAccel.
  ///
  /// In fr, this message translates to:
  /// **'Accélération mini pour sprint'**
  String get teamParamsSprintMinAccel;

  /// No description provided for @teamParamsSprintMinDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée mini sprint'**
  String get teamParamsSprintMinDuration;

  /// No description provided for @teamParamsSpeedMinDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée mini vitesse validée'**
  String get teamParamsSpeedMinDuration;

  /// No description provided for @teamParamsHighAccelThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil forte accélération'**
  String get teamParamsHighAccelThreshold;

  /// No description provided for @teamParamsHighAccelMinDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée mini forte accélération'**
  String get teamParamsHighAccelMinDuration;

  /// No description provided for @teamParamsMaxStepDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance max acceptée par pas'**
  String get teamParamsMaxStepDistance;

  /// No description provided for @teamParamsMaxPlausibleSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse max plausible'**
  String get teamParamsMaxPlausibleSpeed;

  /// No description provided for @teamParamsMaxPlausibleAccel.
  ///
  /// In fr, this message translates to:
  /// **'Accélération max plausible'**
  String get teamParamsMaxPlausibleAccel;

  /// No description provided for @teamParamsMinDeltaTime.
  ///
  /// In fr, this message translates to:
  /// **'Delta temps mini'**
  String get teamParamsMinDeltaTime;

  /// No description provided for @teamParamsMaxDeltaTime.
  ///
  /// In fr, this message translates to:
  /// **'Delta temps maxi'**
  String get teamParamsMaxDeltaTime;

  /// No description provided for @teamParamsSmoothingWindow.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre de lissage'**
  String get teamParamsSmoothingWindow;

  /// No description provided for @teamParamsTimelineBucket.
  ///
  /// In fr, this message translates to:
  /// **'Bucket timeline'**
  String get teamParamsTimelineBucket;

  /// No description provided for @teamMembersPlayers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 joueurs} =1{1 joueur} other{{count} joueurs}}'**
  String teamMembersPlayers(int count);

  /// No description provided for @teamMembersStaff.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 staff} =1{1 staff} other{{count} staffs}}'**
  String teamMembersStaff(int count);

  /// No description provided for @fieldTooltipZoomIn.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir tout le terrain'**
  String get fieldTooltipZoomIn;

  /// No description provided for @fieldTooltipZoomOut.
  ///
  /// In fr, this message translates to:
  /// **'Réduire tout le terrain'**
  String get fieldTooltipZoomOut;

  /// No description provided for @fieldTooltipLengthUp.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter la longueur'**
  String get fieldTooltipLengthUp;

  /// No description provided for @fieldTooltipLengthDown.
  ///
  /// In fr, this message translates to:
  /// **'Réduire la longueur'**
  String get fieldTooltipLengthDown;

  /// No description provided for @fieldTooltipWidthUp.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter la largeur'**
  String get fieldTooltipWidthUp;

  /// No description provided for @fieldTooltipWidthDown.
  ///
  /// In fr, this message translates to:
  /// **'Réduire la largeur'**
  String get fieldTooltipWidthDown;

  /// No description provided for @fieldTooltipRotateLeft.
  ///
  /// In fr, this message translates to:
  /// **'Tourner à gauche'**
  String get fieldTooltipRotateLeft;

  /// No description provided for @fieldTooltipRotateRight.
  ///
  /// In fr, this message translates to:
  /// **'Tourner à droite'**
  String get fieldTooltipRotateRight;

  /// No description provided for @fieldTooltipMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get fieldTooltipMap;

  /// No description provided for @fieldTooltipSatellite.
  ///
  /// In fr, this message translates to:
  /// **'Satellite'**
  String get fieldTooltipSatellite;

  /// No description provided for @fieldLocateCorners.
  ///
  /// In fr, this message translates to:
  /// **'Localiser les coins'**
  String get fieldLocateCorners;

  /// No description provided for @fieldSnackbarLocationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La localisation est désactivée.'**
  String get fieldSnackbarLocationDisabled;

  /// No description provided for @fieldSnackbarAllowLocation.
  ///
  /// In fr, this message translates to:
  /// **'Autorise la localisation pour centrer la carte.'**
  String get fieldSnackbarAllowLocation;

  /// No description provided for @fieldSnackbarGpsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer la position actuelle.'**
  String get fieldSnackbarGpsFailed;

  /// No description provided for @fieldSnackbarEnterAddress.
  ///
  /// In fr, this message translates to:
  /// **'Saisis une adresse ou un nom de stade.'**
  String get fieldSnackbarEnterAddress;

  /// No description provided for @fieldSnackbarMapNotReady.
  ///
  /// In fr, this message translates to:
  /// **'La carte n’est pas encore prête.'**
  String get fieldSnackbarMapNotReady;

  /// No description provided for @fieldSnackbarAddressNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Adresse introuvable.'**
  String get fieldSnackbarAddressNotFound;

  /// No description provided for @fieldSnackbarAddressNotFoundWithStatus.
  ///
  /// In fr, this message translates to:
  /// **'Adresse introuvable : {status}'**
  String fieldSnackbarAddressNotFoundWithStatus(String status);

  /// No description provided for @fieldSnackbarGeocodingFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de rechercher cette adresse. Vérifie la clé et l’API Geocoding.'**
  String get fieldSnackbarGeocodingFailed;

  /// No description provided for @fieldSnackbarPlaceInMap.
  ///
  /// In fr, this message translates to:
  /// **'Place le terrain entièrement dans la carte.'**
  String get fieldSnackbarPlaceInMap;

  /// No description provided for @fieldSnackbarGpsConvertFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de convertir les coins en positions GPS.'**
  String get fieldSnackbarGpsConvertFailed;

  /// No description provided for @fieldHelpGestures.
  ///
  /// In fr, this message translates to:
  /// **'Terrain : glisser déplacer • 2 doigts zoom/tourner • trackpad : scroll zoom, ⇧ tourner, ⌥ largeur, ⇧⌥ longueur'**
  String get fieldHelpGestures;

  /// No description provided for @compoNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Composition non renseignée'**
  String get compoNotFoundTitle;

  /// No description provided for @compoTypeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune composition'**
  String get compoTypeEmptyTitle;

  /// No description provided for @matchStatsUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques indisponibles'**
  String get matchStatsUnavailableTitle;

  /// No description provided for @sensorNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Capteur non trouvé'**
  String get sensorNotFoundTitle;

  /// No description provided for @sensorNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capteur n’est associé à ce joueur pour ce match.'**
  String get sensorNotFoundMessage;

  /// No description provided for @matchHomeJersey.
  ///
  /// In fr, this message translates to:
  /// **'Maillot domicile'**
  String get matchHomeJersey;

  /// No description provided for @matchCartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier'**
  String get matchCartTitle;

  /// No description provided for @matchCartOneItem.
  ///
  /// In fr, this message translates to:
  /// **'1 article - 49,90 €'**
  String get matchCartOneItem;

  /// No description provided for @asiSelectFile.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un fichier .asi'**
  String get asiSelectFile;

  /// No description provided for @asiEnterDeviceId.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le deviceId'**
  String get asiEnterDeviceId;

  /// No description provided for @asiCannotReadFile.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le fichier sélectionné'**
  String get asiCannotReadFile;

  /// No description provided for @asiFileMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier ne correspond pas au tracker sélectionné'**
  String get asiFileMismatch;

  /// No description provided for @asiTrackerUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Tracker non reconnu'**
  String get asiTrackerUnknown;

  /// No description provided for @asiFilePickError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection du fichier : {details}'**
  String asiFilePickError(String details);

  /// No description provided for @asiConversionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur pendant la conversion : {details}'**
  String asiConversionError(String details);

  /// No description provided for @asiAnalysisFailed.
  ///
  /// In fr, this message translates to:
  /// **'Analyse impossible'**
  String get asiAnalysisFailed;

  /// No description provided for @playerSynthesisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse joueur'**
  String get playerSynthesisTitle;

  /// No description provided for @playerSynthesisTabTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse'**
  String get playerSynthesisTabTitle;

  /// No description provided for @teamsListCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} équipe(s)'**
  String teamsListCount(int count);

  /// No description provided for @teamsListCountFiltered.
  ///
  /// In fr, this message translates to:
  /// **'{filtered} / {total}'**
  String teamsListCountFiltered(int filtered, int total);

  /// No description provided for @teamsListNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe trouvée'**
  String get teamsListNoResults;

  /// No description provided for @teamsListNoTeams.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe disponible'**
  String get teamsListNoTeams;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @myTeams.
  ///
  /// In fr, this message translates to:
  /// **'Mes équipes'**
  String get myTeams;

  /// No description provided for @syncTrainingsToSync.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements à synchroniser'**
  String get syncTrainingsToSync;

  /// No description provided for @chatSelectConversation.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne une conversation'**
  String get chatSelectConversation;

  /// No description provided for @chatStartNewHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur \"Nouveau\" pour démarrer un chat.'**
  String get chatStartNewHint;

  /// No description provided for @chatTryAnotherName.
  ///
  /// In fr, this message translates to:
  /// **'Essaie avec un autre nom.'**
  String get chatTryAnotherName;

  /// No description provided for @chatUsersAppearHere.
  ///
  /// In fr, this message translates to:
  /// **'Les autres utilisateurs apparaîtront ici.'**
  String get chatUsersAppearHere;

  /// No description provided for @matchDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail du match'**
  String get matchDetailTitle;

  /// No description provided for @matchDetailVenueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieu du match'**
  String get matchDetailVenueTitle;

  /// No description provided for @matchDetailTrackerKitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélection du kit'**
  String get matchDetailTrackerKitTitle;

  /// No description provided for @matchDetailTrackerKitLabel.
  ///
  /// In fr, this message translates to:
  /// **'Trackers'**
  String get matchDetailTrackerKitLabel;

  /// No description provided for @matchDetailTrackerKitComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get matchDetailTrackerKitComingSoon;

  /// No description provided for @matchDetailTrackerKitWithTracker.
  ///
  /// In fr, this message translates to:
  /// **'Avec tracker'**
  String get matchDetailTrackerKitWithTracker;

  /// No description provided for @matchDetailTrackerKitWithoutTracker.
  ///
  /// In fr, this message translates to:
  /// **'Sans tracker'**
  String get matchDetailTrackerKitWithoutTracker;

  /// No description provided for @matchDetailTrackerKitSelectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Kit'**
  String get matchDetailTrackerKitSelectLabel;

  /// No description provided for @matchDetailTrackerKitNoOwners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun kit configuré pour cette équipe.'**
  String get matchDetailTrackerKitNoOwners;

  /// No description provided for @matchDetailTrackerKitSignInRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour sélectionner un kit.'**
  String get matchDetailTrackerKitSignInRequired;

  /// No description provided for @playerAgeYears.
  ///
  /// In fr, this message translates to:
  /// **'{age} ans'**
  String playerAgeYears(int age);

  /// No description provided for @playerAgeUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Âge non renseigné'**
  String get playerAgeUnknown;

  /// No description provided for @dateUndefined.
  ///
  /// In fr, this message translates to:
  /// **'Date non définie'**
  String get dateUndefined;

  /// No description provided for @matchDateTimeAt.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String matchDateTimeAt(String date, String time);

  /// No description provided for @entityComposition.
  ///
  /// In fr, this message translates to:
  /// **'Composition'**
  String get entityComposition;

  /// No description provided for @entityDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get entityDetails;

  /// No description provided for @entityHeatmap.
  ///
  /// In fr, this message translates to:
  /// **'Heatmap'**
  String get entityHeatmap;

  /// No description provided for @entityPeriods.
  ///
  /// In fr, this message translates to:
  /// **'Périodes'**
  String get entityPeriods;

  /// No description provided for @tabHighlightsShort.
  ///
  /// In fr, this message translates to:
  /// **'Temps'**
  String get tabHighlightsShort;

  /// No description provided for @emptyNoHighlightsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les buts, cartons et changements apparaîtront ici.'**
  String get emptyNoHighlightsMessage;

  /// No description provided for @highlightTypeGoal.
  ///
  /// In fr, this message translates to:
  /// **'But'**
  String get highlightTypeGoal;

  /// No description provided for @highlightTypeSubstitution.
  ///
  /// In fr, this message translates to:
  /// **'Changement'**
  String get highlightTypeSubstitution;

  /// No description provided for @highlightTypeYellowCard.
  ///
  /// In fr, this message translates to:
  /// **'Carton jaune'**
  String get highlightTypeYellowCard;

  /// No description provided for @highlightTypeRedCard.
  ///
  /// In fr, this message translates to:
  /// **'Carton rouge'**
  String get highlightTypeRedCard;

  /// No description provided for @highlightTypeOwnGoal.
  ///
  /// In fr, this message translates to:
  /// **'But contre son camp'**
  String get highlightTypeOwnGoal;

  /// No description provided for @highlightTypePenalty.
  ///
  /// In fr, this message translates to:
  /// **'Penalty'**
  String get highlightTypePenalty;

  /// No description provided for @highlightTypeGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Temps fort'**
  String get highlightTypeGeneric;

  /// No description provided for @highlightSubstitutionOut.
  ///
  /// In fr, this message translates to:
  /// **'{player} sort'**
  String highlightSubstitutionOut(String player);

  /// No description provided for @highlightSubstitutionIn.
  ///
  /// In fr, this message translates to:
  /// **'{incoming} remplace {outgoing}'**
  String highlightSubstitutionIn(String incoming, String outgoing);

  /// No description provided for @errorNoPlayersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur'**
  String get errorNoPlayersTitle;

  /// No description provided for @matchTrackerDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Les données tracker sont disponibles.'**
  String get matchTrackerDataAvailable;

  /// No description provided for @matchTrackerDataPending.
  ///
  /// In fr, this message translates to:
  /// **'Les données tracker ne sont pas encore importées.'**
  String get matchTrackerDataPending;

  /// No description provided for @errorPlayerNoTrackerMatch.
  ///
  /// In fr, this message translates to:
  /// **'Ce joueur n’a pas de données tracker pour ce match.'**
  String get errorPlayerNoTrackerMatch;

  /// No description provided for @trackerSyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation des capteurs'**
  String get trackerSyncTitle;

  /// No description provided for @trackerAvailableSensors.
  ///
  /// In fr, this message translates to:
  /// **'Capteurs disponibles'**
  String get trackerAvailableSensors;

  /// No description provided for @trackerCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} tracker(s)'**
  String trackerCount(int count);

  /// No description provided for @trackerAlreadySyncedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation déjà effectuée'**
  String get trackerAlreadySyncedTitle;

  /// No description provided for @trackerAlreadySyncedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le capteur a déjà été synchronisé pour cette session.'**
  String get trackerAlreadySyncedMessage;

  /// No description provided for @trackerStatusSelected.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionné'**
  String get trackerStatusSelected;

  /// No description provided for @trackerStatusSynced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get trackerStatusSynced;

  /// No description provided for @trackerStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get trackerStatusOpen;

  /// No description provided for @trackerSelectForActions.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne un tracker pour afficher les actions de connexion, téléchargement et effacement.'**
  String get trackerSelectForActions;

  /// No description provided for @trackerSelectedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tracker sélectionné'**
  String get trackerSelectedLabel;

  /// No description provided for @trackerLogsPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Les logs apparaîtront ici.'**
  String get trackerLogsPlaceholder;

  /// No description provided for @trackerNoDataOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée sur ce capteur.'**
  String get trackerNoDataOnDevice;

  /// No description provided for @trackerNoDataOnDeviceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Capteur connecté — aucune séance à importer'**
  String get trackerNoDataOnDeviceTitle;

  /// No description provided for @trackerNoDataOnDeviceDetails.
  ///
  /// In fr, this message translates to:
  /// **'Le capteur a confirmé 0 octet de séance (pas une erreur de connexion). Activité non enregistrée sur le pod, ou données déjà effacées. Enregistrez une séance sur l’Inspirit, puis recliquez « Télécharger ».'**
  String get trackerNoDataOnDeviceDetails;

  /// No description provided for @trackerDownloadFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement'**
  String get trackerDownloadFailedTitle;

  /// No description provided for @trackerDownloadBusyHint.
  ///
  /// In fr, this message translates to:
  /// **'Assurez-vous qu’aucune autre instance de Grinta soit ouverte.'**
  String get trackerDownloadBusyHint;

  /// No description provided for @trackerDownloadPrepareSession.
  ///
  /// In fr, this message translates to:
  /// **'Préparation USB avant téléchargement (équivalent Déconnecter puis Connecter)…'**
  String get trackerDownloadPrepareSession;

  /// No description provided for @uploadTrackerLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get uploadTrackerLoading;

  /// No description provided for @uploadTrackerDownloadData.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger les données'**
  String get uploadTrackerDownloadData;

  /// No description provided for @syncFieldGeolocationPromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Géolocaliser le terrain ?'**
  String get syncFieldGeolocationPromptTitle;

  /// No description provided for @syncFieldGeolocationPromptMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les coordonnées GPS du terrain ne sont pas renseignées. Souhaitez-vous les définir avant de télécharger les données tracker ?'**
  String get syncFieldGeolocationPromptMessage;

  /// No description provided for @trackerUsbAuthorizeHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucun Inspirit autorisé pour ce site. Une fenêtre Chrome va s’ouvrir : cliquez sur « Inspirit_00 » (ou votre modèle), puis le bouton « Connecter » — ne fermez pas la fenêtre.'**
  String get trackerUsbAuthorizeHint;

  /// No description provided for @trackerUsbPopupCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Popup Chrome fermée ou aucun appareil choisi. Branchez le tracker, recliquez « Connecter » et sélectionnez-le dans la liste.'**
  String get trackerUsbPopupCancelled;

  /// No description provided for @trackerUsbPhysicalReconnect.
  ///
  /// In fr, this message translates to:
  /// **'Session USB expirée (câble débranché ou capteur réinitialisé). Rebranchez le tracker si besoin, puis recliquez « Connecter » — une fenêtre Chrome peut s’ouvrir pour le resélectionner.'**
  String get trackerUsbPhysicalReconnect;

  /// No description provided for @trackerDeviceName.
  ///
  /// In fr, this message translates to:
  /// **'Périphérique : {name}'**
  String trackerDeviceName(String name);

  /// No description provided for @asiImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier .asi'**
  String get asiImportTitle;

  /// No description provided for @asiImportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne un fichier, vérifie le deviceId, puis lance la conversion.'**
  String get asiImportSubtitle;

  /// No description provided for @asiFileSelectedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fichier sélectionné'**
  String get asiFileSelectedLabel;

  /// No description provided for @asiImportFileHeader.
  ///
  /// In fr, this message translates to:
  /// **'Import fichier ASI'**
  String get asiImportFileHeader;

  /// No description provided for @actionConvertToCsv.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en CSV'**
  String get actionConvertToCsv;

  /// No description provided for @asiConverting.
  ///
  /// In fr, this message translates to:
  /// **'Conversion en cours...'**
  String get asiConverting;

  /// No description provided for @asiPeriodsOne.
  ///
  /// In fr, this message translates to:
  /// **'1 période transmise'**
  String get asiPeriodsOne;

  /// No description provided for @asiPeriodsMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} période(s) transmise(s) - les 2 premières seront utilisées pour les mi-temps'**
  String asiPeriodsMany(int count);

  /// No description provided for @statsUnitKm.
  ///
  /// In fr, this message translates to:
  /// **'km'**
  String get statsUnitKm;

  /// No description provided for @statsUnitKmh.
  ///
  /// In fr, this message translates to:
  /// **'km/h'**
  String get statsUnitKmh;

  /// No description provided for @statsUnitCount.
  ///
  /// In fr, this message translates to:
  /// **'nb'**
  String get statsUnitCount;

  /// No description provided for @statsUnitSeconds.
  ///
  /// In fr, this message translates to:
  /// **'sec'**
  String get statsUnitSeconds;

  /// No description provided for @statsUnitMps2.
  ///
  /// In fr, this message translates to:
  /// **'m/s²'**
  String get statsUnitMps2;

  /// No description provided for @loadingSession.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la session...'**
  String get loadingSession;

  /// No description provided for @loadingStats.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des statistiques...'**
  String get loadingStats;

  /// No description provided for @dashboardMyManagedTeams.
  ///
  /// In fr, this message translates to:
  /// **'Mes équipes managées'**
  String get dashboardMyManagedTeams;

  /// No description provided for @dashboardMatchListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Liste des matchs'**
  String get dashboardMatchListTitle;

  /// No description provided for @periodCustomRange.
  ///
  /// In fr, this message translates to:
  /// **'du {start} au {end}'**
  String periodCustomRange(String start, String end);

  /// No description provided for @statsPresenceRate.
  ///
  /// In fr, this message translates to:
  /// **'Tx de présence: ({value}) %'**
  String statsPresenceRate(String value);

  /// No description provided for @statsDoneSingular.
  ///
  /// In fr, this message translates to:
  /// **'réalisé'**
  String get statsDoneSingular;

  /// No description provided for @statsDonePlural.
  ///
  /// In fr, this message translates to:
  /// **'réalisés'**
  String get statsDonePlural;

  /// No description provided for @statsPlannedSingular.
  ///
  /// In fr, this message translates to:
  /// **'planifié'**
  String get statsPlannedSingular;

  /// No description provided for @statsPlannedPlural.
  ///
  /// In fr, this message translates to:
  /// **'planifiés'**
  String get statsPlannedPlural;

  /// No description provided for @actionDayPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Jour précédent'**
  String get actionDayPrevious;

  /// No description provided for @actionDayNext.
  ///
  /// In fr, this message translates to:
  /// **'Jour suivant'**
  String get actionDayNext;

  /// No description provided for @actionMonthPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get actionMonthPrevious;

  /// No description provided for @actionMonthNext.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get actionMonthNext;

  /// No description provided for @actionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get actionSave;

  /// No description provided for @actionSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get actionSaving;

  /// No description provided for @periodLoaded.
  ///
  /// In fr, this message translates to:
  /// **'Période chargée : {range}'**
  String periodLoaded(String range);

  /// No description provided for @agendaLegend.
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get agendaLegend;

  /// No description provided for @agendaOverviewEventsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement} other{{count} événements}}'**
  String agendaOverviewEventsCount(int count);

  /// No description provided for @agendaEventSummaryMatches.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matchs}}'**
  String agendaEventSummaryMatches(int count);

  /// No description provided for @agendaEventSummaryTrainings.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 entraînement} other{{count} entraînements}}'**
  String agendaEventSummaryTrainings(int count);

  /// No description provided for @agendaEventSummaryPrepas.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 prépa} other{{count} prépas}}'**
  String agendaEventSummaryPrepas(int count);

  /// No description provided for @agendaTrackerStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques tracker'**
  String get agendaTrackerStatsTitle;

  /// No description provided for @teamDetailBackToTeams.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux équipes'**
  String get teamDetailBackToTeams;

  /// No description provided for @teamDetailAverageAge.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne d\'âge: {age} ans'**
  String teamDetailAverageAge(String age);

  /// No description provided for @teamDetailConfirmDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get teamDetailConfirmDeleteTitle;

  /// No description provided for @teamDetailConfirmRemoveStaff.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez-vous la suppression du staff de {playerName} ?'**
  String teamDetailConfirmRemoveStaff(String playerName);

  /// No description provided for @teamDetailConfirmRemovePlayerTeam.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez-vous la suppression de l\'équipe du joueur {playerName} ?'**
  String teamDetailConfirmRemovePlayerTeam(String playerName);

  /// No description provided for @teamDetailPlayerRemoved.
  ///
  /// In fr, this message translates to:
  /// **'{playerName} a été supprimé.'**
  String teamDetailPlayerRemoved(String playerName);

  /// No description provided for @teamDetailPlayerTeamRemoved.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe du joueur {playerName} a été supprimé.'**
  String teamDetailPlayerTeamRemoved(String playerName);

  /// No description provided for @teamDetailColumnAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get teamDetailColumnAge;

  /// No description provided for @teamDetailColumnPosition.
  ///
  /// In fr, this message translates to:
  /// **'Poste'**
  String get teamDetailColumnPosition;

  /// No description provided for @teamDetailColumnHeight.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get teamDetailColumnHeight;

  /// No description provided for @teamDetailColumnWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get teamDetailColumnWeight;

  /// No description provided for @teamDetailHeightCm.
  ///
  /// In fr, this message translates to:
  /// **'{value} cm'**
  String teamDetailHeightCm(int value);

  /// No description provided for @teamDetailWeightKg.
  ///
  /// In fr, this message translates to:
  /// **'{value} kg'**
  String teamDetailWeightKg(int value);

  /// No description provided for @teamDetailConfirmRemoveTracker.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer l\'affectation du tracker « {trackerName} » ?'**
  String teamDetailConfirmRemoveTracker(String trackerName);

  /// No description provided for @roleCoach.
  ///
  /// In fr, this message translates to:
  /// **'Coach'**
  String get roleCoach;

  /// No description provided for @roleExecutive.
  ///
  /// In fr, this message translates to:
  /// **'Dirigeant'**
  String get roleExecutive;

  /// No description provided for @grintaStaffRoleEducator.
  ///
  /// In fr, this message translates to:
  /// **'Entraîneur / Éducateur'**
  String get grintaStaffRoleEducator;

  /// No description provided for @grintaStaffRoleMedical.
  ///
  /// In fr, this message translates to:
  /// **'Médical'**
  String get grintaStaffRoleMedical;

  /// No description provided for @grintaStaffRoleExecutive.
  ///
  /// In fr, this message translates to:
  /// **'Dirigeant'**
  String get grintaStaffRoleExecutive;

  /// No description provided for @addStaffRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fonction'**
  String get addStaffRoleLabel;

  /// No description provided for @addStaffRoleHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une fonction'**
  String get addStaffRoleHint;

  /// No description provided for @addStaffRoleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir une fonction'**
  String get addStaffRoleRequired;

  /// No description provided for @positionEducator.
  ///
  /// In fr, this message translates to:
  /// **'Educateur/Entraineur'**
  String get positionEducator;

  /// No description provided for @positionExecutive.
  ///
  /// In fr, this message translates to:
  /// **'Dirigeant'**
  String get positionExecutive;

  /// No description provided for @positionGoalkeeper.
  ///
  /// In fr, this message translates to:
  /// **'Gardien'**
  String get positionGoalkeeper;

  /// No description provided for @positionCenterBack.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur central'**
  String get positionCenterBack;

  /// No description provided for @positionCenterBackLeft.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur central gauche'**
  String get positionCenterBackLeft;

  /// No description provided for @positionCenterBackRight.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur central droit'**
  String get positionCenterBackRight;

  /// No description provided for @positionLeftDefender.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur gauche'**
  String get positionLeftDefender;

  /// No description provided for @positionRightDefender.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur droit'**
  String get positionRightDefender;

  /// No description provided for @positionLeftBack.
  ///
  /// In fr, this message translates to:
  /// **'Latéral gauche'**
  String get positionLeftBack;

  /// No description provided for @positionRightBack.
  ///
  /// In fr, this message translates to:
  /// **'Latéral droit'**
  String get positionRightBack;

  /// No description provided for @positionLeftPiston.
  ///
  /// In fr, this message translates to:
  /// **'Piston gauche'**
  String get positionLeftPiston;

  /// No description provided for @positionRightPiston.
  ///
  /// In fr, this message translates to:
  /// **'Piston droit'**
  String get positionRightPiston;

  /// No description provided for @positionDefensiveMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu défensif'**
  String get positionDefensiveMidfielder;

  /// No description provided for @positionCentralMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu central'**
  String get positionCentralMidfielder;

  /// No description provided for @positionBoxToBoxMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu relayeur'**
  String get positionBoxToBoxMidfielder;

  /// No description provided for @positionLeftMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu gauche'**
  String get positionLeftMidfielder;

  /// No description provided for @positionRightMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu droit'**
  String get positionRightMidfielder;

  /// No description provided for @positionAttackingMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu offensif'**
  String get positionAttackingMidfielder;

  /// No description provided for @positionPlaymaker.
  ///
  /// In fr, this message translates to:
  /// **'Meneur de jeu'**
  String get positionPlaymaker;

  /// No description provided for @positionLeftWinger.
  ///
  /// In fr, this message translates to:
  /// **'Ailier gauche'**
  String get positionLeftWinger;

  /// No description provided for @positionRightWinger.
  ///
  /// In fr, this message translates to:
  /// **'Ailier droit'**
  String get positionRightWinger;

  /// No description provided for @positionSecondStriker.
  ///
  /// In fr, this message translates to:
  /// **'Second attaquant'**
  String get positionSecondStriker;

  /// No description provided for @positionCenterForward.
  ///
  /// In fr, this message translates to:
  /// **'Avant-centre'**
  String get positionCenterForward;

  /// No description provided for @positionStriker.
  ///
  /// In fr, this message translates to:
  /// **'Buteur'**
  String get positionStriker;

  /// No description provided for @positionAttacker.
  ///
  /// In fr, this message translates to:
  /// **'Attaquant'**
  String get positionAttacker;

  /// No description provided for @positionDefender.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur'**
  String get positionDefender;

  /// No description provided for @positionMidfielder.
  ///
  /// In fr, this message translates to:
  /// **'Milieu'**
  String get positionMidfielder;

  /// No description provided for @positionForward.
  ///
  /// In fr, this message translates to:
  /// **'Attaquant'**
  String get positionForward;

  /// No description provided for @teamParamsCustomThresholds.
  ///
  /// In fr, this message translates to:
  /// **'Seuils personnalisés'**
  String get teamParamsCustomThresholds;

  /// No description provided for @teamParamsDefaultThresholds.
  ///
  /// In fr, this message translates to:
  /// **'Seuils par défaut'**
  String get teamParamsDefaultThresholds;

  /// No description provided for @teamParamsBackToTeam.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'équipe'**
  String get teamParamsBackToTeam;

  /// No description provided for @teamParamsDeleteCustomizationBody.
  ///
  /// In fr, this message translates to:
  /// **'Les paramètres spécifiques de cette équipe seront supprimés. L\'équipe utilisera alors les paramètres par défaut.'**
  String get teamParamsDeleteCustomizationBody;

  /// No description provided for @teamParamsCustomizationRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation supprimée. Les paramètres par défaut seront utilisés.'**
  String get teamParamsCustomizationRemoved;

  /// No description provided for @teamParamsZoneMaxGreaterThanMin.
  ///
  /// In fr, this message translates to:
  /// **'La zone \"{label}\" doit avoir une borne max supérieure à la borne min.'**
  String teamParamsZoneMaxGreaterThanMin(String label);

  /// No description provided for @teamParamsOnlyLastZoneEmptyMax.
  ///
  /// In fr, this message translates to:
  /// **'Seule la dernière zone peut avoir une borne max vide.'**
  String get teamParamsOnlyLastZoneEmptyMax;

  /// No description provided for @teamParamsZonesOverlap.
  ///
  /// In fr, this message translates to:
  /// **'Les zones \"{zoneA}\" et \"{zoneB}\" se chevauchent.'**
  String teamParamsZonesOverlap(String zoneA, String zoneB);

  /// No description provided for @teamParamsCustomizeZonesHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux personnaliser librement les zones utilisées pour le calcul du temps passé dans chaque zone.'**
  String get teamParamsCustomizeZonesHint;

  /// No description provided for @teamParamsZonesReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule : les zones de vitesse ne sont pas modifiables.'**
  String get teamParamsZonesReadOnly;

  /// No description provided for @teamParamsInvalidInteger.
  ///
  /// In fr, this message translates to:
  /// **'Valeur entière invalide'**
  String get teamParamsInvalidInteger;

  /// No description provided for @teamParamsInvalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Valeur numérique invalide'**
  String get teamParamsInvalidNumber;

  /// No description provided for @teamParamsZoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zone {index}'**
  String teamParamsZoneTitle(int index);

  /// No description provided for @hintRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get hintRequiredField;

  /// No description provided for @fieldSnackbarGoogleMapsKeyMissing.
  ///
  /// In fr, this message translates to:
  /// **'Clé Google Maps manquante pour la recherche d\'adresse.'**
  String get fieldSnackbarGoogleMapsKeyMissing;

  /// No description provided for @fieldMapModeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Mode carte : déplace ou zoome la carte'**
  String get fieldMapModeHelp;

  /// No description provided for @fieldSideLeft.
  ///
  /// In fr, this message translates to:
  /// **'Côté gauche'**
  String get fieldSideLeft;

  /// No description provided for @fieldSideRight.
  ///
  /// In fr, this message translates to:
  /// **'Côté droit'**
  String get fieldSideRight;

  /// No description provided for @fieldEstimatedAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse estimée'**
  String get fieldEstimatedAddress;

  /// No description provided for @fieldAddressUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Adresse postale indisponible pour cette position.'**
  String get fieldAddressUnavailable;

  /// No description provided for @fieldGpsPositionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Positions GPS du terrain'**
  String get fieldGpsPositionsTitle;

  /// No description provided for @fieldAverageLength.
  ///
  /// In fr, this message translates to:
  /// **'Longueur moyenne'**
  String get fieldAverageLength;

  /// No description provided for @fieldAverageWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur moyenne'**
  String get fieldAverageWidth;

  /// No description provided for @trackerParamDefault.
  ///
  /// In fr, this message translates to:
  /// **'Param défaut'**
  String get trackerParamDefault;

  /// No description provided for @trackerParamTeam.
  ///
  /// In fr, this message translates to:
  /// **'Param équipe {teamId}'**
  String trackerParamTeam(String teamId);

  /// No description provided for @halfFirst.
  ///
  /// In fr, this message translates to:
  /// **'1ère mi-temps'**
  String get halfFirst;

  /// No description provided for @halfSecond.
  ///
  /// In fr, this message translates to:
  /// **'2ème mi-temps'**
  String get halfSecond;

  /// No description provided for @halfNth.
  ///
  /// In fr, this message translates to:
  /// **'{index}ème mi-temps'**
  String halfNth(int index);

  /// No description provided for @halfFirstShort.
  ///
  /// In fr, this message translates to:
  /// **'1ère'**
  String get halfFirstShort;

  /// No description provided for @halfSecondShort.
  ///
  /// In fr, this message translates to:
  /// **'2ème'**
  String get halfSecondShort;

  /// No description provided for @halfMatchShort.
  ///
  /// In fr, this message translates to:
  /// **'Match'**
  String get halfMatchShort;

  /// No description provided for @tabSpeedZonesShort.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get tabSpeedZonesShort;

  /// No description provided for @fieldZoneAttackLeftShort.
  ///
  /// In fr, this message translates to:
  /// **'Att. gauche'**
  String get fieldZoneAttackLeftShort;

  /// No description provided for @fieldZoneAttackRightShort.
  ///
  /// In fr, this message translates to:
  /// **'Att. droite'**
  String get fieldZoneAttackRightShort;

  /// No description provided for @fieldZoneMidLeftShort.
  ///
  /// In fr, this message translates to:
  /// **'Mil. gauche'**
  String get fieldZoneMidLeftShort;

  /// No description provided for @fieldZoneMidRightShort.
  ///
  /// In fr, this message translates to:
  /// **'Mil. droite'**
  String get fieldZoneMidRightShort;

  /// No description provided for @fieldZoneDefenseLeftShort.
  ///
  /// In fr, this message translates to:
  /// **'Déf. gauche'**
  String get fieldZoneDefenseLeftShort;

  /// No description provided for @fieldZoneDefenseRightShort.
  ///
  /// In fr, this message translates to:
  /// **'Déf. droite'**
  String get fieldZoneDefenseRightShort;

  /// No description provided for @fieldZoneAttackLeft.
  ///
  /// In fr, this message translates to:
  /// **'Attaque gauche'**
  String get fieldZoneAttackLeft;

  /// No description provided for @fieldZoneAttackRight.
  ///
  /// In fr, this message translates to:
  /// **'Attaque droite'**
  String get fieldZoneAttackRight;

  /// No description provided for @fieldZoneMidLeft.
  ///
  /// In fr, this message translates to:
  /// **'Milieu gauche'**
  String get fieldZoneMidLeft;

  /// No description provided for @fieldZoneMidRight.
  ///
  /// In fr, this message translates to:
  /// **'Milieu droite'**
  String get fieldZoneMidRight;

  /// No description provided for @fieldZoneDefenseLeft.
  ///
  /// In fr, this message translates to:
  /// **'Défense gauche'**
  String get fieldZoneDefenseLeft;

  /// No description provided for @fieldZoneDefenseRight.
  ///
  /// In fr, this message translates to:
  /// **'Défense droite'**
  String get fieldZoneDefenseRight;

  /// No description provided for @halfFirstUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'1ère mi-temps indisponible'**
  String get halfFirstUnavailable;

  /// No description provided for @halfSecondUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'2ème mi-temps indisponible'**
  String get halfSecondUnavailable;

  /// No description provided for @asiHeatmapPointCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} point(s) - {period}'**
  String asiHeatmapPointCount(int count, String period);

  /// No description provided for @metricsEvolutionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évolution - {metric}'**
  String metricsEvolutionTitle(String metric);

  /// No description provided for @trainingOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement du {date}'**
  String trainingOnDate(String date);

  /// No description provided for @subscriptionPaywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez à Grinta Premium'**
  String get subscriptionPaywallTitle;

  /// No description provided for @subscriptionPaywallSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez toutes les fonctionnalités pour le suivi de vos équipes et de vos joueurs'**
  String get subscriptionPaywallSubtitle;

  /// No description provided for @subscriptionPaywallLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get subscriptionPaywallLater;

  /// No description provided for @subscriptionOfferingCoach.
  ///
  /// In fr, this message translates to:
  /// **'Entraîneur'**
  String get subscriptionOfferingCoach;

  /// No description provided for @subscriptionOfferingPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get subscriptionOfferingPlayer;

  /// No description provided for @subscriptionTierCoachBasic.
  ///
  /// In fr, this message translates to:
  /// **'Coach Basic'**
  String get subscriptionTierCoachBasic;

  /// No description provided for @subscriptionTierCoachBasicDesc.
  ///
  /// In fr, this message translates to:
  /// **'Gestion d\'équipe essentielle : agenda, effectif et statistiques de base.'**
  String get subscriptionTierCoachBasicDesc;

  /// No description provided for @subscriptionTierCoachElite.
  ///
  /// In fr, this message translates to:
  /// **'Coach Elite'**
  String get subscriptionTierCoachElite;

  /// No description provided for @subscriptionTierCoachEliteDesc.
  ///
  /// In fr, this message translates to:
  /// **'Analyses avancées, compositions tactiques et outils coach complets.'**
  String get subscriptionTierCoachEliteDesc;

  /// No description provided for @subscriptionTierCoachPro.
  ///
  /// In fr, this message translates to:
  /// **'Coach Pro'**
  String get subscriptionTierCoachPro;

  /// No description provided for @subscriptionTierCoachProDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tout Elite, plus tracker GPS, heatmaps et exports pro.'**
  String get subscriptionTierCoachProDesc;

  /// No description provided for @subscriptionTierPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get subscriptionTierPlayer;

  /// No description provided for @subscriptionTierPlayerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos performances, stats personnelles et progression.'**
  String get subscriptionTierPlayerDesc;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'/mois'**
  String get subscriptionPerMonth;

  /// No description provided for @subscriptionPerYear.
  ///
  /// In fr, this message translates to:
  /// **'/an'**
  String get subscriptionPerYear;

  /// No description provided for @subscriptionBillingMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get subscriptionBillingMonthly;

  /// No description provided for @subscriptionBillingYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get subscriptionBillingYearly;

  /// No description provided for @subscriptionAnnualSavings.
  ///
  /// In fr, this message translates to:
  /// **'2 mois offerts'**
  String get subscriptionAnnualSavings;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner'**
  String get subscriptionSubscribe;

  /// No description provided for @subscriptionTierActive.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get subscriptionTierActive;

  /// No description provided for @subscriptionRestorePurchases.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer les achats'**
  String get subscriptionRestorePurchases;

  /// No description provided for @subscriptionAutoRenewLegal.
  ///
  /// In fr, this message translates to:
  /// **'L\'abonnement se renouvelle automatiquement. Vous pouvez l\'annuler à tout moment dans les réglages de votre compte App Store ou Google Play.'**
  String get subscriptionAutoRenewLegal;

  /// No description provided for @subscriptionStoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les achats intégrés ne sont pas disponibles sur cette plateforme.'**
  String get subscriptionStoreUnavailable;

  /// No description provided for @subscriptionAlreadyActive.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un abonnement actif.'**
  String get subscriptionAlreadyActive;

  /// No description provided for @subscriptionProductNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Produit introuvable. Vérifiez la configuration RevenueCat.'**
  String get subscriptionProductNotFound;

  /// No description provided for @subscriptionOfferingsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les offres d\'abonnement n\'ont pas pu être chargées. Vérifiez votre connexion et l\'offering web RevenueCat, puis réessayez.'**
  String get subscriptionOfferingsUnavailable;

  /// No description provided for @subscriptionPurchaseFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat a échoué. Réessayez.'**
  String get subscriptionPurchaseFailed;

  /// No description provided for @subscriptionRestoreNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat à restaurer.'**
  String get subscriptionRestoreNone;

  /// No description provided for @subscriptionRestoreFailed.
  ///
  /// In fr, this message translates to:
  /// **'La restauration a échoué.'**
  String get subscriptionRestoreFailed;

  /// No description provided for @subscriptionPromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez à Premium'**
  String get subscriptionPromptTitle;

  /// No description provided for @subscriptionPromptMessage.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à toutes les fonctionnalités Grinta avec un abonnement adapté à votre profil.'**
  String get subscriptionPromptMessage;

  /// No description provided for @subscriptionPromptAction.
  ///
  /// In fr, this message translates to:
  /// **'Voir les offres'**
  String get subscriptionPromptAction;

  /// No description provided for @subscriptionMenu.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscriptionMenu;

  /// No description provided for @subscriptionDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscriptionDetailsTitle;

  /// No description provided for @subscriptionTier.
  ///
  /// In fr, this message translates to:
  /// **'Formule'**
  String get subscriptionTier;

  /// No description provided for @subscriptionRenewalDate.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement le {date}'**
  String subscriptionRenewalDate(String date);

  /// No description provided for @subscriptionNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get subscriptionNone;

  /// No description provided for @subscriptionTrialEnds.
  ///
  /// In fr, this message translates to:
  /// **'Fin de l\'essai le {date}'**
  String subscriptionTrialEnds(String date);

  /// No description provided for @subscriptionPeriodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get subscriptionPeriodLabel;

  /// No description provided for @subscriptionRenewalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement'**
  String get subscriptionRenewalLabel;

  /// No description provided for @subscriptionBillingPeriodMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get subscriptionBillingPeriodMonthly;

  /// No description provided for @subscriptionBillingPeriodYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get subscriptionBillingPeriodYearly;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionChangePlan.
  ///
  /// In fr, this message translates to:
  /// **'Changer de formule'**
  String get subscriptionChangePlan;

  /// No description provided for @subscriptionChangePlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier votre abonnement'**
  String get subscriptionChangePlanTitle;

  /// No description provided for @subscriptionChangePlanSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez de Joueur à Coach, changez de formule ou modifiez la période de facturation.'**
  String get subscriptionChangePlanSubtitle;

  /// No description provided for @subscriptionChangePlanConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le changement'**
  String get subscriptionChangePlanConfirm;

  /// No description provided for @subscriptionCurrentPlan.
  ///
  /// In fr, this message translates to:
  /// **'Formule actuelle'**
  String get subscriptionCurrentPlan;

  /// No description provided for @subscriptionPlanChanged.
  ///
  /// In fr, this message translates to:
  /// **'Votre abonnement a été mis à jour.'**
  String get subscriptionPlanChanged;

  /// No description provided for @subscriptionLimitMaxTeamsReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint le nombre maximum d\'équipes ({max}) pour votre abonnement.'**
  String subscriptionLimitMaxTeamsReached(int max);

  /// No description provided for @subscriptionLimitMaxPlayersReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint le nombre maximum de joueurs ({max}) pour cette équipe.'**
  String subscriptionLimitMaxPlayersReached(int max);

  /// No description provided for @subscriptionLimitPlayerTierOnlySelf.
  ///
  /// In fr, this message translates to:
  /// **'Votre abonnement Joueur ne permet d\'ajouter que votre propre profil à une équipe.'**
  String get subscriptionLimitPlayerTierOnlySelf;

  /// No description provided for @subscriptionLimitMaxProfilesReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint le nombre maximum de profils ({max}) pour votre abonnement.'**
  String subscriptionLimitMaxProfilesReached(int max);

  /// No description provided for @subscriptionLimitProfileUpgradeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profils supplémentaires'**
  String get subscriptionLimitProfileUpgradeTitle;

  /// No description provided for @subscriptionLimitProfileUpgradeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Passez à un abonnement payant pour créer des profils supplémentaires.'**
  String get subscriptionLimitProfileUpgradeMessage;

  /// No description provided for @subscriptionLimitProfileCoachBasicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profils supplémentaires'**
  String get subscriptionLimitProfileCoachBasicTitle;

  /// No description provided for @subscriptionLimitProfileCoachBasicMessage.
  ///
  /// In fr, this message translates to:
  /// **'Passez à la formule Elite ou Pro pour créer jusqu\'à 3 profils.'**
  String get subscriptionLimitProfileCoachBasicMessage;

  /// No description provided for @subscriptionLimitProfilePremiumBadge.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get subscriptionLimitProfilePremiumBadge;

  /// No description provided for @subscriptionLimitTeamUpgradeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipes supplémentaires'**
  String get subscriptionLimitTeamUpgradeTitle;

  /// No description provided for @subscriptionLimitTeamUpgradeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Passez à l\'abonnement Joueur pour créer plus d\'équipes et gérer votre effectif.'**
  String get subscriptionLimitTeamUpgradeMessage;

  /// No description provided for @subscriptionLimitTeamCoachBasicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipes supplémentaires'**
  String get subscriptionLimitTeamCoachBasicTitle;

  /// No description provided for @subscriptionLimitTeamCoachBasicMessage.
  ///
  /// In fr, this message translates to:
  /// **'Passez à la formule Elite ou Pro pour créer plus d\'équipes.'**
  String get subscriptionLimitTeamCoachBasicMessage;

  /// No description provided for @subscriptionLimitTeamDetailBlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion d\'équipe'**
  String get subscriptionLimitTeamDetailBlockedTitle;

  /// No description provided for @subscriptionLimitTeamDetailBlockedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Passez à l\'abonnement Joueur pour accéder aux détails de l\'équipe et gérer votre effectif.'**
  String get subscriptionLimitTeamDetailBlockedMessage;

  /// No description provided for @subscriptionLimitTeamCreatedFreePlayer.
  ///
  /// In fr, this message translates to:
  /// **'Votre équipe a été créée. Passez à l\'abonnement payant pour accéder aux détails.'**
  String get subscriptionLimitTeamCreatedFreePlayer;

  /// No description provided for @trialStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit'**
  String get trialStatusTitle;

  /// No description provided for @trialDaysRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour restant} other{{days} jours restants}}'**
  String trialDaysRemaining(int days);

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boutique Grinta'**
  String get shopTitle;

  /// No description provided for @shopPromoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Offre boutique'**
  String get shopPromoTitle;

  /// No description provided for @shopPromoCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'offre'**
  String get shopPromoCta;

  /// No description provided for @shopBrowseAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir la boutique'**
  String get shopBrowseAll;

  /// No description provided for @shopLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la boutique.'**
  String get shopLoadError;

  /// No description provided for @shopRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get shopRetry;

  /// No description provided for @legalPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalPrivacyPolicy;

  /// No description provided for @legalTermsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legalTermsOfService;

  /// No description provided for @actionDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get actionDeleteAccount;

  /// No description provided for @actionDeleteAccountConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get actionDeleteAccountConfirmTitle;

  /// No description provided for @actionDeleteAccountConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Votre compte, votre profil membre et vos données associées seront supprimés.'**
  String get actionDeleteAccountConfirmMessage;

  /// No description provided for @errorDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le compte : {details}'**
  String errorDeleteAccount(String details);

  /// No description provided for @errorDeleteAccountRequiresRecentLogin.
  ///
  /// In fr, this message translates to:
  /// **'Pour des raisons de sécurité, reconnectez-vous puis réessayez.'**
  String get errorDeleteAccountRequiresRecentLogin;

  /// No description provided for @actionDeleteTeam.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'équipe'**
  String get actionDeleteTeam;

  /// No description provided for @teamDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'équipe ?'**
  String get teamDeleteConfirmTitle;

  /// No description provided for @teamDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer « {teamName} » ? Cette action est définitive. Toutes les données liées à l\'équipe (membres, matchs, statistiques, etc.) seront supprimées.'**
  String teamDeleteConfirmMessage(String teamName);

  /// No description provided for @teamDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe « {teamName} » a été supprimée.'**
  String teamDeleteSuccess(String teamName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
