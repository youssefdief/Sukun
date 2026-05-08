import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dhikr_service.dart';
import 'localization_service.dart';
import 'dynamic_sky.dart';
import 'main_screen.dart';

class DhikrScreen extends StatefulWidget {
  final String? initialCategory;
  final bool isTab;
  const DhikrScreen({Key? key, this.initialCategory, this.isTab = false}) : super(key: key);

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  final DhikrService _dhikrService = DhikrService();
  late PageController _pageController;
  
  String _selectedCategory = 'Morning';
  List<DhikrItem> _currentAdhkar = [];
  final Map<int, int> _counts = {};
  int _currentIndex = 0;

  final List<String> _categories = ['Morning', 'Evening', 'Night', 'General'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Morning';
    _pageController = PageController(initialPage: 0);
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    } else {
      _selectedCategory = _dhikrService.getCurrentDhikrType(DateTime.now());
    }
    
    _loadCategory(_selectedCategory);
    
    int lastIndex = prefs.getInt('last_dhikr_index_$_selectedCategory') ?? 0;
    if (lastIndex >= _currentAdhkar.length) lastIndex = 0;
    
    _currentIndex = lastIndex;
    
    if (_currentIndex > 0 && _pageController.hasClients) {
      _pageController.jumpToPage(_currentIndex);
    } else if (_currentIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_dhikr_category', _selectedCategory);
    await prefs.setInt('last_dhikr_index_$_selectedCategory', _currentIndex);
  }

  void _loadCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _currentAdhkar = _dhikrService.getDhikrList(category);
      _counts.clear();
      _currentIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _saveState();
  }

  void _onDhikrTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      int currentCount = _counts[index] ?? 0;
      int maxCount = _currentAdhkar[index].count;
      
      if (currentCount < maxCount) {
        _counts[index] = currentCount + 1;
      }

      if (_counts[index] == maxCount && index < _currentAdhkar.length - 1) {
        // Auto-advance
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pageController.hasClients) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();

    // Map categories to localization keys
    Map<String, String> categoryKeys = {
      'Morning': 'morning',
      'Evening': 'evening',
      'Night': 'sleep',
      'General': 'tasbeeh',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: Stack(
        children: [
          // Background Effect
          Positioned.fill(
            child: DynamicSky(
              currentTime: _selectedCategory == 'Morning' ? DateTime(2000, 1, 1, 7, 30) : 
                           _selectedCategory == 'Evening' ? DateTime(2000, 1, 1, 18, 0) : 
                           _selectedCategory == 'Night' ? DateTime(2000, 1, 1, 23, 0) : null,
              scrollOffset: 0,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      if (!widget.isTab)
                        IconButton(
                          icon: const Icon(CupertinoIcons.back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      Text(
                        loc.translate('dhikr').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF97f7b7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),

                // Category Tabs
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _loadCategory(category);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF007542) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF007542) : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              loc.translate(categoryKeys[category]!),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main PageView
                Expanded(
                  child: _currentAdhkar.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF007542)))
                      : PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _saveState();
                          },
                          itemCount: _currentAdhkar.length,
                          itemBuilder: (context, index) {
                            final dhikr = _currentAdhkar[index];
                            final count = _counts[index] ?? 0;
                            final maxCount = dhikr.count;
                            final isCompleted = count >= maxCount;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                              child: GestureDetector(
                                onTap: () => _onDhikrTap(index),
                                child: _GlassDhikrCard(
                                  dhikr: dhikr,
                                  currentCount: count,
                                  isCompleted: isCompleted,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer (Progress indicator)
                if (_currentAdhkar.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: widget.isTab ? MainScreen.navBarHeight : 32.0),
                    child: Column(
                      children: [
                        Text(
                          '${_currentIndex + 1} / ${_currentAdhkar.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.translate('swipe_to_continue'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
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

class _GlassDhikrCard extends StatelessWidget {
  final DhikrItem dhikr;
  final int currentCount;
  final bool isCompleted;

  const _GlassDhikrCard({
    Key? key,
    required this.dhikr,
    required this.currentCount,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final double progress = currentCount / dhikr.count;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isCompleted 
            ? const Color(0xFF007542).withValues(alpha: 0.5) 
            : Colors.white.withValues(alpha: 0.05),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          if (isCompleted)
            BoxShadow(
              color: const Color(0xFF007542).withValues(alpha: 0.2),
              blurRadius: 40,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              // Progress Fill Background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: progress * MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF007542).withValues(alpha: 0.2),
                        const Color(0xFF007542).withValues(alpha: 0.0),
                      ]
                    )
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                dhikr.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  height: 1.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              dhikr.translation,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Counter Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF97f7b7)),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted 
                              ? const Color(0xFF007542) 
                              : Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Center(
                            child: isCompleted
                              ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 32)
                              : Text(
                                  '$currentCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCompleted ? loc.translate('dhikr_completed') : '${loc.translate('target')}: ${dhikr.count}',
                      style: TextStyle(
                        color: isCompleted ? const Color(0xFF97f7b7) : Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
