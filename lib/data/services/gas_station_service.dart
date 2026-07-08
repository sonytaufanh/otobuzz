import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/gas_station.dart';

class GasStationService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const int _maxRetries = 3;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Simple in-memory cache
  static List<GasStation>? _cachedStations;
  static DateTime? _cacheTimestamp;
  static double? _cachedLat;
  static double? _cachedLng;

  /// Queries Overpass API for gas stations near the given location
  static Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    // Check cache validity
    if (_isCacheValid(latitude, longitude)) {
      return _cachedStations!;
    }

    final query =
        '[out:json];node["amenity"="fuel"](around:$radiusMeters,$latitude,$longitude);out body;';

    List<GasStation> stations = [];
    Exception? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_overpassUrl),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: 'data=${Uri.encodeComponent(query)}',
            )
            .timeout(Duration(seconds: 15 + (attempt * 5)));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final elements = (data['elements'] as List?) ?? [];

          stations = elements
              .where((e) => e['lat'] != null && e['lon'] != null)
              .map((e) =>
                  GasStation.fromOverpassElement(e as Map<String, dynamic>))
              .toList();

          // Update cache
          _cachedStations = stations;
          _cacheTimestamp = DateTime.now();
          _cachedLat = latitude;
          _cachedLng = longitude;

          return stations;
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          // Rate limited or server error - retry with backoff
          lastError = Exception(
              'Server error: ${response.statusCode}');
          await Future.delayed(
              Duration(seconds: (attempt + 1) * 2));
          continue;
        } else {
          throw Exception(
              'Gagal memuat data SPBU (${response.statusCode})');
        }
      } on Exception catch (e) {
        lastError = e;
        if (attempt < _maxRetries - 1) {
          await Future.delayed(
              Duration(seconds: (attempt + 1) * 2));
        }
      }
    }

    throw lastError ??
        Exception('Gagal terhubung ke server setelah $_maxRetries percobaan');
  }

  static bool _isCacheValid(double lat, double lng) {
    if (_cachedStations == null || _cacheTimestamp == null) return false;
    if (DateTime.now().difference(_cacheTimestamp!) > _cacheDuration) {
      return false;
    }
    // Check if location hasn't changed significantly (within ~100m)
    if (_cachedLat == null || _cachedLng == null) return false;
    final latDiff = (lat - _cachedLat!).abs();
    final lngDiff = (lng - _cachedLng!).abs();
    return latDiff < 0.001 && lngDiff < 0.001;
  }

  /// Clear cached data
  static void clearCache() {
    _cachedStations = null;
    _cacheTimestamp = null;
    _cachedLat = null;
    _cachedLng = null;
  }
}
