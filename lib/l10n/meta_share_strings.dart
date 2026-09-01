import 'package:grinta/l10n/app_localizations.dart';

/// Copy for optional Meta connect / API publish (ARB keys added in parallel).
class MetaShareStrings {
  MetaShareStrings(this.localeName);

  factory MetaShareStrings.of(AppLocalizations l10n) {
    return MetaShareStrings(l10n.localeName);
  }

  final String localeName;

  String get _lang => localeName.split('_').first;

  String get settingsTitle {
    switch (_lang) {
      case 'de':
        return 'Instagram / Facebook';
      case 'es':
        return 'Instagram / Facebook';
      case 'it':
        return 'Instagram / Facebook';
      default:
        return 'Instagram / Facebook';
    }
  }

  String get settingsSubtitle {
    switch (_lang) {
      case 'fr':
        return 'Optionnel — pour publier via l’API et voir les vues.';
      case 'de':
        return 'Optional — zum Veröffentlichen per API und für Aufrufe.';
      case 'es':
        return 'Opcional — para publicar por API y ver visualizaciones.';
      case 'it':
        return 'Facoltativo — per pubblicare via API e vedere le views.';
      default:
        return 'Optional — publish via API to get views.';
    }
  }

  String connectedStatus(String account) {
    switch (_lang) {
      case 'fr':
        return account.isEmpty ? 'Connecté' : 'Connecté · $account';
      case 'de':
        return account.isEmpty ? 'Verbunden' : 'Verbunden · $account';
      case 'es':
        return account.isEmpty ? 'Conectado' : 'Conectado · $account';
      case 'it':
        return account.isEmpty ? 'Connesso' : 'Connesso · $account';
      default:
        return account.isEmpty ? 'Connected' : 'Connected · $account';
    }
  }

  String get connectButton {
    switch (_lang) {
      case 'fr':
        return 'Connecter Instagram / Facebook';
      case 'de':
        return 'Instagram / Facebook verbinden';
      case 'es':
        return 'Conectar Instagram / Facebook';
      case 'it':
        return 'Collega Instagram / Facebook';
      default:
        return 'Connect Instagram / Facebook';
    }
  }

  String get disconnectButton {
    switch (_lang) {
      case 'fr':
        return 'Déconnecter';
      case 'de':
        return 'Trennen';
      case 'es':
        return 'Desconectar';
      case 'it':
        return 'Disconnetti';
      default:
        return 'Disconnect';
    }
  }

  String get connectSuccess {
    switch (_lang) {
      case 'fr':
        return 'Compte Instagram / Facebook connecté.';
      case 'de':
        return 'Instagram- / Facebook-Konto verbunden.';
      case 'es':
        return 'Cuenta de Instagram / Facebook conectada.';
      case 'it':
        return 'Account Instagram / Facebook collegato.';
      default:
        return 'Instagram / Facebook account connected.';
    }
  }

  String get connectFailed {
    switch (_lang) {
      case 'fr':
        return 'La connexion Meta a échoué. Vérifie META_APP_ID / META_APP_SECRET.';
      case 'de':
        return 'Meta-Verbindung fehlgeschlagen. META_APP_ID / META_APP_SECRET prüfen.';
      case 'es':
        return 'Error al conectar Meta. Comprueba META_APP_ID / META_APP_SECRET.';
      case 'it':
        return 'Connessione Meta non riuscita. Controlla META_APP_ID / META_APP_SECRET.';
      default:
        return 'Meta connect failed. Check META_APP_ID / META_APP_SECRET.';
    }
  }

  String get publishTitle {
    switch (_lang) {
      case 'fr':
        return 'Publier la synthèse';
      case 'de':
        return 'Zusammenfassung veröffentlichen';
      case 'es':
        return 'Publicar el resumen';
      case 'it':
        return 'Pubblica il riepilogo';
      default:
        return 'Publish the summary';
    }
  }

  String get publishInstagram {
    switch (_lang) {
      case 'fr':
        return 'Publier sur Instagram';
      case 'de':
        return 'Auf Instagram veröffentlichen';
      case 'es':
        return 'Publicar en Instagram';
      case 'it':
        return 'Pubblica su Instagram';
      default:
        return 'Publish to Instagram';
    }
  }

  String get publishFacebook {
    switch (_lang) {
      case 'fr':
        return 'Publier sur Facebook';
      case 'de':
        return 'Auf Facebook veröffentlichen';
      case 'es':
        return 'Publicar en Facebook';
      case 'it':
        return 'Pubblica su Facebook';
      default:
        return 'Publish to Facebook';
    }
  }

  String get publishShareSheet {
    switch (_lang) {
      case 'fr':
        return 'Autres apps (WhatsApp…)';
      case 'de':
        return 'Andere Apps (WhatsApp…)';
      case 'es':
        return 'Otras apps (WhatsApp…)';
      case 'it':
        return 'Altre app (WhatsApp…)';
      default:
        return 'Other apps (WhatsApp…)';
    }
  }

  String get publishSuccess {
    switch (_lang) {
      case 'fr':
        return 'Publication réussie.';
      case 'de':
        return 'Veröffentlicht.';
      case 'es':
        return 'Publicado.';
      case 'it':
        return 'Pubblicato.';
      default:
        return 'Published.';
    }
  }

  String get publishFailed {
    switch (_lang) {
      case 'fr':
        return 'Impossible de publier via Instagram / Facebook.';
      case 'de':
        return 'Veröffentlichen über Instagram / Facebook fehlgeschlagen.';
      case 'es':
        return 'No se pudo publicar en Instagram / Facebook.';
      case 'it':
        return 'Impossibile pubblicare su Instagram / Facebook.';
      default:
        return 'Could not publish to Instagram / Facebook.';
    }
  }
}
