import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/french_address_parser.dart';

void main() {
  group('FrenchAddressParser.parseTerrainAdresse1', () {
    test('splits street, postal code and city on dash separator', () {
      final result = FrenchAddressParser.parseTerrainAdresse1(
        'ROUTE DU RHIN 67150 - ERSTEIN',
      );

      expect(result.adresse, 'ROUTE DU RHIN');
      expect(result.ville, 'ERSTEIN');
    });

    test('handles multiple dash segments with city last', () {
      final result = FrenchAddressParser.parseTerrainAdresse1(
        'STADE MUNICIPAL - ROUTE DU RHIN 67150 - ERSTEIN',
      );

      expect(result.adresse, 'STADE MUNICIPAL - ROUTE DU RHIN');
      expect(result.ville, 'ERSTEIN');
    });

    test('parses street postal code city without dash', () {
      final result = FrenchAddressParser.parseTerrainAdresse1(
        'ROUTE DU RHIN 67150 ERSTEIN',
      );

      expect(result.adresse, 'ROUTE DU RHIN');
      expect(result.ville, 'ERSTEIN');
    });

    test('returns empty parts for null or blank input', () {
      expect(
        FrenchAddressParser.parseTerrainAdresse1(null),
        (adresse: '', ville: ''),
      );
      expect(
        FrenchAddressParser.parseTerrainAdresse1('   '),
        (adresse: '', ville: ''),
      );
    });

    test('keeps full string as adresse when no city separator', () {
      final result = FrenchAddressParser.parseTerrainAdresse1(
        '12 RUE DE LA PAIX',
      );

      expect(result.adresse, '12 RUE DE LA PAIX');
      expect(result.ville, '');
    });
  });

  group('FrenchAddressParser.computeFieldId', () {
    test('concatenates terrainNom and ville, strips spaces, lowercases', () {
      final id = FrenchAddressParser.computeFieldId(
        terrainNom: 'Stade Municipal',
        ville: 'ERSTEIN',
      );

      expect(id, 'stademunicipalerstein');
    });

    test('trims whitespace before computing id', () {
      final id = FrenchAddressParser.computeFieldId(
        terrainNom: '  Stade  ',
        ville: '  Erstein  ',
      );

      expect(id, 'stadeerstein');
    });
  });
}
