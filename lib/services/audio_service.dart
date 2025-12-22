import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload audio file to Firebase Storage
  static Future<String?> uploadAudio({
    required String filePath,
    required String studentId,
    required int level,
    required int itemIndex,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('Audio file does not exist: $filePath');
        return null;
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${studentId}_level${level}_item${itemIndex}_$timestamp.wav';

      // Create reference in Firebase Storage
      final ref =
          _storage.ref().child('student_recordings/$studentId/$fileName');

      // Upload file
      final uploadTask = await ref.putFile(file);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Clean up local file
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete local file: $e');
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  /// Delete audio file from Firebase Storage
  static Future<void> deleteAudio(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting audio: $e');
    }
  }

  /// Get audio file as bytes for playback
  static Future<Uint8List?> getAudioBytes(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final data = await ref.getData();
      return data;
    } catch (e) {
      debugPrint('Error getting audio bytes: $e');
      return null;
    }
  }
}
