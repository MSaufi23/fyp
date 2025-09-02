import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePicturePicker
    extends
        StatefulWidget {
  final String? currentEmoji;
  final String? currentImageUrl;
  final Function(
    String?,
  )
  onEmojiSelected;
  final Function(
    File?,
  )
  onImageSelected;
  final bool isBusiness;
  final bool isEditing;

  const ProfilePicturePicker({
    super.key,
    this.currentEmoji,
    this.currentImageUrl,
    required this.onEmojiSelected,
    required this.onImageSelected,
    this.isBusiness =
        false,
    this.isEditing =
        false,
  });

  @override
  State<
    ProfilePicturePicker
  >
  createState() =>
      _ProfilePicturePickerState();
}

class _ProfilePicturePickerState
    extends
        State<
          ProfilePicturePicker
        > {
  final ImagePicker _imagePicker =
      ImagePicker();
  File? _selectedImage;
  String? _selectedEmoji;
  bool _showEmojiPicker =
      false;

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
    '🏢',
    '🏪',
    '🏨',
    '🏭',
    '🏗️',
    '🏛️',
    '🏰',
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmoji =
        widget.currentEmoji;
  }

  Future<
    void
  >
  _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source:
          ImageSource.gallery,
      maxWidth:
          512,
      maxHeight:
          512,
      imageQuality:
          80,
    );

    if (image !=
        null) {
      setState(
        () {
          _selectedImage = File(
            image.path,
          );
          _selectedEmoji =
              null;
          _showEmojiPicker =
              false;
        },
      );
      widget.onImageSelected(
        _selectedImage,
      );
      widget.onEmojiSelected(
        null,
      );
    }
  }

  void _selectEmoji(
    String emoji,
  ) {
    setState(
      () {
        _selectedEmoji =
            emoji;
        _selectedImage =
            null;
        _showEmojiPicker =
            false;
      },
    );
    widget.onEmojiSelected(
      emoji,
    );
    widget.onImageSelected(
      null,
    );
  }

  void _removeProfilePicture() {
    setState(
      () {
        _selectedEmoji =
            null;
        _selectedImage =
            null;
      },
    );
    widget.onEmojiSelected(
      null,
    );
    widget.onImageSelected(
      null,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        // Profile Picture Display
        GestureDetector(
          onTap:
              widget.isEditing
                  ? () {
                    setState(
                      () {
                        _showEmojiPicker =
                            !_showEmojiPicker;
                      },
                    );
                  }
                  : null,
          child: Container(
            width:
                120,
            height:
                120,
            decoration: BoxDecoration(
              shape:
                  BoxShape.circle,
              border: Border.all(
                color:
                    Colors.grey.shade300,
                width:
                    3,
              ),
              color:
                  Colors.grey.shade100,
            ),
            child: ClipOval(
              child:
                  _selectedImage !=
                          null
                      ? Image.file(
                        _selectedImage!,
                        width:
                            120,
                        height:
                            120,
                        fit:
                            BoxFit.cover,
                      )
                      : widget.currentImageUrl !=
                          null
                      ? Image.network(
                        widget.currentImageUrl!,
                        width:
                            120,
                        height:
                            120,
                        fit:
                            BoxFit.cover,
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress ==
                              null)
                            return child;
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return _buildEmojiOrIcon();
                        },
                      )
                      : _buildEmojiOrIcon(),
            ),
          ),
        ),

        if (_showEmojiPicker) _buildEmojiPicker(),
      ],
    );
  }

  Widget _buildEmojiOrIcon() {
    final emoji =
        _selectedEmoji ??
        widget.currentEmoji;
    if (emoji !=
        null) {
      return Center(
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize:
                60,
          ),
        ),
      );
    }
    return Icon(
      widget.isBusiness
          ? Icons.business
          : Icons.person,
      size:
          60,
      color:
          Colors.grey,
    );
  }

  Widget _buildEmojiPicker() {
    return Column(
      children: [
        const SizedBox(
          height:
              16,
        ),
        Container(
          height:
              200,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(
              8,
            ),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(
              8,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  8,
              crossAxisSpacing:
                  8,
              mainAxisSpacing:
                  8,
            ),
            itemCount:
                _emojiOptions.length,
            itemBuilder: (
              context,
              index,
            ) {
              return GestureDetector(
                onTap:
                    () => _selectEmoji(
                      _emojiOptions[index],
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _selectedEmoji ==
                                _emojiOptions[index]
                            ? Colors.blue.shade100
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      8,
                    ),
                    border:
                        _selectedEmoji ==
                                _emojiOptions[index]
                            ? Border.all(
                              color:
                                  Colors.blue,
                              width:
                                  2,
                            )
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      _emojiOptions[index],
                      style: const TextStyle(
                        fontSize:
                            24,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
