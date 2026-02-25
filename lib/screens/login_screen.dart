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

  // Section dropdown - matching teacher sections
  final List<String> _sections = [
    'Apple',
    'Atis',
    'Chico',
    'Durian',
    'Grapes',
    'Guava',
    'Lemon',
    'Makopa',
    'Mango',
    'Melon',
    'Orange',
    'Pear',
    'Pomelo',
    'Strawberry',
    'Tambis',
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
      case 'Atis':
        return '🍈';
      case 'Chico':
        return '🥝';
      case 'Durian':
        return '🥭';
      case 'Grapes':
        return '🍇';
      case 'Guava':
        return '🍐';
      case 'Lemon':
        return '🍋';
      case 'Makopa':
        return '🍑';
      case 'Mango':
        return '🥭';
      case 'Melon':
        return '🍈';
      case 'Orange':
        return '🍊';
      case 'Pear':
        return '🍐';
      case 'Pomelo':
        return '🍊';
      case 'Strawberry':
        return '🍓';
      case 'Tambis':
        return '🍒';
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
      // Get teacher for the selected section
      final teacher = await _authService.getTeacherBySection(_selectedSection!);

      if (teacher == null) {
        Fluttertoast.showToast(
          msg: 'No teacher found for this section',
          backgroundColor: Colors.red,
          textColor: white,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showStudentLoginConfirmationDialog(
        studentName: _studentNameController.text.trim(),
        section: _selectedSection!,
        teacherName: teacher['name'] ?? 'Unknown',
      );

      if (!confirmed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Find or create student for the selected teacher
      await _studentService.findOrCreateStudent(
        name: _studentNameController.text.trim(),
        teacherId: teacher['id'],
        section: _selectedSection!,
      );

      // Save student name and associated teacher to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('student_name', _studentNameController.text.trim());
      await prefs.setString('current_teacher_id', teacher['id']);

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

  // Show confirmation dialog for student login
  Future<bool> _showStudentLoginConfirmationDialog({
    required String studentName,
    required String section,
    required String teacherName,
  }) async {
    final sectionEmoji = _getSectionEmoji(section);
    final sectionDisplay = '$sectionEmoji $section';
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: primary,
                  size: 60.0,
                ),
                const SizedBox(height: 16.0),
                TextWidget(
                  text: 'Confirm Your Details',
                  fontSize: 20.0,
                  color: primary,
                  isBold: true,
                  align: TextAlign.center,
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Name:', studentName),
                  const SizedBox(height: 12.0),
                  _buildDetailRow('Section:', sectionDisplay),
                  const SizedBox(height: 12.0),
                  _buildDetailRow('Teacher:', teacherName),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: TextWidget(
                          text: 'No, Edit',
                          fontSize: 16.0,
                          color: white,
                          isBold: true,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: TextWidget(
                          text: 'Yes, Correct',
                          fontSize: 16.0,
                          color: white,
                          isBold: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  // Build detail row for confirmation dialog
  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 14.0,
          color: grey,
          isBold: true,
        ),
        const SizedBox(height: 4.0),
        TextWidget(
          text: value,
          fontSize: 16.0,
          color: Colors.black87,
        ),
      ],
    );
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
        // Check if teacher account is verified
        final isVerified = teacher['isVerified'] ?? false;

        if (!isVerified) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                title: Column(
                  children: [
                    Icon(Icons.hourglass_empty,
                        color: Colors.orange, size: 60.0),
                    const SizedBox(height: 16.0),
                    TextWidget(
                      text: 'Account Not Verified',
                      fontSize: 20.0,
                      color: primary,
                      isBold: true,
                      align: TextAlign.center,
                    ),
                  ],
                ),
                content: TextWidget(
                  text:
                      'Your account is still pending verification. Please wait for admin approval before you can log in.',
                  fontSize: 16.0,
                  color: grey,
                  align: TextAlign.center,
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: TextWidget(
                        text: 'OK',
                        fontSize: 16.0,
                        color: white,
                        isBold: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }

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
        await prefs.setString('current_teacher_section', teacher['section']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherHomeScreen(
                teacherId: teacher['id'],
                teacherName: teacher['name'],
                teacherSection: teacher['section'],
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
