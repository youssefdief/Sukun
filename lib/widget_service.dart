import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.example.sukun_app/widgets');

  static Future<void> refreshWidgets() async {
    try {
      await _channel.invokeMethod('refreshWidgets');
    } on PlatformException catch (e) {
      debugPrint("Failed to refresh widgets: '${e.message}'.");
    }
  }
}
