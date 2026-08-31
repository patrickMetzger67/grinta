import 'package:grinta/config/invitation_config.dart';

/// Builds public invite URLs and WhatsApp click-to-chat links.
abstract final class InvitationLinkBuilder {
  /// `https://grinta.io/invite?code=GT1234` (base from [InvitationRuntimeConfig]).
  static String inviteUrl({
    required InvitationRuntimeConfig config,
    required String invitationCode,
  }) {
    final String base = config.inviteBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final String code = invitationCode.trim();
    if (base.isEmpty || code.isEmpty) {
      return '';
    }
    final Uri uri = Uri.parse(base).replace(
      queryParameters: <String, String>{'code': code},
    );
    return uri.toString();
  }

  /// Digits-only phone for WhatsApp Cloud API / wa.me.
  static String? digitsOnlyPhone(String? phoneE164) {
    final String trimmed = phoneE164?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final String digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    return digits;
  }

  /// Opens WhatsApp with a prefilled invitation text (no Meta API required).
  static Uri? waMeUri({
    required String phoneE164,
    required String text,
  }) {
    final String? digits = digitsOnlyPhone(phoneE164);
    if (digits == null) return null;
    return Uri.https('wa.me', '/$digits', <String, String>{'text': text});
  }
}
