import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AdvertisementManager
    extends
        StatefulWidget {
  final String? currentImageUrl;
  final String? currentTitle;
  final String? currentDescription;
  final bool isEditing;
  final Function(
    String?,
  )
  onImageSelected;
  final Function(
    String?,
  )
  onTitleChanged;
  final Function(
    String?,
  )
  onDescriptionChanged;

  const AdvertisementManager({
    super.key,
    this.currentImageUrl,
    this.currentTitle,
    this.currentDescription,
    this.isEditing =
        false,
    required this.onImageSelected,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  @override
  State<
    AdvertisementManager
  >
  createState() =>
      _AdvertisementManagerState();
}

class _AdvertisementManagerState
    extends
        State<
          AdvertisementManager
        > {
  final ImagePicker _imagePicker =
      ImagePicker();
  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _titleController.text =
        widget.currentTitle ??
        '';
    _descriptionController.text =
        widget.currentDescription ??
        '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source:
          ImageSource.gallery,
      maxWidth:
          1024,
      maxHeight:
          1024,
      imageQuality:
          85,
    );

    if (image !=
        null) {
      setState(
        () {
          _selectedImage = File(
            image.path,
          );
        },
      );
      widget.onImageSelected(
        _selectedImage?.path,
      );
    }
  }

  void _removeImage() {
    setState(
      () {
        _selectedImage =
            null;
      },
    );
    widget.onImageSelected(
      null,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      elevation:
          4,
      child: Padding(
        padding: const EdgeInsets.all(
          16.0,
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
                ),
                const SizedBox(
                  width:
                      8,
                ),
                const Text(
                  'Business Advertisement',
                  style: TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.isEditing)
              const Padding(
                padding: EdgeInsets.only(
                  left:
                      32.0,
                  top:
                      2.0,
                  bottom:
                      8.0,
                ),
                child: Text(
                  '(Editing)',
                  style: TextStyle(
                    fontSize:
                        14,
                    color:
                        Colors.orange,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(
              height:
                  16,
            ),

            // Advertisement Image
            const Text(
              'Advertisement Image',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final double imageWidth =
                    constraints.maxWidth;
                return Container(
                  width:
                      imageWidth,
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
                    color:
                        Colors.grey.shade50,
                  ),
                  child:
                      _selectedImage !=
                              null
                          ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ),
                                child: Image.file(
                                  _selectedImage!,
                                  width:
                                      imageWidth,
                                  height:
                                      200,
                                  fit:
                                      BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top:
                                    8,
                                right:
                                    8,
                                child: IconButton(
                                  onPressed:
                                      widget.isEditing
                                          ? _removeImage
                                          : null,
                                  icon: const Icon(
                                    Icons.close,
                                    color:
                                        Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : widget.currentImageUrl !=
                              null
                          ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ),
                                child: Image.network(
                                  widget.currentImageUrl!,
                                  width:
                                      imageWidth,
                                  height:
                                      200,
                                  fit:
                                      BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size:
                                            60,
                                        color:
                                            Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top:
                                    8,
                                right:
                                    8,
                                child: IconButton(
                                  onPressed:
                                      widget.isEditing
                                          ? _removeImage
                                          : null,
                                  icon: const Icon(
                                    Icons.close,
                                    color:
                                        Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size:
                                      60,
                                  color:
                                      Colors.grey,
                                ),
                                SizedBox(
                                  height:
                                      8,
                                ),
                                Text(
                                  'No advertisement image',
                                  style: TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                );
              },
            ),
            const SizedBox(
              height:
                  8,
            ),
            ElevatedButton.icon(
              onPressed:
                  widget.isEditing
                      ? _pickImage
                      : null,
              icon: const Icon(
                Icons.upload,
              ),
              label: const Text(
                'Upload Advertisement Image',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blue,
                foregroundColor:
                    Colors.white,
              ),
            ),
            const SizedBox(
              height:
                  16,
            ),

            // Advertisement Title
            const Text(
              'Advertisement Title',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            TextField(
              controller:
                  _titleController,
              enabled:
                  widget.isEditing,
              decoration: const InputDecoration(
                hintText:
                    'Enter advertisement title...',
                border:
                    OutlineInputBorder(),
              ),
              onChanged:
                  (
                    value,
                  ) => widget.onTitleChanged(
                    value.isEmpty
                        ? null
                        : value,
                  ),
            ),
            const SizedBox(
              height:
                  16,
            ),

            // Advertisement Description
            const Text(
              'Advertisement Description',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            TextField(
              controller:
                  _descriptionController,
              enabled:
                  widget.isEditing,
              decoration: const InputDecoration(
                hintText:
                    'Enter advertisement description...',
                border:
                    OutlineInputBorder(),
              ),
              maxLines:
                  3,
              onChanged:
                  (
                    value,
                  ) => widget.onDescriptionChanged(
                    value.isEmpty
                        ? null
                        : value,
                  ),
            ),
            const SizedBox(
              height:
                  16,
            ),

            // Info Text
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
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color:
                        Colors.blue,
                  ),
                  SizedBox(
                    width:
                        8,
                  ),
                  Expanded(
                    child: Text(
                      'Your advertisement will be displayed to users and admins on the nearby businesses map.',
                      style: TextStyle(
                        color:
                            Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
