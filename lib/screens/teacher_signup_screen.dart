import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
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

  // ID Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _frontIdImage;
  File? _backIdImage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickFrontIdImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _frontIdImage = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking image: $e',
        backgroundColor: Colors.red,
        textColor: white,
      );
    }
  }

  Future<void> _pickBackIdImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _backIdImage = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking image: $e',
        backgroundColor: Colors.red,
        textColor: white,
      );
    }
  }

  Widget _buildIdImagePicker({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: image != null ? Colors.green : grey,
            width: image != null ? 2.0 : 1.0,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: white, size: 16),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: white,
                            fontFamily: 'Regular',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: grey),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: grey,
                      fontFamily: 'Regular',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      color: grey,
                      fontFamily: 'Regular',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
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

    if (_frontIdImage == null || _backIdImage == null) {
      Fluttertoast.showToast(
        msg: 'Please upload both front and back of your ID',
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

      if (!mounted) return;

      // Show success dialog - account pending verification
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 60.0),
              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Account Pending Verification',
                fontSize: 20.0,
                color: primary,
                isBold: true,
                align: TextAlign.center,
              ),
            ],
          ),
          content: TextWidget(
            text:
                'Your account has been created successfully. Please wait for admin verification before you can log in. This usually takes 1-2 business days.',
            fontSize: 16.0,
            color: grey,
            align: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to login
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

              // ID Verification Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.badge, color: primary, size: 24),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'ID Verification',
                          fontSize: 18.0,
                          color: primary,
                          isBold: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text:
                          'Please upload clear photos of your valid ID (front and back) for verification.',
                      fontSize: 14.0,
                      color: grey,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildIdImagePicker(
                            label: 'ID Front',
                            image: _frontIdImage,
                            onTap: _pickFrontIdImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildIdImagePicker(
                            label: 'ID Back',
                            image: _backIdImage,
                            onTap: _pickBackIdImage,
                          ),
                        ),
                      ],
                    ),
                  ],
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
