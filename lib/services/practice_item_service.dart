import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get custom practice items for a specific level and student
  Future<List<Map<String, dynamic>>> getCustomPracticeItems({
    required int level,
    String? studentId,
    String? teacherId,
    bool includeInactive = false,
  }) async {
    try {
      final String? effectiveTeacherId = teacherId ?? studentId;
      if (effectiveTeacherId == null || effectiveTeacherId.trim().isEmpty) {
        return [];
      }

      Query query = _firestore
          .collection('custom_practice_items')
          .where('level', isEqualTo: level)
          .where('teacher_id', isEqualTo: effectiveTeacherId);

      if (!includeInactive) {
        query = query.where('is_active', isEqualTo: true);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final bool isActive = data['is_active'] == null
            ? true
            : (data['is_active'] as bool? ?? true);

        // teacher_id is already filtered by the query above.
        if (!includeInactive && !isActive) {
          return <String, dynamic>{};
        }

        DateTime? createdAt;
        final dynamic createdRaw = data['created_at'];
        if (createdRaw is Timestamp) {
          createdAt = createdRaw.toDate();
        } else if (createdRaw is DateTime) {
          createdAt = createdRaw;
        }

        return {
          'id': doc.id,
          'type': data['type'] ?? 'Word',
          'content': data['content'] ?? '',
          'emoji': data['emoji'] ?? '',
          'level': data['level'] ?? level,
          'teacher_id': data['teacher_id'] ?? effectiveTeacherId,
          'is_active': isActive,
          'created_at': createdAt,
          'order': data['order'],
        };
      }).where((item) => item.isNotEmpty).toList();

      items.sort((a, b) {
        final int ao = (a['order'] is int) ? a['order'] as int : 1 << 30;
        final int bo = (b['order'] is int) ? b['order'] as int : 1 << 30;
        if (ao != bo) return ao.compareTo(bo);

        final DateTime? ac = a['created_at'] as DateTime?;
        final DateTime? bc = b['created_at'] as DateTime?;
        if (ac == null && bc == null) return 0;
        if (ac == null) return 1;
        if (bc == null) return -1;
        return ac.compareTo(bc);
      });

      return items;
    } catch (e) {
      print('Error fetching custom practice items: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamCustomPracticeItems({
    required int level,
    required String teacherId,
    bool includeInactive = false,
  }) {
    Query query = _firestore
        .collection('custom_practice_items')
        .where('level', isEqualTo: level)
        .where('teacher_id', isEqualTo: teacherId);
    if (!includeInactive) {
      query = query.where('is_active', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        DateTime? createdAt;
        final dynamic createdRaw = data['created_at'];
        if (createdRaw is Timestamp) {
          createdAt = createdRaw.toDate();
        } else if (createdRaw is DateTime) {
          createdAt = createdRaw;
        }

        return {
          'id': doc.id,
          'type': data['type'] ?? 'Word',
          'content': data['content'] ?? '',
          'emoji': data['emoji'] ?? '',
          'level': data['level'] ?? level,
          'teacher_id': data['teacher_id'] ?? '',
          'is_active': data['is_active'] ?? true,
          'created_at': createdAt,
          'order': data['order'],
        };
      }).toList();

      items.sort((a, b) {
        final int ao = (a['order'] is int) ? a['order'] as int : 1 << 30;
        final int bo = (b['order'] is int) ? b['order'] as int : 1 << 30;
        if (ao != bo) return ao.compareTo(bo);

        final DateTime? ac = a['created_at'] as DateTime?;
        final DateTime? bc = b['created_at'] as DateTime?;
        if (ac == null && bc == null) return 0;
        if (ac == null) return 1;
        if (bc == null) return -1;
        return ac.compareTo(bc);
      });

      return items;
    });
  }

  Future<void> ensureDefaultPracticeItems({
    required String teacherId,
    required int level,
    required List<Map<String, String>> defaultItems,
  }) async {
    final existing = await _firestore
        .collection('custom_practice_items')
        .where('teacher_id', isEqualTo: teacherId)
        .where('level', isEqualTo: level)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (int i = 0; i < defaultItems.length; i++) {
      final item = defaultItems[i];
      final doc = _firestore.collection('custom_practice_items').doc();
      batch.set(doc, {
        'level': level,
        'type': item['type'] ?? 'Word',
        'content': item['content'] ?? '',
        'emoji': item['emoji'] ?? '',
        'teacher_id': teacherId,
        'is_active': true,
        'order': i,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
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
      final newItem = {
        'level': level,
        'type': type,
        'content': content,
        'emoji': emoji,
        'teacher_id': teacherId,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
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
      await _firestore.collection('custom_practice_items').doc(itemId).update({
        'type': type,
        'content': content,
        'emoji': emoji,
        'updated_at': FieldValue.serverTimestamp(),
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
      await _firestore.collection('custom_practice_items').doc(itemId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('Practice item toggled: $itemId to $isActive');
      return true;
    } catch (e) {
      print('Error toggling practice item: $e');
      return false;
    }
  }
}
