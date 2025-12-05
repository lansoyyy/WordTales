import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:word_tales/screens/teacher.home_screen.dart';
import 'package:word_tales/services/auth_service.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

class TeacherSignupScreen extends StatefulWidget {
  const TeacherSignupScreen({super.key});

  @override
  State<TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all fields',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    if (password.length < 6) {
      Fluttertoast.showToast(
        msg: 'Password must be at least 6 characters',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: 'Passwords do not match',
        backgroundColor: Colors.red,
        textColor: white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teacher = await _authService.createTeacher(
        name: name,
        email: email,
        password: password,
      );

      Fluttertoast.showToast(
        msg: 'Teacher account created successfully',
        backgroundColor: Colors.green,
        textColor: white,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherHomeScreen(
            teacherId: teacher['id'],
            teacherName: teacher['name'],
          ),
        ),
      );
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
      appBar: AppBar(
        backgroundColor: primary,
        title: TextWidget(
          text: 'Teacher Sign Up',
          fontSize: 20.0,
          color: white,
          isBold: true,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 150.0,
                  width: 150.0,
                ),
              ),
              const SizedBox(height: 24.0),
              TextWidget(
                text: 'Create a new teacher account',
                fontSize: 18.0,
                color: grey,
                isItalize: true,
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Full Name',
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
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Email',
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
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Confirm Password',
                  hintStyle: TextStyle(color: grey, fontFamily: 'Regular'),
                  prefixIcon: Icon(Icons.lock_outline, color: primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
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
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: white,
                  minimumSize: const Size(double.infinity, 60.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: white,
                          strokeWidth: 2,
                        ),
                      )
                    : TextWidget(
                        text: 'Create Account',
                        fontSize: 20.0,
                        color: white,
                        isBold: true,
                      ),
              ),
              const SizedBox(height: 12.0),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: TextWidget(
                    text: 'Back to Login',
                    fontSize: 14.0,
                    color: primary,
                    isItalize: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
