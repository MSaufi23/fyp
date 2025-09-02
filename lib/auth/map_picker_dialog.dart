import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerDialog
    extends
        StatefulWidget {
  final LatLng initialLocation;
  final Function(
    LatLng,
  )
  onLocationSelected;

  const MapPickerDialog({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<
    MapPickerDialog
  >
  createState() =>
      _MapPickerDialogState();
}

class _MapPickerDialogState
    extends
        State<
          MapPickerDialog
        > {
  late MapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController =
        MapController();
    _selectedLocation =
        widget.initialLocation;
  }

  void _handleLocationSelection() {
    print(
      'MapPickerDialog: Location selected: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
    );
    // First call the callback
    widget.onLocationSelected(
      _selectedLocation,
    );
    print(
      'MapPickerDialog: Callback executed',
    );
    // Then close the dialog
    if (mounted) {
      print(
        'MapPickerDialog: Closing dialog',
      );
      Navigator.of(
        context,
      ).pop(
        _selectedLocation,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return WillPopScope(
      onWillPop: () async {
        print(
          'MapPickerDialog: WillPopScope triggered',
        );
        Navigator.of(
          context,
        ).pop();
        return false;
      },
      child: Dialog(
        child: Container(
          width:
              MediaQuery.of(
                context,
              ).size.width *
              0.9,
          height:
              MediaQuery.of(
                context,
              ).size.height *
              0.7,
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            children: [
              const Text(
                'Select Business Location',
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
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController:
                          _mapController,
                      options: MapOptions(
                        initialCenter:
                            widget.initialLocation,
                        initialZoom:
                            15,
                        onTap: (
                          _,
                          point,
                        ) {
                          print(
                            'MapPickerDialog: Map tapped at: ${point.latitude}, ${point.longitude}',
                          );
                          setState(
                            () {
                              _selectedLocation =
                                  point;
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
                        MarkerLayer(
                          markers: [
                            Marker(
                              point:
                                  _selectedLocation,
                              width:
                                  40,
                              height:
                                  40,
                              child: const Icon(
                                Icons.location_pin,
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
                      right:
                          16,
                      bottom:
                          16,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            heroTag:
                                'map_picker_zoom_in',
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom +
                                    1,
                              );
                            },
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
                                'map_picker_zoom_out',
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom -
                                    1,
                              );
                            },
                            child: const Icon(
                              Icons.remove,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height:
                    16,
              ),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).pop();
                      }
                    },
                    child: const Text(
                      'Cancel',
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  ElevatedButton(
                    onPressed:
                        _handleLocationSelection,
                    child: const Text(
                      'Select Location',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
