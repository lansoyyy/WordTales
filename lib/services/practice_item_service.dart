import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PracticeItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get custom practice items for a specific level and student
  Future<List<Map<String, dynamic>>> getCustomPracticeItems({
    required int level,
    required String studentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('custom_practice_items')
          .where('level', isEqualTo: level)
          .where('student_id', isEqualTo: studentId)
          .where('is_active', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Word',
          'content': data['content'] ?? '',
          'emoji': data['emoji'] ?? '',
          'level': data['level'] ?? level,
          'teacher_id': data['teacher_id'] ?? '',
          'is_active': data['is_active'] ?? true,
          'created_at': data['created_at']?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching custom practice items: $e');
      return [];
    }
  }

  /// Add a new custom practice item
  Future<bool> addCustomPracticeItem({
    required String teacherId,
    required int level,
    required String type,
    required String content,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user');
        return false;
      }

      final newItem = {
        'level': level,
        'type': type,
        'content': content,
        'emoji': emoji,
        'teacher_id': teacherId,
        'student_id': '', // Will be filled when assigned to student
        'is_active': true,
        'created_at': DateTime.now(),
      };

      await _firestore.collection('custom_practice_items').add(newItem);
      print('Practice item added: $content');
      return true;
    } catch (e) {
      print('Error adding practice item: $e');
      return false;
    }
  }

  /// Update an existing custom practice item
  Future<bool> updateCustomPracticeItem({
    required String itemId,
    required String type,
    required String content,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user');
        return false;
      }

      await _firestore.collection('custom_practice_items').doc(itemId).update({
        'type': type,
        'content': content,
        'emoji': emoji,
        'updated_at': DateTime.now(),
      });

      print('Practice item updated: $content');
      return true;
    } catch (e) {
      print('Error updating practice item: $e');
      return false;
    }
  }

  /// Delete a custom practice item
  Future<bool> deleteCustomPracticeItem({
    required String itemId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user');
        return false;
      }

      await _firestore.collection('custom_practice_items').doc(itemId).delete();
      print('Practice item deleted: $itemId');
      return true;
    } catch (e) {
      print('Error deleting practice item: $e');
      return false;
    }
  }

  /// Toggle a custom practice item's active status
  Future<bool> toggleCustomPracticeItem({
    required String itemId,
    required bool isActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user');
        return false;
      }

      await _firestore.collection('custom_practice_items').doc(itemId).update({
        'is_active': isActive,
        'updated_at': DateTime.now(),
      });

      print('Practice item toggled: $itemId to $isActive');
      return true;
    } catch (e) {
      print('Error toggling practice item: $e');
      return false;
    }
  }
}
