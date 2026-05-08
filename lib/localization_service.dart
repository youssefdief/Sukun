import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  bool get isArabic => _currentLocale.languageCode == 'ar';

  static const String _prefKey = 'selected_language';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefKey) ?? 'en';
    _currentLocale = Locale(langCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _currentLocale = isArabic ? const Locale('en') : const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _currentLocale.languageCode);
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }

  static LocalizationService of(BuildContext context) {
    return _instance;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Sukun',
      'settings': 'Settings',
      'prayer_times': 'Prayer Times',
      'current': 'CURRENT',
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'min_until': 'min until',
      'h': 'h',
      'm': 'm',
      'until': 'until',
      'hijri_date': 'Hijri Date',
      'using_saved_times': 'Using saved prayer times',
      'prayer_tracker': 'Prayer Tracker',
      'daily_observance': 'DAILY OBSERVANCE',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'select_language': 'Select Language',
      'dhikr': 'Dhikr',
      'last_read': 'Last Read',
      'smart_dhikr': 'Smart Dhikr',
      'am': 'AM',
      'pm': 'PM',
      'loading': 'Loading...',
      'daily_dhikr': 'Daily Dhikr',
      'adhkar': 'ADHKAR',
      'morning': 'Morning',
      'general': 'General',
      'evening': 'Evening',
      'night': 'Night',
      'preferences': 'PREFERENCES',
      'notifications': 'Notifications',
      'notifications_subtitle': 'Prayer alerts & reminders',
      'location_services': 'Location Services',
      'theme': 'Theme',
      'calculation_method': 'CALCULATION METHOD',
      'prayer_authority': 'Prayer Authority',
      'asr_calculation': 'Asr Calculation',
      'about': 'ABOUT',
      'about_sukun': 'About Sukun',
      'privacy_policy': 'Privacy Policy',
      'rate_app': 'Rate the App',
      'made_with_peace': 'Made with peace',
      'upcoming': 'UPCOMING',
      'offline': 'OFFLINE',
      'dhikr_notifications': 'Dhikr Notifications',
      'dhikr_notifications_subtitle': 'Daily morning, evening, and night reminders',
      'passed_since': 'Passed',
      'passed_since_azan': 'mins since',
      'upcoming_days': 'UPCOMING DAYS',
      'tasbeeh': 'Tasbeeh',
      'sleep': 'Sleep',
      'dhikr_completed': 'Completed',
      'swipe_to_continue': 'Swipe to next',
      'target': 'Target',
      'send_test_notification': 'Send Test Notification',
      'test_notification_sent': 'Test notification sent',
      'onboarding_subtitle': 'Your daily companion for peace and remembrance',
      'start': 'Start',
      'automatic_location': 'Automatic Location',
      'manual_location': 'Manual Selection',
      'location_desc': 'To provide accurate prayer times',
      'enable_notifications': 'Enable Notifications',
      'notifications_desc': 'Receive peaceful reminders for prayer and dhikr',
      'finish': 'Finish',
      'daily_inspiration': 'Daily Inspiration',
      'splash_screen_settings': 'Splash Screen',
      'enable_splash': 'Enable Splash Screen',
      'splash_duration': 'Splash Duration',
      'seconds': 'seconds',
    },
    'ar': {
      'app_title': 'سكون',
      'settings': 'الإعدادات',
      'prayer_times': 'مواقيت الصلاة',
      'current': 'الآن',
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'min_until': 'دقيقة حتى',
      'h': 'س',
      'm': 'د',
      'until': 'حتى',
      'hijri_date': 'التاريخ الهجري',
      'using_saved_times': 'يتم استخدام مواقيت الصلاة المحفوظة',
      'prayer_tracker': 'متتبع الصلاة',
      'daily_observance': 'الالتزام اليومي',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'select_language': 'اختر اللغة',
      'dhikr': 'الأذكار',
      'last_read': 'آخر قراءة',
      'smart_dhikr': 'الذكر الذكي',
      'am': 'ص',
      'pm': 'م',
      'loading': 'جاري التحميل...',
      'daily_dhikr': 'أذكار اليوم',
      'adhkar': 'أذكار',
      'morning': 'الصباح',
      'general': 'عام',
      'evening': 'المساء',
      'night': 'النوم',
      'preferences': 'التفضيلات',
      'notifications': 'التنبيهات',
      'notifications_subtitle': 'تنبيهات الصلاة والتذكيرات',
      'location_services': 'خدمات الموقع',
      'theme': 'المظهر',
      'calculation_method': 'طريقة الحساب',
      'prayer_authority': 'مرجع التوقيت',
      'asr_calculation': 'حساب العصر',
      'about': 'حول',
      'about_sukun': 'عن سكون',
      'privacy_policy': 'سياسة الخصوصية',
      'rate_app': 'قيم التطبيق',
      'made_with_peace': 'صنع بكل هدوء',
      'upcoming': 'القادم',
      'offline': 'بدون اتصال',
      'dhikr_notifications': 'إشعارات الأذكار',
      'dhikr_notifications_subtitle': 'تذكيرات يومية في الصباح والمساء والليل',
      'passed_since': 'مرّ',
      'passed_since_azan': 'دقيقة على',
      'upcoming_days': 'الأيام القادمة',
      'tasbeeh': 'تسبيح',
      'sleep': 'النوم',
      'dhikr_completed': 'تم الذكر',
      'swipe_to_continue': 'اسحب للتالي',
      'target': 'الهدف',
      'send_test_notification': 'إرسال إشعار تجريبي',
      'test_notification_sent': 'تم إرسال الإشعار التجريبي',
      'onboarding_subtitle': 'رفيقك اليومي للسكينة والذكر',
      'start': 'ابدأ',
      'automatic_location': 'تحديد تلقائي للموقع',
      'manual_location': 'اختيار يدوي',
      'location_desc': 'لتوفير مواقيت صلاة دقيقة',
      'enable_notifications': 'تفعيل الإشعارات',
      'notifications_desc': 'احصل على تذكيرات هادئة للصلاة والذكر',
      'finish': 'إنهاء',
      'daily_inspiration': 'إلهام يومي',
      'splash_screen_settings': 'شاشة البدء',
      'enable_splash': 'تفعيل شاشة البدء',
      'splash_duration': 'مدة شاشة البدء',
      'seconds': 'ثواني',
    }
  };
}
