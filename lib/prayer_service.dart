import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'widget_service.dart';

class UpcomingDay {
  final DateTime date;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  UpcomingDay({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class PrayerData {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String hijriDate;
  final bool isOffline;
  final List<UpcomingDay> upcomingDays;

  PrayerData({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.hijriDate,
    this.isOffline = false,
    this.upcomingDays = const [],
  });

  factory PrayerData.fromJson(Map<String, dynamic> json, {bool isOffline = false}) {
    // Determine if it's the old single 'data' object or the new array of 'data' (calendar endpoint)
    final dynamic rawData = json['data'];
    late Map<String, dynamic> todayData;
    List<UpcomingDay> upcomingDays = [];

    if (rawData is List) {
      final now = DateTime.now();
      // Find today's data or fallback to index 0
      int todayIndex = rawData.indexWhere((dayData) {
        String gregorianStr = dayData['date']['gregorian']['date']; // DD-MM-YYYY
        List<String> parts = gregorianStr.split('-');
        if (parts.length == 3) {
          int d = int.parse(parts[0]);
          int m = int.parse(parts[1]);
          int y = int.parse(parts[2]);
          return d == now.day && m == now.month && y == now.year;
        }
        return false;
      });

      if (todayIndex == -1) todayIndex = 0;
      todayData = rawData[todayIndex];

      // Parse upcoming days (up to 7 days from today in the same month)
      for (int i = todayIndex + 1; i < rawData.length && i <= todayIndex + 7; i++) {
        final day = rawData[i];
        final timings = day['timings'];
        final dateStr = day['date']['gregorian']['date']; // DD-MM-YYYY
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          final date = DateTime(y, m, d);

          DateTime parseTimeStr(String t) {
            final tParts = t.split(' ')[0].split(':'); // Handle "15:30 (EEST)"
            return DateTime(y, m, d, int.parse(tParts[0]), int.parse(tParts[1]));
          }

          upcomingDays.add(UpcomingDay(
            date: date,
            fajr: parseTimeStr(timings['Fajr']),
            dhuhr: parseTimeStr(timings['Dhuhr']),
            asr: parseTimeStr(timings['Asr']),
            maghrib: parseTimeStr(timings['Maghrib']),
            isha: parseTimeStr(timings['Isha']),
          ));
        }
      }
    } else {
      todayData = rawData;
    }

    final timings = todayData['timings'];
    final date = todayData['date'];

    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(' ')[0].split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final hijri = date['hijri'];
    final hijriStr = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}';

    return PrayerData(
      fajr: parseTime(timings['Fajr']),
      dhuhr: parseTime(timings['Dhuhr']),
      asr: parseTime(timings['Asr']),
      maghrib: parseTime(timings['Maghrib']),
      isha: parseTime(timings['Isha']),
      hijriDate: hijriStr,
      isOffline: isOffline,
      upcomingDays: upcomingDays,
    );
  }
}

class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  PrayerData? currentData;

  static const String _prayerDataKey = 'prayer_data_v2';
  static const String _savedDateKey = 'prayer_data_date_v2';

  Future<PrayerData?> fetchPrayerTimes({
    int method = 5,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final locationService = LocationService();
    final location = await locationService.getSavedLocation();
    final double lat = location.latitude;
    final double lng = location.longitude;
    
    // Check if we need to fetch new data
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_savedDateKey);

    try {
      final now = DateTime.now();
      final url = Uri.parse(
          'https://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$lng&method=$method&month=${now.month}&year=${now.year}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Save to local
        await _saveToLocal(prefs, response.body, today);
        
        currentData = PrayerData.fromJson(data, isOffline: false);
        return currentData;
      } else {
        currentData = await _loadFromLocal(prefs, today == savedDate);
        return currentData;
      }
    } catch (e) {
      // API failed (no internet, etc), load from cache
      currentData = await _loadFromLocal(prefs, today == savedDate);
      return currentData;
    }
  }

  Future<void> _saveToLocal(SharedPreferences prefs, String jsonData, String dateStr) async {
    await prefs.setString(_prayerDataKey, jsonData);
    await prefs.setString(_savedDateKey, dateStr);
    // Notify widgets that data has changed
    await WidgetService.refreshWidgets();
  }

  Future<PrayerData?> _loadFromLocal(SharedPreferences prefs, bool isSameDay) async {
    final jsonData = prefs.getString(_prayerDataKey);
    if (jsonData != null) {
        // Even if it's not the same day, returning last known data is better than nothing, 
        // but we'll mark it as offline.
        final Map<String, dynamic> data = json.decode(jsonData);
        return PrayerData.fromJson(data, isOffline: true);
    }
    return null;
  }
}
