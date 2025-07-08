import 'package:flutter/material.dart';
import 'package:word_tales/screens/practice_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _cardAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder data for words and sentences
    final List<Map<String, String>> learningItems = [
      {'type': 'Word', 'content': 'Apple'},
      {'type': 'Sentence', 'content': 'The cat is happy'},
      {'type': 'Word', 'content': 'Sun'},
      {'type': 'Sentence', 'content': 'I like to play'},
    ];

    // Placeholder data for history
    final List<Map<String, dynamic>> historyItems = [
      {'content': 'Dog', 'correct': true, 'date': '2025-07-07'},
      {'content': 'The sun shines', 'correct': false, 'date': '2025-07-07'},
      {'content': 'Tree', 'correct': true, 'date': '2025-07-06'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: TextWidget(
          text: 'WordTales',
          fontSize: 24.0,
          color: white,
          isBold: true,
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [white, secondary.withOpacity(0.2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom AppBar

                // Welcome Section with Character
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: secondary, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: grey.withOpacity(0.4),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png', // Replace with actual character image
                        height: 60.0,
                        width: 60.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Hello, Little Learner!',
                              fontSize: 26.0,
                              color: primary,
                              isBold: true,
                              fontFamily: 'Regular',
                            ),
                            TextWidget(
                              text: 'Ready for fun words today?',
                              fontSize: 18.0,
                              color: grey,
                              isItalize: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                // Learn Today Section
                TextWidget(
                  text: 'Learn Today',
                  fontSize: 24.0,
                  color: black,
                  isBold: true,
                  fontFamily: 'Regular',
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 220.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: learningItems.length,
                    itemBuilder: (context, index) {
                      final item = learningItems[index];
                      return ScaleTransition(
                        scale: _cardAnimation,
                        child: Container(
                          width: 180.0,
                          margin: const EdgeInsets.only(right: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: secondary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: primary, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: grey.withOpacity(0.3),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWidget(
                                text: item['type']!,
                                fontSize: 18.0,
                                color: black,
                                isItalize: true,
                                fontFamily: 'Regular',
                              ),
                              const SizedBox(height: 8.0),
                              TextWidget(
                                text: item['content']!,
                                fontSize: 22.0,
                                color: primary,
                                isBold: true,
                                maxLines: 3,
                                fontFamily: 'Regular',
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PracticeScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.mic, color: white, size: 20.0),
                                label: TextWidget(
                                  text: 'Practice',
                                  fontSize: 16.0,
                                  color: white,
                                  fontFamily: 'Regular',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 6.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32.0),
                // History Section
                TextWidget(
                  text: 'Your Learning History',
                  fontSize: 24.0,
                  color: black,
                  isBold: true,
                  fontFamily: 'Regular',
                ),
                const SizedBox(height: 16.0),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyItems.length,
                  itemBuilder: (context, index) {
                    final item = historyItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: secondary, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: grey.withOpacity(0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              item['correct']
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  item['correct'] ? Colors.green : Colors.red,
                              size: 30.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: item['content'],
                                  fontSize: 20.0,
                                  color: black,
                                  isBold: true,
                                  fontFamily: 'Regular',
                                ),
                                TextWidget(
                                  text: 'Practiced on: ${item['date']}',
                                  fontSize: 16.0,
                                  color: grey,
                                  fontFamily: 'Regular',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),
                // Progress Stars
              ],
            ),
          ),
        ),
      ),
    );
  }
}
