// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sealed_countries/sealed_countries.dart';

/// Generates lib/data/nationality_labels.dart from i18n-nationality JSON
/// (en, de, es, it) and sealed_countries feminine French demonyms.
Future<void> main() async {
  final tmpDir = Directory('/tmp/package/langs');
  if (!tmpDir.existsSync()) {
    stderr.writeln(
      'Missing /tmp/package/langs — extract i18n-nationality npm package first.',
    );
    exit(1);
  }

  const locales = ['en', 'de', 'es', 'it'];
  final labelsByLocale = <String, Map<String, String>>{};

  for (final locale in locales) {
    final file = File('${tmpDir.path}/$locale.json');
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final nationalities = json['nationalities'] as Map<String, dynamic>;
    labelsByLocale[locale] = nationalities.map(
      (key, value) => MapEntry(key.toUpperCase(), value as String),
    );
  }

  // French: feminine demonyms from sealed_countries, fallback to i18n + heuristic.
  final frI18n = jsonDecode(
    await File('${tmpDir.path}/fr.json').readAsString(),
  ) as Map<String, dynamic>;
  final frI18nMap = (frI18n['nationalities'] as Map<String, dynamic>).map(
    (key, value) => MapEntry(key.toUpperCase(), value as String),
  );

  final frLabels = <String, String>{};
  for (final country in WorldCountry.list) {
    final code = country.codeShort;
    if (code.isEmpty) continue;

    final fraDemonym = country.demonyms
        .where((d) => d.language is LangFra)
        .map((d) => d.female)
        .firstOrNull;

    frLabels[code] = fraDemonym ?? _frenchFeminineFallback(frI18nMap[code]);
  }

  labelsByLocale['fr'] = frLabels;

  // Union of all ISO2 codes.
  final allCodes = <String>{};
  for (final map in labelsByLocale.values) {
    allCodes.addAll(map.keys);
  }
  final sortedCodes = allCodes.toList()..sort();

  final buffer = StringBuffer('''
// GENERATED FILE — do not edit by hand.
// Regenerate: dart run tool/generate_nationality_labels.dart
// Sources: i18n-nationality (MIT), sealed_countries (French feminine demonyms).

/// Localized nationality adjectives keyed by [Locale.languageCode] then ISO 3166-1 alpha-2.
const nationalityLabelsByLocale = <String, Map<String, String>>{
''');

  for (final locale in ['fr', 'en', 'de', 'es', 'it']) {
    final map = labelsByLocale[locale]!;
    buffer.writeln("  '$locale': {");
    for (final code in sortedCodes) {
      final label = map[code];
      if (label == null) continue;
      buffer.writeln("    '$code': ${_escapeDart(label)},");
    }
    buffer.writeln('  },');
  }

  buffer.writeln('};');
  buffer.writeln('');
  buffer.writeln('const supportedNationalityLocales = <String>[\'fr\', \'en\', \'de\', \'es\', \'it\'];');

  final outFile = File('lib/data/nationality_labels.dart');
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString(buffer.toString());
  print('Wrote ${outFile.path} (${sortedCodes.length} country codes)');
}

String _escapeDart(String value) {
  return "'${value.replaceAll('\\', r'\\').replaceAll("'", r"\'")}'";
}

String _frenchFeminineFallback(String? masculine) {
  if (masculine == null || masculine.isEmpty) return masculine ?? '';

  const overrides = <String, String>{
    'Français': 'Française',
    'Algérien': 'Algérienne',
    'Américain': 'Américaine',
    'Antiguayen': 'Antiguayenne',
    'Argentin': 'Argentine',
    'Arménien': 'Arménienne',
    'Autrichien': 'Autrichienne',
    'Azerbaïdjanais': 'Azerbaïdjanaise',
    'Bahamien': 'Bahamienne',
    'Bahreïnien': 'Bahreïnienne',
    'Bangladais': 'Bangladaise',
    'Barbadien': 'Barbadienne',
    'Belge': 'Belge',
    'Béninois': 'Béninoise',
    'Biélorusse': 'Biélorusse',
    'Birman': 'Birmane',
    'Bolivien': 'Bolivienne',
    'Bosnien': 'Bosnienne',
    'Botswanais': 'Botswanaise',
    'Brésilien': 'Brésilienne',
    'Britannique': 'Britannique',
    'Bulgare': 'Bulgare',
    'Burkinabé': 'Burkinabée',
    'Burundais': 'Burundaise',
    'Cambodgien': 'Cambodgienne',
    'Camerounais': 'Camerounaise',
    'Canadien': 'Canadienne',
    'Cap-verdien': 'Cap-verdienne',
    'Centrafricain': 'Centrafricaine',
    'Chilien': 'Chilienne',
    'Chinois': 'Chinoise',
    'Chypriote': 'Chypriote',
    'Colombien': 'Colombienne',
    'Comorien': 'Comorienne',
    'Congolais': 'Congolaise',
    'Costaricain': 'Costaricaine',
    'Croate': 'Croate',
    'Cubain': 'Cubaine',
    'Danois': 'Danoise',
    'Djiboutien': 'Djiboutienne',
    'Dominicain': 'Dominicaine',
    'Égyptien': 'Égyptienne',
    'Émirati': 'Émiratie',
    'Équatorien': 'Équatorienne',
    'Érythréen': 'Érythréenne',
    'Espagnol': 'Espagnole',
    'Estonien': 'Estonienne',
    'Éthiopien': 'Éthiopienne',
    'Finlandais': 'Finlandaise',
    'Gabonais': 'Gabonaise',
    'Gambien': 'Gambienne',
    'Géorgien': 'Géorgienne',
    'Ghanéen': 'Ghanéenne',
    'Grec': 'Grecque',
    'Guatémaltèque': 'Guatémaltèque',
    'Guinéen': 'Guinéenne',
    'Haïtien': 'Haïtienne',
    'Hondurien': 'Hondurienne',
    'Hongrois': 'Hongroise',
    'Indien': 'Indienne',
    'Indonésien': 'Indonésienne',
    'Irakien': 'Irakienne',
    'Irlandais': 'Irlandaise',
    'Islandais': 'Islandaise',
    'Israélien': 'Israélienne',
    'Italien': 'Italienne',
    'Ivoirien': 'Ivoirienne',
    'Jamaïcain': 'Jamaïcaine',
    'Japonais': 'Japonaise',
    'Jordanien': 'Jordanienne',
    'Kazakh': 'Kazakhe',
    'Kényan': 'Kényane',
    'Kirghiz': 'Kirghize',
    'Kiribatien': 'Kiribatienne',
    'Kosovar': 'Kosovare',
    'Koweïtien': 'Koweïtienne',
    'Laotien': 'Laotienne',
    'Lesothan': 'Lesothane',
    'Letton': 'Lettone',
    'Libanais': 'Libanaise',
    'Libérien': 'Libérienne',
    'Libyen': 'Libyenne',
    'Liechtensteinois': 'Liechtensteinoise',
    'Lituanien': 'Lituanienne',
    'Luxembourgeois': 'Luxembourgeoise',
    'Macédonien': 'Macédonienne',
    'Malaisien': 'Malaisienne',
    'Malawien': 'Malawienne',
    'Maldivien': 'Maldivienne',
    'Malien': 'Malienne',
    'Maltais': 'Maltaise',
    'Marocain': 'Marocaine',
    'Mauricien': 'Mauricienne',
    'Mauritanien': 'Mauritanienne',
    'Mexicain': 'Mexicaine',
    'Micronésien': 'Micronésienne',
    'Moldave': 'Moldave',
    'Monégasque': 'Monégasque',
    'Mongol': 'Mongole',
    'Monténégrin': 'Monténégrine',
    'Mozambicain': 'Mozambicaine',
    'Namibien': 'Namibienne',
    'Nauruan': 'Nauruane',
    'Néerlandais': 'Néerlandaise',
    'Népalais': 'Népalaise',
    'Nicaraguayen': 'Nicaraguayenne',
    'Nigérian': 'Nigériane',
    'Nigérien': 'Nigérienne',
    'Norvégien': 'Norvégienne',
    'Néo-Zélandais': 'Néo-Zélandaise',
    'Omanais': 'Omanaise',
    'Ougandais': 'Ougandaise',
    'Ouzbek': 'Ouzbèke',
    'Pakistanais': 'Pakistanaise',
    'Panaméen': 'Panaméenne',
    'Papouasien': 'Papouasienne',
    'Paraguayen': 'Paraguayenne',
    'Péruvien': 'Péruvienne',
    'Philippin': 'Philippine',
    'Polonais': 'Polonaise',
    'Portugais': 'Portugaise',
    'Qatari': 'Qatarie',
    'Roumain': 'Roumaine',
    'Russe': 'Russe',
    'Rwandais': 'Rwandaise',
    'Saint-Marinais': 'Saint-Marinaise',
    'Salvadorien': 'Salvadorienne',
    'Samoan': 'Samoane',
    'Saoudien': 'Saoudienne',
    'Sénégalais': 'Sénégalaise',
    'Serbe': 'Serbe',
    'Seychellois': 'Seychelloise',
    'Sierra-Léonais': 'Sierra-Léonaise',
    'Singapourien': 'Singapourienne',
    'Slovaque': 'Slovaque',
    'Slovène': 'Slovène',
    'Somalien': 'Somalienne',
    'Soudanais': 'Soudanaise',
    'Sri-Lankais': 'Sri-Lankaise',
    'Suédois': 'Suédoise',
    'Suisse': 'Suisse',
    'Surinamais': 'Surinamaise',
    'Syrien': 'Syrienne',
    'Tadjik': 'Tadjike',
    'Tanzanien': 'Tanzanienne',
    'Tchadien': 'Tchadienne',
    'Tchèque': 'Tchèque',
    'Thaïlandais': 'Thaïlandaise',
    'Togolais': 'Togolaise',
    'Tongien': 'Tongienne',
    'Trinidadien': 'Trinidadienne',
    'Tunisien': 'Tunisienne',
    'Turkmène': 'Turkmène',
    'Turc': 'Turque',
    'Tuvaluan': 'Tuvaluane',
    'Ukrainien': 'Ukrainienne',
    'Uruguayen': 'Uruguayenne',
    'Vanuatuan': 'Vanuatuane',
    'Vénézuélien': 'Vénézuélienne',
    'Vietnamien': 'Vietnamienne',
    'Yéménite': 'Yéménite',
    'Zambien': 'Zambienne',
    'Zimbabwéen': 'Zimbabwéenne',
  };

  return overrides[masculine] ?? _frenchSuffixHeuristic(masculine);
}

String _frenchSuffixHeuristic(String masculine) {
  if (masculine.endsWith('e')) return masculine;
  if (masculine.endsWith('ien')) return '${masculine.substring(0, masculine.length - 3)}ienne';
  if (masculine.endsWith('in')) return '${masculine.substring(0, masculine.length - 2)}ine';
  if (masculine.endsWith('ais')) return '${masculine.substring(0, masculine.length - 3)}aise';
  if (masculine.endsWith('ois')) return '${masculine.substring(0, masculine.length - 3)}oise';
  if (masculine.endsWith('ais')) return '${masculine.substring(0, masculine.length - 3)}aise';
  return '${masculine}ne';
}
