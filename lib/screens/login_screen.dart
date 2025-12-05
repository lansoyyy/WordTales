import 'package:flutter/material.dart';
import 'package:word_tales/screens/teacher.home_screen.dart';
import 'package:word_tales/screens/reminder_screen.dart';
import 'package:word_tales/screens/teacher_signup_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:word_tales/services/auth_service.dart';
import 'package:word_tales/services/student_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _showTeacherLogin = false;
  bool _isLoading = false;

  // Section dropdown - fruits from A to G
  final List<String> _sections = [
    'Apple',
    'Banana',
    'Cherry',
    'Durian',
    'Elderberry',
    'Fig',
    'Guava',
  ];
  String? _selectedSection;

  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  // Get emoji for each fruit section
  String _getSectionEmoji(String section) {
    switch (section) {
      case 'Apple':
        return '🍎';
      case 'Banana':
        return '🍌';
      case 'Cherry':
        return '🍒';
      case 'Durian':
        return '🥭';
      case 'Elderberry':
        return '🫐';
      case 'Fig':
        return '🍇';
      case 'Guava':
        return '🍐';
      default:
        return '🍎';
    }
  }

  // Handle student login/creation
  Future<void> _handleStudentLogin() async {
    if (_studentNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter student name',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    if (_selectedSection == null) {
      Fluttertoast.showToast(
        msg: 'Please select a section',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine which teacher this student belongs to.
      // If a teacher has logged in on this device, we use that teacher's ID.
      // Otherwise, fall back to the original 'default_teacher'.
      final prefs = await SharedPreferences.getInstance();
      final String selectedTeacherId =
          prefs.getString('current_teacher_id') ?? 'default_teacher';

      // Find or create student for the selected teacher
      await _studentService.findOrCreateStudent(
        name: _studentNameController.text.trim(),
        teacherId: selectedTeacherId,
        section: _selectedSection!,
      );

      // Save student name and associated teacher to SharedPreferences
      await prefs.setString('student_name', _studentNameController.text.trim());
      await prefs.setString('current_teacher_id', selectedTeacherId);

      Fluttertoast.showToast(
        msg: 'Welcome back, ${_studentNameController.text}!',
        backgroundColor: Colors.green,
        textColor: white,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReminderScreen()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle teacher login
  Future<void> _handleTeacherLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter email and password',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teacher = await _authService.loginTeacher(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (teacher != null) {
        Fluttertoast.showToast(
          msg: 'Welcome ${teacher['name']}!',
          backgroundColor: Colors.green,
          textColor: white,
        );

        // Persist current teacher so student logins and HomeScreen
        // can associate students with the correct teacher.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_teacher_id', teacher['id']);
        await prefs.setString('current_teacher_name', teacher['name']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherHomeScreen(
                teacherId: teacher['id'],
                teacherName: teacher['name'],
              ),
            ),
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid email or password',
          backgroundColor: Colors.red,
          textColor: white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png', // Replace with actual logo path
                height: 250.0,
                width: 250.0,
              ),

              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Learn words and sentences with fun!',
                fontSize: 18.0,
                color: grey,
                isItalize: true,
              ),
              const SizedBox(height: 48.0),
              // Teacher login fields (shown only when Continue as Teacher is clicked)
              if (!_showTeacherLogin) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: _studentNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: white,
                      hintText: 'Student Name',
                      hintStyle: TextStyle(color: grey, fontFamily: 'Regular'),
                      prefixIcon: Icon(Icons.person, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: primary, width: 2.0),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                  ),
                ),
                // Section dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    hint: TextWidget(
                      text: 'Select Section',
                      fontSize: 16.0,
                      color: grey,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: white,
                      prefixIcon: Icon(Icons.class_, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: primary, width: 2.0),
                      ),
                    ),
                    items: _sections.map((section) {
                      return DropdownMenuItem<String>(
                        value: section,
                        child: Row(
                          children: [
                            Text(
                              _getSectionEmoji(section),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            TextWidget(
                              text: section,
                              fontSize: 16.0,
                              color: black,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSection = value;
                      });
                    },
                  ),
                ),
              ],
              if (_showTeacherLogin) ...[
                TextField(
                  controller: _emailController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: white,
                    hintText: 'Teacher Email',
                    hintStyle: TextStyle(color: grey, fontFamily: 'Regular'),
                    prefixIcon: Icon(Icons.email, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: primary, width: 2.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  onChanged: (value) {
                    setState(() {});
                  },
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: white,
                    hintText: 'Password',
                    hintStyle: TextStyle(color: grey, fontFamily: 'Regular'),
                    prefixIcon: Icon(Icons.lock, color: primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: primary, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
              // Continue button for kids
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _showTeacherLogin
                        ? () {
                            setState(() {
                              _showTeacherLogin = false;
                            });
                          }
                        : (_studentNameController.text.trim().isEmpty ||
                                _selectedSection == null)
                            ? null
                            : _handleStudentLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: black,
                  minimumSize: const Size(double.infinity, 60.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading && !_showTeacherLogin
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: black,
                          strokeWidth: 2,
                        ),
                      )
                    : TextWidget(
                        text: _showTeacherLogin ? 'Student Login' : 'Continue',
                        fontSize: 20.0,
                        color: black,
                        isBold: true,
                      ),
              ),
              const SizedBox(height: 16.0),
              // Continue as Teacher button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _showTeacherLogin
                        ? _emailController.text.trim().isEmpty ||
                                _passwordController.text.trim().isEmpty
                            ? null
                            : _handleTeacherLogin
                        : () {
                            setState(() {
                              _showTeacherLogin = true;
                            });
                          },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: white,
                  minimumSize: const Size(double.infinity, 60.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading && _showTeacherLogin
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: white,
                          strokeWidth: 2,
                        ),
                      )
                    : TextWidget(
                        text: _showTeacherLogin
                            ? 'Continue as Teacher'
                            : 'Teacher Login',
                        fontSize: 20.0,
                        color: white,
                        isBold: true,
                      ),
              ),
              if (_showTeacherLogin) ...[
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherSignupScreen(),
                            ),
                          );
                        },
                  child: TextWidget(
                    text: 'Create a new teacher account',
                    fontSize: 14.0,
                    color: primary,
                    isItalize: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
