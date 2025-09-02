/*
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';
import '../main.dart';
import '../services/database_service.dart';

class MapPage
    extends
        StatefulWidget {
  MapPage({
    Key? key,
  }) : super(
         key:
             key,
       ) {
    print(
      'MapPage: constructor called',
    );
  }

  @override
  State<
    MapPage
  >
  createState() =>
      _MapPageState();
}

class SearchFilter {
  final String name;
  final String value;
  final IconData icon;

  const SearchFilter({
    required this.name,
    required this.value,
    required this.icon,
  });
}

class MapSearchResult {
  final String name;
  final String fullAddress;
  final String? type;
  final LatLng location;
  final Map<
    String,
    dynamic
  >?
  details;
  double? distance;
  String? estimatedTime;

  MapSearchResult({
    required this.name,
    required this.fullAddress,
    this.type,
    required this.location,
    this.details,
    this.distance,
    this.estimatedTime,
  });

  String? get openingHours {
    if (details !=
            null &&
        details!['opening_hours'] !=
            null) {
      return details!['opening_hours']['current_status'] ??
          'No hours available';
    }
    return null;
  }
}

class _MapPageState
    extends
        State<
          MapPage
        > {
  final MapController _mapController =
      MapController();
  bool _isLoadingLocation =
      false;
  bool _isSearching =
      false;
  String _searchQuery =
      '';
  List<
    MapSearchResult
  >
  _searchResults =
      [];
  bool _isNightMode =
      false;
  String _selectedMapStyle =
      'default';
  Position? _currentPosition;
  List<
    LatLng
  >
  _routePoints =
      [];
  bool _isLoadingRoute =
      false;
  bool _isMapReady =
      false;
  bool _hasError =
      false;
  String? _errorMessage;

  // Business markers
  List<
    User
  >
  _businesses =
      [];
  User? _selectedBusiness;

  // Map style URLs
  final Map<
    String,
    String
  >
  _mapStyles = {
    'default':
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'terrain':
        'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg',
  };

  @override
  void initState() {
    super.initState();
    print(
      'MapPage: initState called',
    );
    Future.delayed(
      Duration.zero,
      () {
        if (mounted) {
          print(
            'MapPage: calling _initializeLocation and _fetchBusinesses',
          );
          _initializeLocation();
          _fetchBusinesses();
        }
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    print(
      'MapPage: build called',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isNightMode
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
            ),
            onPressed:
                _toggleNightMode,
          ),
        ],
      ),
      body:
          _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size:
                  48,
              color:
                  Colors.red,
            ),
            const SizedBox(
              height:
                  16,
            ),
            Text(
              _errorMessage ??
                  'An error occurred',
            ),
            const SizedBox(
              height:
                  16,
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () {
                    _hasError =
                        false;
                    _errorMessage =
                        null;
                  },
                );
                _initializeLocation();
                _fetchBusinesses();
              },
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingLocation) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    // Set initial center to first business if available
    LatLng initialCenter =
        _businesses.isNotEmpty &&
                _businesses.first.businessLocation !=
                    null
            ? _businesses.first.businessLocation!
            : const LatLng(
              2.1896,
              102.2501,
            );
    return Stack(
      children: [
        FlutterMap(
          mapController:
              _mapController,
          options: MapOptions(
            initialCenter:
                initialCenter,
            initialZoom:
                13.0,
            onMapReady: () {
              print(
                'MapPage: Map is ready',
              );
              if (mounted) {
                setState(
                  () {
                    _isMapReady =
                        true;
                  },
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'FYP_App/1.0',
              subdomains: const [
                'a',
                'b',
                'c',
              ],
            ),
            MarkerLayer(
              markers: [
                ..._businesses
                    .where(
                      (
                        b,
                      ) =>
                          b.businessLocation !=
                          null,
                    )
                    .map(
                      (
                        business,
                      ) => Marker(
                        point:
                            business.businessLocation!,
                        width:
                            40, // Reduced width since no text
                        height:
                            40, // Set height to match
                        child: GestureDetector(
                          onTap:
                              () => _showBusinessDetails(
                                business,
                              ),
                          child: Icon(
                            business.type ==
                                    UserType.business
                                ? Icons.location_on
                                : Icons.person_pin_circle,
                            color:
                                business.type ==
                                        UserType.business
                                    ? Colors.red
                                    : Colors.blue,
                            size:
                                32,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ],
        ),
        // Attribution
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ),
        ),
        Positioned(
          bottom:
              16,
          right:
              16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag:
                    'map_zoom_in',
                onPressed:
                    _zoomIn,
                backgroundColor:
                    _isNightMode
                        ? Colors.grey[800]
                        : null,
                child: Icon(
                  Icons.add,
                  color:
                      _isNightMode
                          ? Colors.white
                          : null,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              FloatingActionButton(
                heroTag:
                    'map_zoom_out',
                onPressed:
                    _zoomOut,
                backgroundColor:
                    _isNightMode
                        ? Colors.grey[800]
                        : null,
                child: Icon(
                  Icons.remove,
                  color:
                      _isNightMode
                          ? Colors.white
                          : null,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              FloatingActionButton(
                heroTag:
                    'map_my_location',
                onPressed:
                    _isLoadingLocation
                        ? null
                        : _getCurrentLocation,
                backgroundColor:
                    _isNightMode
                        ? Colors.grey[800]
                        : null,
                child:
                    _isLoadingLocation
                        ? const SizedBox(
                          width:
                              24,
                          height:
                              24,
                          child: CircularProgressIndicator(
                            strokeWidth:
                                2,
                            valueColor: AlwaysStoppedAnimation<
                              Color
                            >(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.my_location,
                          color:
                              _isNightMode
                                  ? Colors.white
                                  : null,
                        ),
              ),
              if (currentUser?.type ==
                  UserType.business) ...[
                const SizedBox(
                  height:
                      8,
                ),
                FloatingActionButton(
                  heroTag:
                      'map_center_business',
                  onPressed:
                      _centerOnBusinessLocation,
                  backgroundColor:
                      _isNightMode
                          ? Colors.grey[800]
                          : null,
                  child: Icon(
                    Icons.business,
                    color:
                        _isNightMode
                            ? Colors.white
                            : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsSheet(
    User business,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            business.businessName ??
                '',
            style: const TextStyle(
              fontSize:
                  20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          if (business.businessDescription !=
              null)
            Padding(
              padding: const EdgeInsets.only(
                top:
                    8.0,
              ),
              child: Text(
                business.businessDescription!,
              ),
            ),
          if (business.businessAddress !=
              null)
            Padding(
              padding: const EdgeInsets.only(
                top:
                    8.0,
              ),
              child: Text(
                'Address: ${business.businessAddress!}',
              ),
            ),
          if (business.businessPhone !=
              null)
            Padding(
              padding: const EdgeInsets.only(
                top:
                    8.0,
              ),
              child: Text(
                'Phone: ${business.businessPhone!}',
              ),
            ),
          if (business.businessEmail !=
              null)
            Padding(
              padding: const EdgeInsets.only(
                top:
                    8.0,
              ),
              child: Text(
                'Email: ${business.businessEmail!}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessMarker(
    User user,
  ) {
    // Show different marker color/icon for business vs normal user
    final isBusiness =
        user.type ==
        UserType.business;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(
            8,
          ),
          decoration: BoxDecoration(
            color:
                Colors.white,
            shape:
                BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.2,
                ),
                blurRadius:
                    8,
                spreadRadius:
                    2,
              ),
            ],
          ),
          child: Icon(
            isBusiness
                ? Icons.location_on
                : Icons.person_pin_circle,
            color:
                isBusiness
                    ? Colors.red
                    : Colors.blue,
            size:
                32,
          ),
        ),
        const SizedBox(
          height:
              4,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal:
                8,
            vertical:
                4,
          ),
          decoration: BoxDecoration(
            color:
                Colors.white,
            borderRadius: BorderRadius.circular(
              8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.1,
                ),
                blurRadius:
                    4,
                spreadRadius:
                    1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                isBusiness
                    ? (user.businessName ??
                        'Business')
                    : user.username,
                style: const TextStyle(
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.black87,
                ),
              ),
              // Removed business hours to prevent overflow
            ],
          ),
        ),
      ],
    );
  }

  Future<
    void
  >
  _initializeLocation() async {
    if (!mounted) return;

    print(
      'MapPage: Initializing location...',
    );
    try {
      setState(
        () {
          _isLoadingLocation =
              true;
          _hasError =
              false;
          _errorMessage =
              null;
        },
      );

      // Check location permission
      LocationPermission permission =
          await Geolocator.checkPermission();
      print(
        'MapPage: Current permission status: $permission',
      );

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
        print(
          'MapPage: Requested permission, new status: $permission',
        );

        if (permission ==
            LocationPermission.denied) {
          if (!mounted) return;
          setState(
            () {
              _isLoadingLocation =
                  false;
              _hasError =
                  true;
              _errorMessage =
                  'Location permission denied. Some features may not work.';
            },
          );
          return;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(
          () {
            _isLoadingLocation =
                false;
            _hasError =
                true;
            _errorMessage =
                'Location permissions are permanently denied. Please enable them in settings.';
          },
        );
        return;
      }

      // Get current position
      final position =
          await Geolocator.getCurrentPosition();
      print(
        'MapPage: Got position: ${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;
      setState(
        () {
          _currentPosition =
              position;
          _isLoadingLocation =
              false;
          _isMapReady =
              true;
        },
      );
    } catch (
      e,
      stackTrace
    ) {
      print(
        'MapPage: Error initializing location: $e',
      );
      print(
        'MapPage: Stack trace: $stackTrace',
      );
      if (!mounted) return;
      setState(
        () {
          _isLoadingLocation =
              false;
          _hasError =
              true;
          _errorMessage =
              'Error initializing map: $e';
        },
      );
    }
  }

  Future<
    void
  >
  _fetchBusinesses() async {
    print(
      'Calling _fetchBusinesses...',
    );
    final usersWithLocation =
        await DatabaseService().getAllUsersWithLocation();
    print(
      'Fetched users with location: \\${usersWithLocation.length}',
    );
    for (final u in usersWithLocation) {
      print(
        'User: \\${u.username} (type: \\${u.type}) at \\${u.businessLocation}',
      );
    }
    setState(
      () {
        _businesses =
            usersWithLocation;
      },
    );
  }

  void _toggleNightMode() {
    setState(
      () {
        _isNightMode =
            !_isNightMode;
      },
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom +
          1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom -
          1,
    );
  }

  Future<
    void
  >
  _getCurrentLocation() async {
    try {
      setState(
        () {
          _isLoadingLocation =
              true;
        },
      );
      final position =
          await Geolocator.getCurrentPosition();
      setState(
        () {
          _currentPosition =
              position;
          _isLoadingLocation =
              false;
        },
      );
      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        _mapController.camera.zoom,
      );
    } catch (
      e
    ) {
      setState(
        () {
          _isLoadingLocation =
              false;
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Could not get current location: $e',
          ),
        ),
      );
    }
  }

  void _centerOnBusinessLocation() {
    if (currentUser?.type ==
            UserType.business &&
        currentUser?.businessLocation !=
            null) {
      _mapController.move(
        currentUser!.businessLocation!,
        _mapController.camera.zoom,
      );
    }
  }

  void _showBusinessDetails(
    User business,
  ) {
    showModalBottomSheet(
      context:
          context,
      builder:
          (
            context,
          ) => _buildBusinessDetailsSheet(
            business,
          ),
    );
  }

  // ... rest of your existing MapPage code ...
}
*/
