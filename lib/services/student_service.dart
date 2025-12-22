import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final String _studentsCollection = 'students';

  // Create a new student
  Future<String> createStudent({
    required String name,
    required String teacherId,
    required String section,
  }) async {
    try {
      final docRef = await _firestore.collection(_studentsCollection).add({
        'name': name,
        'teacherId': teacherId,
        'section': section,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'levelProgress': {
          '1': {
            'completed': false,
            'score': 0,
            'totalItems': 5,
            'date': null,
            'audioRecordings': <String, String>{}
          },
          '2': {
            'completed': false,
            'score': 0,
            'totalItems': 10,
            'date': null,
            'audioRecordings': <String, String>{}
          },
          '3': {
            'completed': false,
            'score': 0,
            'totalItems': 15,
            'date': null,
            'audioRecordings': <String, String>{}
          },
          '4': {
            'completed': false,
            'score': 0,
            'totalItems': 20,
            'date': null,
            'audioRecordings': <String, String>{}
          },
          '5': {
            'completed': false,
            'score': 0,
            'totalItems': 20,
            'date': null,
            'audioRecordings': <String, String>{}
          },
        },
      });
      print('Student created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating student: $e');
      rethrow;
    }
  }

  // Get all students for a teacher
  Future<List<Map<String, dynamic>>> getStudentsByTeacher(
      String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_studentsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      rethrow;
    }
  }

  // Get student by ID
  Future<Map<String, dynamic>?> getStudent(String studentId) async {
    try {
      final doc =
          await _firestore.collection(_studentsCollection).doc(studentId).get();
      if (doc.exists) {
        final data = doc.data();
        data?['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      rethrow;
    }
  }

  // Get student by name and teacher ID
  Future<Map<String, dynamic>?> getStudentByName({
    required String name,
    required String teacherId,
    String? section,
  }) async {
    try {
      var query = _firestore
          .collection(_studentsCollection)
          .where('name', isEqualTo: name)
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true);

      // If section is provided, filter by section too
      if (section != null) {
        query = query.where('section', isEqualTo: section);
      }

      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['id'] = querySnapshot.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting student by name: $e');
      rethrow;
    }
  }

  // Find or create student - returns existing student if name matches, creates new one if not
  Future<Map<String, dynamic>> findOrCreateStudent({
    required String name,
    required String teacherId,
    required String section,
  }) async {
    try {
      // First, try to find existing student with same name and section
      final existingStudent = await getStudentByName(
        name: name,
        teacherId: teacherId,
        section: section,
      );

      if (existingStudent != null) {
        print('Found existing student: ${existingStudent['id']}');
        return existingStudent;
      }

      // If not found, create new student
      final studentId = await createStudent(
        name: name,
        teacherId: teacherId,
        section: section,
      );

      // Return the newly created student
      final newStudent = await getStudent(studentId);
      return newStudent!;
    } catch (e) {
      print('Error in findOrCreateStudent: $e');
      rethrow;
    }
  }

  // Update student information
  Future<void> updateStudent(
      String studentId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_studentsCollection)
          .doc(studentId)
          .update(data);
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  // Update student level progress (completed level)
  Future<void> updateLevelProgress({
    required String studentId,
    required int level,
    required int score,
    required int totalItems,
    List<int>? completedItems,
    List<int>? failedItems,
  }) async {
    try {
      await _firestore.collection(_studentsCollection).doc(studentId).update({
        'levelProgress.$level': {
          'completed': true,
          'score': score,
          'totalItems': totalItems,
          'date': DateTime.now().toString().split(' ')[0],
          if (completedItems != null || failedItems != null)
            'results': {
              'completedItems': completedItems ?? <int>[],
              'failedItems': failedItems ?? <int>[],
            },
          'audioRecordings': <String, String>{},
        }
      });
    } catch (e) {
      print('Error updating level progress: $e');
      rethrow;
    }
  }

  // Save audio recording for a specific item
  Future<void> saveAudioRecording({
    required String studentId,
    required int level,
    required int itemIndex,
    required String audioUrl,
  }) async {
    try {
      await _firestore.collection(_studentsCollection).doc(studentId).update({
        'levelProgress.$level.audioRecordings.$itemIndex': audioUrl,
      });
    } catch (e) {
      print('Error saving audio recording: $e');
      rethrow;
    }
  }

  Future<void> updateLevelPartialProgress({
    required String studentId,
    required int level,
    required int score,
    required int totalItems,
    required int currentIndex,
    required List<int> completedItems,
    required List<int> failedItems,
    required int incorrectAttempts,
  }) async {
    try {
      await _firestore.collection(_studentsCollection).doc(studentId).update({
        'levelProgress.$level': {
          'completed': false,
          'score': score,
          'totalItems': totalItems,
          'date': DateTime.now().toString().split(' ')[0],
          'inProgress': {
            'currentIndex': currentIndex,
            'completedItems': completedItems,
            'failedItems': failedItems,
            'incorrectAttempts': incorrectAttempts,
          },
        }
      });
    } catch (e) {
      print('Error updating partial level progress: $e');
      rethrow;
    }
  }

  // Reset student's level progress (all levels or specific level)
  Future<void> resetStudentProgress(String studentId, {int? level}) async {
    try {
      if (level != null) {
        // Reset specific level
        await _firestore.collection(_studentsCollection).doc(studentId).update({
          'levelProgress.$level': {
            'completed': false,
            'score': 0,
            'totalItems': level == 1
                ? 10
                : level == 2
                    ? 15
                    : level == 3
                        ? 20
                        : level == 4
                            ? 25
                            : 20,
            'date': null,
            'audioRecordings': <String, String>{},
          }
        });
      } else {
        // Reset all levels
        await _firestore.collection(_studentsCollection).doc(studentId).update({
          'levelProgress': {
            '1': {
              'completed': false,
              'score': 0,
              'totalItems': 10,
              'date': null,
              'audioRecordings': <String, String>{},
            },
            '2': {
              'completed': false,
              'score': 0,
              'totalItems': 15,
              'date': null,
              'audioRecordings': <String, String>{},
            },
            '3': {
              'completed': false,
              'score': 0,
              'totalItems': 20,
              'date': null,
              'audioRecordings': <String, String>{},
            },
            '4': {
              'completed': false,
              'score': 0,
              'totalItems': 25,
              'date': null,
              'audioRecordings': <String, String>{},
            },
            '5': {
              'completed': false,
              'score': 0,
              'totalItems': 20,
              'date': null,
              'audioRecordings': <String, String>{},
            },
          },
        });
      }
    } catch (e) {
      print('Error resetting student progress: $e');
      rethrow;
    }
  }

  // Delete student (soft delete)
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore
          .collection(_studentsCollection)
          .doc(studentId)
          .update({'isActive': false});
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  // Get student count for a teacher
  Future<int> getStudentCount(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_studentsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting student count: $e');
      rethrow;
    }
  }

  // Get level statistics for a teacher
  Future<Map<String, dynamic>> getLevelStats(
      String teacherId, int level) async {
    try {
      final students = await getStudentsByTeacher(teacherId);
      int completedStudents = 0;
      double totalScore = 0;

      for (var student in students) {
        final levelProgress = student['levelProgress'];
        if (levelProgress != null && levelProgress['$level'] != null) {
          final levelData = levelProgress['$level'];
          if (levelData['completed'] == true) {
            completedStudents++;
            totalScore += (levelData['score'] ?? 0).toDouble();
          }
        }
      }

      return {
        'totalStudents': students.length,
        'completedStudents': completedStudents,
        'averageScore':
            completedStudents > 0 ? totalScore / completedStudents : 0.0,
      };
    } catch (e) {
      print('Error getting level stats: $e');
      rethrow;
    }
  }

  // Stream students for real-time updates
  Stream<List<Map<String, dynamic>>> streamStudentsByTeacher(String teacherId) {
    return _firestore
        .collection(_studentsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
