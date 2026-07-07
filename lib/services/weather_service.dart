import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches weather forecasts from Open-Meteo (no API key required).
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns a compact forecast for [dateIso] (`yyyy-MM-dd`) near [hourMinute] (`HH:mm`).
  Future<Map<String, dynamic>?> fetchMatchDayForecast({
    required double latitude,
    required double longitude,
    required String dateIso,
    String? hourMinute,
  }) async {
    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        <String, String>{
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'hourly':
              'temperature_2m,precipitation_probability,weather_code,wind_speed_10m',
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
          'start_date': dateIso,
          'end_date': dateIso,
          'timezone': 'auto',
        },
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>?;
      final daily = data['daily'] as Map<String, dynamic>?;

      final Map<String, dynamic> result = <String, dynamic>{
        'date': dateIso,
        'latitude': latitude,
        'longitude': longitude,
        'source': 'open-meteo',
      };

      if (daily != null) {
        final codes = daily['weather_code'] as List<dynamic>?;
        if (codes != null && codes.isNotEmpty) {
          result['dailyWeatherCode'] = codes.first;
          result['dailyConditions'] = _weatherCodeLabel(codes.first);
        }
        final maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
        final minTemps = daily['temperature_2m_min'] as List<dynamic>?;
        if (maxTemps != null && maxTemps.isNotEmpty) {
          result['temperatureMaxC'] = maxTemps.first;
        }
        if (minTemps != null && minTemps.isNotEmpty) {
          result['temperatureMinC'] = minTemps.first;
        }
        final precip = daily['precipitation_sum'] as List<dynamic>?;
        if (precip != null && precip.isNotEmpty) {
          result['precipitationMm'] = precip.first;
        }
        final precipProb = daily['precipitation_probability_max'] as List<dynamic>?;
        if (precipProb != null && precipProb.isNotEmpty) {
          result['precipitationProbabilityMaxPercent'] = precipProb.first;
        }
      }

      if (hourly != null) {
        final times = hourly['time'] as List<dynamic>?;
        final temps = hourly['temperature_2m'] as List<dynamic>?;
        final precipProbs = hourly['precipitation_probability'] as List<dynamic>?;
        final codes = hourly['weather_code'] as List<dynamic>?;
        final winds = hourly['wind_speed_10m'] as List<dynamic>?;

        if (times != null && times.isNotEmpty) {
          final int index = _resolveHourlyIndex(
            times: times,
            dateIso: dateIso,
            hourMinute: hourMinute,
          );
          if (index >= 0) {
            result['matchHour'] = times[index];
            if (temps != null && index < temps.length) {
              result['temperatureAtMatchC'] = temps[index];
            }
            if (precipProbs != null && index < precipProbs.length) {
              result['precipitationProbabilityAtMatchPercent'] = precipProbs[index];
            }
            if (codes != null && index < codes.length) {
              result['weatherCodeAtMatch'] = codes[index];
              result['conditionsAtMatch'] = _weatherCodeLabel(codes[index]);
            }
            if (winds != null && index < winds.length) {
              result['windSpeedAtMatchKmh'] = winds[index];
            }
          }
        }
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  static int _resolveHourlyIndex({
    required List<dynamic> times,
    required String dateIso,
    String? hourMinute,
  }) {
    if (hourMinute == null || hourMinute.trim().isEmpty) {
      return 0;
    }

    final parts = hourMinute.trim().split(':');
    if (parts.length != 2) return 0;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return 0;

    final String targetPrefix = '${dateIso}T${hour.toString().padLeft(2, '0')}:';
    for (var i = 0; i < times.length; i++) {
      final String time = times[i].toString();
      if (time.startsWith(targetPrefix)) {
        return i;
      }
    }

    final String fallback = '${dateIso}T${hour.toString().padLeft(2, '0')}:00';
    for (var i = 0; i < times.length; i++) {
      if (times[i].toString() == fallback) return i;
    }

    return 0;
  }

  static String _weatherCodeLabel(dynamic code) {
    final int? value = code is num ? code.toInt() : int.tryParse('$code');
    return switch (value) {
      0 => 'Ciel dégagé',
      1 || 2 || 3 => 'Partiellement nuageux',
      45 || 48 => 'Brouillard',
      51 || 53 || 55 => 'Bruine',
      56 || 57 => 'Bruine verglaçante',
      61 || 63 || 65 => 'Pluie',
      66 || 67 => 'Pluie verglaçante',
      71 || 73 || 75 => 'Neige',
      77 => 'Grains de neige',
      80 || 81 || 82 => 'Averses',
      85 || 86 => 'Averses de neige',
      95 => 'Orage',
      96 || 99 => 'Orage avec grêle',
      _ => 'Conditions variables',
    };
  }
}
