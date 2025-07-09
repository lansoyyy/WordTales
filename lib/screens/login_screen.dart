import 'package:flutter/material.dart';
import 'package:word_tales/screens/home_screen.dart';
import 'package:word_tales/screens/teacher.home_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.only(bottom: 20),
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
                    keyboardType: TextInputType.emailAddress,
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
              Visibility(
                visible: !_showTeacherLogin,
                child: ElevatedButton(
                  onPressed: _studentNameController.text == ''
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: black,
                    minimumSize: const Size(double.infinity, 60.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: TextWidget(
                    text: 'Continue',
                    fontSize: 20.0,
                    color: black,
                    isBold: true,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Continue as Teacher button
              ElevatedButton(
                onPressed: _showTeacherLogin
                    ? _emailController.text == '' ||
                            _passwordController.text == ''
                        ? null
                        : () {
                            if (_showTeacherLogin) {
                              // Handle teacher login logic here
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const TeacherHomeScreen()),
                              );
                            } else {
                              setState(() {
                                _showTeacherLogin = true;
                              });
                            }
                          }
                    : () {
                        if (_showTeacherLogin) {
                          // Handle teacher login logic here
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TeacherHomeScreen()),
                          );
                        } else {
                          setState(() {
                            _showTeacherLogin = true;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: white,
                  minimumSize: const Size(double.infinity, 60.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: TextWidget(
                  text: _showTeacherLogin
                      ? 'Continue as Teacher'
                      : 'Teacher Login',
                  fontSize: 20.0,
                  color: white,
                  isBold: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
