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
  String get heroTitle => 'Manage your sports activity with ease';

  @override
  String get heroSubtitle =>
      'Organize your events, manage your members and track your activity from a clear, modern and responsive interface.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in to access your space.';

  @override
  String get email => 'Email address';

  @override
  String get you => 'vous@exemple.com';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get hasATeamCode => 'Je dispose d\'un code équipe';

  @override
  String get slide1Title => 'Manage your team';

  @override
  String get slide1Subtitle =>
      'Centralize your members, your information and your organization in a single application.';

  @override
  String get slide2Title => 'Plan your matches';

  @override
  String get slide2Subtitle =>
      'Create your events, invite your players and easily track their availability.';

  @override
  String get slide3Title => 'Track your performance';

  @override
  String get slide3Subtitle =>
      'View statistics, activity and results from a clear interface.';
}
