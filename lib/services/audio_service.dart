import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Start recording audio and return recording path
  static Future<String?> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        // Get temporary directory for recording
        final Directory tempDir = await getTemporaryDirectory();
        final String path =
            '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        // Use WAV format for better compatibility
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        return path;
      }
      return null;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return null;
    }
  }

  /// Stop recording and return audio file path
  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Check if currently recording
  static Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

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
