import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart'; // Import for currentUser
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'report_page.dart';
import '../models/review.dart';
import '../widgets/profile_picture_picker.dart';
import '../widgets/advertisement_manager.dart';

class ProfilePage
    extends
        StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<
    ProfilePage
  >
  createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends
        State<
          ProfilePage
        > {
  bool _isEditing =
      false;
  final _formKey =
      GlobalKey<
        FormState
      >();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedEmoji;
  final _databaseService =
      DatabaseService();
  final _storageService =
      StorageService();
  final _imagePicker =
      ImagePicker();
  File? _profileImage;
  File? _advertisementImage;
  String? _advertisementTitle;
  String? _advertisementDescription;
  bool _isEditingBusiness =
      false;
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;
  late TextEditingController _businessDescriptionController;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  List<
    Review
  >
  _businessReviews =
      [];

  // Emoji options for profile picture
  final List<
    String
  >
  _emojiOptions = [
    '😀',
    '😎',
    '👩‍💻',
    '👨‍💻',
    '🧑‍🎨',
    '👩‍🔬',
    '👨‍🚀',
    '🧑‍🚀',
    '👩‍🍳',
    '👨‍🍳',
    '🦸‍♂️',
    '🦸‍♀️',
    '🧑‍🏫',
    '👩‍🏫',
    '👨‍🏫',
    '🧑‍⚕️',
    '👩‍⚕️',
    '👨‍⚕️',
    '🧑‍🔧',
    '👩‍🔧',
    '👨‍🔧',
    '🧑‍🌾',
    '👩‍🌾',
    '👨‍🌾',
    '🧑‍🎤',
    '👩‍🎤',
    '👨‍🎤',
    '🧑‍✈️',
    '👩‍✈️',
    '👨‍✈️',
    '🐱',
    '🐶',
    '🦊',
    '🐻',
    '🐼',
    '🐵',
    '🦄',
    '🐸',
    '🐧',
    '🐢',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (currentUser?.type ==
        UserType.business) {
      _loadBusinessReviews();
    }
    _usernameController = TextEditingController(
      text:
          currentUser?.username,
    );
    _emailController = TextEditingController(
      text:
          currentUser?.email,
    );
    _phoneController = TextEditingController(
      text:
          currentUser?.businessPhone,
    );
    _selectedEmoji =
        currentUser?.profileEmoji; // Use profileEmoji instead of businessDescription
    if (currentUser?.type ==
        UserType.business) {
      _businessNameController = TextEditingController(
        text:
            currentUser?.businessName,
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
      _businessDescriptionController = TextEditingController(
        text:
            currentUser?.businessDescription,
      );
      _openingTime =
          currentUser?.openingTime;
      _closingTime =
          currentUser?.closingTime;

      // Initialize advertisement fields
      _advertisementTitle =
          currentUser?.advertisementTitle;
      _advertisementDescription =
          currentUser?.advertisementDescription;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source:
          ImageSource.gallery,
    );

    if (image !=
        null) {
      setState(
        () {
          _profileImage = File(
            image.path,
          );
        },
      );
    }
  }

  Future<
    void
  >
  _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? profilePictureUrl =
            currentUser?.profilePictureUrl;
        String? advertisementImageUrl =
            currentUser?.advertisementImageUrl;

        // Upload profile picture if selected
        if (_profileImage !=
            null) {
          // Delete old profile picture if exists
          if (currentUser?.profilePictureUrl !=
              null) {
            try {
              await _storageService.deleteProfilePicture(
                currentUser!.profilePictureUrl!,
              );
            } catch (
              e
            ) {
              // Ignore deletion errors
            }
          }
          // Upload new profile picture
          profilePictureUrl = await _storageService.uploadProfilePicture(
            _profileImage!,
            currentUser!.username,
          );
        }

        // Upload advertisement image if selected (for business users)
        if (currentUser?.type ==
                UserType.business &&
            _advertisementImage !=
                null) {
          // Delete old advertisement image if exists
          if (currentUser?.advertisementImageUrl !=
              null) {
            try {
              await _storageService.deleteAdvertisementImage(
                currentUser!.advertisementImageUrl!,
              );
            } catch (
              e
            ) {
              // Ignore deletion errors
            }
          }
          // Upload new advertisement image
          advertisementImageUrl = await _storageService.uploadAdvertisementImage(
            _advertisementImage!,
            currentUser!.username,
          );
        }

        // Prepare update data
        Map<
          String,
          dynamic
        >
        updateData = {
          'username':
              _usernameController.text,
          'email':
              _emailController.text,
          'profileEmoji':
              _selectedEmoji,
          'profilePictureUrl':
              profilePictureUrl,
        };

        if (currentUser?.type ==
            UserType.business) {
          updateData.addAll(
            {
              'businessPhone':
                  _phoneController.text,
              'advertisementImageUrl':
                  advertisementImageUrl,
              'advertisementTitle':
                  _advertisementTitle,
              'advertisementDescription':
                  _advertisementDescription,
            },
          );
        }

        // Update user profile in database
        await _databaseService.updateUserProfile(
          currentUser!.username,
          updateData,
        );

        // Update the currentUser object with new values
        currentUser = User(
          username:
              _usernameController.text,
          email:
              _emailController.text,
          password:
              currentUser!.password,
          type:
              currentUser!.type,
          businessName:
              currentUser!.businessName,
          businessDescription:
              currentUser!.businessDescription,
          businessAddress:
              currentUser!.businessAddress,
          businessPhone:
              currentUser!.businessPhone,
          businessEmail:
              currentUser!.businessEmail,
          openingTime:
              currentUser!.openingTime,
          closingTime:
              currentUser!.closingTime,
          businessLocation:
              currentUser!.businessLocation,
          profileEmoji:
              _selectedEmoji,
          profilePictureUrl:
              profilePictureUrl,
          advertisementImageUrl:
              advertisementImageUrl,
          advertisementTitle:
              _advertisementTitle,
          advertisementDescription:
              _advertisementDescription,
        );

        setState(
          () {
            _isEditing =
                false;
          },
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully',
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      } catch (
        e
      ) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating profile: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context:
          context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (
            context,
          ) => Padding(
            padding: const EdgeInsets.all(
              16.0,
            ),
            child: GridView.count(
              crossAxisCount:
                  6,
              shrinkWrap:
                  true,
              children:
                  _emojiOptions
                      .map(
                        (
                          emoji,
                        ) => GestureDetector(
                          onTap: () {
                            setState(
                              () {
                                _selectedEmoji =
                                    emoji;
                              },
                            );
                            Navigator.pop(
                              context,
                            );
                          },
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(
                                fontSize:
                                    32,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController =
        TextEditingController();
    final newPasswordController =
        TextEditingController();
    final confirmPasswordController =
        TextEditingController();
    final formKey =
        GlobalKey<
          FormState
        >();
    bool isLoading =
        false;

    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => StatefulBuilder(
            builder:
                (
                  context,
                  setState,
                ) => AlertDialog(
                  title: const Text(
                    'Change Password',
                  ),
                  content: Form(
                    key:
                        formKey,
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller:
                              oldPasswordController,
                          decoration: const InputDecoration(
                            labelText:
                                'Old Password',
                          ),
                          obscureText:
                              true,
                          validator:
                              (
                                v,
                              ) =>
                                  v ==
                                              null ||
                                          v.isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                        TextFormField(
                          controller:
                              newPasswordController,
                          decoration: const InputDecoration(
                            labelText:
                                'New Password',
                          ),
                          obscureText:
                              true,
                          validator:
                              (
                                v,
                              ) =>
                                  v ==
                                              null ||
                                          v.isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                        TextFormField(
                          controller:
                              confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText:
                                'Confirm New Password',
                          ),
                          obscureText:
                              true,
                          validator:
                              (
                                v,
                              ) =>
                                  v !=
                                          newPasswordController.text
                                      ? 'Passwords do not match'
                                      : null,
                        ),
                      ],
                    ),
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
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (!formKey.currentState!.validate()) return;
                                setState(
                                  () =>
                                      isLoading =
                                          true,
                                );
                                // Check old password
                                final userSnap =
                                    await DatabaseService.database
                                        .child(
                                          'users/${_getUserTypePath(currentUser!.type)}/${currentUser!.username}',
                                        )
                                        .get();
                                final userData =
                                    userSnap.value
                                        as Map<
                                          dynamic,
                                          dynamic
                                        >?;
                                if (userData ==
                                        null ||
                                    userData['password'] !=
                                        oldPasswordController.text) {
                                  setState(
                                    () =>
                                        isLoading =
                                            false,
                                  );
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Old password is incorrect',
                                      ),
                                      backgroundColor:
                                          Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                // Update password
                                await _databaseService.updateUserByType(
                                  currentUser!.username,
                                  currentUser!.type,
                                  {
                                    'password':
                                        newPasswordController.text,
                                  },
                                );
                                setState(
                                  () =>
                                      isLoading =
                                          false,
                                );
                                Navigator.pop(
                                  context,
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password changed successfully',
                                    ),
                                    backgroundColor:
                                        Colors.green,
                                  ),
                                );
                              },
                      child:
                          isLoading
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
                                'Change',
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  String _getUserTypePath(
    UserType type,
  ) {
    switch (type) {
      case UserType.admin:
        return 'admin';
      case UserType.business:
        return 'business';
      default:
        return 'normalUser';
    }
  }

  Future<
    void
  >
  _saveBusinessInfo() async {
    if (_businessNameController.text.isEmpty ||
        _businessAddressController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Business name and address are required',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context:
          context,
      barrierDismissible:
          false,
      builder: (
        BuildContext context,
      ) {
        return const Center(
          child:
              CircularProgressIndicator(),
        );
      },
    );

    try {
      String? advertisementImageUrl =
          currentUser?.advertisementImageUrl;

      // Upload advertisement image if a new one is selected
      if (_advertisementImage !=
          null) {
        try {
          advertisementImageUrl = await _storageService.uploadAdvertisementImage(
            _advertisementImage!,
            currentUser!.username,
          );
        } catch (
          e
        ) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload advertisement image: $e',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
          Navigator.of(
            context,
          ).pop(); // Close loading dialog
          return;
        }
      }

      // Prepare update data
      Map<
        String,
        dynamic
      >
      updateData = {
        'businessName':
            _businessNameController.text,
        'businessAddress':
            _businessAddressController.text,
        'businessPhone':
            _businessPhoneController.text,
        'businessEmail':
            _businessEmailController.text,
        'businessDescription':
            _businessDescriptionController.text,
        'openingTime':
            _openingTime !=
                    null
                ? _openingTime!.format(
                  context,
                )
                : null,
        'closingTime':
            _closingTime !=
                    null
                ? _closingTime!.format(
                  context,
                )
                : null,
        'advertisementImageUrl':
            advertisementImageUrl,
        'advertisementTitle':
            _advertisementTitle,
        'advertisementDescription':
            _advertisementDescription,
      };

      // Update user in database
      await _databaseService.updateUserByType(
        currentUser!.username,
        UserType.business,
        updateData,
      );

      // Close loading dialog
      Navigator.of(
        context,
      ).pop();

      setState(
        () {
          _isEditingBusiness =
              false;
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
                currentUser!.businessLocation,
            profileEmoji:
                currentUser!.profileEmoji,
            profilePictureUrl:
                currentUser!.profilePictureUrl,
            advertisementImageUrl:
                advertisementImageUrl,
            advertisementTitle:
                _advertisementTitle,
            advertisementDescription:
                _advertisementDescription,
          );
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Business information and advertisement updated successfully!',
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    } catch (
      e
    ) {
      // Close loading dialog
      Navigator.of(
        context,
      ).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update business information: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  Future<
    void
  >
  _pickBusinessTime(
    bool isOpening,
  ) async {
    final picked = await showTimePicker(
      context:
          context,
      initialTime:
          isOpening
              ? (_openingTime ??
                  TimeOfDay(
                    hour:
                        9,
                    minute:
                        0,
                  ))
              : (_closingTime ??
                  TimeOfDay(
                    hour:
                        17,
                    minute:
                        0,
                  )),
    );
    if (picked !=
        null) {
      setState(
        () {
          if (isOpening) {
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing
                  ? Icons.save
                  : Icons.edit,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
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
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ),
          child: Form(
            key:
                _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  elevation:
                      4,
                  child: Padding(
                    padding: const EdgeInsets.all(
                      24.0,
                    ),
                    child: Column(
                      children: [
                        _buildProfilePictureSection(),
                        const SizedBox(
                          height:
                              16,
                        ),
                        TextFormField(
                          controller:
                              _usernameController,
                          decoration: const InputDecoration(
                            labelText:
                                'Username',
                            prefixIcon: Icon(
                              Icons.person,
                            ),
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
                              return 'Please enter a username';
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
                            prefixIcon: Icon(
                              Icons.email,
                            ),
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
                              return 'Please enter an email';
                            }
                            if (!value.contains(
                              '@',
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
                        if (currentUser?.type ==
                            UserType.business) ...[
                          TextFormField(
                            controller:
                                _phoneController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Phone Number',
                              prefixIcon: Icon(
                                Icons.phone,
                              ),
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
                                return 'Please enter a phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(
                          height:
                              24,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.lock,
                          ),
                          label: const Text(
                            'Change Password',
                          ),
                          onPressed:
                              _showChangePasswordDialog,
                        ),
                        const SizedBox(
                          height:
                              8,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.bug_report,
                          ),
                          label: const Text(
                            'Report an Issue',
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (
                                      context,
                                    ) =>
                                        const ReportPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height:
                              8,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.logout,
                          ),
                          label: const Text(
                            'Logout',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red,
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed: () {
                            currentUser =
                                null;
                            Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (currentUser?.type ==
                    UserType.business) ...[
                  const SizedBox(
                    height:
                        24,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                    ),
                    elevation:
                        2,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        16.0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Business Information',
                                style: TextStyle(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isEditingBusiness
                                      ? Icons.save
                                      : Icons.edit,
                                ),
                                onPressed: () {
                                  if (_isEditingBusiness) {
                                    _saveBusinessInfo();
                                  } else {
                                    setState(
                                      () =>
                                          _isEditingBusiness =
                                              true,
                                    );
                                  }
                                },
                              ),
                            ],
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
                              prefixIcon: Icon(
                                Icons.business,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            enabled:
                                _isEditingBusiness,
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          TextFormField(
                            controller:
                                _businessDescriptionController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Business Description',
                              prefixIcon: Icon(
                                Icons.description,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            enabled:
                                _isEditingBusiness,
                            maxLines:
                                2,
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          TextFormField(
                            controller:
                                _businessAddressController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Business Address',
                              prefixIcon: Icon(
                                Icons.location_on,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            enabled:
                                _isEditingBusiness,
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          TextFormField(
                            controller:
                                _businessPhoneController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Business Phone',
                              prefixIcon: Icon(
                                Icons.phone,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            enabled:
                                _isEditingBusiness,
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          TextFormField(
                            controller:
                                _businessEmailController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Business Email',
                              prefixIcon: Icon(
                                Icons.email,
                              ),
                              border:
                                  OutlineInputBorder(),
                            ),
                            enabled:
                                _isEditingBusiness,
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly:
                                      true,
                                  controller: TextEditingController(
                                    text:
                                        _openingTime !=
                                                null
                                            ? _openingTime!.format(
                                              context,
                                            )
                                            : '',
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Opening Time',
                                    prefixIcon: const Icon(
                                      Icons.access_time,
                                    ),
                                    suffixIcon:
                                        _isEditingBusiness
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                              ),
                                              onPressed:
                                                  () => _pickBusinessTime(
                                                    true,
                                                  ),
                                            )
                                            : null,
                                    border:
                                        const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width:
                                    8,
                              ),
                              Expanded(
                                child: TextFormField(
                                  readOnly:
                                      true,
                                  controller: TextEditingController(
                                    text:
                                        _closingTime !=
                                                null
                                            ? _closingTime!.format(
                                              context,
                                            )
                                            : '',
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Closing Time',
                                    prefixIcon: const Icon(
                                      Icons.access_time,
                                    ),
                                    suffixIcon:
                                        _isEditingBusiness
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                              ),
                                              onPressed:
                                                  () => _pickBusinessTime(
                                                    false,
                                                  ),
                                            )
                                            : null,
                                    border:
                                        const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height:
                                16,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.edit_location_alt,
                            ),
                            label: const Text(
                              'Change Business Location',
                            ),
                            onPressed: () async {
                              LatLng? newLocation = await _pickLocationOnMap(
                                context,
                                currentUser?.businessLocation,
                              );
                              if (newLocation !=
                                  null) {
                                await DatabaseService().updateUserByType(
                                  currentUser!.username,
                                  UserType.business,
                                  {
                                    'businessLocation': {
                                      'latitude':
                                          newLocation.latitude,
                                      'longitude':
                                          newLocation.longitude,
                                    },
                                  },
                                );
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
                                          newLocation,
                                    );
                                  },
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Business location updated!',
                                    ),
                                    backgroundColor:
                                        Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(
                            height:
                                16,
                          ),
                          // Advertisement Manager for Business Users
                          AdvertisementManager(
                            currentImageUrl:
                                currentUser?.advertisementImageUrl,
                            currentTitle:
                                currentUser?.advertisementTitle,
                            currentDescription:
                                currentUser?.advertisementDescription,
                            isEditing:
                                _isEditingBusiness,
                            onImageSelected: (
                              imagePath,
                            ) {
                              if (imagePath !=
                                  null) {
                                setState(
                                  () {
                                    _advertisementImage = File(
                                      imagePath,
                                    );
                                  },
                                );
                              } else {
                                setState(
                                  () {
                                    _advertisementImage =
                                        null;
                                  },
                                );
                              }
                            },
                            onTitleChanged: (
                              title,
                            ) {
                              setState(
                                () {
                                  _advertisementTitle =
                                      title;
                                },
                              );
                            },
                            onDescriptionChanged: (
                              description,
                            ) {
                              setState(
                                () {
                                  _advertisementDescription =
                                      description;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height:
                        24,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                    ),
                    elevation:
                        2,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        16.0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Business Reviews',
                                style: TextStyle(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                ),
                                onPressed: () async {
                                  final reviews = await _databaseService.getBusinessReviews(
                                    currentUser!.username,
                                  );
                                  setState(
                                    () {
                                      _businessReviews =
                                          reviews;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height:
                                16,
                          ),
                          if (_businessReviews.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  16.0,
                                ),
                                child: Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap:
                                  true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _businessReviews.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final review =
                                    _businessReviews[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              review.reviewerUsername,
                                              style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color:
                                                      Colors.amber,
                                                  size:
                                                      20,
                                                ),
                                                const SizedBox(
                                                  width:
                                                      4,
                                                ),
                                                Text(
                                                  review.rating.toString(),
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height:
                                              8,
                                        ),
                                        Text(
                                          review.comment,
                                        ),
                                        const SizedBox(
                                          height:
                                              8,
                                        ),
                                        Text(
                                          '${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year}',
                                          style: const TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                12,
                                          ),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        ProfilePicturePicker(
          currentEmoji:
              _selectedEmoji ??
              currentUser?.profileEmoji,
          currentImageUrl:
              currentUser?.profilePictureUrl,
          onEmojiSelected: (
            emoji,
          ) {
            setState(
              () {
                _selectedEmoji =
                    emoji;
                _profileImage =
                    null; // Clear image when emoji is selected
              },
            );
          },
          onImageSelected: (
            image,
          ) {
            setState(
              () {
                _profileImage =
                    image;
                _selectedEmoji =
                    null; // Clear emoji when image is selected
              },
            );
          },
          isBusiness:
              currentUser?.type ==
              UserType.business,
          isEditing:
              _isEditing,
        ),
        if (_isEditing) ...[
          const SizedBox(
            height:
                16,
          ),
          Wrap(
            spacing:
                8.0, // gap between adjacent chips
            runSpacing:
                4.0, // gap between lines
            alignment:
                WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _pickImage,
                icon: const Icon(
                  Icons.upload,
                ),
                label: const Text(
                  'Upload Photo',
                ),
                style: ElevatedButton.styleFrom(
                  shape:
                      const StadiumBorder(),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _showEmojiPicker,
                icon: const Icon(
                  Icons.emoji_emotions,
                ),
                label: const Text(
                  'Choose Emoji',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange,
                  shape:
                      const StadiumBorder(),
                ),
              ),
              if (currentUser?.profilePictureUrl !=
                      null ||
                  _profileImage !=
                      null ||
                  _selectedEmoji !=
                      null)
                ElevatedButton.icon(
                  onPressed:
                      _removeProfilePicture,
                  icon: const Icon(
                    Icons.delete,
                  ),
                  label: const Text(
                    'Remove',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    shape:
                        const StadiumBorder(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      elevation:
          1,
      child: ListTile(
        leading: Icon(
          icon,
          color:
              Colors.deepPurple,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
        ),
      ),
    );
  }

  Future<
    LatLng?
  >
  _pickLocationOnMap(
    BuildContext context,
    LatLng? initialLocation,
  ) async {
    LatLng selectedLocation =
        initialLocation ??
        const LatLng(
          2.1896,
          102.2501,
        );
    return await showDialog<
      LatLng
    >(
      context:
          context,
      builder: (
        context,
      ) {
        final mapController =
            MapController();
        return AlertDialog(
          title: const Text(
            'Select New Business Location',
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
                0.5,
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
                      mapController.move(
                        point,
                        mapController.camera.zoom,
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
                          width:
                              60.0,
                          height:
                              60.0,
                          point:
                              selectedLocation,
                          child: const Icon(
                            Icons.location_on,
                            color:
                                Colors.red,
                            size:
                                36,
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
            ElevatedButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(
                    selectedLocation,
                  ),
              child: const Text(
                'Select',
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
  _loadBusinessReviews() async {
    if (currentUser ==
        null)
      return;
    final reviews = await _databaseService.getBusinessReviews(
      currentUser!.username,
    );
    setState(
      () {
        _businessReviews =
            reviews;
      },
    );
  }

  Future<
    void
  >
  _loadUserData() async {
    if (currentUser ==
        null)
      return;
    final user = await _databaseService.getUser(
      currentUser!.username,
    );
    if (user !=
        null) {
      setState(
        () {
          currentUser =
              user;
          _usernameController.text = user.username;
          _emailController.text = user.email;
          _phoneController.text =
              user.businessPhone ??
              '';
          _selectedEmoji =
              user.profileEmoji;
          if (user.type ==
              UserType.business) {
            _businessNameController.text =
                user.businessName ??
                '';
            _businessAddressController.text =
                user.businessAddress ??
                '';
            _businessPhoneController.text =
                user.businessPhone ??
                '';
            _businessEmailController.text =
                user.businessEmail ??
                '';
            _businessDescriptionController.text =
                user.businessDescription ??
                '';
            _openingTime =
                user.openingTime;
            _closingTime =
                user.closingTime;
          }
        },
      );
    }
  }

  Future<
    void
  >
  _removeProfilePicture() async {
    setState(
      () {
        _profileImage =
            null;
        _selectedEmoji =
            null;
        // Also remove from database/storage if it's already uploaded
        if (currentUser?.profilePictureUrl !=
            null) {
          // You might want to ask for confirmation here
          _storageService.deleteProfilePicture(
            currentUser!.profilePictureUrl!,
          );
          currentUser!.profilePictureUrl = null;
          _databaseService.updateUser(
            currentUser!,
          );
        }
      },
    );
  }
}
