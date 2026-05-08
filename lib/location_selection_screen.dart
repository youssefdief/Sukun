import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'location_service.dart';
import 'localization_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isAutomatic = true;
  bool _isLoading = false;
  String _currentCity = '...';
  
  // Search results
  LocationModel? _searchResult;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final loc = await _locationService.getSavedLocation();
    setState(() {
      _isAutomatic = loc.isAutomatic;
      _currentCity = loc.cityName;
    });
  }

  Future<void> _handleAutomaticToggle(bool value) async {
    setState(() {
      _isAutomatic = value;
      _isLoading = true;
    });

    if (value) {
      final loc = await _locationService.determinePosition();
      if (loc != null) {
        setState(() {
          _currentCity = loc.cityName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAutomatic = false; // Revert if permission denied or failed
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().translate('location_permission_denied')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      // Just toggle, keep current city as manual for now until they search
      final currentLoc = await _locationService.getSavedLocation();
      await _locationService.saveLocation(LocationModel(
        latitude: currentLoc.latitude,
        longitude: currentLoc.longitude,
        cityName: currentLoc.cityName,
        isAutomatic: false,
      ));
    }
  }

  Future<void> _searchCity(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchResult = null;
    });

    final result = await _locationService.searchCity(query);
    
    setState(() {
      _isSearching = false;
      if (result != null) {
        _searchResult = result;
      }
    });
  }

  Future<void> _selectManualLocation(LocationModel location) async {
    await _locationService.saveLocation(location);
    setState(() {
      _currentCity = location.cityName;
      _searchController.clear();
      _searchResult = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().translate('location_updated')}: ${location.cityName}'),
          backgroundColor: const Color(0xFF007542),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('location_services'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Automatic Location Toggle Card
            _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isAutomatic 
                          ? const Color(0xFF007542).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.location_fill,
                        color: _isAutomatic ? const Color(0xFF97f7b7) : Colors.white.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('automatic_location'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAutomatic ? _currentCity : loc.translate('detect_my_location'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const CupertinoActivityIndicator(color: Color(0xFF97f7b7))
                    else
                      CupertinoSwitch(
                        value: _isAutomatic,
                        onChanged: _handleAutomaticToggle,
                        activeTrackColor: const Color(0xFF007542),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Manual Location Section
            AnimatedOpacity(
              opacity: _isAutomatic ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: _isAutomatic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('manual_location'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.search, color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: loc.translate('search_city'),
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                border: InputBorder.none,
                              ),
                              onSubmitted: _searchCity,
                            ),
                          ),
                          if (_isSearching)
                            const CupertinoActivityIndicator()
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Search Result
                    if (_searchResult != null)
                      _buildGlassCard(
                        child: InkWell(
                          onTap: () => _selectManualLocation(_searchResult!),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.map_pin_ellipse,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _searchResult!.cityName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(CupertinoIcons.plus_circle_fill, color: const Color(0xFF97f7b7).withValues(alpha: 0.8)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                    if (!_isSearching && _searchController.text.isNotEmpty && _searchResult == null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          loc.translate('no_results_found'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      ),
    );
  }
}
