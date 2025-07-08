import 'package:flutter/material.dart';
import 'package:word_tales/screens/login_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/utils/const.dart';
import 'package:word_tales/widgets/text_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to next screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Image.asset(
                logo,
              ),
            ),
            const SizedBox(height: 16.0),
            TextWidget(
              text: 'Fun Learning for Kids',
              fontSize: 24.0,
              color: secondary,
              isItalize: true,
            ),
            const SizedBox(height: 32.0),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondary),
            ),
          ],
        ),
      ),
    );
  }
}
