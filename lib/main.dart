import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart' as auth;
import 'models/user.dart';
import 'admin/admin_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as logging;
import 'package:firebase_core/firebase_core.dart';
import 'pages/profile_page.dart';
import 'pages/nearby_businesses_page.dart';
import 'pages/my_menu_page.dart';

// Global variable to store current user
User?
currentUser;

void
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MyApp(),
  );
}

class MyApp
    extends
        StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title:
          'Flutter Map Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.deepPurple,
        ),
      ),
      initialRoute:
          '/login',
      routes: {
        '/login':
            (
              context,
            ) =>
                const LoginPage(),
        '/signup':
            (
              context,
            ) =>
                const auth.SignupPage(),
        '/home':
            (
              context,
            ) =>
                const MainScreen(),
      },
    );
  }
}

class MainScreen
    extends
        StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<
    MainScreen
  >
  createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends
        State<
          MainScreen
        > {
  int _selectedIndex =
      0;

  List<
    Widget
  >
  get _pages {
    if (currentUser ==
        null) {
      return [
        const Center(
          child: Text(
            'No user logged in',
          ),
        ),
      ];
    }

    if (currentUser?.type ==
        UserType.admin) {
      return [
        const NearbyBusinessesPage(),
        const AdminPage(),
        const ProfilePage(),
      ];
    }
    if (currentUser?.type ==
        UserType.business) {
      return [
        NearbyBusinessesPage(
          onlyShowCurrentBusiness:
              true,
        ),
        const MyMenuPage(),
        const ProfilePage(),
      ];
    }
    return [
      const NearbyBusinessesPage(),
      const ProfilePage(),
    ];
  }

  List<
    BottomNavigationBarItem
  >
  get _navigationItems {
    if (currentUser ==
        null) {
      return [];
    }

    if (currentUser?.type ==
        UserType.admin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.business,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.business,
            color:
                Colors.deepPurple,
          ),
          label:
              'Nearby',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.admin_panel_settings,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.admin_panel_settings,
            color:
                Colors.deepPurple,
          ),
          label:
              'Admin',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.person,
            color:
                Colors.deepPurple,
          ),
          label:
              'Account',
        ),
      ];
    }
    if (currentUser?.type ==
        UserType.business) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.map,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.map,
            color:
                Colors.deepPurple,
          ),
          label:
              'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.restaurant_menu,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.restaurant_menu,
            color:
                Colors.deepPurple,
          ),
          label:
              'My Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color:
                Colors.grey,
          ),
          activeIcon: Icon(
            Icons.person,
            color:
                Colors.deepPurple,
          ),
          label:
              'Account',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.business,
          color:
              Colors.grey,
        ),
        activeIcon: Icon(
          Icons.business,
          color:
              Colors.deepPurple,
        ),
        label:
            'Nearby',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.person,
          color:
              Colors.grey,
        ),
        activeIcon: Icon(
          Icons.person,
          color:
              Colors.deepPurple,
        ),
        label:
            'Account',
      ),
    ];
  }

  void _onItemTapped(
    int index,
  ) {
    if (currentUser ==
        null)
      return;
    setState(
      () {
        _selectedIndex =
            index;
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    print(
      'MainScreen: build called, selectedIndex=$_selectedIndex',
    );
    if (currentUser ==
        null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No user logged in',
          ),
        ),
      );
    }

    return Scaffold(
      body:
          _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items:
            _navigationItems,
        currentIndex:
            _selectedIndex,
        onTap:
            _onItemTapped,
      ),
    );
  }
}

class MapPage
    extends
        StatefulWidget {
  const MapPage({
    super.key,
  });

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

  // Route information
  double? _routeDistance;
  int? _routeDuration;
  String? _routeDestination;

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
    _initializeLocation();
  }

  Future<
    void
  >
  _initializeLocation() async {
    try {
      // Check location permission
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
        if (permission ==
            LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Some features may not work.',
                ),
                backgroundColor:
                    Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable them in settings.',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      final position =
          await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(
          () {
            _currentPosition =
                position;
          },
        );
      }
    } catch (
      e
    ) {
      print(
        'Error initializing location: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
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

      // Check location permission
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
        if (permission ==
            LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied',
                ),
                backgroundColor:
                    Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Get current position
      final position =
          await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(
          () {
            _currentPosition =
                position;
          },
        );
        _mapController.move(
          LatLng(
            position.latitude,
            position.longitude,
          ),
          _mapController.camera.zoom,
        );
      }
    } catch (
      e
    ) {
      print(
        'Error getting current location: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoadingLocation =
                false;
          },
        );
      }
    }
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

  void _centerOnBusinessLocation() {
    if (currentUser?.type ==
        UserType.business) {
      _mapController.move(
        currentUser!.businessLocation!,
        _mapController.camera.zoom,
      );
    }
  }

  Future<
    void
  >
  _searchLocation(
    String query,
  ) async {
    if (query.isEmpty) {
      setState(
        () {
          _searchResults =
              [];
          _isSearching =
              false;
        },
      );
      return;
    }

    setState(
      () {
        _isSearching =
            true;
      },
    );

    try {
      // For now, just use basic search until database is implemented
      final String searchQuery =
          '$query, Malacca, Malaysia';

      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=10&countrycodes=my',
        ),
        headers: {
          'User-Agent':
              'FYP_App/1.0',
        },
      );

      if (response.statusCode ==
          200) {
        final List<
          dynamic
        >
        data = json.decode(
          response.body,
        );
        logging.debugPrint(
          'Found ${data.length} locations',
        ); // Debug log

        setState(
          () {
            _searchResults =
                data.map(
                  (
                    item,
                  ) {
                    final String fullAddress =
                        item['display_name']
                            as String;
                    final String
                    mainName =
                        fullAddress
                            .split(
                              ',',
                            )
                            .first;

                    return MapSearchResult(
                      name:
                          mainName,
                      fullAddress:
                          fullAddress,
                      location: LatLng(
                        double.parse(
                          item['lat']
                              as String,
                        ),
                        double.parse(
                          item['lon']
                              as String,
                        ),
                      ),
                    );
                  },
                ).toList();
          },
        );

        if (_searchResults.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'No locations found. Try a different search term.',
              ),
              backgroundColor:
                  Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(
          'Failed to load search results',
        );
      }
    } catch (
      e
    ) {
      logging.debugPrint(
        'Error searching for location: $e',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Error searching for location. Please check your internet connection and try again.\nDetails: ${e.toString()}',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      setState(
        () {
          _searchResults =
              [];
        },
      );
    } finally {
      setState(
        () {
          _isSearching =
              false;
        },
      );
    }
  }

  void _selectSearchResult(
    MapSearchResult result,
  ) {
    _mapController.move(
      result.location,
      16.0,
    ); // Zoom in closer to the selected location
    setState(
      () {
        _searchQuery =
            '';
        _searchResults =
            [];
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

  void _changeMapStyle(
    String style,
  ) {
    setState(
      () {
        _selectedMapStyle =
            style;
      },
    );
  }

  Future<
    void
  >
  _showRouteDetails(
    MapSearchResult result,
  ) async {
    if (_currentPosition ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to get current location. Please enable location services.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    setState(
      () {
        _isLoadingRoute =
            true;
      },
    );

    try {
      // Get route using OSRM
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${result.location.longitude},${result.location.latitude}'
          '?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode ==
          200) {
        final data = json.decode(
          response.body,
        );
        if (data['routes'] !=
                null &&
            data['routes'].isNotEmpty) {
          final route =
              data['routes'][0];
          final geometry =
              route['geometry'];
          final coordinates =
              geometry['coordinates']
                  as List;

          setState(
            () {
              _routePoints =
                  coordinates.map(
                    (
                      coord,
                    ) {
                      return LatLng(
                        coord[1].toDouble(),
                        coord[0].toDouble(),
                      );
                    },
                  ).toList();

              // Store route information
              _routeDistance =
                  route['distance'] /
                  1000; // Convert to km
              _routeDuration =
                  (route['duration'] /
                          60)
                      .round(); // Convert to minutes
              _routeDestination =
                  result.name;
            },
          );

          // Fit map to show entire route
          if (_routePoints.isNotEmpty) {
            _fitMapToRoute();
          }

          // Show enhanced route details dialog
          if (!mounted) return;
          showDialog(
            context:
                context,
            builder:
                (
                  context,
                ) => AlertDialog(
                  title: Text(
                    'Route to ${result.name}',
                  ),
                  content: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance: ${_routeDistance?.toStringAsFixed(1) ?? "N/A"} km',
                      ),
                      Text(
                        'Estimated time: ${_routeDuration ?? "N/A"} minutes',
                      ),
                      const SizedBox(
                        height:
                            16,
                      ),
                      const Text(
                        'Options:',
                      ),
                      const SizedBox(
                        height:
                            8,
                      ),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.map,
                            ),
                            label: const Text(
                              'View Route',
                            ),
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop();
                              // Route is already displayed on map
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Route displayed on map. Tap "Clear Route" to remove.',
                                  ),
                                  backgroundColor:
                                      Colors.green,
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.navigation,
                            ),
                            label: const Text(
                              'Navigate',
                            ),
                            onPressed:
                                () => _launchMapsUrl(
                                  result,
                                  'google',
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                        _clearRoute();
                      },
                      child: const Text(
                        'Clear Route',
                      ),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (
      e
    ) {
      logging.debugPrint(
        'Error getting route: $e',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Error getting route: ${e.toString()}',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      setState(
        () {
          _isLoadingRoute =
              false;
        },
      );
    }
  }

  Future<
    void
  >
  _launchMapsUrl(
    MapSearchResult result,
    String app,
  ) async {
    String url;
    if (app ==
        'google') {
      url =
          'https://www.google.com/maps/dir/?api=1'
          '&destination=${result.location.latitude},${result.location.longitude}'
          '&travelmode=driving';
    } else {
      url =
          'https://waze.com/ul?ll=${result.location.latitude},${result.location.longitude}&navigate=yes';
    }

    if (await canLaunchUrl(
      Uri.parse(
        url,
      ),
    )) {
      await launchUrl(
        Uri.parse(
          url,
        ),
        mode:
            LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch $app Maps',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    // Calculate bounds to fit the entire route
    double minLat =
        _routePoints.first.latitude;
    double maxLat =
        _routePoints.first.latitude;
    double minLng =
        _routePoints.first.longitude;
    double maxLng =
        _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = min(
        minLat,
        point.latitude,
      );
      maxLat = max(
        maxLat,
        point.latitude,
      );
      minLng = min(
        minLng,
        point.longitude,
      );
      maxLng = max(
        maxLng,
        point.longitude,
      );
    }

    // Add some padding
    const padding =
        0.01; // Adjust this value for more/less padding
    final center = LatLng(
      (minLat +
              maxLat) /
          2,
      (minLng +
              maxLng) /
          2,
    );

    // Calculate appropriate zoom level
    final latDiff =
        maxLat -
        minLat;
    final lngDiff =
        maxLng -
        minLng;
    final maxDiff = max(
      latDiff,
      lngDiff,
    );

    double zoom =
        15.0;
    if (maxDiff >
        0.1)
      zoom =
          10.0;
    if (maxDiff >
        0.5)
      zoom =
          8.0;
    if (maxDiff >
        1.0)
      zoom =
          6.0;

    _mapController.move(
      center,
      zoom,
    );
  }

  void _clearRoute() {
    setState(
      () {
        _routePoints =
            [];
        _routeDistance =
            null;
        _routeDuration =
            null;
        _routeDestination =
            null;
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(
              context,
            ).colorScheme.inversePrimary,
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
      body: Theme(
        data:
            _isNightMode
                ? ThemeData.dark().copyWith(
                  scaffoldBackgroundColor:
                      Colors.black,
                  cardColor:
                      Colors.grey[900],
                )
                : Theme.of(
                  context,
                ),
        child: Stack(
          children: [
            FlutterMap(
              mapController:
                  _mapController,
              options: MapOptions(
                initialCenter:
                    currentUser?.type ==
                            UserType.business
                        ? currentUser!.businessLocation!
                        : const LatLng(
                          2.1896,
                          102.2501,
                        ),
                initialZoom:
                    13.0,
                onTap: (
                  tapPosition,
                  point,
                ) {
                  // Close any open info windows
                  setState(
                    () {
                      _searchQuery =
                          '';
                      _searchResults =
                          [];
                    },
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      _mapStyles[_selectedMapStyle],
                  userAgentPackageName:
                      'FYP_App/1.0',
                  subdomains: const [
                    'a',
                    'b',
                    'c',
                  ],
                  tileBuilder: (
                    context,
                    widget,
                    tile,
                  ) {
                    return ColorFiltered(
                      colorFilter:
                          _isNightMode
                              ? const ColorFilter.matrix(
                                [
                                  0.75,
                                  0,
                                  0,
                                  0,
                                  -5, // Red channel
                                  0,
                                  0.75,
                                  0,
                                  0,
                                  -5, // Green channel
                                  0,
                                  0,
                                  1,
                                  0,
                                  10, // Blue channel - slightly enhanced
                                  0,
                                  0,
                                  0,
                                  1,
                                  0, // Alpha channel
                                ],
                              )
                              : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.saturation,
                              ),
                      child:
                          widget,
                    );
                  },
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:
                            _routePoints,
                        color:
                            Colors.blue,
                        strokeWidth:
                            4.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (currentUser?.type ==
                            UserType.business &&
                        currentUser?.businessLocation !=
                            null)
                      Marker(
                        point:
                            currentUser!.businessLocation!,
                        width:
                            200,
                        height:
                            80,
                        child: GestureDetector(
                          onTap:
                              () => _showBusinessDetails(
                                currentUser!,
                              ),
                          child: _buildBusinessMarker(
                            currentUser!,
                          ),
                        ),
                      ),

                    // Start marker (current location) when route is active
                    if (_routePoints.isNotEmpty &&
                        _currentPosition !=
                            null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width:
                            40,
                        height:
                            40,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Colors.green,
                            shape:
                                BoxShape.circle,
                            border: Border.all(
                              color:
                                  Colors.white,
                              width:
                                  2,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color:
                                Colors.white,
                            size:
                                20,
                          ),
                        ),
                      ),

                    // End marker (destination) when route is active
                    if (_routePoints.isNotEmpty)
                      Marker(
                        point:
                            _routePoints.last,
                        width:
                            40,
                        height:
                            40,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Colors.red,
                            shape:
                                BoxShape.circle,
                            border: Border.all(
                              color:
                                  Colors.white,
                              width:
                                  2,
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color:
                                Colors.white,
                            size:
                                20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Attribution
            Positioned(
              bottom:
                  8,
              left:
                  8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      8,
                  vertical:
                      4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.8,
                  ),
                  borderRadius: BorderRadius.circular(
                    4,
                  ),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    fontSize:
                        10,
                    color:
                        Colors.black54,
                  ),
                ),
              ),
            ),
            // Search Bar
            Positioned(
              top:
                  8,
              left:
                  16,
              right:
                  16,
              child: Column(
                children: [
                  // Search Bar
                  Card(
                    elevation:
                        4,
                    color:
                        _isNightMode
                            ? Colors.grey[900]
                            : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal:
                            8.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color:
                                _isNightMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(
                            width:
                                8,
                          ),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Search restaurants...',
                                hintStyle: TextStyle(
                                  color:
                                      _isNightMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                                border:
                                    InputBorder.none,
                              ),
                              style: TextStyle(
                                color:
                                    _isNightMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              onChanged: (
                                value,
                              ) {
                                setState(
                                  () {
                                    _searchQuery =
                                        value;
                                  },
                                );
                                _searchLocation(
                                  value,
                                );
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color:
                                    _isNightMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(
                                  () {
                                    _searchQuery =
                                        '';
                                    _searchResults =
                                        [];
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Search Results
                  if (_searchResults.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(
                        top:
                            8,
                      ),
                      color:
                          _isNightMode
                              ? Colors.grey[900]
                              : Colors.white,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(
                                context,
                              ).size.height *
                              0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap:
                              true,
                          itemCount:
                              _searchResults.length,
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            final result =
                                _searchResults[index];
                            return _buildSearchResult(
                              result,
                            );
                          },
                        ),
                      ),
                    ),
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.all(
                        8.0,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<
                            Color
                          >(
                            _isNightMode
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).primaryColor,
                          ),
                        ),
                      ),
                    ),

                  // Route Information Panel
                  if (_routePoints.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(
                        top:
                            8,
                      ),
                      color:
                          _isNightMode
                              ? Colors.grey[900]
                              : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          12.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Text(
                                    'Route to ${_routeDestination ?? "Destination"}',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          _isNightMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  if (_routeDistance !=
                                          null &&
                                      _routeDuration !=
                                          null)
                                    Text(
                                      '${_routeDistance!.toStringAsFixed(1)} km • ${_routeDuration} min',
                                      style: TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            _isNightMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                              ),
                              onPressed:
                                  _clearRoute,
                              color:
                                  Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Map Style Selector
            Positioned(
              top:
                  72,
              right:
                  16,
              child: Card(
                color:
                    _isNightMode
                        ? Colors.grey[900]
                        : Colors.white,
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.map,
                        color:
                            _isNightMode
                                ? Colors.white
                                : Colors.black,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context:
                              context,
                          builder:
                              (
                                context,
                              ) => Container(
                                color:
                                    _isNightMode
                                        ? Colors.grey[900]
                                        : Colors.white,
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(
                                        Icons.map,
                                        color:
                                            _isNightMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                      title: Text(
                                        'Default',
                                        style: TextStyle(
                                          color:
                                              _isNightMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      onTap: () {
                                        _changeMapStyle(
                                          'default',
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.satellite,
                                        color:
                                            _isNightMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                      title: Text(
                                        'Satellite',
                                        style: TextStyle(
                                          color:
                                              _isNightMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      onTap: () {
                                        _changeMapStyle(
                                          'satellite',
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.terrain,
                                        color:
                                            _isNightMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                      title: Text(
                                        'Terrain',
                                        style: TextStyle(
                                          color:
                                              _isNightMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      onTap: () {
                                        _changeMapStyle(
                                          'terrain',
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Control Buttons
            Positioned(
              right:
                  16,
              bottom:
                  16,
              child: Column(
                children: [
                  FloatingActionButton(
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

                  // Route control button
                  if (_routePoints.isNotEmpty) ...[
                    const SizedBox(
                      height:
                          8,
                    ),
                    FloatingActionButton(
                      heroTag:
                          'clear_route',
                      onPressed:
                          _clearRoute,
                      backgroundColor:
                          Colors.red,
                      child: const Icon(
                        Icons.clear,
                        color:
                            Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isLoadingRoute)
              Container(
                color: Colors.black.withAlpha(
                  (0.5 *
                          255)
                      .round(),
                ),
                child: const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(
    MapSearchResult result,
  ) {
    return ListTile(
      leading: const Icon(
        Icons.restaurant,
      ),
      title: Text(
        result.name,
        style: TextStyle(
          color:
              _isNightMode
                  ? Colors.white
                  : Colors.black,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            result.fullAddress,
            style: TextStyle(
              color:
                  _isNightMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
              fontSize:
                  12,
            ),
            maxLines:
                2,
            overflow:
                TextOverflow.ellipsis,
          ),
          if (result.distance !=
              null)
            Text(
              '${(result.distance! / 1000).toStringAsFixed(1)} km • ${result.estimatedTime}',
              style: TextStyle(
                color:
                    _isNightMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                fontSize:
                    12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.directions,
        ),
        onPressed:
            () => _showRouteDetails(
              result,
            ),
        color:
            Theme.of(
              context,
            ).primaryColor,
      ),
      onTap:
          () => _selectSearchResult(
            result,
          ),
    );
  }

  Widget _buildBusinessMarker(
    User business,
  ) {
    return Column(
      children: [
        Icon(
          Icons.location_on,
          color:
              _isNightMode
                  ? Colors.lightBlueAccent
                  : Colors.red,
          size:
              40,
        ),
        Container(
          padding: const EdgeInsets.all(
            4,
          ),
          decoration: BoxDecoration(
            color:
                _isNightMode
                    ? Colors.grey[900]
                    : Colors.white,
            borderRadius: BorderRadius.circular(
              4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.2,
                ),
                blurRadius:
                    4,
                offset: const Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                business.businessName!,
                style: TextStyle(
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      _isNightMode
                          ? Colors.white
                          : Colors.black,
                ),
              ),
              Text(
                '${business.openingTime!.format(context)} - ${business.closingTime!.format(context)}',
                style: TextStyle(
                  fontSize:
                      10,
                  color:
                      _isNightMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBusinessDetails(
    User business,
  ) {
    showModalBottomSheet(
      context:
          context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      builder:
          (
            context,
          ) => Container(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  business.businessName!,
                  style: const TextStyle(
                    fontSize:
                        24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Text(
                  business.businessDescription!,
                  style: TextStyle(
                    color:
                        Colors.grey[600],
                    fontSize:
                        16,
                  ),
                ),
                const SizedBox(
                  height:
                      16,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      '${business.openingTime!.format(context)} - ${business.closingTime!.format(context)}',
                      style: const TextStyle(
                        fontSize:
                            16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Expanded(
                      child: Text(
                        business.businessAddress!,
                        style: const TextStyle(
                          fontSize:
                              16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      business.businessPhone!,
                      style: const TextStyle(
                        fontSize:
                            16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      business.businessEmail!,
                      style: const TextStyle(
                        fontSize:
                            16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      16,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () => _showRouteDetails(
                          MapSearchResult(
                            name:
                                business.businessName!,
                            fullAddress:
                                business.businessAddress!,
                            location:
                                business.businessLocation!,
                          ),
                        ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical:
                            12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Get Directions',
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class AccountPage
    extends
        StatefulWidget {
  const AccountPage({
    super.key,
  });

  @override
  State<
    AccountPage
  >
  createState() =>
      _AccountPageState();
}

class _AccountPageState
    extends
        State<
          AccountPage
        > {
  final _formKey =
      GlobalKey<
        FormState
      >();
  late TextEditingController _businessNameController;
  late TextEditingController _businessDescriptionController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  LatLng? _selectedLocation;
  bool _isEditing =
      false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _businessNameController = TextEditingController(
      text:
          currentUser?.businessName,
    );
    _businessDescriptionController = TextEditingController(
      text:
          currentUser?.businessDescription,
    );
    _businessAddressController = TextEditingController(
      text:
          currentUser?.businessAddress,
    );
    _businessPhoneController = TextEditingController(
      text:
          currentUser?.businessPhone,
    );
    _businessEmailController = TextEditingController(
      text:
          currentUser?.businessEmail,
    );
    _openingTime =
        currentUser?.openingTime;
    _closingTime =
        currentUser?.closingTime;
    _selectedLocation =
        currentUser?.businessLocation;
  }

  void _logout(
    BuildContext context,
  ) {
    showDialog(
      context:
          context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.pop(
                    context,
                  ),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                currentUser =
                    null;
                Navigator.pop(
                  context,
                );
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<
    void
  >
  _selectTime(
    BuildContext context,
    bool isOpeningTime,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context:
          context,
      initialTime:
          isOpeningTime
              ? _openingTime ??
                  const TimeOfDay(
                    hour:
                        9,
                    minute:
                        0,
                  )
              : _closingTime ??
                  const TimeOfDay(
                    hour:
                        17,
                    minute:
                        0,
                  ),
    );
    if (picked !=
        null) {
      setState(
        () {
          if (isOpeningTime) {
            _openingTime =
                picked;
          } else {
            _closingTime =
                picked;
          }
        },
      );
    }
  }

  Future<
    void
  >
  _selectLocation(
    BuildContext context,
  ) async {
    final LatLng? result = await showDialog<
      LatLng
    >(
      context:
          context,
      builder: (
        BuildContext context,
      ) {
        LatLng? selectedLocation =
            _selectedLocation ??
            const LatLng(
              2.1896,
              102.2501,
            );
        final mapController =
            MapController();

        return AlertDialog(
          title: const Text(
            'Select Business Location',
          ),
          content: SizedBox(
            width:
                MediaQuery.of(
                  context,
                ).size.width *
                0.8,
            height:
                MediaQuery.of(
                  context,
                ).size.height *
                0.6,
            child: Stack(
              children: [
                FlutterMap(
                  mapController:
                      mapController,
                  options: MapOptions(
                    initialCenter:
                        selectedLocation,
                    initialZoom:
                        15,
                    onTap: (
                      tapPosition,
                      point,
                    ) {
                      selectedLocation =
                          point;
                      Navigator.of(
                        context,
                      ).pop(
                        point,
                      );
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
                        if (_selectedLocation !=
                            null)
                          Marker(
                            point:
                                _selectedLocation!,
                            width:
                                40,
                            height:
                                40,
                            child: const Icon(
                              Icons.location_on,
                              color:
                                  Colors.red,
                              size:
                                  40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color:
                        Colors.blue,
                    size:
                        40,
                  ),
                ),
                Positioned(
                  bottom:
                      16,
                  left:
                      16,
                  right:
                      16,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(
                        selectedLocation,
                      );
                    },
                    child: const Text(
                      'Confirm Location',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.of(
                        context,
                      ).pop(),
              child: const Text(
                'Cancel',
              ),
            ),
          ],
        );
      },
    );

    if (result !=
        null) {
      setState(
        () {
          _selectedLocation =
              result;
          // Update the address based on the new location
          _updateAddressFromLocation(
            result,
          );
        },
      );
    }
  }

  Future<
    void
  >
  _updateAddressFromLocation(
    LatLng location,
  ) async {
    try {
      List<
        Placemark
      >
      placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place =
            placemarks.first;
        final address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
        setState(
          () {
            _businessAddressController.text = address;
          },
        );
      }
    } catch (
      e
    ) {
      // Handle error
      logging.debugPrint(
        'Error getting address: $e',
      );
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      setState(
        () {
          currentUser = User(
            username:
                currentUser!.username,
            email:
                currentUser!.email,
            password:
                currentUser!.password,
            type:
                UserType.business,
            businessName:
                _businessNameController.text,
            businessDescription:
                _businessDescriptionController.text,
            businessAddress:
                _businessAddressController.text,
            businessPhone:
                _businessPhoneController.text,
            businessEmail:
                _businessEmailController.text,
            openingTime:
                _openingTime,
            closingTime:
                _closingTime,
            businessLocation:
                _selectedLocation,
          );
          _isEditing =
              false;
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Business information updated successfully',
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(
              context,
            ).colorScheme.inversePrimary,
        title: const Text(
          'Account',
        ),
        actions: [
          if (currentUser?.type ==
              UserType.business)
            IconButton(
              icon: Icon(
                _isEditing
                    ? Icons.save
                    : Icons.edit,
              ),
              onPressed: () {
                if (_isEditing) {
                  _saveChanges();
                } else {
                  setState(
                    () {
                      _isEditing =
                          true;
                    },
                  );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius:
                  50,
              child: Icon(
                Icons.person,
                size:
                    50,
              ),
            ),
            const SizedBox(
              height:
                  16,
            ),
            Text(
              currentUser?.username ??
                  'User',
              style: const TextStyle(
                fontSize:
                    24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            Text(
              currentUser?.email ??
                  'email@example.com',
              style: const TextStyle(
                fontSize:
                    16,
                color:
                    Colors.grey,
              ),
            ),
            const SizedBox(
              height:
                  32,
            ),
            if (currentUser?.type ==
                UserType.business) ...[
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height:
                    16,
              ),
              Form(
                key:
                    _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller:
                          _businessNameController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Name',
                        border:
                            OutlineInputBorder(),
                      ),
                      enabled:
                          _isEditing,
                      validator: (
                        value,
                      ) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    TextFormField(
                      controller:
                          _businessDescriptionController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Description',
                        border:
                            OutlineInputBorder(),
                      ),
                      maxLines:
                          3,
                      enabled:
                          _isEditing,
                      validator: (
                        value,
                      ) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return 'Please enter business description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    TextFormField(
                      controller:
                          _businessAddressController,
                      decoration: InputDecoration(
                        labelText:
                            'Business Address',
                        border:
                            const OutlineInputBorder(),
                        suffixIcon:
                            _isEditing
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.location_on,
                                  ),
                                  onPressed:
                                      () => _selectLocation(
                                        context,
                                      ),
                                )
                                : null,
                      ),
                      enabled:
                          _isEditing,
                      maxLines:
                          2,
                      validator: (
                        value,
                      ) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return 'Please enter business address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly:
                                true,
                            decoration: InputDecoration(
                              labelText:
                                  'Opening Time',
                              border:
                                  const OutlineInputBorder(),
                              suffixIcon:
                                  _isEditing
                                      ? IconButton(
                                        icon: const Icon(
                                          Icons.access_time,
                                        ),
                                        onPressed:
                                            () => _selectTime(
                                              context,
                                              true,
                                            ),
                                      )
                                      : null,
                            ),
                            controller: TextEditingController(
                              text:
                                  _openingTime?.format(
                                    context,
                                  ) ??
                                  '',
                            ),
                            enabled:
                                _isEditing,
                          ),
                        ),
                        const SizedBox(
                          width:
                              16,
                        ),
                        Expanded(
                          child: TextFormField(
                            readOnly:
                                true,
                            decoration: InputDecoration(
                              labelText:
                                  'Closing Time',
                              border:
                                  const OutlineInputBorder(),
                              suffixIcon:
                                  _isEditing
                                      ? IconButton(
                                        icon: const Icon(
                                          Icons.access_time,
                                        ),
                                        onPressed:
                                            () => _selectTime(
                                              context,
                                              false,
                                            ),
                                      )
                                      : null,
                            ),
                            controller: TextEditingController(
                              text:
                                  _closingTime?.format(
                                    context,
                                  ) ??
                                  '',
                            ),
                            enabled:
                                _isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    TextFormField(
                      controller:
                          _businessPhoneController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Phone',
                        border:
                            OutlineInputBorder(),
                      ),
                      enabled:
                          _isEditing,
                      keyboardType:
                          TextInputType.phone,
                      validator: (
                        value,
                      ) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return 'Please enter business phone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    TextFormField(
                      controller:
                          _businessEmailController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Email',
                        border:
                            OutlineInputBorder(),
                      ),
                      enabled:
                          _isEditing,
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (
                        value,
                      ) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return 'Please enter business email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(
              height:
                  32,
            ),
            SizedBox(
              width:
                  double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => _logout(
                      context,
                    ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical:
                        16,
                  ),
                  backgroundColor:
                      Colors.red,
                  foregroundColor:
                      Colors.white,
                ),
                child: const Text(
                  'Logout',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    super.dispose();
  }
}
