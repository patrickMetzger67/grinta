import 'package:web/web.dart' as web;

/// Removes Whoop OAuth query params from the browser URL after handling.
void cleanWhoopOAuthQueryParams() {
  final uri = Uri.base;
  if (uri.queryParameters['whoopOAuth'] != '1') return;

  final cleaned = uri.replace(
    queryParameters: {
      for (final entry in uri.queryParameters.entries)
        if (entry.key != 'whoopOAuth' &&
            entry.key != 'success' &&
            entry.key != 'error' &&
            entry.key != 'playerId')
          entry.key: entry.value,
    },
  );
  final next = cleaned.replace(
    queryParameters:
        cleaned.queryParameters.isEmpty ? null : cleaned.queryParameters,
  );
  web.window.history.replaceState(null, '', next.toString());
}
