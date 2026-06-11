import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Optional Google Gemini integration for advanced AI-powered insights.
/// This service is opt-in and works independently from the offline SmartTipsEngine.
class AiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _apiKeyPrefKey = 'gemini_api_key';
  static const String _aiEnabledPrefKey = 'ai_enabled';
  static const String _lastCallTimePrefKey = 'ai_last_call_time';
  static const String _cachedResponsePrefKey = 'ai_cached_response_';

  static const Duration _rateLimitInterval = Duration(seconds: 60);
  static const Duration _cacheExpiry = Duration(hours: 1);

  String? _apiKey;
  bool _isEnabled = false;

  /// Initialize the service by loading API key from SharedPreferences.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPrefKey);
    _isEnabled = prefs.getBool(_aiEnabledPrefKey) ?? false;
  }

  /// Whether the AI service is configured with a valid API key.
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _isEnabled;

  /// Whether AI features are enabled.
  bool get isEnabled => _isEnabled;

  /// Save API key to secure storage.
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
    _apiKey = apiKey;
  }

  /// Enable or disable AI features.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledPrefKey, enabled);
    _isEnabled = enabled;
  }

  /// Remove API key.
  Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
    _apiKey = null;
  }

  /// Test connection to Gemini API.
  Future<bool> testConnection() async {
    if (_apiKey == null || _apiKey!.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Say "OK" if you can read this.'}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends fleet data summary + question to Gemini and returns response.
  Future<String> askAboutFleet({
    required String question,
    required Map<String, dynamic> fleetContext,
  }) async {
    if (!isConfigured) {
      throw AiServiceException(
          'Fitur AI belum dikonfigurasi. Silakan masukkan kunci API di Pengaturan.');
    }

    // Check rate limit
    if (!await _checkRateLimit()) {
      throw AiServiceException(
          'Terlalu banyak permintaan. Tunggu sebentar sebelum bertanya lagi.');
    }

    // Check cache
    final cacheKey = '${question.hashCode}_${fleetContext.hashCode}';
    final cached = await _getCachedResponse(cacheKey);
    if (cached != null) return cached;

    final systemPrompt = '''
Kamu adalah asisten AI untuk manajemen armada kendaraan (fleet management).
Kamu membantu pemilik armada kecil di Indonesia mengelola mobil dan motor mereka.
Jawab dalam Bahasa Indonesia yang ringkas dan mudah dipahami.
Berikan saran praktis berdasarkan data yang diberikan.
Jangan memberikan informasi palsu - jika tidak yakin, katakan dengan jelas.
''';

    final contextText = _summarizeFleetContext(fleetContext);

    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '$systemPrompt\n\nData armada:\n$contextText\n\nPertanyaan: $question'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 1024,
            'temperature': 0.7,
          },
        }),
      );

      await _recordCallTime();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]
                ?['text'] as String? ??
            'Maaf, tidak bisa memberikan jawaban saat ini.';

        // Cache the response
        await _cacheResponse(cacheKey, text);
        return text;
      } else if (response.statusCode == 429) {
        throw AiServiceException(
            'Batas permintaan API tercapai. Coba lagi nanti.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AiServiceException(
            'Kunci API tidak valid. Periksa kembali di Pengaturan.');
      } else {
        throw AiServiceException(
            'Gagal menghubungi AI (${response.statusCode}). Coba lagi nanti.');
      }
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException(
          'Gagal terhubung ke server AI. Periksa koneksi internet Anda.');
    }
  }

  /// Generate weekly fleet report summary using AI.
  Future<String> generateWeeklyInsight(Map<String, dynamic> fleetData) async {
    return askAboutFleet(
      question:
          'Berikan ringkasan kondisi armada minggu ini dan saran prioritas untuk minggu depan. Fokus pada hal yang perlu segera ditangani.',
      fleetContext: fleetData,
    );
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  String _summarizeFleetContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();

    if (context.containsKey('totalVehicles')) {
      buffer.writeln('Jumlah kendaraan: ${context['totalVehicles']}');
    }
    if (context.containsKey('vehicles')) {
      final vehicles = context['vehicles'] as List<dynamic>?;
      if (vehicles != null) {
        for (final v in vehicles) {
          buffer.writeln(
              '- ${v['name']}: ${v['plate']}, ${v['km']} km, status: ${v['status']}');
        }
      }
    }
    if (context.containsKey('overdueCount')) {
      buffer.writeln('Perawatan terlambat: ${context['overdueCount']}');
    }
    if (context.containsKey('upcomingCount')) {
      buffer.writeln('Perawatan segera: ${context['upcomingCount']}');
    }
    if (context.containsKey('monthlyBudget')) {
      buffer.writeln('Budget bulan ini: Rp ${context['monthlyBudget']}');
    }
    if (context.containsKey('monthlySpent')) {
      buffer.writeln('Pengeluaran bulan ini: Rp ${context['monthlySpent']}');
    }
    if (context.containsKey('fuelEfficiency')) {
      buffer.writeln('Efisiensi BBM rata-rata: ${context['fuelEfficiency']}');
    }

    return buffer.toString();
  }

  Future<bool> _checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCallMs = prefs.getInt(_lastCallTimePrefKey) ?? 0;
    final lastCall = DateTime.fromMillisecondsSinceEpoch(lastCallMs);
    final elapsed = DateTime.now().difference(lastCall);
    return elapsed > _rateLimitInterval;
  }

  Future<void> _recordCallTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastCallTimePrefKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _getCachedResponse(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_cachedResponsePrefKey$key');
    if (cached == null) return null;

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['time'] as int);
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await prefs.remove('$_cachedResponsePrefKey$key');
        return null;
      }
      return data['response'] as String;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheResponse(String key, String response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cachedResponsePrefKey$key',
      jsonEncode({
        'time': DateTime.now().millisecondsSinceEpoch,
        'response': response,
      }),
    );
  }
}

/// Exception thrown by AiService with user-friendly Indonesian message.
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}
