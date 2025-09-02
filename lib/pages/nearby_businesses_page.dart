import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/menu_item.dart';
import '../widgets/business_map.dart';
import '../widgets/advertisement_carousel.dart';
import '../models/review.dart';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as logging;

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

class NearbyBusinessesPage
    extends
        StatefulWidget {
  final bool onlyShowCurrentBusiness;
  const NearbyBusinessesPage({
    super.key,
    this.onlyShowCurrentBusiness =
        false,
  });

  @override
  State<
    NearbyBusinessesPage
  >
  createState() =>
      _NearbyBusinessesPageState();
}

class _NearbyBusinessesPageState
    extends
        State<
          NearbyBusinessesPage
        > {
  List<
    User
  >
  _businesses =
      [];
  bool _isLoading =
      true;
  Position? _currentPosition;
  String? _errorMessage;

  // Search functionality
  // bool _isSearching = false;
  // String _searchQuery = '';
  // List<MapSearchResult> _searchResults = [];
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
      setState(
        () {
          _isLoading =
              true;
          _errorMessage =
              null;
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
          setState(
            () {
              _isLoading =
                  false;
              _errorMessage =
                  'Location permission denied. Please enable location services.';
            },
          );
          return;
        }
      }

      // Get current position
      final position =
          await Geolocator.getCurrentPosition();
      setState(
        () {
          _currentPosition =
              position;
        },
      );

      // Fetch businesses
      final businesses =
          await DatabaseService().getAllBusinesses();

      // Calculate distances and sort by distance
      final sortedBusinesses =
          businesses
              .where(
                (
                  b,
                ) =>
                    b.businessLocation !=
                    null,
              )
              .toList()
            ..sort(
              (
                a,
                b,
              ) {
                final distanceA = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  a.businessLocation!.latitude,
                  a.businessLocation!.longitude,
                );
                final distanceB = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  b.businessLocation!.latitude,
                  b.businessLocation!.longitude,
                );
                return distanceA.compareTo(
                  distanceB,
                );
              },
            );

      // Filter to only current business if needed
      List<
        User
      >
      filteredBusinesses =
          sortedBusinesses;
      if (widget.onlyShowCurrentBusiness &&
          currentUser !=
              null) {
        filteredBusinesses =
            sortedBusinesses
                .where(
                  (
                    b,
                  ) =>
                      b.username ==
                      currentUser!.username,
                )
                .toList();
      }

      setState(
        () {
          _businesses =
              filteredBusinesses;
          _isLoading =
              false;
        },
      );
    } catch (
      e
    ) {
      setState(
        () {
          _isLoading =
              false;
          _errorMessage =
              'Error loading nearby businesses: $e';
        },
      );
    }
  }

  String _formatDistance(
    double meters,
  ) {
    if (meters <
        1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // Search functionality
  // Future<void> _searchLocation(String query) async {}

  Future<
    void
  >
  _showRouteToBusiness(
    User business,
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

    if (business.businessLocation ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Business location not available.',
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
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${business.businessLocation!.longitude},${business.businessLocation!.latitude}'
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
                  business.businessName ??
                  'Business';
            },
          );

          // Show route details dialog
          if (!mounted) return;
          showDialog(
            context:
                context,
            builder:
                (
                  context,
                ) => AlertDialog(
                  title: Text(
                    'Route to ${business.businessName ?? 'Business'}',
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
                                  business,
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
    User business,
    String app,
  ) async {
    if (business.businessLocation ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Business location not available.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
      return;
    }

    String url;
    if (app ==
        'google') {
      url =
          'https://www.google.com/maps/dir/?api=1'
          '&destination=${business.businessLocation!.latitude},${business.businessLocation!.longitude}'
          '&travelmode=driving';
    } else {
      url =
          'https://waze.com/ul?ll=${business.businessLocation!.latitude},${business.businessLocation!.longitude}&navigate=yes';
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

  // Widget _buildSearchResult(MapSearchResult result) {
  //   return ListTile(
  //     leading: const Icon(Icons.location_on),
  //     title: Text(result.name),
  //     subtitle: Text(
  //       result.fullAddress,
  //       maxLines: 2,
  //       overflow: TextOverflow.ellipsis,
  //     ),
  //     onTap: () {
  //       // setState(() {
  //       //   _searchQuery = '';
  //       //   _searchResults = [];
  //       // });
  //       _showRouteToBusiness(
  //         _businesses[0],
  //       );
  //     },
  //   );
  // }

  // Future<void> _showRouteDetails(MapSearchResult result) async {
  //   // Old function - no longer used
  // }

  void _showBusinessDetails(
    User business,
  ) {
    showModalBottomSheet(
      context:
          context,
      isScrollControlled:
          true,
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
          ) => DraggableScrollableSheet(
            initialChildSize:
                0.7,
            minChildSize:
                0.5,
            maxChildSize:
                0.95,
            expand:
                false,
            builder:
                (
                  context,
                  scrollController,
                ) => _buildBusinessDetailsSheet(
                  business,
                ),
          ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage !=
        null) {
      return Scaffold(
        body: Center(
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
                _errorMessage!,
              ),
              const SizedBox(
                height:
                    16,
              ),
              ElevatedButton(
                onPressed:
                    _initializeLocation,
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_businesses.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No businesses found nearby',
          ),
        ),
      );
    }

    // Convert User objects to Map format for BusinessMap
    final businessList =
        _businesses.map(
          (
            business,
          ) {
            double? distance;
            if (_currentPosition !=
                    null &&
                business.businessLocation !=
                    null) {
              distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                business.businessLocation!.latitude,
                business.businessLocation!.longitude,
              );
            }
            return {
              'username':
                  business.username,
              'name':
                  business.businessName ??
                  'Unknown Business',
              'description':
                  business.businessDescription ??
                  'No description available',
              'latitude':
                  business.businessLocation!.latitude,
              'longitude':
                  business.businessLocation!.longitude,
              'address':
                  business.businessAddress,
              'phone':
                  business.businessPhone,
              'email':
                  business.businessEmail,
              'openingTime':
                  business.openingTime !=
                          null
                      ? business.openingTime!.format(
                        context,
                      )
                      : null,
              'closingTime':
                  business.closingTime !=
                          null
                      ? business.closingTime!.format(
                        context,
                      )
                      : null,
              'distance':
                  distance,
            };
          },
        ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Businesses',
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Advertisement Carousel
              if (!(widget.onlyShowCurrentBusiness)) ...[
                Builder(
                  builder: (
                    context,
                  ) {
                    final businessesWithAds =
                        _businesses
                            .where(
                              (
                                business,
                              ) =>
                                  business.advertisementImageUrl !=
                                      null ||
                                  business.advertisementTitle !=
                                      null ||
                                  business.advertisementDescription !=
                                      null,
                            )
                            .toList();

                    if (businessesWithAds.isNotEmpty) {
                      return AdvertisementCarousel(
                        businessesWithAds:
                            businessesWithAds,
                        onBusinessTap: (
                          business,
                        ) {
                          // Show business details dialog
                          _showBusinessDetails(
                            business,
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              // Business Map
              Expanded(
                child: BusinessMap(
                  businessList:
                      businessList,
                  userLocation:
                      _currentPosition !=
                              null
                          ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                          : null,
                  businesses:
                      _businesses,
                  routePoints:
                      _routePoints,
                  routeDistance:
                      _routeDistance,
                  routeDuration:
                      _routeDuration,
                  routeDestination:
                      _routeDestination,
                  onClearRoute:
                      _clearRoute,
                  onGetDirections:
                      _showRouteToBusiness,
                ),
              ),
            ],
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
                // Route Information Panel
                if (_routePoints.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(
                      top:
                          8,
                    ),
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
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                if (_routeDistance !=
                                        null &&
                                    _routeDuration !=
                                        null)
                                  Text(
                                    '${_routeDistance!.toStringAsFixed(1)} km • ${_routeDuration} min',
                                    style: const TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors.grey,
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

                if (_isLoadingRoute)
                  const Padding(
                    padding: EdgeInsets.all(
                      8.0,
                    ),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsSheet(
    User business,
  ) {
    return FutureBuilder<
      List<
        MenuItem
      >
    >(
      future: DatabaseService().getMenuItems(
        business.username,
      ),
      builder: (
        context,
        snapshot,
      ) {
        final menu =
            snapshot.data;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Handle bar for dragging
                Center(
                  child: Container(
                    width:
                        40,
                    height:
                        4,
                    margin: const EdgeInsets.only(
                      bottom:
                          16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                        2,
                      ),
                    ),
                  ),
                ),
                Text(
                  business.businessName ??
                      'Unnamed Business',
                  style: const TextStyle(
                    fontSize:
                        24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height:
                      16,
                ),
                if (business.businessDescription !=
                    null) ...[
                  Text(
                    business.businessDescription!,
                    style: const TextStyle(
                      fontSize:
                          16,
                    ),
                  ),
                  const SizedBox(
                    height:
                        16,
                  ),
                ],
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
                        business.businessAddress ??
                            'No address',
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
                      Icons.access_time,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      business.openingTime !=
                                  null &&
                              business.closingTime !=
                                  null
                          ? '${business.openingTime!.format(context)} - ${business.closingTime!.format(context)}'
                          : 'Hours not available',
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
                      Icons.phone,
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Text(
                      business.businessPhone ??
                          'No phone number',
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
                      business.businessEmail ??
                          'No email',
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRouteToBusiness(
                            business,
                          );
                        },
                        icon: const Icon(
                          Icons.directions,
                        ),
                        label: const Text(
                          'Get Directions',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical:
                                12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                          _showBusinessReviews(
                            business,
                          );
                        },
                        icon: const Icon(
                          Icons.star,
                        ),
                        label: const Text(
                          'Reviews',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical:
                                12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      24,
                ),
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                if (snapshot.hasError)
                  Text(
                    'Error loading menu: ${snapshot.error}',
                  ),
                if (menu !=
                        null &&
                    menu.isEmpty)
                  const Text(
                    'No menu items available.',
                  ),
                if (menu !=
                        null &&
                    menu.isNotEmpty)
                  ListView.builder(
                    shrinkWrap:
                        true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        menu.length,
                    itemBuilder: (
                      context,
                      idx,
                    ) {
                      final item =
                          menu[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical:
                              6,
                        ),
                        child: ListTile(
                          leading:
                              item.imageUrl !=
                                          null &&
                                      item.imageUrl!.isNotEmpty
                                  ? Image.network(
                                    item.imageUrl!,
                                    width:
                                        50,
                                    height:
                                        50,
                                    fit:
                                        BoxFit.cover,
                                  )
                                  : const Icon(
                                    Icons.fastfood,
                                    size:
                                        40,
                                  ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                          ),
                          trailing: Text(
                            'RM${item.price.toStringAsFixed(2)}',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBusinessReviews(
    User business,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => _BusinessReviewsDialog(
            businessUsername:
                business.username,
            businessName:
                business.businessName ??
                'Business',
          ),
    );
  }
}

class _BusinessReviewsDialog
    extends
        StatefulWidget {
  final String businessUsername;
  final String businessName;

  const _BusinessReviewsDialog({
    required this.businessUsername,
    required this.businessName,
  });

  @override
  State<
    _BusinessReviewsDialog
  >
  createState() =>
      _BusinessReviewsDialogState();
}

class _BusinessReviewsDialogState
    extends
        State<
          _BusinessReviewsDialog
        > {
  final _commentController =
      TextEditingController();
  int _selectedRating =
      5;
  bool _submitting =
      false;

  Future<
    void
  >
  _submitReview() async {
    setState(
      () =>
          _submitting =
              true,
    );

    final reviewerUsername =
        currentUser?.username ??
        'Anonymous';
    await DatabaseService().addBusinessReview(
      businessUsername:
          widget.businessUsername,
      reviewerUsername:
          reviewerUsername,
      rating:
          _selectedRating,
      comment:
          _commentController.text,
    );

    _commentController.clear();
    setState(
      () =>
          _submitting =
              false,
    );
    setState(
      () {},
    ); // Refresh reviews
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text(
        '${widget.businessName} Reviews',
      ),
      content: SizedBox(
        width:
            350,
        child: FutureBuilder<
          List<
            Review
          >
        >(
          future: DatabaseService().getBusinessReviews(
            widget.businessUsername,
          ),
          builder: (
            context,
            snapshot,
          ) {
            final reviews =
                snapshot.data ??
                [];
            return Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                FutureBuilder<
                  double
                >(
                  future: DatabaseService().getBusinessAverageRating(
                    widget.businessUsername,
                  ),
                  builder: (
                    context,
                    avgSnap,
                  ) {
                    final avg =
                        avgSnap.data ??
                        0.0;
                    return Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color:
                              Colors.amber,
                        ),
                        Text(
                          avg.toStringAsFixed(
                            1,
                          ),
                        ),
                        Text(
                          ' (${reviews.length} reviews)',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(),
                if (reviews.isEmpty)
                  const Text(
                    'No reviews yet',
                  )
                else
                  SizedBox(
                    height:
                        200,
                    child: ListView.builder(
                      itemCount:
                          reviews.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final r = reviews[index];
                        return ListTile(
                          leading: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: List.generate(
                              5,
                              (
                                idx,
                              ) => Icon(
                                idx <
                                        (r.rating ??
                                            0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color:
                                    Colors.amber,
                                size:
                                    18,
                              ),
                            ),
                          ),
                          title: Text(
                            r.reviewerUsername ??
                                '',
                          ),
                          subtitle: Text(
                            r.comment ??
                                '',
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                const Text(
                  'Leave a review:',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (
                      idx,
                    ) => IconButton(
                      icon: Icon(
                        idx <
                                _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color:
                            Colors.amber,
                      ),
                      onPressed:
                          () => setState(
                            () =>
                                _selectedRating =
                                    idx +
                                    1,
                          ),
                    ),
                  ),
                ),
                TextField(
                  controller:
                      _commentController,
                  decoration: const InputDecoration(
                    hintText:
                        'Write your review...',
                  ),
                  minLines:
                      1,
                  maxLines:
                      3,
                ),
                const SizedBox(
                  height:
                      8,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _submitting
                            ? null
                            : _submitReview,
                    child:
                        _submitting
                            ? const CircularProgressIndicator()
                            : const Text(
                              'Submit Review',
                            ),
                  ),
                ),
              ],
            );
          },
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
            'Close',
          ),
        ),
      ],
    );
  }
}
