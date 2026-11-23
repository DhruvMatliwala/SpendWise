import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/currency_rate.dart';

/// Exception raised when live currency exchange rate fetching fails.
class CurrencyException implements Exception {
  const CurrencyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service wrapping the live exchange rate REST API and `SharedPreferences` cache.
class CurrencyService {
  CurrencyService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const String _cachedRatesKey = 'spendwise_cached_rates_v1';
  static const String _baseCurrencyKey = 'spendwise_base_currency_v1';
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Static USD-anchored baseline used only if the device has never synced online.
  static const Map<String, double> _usdBaseline = {
    'USD': 1.0,
    'INR': 84.40,
    'EUR': 0.92,
    'GBP': 0.79,
    'AED': 3.6725,
    'JPY': 154.50,
  };

  /// Reads the user's persisted base currency, defaulting to INR.
  Future<String> getSavedBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseCurrencyKey) ??
        SupportedCurrency.defaultBaseCode;
  }

  /// Persists the selected base currency code.
  Future<void> saveBaseCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseCurrencyKey, code.toUpperCase());
  }

  /// Loads cached rates from `SharedPreferences`, rebasing offline if needed.
  Future<CurrencyRates?> getCachedRates(String expectedBase) async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_cachedRatesKey);
    if (rawJson == null || rawJson.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;
      final cached = CurrencyRates.fromJson(decoded);
      return cached.baseCurrency == expectedBase.toUpperCase()
          ? cached
          : cached.rebasedTo(expectedBase);
    } on FormatException {
      return null;
    }
  }

  /// Fetches live exchange rates for [baseCurrency] and caches them locally.
  Future<CurrencyRates> fetchLiveRates(String baseCurrency) async {
    final normalizedBase = baseCurrency.toUpperCase();
    final uri =
        Uri.parse('https://open.er-api.com/v6/latest/$normalizedBase');

    try {
      final response = await _httpClient.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw CurrencyException(
          'Exchange rate API returned status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const CurrencyException('Malformed exchange rate payload.');
      }

      if (decoded['result'] == 'error') {
        throw CurrencyException(
          'API error: ${decoded['error-type'] ?? 'unknown'}',
        );
      }

      final liveRates = CurrencyRates.fromApiJson(decoded);
      await _persistRates(liveRates);
      return liveRates;
    } on TimeoutException {
      throw const CurrencyException(
        'Exchange rate request timed out. Using cached rates.',
      );
    } on http.ClientException catch (error) {
      throw CurrencyException(
        'Network error (${error.message}). Using cached rates.',
      );
    } on FormatException {
      throw const CurrencyException(
        'Unable to parse exchange rate response.',
      );
    }
  }

  Future<void> _persistRates(CurrencyRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedRatesKey, jsonEncode(rates.toJson()));
  }

  /// Builds deterministic fallback rates anchored to [baseCurrency] when offline.
  CurrencyRates getOfflineFallbackRates(String baseCurrency) {
    final target = baseCurrency.toUpperCase();
    final usdSeed = CurrencyRates(
      baseCurrency: 'USD',
      rates: _usdBaseline,
      lastUpdated: DateTime.now(),
      isFromCache: true,
    );
    return target == 'USD' ? usdSeed : usdSeed.rebasedTo(target);
  }
}
