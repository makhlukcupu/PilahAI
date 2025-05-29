import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class QuotesServices {
  static List<String> _quotes = [];

  /// Load kutipan dari file JSON
  static Future<void> loadQuotes() async {
    final String jsonString = await rootBundle.loadString('assets/quotes.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    _quotes = List<String>.from(jsonData);
  }

  /// ambil random quotes
  static String getRandomQuote() {
    if (_quotes.isEmpty) return "Selamat menjaga bumi hari ini 🌱";
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }
}
