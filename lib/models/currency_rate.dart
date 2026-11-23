import 'package:flutter/foundation.dart';

/// Immutable multi-currency exchange rate table anchored to [baseCurrency].
@immutable
class CurrencyRates {
  const CurrencyRates({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
    this.isFromCache = false,
  });

  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;
  final bool isFromCache;

  /// Creates an updated copy of [CurrencyRates].
  CurrencyRates copyWith({
    String? baseCurrency,
    Map<String, double>? rates,
    DateTime? lastUpdated,
    bool? isFromCache,
  }) {
    return CurrencyRates(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      rates: rates ?? this.rates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  /// Parses live JSON from open.er-api.com (or Frankfurter-compatible payloads).
  factory CurrencyRates.fromApiJson(Map<String, dynamic> json) {
    final rawBase = (json['base_code'] ?? json['base']) as String?;
    final rawRates = json['rates'];
    if (rawBase == null || rawRates is! Map) {
      throw const FormatException('Unexpected exchange rate API response.');
    }

    final parsedRates = <String, double>{rawBase.toUpperCase(): 1.0};
    for (final entry in rawRates.entries) {
      final value = entry.value;
      if (value is num && value > 0) {
        parsedRates[entry.key.toString().toUpperCase()] = value.toDouble();
      }
    }

    DateTime updatedAt = DateTime.now();
    final unixSeconds = json['time_last_update_unix'];
    if (unixSeconds is num && unixSeconds > 0) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(
        unixSeconds.toInt() * 1000,
      );
    }

    return CurrencyRates(
      baseCurrency: rawBase.toUpperCase(),
      rates: Map.unmodifiable(parsedRates),
      lastUpdated: updatedAt,
      isFromCache: false,
    );
  }

  /// Serializes rates for `SharedPreferences` caching.
  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'rates': rates,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Deserializes cached rates from `SharedPreferences`.
  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final rawBase = json['baseCurrency'];
    final rawRates = json['rates'];
    final rawUpdated = json['lastUpdated'];
    if (rawBase is! String || rawRates is! Map || rawUpdated is! String) {
      throw const FormatException('Invalid cached currency rate payload.');
    }

    final parsedRates = <String, double>{};
    for (final entry in rawRates.entries) {
      final value = entry.value;
      if (value is num && value > 0) {
        parsedRates[entry.key.toString().toUpperCase()] = value.toDouble();
      }
    }

    return CurrencyRates(
      baseCurrency: rawBase.toUpperCase(),
      rates: Map.unmodifiable(parsedRates),
      lastUpdated: DateTime.parse(rawUpdated),
      isFromCache: true,
    );
  }

  /// Returns units of [targetCurrency] per 1 unit of [baseCurrency].
  double rateFor(String targetCurrency) {
    final normalized = targetCurrency.toUpperCase();
    if (normalized == baseCurrency) return 1.0;
    return rates[normalized] ?? 1.0;
  }

  /// Converts [amount] in [fromCurrency] into [baseCurrency].
  double convertToBase(double amount, String fromCurrency) {
    final normalized = fromCurrency.toUpperCase();
    if (normalized == baseCurrency) return amount;
    final rate = rates[normalized];
    if (rate == null || rate <= 0) return amount;
    return amount / rate;
  }

  /// Re-anchors this rate table to a different [newBaseCurrency] offline.
  CurrencyRates rebasedTo(String newBaseCurrency) {
    final target = newBaseCurrency.toUpperCase();
    if (target == baseCurrency) return this;
    final anchorRate = rates[target];
    if (anchorRate == null || anchorRate <= 0) return this;

    final rebased = <String, double>{};
    for (final entry in rates.entries) {
      rebased[entry.key] = entry.value / anchorRate;
    }
    rebased[target] = 1.0;

    return CurrencyRates(
      baseCurrency: target,
      rates: Map.unmodifiable(rebased),
      lastUpdated: lastUpdated,
      isFromCache: true,
    );
  }
}
