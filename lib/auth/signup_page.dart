import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'map_picker_dialog.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class SignupPage
    extends
        StatefulWidget {
  const SignupPage({
    super.key,
  });

  @override
  State<
    SignupPage
  >
  createState() =>
      _SignupPageState();
}

class _SignupPageState
    extends
        State<
          SignupPage
        > {
  final _formKey =
      GlobalKey<
        FormState
      >();
  final _usernameController =
      TextEditingController();
  final _emailController =
      TextEditingController();
  final _passwordController =
      TextEditingController();
  final _confirmPasswordController =
      TextEditingController();
  final _businessNameController =
      TextEditingController();
  final _businessDescriptionController =
      TextEditingController();
  final _businessAddressController =
      TextEditingController();
  final _businessPhoneController =
      TextEditingController();
  final _businessEmailController =
      TextEditingController();
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  LatLng? _selectedLocation;
  bool _isLoading =
      false;
  UserType _selectedUserType =
      UserType.user;
  bool _isLoadingAddress =
      false;
  bool _isFirebaseInitialized =
      false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<
    void
  >
  _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      if (mounted) {
        setState(
          () {
            _isFirebaseInitialized =
                true;
          },
        );
      }
    } catch (
      e
    ) {
      print(
        'Error initializing Firebase: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error initializing app: $e',
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
  _selectTime(
    BuildContext context,
    bool isOpeningTime,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context:
          context,
      initialTime:
          isOpeningTime
              ? (_openingTime ??
                  TimeOfDay.now())
              : (_closingTime ??
                  TimeOfDay.now()),
    );
    if (picked !=
        null) {
      setState(
        () {
          if (isOpeningTime) {
            _openingTime =
                picked;
            // Validate closing time if it exists
            if (_closingTime !=
                    null &&
                _closingTime!.hour <
                    picked.hour) {
              _closingTime =
                  null;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Closing time must be after opening time',
                  ),
                  backgroundColor:
                      Colors.red,
                ),
              );
            }
          } else {
            // Validate that closing time is after opening time
            if (_openingTime !=
                    null &&
                picked.hour <
                    _openingTime!.hour) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Closing time must be after opening time',
                  ),
                  backgroundColor:
                      Colors.red,
                ),
              );
              return;
            }
            _closingTime =
                picked;
          }
        },
      );
    }
  }

  Future<
    String
  >
  _getAddressFromLatLng(
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
        Placemark place =
            placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}';
      }
    } catch (
      e
    ) {
      print(
        'Error getting address: $e',
      );
    }
    return '${location.latitude}, ${location.longitude}';
  }

  Future<
    void
  >
  _showMapPicker() async {
    print(
      'SignupPage: Starting map picker',
    );
    if (!mounted) {
      print(
        'SignupPage: Not mounted, returning',
      );
      return;
    }

    // Check location permission
    LocationPermission permission =
        await Geolocator.checkPermission();
    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to select a business location',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      final LatLng initialLocation =
          _selectedLocation ??
          LatLng(
            2.1896,
            102.2501,
          );
      print(
        'SignupPage: Initial location: ${initialLocation.latitude}, ${initialLocation.longitude}',
      );

      final result = await showDialog<
        LatLng
      >(
        context:
            context,
        barrierDismissible:
            false,
        builder:
            (
              BuildContext dialogContext,
            ) => WillPopScope(
              onWillPop:
                  () async =>
                      false,
              child: MapPickerDialog(
                initialLocation:
                    initialLocation,
                onLocationSelected: (
                  location,
                ) {
                  print(
                    'SignupPage: Location selected in dialog: ${location.latitude}, ${location.longitude}',
                  );
                  // Don't pop here, let the dialog handle it
                },
              ),
            ),
      );

      print(
        'SignupPage: Dialog returned with result: ${result?.latitude}, ${result?.longitude}',
      );

      if (!mounted) {
        print(
          'SignupPage: Not mounted after dialog, returning',
        );
        return;
      }

      if (result !=
          null) {
        print(
          'SignupPage: Updating location',
        );
        // Update the location first
        setState(
          () {
            _selectedLocation =
                result;
          },
        );

        // Then try to get the address
        print(
          'SignupPage: Getting address for location',
        );
        setState(
          () {
            _isLoadingAddress =
                true;
          },
        );

        try {
          final address = await _getAddressFromLatLng(
            result,
          );
          print(
            'SignupPage: Got address: $address',
          );
          if (mounted) {
            setState(
              () {
                _businessAddressController.text = address;
                _isLoadingAddress =
                    false;
              },
            );
          }
        } catch (
          e
        ) {
          print(
            'SignupPage: Error getting address: $e',
          );
          if (mounted) {
            setState(
              () {
                _businessAddressController.text = '${result.latitude}, ${result.longitude}';
                _isLoadingAddress =
                    false;
              },
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not get address details, using coordinates instead',
                ),
                backgroundColor:
                    Colors.orange,
              ),
            );
          }
        }
      } else {
        print(
          'SignupPage: No result from dialog',
        );
      }
    } catch (
      e
    ) {
      print(
        'SignupPage: Error in _showMapPicker: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting location: $e',
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
  _signup() async {
    if (!_isFirebaseInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait while the app initializes',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(
        () {
          _isLoading =
              true;
        },
      );

      try {
        final user = User(
          username:
              _usernameController.text,
          email:
              _emailController.text,
          password:
              _passwordController.text,
          type:
              _selectedUserType ==
                      UserType.business
                  ? UserType.business
                  : UserType.user,
          businessName:
              _selectedUserType ==
                      UserType.business
                  ? _businessNameController.text
                  : null,
          businessDescription:
              _selectedUserType ==
                      UserType.business
                  ? _businessDescriptionController.text
                  : null,
          businessAddress:
              _selectedUserType ==
                      UserType.business
                  ? _businessAddressController.text
                  : null,
          businessPhone:
              _selectedUserType ==
                      UserType.business
                  ? _businessPhoneController.text
                  : null,
          businessEmail:
              _selectedUserType ==
                      UserType.business
                  ? _businessEmailController.text
                  : null,
          openingTime:
              _selectedUserType ==
                      UserType.business
                  ? _openingTime
                  : null,
          closingTime:
              _selectedUserType ==
                      UserType.business
                  ? _closingTime
                  : null,
          businessLocation:
              _selectedUserType ==
                      UserType.business
                  ? _selectedLocation
                  : null,
        );

        final databaseService =
            DatabaseService();
        await databaseService.createUser(
          user,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully!',
            ),
            backgroundColor:
                Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      } catch (
        e
      ) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating account: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(
            () {
              _isLoading =
                  false;
            },
          );
        }
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            16.0,
          ),
          child: Form(
            key:
                _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize:
                        32,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height:
                      32,
                ),
                // User Type Selection
                const Text(
                  'Select Account Type',
                  style: TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<
                        UserType
                      >(
                        title: const Text(
                          'Normal User',
                        ),
                        value:
                            UserType.user,
                        groupValue:
                            _selectedUserType,
                        onChanged: (
                          UserType? value,
                        ) {
                          setState(
                            () {
                              _selectedUserType =
                                  value!;
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<
                        UserType
                      >(
                        title: const Text(
                          'Business Owner',
                        ),
                        value:
                            UserType.business,
                        groupValue:
                            _selectedUserType,
                        onChanged: (
                          UserType? value,
                        ) {
                          setState(
                            () {
                              _selectedUserType =
                                  value!;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      16,
                ),
                // Common fields for all users
                TextFormField(
                  controller:
                      _usernameController,
                  decoration: const InputDecoration(
                    labelText:
                        'Username',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.person,
                    ),
                  ),
                  validator: (
                    value,
                  ) {
                    if (value ==
                            null ||
                        value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length <
                        3) {
                      return 'Username must be at least 3 characters';
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
                      _emailController,
                  decoration: const InputDecoration(
                    labelText:
                        'Email',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email,
                    ),
                  ),
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: (
                    value,
                  ) {
                    if (value ==
                            null ||
                        value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains(
                          '@',
                        ) ||
                        !value.contains(
                          '.',
                        )) {
                      return 'Please enter a valid email';
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
                      _passwordController,
                  decoration: const InputDecoration(
                    labelText:
                        'Password',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.lock,
                    ),
                  ),
                  obscureText:
                      true,
                  validator: (
                    value,
                  ) {
                    if (value ==
                            null ||
                        value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length <
                        6) {
                      return 'Password must be at least 6 characters';
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
                      _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText:
                        'Confirm Password',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                    ),
                  ),
                  obscureText:
                      true,
                  validator: (
                    value,
                  ) {
                    if (value ==
                            null ||
                        value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value !=
                        _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                // Business owner specific fields
                if (_selectedUserType ==
                    UserType.business) ...[
                  const SizedBox(
                    height:
                        24,
                  ),
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
                  TextFormField(
                    controller:
                        _businessNameController,
                    decoration: const InputDecoration(
                      labelText:
                          'Business Name',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.business,
                      ),
                    ),
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter your business name';
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
                      prefixIcon: Icon(
                        Icons.description,
                      ),
                    ),
                    maxLines:
                        3,
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter a business description';
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
                      prefixIcon: const Icon(
                        Icons.location_on,
                      ),
                      suffixIcon:
                          _isLoadingAddress
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
                              : IconButton(
                                icon: const Icon(
                                  Icons.map,
                                ),
                                onPressed:
                                    _showMapPicker,
                              ),
                    ),
                    readOnly:
                        true,
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please select your business location';
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
                        _businessPhoneController,
                    decoration: const InputDecoration(
                      labelText:
                          'Business Phone Number',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.phone,
                      ),
                    ),
                    keyboardType:
                        TextInputType.phone,
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter your business phone number';
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
                      prefixIcon: Icon(
                        Icons.email,
                      ),
                    ),
                    keyboardType:
                        TextInputType.emailAddress,
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter your business email';
                      }
                      if (!value.contains(
                            '@',
                          ) ||
                          !value.contains(
                            '.',
                          )) {
                        return 'Please enter a valid email';
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
                        child: InkWell(
                          onTap:
                              () => _selectTime(
                                context,
                                true,
                              ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText:
                                  'Opening Time',
                              border:
                                  OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.access_time,
                              ),
                            ),
                            child: Text(
                              _openingTime?.format(
                                    context,
                                  ) ??
                                  'Select Time',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width:
                            16,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap:
                              () => _selectTime(
                                context,
                                false,
                              ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText:
                                  'Closing Time',
                              border:
                                  OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.access_time,
                              ),
                            ),
                            child: Text(
                              _closingTime?.format(
                                    context,
                                  ) ??
                                  'Select Time',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(
                  height:
                      24,
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical:
                          16,
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                            'Sign Up',
                          ),
                ),
                const SizedBox(
                  height:
                      16,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    super.dispose();
  }
}
