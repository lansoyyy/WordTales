import 'package:flutter/material.dart';
import 'package:word_tales/screens/practice_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:word_tales/services/student_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _cardAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  // Track completed levels (initially only level 1 is available)
  int _highestUnlockedLevel = 1;

  // Student information
  String? _studentId;
  String? _studentName;
  final StudentService _studentService = StudentService();

  // Track level completion with scores
  Map<int, Map<String, dynamic>> _levelCompletion = {
    1: {'completed': false, 'score': 0, 'totalItems': 5, 'date': null},
    2: {'completed': false, 'score': 0, 'totalItems': 10, 'date': null},
    3: {'completed': false, 'score': 0, 'totalItems': 15, 'date': null},
    4: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
    5: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
  };

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _cardAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );

    _bounceAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // Load student information from SharedPreferences
  Future<void> _loadStudentInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('student_name');

      if (studentName != null) {
        final student = await _studentService.getStudentByName(
          name: studentName,
          teacherId: 'default_teacher',
        );

        if (mounted) {
          setState(() {
            _studentName = studentName;
            _studentId = student?['id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student info: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Method to unlock next level
  void _unlockNextLevel() {
    setState(() {
      if (_highestUnlockedLevel < 5) {
        _highestUnlockedLevel++;
      }
    });
  }

  // Method to update level completion
  void _updateLevelCompletion(int level, int score, int totalItems) {
    setState(() {
      _levelCompletion[level] = {
        'completed': true,
        'score': score,
        'totalItems': totalItems,
        'date': DateTime.now().toString().split(' ')[0], // Get current date
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Level data with descriptions and emojis
    final List<Map<String, dynamic>> levels = [
      {
        'level': 1,
        'title': 'Level 1',
        'description': '1 Letter Words',
        'emoji': '🔤',
        'icon': Icons.abc,
        'color': Colors.red,
        'gradient': [Colors.red.shade300, Colors.red.shade600],
      },
      {
        'level': 2,
        'title': 'Level 2',
        'description': '2 Letter Words',
        'emoji': '📝',
        'icon': Icons.text_fields,
        'color': Colors.orange,
        'gradient': [Colors.orange.shade300, Colors.orange.shade600],
      },
      {
        'level': 3,
        'title': 'Level 3',
        'description': '3 Letter Words',
        'emoji': '📚',
        'icon': Icons.text_format,
        'color': Colors.yellow,
        'gradient': [Colors.yellow.shade300, Colors.yellow.shade600],
      },
      {
        'level': 4,
        'title': 'Level 4',
        'description': '4 Letter Words',
        'emoji': '📖',
        'icon': Icons.text_snippet,
        'color': Colors.green,
        'gradient': [Colors.green.shade300, Colors.green.shade600],
      },
      {
        'level': 5,
        'title': 'Level 5',
        'description': 'Sentences',
        'emoji': '📄',
        'icon': Icons.article,
        'color': Colors.blue,
        'gradient': [Colors.blue.shade300, Colors.blue.shade600],
      },
    ];

    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    Icons.school,
                    color: white,
                    size: 28.0,
                  ),
                );
              },
            ),
            const SizedBox(width: 8.0),
            TextWidget(
              text: 'WordTales',
              fontSize: 24.0,
              color: white,
              isBold: true,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber[50]!,
              Colors.orange[50]!,
              Colors.yellow[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section with Character
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [white, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(color: secondary, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: grey.withOpacity(0.4),
                              blurRadius: 15.0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 70.0,
                                width: 70.0,
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Hello, Little Learner! 🌟',
                                    fontSize: 26.0,
                                    color: primary,
                                    isBold: true,
                                    fontFamily: 'Regular',
                                  ),
                                  const SizedBox(height: 4.0),
                                  TextWidget(
                                    text:
                                        'Ready for an adventure? Complete levels to unlock more fun! 🚀',
                                    fontSize: 16.0,
                                    color: grey,
                                    isItalize: true,
                                    maxLines: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),

                // Levels Section with animated title
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 28.0,
                          ),
                          const SizedBox(width: 8.0),
                          TextWidget(
                            text: 'Continue Your Adventure!',
                            fontSize: 24.0,
                            color: black,
                            isBold: true,
                            fontFamily: 'Regular',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),

                // Animated floating particles
                SizedBox(
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0, _bounceAnimation.value * (index + 1) * 0.5),
                            child: Icon(
                              Icons.star,
                              color: Colors.amber[400],
                              size: 12.0,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16.0),
                SizedBox(
                  height: 280.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final isUnlocked =
                          level['level'] <= _highestUnlockedLevel;
                      final isCompleted =
                          level['level'] < _highestUnlockedLevel;

                      return ScaleTransition(
                        scale: _cardAnimation,
                        child: Container(
                          width: 200.0,
                          margin: const EdgeInsets.only(right: 16.0),
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUnlocked
                                  ? level['gradient']
                                  : [
                                      grey.withOpacity(0.6),
                                      grey.withOpacity(0.8)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25.0),
                            border: Border.all(
                                color: isUnlocked ? level['color'] : grey,
                                width: 3.0),
                            boxShadow: [
                              BoxShadow(
                                color: grey.withOpacity(0.4),
                                blurRadius: 15.0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Emoji and lock/check icon
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: !isUnlocked
                                    ? Icon(
                                        Icons.lock,
                                        size: 40.0,
                                        color: Colors.white,
                                      )
                                    : isCompleted
                                        ? Icon(
                                            Icons.check_circle,
                                            size: 40.0,
                                            color: Colors.green,
                                          )
                                        : Text(
                                            level['emoji'],
                                            style:
                                                const TextStyle(fontSize: 40.0),
                                          ),
                              ),
                              const SizedBox(height: 12.0),
                              TextWidget(
                                text: level['title'],
                                fontSize: 22.0,
                                color: Colors.white,
                                isBold: true,
                                fontFamily: 'Regular',
                              ),
                              const SizedBox(height: 6.0),
                              TextWidget(
                                text: isCompleted
                                    ? 'Completed! 🎉'
                                    : level['description'],
                                fontSize: 16.0,
                                color: Colors.white,
                                fontFamily: 'Regular',
                                align: TextAlign.center,
                              ),
                              const SizedBox(height: 20.0),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton.icon(
                                  onPressed: isUnlocked
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PracticeScreen(
                                                level: level['level'],
                                                levelTitle: level['title'],
                                                levelDescription:
                                                    level['description'],
                                                studentId: _studentId,
                                                studentName: _studentName,
                                                onLevelCompleted: () {
                                                  if (level['level'] ==
                                                      _highestUnlockedLevel) {
                                                    _unlockNextLevel();
                                                  }
                                                },
                                                onLevelCompletedWithScore:
                                                    (score, totalItems) {
                                                  _updateLevelCompletion(
                                                      level['level'],
                                                      score,
                                                      totalItems);
                                                  if (level['level'] ==
                                                      _highestUnlockedLevel) {
                                                    _unlockNextLevel();
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: Icon(
                                      isUnlocked
                                          ? Icons.play_arrow
                                          : Icons.lock,
                                      color: white,
                                      size: 22.0),
                                  label: TextWidget(
                                    text:
                                        isUnlocked ? 'Start Level!' : 'Locked',
                                    fontSize: 16.0,
                                    color: white,
                                    fontFamily: 'Regular',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isUnlocked ? level['color'] : grey,
                                    foregroundColor: white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    elevation: isUnlocked ? 8.0 : 0.0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 12.0,
                                    ),
                                  ),
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

                // History Section with animated title
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.95 + 0.05,
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.purple[600],
                            size: 28.0,
                          ),
                          const SizedBox(width: 8.0),
                          TextWidget(
                            text: 'Your Learning Journey',
                            fontSize: 24.0,
                            color: black,
                            isBold: true,
                            fontFamily: 'Regular',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),

                // Level completion history with animations
                ...List.generate(5, (levelIndex) {
                  final levelNumber = levelIndex + 1;
                  final levelData = _levelCompletion[levelNumber]!;

                  if (!levelData['completed']) return const SizedBox.shrink();

                  return AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_bounceAnimation.value * 2, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level completion card
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PracticeScreen(
                                      level: levelNumber,
                                      levelTitle: 'Level $levelNumber',
                                      levelDescription: levels[levelIndex]
                                          ['description'],
                                      studentId: _studentId,
                                      studentName: _studentName,
                                      onLevelCompletedWithScore:
                                          (score, totalItems) {
                                        _updateLevelCompletion(
                                            levelNumber, score, totalItems);
                                        if (levelNumber ==
                                            _highestUnlockedLevel) {
                                          _unlockNextLevel();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      white,
                                      levels[levelIndex]['color']
                                          .withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: levels[levelIndex]['color'],
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: grey.withOpacity(0.3),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Level icon and completion status
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            levels[levelIndex]['color']
                                                .withOpacity(0.2),
                                            levels[levelIndex]['color']
                                                .withOpacity(0.4),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 30.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),

                                    // Level info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                levels[levelIndex]['emoji'],
                                                style: const TextStyle(
                                                    fontSize: 20.0),
                                              ),
                                              const SizedBox(width: 8.0),
                                              TextWidget(
                                                text:
                                                    'Level $levelNumber - ${levels[levelIndex]['description']}',
                                                fontSize: 18.0,
                                                color: levels[levelIndex]
                                                    ['color'],
                                                isBold: true,
                                                fontFamily: 'Regular',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8.0),

                                          // Score display with stars
                                          Row(
                                            children: [
                                              Icon(Icons.star,
                                                  color: Colors.yellow,
                                                  size: 18.0),
                                              const SizedBox(width: 6.0),
                                              TextWidget(
                                                text:
                                                    'Score: ${levelData['score']}/${levelData['totalItems']} ⭐',
                                                fontSize: 16.0,
                                                color: primary,
                                                isBold: true,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4.0),

                                          // Completion date
                                          TextWidget(
                                            text:
                                                'Completed on: ${levelData['date']} 📅',
                                            fontSize: 14.0,
                                            color: Colors.black,
                                            fontFamily: 'Regular',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 24.0),

                // Fun bottom decoration
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0, _bounceAnimation.value * (index + 1) * 0.3),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.pink[300],
                                size: 16.0,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
