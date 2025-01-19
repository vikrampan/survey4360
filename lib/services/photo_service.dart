// lib/services/photo_service.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> capturePhoto({
    required String surveyId,
    required String questionId,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'surveys/$surveyId/$questionId/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      // Handle the upload based on platform
      final UploadTask uploadTask;
      if (kIsWeb) {
        // For web, read as bytes
        final Uint8List bytes = await photo.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile, use URI
        uploadTask = ref.putData(await photo.readAsBytes());
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error capturing photo: $e');
      return null;
    }
  }

  Future<String?> pickFromGallery({
    required String surveyId,
    required String questionId,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'surveys/$surveyId/$questionId/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      // Handle the upload based on platform
      final UploadTask uploadTask;
      if (kIsWeb) {
        // For web, read as bytes
        final Uint8List bytes = await photo.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile, use URI
        uploadTask = ref.putData(await photo.readAsBytes());
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error picking photo: $e');
      return null;
    }
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  Future<String?> showPhotoOptions({
    required BuildContext context,
    required String surveyId,
    required String questionId,
  }) async {
    final String? result = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final url = await capturePhoto(
                    surveyId: surveyId,
                    questionId: questionId,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, url);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final url = await pickFromGallery(
                    surveyId: surveyId,
                    questionId: questionId,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, url);
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    return result;
  }
}