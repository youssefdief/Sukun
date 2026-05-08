import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'localization_service.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('coming_soon'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
