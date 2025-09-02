import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;
  final Uuid _uuid =
      Uuid();

  // Upload profile picture
  Future<
    String
  >
  uploadProfilePicture(
    File imageFile,
    String username,
  ) async {
    try {
      final String fileName =
          'profile_pictures/$username/${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child(
        fileName,
      );

      final UploadTask uploadTask = ref.putFile(
        imageFile,
      );
      final TaskSnapshot snapshot =
          await uploadTask;

      final String downloadUrl =
          await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (
      e
    ) {
      throw Exception(
        'Failed to upload profile picture: $e',
      );
    }
  }

  // Upload advertisement image
  Future<
    String
  >
  uploadAdvertisementImage(
    File imageFile,
    String businessUsername,
  ) async {
    try {
      final String fileName =
          'advertisements/$businessUsername/${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child(
        fileName,
      );

      final UploadTask uploadTask = ref.putFile(
        imageFile,
      );
      final TaskSnapshot snapshot =
          await uploadTask;

      final String downloadUrl =
          await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (
      e
    ) {
      throw Exception(
        'Failed to upload advertisement image: $e',
      );
    }
  }

  // Delete profile picture
  Future<
    void
  >
  deleteProfilePicture(
    String imageUrl,
  ) async {
    try {
      if (imageUrl.isNotEmpty) {
        final Reference ref = _storage.refFromURL(
          imageUrl,
        );
        await ref.delete();
      }
    } catch (
      e
    ) {
      throw Exception(
        'Failed to delete profile picture: $e',
      );
    }
  }

  // Delete advertisement image
  Future<
    void
  >
  deleteAdvertisementImage(
    String imageUrl,
  ) async {
    try {
      if (imageUrl.isNotEmpty) {
        final Reference ref = _storage.refFromURL(
          imageUrl,
        );
        await ref.delete();
      }
    } catch (
      e
    ) {
      throw Exception(
        'Failed to delete advertisement image: $e',
      );
    }
  }
}
