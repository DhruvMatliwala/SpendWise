import 'package:flutter/foundation.dart';

/// Immutable domain model representing a single logged expense.
@immutable
class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.convertedAmountInBase,
    required this.category,
    required this.date,
    this.notes = '',
  });

  final int? id;
  final String title;
  final double amount;
  final String currency;
  final double convertedAmountInBase;
  final String category;
  final DateTime date;
  final String notes;

  /// Creates a copy of this expense with optional field overrides.
  Expense copyWith({
    int? id,
    bool clearId = false,
    String? title,
    double? amount,
    String? currency,
    double? convertedAmountInBase,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return Expense(
      id: clearId ? null : (id ?? this.id),
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      convertedAmountInBase:
          convertedAmountInBase ?? this.convertedAmountInBase,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  /// Serializes this expense into a SQLite row map.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'converted_amount_in_base': convertedAmountInBase,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// Deserializes an [Expense] from a SQLite row map.
  factory Expense.fromMap(Map<String, Object?> map) {
    return switch (map) {
      {
        'title': final String title,
        'amount': final num amount,
        'currency': final String currency,
        'converted_amount_in_base': final num convertedAmountInBase,
        'category': final String category,
        'date': final String dateIso,
      } =>
        Expense(
          id: (map['id'] as num?)?.toInt(),
          title: title,
          amount: amount.toDouble(),
          currency: currency,
          convertedAmountInBase: convertedAmountInBase.toDouble(),
          category: category,
          date: DateTime.parse(dateIso),
          notes: (map['notes'] as String?) ?? '',
        ),
      _ => throw const FormatException('Invalid SQLite expense record.'),
    };
  }

  /// Serializes this expense to a JSON-encodable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'convertedAmountInBase': convertedAmountInBase,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// Deserializes an [Expense] from JSON.
  factory Expense.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'title': final String title,
        'amount': final num amount,
        'currency': final String currency,
        'convertedAmountInBase': final num convertedAmountInBase,
        'category': final String category,
        'date': final String dateIso,
      } =>
        Expense(
          id: (json['id'] as num?)?.toInt(),
          title: title,
          amount: amount.toDouble(),
          currency: currency,
          convertedAmountInBase: convertedAmountInBase.toDouble(),
          category: category,
          date: DateTime.parse(dateIso),
          notes: (json['notes'] as String?) ?? '',
        ),
      _ => throw const FormatException('Invalid JSON expense payload.'),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.currency == currency &&
        other.convertedAmountInBase == convertedAmountInBase &&
        other.category == category &&
        other.date == date &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        amount,
        currency,
        convertedAmountInBase,
        category,
        date,
        notes,
      );
}
