import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/util/calendar_event_formatter.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:http/http.dart' as http;

/// Resolves match venue coordinates, user position, and distance.
class MatchLocationService {
  MatchLocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, ({double latitude, double longitude})> _geocodeCache =
      <String, ({double latitude, double longitude})>{};

  /// Best-effort current device position (null if permission denied or unavailable).
  Future<({double latitude, double longitude})?> getCurrentUserPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// GPS centroid from field corners, or geocoded venue address.
  Future<({double latitude, double longitude})?> resolveMatchCoordinates(
    grinta_match.Match match,
  ) async {
    final coords = CalendarEventFormatter.matchCoordinates(match);
    if (coords != null) {
      return (latitude: coords.latitude, longitude: coords.longitude);
    }

    final address = CalendarEventFormatter.matchLocation(match);
    if (address == null || address.trim().isEmpty) return null;
    return geocodeAddress(address);
  }

  Future<({double latitude, double longitude})?> geocodeAddress(
    String address,
  ) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    final cached = _geocodeCache[query];
    if (cached != null) return cached;

    final apiKey = kGoogleMapsGeocodingApiKey.trim();
    if (apiKey.isEmpty || apiKey == 'TA_CLE_GOOGLE_MAPS_ICI') {
      return null;
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        <String, String>{
          'address': query,
          'key': apiKey,
          'language': 'fr',
          'region': 'fr',
        },
      );

      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status']?.toString() != 'OK') return null;

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final geometry =
          (results.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
      final location =
          geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final double? lat = (location['lat'] as num?)?.toDouble();
      final double? lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      final resolved = (latitude: lat, longitude: lng);
      _geocodeCache[query] = resolved;
      return resolved;
    } catch (_) {
      return null;
    }
  }

  double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final meters = FieldCornerGps.distanceMeters(
      FieldCornerGps(latitude: fromLatitude, longitude: fromLongitude),
      FieldCornerGps(latitude: toLatitude, longitude: toLongitude),
    );
    return double.parse((meters / 1000).toStringAsFixed(1));
  }
}
