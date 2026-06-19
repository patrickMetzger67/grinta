List<String> generateSearchOptions(String? name) {
  final searchOptions = <String>[];
  if (name == null || name.trim().isEmpty) {
    return searchOptions;
  }

  final nameParts = name.split(' ');
  for (var i = 0; i < nameParts.length; i++) {
    nameParts[i] = nameParts[i].trim();
    for (var y = 0; y < nameParts[i].length; y++) {
      final tmpStr = nameParts[i].substring(0, y);
      if (tmpStr.isNotEmpty) {
        searchOptions.add(tmpStr.toLowerCase());
      }
    }
    searchOptions.add(nameParts[i].toLowerCase());
  }

  return searchOptions;
}

List<String> buildPlayerSearchOptions({
  required String firstName,
  required String lastName,
}) {
  return [
    ...generateSearchOptions(firstName),
    ...generateSearchOptions(lastName),
  ];
}
