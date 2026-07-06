/// Configuration for the Grinta Gemini assistant chatbot.
///
/// ## Recommended (production)
/// Deploy the `chatWithGemini` Cloud Function and set the secret:
/// ```bash
/// cd functions && npm install
/// firebase functions:secrets:set GEMINI_API_KEY
/// firebase deploy --only functions:chatWithGemini
/// ```
/// The Flutter client calls this function via `cloud_functions` (region
/// `europe-west1`). The API key never ships in the app binary.
///
/// ## Local / fallback (NOT for production)
/// Set `GEMINI_API_KEY` in `dart_defines.json` only for development.
/// Never commit real keys. Prefer the Cloud Function proxy.
library;

/// When true, [kGeminiApiKey] is used for direct HTTP calls (dev only).
const bool kGeminiChatUseDirectApi = bool.fromEnvironment(
  'GEMINI_CHAT_USE_DIRECT_API',
  defaultValue: false,
);

/// Direct Gemini API key — development fallback only.
const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Gemini model for chat (generateContent API).
const String kGeminiChatModel = 'gemini-2.5-flash';

/// Cloud Function name (callable, europe-west1).
const String kChatWithGeminiFunctionName = 'chatWithGemini';

/// Firebase Functions region (matches existing Grinta functions).
const String kGeminiFunctionsRegion = 'europe-west1';

bool get isGeminiChatConfigured {
  if (kGeminiChatUseDirectApi) {
    return kGeminiApiKey.trim().isNotEmpty;
  }
  // Callable path: configured server-side via GEMINI_API_KEY secret.
  return true;
}
