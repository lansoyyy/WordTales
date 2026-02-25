import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final String _teachersCollection = 'teachers';

  // Predefined teachers with their sections
  static const List<Map<String, String>> predefinedTeachers = [
    {
      'name': 'Jinky B. Talaogon',
      'section': 'Apple',
      'email': 'jinky.talaogon@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Gemma C. Caingin',
      'section': 'Durian',
      'email': 'gemma.caingin@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Ma. Lyric E. Alcantara',
      'section': 'Guava',
      'email': 'lyric.alcantara@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Luilne B. Arcaya',
      'section': 'Makopa',
      'email': 'luilne.arcaya@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Beverly Jane L. Bariquit',
      'section': 'Pear',
      'email': 'beverly.bariquit@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Analie M. Boniao',
      'section': 'Lemon',
      'email': 'analie.boniao@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Mary Jane M. Caay',
      'section': 'Mango',
      'email': 'maryjane.caay@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Thelma E. Callo',
      'section': 'Strawberry',
      'email': 'thelma.callo@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Crispina A. Entero',
      'section': 'Chico',
      'email': 'crispina.entero@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Elsa Q. Guzmana',
      'section': 'Orange',
      'email': 'elsa.guzmana@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Mae B. Lavictoria',
      'section': 'Atis',
      'email': 'mae.lavictoria@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Lovella R. Managatan',
      'section': 'Pomelo',
      'email': 'lovella.managatan@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Hanna Namocot',
      'section': 'Grapes',
      'email': 'hanna.namocot@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Olga G. Quiliman',
      'section': 'Melon',
      'email': 'olga.quiliman@wordtales.com',
      'password': 'teacher123'
    },
    {
      'name': 'Mona P. Yanez',
      'section': 'Tambis',
      'email': 'mona.yanez@wordtales.com',
      'password': 'teacher123'
    },
  ];

  // Initialize all predefined teacher accounts
  Future<void> initializePredefinedTeachers() async {
    try {
      for (final teacher in predefinedTeachers) {
        // Check if teacher already exists by email
        final querySnapshot = await _firestore
            .collection(_teachersCollection)
            .where('email', isEqualTo: teacher['email'])
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Create teacher account
          await _firestore.collection(_teachersCollection).add({
            'email': teacher['email'],
            'password': teacher['password'],
            'name': teacher['name'],
            'section': teacher['section'],
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'isVerified': true, // Pre-verified
          });
          print('Teacher account created: ${teacher['name']}');
        } else {
          print('Teacher already exists: ${teacher['name']}');
        }
      }
      print('All predefined teachers initialized');
    } catch (e) {
      print('Error initializing predefined teachers: $e');
      rethrow;
    }
  }

  // Initialize default teacher account (legacy - kept for compatibility)
  Future<void> initializeDefaultTeacher() async {
    await initializePredefinedTeachers();
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

  // Get teacher by section
  Future<Map<String, dynamic>?> getTeacherBySection(String section) async {
    try {
      final querySnapshot = await _firestore
          .collection(_teachersCollection)
          .where('section', isEqualTo: section)
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
      print('Error getting teacher by section: $e');
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
