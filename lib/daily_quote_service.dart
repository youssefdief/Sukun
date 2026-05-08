import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class QuoteItem {
  final int id;
  final String type;
  final String textAr;
  final String textEn;
  final String sourceAr;
  final String sourceEn;

  QuoteItem({
    required this.id,
    required this.type,
    required this.textAr,
    required this.textEn,
    required this.sourceAr,
    required this.sourceEn,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      type: json['type'],
      textAr: json['text_ar'],
      textEn: json['text_en'],
      sourceAr: json['source_ar'],
      sourceEn: json['source_en'],
    );
  }
}

class DailyQuoteService {
  static final DailyQuoteService _instance = DailyQuoteService._internal();
  factory DailyQuoteService() => _instance;
  DailyQuoteService._internal();

  List<QuoteItem> _quotes = [];
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/data/quotes.json');
      final List<dynamic> data = json.decode(response);
      _quotes = data.map((json) => QuoteItem.fromJson(json)).toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading quotes: $e');
    }
  }

  QuoteItem? getDailyQuote(DateTime date) {
    if (_quotes.isEmpty) return null;
    
    // Create a predictable index for the given day
    int seed = date.year * 10000 + date.month * 100 + date.day;
    int index = seed % _quotes.length;
    
    return _quotes[index];
  }
}
