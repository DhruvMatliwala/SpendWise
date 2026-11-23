import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/currency_rate.dart';
import '../services/currency_service.dart';

/// Manages active base currency, live exchange rates, and offline cache fallback.
class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider({CurrencyService? currencyService})
      : _currencyService = currencyService ?? CurrencyService();

  final CurrencyService _currencyService;

  String _baseCurrency = SupportedCurrency.defaultBaseCode;
  CurrencyRates? _rates;
  bool _isLoading = false;
  bool _isOfflineFallback = false;
  String? _errorMessage;

  String get baseCurrency => _baseCurrency;
  CurrencyRates? get rates => _rates;
  bool get isLoading => _isLoading;
  bool get isOfflineFallback => _isOfflineFallback;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _rates?.lastUpdated;

  /// Loads persisted base currency and cached rates, then refreshes live rates.
  Future<void> initialize() async {
    _baseCurrency = await _currencyService.getSavedBaseCurrency();
    final cached = await _currencyService.getCachedRates(_baseCurrency);
    _rates = cached ?? _currencyService.getOfflineFallbackRates(_baseCurrency);
    _isOfflineFallback = cached != null ? cached.isFromCache : true;
    notifyListeners();

    await refreshRates();
  }

  /// Fetches live exchange rates for the active [baseCurrency].
  Future<void> refreshRates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final live = await _currencyService.fetchLiveRates(_baseCurrency);
      _rates = live;
      _isOfflineFallback = false;
    } on CurrencyException catch (error) {
      _errorMessage = error.message;
      _isOfflineFallback = true;
      _rates ??= _currencyService.getOfflineFallbackRates(_baseCurrency);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switches the app-wide base currency and fetches updated rates.
  Future<void> setBaseCurrency(String newBaseCurrency) async {
    final normalized = newBaseCurrency.toUpperCase();
    if (normalized == _baseCurrency) return;

    _baseCurrency = normalized;
    final currentRates = _rates;
    _rates = currentRates != null
        ? currentRates.rebasedTo(normalized)
        : _currencyService.getOfflineFallbackRates(normalized);
    _isOfflineFallback = true;
    notifyListeners();

    await _currencyService.saveBaseCurrency(normalized);
    await refreshRates();
  }

  /// Converts [amount] in [fromCurrency] into [baseCurrency].
  double convertToBase(double amount, String fromCurrency) {
    final activeRates =
        _rates ?? _currencyService.getOfflineFallbackRates(_baseCurrency);
    return activeRates.convertToBase(amount, fromCurrency);
  }

  /// Returns units of [targetCurrency] per 1 unit of [baseCurrency].
  double rateFor(String targetCurrency) {
    final activeRates =
        _rates ?? _currencyService.getOfflineFallbackRates(_baseCurrency);
    return activeRates.rateFor(targetCurrency);
  }
}
