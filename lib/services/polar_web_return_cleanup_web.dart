import 'package:web/web.dart' as web;

/// Removes Polar OAuth query params from the browser URL after handling.
void cleanPolarOAuthQueryParams() {
  final uri = Uri.base;
  if (uri.queryParameters['polarOAuth'] != '1') return;

  final cleaned = uri.replace(
    queryParameters: {
      for (final entry in uri.queryParameters.entries)
        if (entry.key != 'polarOAuth' &&
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
