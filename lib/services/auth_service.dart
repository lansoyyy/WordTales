import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final String _teachersCollection = 'teachers';

  // Initialize default teacher account
  Future<void> initializeDefaultTeacher() async {
    try {
      // Check if default teacher exists
      final teacherDoc = await _firestore
          .collection(_teachersCollection)
          .doc('default_teacher')
          .get();

      if (!teacherDoc.exists) {
        // Create default teacher account
        await _firestore
            .collection(_teachersCollection)
            .doc('default_teacher')
            .set({
          'email': 'teacher@wordtales.com',
          'password': 'teacher123', // In production, this should be hashed
          'name': 'Default Teacher',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        print('Default teacher account created successfully');
      } else {
        print('Default teacher account already exists');
      }
    } catch (e) {
      print('Error initializing default teacher: $e');
      rethrow;
    }
  }

  // Teacher login with Firestore
  Future<Map<String, dynamic>?> loginTeacher(
      String email, String password) async {
    try {
      // Query teachers collection for matching credentials
      final querySnapshot = await _firestore
          .collection(_teachersCollection)
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final teacherData = querySnapshot.docs.first.data();
        teacherData['id'] = querySnapshot.docs.first.id;
        return teacherData;
      }
      return null;
    } catch (e) {
      print('Error logging in teacher: $e');
      rethrow;
    }
  }

  // Get teacher by ID
  Future<Map<String, dynamic>?> getTeacher(String teacherId) async {
    try {
      final doc =
          await _firestore.collection(_teachersCollection).doc(teacherId).get();
      if (doc.exists) {
        final data = doc.data();
        data?['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting teacher: $e');
      rethrow;
    }
  }

  // Update teacher profile
  Future<void> updateTeacher(
      String teacherId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_teachersCollection)
          .doc(teacherId)
          .update(data);
    } catch (e) {
      print('Error updating teacher: $e');
      rethrow;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_teachersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final exists = await emailExists(email);
      if (exists) {
        throw Exception('Email already in use');
      }

      final docRef = await _firestore.collection(_teachersCollection).add({
        'email': email,
        'password': password,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': false, // Teachers start unverified until admin approves
      });

      final teacherData = {
        'id': docRef.id,
        'email': email,
        'name': name,
        'isActive': true,
        'isVerified': false,
      };

      return teacherData;
    } catch (e) {
      print('Error creating teacher: $e');
      rethrow;
    }
  }

  // Check if teacher is verified
  Future<bool> isTeacherVerified(String teacherId) async {
    try {
      final doc =
          await _firestore.collection(_teachersCollection).doc(teacherId).get();
      if (doc.exists) {
        return doc.data()?['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking teacher verification: $e');
      return false;
    }
  }
}
