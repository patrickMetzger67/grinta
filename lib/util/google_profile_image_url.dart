/// URL candidates for Google profile photos ([lh3.googleusercontent.com]).
List<String> expandGoogleProfileImageUrls(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return const [];

  if (!trimmed.contains('googleusercontent.com')) {
    return [trimmed];
  }

  final candidates = <String>[];
  void add(String value) {
    final next = value.trim();
    if (next.isNotEmpty && !candidates.contains(next)) {
      candidates.add(next);
    }
  }

  add(trimmed);

  // Strip =s96-c style size suffix.
  final withoutSize = trimmed.replaceFirst(RegExp(r'=s\d+(-c)?$'), '');
  add(withoutSize);

  // Query-parameter size variant.
  final uri = Uri.tryParse(withoutSize);
  if (uri != null && uri.host.contains('googleusercontent.com')) {
    add(uri.replace(queryParameters: {'sz': '96'}).toString());
  }

  return candidates;
}
