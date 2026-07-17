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

  /// No description provided for @memberEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'e-mail est requis pour les invitations'**
  String get memberEmailRequired;

  /// No description provided for @invitationEmailSubject.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach t\'invite à rejoindre {appName}'**
  String invitationEmailSubject(String appName);

  /// No description provided for @invitationEmailIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach t\'invite à rejoindre {appName}'**
  String invitationEmailIntro(String appName);

  /// No description provided for @invitationEmailCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton code d\'invitation'**
  String get invitationEmailCodeLabel;

  /// No description provided for @invitationEmailDownloadIos.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger sur iPhone'**
  String get invitationEmailDownloadIos;

  /// No description provided for @invitationEmailDownloadAndroid.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger sur Android'**
  String get invitationEmailDownloadAndroid;

  /// No description provided for @invitationEmailFooter.
  ///
  /// In fr, this message translates to:
  /// **'Tu as reçu cet e-mail parce qu\'un coach t\'a ajouté sur {appName}. Si tu n\'attendais pas ce message, tu peux l\'ignorer.'**
  String invitationEmailFooter(String appName);

  /// No description provided for @invitationSmsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach t\'invite à rejoindre {appName}. Ton code : {code}.\niPhone : {appleStoreUrl}\nAndroid : {googlePlayUrl}'**
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl);

  /// No description provided for @sessionReportEmailSubject.
  ///
  /// In fr, this message translates to:
  /// **'{appName} — Rapport {eventLabel} : {title}'**
  String sessionReportEmailSubject(
      String appName, String eventLabel, String title);

  /// No description provided for @sessionReportEmailIntro.
  ///
  /// In fr, this message translates to:
  /// **'Voici ton rapport de statistiques {appName}'**
  String sessionReportEmailIntro(String appName);

  /// No description provided for @sessionReportEmailEventMatch.
  ///
  /// In fr, this message translates to:
  /// **'match'**
  String get sessionReportEmailEventMatch;

  /// No description provided for @sessionReportEmailEventTraining.
  ///
  /// In fr, this message translates to:
  /// **'entraînement'**
  String get sessionReportEmailEventTraining;

  /// No description provided for @sessionReportEmailDetailsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détails du rapport'**
  String get sessionReportEmailDetailsLabel;

  /// No description provided for @sessionReportEmailTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get sessionReportEmailTypeLabel;

  /// No description provided for @sessionReportEmailTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Séance'**
  String get sessionReportEmailTitleLabel;

  /// No description provided for @sessionReportEmailDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get sessionReportEmailDateLabel;

  /// No description provided for @sessionReportEmailTeamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get sessionReportEmailTeamLabel;

  /// No description provided for @sessionReportEmailPlayersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get sessionReportEmailPlayersLabel;

  /// No description provided for @sessionReportEmailAvgWorkloadLabel.
  ///
  /// In fr, this message translates to:
  /// **'Workload moyen'**
  String get sessionReportEmailAvgWorkloadLabel;

  /// No description provided for @sessionReportEmailDateLine.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String sessionReportEmailDateLine(String date);

  /// No description provided for @sessionReportEmailTeamLine.
  ///
  /// In fr, this message translates to:
  /// **'Équipe : {team}'**
  String sessionReportEmailTeamLine(String team);

  /// No description provided for @sessionReportEmailPlayersLine.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs avec données : {count}'**
  String sessionReportEmailPlayersLine(int count);

  /// No description provided for @sessionReportEmailAttachmentHint.
  ///
  /// In fr, this message translates to:
  /// **'Le rapport PDF des statistiques tracker est joint à cet e-mail.'**
  String get sessionReportEmailAttachmentHint;

  /// No description provided for @sessionReportEmailDownloadHint.
  ///
  /// In fr, this message translates to:
  /// **'Télécharge le rapport PDF via le bouton ci-dessous.'**
  String get sessionReportEmailDownloadHint;

  /// No description provided for @sessionReportEmailDownloadButton.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le PDF'**
  String get sessionReportEmailDownloadButton;

  /// No description provided for @sessionReportEmailDownloadLine.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le PDF : {url}'**
  String sessionReportEmailDownloadLine(String url);

  /// No description provided for @sessionReportEmailAskAddress.
  ///
  /// In fr, this message translates to:
  /// **'Indique-moi l\'adresse e-mail à laquelle envoyer le rapport PDF.'**
  String get sessionReportEmailAskAddress;

  /// No description provided for @sessionReportEmailNoSessionYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai trouvé aucune séance pour cette période.'**
  String get sessionReportEmailNoSessionYesterday;

  /// No description provided for @sessionReportEmailPeriodUnclear.
  ///
  /// In fr, this message translates to:
  /// **'Précise la période (hier, aujourd\'hui…) pour le rapport.'**
  String get sessionReportEmailPeriodUnclear;

  /// No description provided for @sessionReportEmailFooter.
  ///
  /// In fr, this message translates to:
  /// **'Tu as reçu cet e-mail parce qu\'un rapport de séance a été généré depuis {appName}. Si tu n\'attendais pas ce message, tu peux l\'ignorer.'**
  String sessionReportEmailFooter(String appName);

  /// No description provided for @sessionReportEmailDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le rapport PDF'**
  String get sessionReportEmailDialogTitle;

  /// No description provided for @sessionReportEmailDialogMessage.
  ///
  /// In fr, this message translates to:
  /// **'Indique l\'adresse e-mail qui recevra le rapport de statistiques (PDF).'**
  String get sessionReportEmailDialogMessage;

  /// No description provided for @sessionReportEmailDialogHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.com'**
  String get sessionReportEmailDialogHint;

  /// No description provided for @sessionReportEmailDialogSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get sessionReportEmailDialogSend;

  /// No description provided for @sessionReportEmailDialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get sessionReportEmailDialogCancel;

  /// No description provided for @sessionReportEmailActionTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le rapport PDF par e-mail'**
  String get sessionReportEmailActionTooltip;

  /// No description provided for @sessionReportEmailActionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rapport PDF'**
  String get sessionReportEmailActionLabel;

  /// No description provided for @sessionReportEmailSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Rapport envoyé à {email}'**
  String sessionReportEmailSuccess(String email);

  /// No description provided for @sessionReportEmailFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le rapport PDF.'**
  String get sessionReportEmailFailed;

  /// No description provided for @sessionReportEmailNoStats.
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique tracker disponible pour générer ce rapport.'**
  String get sessionReportEmailNoStats;

  /// No description provided for @sessionReportEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get sessionReportEmailInvalid;

  /// No description provided for @memberInvitationEmailFailed.
  ///
  /// In fr, this message translates to:
  /// **'Membre ajouté, mais l\'envoi de l\'e-mail d\'invitation a échoué.'**
  String get memberInvitationEmailFailed;

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

  /// No description provided for @resendInvitationTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'e-mail d\'invitation'**
  String get resendInvitationTooltip;

  /// No description provided for @resendInvitationNoEmailTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une adresse e-mail pour envoyer une invitation'**
  String get resendInvitationNoEmailTooltip;

  /// No description provided for @resendInvitationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'E-mail d\'invitation envoyé'**
  String get resendInvitationSuccess;

  /// No description provided for @resendInvitationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'e-mail d\'invitation'**
  String get resendInvitationFailed;

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

  /// No description provided for @settingsMyUnavailabilities.
  ///
  /// In fr, this message translates to:
  /// **'Mes indisponibilités'**
  String get settingsMyUnavailabilities;

  /// No description provided for @myUnavailabilitiesNoPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil joueur lié à ton compte.'**
  String get myUnavailabilitiesNoPlayer;

  /// No description provided for @myUnavailabilitiesNoSeason.
  ///
  /// In fr, this message translates to:
  /// **'Aucune saison sélectionnée. Choisis une saison dans le menu compte.'**
  String get myUnavailabilitiesNoSeason;

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

  /// No description provided for @navNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucune notification non lue.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsMarkAsRead.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme lue'**
  String get notificationsMarkAsRead;

  /// No description provided for @notificationsMarkAsReadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de marquer la notification comme lue.'**
  String get notificationsMarkAsReadError;

  /// No description provided for @notificationsConvocationMatchDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du match'**
  String get notificationsConvocationMatchDetails;

  /// No description provided for @notificationsConvocationPresent.
  ///
  /// In fr, this message translates to:
  /// **'Je serai présent'**
  String get notificationsConvocationPresent;

  /// No description provided for @notificationsConvocationAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Pas présent'**
  String get notificationsConvocationAbsent;

  /// No description provided for @notificationsConvocationAbsentDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motif d\'absence'**
  String get notificationsConvocationAbsentDialogTitle;

  /// No description provided for @notificationsConvocationAbsentMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez pourquoi vous ne serez pas présent'**
  String get notificationsConvocationAbsentMessageHint;

  /// No description provided for @notificationsConvocationAbsentConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get notificationsConvocationAbsentConfirm;

  /// No description provided for @notificationsConvocationAbsentMessageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un message.'**
  String get notificationsConvocationAbsentMessageRequired;

  /// No description provided for @notificationsConvocationActionError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de répondre à la convocation.'**
  String get notificationsConvocationActionError;

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
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @tabCompo.
  ///
  /// In fr, this message translates to:
  /// **'Compo'**
  String get tabCompo;

  /// No description provided for @tabConvocations.
  ///
  /// In fr, this message translates to:
  /// **'Convocations'**
  String get tabConvocations;

  /// No description provided for @tabConvocationsShort.
  ///
  /// In fr, this message translates to:
  /// **'Convo'**
  String get tabConvocationsShort;

  /// No description provided for @matchConvocationsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Convocations enregistrées'**
  String get matchConvocationsSaved;

  /// No description provided for @matchConvocationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Convocations indisponibles pour ce match'**
  String get matchConvocationsUnavailable;

  /// No description provided for @matchPlayerUnavailableOnMatchDate.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible à la date du match'**
  String get matchPlayerUnavailableOnMatchDate;

  /// No description provided for @matchPlayerCannotConvokeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce joueur est indisponible à la date de la rencontre et ne peut pas être convoqué.'**
  String get matchPlayerCannotConvokeUnavailable;

  /// No description provided for @matchConvocationsStatusPresent.
  ///
  /// In fr, this message translates to:
  /// **'Présent confirmé'**
  String get matchConvocationsStatusPresent;

  /// No description provided for @matchConvocationsStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de réponse'**
  String get matchConvocationsStatusPending;

  /// No description provided for @matchConvocationsSendAction.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer les convocations'**
  String get matchConvocationsSendAction;

  /// No description provided for @matchConvocationsSendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer les convocations'**
  String get matchConvocationsSendTitle;

  /// No description provided for @matchConvocationsSendSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 joueur convoqué} other{{count} joueurs convoqués}}'**
  String matchConvocationsSendSubtitle(int count);

  /// No description provided for @matchConvocationsSendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get matchConvocationsSendMessage;

  /// No description provided for @matchConvocationsSendMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Informations complémentaires pour les joueurs'**
  String get matchConvocationsSendMessageHint;

  /// No description provided for @matchConvocationsSendMessageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisis un message'**
  String get matchConvocationsSendMessageRequired;

  /// No description provided for @matchConvocationsSendTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de convocation'**
  String get matchConvocationsSendTime;

  /// No description provided for @matchConvocationsSendAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de convocation'**
  String get matchConvocationsSendAddress;

  /// No description provided for @matchConvocationsSendAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de rendez-vous'**
  String get matchConvocationsSendAddressHint;

  /// No description provided for @matchConvocationsSendAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisis une adresse'**
  String get matchConvocationsSendAddressRequired;

  /// No description provided for @matchConvocationsSendSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get matchConvocationsSendSubmit;

  /// No description provided for @matchConvocationsSendSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 convocation envoyée} other{{count} convocations envoyées}}'**
  String matchConvocationsSendSuccess(int count);

  /// No description provided for @matchConvocationsSendSkippedNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 joueur sans compte lié} other{{count} joueurs sans compte lié}}'**
  String matchConvocationsSendSkippedNoAccount(int count);

  /// No description provided for @matchConvocationsSendSkippedNoPush.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 joueur sans notification push} other{{count} joueurs sans notification push}}'**
  String matchConvocationsSendSkippedNoPush(int count);

  /// No description provided for @matchConvocationsSendNoRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur convoqué n\'a de compte Grinta lié.'**
  String get matchConvocationsSendNoRecipients;

  /// No description provided for @matchConvocationsSendError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi : {error}'**
  String matchConvocationsSendError(String error);

  /// No description provided for @matchConvocationsSendErrorAuth.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour envoyer les convocations.'**
  String get matchConvocationsSendErrorAuth;

  /// No description provided for @matchConvocationsSendDateTimeValue.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String matchConvocationsSendDateTimeValue(String date, String time);

  /// No description provided for @matchConvocationsSendMatchLine.
  ///
  /// In fr, this message translates to:
  /// **'Match : {opponent}'**
  String matchConvocationsSendMatchLine(String opponent);

  /// No description provided for @matchConvocationsSendTimeLine.
  ///
  /// In fr, this message translates to:
  /// **'Heure : {time}'**
  String matchConvocationsSendTimeLine(String time);

  /// No description provided for @matchConvocationsSendAddressLine.
  ///
  /// In fr, this message translates to:
  /// **'Adresse : {address}'**
  String matchConvocationsSendAddressLine(String address);

  /// No description provided for @matchConvocationNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Convocation · {opponent}'**
  String matchConvocationNotificationTitle(String opponent);

  /// No description provided for @matchConvocationFeedbackNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réponse convocation · {opponent}'**
  String matchConvocationFeedbackNotificationTitle(String opponent);

  /// No description provided for @matchConvocationNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'{opponent} · RDV {time}'**
  String matchConvocationNotificationBody(String opponent, String time);

  /// No description provided for @matchConvocationNotificationBodyWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'{opponent} · RDV {time} · {message}'**
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message);

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
  /// **'Clôturer définitivement la synchronisation'**
  String get dialogCloseSyncTitle;

  /// No description provided for @dialogCloseSyncMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous clôturer définitivement la synchronisation ? Oui : plus d’accès à cet écran. Non : quitter sans clôturer.'**
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

  /// No description provided for @asiFileEmptyOrNoData.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier .asi est vide ou ne contient aucune donnée exploitable.'**
  String get asiFileEmptyOrNoData;

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

  /// No description provided for @teamStreamChannelSynced.
  ///
  /// In fr, this message translates to:
  /// **'Groupe Stream actif'**
  String get teamStreamChannelSynced;

  /// No description provided for @teamStreamChannelPending.
  ///
  /// In fr, this message translates to:
  /// **'Groupe Stream non synchronisé'**
  String get teamStreamChannelPending;

  /// No description provided for @teamStreamChannelCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe Stream ?'**
  String get teamStreamChannelCreateTitle;

  /// No description provided for @teamStreamChannelCreateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe Stream pour l\'équipe {teamName} ? Les joueurs et le staff seront ajoutés automatiquement.'**
  String teamStreamChannelCreateMessage(String teamName);

  /// No description provided for @teamStreamChannelCreateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get teamStreamChannelCreateConfirm;

  /// No description provided for @teamStreamChannelCreateLoading.
  ///
  /// In fr, this message translates to:
  /// **'Création du groupe Stream…'**
  String get teamStreamChannelCreateLoading;

  /// No description provided for @teamStreamChannelCreateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Groupe Stream créé pour {teamName}.'**
  String teamStreamChannelCreateSuccess(String teamName);

  /// No description provided for @teamStreamChannelCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le groupe Stream : {details}'**
  String teamStreamChannelCreateError(String details);

  /// No description provided for @teamStreamChannelCreateNotManager.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les managers peuvent créer le groupe Stream.'**
  String get teamStreamChannelCreateNotManager;

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

  /// No description provided for @chatChannelMembersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get chatChannelMembersTitle;

  /// No description provided for @chatMessageReadByTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lu par'**
  String get chatMessageReadByTitle;

  /// No description provided for @chatMessageNotReadYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore lu'**
  String get chatMessageNotReadYet;

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

  /// No description provided for @matchHighlightsSourceFmi.
  ///
  /// In fr, this message translates to:
  /// **'Temps forts de la FMI'**
  String get matchHighlightsSourceFmi;

  /// No description provided for @matchHighlightsSourceGrinta.
  ///
  /// In fr, this message translates to:
  /// **'Temps forts Grinta'**
  String get matchHighlightsSourceGrinta;

  /// No description provided for @matchHighlightsGrintaPlaceholderMessage.
  ///
  /// In fr, this message translates to:
  /// **'À détailler ensemble après.'**
  String get matchHighlightsGrintaPlaceholderMessage;

  /// No description provided for @matchGrintaHighlightsAddAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un temps fort'**
  String get matchGrintaHighlightsAddAction;

  /// No description provided for @matchGrintaHighlightsPickTypeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le type de temps fort'**
  String get matchGrintaHighlightsPickTypeTitle;

  /// No description provided for @matchGrintaHighlightsPickTimeEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir l\'événement'**
  String get matchGrintaHighlightsPickTimeEventTitle;

  /// No description provided for @matchGrintaHighlightsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par le coup d\'envoi avec le bouton +.'**
  String get matchGrintaHighlightsEmptyMessage;

  /// No description provided for @matchGrintaHighlightsDetailsComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Le détail de ce temps fort arrive bientôt.'**
  String get matchGrintaHighlightsDetailsComingSoon;

  /// No description provided for @matchGrintaHighlightsActionTimeEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement de temps'**
  String get matchGrintaHighlightsActionTimeEvent;

  /// No description provided for @matchGrintaHighlightsAllTimeEventsRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Tous les événements de temps ont déjà été enregistrés pour ce match.'**
  String get matchGrintaHighlightsAllTimeEventsRecorded;

  /// No description provided for @matchGrintaHighlightDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce temps fort ?'**
  String get matchGrintaHighlightDeleteConfirmTitle;

  /// No description provided for @matchGrintaHighlightDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer « {highlightLabel} » ? Cette action est définitive.'**
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel);

  /// No description provided for @matchGrintaHighlightDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Temps fort supprimé'**
  String get matchGrintaHighlightDeleted;

  /// No description provided for @matchGoalAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un but'**
  String get matchGoalAddTitle;

  /// No description provided for @matchGoalPickTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle équipe a marqué ?'**
  String get matchGoalPickTeamTitle;

  /// No description provided for @matchGoalPickScorerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Buteur'**
  String get matchGoalPickScorerTitle;

  /// No description provided for @matchGoalPickAssisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passeur décisif (optionnel)'**
  String get matchGoalPickAssisterTitle;

  /// No description provided for @matchGoalNoAssister.
  ///
  /// In fr, this message translates to:
  /// **'Sans passeur'**
  String get matchGoalNoAssister;

  /// No description provided for @matchGoalOpponentJerseyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du buteur (optionnel)'**
  String get matchGoalOpponentJerseyTitle;

  /// No description provided for @matchGoalOpponentJerseyHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. 10'**
  String get matchGoalOpponentJerseyHint;

  /// No description provided for @matchGoalScorerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un buteur.'**
  String get matchGoalScorerRequired;

  /// No description provided for @matchGoalInvalidJerseyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro de maillot valide.'**
  String get matchGoalInvalidJerseyNumber;

  /// No description provided for @matchGoalMinuteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Minute'**
  String get matchGoalMinuteTitle;

  /// No description provided for @matchGoalMinuteHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. 67'**
  String get matchGoalMinuteHint;

  /// No description provided for @matchGoalInvalidMinute.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une minute d\'au moins 1.'**
  String get matchGoalInvalidMinute;

  /// No description provided for @matchGoalSelectScorer.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un buteur'**
  String get matchGoalSelectScorer;

  /// No description provided for @matchGoalSelectAssister.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un passeur'**
  String get matchGoalSelectAssister;

  /// No description provided for @matchCardYellowAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un carton jaune'**
  String get matchCardYellowAddTitle;

  /// No description provided for @matchCardRedAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un carton rouge'**
  String get matchCardRedAddTitle;

  /// No description provided for @matchCardPickTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle équipe reçoit le carton ?'**
  String get matchCardPickTeamTitle;

  /// No description provided for @matchCardPickPlayerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get matchCardPickPlayerTitle;

  /// No description provided for @matchCardSelectPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un joueur'**
  String get matchCardSelectPlayer;

  /// No description provided for @matchCardPlayerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un joueur.'**
  String get matchCardPlayerRequired;

  /// No description provided for @matchCardOpponentJerseyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du joueur (optionnel)'**
  String get matchCardOpponentJerseyTitle;

  /// No description provided for @matchCardOpponentJerseyHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. 10'**
  String get matchCardOpponentJerseyHint;

  /// No description provided for @matchSubstitutionAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un changement'**
  String get matchSubstitutionAddTitle;

  /// No description provided for @matchSubstitutionPickTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle équipe effectue le changement ?'**
  String get matchSubstitutionPickTeamTitle;

  /// No description provided for @matchSubstitutionPickOutgoingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Joueur sortant'**
  String get matchSubstitutionPickOutgoingTitle;

  /// No description provided for @matchSubstitutionPickIncomingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Joueur entrant'**
  String get matchSubstitutionPickIncomingTitle;

  /// No description provided for @matchSubstitutionSelectOutgoing.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le joueur sortant'**
  String get matchSubstitutionSelectOutgoing;

  /// No description provided for @matchSubstitutionSelectIncoming.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le joueur entrant'**
  String get matchSubstitutionSelectIncoming;

  /// No description provided for @matchSubstitutionOutgoingRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez le joueur sortant.'**
  String get matchSubstitutionOutgoingRequired;

  /// No description provided for @matchSubstitutionIncomingRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez le joueur entrant.'**
  String get matchSubstitutionIncomingRequired;

  /// No description provided for @matchSubstitutionSamePlayerError.
  ///
  /// In fr, this message translates to:
  /// **'Les deux joueurs doivent être différents.'**
  String get matchSubstitutionSamePlayerError;

  /// No description provided for @matchSubstitutionOpponentOutgoingJerseyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du joueur sortant (optionnel)'**
  String get matchSubstitutionOpponentOutgoingJerseyTitle;

  /// No description provided for @matchSubstitutionOpponentIncomingJerseyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du joueur entrant (optionnel)'**
  String get matchSubstitutionOpponentIncomingJerseyTitle;

  /// No description provided for @highlightGoalScored.
  ///
  /// In fr, this message translates to:
  /// **'But — {scorer}'**
  String highlightGoalScored(String scorer);

  /// No description provided for @highlightTimeHalfTime.
  ///
  /// In fr, this message translates to:
  /// **'Mi-temps'**
  String get highlightTimeHalfTime;

  /// No description provided for @highlightTimeSecondHalf.
  ///
  /// In fr, this message translates to:
  /// **'Deuxième mi-temps'**
  String get highlightTimeSecondHalf;

  /// No description provided for @highlightTimeStartExtraTime.
  ///
  /// In fr, this message translates to:
  /// **'Prolongations'**
  String get highlightTimeStartExtraTime;

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

  /// No description provided for @highlightYellowCardShown.
  ///
  /// In fr, this message translates to:
  /// **'Carton jaune — {player}'**
  String highlightYellowCardShown(String player);

  /// No description provided for @highlightRedCardShown.
  ///
  /// In fr, this message translates to:
  /// **'Carton rouge — {player}'**
  String highlightRedCardShown(String player);

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

  /// No description provided for @trackerAllSensorsSynced.
  ///
  /// In fr, this message translates to:
  /// **'Tous les capteurs ont été synchronisés'**
  String get trackerAllSensorsSynced;

  /// No description provided for @trackerSensorsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'À synchroniser'**
  String get trackerSensorsRemaining;

  /// No description provided for @trackerSensorsAlreadySynced.
  ///
  /// In fr, this message translates to:
  /// **'Déjà synchronisés'**
  String get trackerSensorsAlreadySynced;

  /// No description provided for @trackerSyncedProgress.
  ///
  /// In fr, this message translates to:
  /// **'{synced}/{total} synchronisés'**
  String trackerSyncedProgress(int synced, int total);

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

  /// No description provided for @agendaAddEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get agendaAddEventTitle;

  /// No description provided for @agendaAddEventMatch.
  ///
  /// In fr, this message translates to:
  /// **'Une rencontre / match'**
  String get agendaAddEventMatch;

  /// No description provided for @agendaAddEventTraining.
  ///
  /// In fr, this message translates to:
  /// **'Une session d\'entraînement'**
  String get agendaAddEventTraining;

  /// No description provided for @agendaAddEventPersonalSport.
  ///
  /// In fr, this message translates to:
  /// **'Une activité sportive personnelle'**
  String get agendaAddEventPersonalSport;

  /// No description provided for @agendaAddEventPersonalSportHint.
  ///
  /// In fr, this message translates to:
  /// **'Running, préparation, …'**
  String get agendaAddEventPersonalSportHint;

  /// No description provided for @agendaAddEventNonSport.
  ///
  /// In fr, this message translates to:
  /// **'Un évènement / activité non sportive'**
  String get agendaAddEventNonSport;

  /// No description provided for @agendaAllDayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Journée entière'**
  String get agendaAllDayLabel;

  /// No description provided for @agendaEventSummaryNonSport.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 activité} other{{count} activités}}'**
  String agendaEventSummaryNonSport(int count);

  /// No description provided for @createNonSportEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel évènement / activité'**
  String get createNonSportEventTitle;

  /// No description provided for @createNonSportEventTitleField.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get createNonSportEventTitleField;

  /// No description provided for @createNonSportEventTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un titre'**
  String get createNonSportEventTitleRequired;

  /// No description provided for @createNonSportEventDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get createNonSportEventDate;

  /// No description provided for @createNonSportEventTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get createNonSportEventTime;

  /// No description provided for @createNonSportEventAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Journée entière'**
  String get createNonSportEventAllDay;

  /// No description provided for @createNonSportEventStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get createNonSportEventStartDate;

  /// No description provided for @createNonSportEventStartTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de début'**
  String get createNonSportEventStartTime;

  /// No description provided for @createNonSportEventEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get createNonSportEventEndDate;

  /// No description provided for @createNonSportEventEndTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de fin'**
  String get createNonSportEventEndTime;

  /// No description provided for @createNonSportEventInvalidRange.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit être après le début.'**
  String get createNonSportEventInvalidRange;

  /// No description provided for @editNonSportEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'évènement'**
  String get editNonSportEventTitle;

  /// No description provided for @editNonSportEventSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get editNonSportEventSubmit;

  /// No description provided for @editNonSportEventSaved.
  ///
  /// In fr, this message translates to:
  /// **'Évènement mis à jour'**
  String get editNonSportEventSaved;

  /// No description provided for @editNonSportEventError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier l\'évènement. Réessayez.'**
  String get editNonSportEventError;

  /// No description provided for @deleteNonSportEventConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'évènement ?'**
  String get deleteNonSportEventConfirmTitle;

  /// No description provided for @deleteNonSportEventConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » sera définitivement supprimé, ainsi que les notifications associées.'**
  String deleteNonSportEventConfirmMessage(String title);

  /// No description provided for @deleteNonSportEventDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Évènement supprimé'**
  String get deleteNonSportEventDeleted;

  /// No description provided for @deleteNonSportEventError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer l\'évènement. Réessayez.'**
  String get deleteNonSportEventError;

  /// No description provided for @createNonSportEventLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get createNonSportEventLocation;

  /// No description provided for @createNonSportEventLocationHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse ou lieu de rendez-vous'**
  String get createNonSportEventLocationHint;

  /// No description provided for @createNonSportEventInviteTeams.
  ///
  /// In fr, this message translates to:
  /// **'Inviter une ou plusieurs équipes'**
  String get createNonSportEventInviteTeams;

  /// No description provided for @createNonSportEventSelectMembers.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner les membres'**
  String get createNonSportEventSelectMembers;

  /// No description provided for @createNonSportEventSelectedMembersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre sélectionné} other{{count} membres sélectionnés}}'**
  String createNonSportEventSelectedMembersCount(int count);

  /// No description provided for @createNonSportEventNoTeamMembers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre dans cette équipe.'**
  String get createNonSportEventNoTeamMembers;

  /// No description provided for @createNonSportEventInviteOthers.
  ///
  /// In fr, this message translates to:
  /// **'Inviter d\'autres profils'**
  String get createNonSportEventInviteOthers;

  /// No description provided for @createNonSportEventAddProfile.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un profil'**
  String get createNonSportEventAddProfile;

  /// No description provided for @createNonSportEventInvitees.
  ///
  /// In fr, this message translates to:
  /// **'Invités'**
  String get createNonSportEventInvitees;

  /// No description provided for @createNonSportEventNoInvitees.
  ///
  /// In fr, this message translates to:
  /// **'Aucun invité pour le moment.'**
  String get createNonSportEventNoInvitees;

  /// No description provided for @createNonSportEventNoTeams.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe disponible pour cette saison.'**
  String get createNonSportEventNoTeams;

  /// No description provided for @createNonSportEventSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'évènement'**
  String get createNonSportEventSubmit;

  /// No description provided for @createNonSportEventSaved.
  ///
  /// In fr, this message translates to:
  /// **'Évènement créé'**
  String get createNonSportEventSaved;

  /// No description provided for @createNonSportEventError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer l\'évènement. Réessayez.'**
  String get createNonSportEventError;

  /// No description provided for @createNonSportEventInviteStatusSent.
  ///
  /// In fr, this message translates to:
  /// **'Notification envoyée'**
  String get createNonSportEventInviteStatusSent;

  /// No description provided for @createNonSportEventInviteStatusNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte utilisateur lié'**
  String get createNonSportEventInviteStatusNoAccount;

  /// No description provided for @createNonSportEventInviteStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get createNonSportEventInviteStatusPending;

  /// No description provided for @createNonSportEventInviteStatusError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de notification'**
  String get createNonSportEventInviteStatusError;

  /// No description provided for @createNonSportEventNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel évènement'**
  String get createNonSportEventNotificationTitle;

  /// No description provided for @createNonSportEventNotificationBody.
  ///
  /// In fr, this message translates to:
  /// **'{title} — {when}'**
  String createNonSportEventNotificationBody(String title, String when);

  /// No description provided for @createNonSportEventNotificationBodyWithLocation.
  ///
  /// In fr, this message translates to:
  /// **'{title} — {when} — {location}'**
  String createNonSportEventNotificationBodyWithLocation(
      String title, String when, String location);

  /// No description provided for @nonSportEventInviteesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitations'**
  String get nonSportEventInviteesTitle;

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

  /// No description provided for @teamDetailColumnApp.
  ///
  /// In fr, this message translates to:
  /// **'App'**
  String get teamDetailColumnApp;

  /// No description provided for @teamDetailPlayerDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails du joueur'**
  String get teamDetailPlayerDetailsTitle;

  /// No description provided for @teamDetailGrantManager.
  ///
  /// In fr, this message translates to:
  /// **'Accorder les droits manager'**
  String get teamDetailGrantManager;

  /// No description provided for @teamDetailRevokeManager.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les droits manager'**
  String get teamDetailRevokeManager;

  /// No description provided for @teamDetailRemoveFromTeam.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get teamDetailRemoveFromTeam;

  /// No description provided for @teamDetailTrackerOwnersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trackers GPS'**
  String get teamDetailTrackerOwnersTitle;

  /// No description provided for @teamDetailTrackerOwnersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun kit tracker disponible pour votre compte.'**
  String get teamDetailTrackerOwnersEmpty;

  /// No description provided for @teamDetailTrackerOwnerType.
  ///
  /// In fr, this message translates to:
  /// **'Type : {type}'**
  String teamDetailTrackerOwnerType(String type);

  /// No description provided for @teamDetailTrackerOwnersSaved.
  ///
  /// In fr, this message translates to:
  /// **'Kits tracker mis à jour.'**
  String get teamDetailTrackerOwnersSaved;

  /// No description provided for @teamDetailTrackerCoachProRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trackers GPS'**
  String get teamDetailTrackerCoachProRequiredTitle;

  /// No description provided for @teamDetailTrackerCoachProRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'association de kits tracker GPS à une équipe nécessite un abonnement Coach Pro.'**
  String get teamDetailTrackerCoachProRequiredMessage;

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

  /// No description provided for @teamEditNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom de l\'équipe'**
  String get teamEditNameTitle;

  /// No description provided for @teamEditNameSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'équipe mis à jour.'**
  String get teamEditNameSuccess;

  /// No description provided for @calendarSyncToggleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sync. calendrier'**
  String get calendarSyncToggleLabel;

  /// No description provided for @calendarSyncToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour auto à l\'ouverture de l\'agenda (max 1×/15 min)'**
  String get calendarSyncToggleSubtitle;

  /// No description provided for @calendarSyncWebSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharge un fichier ICS à importer dans ton calendrier'**
  String get calendarSyncWebSubtitle;

  /// No description provided for @calendarSyncWebRedownloadHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour télécharger à nouveau le fichier calendrier'**
  String get calendarSyncWebRedownloadHint;

  /// No description provided for @calendarSyncWebDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Fichier calendrier téléchargé. Importe-le dans ton application de calendrier.'**
  String get calendarSyncWebDownloaded;

  /// No description provided for @calendarSyncPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès au calendrier a été refusé. Activez-le dans les réglages de l\'appareil.'**
  String get calendarSyncPermissionDenied;

  /// No description provided for @calendarSyncCalendarCreationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le calendrier Grinta sur cet appareil.'**
  String get calendarSyncCalendarCreationFailed;

  /// No description provided for @calendarSyncEnableFailed.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation du calendrier n\'a pas pu être activée. Réessayez.'**
  String get calendarSyncEnableFailed;

  /// No description provided for @calendarSyncForceNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get calendarSyncForceNow;

  /// No description provided for @calendarSyncForceSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier synchronisé.'**
  String get calendarSyncForceSuccess;

  /// No description provided for @calendarSyncForceFailed.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation a échoué. Réessayez.'**
  String get calendarSyncForceFailed;

  /// No description provided for @settingsDevicesSection.
  ///
  /// In fr, this message translates to:
  /// **'Appareils/Applications'**
  String get settingsDevicesSection;

  /// No description provided for @settingsDevicesClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get settingsDevicesClose;

  /// No description provided for @settingsDevicesSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get settingsDevicesSync;

  /// No description provided for @settingsDevicesConnectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appareils/applications connectés'**
  String get settingsDevicesConnectedTitle;

  /// No description provided for @settingsDevicesConnectedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get settingsDevicesConnectedStatus;

  /// No description provided for @settingsDevicesDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get settingsDevicesDisconnect;

  /// No description provided for @settingsDevicesNoConnected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil ou application connecté'**
  String get settingsDevicesNoConnected;

  /// No description provided for @settingsDevicesBadgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun appareil/application connecté} =1{1 appareil/application connecté} other{{count} appareils/applications connectés}}'**
  String settingsDevicesBadgeLabel(int count);

  /// No description provided for @wearableDeviceTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'appareil/application'**
  String get wearableDeviceTypeLabel;

  /// No description provided for @wearableDeviceWhoop.
  ///
  /// In fr, this message translates to:
  /// **'Whoop'**
  String get wearableDeviceWhoop;

  /// No description provided for @wearableDeviceStrava.
  ///
  /// In fr, this message translates to:
  /// **'Strava'**
  String get wearableDeviceStrava;

  /// No description provided for @wearableDevicePolar.
  ///
  /// In fr, this message translates to:
  /// **'Polar'**
  String get wearableDevicePolar;

  /// No description provided for @wearableDeviceFitbit.
  ///
  /// In fr, this message translates to:
  /// **'Fitbit'**
  String get wearableDeviceFitbit;

  /// No description provided for @wearableDeviceAppleHealth.
  ///
  /// In fr, this message translates to:
  /// **'Apple Forme'**
  String get wearableDeviceAppleHealth;

  /// No description provided for @wearableDeviceGoogleHealthConnect.
  ///
  /// In fr, this message translates to:
  /// **'Google Fit / Health Connect'**
  String get wearableDeviceGoogleHealthConnect;

  /// No description provided for @whoopConnectToggleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sync. Whoop'**
  String get whoopConnectToggleLabel;

  /// No description provided for @whoopConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Whoop pour importer récupération, sommeil et entraînements'**
  String get whoopConnectToggleSubtitle;

  /// No description provided for @whoopConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Whoop connecté — synchronisation des données à venir (Phase 2)'**
  String get whoopConnectToggleConnectedSubtitle;

  /// No description provided for @whoopConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Whoop connecté.'**
  String get whoopConnectSuccess;

  /// No description provided for @whoopConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Whoop a échoué. Réessayez.'**
  String get whoopConnectFailed;

  /// No description provided for @whoopConnectLaunchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de connexion Whoop.'**
  String get whoopConnectLaunchFailed;

  /// No description provided for @whoopConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Whoop.'**
  String get whoopConnectAuthRequired;

  /// No description provided for @whoopDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Whoop a échoué.'**
  String get whoopDisconnectFailed;

  /// No description provided for @whoopCoachVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité coach'**
  String get whoopCoachVisibilityTitle;

  /// No description provided for @whoopCoachVisibilitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser ton coach à voir cette donnée'**
  String get whoopCoachVisibilitySubtitle;

  /// No description provided for @whoopCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Whoop.'**
  String get whoopCoachVisibilitySaveFailed;

  /// No description provided for @whoopMetricRecovery.
  ///
  /// In fr, this message translates to:
  /// **'Récupération'**
  String get whoopMetricRecovery;

  /// No description provided for @whoopMetricCycles.
  ///
  /// In fr, this message translates to:
  /// **'Cycles'**
  String get whoopMetricCycles;

  /// No description provided for @whoopMetricSleep.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get whoopMetricSleep;

  /// No description provided for @whoopMetricWorkout.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements'**
  String get whoopMetricWorkout;

  /// No description provided for @whoopMetricProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get whoopMetricProfile;

  /// No description provided for @whoopMetricBodyMeasurement.
  ///
  /// In fr, this message translates to:
  /// **'Mensurations'**
  String get whoopMetricBodyMeasurement;

  /// No description provided for @whoopCoachConnectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Whoop'**
  String get whoopCoachConnectTitle;

  /// No description provided for @whoopCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter le compte Whoop de {playerName}'**
  String whoopCoachConnectSubtitle(String playerName);

  /// No description provided for @whoopCoachConnectAction.
  ///
  /// In fr, this message translates to:
  /// **'Connecter'**
  String get whoopCoachConnectAction;

  /// No description provided for @whoopCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Whoop connecté pour {playerName}'**
  String whoopCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @stravaConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Strava pour importer activités et entraînements'**
  String get stravaConnectToggleSubtitle;

  /// No description provided for @stravaConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Strava connecté — synchronisation des données à venir (Phase 2)'**
  String get stravaConnectToggleConnectedSubtitle;

  /// No description provided for @stravaConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Strava connecté.'**
  String get stravaConnectSuccess;

  /// No description provided for @stravaConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Strava a échoué. Réessayez.'**
  String get stravaConnectFailed;

  /// No description provided for @stravaConnectLaunchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de connexion Strava.'**
  String get stravaConnectLaunchFailed;

  /// No description provided for @stravaConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Strava.'**
  String get stravaConnectAuthRequired;

  /// No description provided for @stravaDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Strava a échoué.'**
  String get stravaDisconnectFailed;

  /// No description provided for @stravaCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Strava.'**
  String get stravaCoachVisibilitySaveFailed;

  /// No description provided for @stravaMetricActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get stravaMetricActivities;

  /// No description provided for @stravaMetricProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get stravaMetricProfile;

  /// No description provided for @stravaCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter le compte Strava de {playerName}'**
  String stravaCoachConnectSubtitle(String playerName);

  /// No description provided for @stravaCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Strava connecté pour {playerName}'**
  String stravaCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @polarConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Polar pour importer entraînements, sommeil et fréquence cardiaque depuis Loop ou Verity Sense via Polar Flow'**
  String get polarConnectToggleSubtitle;

  /// No description provided for @polarConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Polar connecté — synchronisation des données à venir (Phase 2)'**
  String get polarConnectToggleConnectedSubtitle;

  /// No description provided for @polarConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Polar connecté.'**
  String get polarConnectSuccess;

  /// No description provided for @polarConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Polar a échoué. Réessayez.'**
  String get polarConnectFailed;

  /// No description provided for @polarConnectLaunchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de connexion Polar.'**
  String get polarConnectLaunchFailed;

  /// No description provided for @polarConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Polar.'**
  String get polarConnectAuthRequired;

  /// No description provided for @polarDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Polar a échoué.'**
  String get polarDisconnectFailed;

  /// No description provided for @polarCoachVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité coach'**
  String get polarCoachVisibilityTitle;

  /// No description provided for @polarCoachVisibilitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser ton coach à voir cette donnée'**
  String get polarCoachVisibilitySubtitle;

  /// No description provided for @polarCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Polar.'**
  String get polarCoachVisibilitySaveFailed;

  /// No description provided for @polarMetricTraining.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements'**
  String get polarMetricTraining;

  /// No description provided for @polarMetricSleep.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get polarMetricSleep;

  /// No description provided for @polarMetricRecoveryHr.
  ///
  /// In fr, this message translates to:
  /// **'Récupération / fréquence cardiaque'**
  String get polarMetricRecoveryHr;

  /// No description provided for @polarMetricProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get polarMetricProfile;

  /// No description provided for @polarMetricBody.
  ///
  /// In fr, this message translates to:
  /// **'Mensurations'**
  String get polarMetricBody;

  /// No description provided for @polarCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter le compte Polar de {playerName}'**
  String polarCoachConnectSubtitle(String playerName);

  /// No description provided for @polarCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Polar connecté pour {playerName}'**
  String polarCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @fitbitConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Fitbit pour importer activité, fréquence cardiaque, sommeil et poids depuis ton bracelet via le cloud Fitbit'**
  String get fitbitConnectToggleSubtitle;

  /// No description provided for @fitbitConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fitbit connecté — synchronisation des données à venir (Phase 2)'**
  String get fitbitConnectToggleConnectedSubtitle;

  /// No description provided for @fitbitConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Fitbit connecté.'**
  String get fitbitConnectSuccess;

  /// No description provided for @fitbitConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Fitbit a échoué. Réessayez.'**
  String get fitbitConnectFailed;

  /// No description provided for @fitbitConnectLaunchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de connexion Fitbit.'**
  String get fitbitConnectLaunchFailed;

  /// No description provided for @fitbitConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Fitbit.'**
  String get fitbitConnectAuthRequired;

  /// No description provided for @fitbitDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Fitbit a échoué.'**
  String get fitbitDisconnectFailed;

  /// No description provided for @fitbitCoachVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité coach'**
  String get fitbitCoachVisibilityTitle;

  /// No description provided for @fitbitCoachVisibilitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser ton coach à voir cette donnée'**
  String get fitbitCoachVisibilitySubtitle;

  /// No description provided for @fitbitCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Fitbit.'**
  String get fitbitCoachVisibilitySaveFailed;

  /// No description provided for @fitbitMetricActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité / entraînements / pas'**
  String get fitbitMetricActivity;

  /// No description provided for @fitbitMetricHeartrate.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence cardiaque'**
  String get fitbitMetricHeartrate;

  /// No description provided for @fitbitMetricSleep.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get fitbitMetricSleep;

  /// No description provided for @fitbitMetricProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get fitbitMetricProfile;

  /// No description provided for @fitbitMetricBody.
  ///
  /// In fr, this message translates to:
  /// **'Poids / mensurations'**
  String get fitbitMetricBody;

  /// No description provided for @fitbitCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter le compte Fitbit de {playerName}'**
  String fitbitCoachConnectSubtitle(String playerName);

  /// No description provided for @fitbitCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fitbit connecté pour {playerName}'**
  String fitbitCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @appleHealthConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte Apple Forme pour importer entraînements, fréquence cardiaque et énergie active depuis l\'app Santé (iOS uniquement)'**
  String get appleHealthConnectToggleSubtitle;

  /// No description provided for @appleHealthConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apple Forme connecté — synchronisation complète des entraînements à venir (Phase 2)'**
  String get appleHealthConnectToggleConnectedSubtitle;

  /// No description provided for @appleHealthConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Apple Forme connecté.'**
  String get appleHealthConnectSuccess;

  /// No description provided for @appleHealthConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Apple Forme a échoué. Réessayez.'**
  String get appleHealthConnectFailed;

  /// No description provided for @appleHealthConnectDenied.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès Santé a été refusé. Active-le dans Réglages → Santé → Accès aux données et appareils → Grinta.'**
  String get appleHealthConnectDenied;

  /// No description provided for @appleHealthConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Apple Forme.'**
  String get appleHealthConnectAuthRequired;

  /// No description provided for @appleHealthIosOnlyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Apple Forme est disponible uniquement sur iPhone. Les données sont lues sur l\'appareil via Apple HealthKit.'**
  String get appleHealthIosOnlyMessage;

  /// No description provided for @appleHealthDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Apple Forme a échoué.'**
  String get appleHealthDisconnectFailed;

  /// No description provided for @appleHealthCoachVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité coach'**
  String get appleHealthCoachVisibilityTitle;

  /// No description provided for @appleHealthCoachVisibilitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser ton coach à voir cette donnée'**
  String get appleHealthCoachVisibilitySubtitle;

  /// No description provided for @appleHealthCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Apple Forme.'**
  String get appleHealthCoachVisibilitySaveFailed;

  /// No description provided for @appleHealthMetricActivity.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements / activité'**
  String get appleHealthMetricActivity;

  /// No description provided for @appleHealthMetricHeartrate.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence cardiaque'**
  String get appleHealthMetricHeartrate;

  /// No description provided for @appleHealthMetricActiveEnergy.
  ///
  /// In fr, this message translates to:
  /// **'Énergie active'**
  String get appleHealthMetricActiveEnergy;

  /// No description provided for @appleHealthMetricSleep.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get appleHealthMetricSleep;

  /// No description provided for @appleHealthCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter Apple Forme pour {playerName}'**
  String appleHealthCoachConnectSubtitle(String playerName);

  /// No description provided for @appleHealthCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apple Forme connecté pour {playerName}'**
  String appleHealthCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @googleHealthConnectToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte Google Fit pour importer entraînements, fréquence cardiaque et énergie active depuis Health Connect (Android uniquement)'**
  String get googleHealthConnectToggleSubtitle;

  /// No description provided for @googleHealthConnectToggleConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Google Fit / Health Connect connecté — synchronisation complète des entraînements à venir (Phase 2)'**
  String get googleHealthConnectToggleConnectedSubtitle;

  /// No description provided for @googleHealthConnectSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Google Fit / Health Connect connecté.'**
  String get googleHealthConnectSuccess;

  /// No description provided for @googleHealthConnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google Fit / Health Connect a échoué. Réessayez.'**
  String get googleHealthConnectFailed;

  /// No description provided for @googleHealthConnectDenied.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès Health Connect a été refusé. Active-le dans Health Connect → Autorisations des applis → Grinta.'**
  String get googleHealthConnectDenied;

  /// No description provided for @googleHealthConnectAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Grinta pour lier Google Fit / Health Connect.'**
  String get googleHealthConnectAuthRequired;

  /// No description provided for @googleHealthAndroidOnlyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Google Fit / Health Connect est disponible uniquement sur Android. Les données sont lues sur l\'appareil via Health Connect.'**
  String get googleHealthAndroidOnlyMessage;

  /// No description provided for @googleHealthDisconnectFailed.
  ///
  /// In fr, this message translates to:
  /// **'La déconnexion Google Fit / Health Connect a échoué.'**
  String get googleHealthDisconnectFailed;

  /// No description provided for @googleHealthCoachVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité coach'**
  String get googleHealthCoachVisibilityTitle;

  /// No description provided for @googleHealthCoachVisibilitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser ton coach à voir cette donnée'**
  String get googleHealthCoachVisibilitySubtitle;

  /// No description provided for @googleHealthCoachVisibilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les préférences Google Fit / Health Connect.'**
  String get googleHealthCoachVisibilitySaveFailed;

  /// No description provided for @googleHealthMetricActivity.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements / activité'**
  String get googleHealthMetricActivity;

  /// No description provided for @googleHealthMetricHeartrate.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence cardiaque'**
  String get googleHealthMetricHeartrate;

  /// No description provided for @googleHealthMetricActiveEnergy.
  ///
  /// In fr, this message translates to:
  /// **'Énergie active'**
  String get googleHealthMetricActiveEnergy;

  /// No description provided for @googleHealthMetricSleep.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get googleHealthMetricSleep;

  /// No description provided for @googleHealthCoachConnectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter Google Fit / Health Connect pour {playerName}'**
  String googleHealthCoachConnectSubtitle(String playerName);

  /// No description provided for @googleHealthCoachConnectConnectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Google Fit / Health Connect connecté pour {playerName}'**
  String googleHealthCoachConnectConnectedSubtitle(String playerName);

  /// No description provided for @createTrainingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle session d\'entraînement'**
  String get createTrainingTitle;

  /// No description provided for @createTrainingTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get createTrainingTeam;

  /// No description provided for @createTrainingTeamRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une équipe'**
  String get createTrainingTeamRequired;

  /// No description provided for @createTrainingDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get createTrainingDate;

  /// No description provided for @createTrainingTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get createTrainingTime;

  /// No description provided for @createTrainingDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get createTrainingDuration;

  /// No description provided for @createTrainingDurationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String createTrainingDurationMinutes(int minutes);

  /// No description provided for @createTrainingRecurrent.
  ///
  /// In fr, this message translates to:
  /// **'Récurrent'**
  String get createTrainingRecurrent;

  /// No description provided for @createTrainingRecurrentDays.
  ///
  /// In fr, this message translates to:
  /// **'Jour(s) de la semaine'**
  String get createTrainingRecurrentDays;

  /// No description provided for @createTrainingRecurrentDaysRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins un jour'**
  String get createTrainingRecurrentDaysRequired;

  /// No description provided for @createTrainingRecurrentFrom.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get createTrainingRecurrentFrom;

  /// No description provided for @createTrainingRecurrentTo.
  ///
  /// In fr, this message translates to:
  /// **'À'**
  String get createTrainingRecurrentTo;

  /// No description provided for @createTrainingRecurrentInvalidRange.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin ne peut pas être antérieure à la date de début'**
  String get createTrainingRecurrentInvalidRange;

  /// No description provided for @createTrainingWithTracker.
  ///
  /// In fr, this message translates to:
  /// **'Avec tracker GPS'**
  String get createTrainingWithTracker;

  /// No description provided for @createTrainingSelectOwner.
  ///
  /// In fr, this message translates to:
  /// **'Kit tracker (propriétaire)'**
  String get createTrainingSelectOwner;

  /// No description provided for @createTrainingOwnerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un propriétaire tracker'**
  String get createTrainingOwnerRequired;

  /// No description provided for @createTrainingNoOwners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun kit tracker n\'est assigné à cette équipe.'**
  String get createTrainingNoOwners;

  /// No description provided for @createTrainingNoManagedTeams.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne gérez aucune équipe pour cette saison.'**
  String get createTrainingNoManagedTeams;

  /// No description provided for @createTrainingSaved.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 entraînement créé} other{{count} entraînements créés}}'**
  String createTrainingSaved(int count);

  /// No description provided for @createTrainingError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer l\'entraînement. Réessayez.'**
  String get createTrainingError;

  /// No description provided for @createTrainingSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'entraînement'**
  String get createTrainingSubmit;

  /// No description provided for @createTrainingRecurrentConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement récurrent'**
  String get createTrainingRecurrentConfirmTitle;

  /// No description provided for @createTrainingRecurrentConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous créer les récurrences ?'**
  String get createTrainingRecurrentConfirmMessage;

  /// No description provided for @editTrainingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'entraînement'**
  String get editTrainingTitle;

  /// No description provided for @editTrainingSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get editTrainingSubmit;

  /// No description provided for @editTrainingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement modifié'**
  String get editTrainingSaved;

  /// No description provided for @editTrainingError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier l\'entraînement. Réessayez.'**
  String get editTrainingError;

  /// No description provided for @trainingDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'entraînement ?'**
  String get trainingDeleteConfirmTitle;

  /// No description provided for @trainingDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cet entraînement ? Cette action est définitive.'**
  String get trainingDeleteConfirmMessage;

  /// No description provided for @trainingDeleteRecurrentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'entraînement récurrent ?'**
  String get trainingDeleteRecurrentTitle;

  /// No description provided for @trainingDeleteRecurrentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous supprimer toutes les récurrences de cette série ?'**
  String get trainingDeleteRecurrentMessage;

  /// No description provided for @trainingDeleteThisOccurrence.
  ///
  /// In fr, this message translates to:
  /// **'Cette occurrence uniquement'**
  String get trainingDeleteThisOccurrence;

  /// No description provided for @trainingDeleteAllOccurrences.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les occurrences'**
  String get trainingDeleteAllOccurrences;

  /// No description provided for @trainingDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement supprimé'**
  String get trainingDeleted;

  /// No description provided for @trainingDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer l\'entraînement. Réessayez.'**
  String get trainingDeleteError;

  /// No description provided for @finishTrainingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'entraînement'**
  String get finishTrainingTitle;

  /// No description provided for @trainingFinishConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'entraînement ?'**
  String get trainingFinishConfirmTitle;

  /// No description provided for @trainingFinishConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs indisponibles encore marqués présents seront passés absents. Voulez-vous terminer cet entraînement ?'**
  String get trainingFinishConfirmMessage;

  /// No description provided for @trainingFinished.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement terminé'**
  String get trainingFinished;

  /// No description provided for @trainingFinishError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de terminer l\'entraînement. Réessayez.'**
  String get trainingFinishError;

  /// No description provided for @trainingIntenseFinishTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des données capteurs'**
  String get trainingIntenseFinishTitle;

  /// No description provided for @trainingIntenseFinishMessage.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des données des joueurs présents avec capteur assigné. Ne fermez pas cette fenêtre.'**
  String get trainingIntenseFinishMessage;

  /// No description provided for @trainingIntenseResyncButton.
  ///
  /// In fr, this message translates to:
  /// **'Re sync'**
  String get trainingIntenseResyncButton;

  /// No description provided for @trainingIntenseResyncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Resynchroniser les données capteurs'**
  String get trainingIntenseResyncTitle;

  /// No description provided for @trainingIntenseResyncMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récupération des données sur toute la durée de l\'entraînement (début → fin). Ne fermez pas cette fenêtre.'**
  String get trainingIntenseResyncMessage;

  /// No description provided for @trainingIntenseResyncSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Données capteurs resynchronisées.'**
  String get trainingIntenseResyncSuccess;

  /// No description provided for @trainingIntenseFinishSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours…'**
  String get trainingIntenseFinishSyncing;

  /// No description provided for @trainingIntenseFinishStagePending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get trainingIntenseFinishStagePending;

  /// No description provided for @trainingIntenseFinishStageFetching.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des données brutes…'**
  String get trainingIntenseFinishStageFetching;

  /// No description provided for @trainingIntenseFinishStageConverting.
  ///
  /// In fr, this message translates to:
  /// **'Conversion des données…'**
  String get trainingIntenseFinishStageConverting;

  /// No description provided for @trainingIntenseFinishStageAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours…'**
  String get trainingIntenseFinishStageAnalyzing;

  /// No description provided for @trainingIntenseFinishStageDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get trainingIntenseFinishStageDone;

  /// No description provided for @trainingIntenseFinishStageError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get trainingIntenseFinishStageError;

  /// No description provided for @trainingIntenseFinishNoTrackers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur présent n\'a de capteur assigné. Vous pouvez terminer l\'entraînement sans récupération.'**
  String get trainingIntenseFinishNoTrackers;

  /// No description provided for @trainingIntenseFinishPartialError.
  ///
  /// In fr, this message translates to:
  /// **'Certaines récupérations ont échoué. Corrigez le problème puis réessayez.'**
  String get trainingIntenseFinishPartialError;

  /// No description provided for @intenseLiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Live'**
  String get intenseLiveTitle;

  /// No description provided for @intenseLiveOpenTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Voir le live capteurs'**
  String get intenseLiveOpenTooltip;

  /// No description provided for @intenseLiveSelectPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un joueur'**
  String get intenseLiveSelectPlayer;

  /// No description provided for @intenseLiveNoPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur présent avec capteur assigné'**
  String get intenseLiveNoPlayers;

  /// No description provided for @intenseLiveRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get intenseLiveRefresh;

  /// No description provided for @intenseLiveLastUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour à {time}'**
  String intenseLiveLastUpdate(String time);

  /// No description provided for @tabLive.
  ///
  /// In fr, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabLiveShort.
  ///
  /// In fr, this message translates to:
  /// **'Live'**
  String get tabLiveShort;

  /// No description provided for @createMatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle rencontre'**
  String get createMatchTitle;

  /// No description provided for @createMatchTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get createMatchTeam;

  /// No description provided for @createMatchTeamRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une équipe'**
  String get createMatchTeamRequired;

  /// No description provided for @createMatchHome.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre à domicile'**
  String get createMatchHome;

  /// No description provided for @createMatchFriendly.
  ///
  /// In fr, this message translates to:
  /// **'Match amical'**
  String get createMatchFriendly;

  /// No description provided for @createMatchDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get createMatchDate;

  /// No description provided for @createMatchTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get createMatchTime;

  /// No description provided for @createMatchDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get createMatchDuration;

  /// No description provided for @createMatchDurationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String createMatchDurationMinutes(int minutes);

  /// No description provided for @createMatchOpponent.
  ///
  /// In fr, this message translates to:
  /// **'Adversaire'**
  String get createMatchOpponent;

  /// No description provided for @createMatchSelectOpponentClub.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un club'**
  String get createMatchSelectOpponentClub;

  /// No description provided for @createMatchClubNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Club non trouvé'**
  String get createMatchClubNotFound;

  /// No description provided for @createMatchOpponentNameManual.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'adversaire'**
  String get createMatchOpponentNameManual;

  /// No description provided for @createMatchOpponentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l\'adversaire'**
  String get createMatchOpponentRequired;

  /// No description provided for @createMatchVenue.
  ///
  /// In fr, this message translates to:
  /// **'Lieu / adresse du terrain'**
  String get createMatchVenue;

  /// No description provided for @createMatchSurface.
  ///
  /// In fr, this message translates to:
  /// **'Surface de jeu'**
  String get createMatchSurface;

  /// No description provided for @createMatchSurfaceSynthetic.
  ///
  /// In fr, this message translates to:
  /// **'Synthétique'**
  String get createMatchSurfaceSynthetic;

  /// No description provided for @createMatchSurfaceNatural.
  ///
  /// In fr, this message translates to:
  /// **'Pelouse naturelle'**
  String get createMatchSurfaceNatural;

  /// No description provided for @createMatchWithTracker.
  ///
  /// In fr, this message translates to:
  /// **'Avec tracker GPS'**
  String get createMatchWithTracker;

  /// No description provided for @createMatchSelectOwner.
  ///
  /// In fr, this message translates to:
  /// **'Kit tracker (propriétaire)'**
  String get createMatchSelectOwner;

  /// No description provided for @createMatchOwnerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un propriétaire tracker'**
  String get createMatchOwnerRequired;

  /// No description provided for @createMatchNoOwners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun kit tracker n\'est assigné à cette équipe.'**
  String get createMatchNoOwners;

  /// No description provided for @createMatchNoManagedTeams.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne gérez aucune équipe pour cette saison.'**
  String get createMatchNoManagedTeams;

  /// No description provided for @createMatchSaved.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre créée'**
  String get createMatchSaved;

  /// No description provided for @createMatchError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer la rencontre. Réessayez.'**
  String get createMatchError;

  /// No description provided for @createMatchSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer la rencontre'**
  String get createMatchSubmit;

  /// No description provided for @editMatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la rencontre'**
  String get editMatchTitle;

  /// No description provided for @editMatchSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get editMatchSubmit;

  /// No description provided for @editMatchSaved.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre modifiée'**
  String get editMatchSaved;

  /// No description provided for @editMatchError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier la rencontre. Réessayez.'**
  String get editMatchError;

  /// No description provided for @matchDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la rencontre ?'**
  String get matchDeleteConfirmTitle;

  /// No description provided for @matchDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cette rencontre ? Cette action est définitive.'**
  String get matchDeleteConfirmMessage;

  /// No description provided for @matchRemoveFromTeamConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la rencontre du calendrier ?'**
  String get matchRemoveFromTeamConfirmTitle;

  /// No description provided for @matchRemoveFromTeamConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action retire la rencontre du calendrier de votre équipe. La rencontre restera visible pour les autres équipes.'**
  String get matchRemoveFromTeamConfirmMessage;

  /// No description provided for @matchDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre supprimée'**
  String get matchDeleted;

  /// No description provided for @matchRemovedFromTeam.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre retirée du calendrier de votre équipe'**
  String get matchRemovedFromTeam;

  /// No description provided for @matchDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer la rencontre. Réessayez.'**
  String get matchDeleteError;

  /// No description provided for @teamDetailManageUnavailabilities.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les indisponibilités'**
  String get teamDetailManageUnavailabilities;

  /// No description provided for @manageUnavailabilitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Indisponibilités'**
  String get manageUnavailabilitiesTitle;

  /// No description provided for @manageUnavailabilitiesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune indisponibilité pour cette saison.'**
  String get manageUnavailabilitiesEmpty;

  /// No description provided for @manageUnavailabilitiesAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une indisponibilité'**
  String get manageUnavailabilitiesAdd;

  /// No description provided for @manageUnavailabilitiesEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'indisponibilité'**
  String get manageUnavailabilitiesEditTitle;

  /// No description provided for @manageUnavailabilitiesFromDate.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get manageUnavailabilitiesFromDate;

  /// No description provided for @manageUnavailabilitiesToDate.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get manageUnavailabilitiesToDate;

  /// No description provided for @manageUnavailabilitiesType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get manageUnavailabilitiesType;

  /// No description provided for @manageUnavailabilitiesDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get manageUnavailabilitiesDetails;

  /// No description provided for @manageUnavailabilitiesDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Détails optionnels'**
  String get manageUnavailabilitiesDetailsHint;

  /// No description provided for @manageUnavailabilitiesVisible.
  ///
  /// In fr, this message translates to:
  /// **'Visible par l\'équipe'**
  String get manageUnavailabilitiesVisible;

  /// No description provided for @manageUnavailabilitiesVisibleHint.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, seuls les managers voient cette entrée'**
  String get manageUnavailabilitiesVisibleHint;

  /// No description provided for @manageUnavailabilitiesDateRange.
  ///
  /// In fr, this message translates to:
  /// **'{from} – {to}'**
  String manageUnavailabilitiesDateRange(String from, String to);

  /// No description provided for @manageUnavailabilitiesHidden.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get manageUnavailabilitiesHidden;

  /// No description provided for @manageUnavailabilitiesSaved.
  ///
  /// In fr, this message translates to:
  /// **'Indisponibilité enregistrée'**
  String get manageUnavailabilitiesSaved;

  /// No description provided for @manageUnavailabilitiesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Indisponibilité supprimée'**
  String get manageUnavailabilitiesDeleted;

  /// No description provided for @manageUnavailabilitiesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer l\'indisponibilité. Veuillez réessayer.'**
  String get manageUnavailabilitiesError;

  /// No description provided for @manageUnavailabilitiesDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer l\'indisponibilité. Veuillez réessayer.'**
  String get manageUnavailabilitiesDeleteError;

  /// No description provided for @manageUnavailabilitiesDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'indisponibilité ?'**
  String get manageUnavailabilitiesDeleteConfirmTitle;

  /// No description provided for @manageUnavailabilitiesDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get manageUnavailabilitiesDeleteConfirmMessage;

  /// No description provided for @manageUnavailabilitiesInvalidRange.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin ne peut pas être antérieure à la date de début'**
  String get manageUnavailabilitiesInvalidRange;

  /// No description provided for @manageUnavailabilitiesTypeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un type'**
  String get manageUnavailabilitiesTypeRequired;

  /// No description provided for @unavailabilityTypeHoliday.
  ///
  /// In fr, this message translates to:
  /// **'Vacances'**
  String get unavailabilityTypeHoliday;

  /// No description provided for @unavailabilityTypeUnwell.
  ///
  /// In fr, this message translates to:
  /// **'Malade'**
  String get unavailabilityTypeUnwell;

  /// No description provided for @unavailabilityTypeInjured.
  ///
  /// In fr, this message translates to:
  /// **'Blessé'**
  String get unavailabilityTypeInjured;

  /// No description provided for @unavailabilityTypeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre motif'**
  String get unavailabilityTypeOther;

  /// No description provided for @teamStatsScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques — {teamName}'**
  String teamStatsScreenTitle(String teamName);

  /// No description provided for @teamStatsTabAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get teamStatsTabAnalysis;

  /// No description provided for @teamStatsTabCalendars.
  ///
  /// In fr, this message translates to:
  /// **'Calendriers'**
  String get teamStatsTabCalendars;

  /// No description provided for @teamStatsCompetitionFilterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compétitions'**
  String get teamStatsCompetitionFilterLabel;

  /// No description provided for @teamStatsOpponentFilterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Club'**
  String get teamStatsOpponentFilterLabel;

  /// No description provided for @teamStatsNoOpponents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun club dans cette compétition'**
  String get teamStatsNoOpponents;

  /// No description provided for @teamStatsTabTrainings.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements'**
  String get teamStatsTabTrainings;

  /// No description provided for @teamStatsTabOpponents.
  ///
  /// In fr, this message translates to:
  /// **'Adversaires'**
  String get teamStatsTabOpponents;

  /// No description provided for @teamStatsSubTabMatches.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres'**
  String get teamStatsSubTabMatches;

  /// No description provided for @teamStatsSubTabRanking.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get teamStatsSubTabRanking;

  /// No description provided for @teamStatsSubTabGoals.
  ///
  /// In fr, this message translates to:
  /// **'Buts'**
  String get teamStatsSubTabGoals;

  /// No description provided for @teamStatsSubTabPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get teamStatsSubTabPlayers;

  /// No description provided for @teamStatsSubTabTypicalTeam.
  ///
  /// In fr, this message translates to:
  /// **'Equipe type'**
  String get teamStatsSubTabTypicalTeam;

  /// No description provided for @teamStatsTypicalTeamStartersSection.
  ///
  /// In fr, this message translates to:
  /// **'Titulaires probables'**
  String get teamStatsTypicalTeamStartersSection;

  /// No description provided for @teamStatsTypicalTeamSubstitutesSection.
  ///
  /// In fr, this message translates to:
  /// **'Remplaçants probables'**
  String get teamStatsTypicalTeamSubstitutesSection;

  /// No description provided for @teamStatsTypicalTeamStartsLabel.
  ///
  /// In fr, this message translates to:
  /// **'{starts}/{total} titularisations'**
  String teamStatsTypicalTeamStartsLabel(int starts, int total);

  /// No description provided for @teamStatsTypicalTeamSubsLabel.
  ///
  /// In fr, this message translates to:
  /// **'{subs}/{total} remplacements'**
  String teamStatsTypicalTeamSubsLabel(int subs, int total);

  /// No description provided for @teamStatsTypicalTeamNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de composition disponible pour cet adversaire'**
  String get teamStatsTypicalTeamNoData;

  /// No description provided for @teamStatsTypicalTeamIncompleteStarters.
  ///
  /// In fr, this message translates to:
  /// **'Seulement {count} joueurs avec des données de titularisation'**
  String teamStatsTypicalTeamIncompleteStarters(int count);

  /// No description provided for @teamStatsTypicalTeamMatchesBasis.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur {count, plural, =1{1 match avec composition} other{{count} matchs avec composition}}'**
  String teamStatsTypicalTeamMatchesBasis(int count);

  /// No description provided for @teamStatsRankingAtDate.
  ///
  /// In fr, this message translates to:
  /// **'A date'**
  String get teamStatsRankingAtDate;

  /// No description provided for @teamStatsRankingEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Evolution'**
  String get teamStatsRankingEvolution;

  /// No description provided for @teamStatsRankingNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucun classement disponible pour cette compétition'**
  String get teamStatsRankingNoData;

  /// No description provided for @teamStatsRankingSelectCompetition.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une compétition pour afficher le classement'**
  String get teamStatsRankingSelectCompetition;

  /// No description provided for @teamStatsRankingColumnRank.
  ///
  /// In fr, this message translates to:
  /// **'#'**
  String get teamStatsRankingColumnRank;

  /// No description provided for @teamStatsRankingColumnTeam.
  ///
  /// In fr, this message translates to:
  /// **'Equipe'**
  String get teamStatsRankingColumnTeam;

  /// No description provided for @teamStatsRankingColumnPts.
  ///
  /// In fr, this message translates to:
  /// **'Pts'**
  String get teamStatsRankingColumnPts;

  /// No description provided for @teamStatsRankingColumnPlayed.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get teamStatsRankingColumnPlayed;

  /// No description provided for @teamStatsRankingColumnWon.
  ///
  /// In fr, this message translates to:
  /// **'G'**
  String get teamStatsRankingColumnWon;

  /// No description provided for @teamStatsRankingColumnDrawn.
  ///
  /// In fr, this message translates to:
  /// **'N'**
  String get teamStatsRankingColumnDrawn;

  /// No description provided for @teamStatsRankingColumnLost.
  ///
  /// In fr, this message translates to:
  /// **'P'**
  String get teamStatsRankingColumnLost;

  /// No description provided for @teamStatsRankingColumnDiff.
  ///
  /// In fr, this message translates to:
  /// **'+/-'**
  String get teamStatsRankingColumnDiff;

  /// No description provided for @teamStatsRankingAddClubs.
  ///
  /// In fr, this message translates to:
  /// **'Comparer des clubs'**
  String get teamStatsRankingAddClubs;

  /// No description provided for @teamStatsRankingSelectClubsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner des clubs à comparer'**
  String get teamStatsRankingSelectClubsTitle;

  /// No description provided for @teamStatsRankingOwnTeamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre équipe'**
  String get teamStatsRankingOwnTeamLabel;

  /// No description provided for @teamStatsRankingTooltipRank.
  ///
  /// In fr, this message translates to:
  /// **'Rang {rank}'**
  String teamStatsRankingTooltipRank(String rank);

  /// No description provided for @teamStatsAllCompetitions.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les compétitions'**
  String get teamStatsAllCompetitions;

  /// No description provided for @teamStatsContentComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Contenu à venir'**
  String get teamStatsContentComingSoon;

  /// No description provided for @teamStatsNoCompetitions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compétition disponible'**
  String get teamStatsNoCompetitions;

  /// No description provided for @teamStatsPlayerComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Vue joueur à venir'**
  String get teamStatsPlayerComingSoon;

  /// No description provided for @teamStatsPeriodFullSeason.
  ///
  /// In fr, this message translates to:
  /// **'Saison complète'**
  String get teamStatsPeriodFullSeason;

  /// No description provided for @teamStatsPeriodFirstHalf.
  ///
  /// In fr, this message translates to:
  /// **'1ère partie'**
  String get teamStatsPeriodFirstHalf;

  /// No description provided for @teamStatsPeriodSecondHalf.
  ///
  /// In fr, this message translates to:
  /// **'2ème partie'**
  String get teamStatsPeriodSecondHalf;

  /// No description provided for @teamStatsNoPlayedMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match joué sur cette période'**
  String get teamStatsNoPlayedMatches;

  /// No description provided for @teamStatsWdlMatchesDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'{outcome} — {period}'**
  String teamStatsWdlMatchesDialogTitle(String outcome, String period);

  /// No description provided for @teamStatsTrendLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tendance'**
  String get teamStatsTrendLabel;

  /// No description provided for @teamStatsTrendUp.
  ///
  /// In fr, this message translates to:
  /// **'En progression'**
  String get teamStatsTrendUp;

  /// No description provided for @teamStatsTrendDown.
  ///
  /// In fr, this message translates to:
  /// **'En baisse'**
  String get teamStatsTrendDown;

  /// No description provided for @teamStatsTrendFlat.
  ///
  /// In fr, this message translates to:
  /// **'Stable'**
  String get teamStatsTrendFlat;

  /// No description provided for @teamStatsTrendInsufficientData.
  ///
  /// In fr, this message translates to:
  /// **'Données insuffisantes'**
  String get teamStatsTrendInsufficientData;

  /// No description provided for @teamStatsGoalsScored.
  ///
  /// In fr, this message translates to:
  /// **'Buts marqués'**
  String get teamStatsGoalsScored;

  /// No description provided for @teamStatsGoalsConceded.
  ///
  /// In fr, this message translates to:
  /// **'Buts encaissés'**
  String get teamStatsGoalsConceded;

  /// No description provided for @teamStatsGoalsTrendScored.
  ///
  /// In fr, this message translates to:
  /// **'Buts marqués'**
  String get teamStatsGoalsTrendScored;

  /// No description provided for @teamStatsGoalsTrendConceded.
  ///
  /// In fr, this message translates to:
  /// **'Buts encaissés'**
  String get teamStatsGoalsTrendConceded;

  /// No description provided for @teamStatsGoalsAvgPerMatch.
  ///
  /// In fr, this message translates to:
  /// **'{avg}/match'**
  String teamStatsGoalsAvgPerMatch(double avg);

  /// No description provided for @teamStatsGoalsMatchCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matchs}}'**
  String teamStatsGoalsMatchCount(int count);

  /// No description provided for @teamStatsAvgPointsPerMatch.
  ///
  /// In fr, this message translates to:
  /// **'{avg}'**
  String teamStatsAvgPointsPerMatch(double avg);

  /// No description provided for @teamStatsPlayersColumnPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get teamStatsPlayersColumnPlayer;

  /// No description provided for @teamStatsPlayersColumnConvocations.
  ///
  /// In fr, this message translates to:
  /// **'Convo'**
  String get teamStatsPlayersColumnConvocations;

  /// No description provided for @teamStatsPlayersColumnStarts.
  ///
  /// In fr, this message translates to:
  /// **'Titu.'**
  String get teamStatsPlayersColumnStarts;

  /// No description provided for @teamStatsPlayersColumnPlayTime.
  ///
  /// In fr, this message translates to:
  /// **'Tps jeu'**
  String get teamStatsPlayersColumnPlayTime;

  /// No description provided for @teamStatsPlayersColumnGoals.
  ///
  /// In fr, this message translates to:
  /// **'Buts'**
  String get teamStatsPlayersColumnGoals;

  /// No description provided for @teamStatsPlayersNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée joueur sur cette période'**
  String get teamStatsPlayersNoData;

  /// No description provided for @teamStatsPlayersPlayTimeMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String teamStatsPlayersPlayTimeMinutes(int minutes);

  /// No description provided for @teamStatsAllMonths.
  ///
  /// In fr, this message translates to:
  /// **'Tous les mois'**
  String get teamStatsAllMonths;

  /// No description provided for @teamStatsTrainingsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 entraînement} other{{count} entraînements}}'**
  String teamStatsTrainingsCount(int count);

  /// No description provided for @teamStatsTrainingsAttendanceRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de présence'**
  String get teamStatsTrainingsAttendanceRate;

  /// No description provided for @teamStatsTrainingsAttendanceRateValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String teamStatsTrainingsAttendanceRateValue(String value);

  /// No description provided for @teamStatsTrainingsNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucun entraînement passé sur cette période'**
  String get teamStatsTrainingsNoData;

  /// No description provided for @teamStatsTrainingsNoSeasonMonths.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mois disponible pour cette saison'**
  String get teamStatsTrainingsNoSeasonMonths;

  /// No description provided for @teamStatsTrainingsColumnPresent.
  ///
  /// In fr, this message translates to:
  /// **'Prés.'**
  String get teamStatsTrainingsColumnPresent;

  /// No description provided for @teamStatsTrainingsColumnAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Abs.'**
  String get teamStatsTrainingsColumnAbsent;

  /// No description provided for @teamStatsTrainingsColumnAttendanceRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get teamStatsTrainingsColumnAttendanceRate;

  /// No description provided for @teamStatsTrainingsPlayersNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée joueur sur cette période'**
  String get teamStatsTrainingsPlayersNoData;

  /// No description provided for @teamStatsTrainingsGlobalSection.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get teamStatsTrainingsGlobalSection;

  /// No description provided for @teamStatsTrainingsPersonalSection.
  ///
  /// In fr, this message translates to:
  /// **'Mes stats'**
  String get teamStatsTrainingsPersonalSection;

  /// No description provided for @teamStatsCalendarNoMatchdays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match pour cette compétition'**
  String get teamStatsCalendarNoMatchdays;

  /// No description provided for @teamStatsCalendarNoMatchesForMatchday.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match pour cette journée'**
  String get teamStatsCalendarNoMatchesForMatchday;

  /// No description provided for @teamStatsCalendarDatesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dates'**
  String get teamStatsCalendarDatesLabel;

  /// No description provided for @teamStatsCalendarNoMatchDates.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date programmée'**
  String get teamStatsCalendarNoMatchDates;

  /// No description provided for @teamStatsCalendarDateSeparator.
  ///
  /// In fr, this message translates to:
  /// **', '**
  String get teamStatsCalendarDateSeparator;

  /// No description provided for @askDiegoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ask Gio'**
  String get askDiegoTitle;

  /// No description provided for @askDiegoWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! Je suis Gio. Je peux vous aider avec votre agenda, votre prochain adversaire ou les statistiques de votre équipe. Posez-moi une question ou utilisez le micro.'**
  String get askDiegoWelcome;

  /// No description provided for @askDiegoInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Demandez à Gio…'**
  String get askDiegoInputHint;

  /// No description provided for @askDiegoSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get askDiegoSend;

  /// No description provided for @askDiegoListen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter la réponse'**
  String get askDiegoListen;

  /// No description provided for @askDiegoOpenScreen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get askDiegoOpenScreen;

  /// No description provided for @askDiegoOpenOpponentStats.
  ///
  /// In fr, this message translates to:
  /// **'Voir les stats adversaire'**
  String get askDiegoOpenOpponentStats;

  /// No description provided for @askDiegoStartListening.
  ///
  /// In fr, this message translates to:
  /// **'Dicter une question'**
  String get askDiegoStartListening;

  /// No description provided for @askDiegoStopListening.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter l\'écoute'**
  String get askDiegoStopListening;

  /// No description provided for @askDiegoSpeechUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La reconnaissance vocale n\'est pas disponible sur cet appareil.'**
  String get askDiegoSpeechUnavailable;

  /// No description provided for @askDiegoSpeechPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation micro ou reconnaissance vocale refusée. Activez-la dans Réglages.'**
  String get askDiegoSpeechPermissionDenied;

  /// No description provided for @askDiegoSpeechError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la reconnaissance vocale : {reason}'**
  String askDiegoSpeechError(String reason);

  /// No description provided for @askDiegoEmptyResponse.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas de réponse pour le moment.'**
  String get askDiegoEmptyResponse;

  /// No description provided for @askDiegoCloseSpeedDial.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get askDiegoCloseSpeedDial;

  /// No description provided for @askDiegoNavigationUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Navigation non reconnue : {route}'**
  String askDiegoNavigationUnknown(String route);

  /// No description provided for @askDiegoNavigationAgendaHint.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'onglet Agenda pour voir votre calendrier.'**
  String get askDiegoNavigationAgendaHint;

  /// No description provided for @askDiegoNavigationMatchMissing.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant de match manquant pour la navigation.'**
  String get askDiegoNavigationMatchMissing;

  /// No description provided for @askDiegoNavigationMatchNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Match introuvable.'**
  String get askDiegoNavigationMatchNotFound;

  /// No description provided for @askDiegoNavigationNoTeam.
  ///
  /// In fr, this message translates to:
  /// **'Aucune équipe sélectionnée.'**
  String get askDiegoNavigationNoTeam;

  /// No description provided for @askDiegoNavigationOpponentsManagerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Les statistiques adversaires sont réservées aux entraîneurs.'**
  String get askDiegoNavigationOpponentsManagerOnly;

  /// No description provided for @askDiegoNavigationOpponentsPremiumOnly.
  ///
  /// In fr, this message translates to:
  /// **'Les statistiques adversaires nécessitent un abonnement.'**
  String get askDiegoNavigationOpponentsPremiumOnly;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsRemindersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels locaux pour entraînements et matchs.'**
  String get settingsRemindersSubtitle;

  /// No description provided for @settingsRemindersEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Activer les rappels'**
  String get settingsRemindersEnabled;

  /// No description provided for @settingsQuietDaysLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jours silencieux'**
  String get settingsQuietDaysLabel;

  /// No description provided for @settingsQuietHoursLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heures silencieuses'**
  String get settingsQuietHoursLabel;

  /// No description provided for @settingsQuietHoursStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get settingsQuietHoursStart;

  /// No description provided for @settingsQuietHoursEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get settingsQuietHoursEnd;

  /// No description provided for @settingsMorningReminderHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel matinal'**
  String get settingsMorningReminderHour;

  /// No description provided for @reminderWeekdayMon.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get reminderWeekdayMon;

  /// No description provided for @reminderWeekdayTue.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get reminderWeekdayTue;

  /// No description provided for @reminderWeekdayWed.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get reminderWeekdayWed;

  /// No description provided for @reminderWeekdayThu.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get reminderWeekdayThu;

  /// No description provided for @reminderWeekdayFri.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get reminderWeekdayFri;

  /// No description provided for @reminderWeekdaySat.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get reminderWeekdaySat;

  /// No description provided for @reminderWeekdaySun.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get reminderWeekdaySun;

  /// No description provided for @reminderTrainingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement aujourd\'hui'**
  String get reminderTrainingTitle;

  /// No description provided for @reminderTrainingBody.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement aujourd\'hui à {time}, préviens ton coach si tu es absent'**
  String reminderTrainingBody(String time);

  /// No description provided for @reminderMatchOpponentStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Match aujourd\'hui'**
  String get reminderMatchOpponentStatsTitle;

  /// No description provided for @reminderMatchOpponentStatsBody.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui à {time}, tu rencontres {opponent} — découvre ses statistiques'**
  String reminderMatchOpponentStatsBody(String time, String opponent);

  /// No description provided for @trainingPresenceConfirmPresent.
  ///
  /// In fr, this message translates to:
  /// **'Je serai présent'**
  String get trainingPresenceConfirmPresent;

  /// No description provided for @trainingPresenceConfirmAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Je serai absent'**
  String get trainingPresenceConfirmAbsent;

  /// No description provided for @trainingPresenceConfirmedPresent.
  ///
  /// In fr, this message translates to:
  /// **'Présence confirmée'**
  String get trainingPresenceConfirmedPresent;

  /// No description provided for @trainingPresenceConfirmedAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absence signalée'**
  String get trainingPresenceConfirmedAbsent;

  /// No description provided for @matchDetailOpponentStats.
  ///
  /// In fr, this message translates to:
  /// **'Stats adversaire'**
  String get matchDetailOpponentStats;

  /// No description provided for @adminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Outils d\'administration de la plateforme.'**
  String get adminSubtitle;

  /// No description provided for @adminPromoCodesSection.
  ///
  /// In fr, this message translates to:
  /// **'Codes promo'**
  String get adminPromoCodesSection;

  /// No description provided for @adminPromoCodesSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créer et gérer les codes promo d\'abonnement.'**
  String get adminPromoCodesSectionDesc;

  /// No description provided for @adminPromoCodesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Codes promo'**
  String get adminPromoCodesTitle;

  /// No description provided for @adminPromoCodeCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un code'**
  String get adminPromoCodeCreate;

  /// No description provided for @adminPromoCodesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les codes promo.'**
  String get adminPromoCodesLoadError;

  /// No description provided for @adminPromoCodesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code promo pour le moment.'**
  String get adminPromoCodesEmpty;

  /// No description provided for @adminPromoCodeUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le code promo.'**
  String get adminPromoCodeUpdateFailed;

  /// No description provided for @adminPromoCodeCreated.
  ///
  /// In fr, this message translates to:
  /// **'Code promo créé.'**
  String get adminPromoCodeCreated;

  /// No description provided for @adminPromoCodeEntitlementLabel.
  ///
  /// In fr, this message translates to:
  /// **'Droit : {entitlement}'**
  String adminPromoCodeEntitlementLabel(String entitlement);

  /// No description provided for @adminPromoCodeUsageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations : {used} / {max}'**
  String adminPromoCodeUsageLabel(int used, int max);

  /// No description provided for @adminPromoCodeDurationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée : {days} jours'**
  String adminPromoCodeDurationLabel(int days);

  /// No description provided for @adminPromoCodeTeamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Club : {teamId}'**
  String adminPromoCodeTeamLabel(String teamId);

  /// No description provided for @adminPromoCodeExpiresLabel.
  ///
  /// In fr, this message translates to:
  /// **'Expire le : {date}'**
  String adminPromoCodeExpiresLabel(String date);

  /// No description provided for @adminPromoCodeStatusInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get adminPromoCodeStatusInactive;

  /// No description provided for @adminPromoCodeStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get adminPromoCodeStatusExpired;

  /// No description provided for @adminPromoCodeStatusExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get adminPromoCodeStatusExhausted;

  /// No description provided for @adminPromoCodeStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminPromoCodeStatusActive;

  /// No description provided for @adminPromoCodeFieldCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get adminPromoCodeFieldCode;

  /// No description provided for @adminPromoCodeFieldCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir au moins 4 caractères.'**
  String get adminPromoCodeFieldCodeInvalid;

  /// No description provided for @adminPromoCodeFieldEntitlement.
  ///
  /// In fr, this message translates to:
  /// **'Droit'**
  String get adminPromoCodeFieldEntitlement;

  /// No description provided for @adminPromoCodeFieldMaxUses.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'utilisations max.'**
  String get adminPromoCodeFieldMaxUses;

  /// No description provided for @adminPromoCodeFieldMaxUsesInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre supérieur à 0.'**
  String get adminPromoCodeFieldMaxUsesInvalid;

  /// No description provided for @adminPromoCodeFieldDurationDays.
  ///
  /// In fr, this message translates to:
  /// **'Durée d\'abonnement (jours)'**
  String get adminPromoCodeFieldDurationDays;

  /// No description provided for @adminPromoCodeFieldDurationDaysInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre supérieur à 0.'**
  String get adminPromoCodeFieldDurationDaysInvalid;

  /// No description provided for @adminPromoCodeFieldTeamId.
  ///
  /// In fr, this message translates to:
  /// **'ID club (optionnel)'**
  String get adminPromoCodeFieldTeamId;

  /// No description provided for @adminPromoCodeFieldTeamIdHint.
  ///
  /// In fr, this message translates to:
  /// **'Limiter l\'utilisation aux membres de ce club.'**
  String get adminPromoCodeFieldTeamIdHint;

  /// No description provided for @adminPromoCodeFieldExpiresOptional.
  ///
  /// In fr, this message translates to:
  /// **'Définir une date d\'expiration (optionnel)'**
  String get adminPromoCodeFieldExpiresOptional;

  /// No description provided for @adminPromoCodeAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo existe déjà.'**
  String get adminPromoCodeAlreadyExists;

  /// No description provided for @adminPromoCodeCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le code promo.'**
  String get adminPromoCodeCreateFailed;

  /// No description provided for @adminPromoCodePermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Un accès admin est requis pour gérer les codes promo.'**
  String get adminPromoCodePermissionDenied;

  /// No description provided for @adminPromoCodeAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour créer un code promo.'**
  String get adminPromoCodeAuthRequired;

  /// No description provided for @adminPromoCodeActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get adminPromoCodeActions;

  /// No description provided for @adminPromoCodeEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get adminPromoCodeEdit;

  /// No description provided for @adminPromoCodeEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code promo'**
  String get adminPromoCodeEditTitle;

  /// No description provided for @adminPromoCodeDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get adminPromoCodeDelete;

  /// No description provided for @adminPromoCodeDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le code promo ?'**
  String get adminPromoCodeDeleteConfirmTitle;

  /// No description provided for @adminPromoCodeDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer le code {code} ? Cette action est définitive.'**
  String adminPromoCodeDeleteConfirmMessage(String code);

  /// No description provided for @adminPromoCodeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Code promo supprimé.'**
  String get adminPromoCodeDeleted;

  /// No description provided for @adminPromoCodeDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le code promo.'**
  String get adminPromoCodeDeleteFailed;

  /// No description provided for @adminPromoCodeUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Code promo mis à jour.'**
  String get adminPromoCodeUpdated;

  /// No description provided for @adminPromoCodeSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get adminPromoCodeSave;

  /// No description provided for @adminPromoCodeFieldCodeReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le code ne peut pas être modifié.'**
  String get adminPromoCodeFieldCodeReadOnly;

  /// No description provided for @adminPromoCodeFieldMaxUsesBelowUsed.
  ///
  /// In fr, this message translates to:
  /// **'Le nombre max. doit être au moins {used} (déjà utilisé).'**
  String adminPromoCodeFieldMaxUsesBelowUsed(int used);

  /// No description provided for @adminPromoCodeFieldActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminPromoCodeFieldActive;

  /// No description provided for @adminPromoCodeClearExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la date d\'expiration'**
  String get adminPromoCodeClearExpiry;

  /// No description provided for @adminPromoCodeNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Code promo introuvable.'**
  String get adminPromoCodeNotFound;

  /// No description provided for @adminTrackerOwnersSection.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaires trackers'**
  String get adminTrackerOwnersSection;

  /// No description provided for @adminTrackerOwnersSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créer et gérer les propriétaires de trackers.'**
  String get adminTrackerOwnersSectionDesc;

  /// No description provided for @adminTrackerOwnersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaires trackers'**
  String get adminTrackerOwnersTitle;

  /// No description provided for @adminTrackerOwnersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun propriétaire pour le moment.'**
  String get adminTrackerOwnersEmpty;

  /// No description provided for @adminTrackerOwnersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les propriétaires.'**
  String get adminTrackerOwnersLoadError;

  /// No description provided for @adminTrackerOwnerCreate.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un propriétaire'**
  String get adminTrackerOwnerCreate;

  /// No description provided for @adminTrackerOwnerCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un propriétaire'**
  String get adminTrackerOwnerCreateTitle;

  /// No description provided for @adminTrackerOwnerEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le propriétaire'**
  String get adminTrackerOwnerEditTitle;

  /// No description provided for @adminTrackerOwnerFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get adminTrackerOwnerFieldName;

  /// No description provided for @adminTrackerOwnerFieldEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get adminTrackerOwnerFieldEmail;

  /// No description provided for @adminTrackerOwnerFieldFirstname.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get adminTrackerOwnerFieldFirstname;

  /// No description provided for @adminTrackerOwnerFieldLastname.
  ///
  /// In fr, this message translates to:
  /// **'Nom de famille'**
  String get adminTrackerOwnerFieldLastname;

  /// No description provided for @adminTrackerOwnerFieldActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminTrackerOwnerFieldActive;

  /// No description provided for @adminTrackerOwnerFieldTypeTracker.
  ///
  /// In fr, this message translates to:
  /// **'Type de tracker'**
  String get adminTrackerOwnerFieldTypeTracker;

  /// No description provided for @adminTrackerOwnerTypeInspirit.
  ///
  /// In fr, this message translates to:
  /// **'Inspirit'**
  String get adminTrackerOwnerTypeInspirit;

  /// No description provided for @adminTrackerOwnerTypeFootbar.
  ///
  /// In fr, this message translates to:
  /// **'Footbar'**
  String get adminTrackerOwnerTypeFootbar;

  /// No description provided for @adminTrackerOwnerTypeIntense.
  ///
  /// In fr, this message translates to:
  /// **'Intense (SIM, flux cloud)'**
  String get adminTrackerOwnerTypeIntense;

  /// No description provided for @adminTrackerOwnerFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get adminTrackerOwnerFieldRequired;

  /// No description provided for @adminTrackerOwnerFieldEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get adminTrackerOwnerFieldEmailInvalid;

  /// No description provided for @adminTrackerOwnerStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminTrackerOwnerStatusActive;

  /// No description provided for @adminTrackerOwnerStatusInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get adminTrackerOwnerStatusInactive;

  /// No description provided for @adminTrackerOwnerSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get adminTrackerOwnerSave;

  /// No description provided for @adminTrackerOwnerDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get adminTrackerOwnerDelete;

  /// No description provided for @adminTrackerOwnerDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le propriétaire ?'**
  String get adminTrackerOwnerDeleteConfirmTitle;

  /// No description provided for @adminTrackerOwnerDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer {name} ? Cette action est définitive.'**
  String adminTrackerOwnerDeleteConfirmMessage(String name);

  /// No description provided for @adminTrackerOwnerCreated.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire créé.'**
  String get adminTrackerOwnerCreated;

  /// No description provided for @adminTrackerOwnerUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire mis à jour.'**
  String get adminTrackerOwnerUpdated;

  /// No description provided for @adminTrackerOwnerDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire supprimé.'**
  String get adminTrackerOwnerDeleted;

  /// No description provided for @adminTrackerOwnerSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer le propriétaire.'**
  String get adminTrackerOwnerSaveFailed;

  /// No description provided for @adminTrackerOwnerDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le propriétaire.'**
  String get adminTrackerOwnerDeleteFailed;

  /// No description provided for @adminTrackerOwnerPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Un accès administrateur est requis pour gérer les propriétaires.'**
  String get adminTrackerOwnerPermissionDenied;

  /// No description provided for @adminTrackerDevicesSection.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des trackers'**
  String get adminTrackerDevicesSection;

  /// No description provided for @adminTrackerDevicesSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser, affecter et gérer les devices trackers.'**
  String get adminTrackerDevicesSectionDesc;

  /// No description provided for @adminTrackerDevicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des trackers'**
  String get adminTrackerDevicesTitle;

  /// No description provided for @adminTrackerDevicesManageAction.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des trackers'**
  String get adminTrackerDevicesManageAction;

  /// No description provided for @adminTrackerDevicesShowUnassigned.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les devices sans affectation'**
  String get adminTrackerDevicesShowUnassigned;

  /// No description provided for @adminTrackerDevicesSelectOwner.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un responsable'**
  String get adminTrackerDevicesSelectOwner;

  /// No description provided for @adminTrackerDevicesResetFilter.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get adminTrackerDevicesResetFilter;

  /// No description provided for @adminTrackerDevicesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun device'**
  String get adminTrackerDevicesEmpty;

  /// No description provided for @adminTrackerDevicesEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document dans TRACKER_Device.'**
  String get adminTrackerDevicesEmptySubtitle;

  /// No description provided for @adminTrackerDevicesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les devices.'**
  String get adminTrackerDevicesLoadError;

  /// No description provided for @adminTrackerDevicesSource.
  ///
  /// In fr, this message translates to:
  /// **'Source : {provider}'**
  String adminTrackerDevicesSource(String provider);

  /// No description provided for @adminTrackerDevicesSerial.
  ///
  /// In fr, this message translates to:
  /// **'Serial : {serial}'**
  String adminTrackerDevicesSerial(String serial);

  /// No description provided for @adminTrackerDevicesUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Maj : {date}'**
  String adminTrackerDevicesUpdatedAt(String date);

  /// No description provided for @adminTrackerDevicesStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminTrackerDevicesStatusActive;

  /// No description provided for @adminTrackerDevicesStatusInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get adminTrackerDevicesStatusInactive;

  /// No description provided for @adminTrackerDevicesAssign.
  ///
  /// In fr, this message translates to:
  /// **'Affecter'**
  String get adminTrackerDevicesAssign;

  /// No description provided for @adminTrackerDevicesUnassign.
  ///
  /// In fr, this message translates to:
  /// **'Désaffecter'**
  String get adminTrackerDevicesUnassign;

  /// No description provided for @adminTrackerDevicesAssignTitle.
  ///
  /// In fr, this message translates to:
  /// **'Affecter un device'**
  String get adminTrackerDevicesAssignTitle;

  /// No description provided for @adminTrackerDevicesCustomName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (optionnel)'**
  String get adminTrackerDevicesCustomName;

  /// No description provided for @adminTrackerDevicesCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get adminTrackerDevicesCancel;

  /// No description provided for @adminTrackerDevicesValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get adminTrackerDevicesValidate;

  /// No description provided for @adminTrackerDevicesSelectOwnerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un responsable.'**
  String get adminTrackerDevicesSelectOwnerRequired;

  /// No description provided for @adminTrackerDevicesAssignSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Affectation enregistrée.'**
  String get adminTrackerDevicesAssignSuccess;

  /// No description provided for @adminTrackerDevicesUnassignSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Désaffectation enregistrée.'**
  String get adminTrackerDevicesUnassignSuccess;

  /// No description provided for @adminTrackerDevicesError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String adminTrackerDevicesError(String error);

  /// No description provided for @adminTrackerDevicesSyncInspirit.
  ///
  /// In fr, this message translates to:
  /// **'Sync Inspirit'**
  String get adminTrackerDevicesSyncInspirit;

  /// No description provided for @adminTrackerDevicesSyncFootbar.
  ///
  /// In fr, this message translates to:
  /// **'Sync Footbar'**
  String get adminTrackerDevicesSyncFootbar;

  /// No description provided for @adminTrackerDevicesSyncInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation...'**
  String get adminTrackerDevicesSyncInProgress;

  /// No description provided for @adminTrackerDevicesSyncInspiritInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Sync Inspirit (insiders) en cours...'**
  String get adminTrackerDevicesSyncInspiritInProgress;

  /// No description provided for @adminTrackerDevicesSyncFootbarInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Sync Footbar en cours...'**
  String get adminTrackerDevicesSyncFootbarInProgress;

  /// No description provided for @adminTrackerDevicesSyncInspiritSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sync Inspirit : {count} device(s) mis à jour.'**
  String adminTrackerDevicesSyncInspiritSuccess(int count);

  /// No description provided for @adminTrackerDevicesSyncInspiritError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur Sync Inspirit : {error}'**
  String adminTrackerDevicesSyncInspiritError(String error);

  /// No description provided for @adminTrackerDevicesPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Un accès administrateur est requis pour gérer les devices.'**
  String get adminTrackerDevicesPermissionDenied;

  /// No description provided for @adminStreamGroupsSection.
  ///
  /// In fr, this message translates to:
  /// **'Messagerie - Groupe'**
  String get adminStreamGroupsSection;

  /// No description provided for @adminStreamGroupsSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lister et supprimer les groupes de chat GetStream des équipes.'**
  String get adminStreamGroupsSectionDesc;

  /// No description provided for @adminStreamGroupsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messagerie - Groupe'**
  String get adminStreamGroupsTitle;

  /// No description provided for @adminStreamGroupsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe'**
  String get adminStreamGroupsEmpty;

  /// No description provided for @adminStreamGroupsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun canal d\'équipe trouvé sur GetStream.'**
  String get adminStreamGroupsEmptySubtitle;

  /// No description provided for @adminStreamGroupsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les groupes.'**
  String get adminStreamGroupsLoadError;

  /// No description provided for @adminStreamGroupsRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get adminStreamGroupsRefresh;

  /// No description provided for @adminStreamGroupsCid.
  ///
  /// In fr, this message translates to:
  /// **'CID : {cid}'**
  String adminStreamGroupsCid(String cid);

  /// No description provided for @adminStreamGroupsMemberCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} membres'**
  String adminStreamGroupsMemberCount(int count);

  /// No description provided for @adminStreamGroupsLastMessageAt.
  ///
  /// In fr, this message translates to:
  /// **'Dernier message : {date}'**
  String adminStreamGroupsLastMessageAt(String date);

  /// No description provided for @adminStreamGroupsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get adminStreamGroupsDelete;

  /// No description provided for @adminStreamGroupsCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get adminStreamGroupsCancel;

  /// No description provided for @adminStreamGroupsDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe ?'**
  String get adminStreamGroupsDeleteConfirmTitle;

  /// No description provided for @adminStreamGroupsDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer le groupe {name} ({cid}) ? Cette action est définitive.'**
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid);

  /// No description provided for @adminStreamGroupsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Groupe supprimé.'**
  String get adminStreamGroupsDeleted;

  /// No description provided for @adminStreamGroupsDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le groupe.'**
  String get adminStreamGroupsDeleteFailed;

  /// No description provided for @adminStreamGroupsPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Un accès administrateur est requis pour gérer les groupes.'**
  String get adminStreamGroupsPermissionDenied;

  /// No description provided for @adminSeasonsSection.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get adminSeasonsSection;

  /// No description provided for @adminSeasonsSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lister et gérer les saisons de la plateforme.'**
  String get adminSeasonsSectionDesc;

  /// No description provided for @adminSeasonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get adminSeasonsTitle;

  /// No description provided for @adminSeasonsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune saison pour le moment.'**
  String get adminSeasonsEmpty;

  /// No description provided for @adminSeasonsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les saisons.'**
  String get adminSeasonsLoadError;

  /// No description provided for @adminSeasonCreate.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une saison'**
  String get adminSeasonCreate;

  /// No description provided for @adminSeasonEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la saison'**
  String get adminSeasonEditTitle;

  /// No description provided for @adminSeasonCreated.
  ///
  /// In fr, this message translates to:
  /// **'Saison créée.'**
  String get adminSeasonCreated;

  /// No description provided for @adminSeasonUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Saison mise à jour.'**
  String get adminSeasonUpdated;

  /// No description provided for @adminSeasonCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer la saison.'**
  String get adminSeasonCreateFailed;

  /// No description provided for @adminSeasonUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour la saison.'**
  String get adminSeasonUpdateFailed;

  /// No description provided for @adminSeasonUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Saison sans nom'**
  String get adminSeasonUnnamed;

  /// No description provided for @adminSeasonCurrentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Actuelle'**
  String get adminSeasonCurrentBadge;

  /// No description provided for @adminSeasonNewVersionBadge.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version'**
  String get adminSeasonNewVersionBadge;

  /// No description provided for @adminSeasonDateRange.
  ///
  /// In fr, this message translates to:
  /// **'{start} – {end}'**
  String adminSeasonDateRange(String start, String end);

  /// No description provided for @adminSeasonClubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Club : {clubName}'**
  String adminSeasonClubLabel(String clubName);

  /// No description provided for @adminSeasonAffiliateLabel.
  ///
  /// In fr, this message translates to:
  /// **'N° affilié : {number}'**
  String adminSeasonAffiliateLabel(String number);

  /// No description provided for @adminSeasonFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get adminSeasonFieldName;

  /// No description provided for @adminSeasonFieldNameReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le nom de la saison ne peut pas être modifié après création.'**
  String get adminSeasonFieldNameReadOnly;

  /// No description provided for @adminSeasonFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get adminSeasonFieldRequired;

  /// No description provided for @adminSeasonFieldStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get adminSeasonFieldStartDate;

  /// No description provided for @adminSeasonFieldEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get adminSeasonFieldEndDate;

  /// No description provided for @adminSeasonDateSelected.
  ///
  /// In fr, this message translates to:
  /// **'Sélection : {date}'**
  String adminSeasonDateSelected(String date);

  /// No description provided for @adminSeasonFieldClubName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du club'**
  String get adminSeasonFieldClubName;

  /// No description provided for @adminSeasonFieldAffiliateNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'affilié'**
  String get adminSeasonFieldAffiliateNumber;

  /// No description provided for @adminSeasonFieldCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Saison actuelle'**
  String get adminSeasonFieldCurrent;

  /// No description provided for @adminSeasonFieldCurrentHint.
  ///
  /// In fr, this message translates to:
  /// **'Une seule saison peut être actuelle à la fois.'**
  String get adminSeasonFieldCurrentHint;

  /// No description provided for @adminSeasonFieldNewVersion.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version'**
  String get adminSeasonFieldNewVersion;

  /// No description provided for @adminSeasonChangeDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer la saison actuelle ?'**
  String get adminSeasonChangeDefaultTitle;

  /// No description provided for @adminSeasonChangeDefaultMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {seasonName} » est actuellement la saison par défaut. Voulez-vous la remplacer ?'**
  String adminSeasonChangeDefaultMessage(String seasonName);

  /// No description provided for @adminSeasonChangeDefaultConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Changer la saison par défaut'**
  String get adminSeasonChangeDefaultConfirm;

  /// No description provided for @promoCodeMenuLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get promoCodeMenuLabel;

  /// No description provided for @promoCodeDialogValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get promoCodeDialogValidate;

  /// No description provided for @promoCodeRedeemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez un code promo ?'**
  String get promoCodeRedeemTitle;

  /// No description provided for @promoCodeRedeemHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code'**
  String get promoCodeRedeemHint;

  /// No description provided for @promoCodeRedeemAction.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get promoCodeRedeemAction;

  /// No description provided for @promoCodeRedeemEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un code promo.'**
  String get promoCodeRedeemEmpty;

  /// No description provided for @promoCodeRedeemSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code promo appliqué : {days} jours de {entitlement}.'**
  String promoCodeRedeemSuccess(int days, String entitlement);

  /// No description provided for @promoCodeRedeemSuccessVerified.
  ///
  /// In fr, this message translates to:
  /// **'{entitlement} actif jusqu\'au {expiresAt} ({days} jours offerts).'**
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days);

  /// No description provided for @promoCodeRedeemSyncPending.
  ///
  /// In fr, this message translates to:
  /// **'Code enregistré côté serveur, mais l\'abonnement n\'apparaît pas encore. Ouvrez Réglages → Abonnement dans un instant, ou déconnectez-vous puis reconnectez-vous.'**
  String get promoCodeRedeemSyncPending;

  /// No description provided for @promoCodeRedeemRcUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Code enregistré côté serveur, mais RevenueCat n\'est pas configuré sur cet appareil (vérifiez les clés API). Essayez sur iOS ou web, ou relancez avec dart_defines.json.'**
  String get promoCodeRedeemRcUnavailable;

  /// No description provided for @promoCodeRedeemNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Code promo introuvable.'**
  String get promoCodeRedeemNotFound;

  /// No description provided for @promoCodeRedeemInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo n\'est plus valide.'**
  String get promoCodeRedeemInvalid;

  /// No description provided for @promoCodeRedeemInactive.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo n\'est plus actif.'**
  String get promoCodeRedeemInactive;

  /// No description provided for @promoCodeRedeemExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo a expiré.'**
  String get promoCodeRedeemExpired;

  /// No description provided for @promoCodeRedeemAlreadyRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà utilisé ce code promo.'**
  String get promoCodeRedeemAlreadyRedeemed;

  /// No description provided for @promoCodeRedeemExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo a atteint sa limite d\'utilisation.'**
  String get promoCodeRedeemExhausted;

  /// No description provided for @promoCodeRedeemTeamMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo est réservé à un autre club.'**
  String get promoCodeRedeemTeamMismatch;

  /// No description provided for @promoCodeRedeemUnauthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour utiliser un code promo.'**
  String get promoCodeRedeemUnauthenticated;

  /// No description provided for @promoCodeRedeemFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'utiliser le code promo.'**
  String get promoCodeRedeemFailed;
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
