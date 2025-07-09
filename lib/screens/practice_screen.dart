import 'package:flutter/material.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

class PracticeScreen extends StatefulWidget {
  bool? isTeacher;

  PracticeScreen({this.isTeacher = false});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> practiceItems = [
    {'type': 'Word', 'content': 'Apple'},
    {'type': 'Sentence', 'content': 'The cat is happy'},
    {'type': 'Word', 'content': 'Sun'},
    {'type': 'Sentence', 'content': 'I like to play'},
  ];
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextItem() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % practiceItems.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = practiceItems[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [white, secondary.withOpacity(0.3)],
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: primary,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: white, size: 30.0),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: TextWidget(
                        text: 'Practice Time!',
                        fontSize: 28.0,
                        color: white,
                        isBold: true,
                        // Note: Replace 'Regular' with a kid-friendly font like 'Comic Sans' or a custom font asset
                        fontFamily: 'Regular',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: widget.isTeacher!,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextWidget(
                  text: 'Emma Watson',
                  fontSize: 24.0,
                  color: primary,
                  isBold: true,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: currentItem['type']!,
                      fontSize: 24.0,
                      color: primary,
                      isItalize: true,
                      isBold: true,
                    ),
                    const SizedBox(height: 24.0),
                    // Word/Sentence Card with Stars
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Star Decorations
                        Positioned(
                          top: -20,
                          left: 0,
                          child: Icon(Icons.star, color: secondary, size: 40.0),
                        ),
                        Positioned(
                          bottom: -20,
                          right: 0,
                          child: Icon(Icons.star, color: secondary, size: 40.0),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: grey.withOpacity(0.4),
                                blurRadius: 12.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: secondary, width: 3.0),
                          ),
                          child: TextWidget(
                            text: currentItem['content']!,
                            fontSize: 36.0,
                            color: primary,
                            isBold: true,
                            maxLines: 3,
                            align: TextAlign.center,
                            // Note: Replace 'Regular' with a kid-friendly font
                            fontFamily: 'Regular',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),
                    // Placeholder Feedback Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: grey.withOpacity(0.5)),
                      ),
                      child: widget.isTeacher!
                          ? TextWidget(
                              text: 'Result:',
                              fontSize: 18,
                              fontFamily: 'Bold',
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: primary, size: 30.0),
                                const SizedBox(width: 8.0),
                                TextWidget(
                                  text: 'Say it loud!',
                                  fontSize: 20.0,
                                  color: black,
                                  isBold: true,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48.0),
                    // Practice Button with Animation
                    Visibility(
                      visible: !widget.isTeacher!,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for speech-to-text action
                          },
                          icon: Icon(Icons.mic, color: white, size: 28.0),
                          label: TextWidget(
                            text: 'Practice',
                            fontSize: 24.0,
                            color: white,
                            isBold: true,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: white,
                            minimumSize: const Size(double.infinity, 70.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 8.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Next Button
                    OutlinedButton.icon(
                      onPressed: _nextItem,
                      icon: Icon(Icons.arrow_forward,
                          color: secondary, size: 28.0),
                      label: TextWidget(
                        text: 'Next',
                        fontSize: 24.0,
                        color: secondary,
                        isBold: true,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        side: BorderSide(color: secondary, width: 3.0),
                        minimumSize: const Size(double.infinity, 70.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Progress Stars
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
