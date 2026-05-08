import 'package:flutter/material.dart';
import 'daily_quote_service.dart';
import 'localization_service.dart';
import 'main.dart'; // to use GlassPanel

class DailyQuoteCard extends StatefulWidget {
  final DateTime now;
  const DailyQuoteCard({Key? key, required this.now}) : super(key: key);

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  final DailyQuoteService _service = DailyQuoteService();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    await _service.init();
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const SizedBox(height: 120); // Placeholder
    }

    final quote = _service.getDailyQuote(widget.now);
    if (quote == null) {
      return const SizedBox.shrink();
    }

    final loc = LocalizationService();
    final isArabic = loc.isArabic;

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007542).withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007542).withValues(alpha: 0.05),
                    blurRadius: 40,
                  )
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Column(
              key: ValueKey(quote.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate('daily_inspiration').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: isArabic ? 0.0 : 2.0,
                      ),
                    ),
                    Icon(
                      Icons.format_quote_rounded,
                      color: const Color(0xFF97f7b7).withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? quote.textAr : quote.textEn,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isArabic ? 20 : 16,
                    fontWeight: isArabic ? FontWeight.w500 : FontWeight.w600,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? quote.sourceAr : quote.sourceEn,
                  textAlign: isArabic ? TextAlign.left : TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFF97f7b7).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
