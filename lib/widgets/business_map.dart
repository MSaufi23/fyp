import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import '../main.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../models/menu_item.dart';

class BusinessMap
    extends
        StatefulWidget {
  final List<
    Map<
      String,
      dynamic
    >
  >
  businessList;
  final LatLng? userLocation;
  final List<
    User
  >?
  businesses;
  final List<
    LatLng
  >
  routePoints;
  final double? routeDistance;
  final int? routeDuration;
  final String? routeDestination;
  final VoidCallback? onClearRoute;
  final Function(
    User,
  )?
  onGetDirections;

  const BusinessMap({
    super.key,
    required this.businessList,
    this.userLocation,
    this.businesses,
    this.routePoints =
        const [],
    this.routeDistance,
    this.routeDuration,
    this.routeDestination,
    this.onClearRoute,
    this.onGetDirections,
  });

  @override
  State<
    BusinessMap
  >
  createState() =>
      _BusinessMapState();
}

class _BusinessMapState
    extends
        State<
          BusinessMap
        > {
  final MapController _mapController =
      MapController();
  LatLng _center = const LatLng(
    2.1896,
    102.2501,
  );
  double _zoom =
      15.0;
  LatLng? _userLocation;
  bool _locating =
      false;

  @override
  void initState() {
    super.initState();
    _userLocation =
        widget.userLocation;
    if (_userLocation !=
        null) {
      _center =
          _userLocation!;
      _zoom =
          17.0;
    }
  }

  Future<
    void
  >
  _getCurrentLocation() async {
    setState(
      () {
        _locating =
            true;
      },
    );
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
        if (permission ==
            LocationPermission.denied) {
          setState(
            () =>
                _locating =
                    false,
          );
          return;
        }
      }
      if (permission ==
          LocationPermission.deniedForever) {
        setState(
          () =>
              _locating =
                  false,
        );
        return;
      }
      final position =
          await Geolocator.getCurrentPosition();
      setState(
        () {
          _userLocation = LatLng(
            position.latitude,
            position.longitude,
          );
          _center =
              _userLocation!;
          _zoom =
              17.0;
          _locating =
              false;
        },
      );
      _mapController.move(
        _userLocation!,
        _zoom,
      );
    } catch (
      e
    ) {
      setState(
        () =>
            _locating =
                false,
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

  void _zoomIn() {
    setState(
      () {
        _zoom +=
            1;
      },
    );
    _mapController.move(
      _center,
      _zoom,
    );
  }

  void _zoomOut() {
    setState(
      () {
        _zoom -=
            1;
      },
    );
    _mapController.move(
      _center,
      _zoom,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    List<
      Marker
    >
    markers =
        widget.businessList.asMap().entries.map(
          (
            entry,
          ) {
            final index =
                entry.key;
            final business =
                entry.value;
            final LatLng location = LatLng(
              business['latitude'],
              business['longitude'],
            );

            // Get corresponding User object for profile picture and advertisement info
            User? userBusiness;
            if (widget.businesses !=
                    null &&
                index <
                    widget.businesses!.length) {
              userBusiness =
                  widget.businesses![index];
            }

            return Marker(
              width:
                  80.0,
              height:
                  80.0,
              point:
                  location,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context:
                        context,
                    builder:
                        (
                          context,
                        ) => AlertDialog(
                          title: Row(
                            children: [
                              // Profile picture/emoji
                              Container(
                                width:
                                    40,
                                height:
                                    40,
                                decoration: BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  color:
                                      Colors.grey.shade100,
                                ),
                                child:
                                    userBusiness?.profilePictureUrl !=
                                            null
                                        ? ClipOval(
                                          child: Image.network(
                                            userBusiness!.profilePictureUrl!,
                                            width:
                                                40,
                                            height:
                                                40,
                                            fit:
                                                BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Center(
                                                child: Text(
                                                  userBusiness?.profileEmoji ??
                                                      '🏢',
                                                  style: const TextStyle(
                                                    fontSize:
                                                        20,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Center(
                                          child: Text(
                                            userBusiness?.profileEmoji ??
                                                '🏢',
                                            style: const TextStyle(
                                              fontSize:
                                                  20,
                                            ),
                                          ),
                                        ),
                              ),
                              const SizedBox(
                                width:
                                    12,
                              ),
                              Expanded(
                                child: Text(
                                  business['name'],
                                ),
                              ),
                              // Advertisement indicator
                              if (userBusiness?.advertisementImageUrl !=
                                      null ||
                                  userBusiness?.advertisementTitle !=
                                      null ||
                                  userBusiness?.advertisementDescription !=
                                      null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        6,
                                    vertical:
                                        2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange,
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                  ),
                                  child: const Text(
                                    'AD',
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          10,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Advertisement section
                                if (userBusiness?.advertisementTitle !=
                                        null ||
                                    userBusiness?.advertisementDescription !=
                                        null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
                                      border: Border.all(
                                        color:
                                            Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.campaign,
                                              color:
                                                  Colors.blue,
                                              size:
                                                  16,
                                            ),
                                            const SizedBox(
                                              width:
                                                  4,
                                            ),
                                            const Text(
                                              'Advertisement',
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (userBusiness?.advertisementTitle !=
                                            null) ...[
                                          const SizedBox(
                                            height:
                                                4,
                                          ),
                                          Text(
                                            userBusiness!.advertisementTitle!,
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        if (userBusiness?.advertisementDescription !=
                                            null) ...[
                                          const SizedBox(
                                            height:
                                                4,
                                          ),
                                          Text(
                                            userBusiness!.advertisementDescription!,
                                            style: const TextStyle(
                                              fontSize:
                                                  12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height:
                                        16,
                                  ),
                                ],

                                // Business information
                                if (business['description'] !=
                                    null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom:
                                          8.0,
                                    ),
                                    child: Text(
                                      business['description'],
                                    ),
                                  ),
                                if (business['address'] !=
                                    null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      Expanded(
                                        child: Text(
                                          business['address'] ??
                                              '',
                                        ),
                                      ),
                                    ],
                                  ),
                                if (business['openingTime'] !=
                                        null &&
                                    business['closingTime'] !=
                                        null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      Text(
                                        '${business['openingTime']} - ${business['closingTime']}',
                                      ),
                                    ],
                                  ),
                                if (business['phone'] !=
                                    null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      Text(
                                        business['phone'] ??
                                            '',
                                      ),
                                    ],
                                  ),
                                if (business['email'] !=
                                    null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      Text(
                                        business['email'] ??
                                            '',
                                      ),
                                    ],
                                  ),
                                if (business['distance'] !=
                                    null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_walk,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      Text(
                                        '${_formatDistance(business['distance'])} away',
                                      ),
                                    ],
                                  ),

                                const SizedBox(
                                  height:
                                      16,
                                ),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (widget.onGetDirections !=
                                                  null &&
                                              userBusiness !=
                                                  null) {
                                            Navigator.pop(
                                              context,
                                            );
                                            widget.onGetDirections!(
                                              userBusiness!,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.directions,
                                          size:
                                              16,
                                        ),
                                        label: const Text(
                                          'Directions',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical:
                                                8,
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
                                          showDialog(
                                            context:
                                                context,
                                            builder:
                                                (
                                                  context,
                                                ) => _BusinessReviewsDialog(
                                                  businessUsername:
                                                      business['username'],
                                                  businessName:
                                                      business['name'],
                                                ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.star,
                                          size:
                                              16,
                                        ),
                                        label: const Text(
                                          'Reviews',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical:
                                                8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height:
                                      16,
                                ),

                                // Menu section
                                const Text(
                                  'Menu',
                                  style: TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height:
                                      8,
                                ),
                                FutureBuilder<
                                  List<
                                    MenuItem
                                  >
                                >(
                                  future: DatabaseService().getMenuItems(
                                    business['username'],
                                  ),
                                  builder: (
                                    context,
                                    snapshot,
                                  ) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            16.0,
                                          ),
                                          child:
                                              CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Error loading menu: \\${snapshot.error}',
                                      );
                                    }

                                    final menu =
                                        snapshot.data;
                                    if (menu ==
                                            null ||
                                        menu.isEmpty) {
                                      return const Text(
                                        'No menu items available.',
                                      );
                                    }

                                    return Column(
                                      children:
                                          menu
                                              .take(
                                                3,
                                              )
                                              .map(
                                                (
                                                  item,
                                                ) => Card(
                                                  margin: const EdgeInsets.symmetric(
                                                    vertical:
                                                        2,
                                                  ),
                                                  child: ListTile(
                                                    leading:
                                                        item.imageUrl !=
                                                                    null &&
                                                                item.imageUrl!.isNotEmpty
                                                            ? Image.network(
                                                              item.imageUrl!,
                                                              width:
                                                                  40,
                                                              height:
                                                                  40,
                                                              fit:
                                                                  BoxFit.cover,
                                                            )
                                                            : const Icon(
                                                              Icons.fastfood,
                                                              size:
                                                                  24,
                                                            ),
                                                    title: Text(
                                                      item.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines:
                                                          1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                      item.description,
                                                      maxLines:
                                                          2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    trailing: Text(
                                                      'RM${item.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    );
                                  },
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
                                'Close',
                              ),
                            ),
                          ],
                        ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Colors.white,
                    shape:
                        BoxShape.circle,
                    border: Border.all(
                      color:
                          Colors.blue,
                      width:
                          2,
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
                  child: Stack(
                    children: [
                      // Profile picture/emoji
                      Center(
                        child:
                            userBusiness?.profilePictureUrl !=
                                    null
                                ? ClipOval(
                                  child: Image.network(
                                    userBusiness!.profilePictureUrl!,
                                    width:
                                        60,
                                    height:
                                        60,
                                    fit:
                                        BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return Text(
                                        userBusiness?.profileEmoji ??
                                            '🏢',
                                        style: const TextStyle(
                                          fontSize:
                                              30,
                                        ),
                                      );
                                    },
                                  ),
                                )
                                : Text(
                                  userBusiness?.profileEmoji ??
                                      '🏢',
                                  style: const TextStyle(
                                    fontSize:
                                        30,
                                  ),
                                ),
                      ),
                      // Advertisement indicator
                      if (userBusiness?.advertisementImageUrl !=
                              null ||
                          userBusiness?.advertisementTitle !=
                              null ||
                          userBusiness?.advertisementDescription !=
                              null)
                        Positioned(
                          top:
                              0,
                          right:
                              0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  4,
                              vertical:
                                  2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.orange,
                              borderRadius: BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: const Text(
                              'AD',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    8,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ).toList();

    // Add user location marker if available
    if (widget.userLocation !=
        null) {
      markers.add(
        Marker(
          width:
              60.0,
          height:
              60.0,
          point:
              widget.userLocation!,
          child: const Icon(
            Icons.my_location,
            color:
                Colors.blue,
            size:
                36,
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController:
              _mapController,
          options: MapOptions(
            initialCenter:
                _center,
            initialZoom:
                _zoom,
            onPositionChanged: (
              pos,
              _,
            ) {
              setState(
                () {
                  _center =
                      pos.center;
                  _zoom =
                      pos.zoom;
                },
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
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        widget.routePoints,
                    color:
                        Colors.blue,
                    strokeWidth:
                        4.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers:
                  markers,
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
        Positioned(
          bottom:
              16,
          right:
              16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag:
                    'zoom_in',
                onPressed:
                    _zoomIn,
                mini:
                    true,
                child: const Icon(
                  Icons.add,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              FloatingActionButton(
                heroTag:
                    'zoom_out',
                onPressed:
                    _zoomOut,
                mini:
                    true,
                child: const Icon(
                  Icons.remove,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              FloatingActionButton(
                heroTag:
                    'my_location',
                onPressed:
                    _locating
                        ? null
                        : _getCurrentLocation,
                mini:
                    true,
                child:
                    _locating
                        ? const SizedBox(
                          width:
                              20,
                          height:
                              20,
                          child: CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                        : const Icon(
                          Icons.my_location,
                        ),
              ),

              // Route control button
              if (widget.routePoints.isNotEmpty) ...[
                const SizedBox(
                  height:
                      8,
                ),
                FloatingActionButton(
                  heroTag:
                      'clear_route',
                  onPressed:
                      widget.onClearRoute,
                  backgroundColor:
                      Colors.red,
                  mini:
                      true,
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
      ],
    );
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
    // Replace with your current user logic
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
    // Refresh reviews
    setState(
      () {},
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text(
        '${widget.businessName} Reviews',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
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
                      'No reviews yet.',
                    ),
                  if (reviews.isNotEmpty)
                    SizedBox(
                      height:
                          120,
                      child: ListView.separated(
                        shrinkWrap:
                            true,
                        itemCount:
                            reviews.length,
                        separatorBuilder:
                            (
                              context,
                              i,
                            ) =>
                                const Divider(),
                        itemBuilder: (
                          context,
                          i,
                        ) {
                          final r = reviews[i];
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
                  ElevatedButton(
                    onPressed:
                        _submitting
                            ? null
                            : _submitReview,
                    child:
                        _submitting
                            ? const SizedBox(
                              width:
                                  20,
                              height:
                                  20,
                              child: CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                            : const Text(
                              'Submit',
                            ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              () => Navigator.pop(
                context,
              ),
          child: const Text(
            'Close',
          ),
        ),
      ],
    );
  }
}
