import 'package:flutter/material.dart';
import 'package:word_tales/screens/home_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

class PracticeScreen extends StatefulWidget {
  bool? isTeacher;
  int? level;
  String? levelTitle;
  String? levelDescription;
  VoidCallback? onLevelCompleted;
  Function(int score, int totalItems)? onLevelCompletedWithScore;

  PracticeScreen({
    this.isTeacher = false,
    this.level,
    this.levelTitle,
    this.levelDescription,
    this.onLevelCompleted,
    this.onLevelCompletedWithScore,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late List<Map<String, String>> practiceItems;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _celebrationAnimation;

  // Track completed items and score
  Set<int> _completedItems = {};
  int _score = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _initializePracticeItems();
    _totalItems = practiceItems.length;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.bounceOut),
    );
  }

  void _initializePracticeItems() {
    // Initialize practice items based on level
    switch (widget.level) {
      case 1:
        practiceItems = [
          {'type': 'Word', 'content': 'A', 'emoji': '🔤'},
          {'type': 'Word', 'content': 'I', 'emoji': '📝'},
          {'type': 'Word', 'content': 'O', 'emoji': '📚'},
          {'type': 'Word', 'content': 'U', 'emoji': '📖'},
          {'type': 'Word', 'content': 'E', 'emoji': '📄'},
        ];
        break;
      case 2:
        practiceItems = [
          {'type': 'Word', 'content': 'AT', 'emoji': '🐱'},
          {'type': 'Word', 'content': 'IT', 'emoji': '🐶'},
          {'type': 'Word', 'content': 'ON', 'emoji': '☀️'},
          {'type': 'Word', 'content': 'UP', 'emoji': '⬆️'},
          {'type': 'Word', 'content': 'IN', 'emoji': '🏠'},
          {'type': 'Word', 'content': 'GO', 'emoji': '🚶'},
          {'type': 'Word', 'content': 'TO', 'emoji': '🎯'},
          {'type': 'Word', 'content': 'DO', 'emoji': '✅'},
          {'type': 'Word', 'content': 'NO', 'emoji': '❌'},
          {'type': 'Word', 'content': 'SO', 'emoji': '✨'},
        ];
        break;
      case 3:
        practiceItems = [
          {'type': 'Word', 'content': 'CAT', 'emoji': '🐱'},
          {'type': 'Word', 'content': 'DOG', 'emoji': '🐶'},
          {'type': 'Word', 'content': 'SUN', 'emoji': '☀️'},
          {'type': 'Word', 'content': 'RUN', 'emoji': '🏃'},
          {'type': 'Word', 'content': 'BIG', 'emoji': '🐘'},
          {'type': 'Word', 'content': 'RED', 'emoji': '🔴'},
          {'type': 'Word', 'content': 'BLUE', 'emoji': '🔵'},
          {'type': 'Word', 'content': 'HOT', 'emoji': '🔥'},
          {'type': 'Word', 'content': 'COLD', 'emoji': '❄️'},
          {'type': 'Word', 'content': 'NEW', 'emoji': '🆕'},
          {'type': 'Word', 'content': 'OLD', 'emoji': '👴'},
          {'type': 'Word', 'content': 'BAD', 'emoji': '😞'},
          {'type': 'Word', 'content': 'GOOD', 'emoji': '😊'},
          {'type': 'Word', 'content': 'FUN', 'emoji': '🎉'},
          {'type': 'Word', 'content': 'SAD', 'emoji': '😢'},
        ];
        break;
      case 4:
        practiceItems = [
          {'type': 'Word', 'content': 'TREE', 'emoji': '🌳'},
          {'type': 'Word', 'content': 'BOOK', 'emoji': '📚'},
          {'type': 'Word', 'content': 'PLAY', 'emoji': '🎮'},
          {'type': 'Word', 'content': 'JUMP', 'emoji': '🦘'},
          {'type': 'Word', 'content': 'WALK', 'emoji': '🚶'},
          {'type': 'Word', 'content': 'TALK', 'emoji': '💬'},
          {'type': 'Word', 'content': 'READ', 'emoji': '📖'},
          {'type': 'Word', 'content': 'WRITE', 'emoji': '✍️'},
          {'type': 'Word', 'content': 'DRAW', 'emoji': '🎨'},
          {'type': 'Word', 'content': 'SING', 'emoji': '🎤'},
          {'type': 'Word', 'content': 'DANCE', 'emoji': '💃'},
          {'type': 'Word', 'content': 'SWIM', 'emoji': '🏊'},
          {'type': 'Word', 'content': 'FISH', 'emoji': '🐟'},
          {'type': 'Word', 'content': 'BIRD', 'emoji': '🐦'},
          {'type': 'Word', 'content': 'FROG', 'emoji': '🐸'},
          {'type': 'Word', 'content': 'DUCK', 'emoji': '🦆'},
          {'type': 'Word', 'content': 'BEAR', 'emoji': '🐻'},
          {'type': 'Word', 'content': 'LION', 'emoji': '🦁'},
          {'type': 'Word', 'content': 'TIGER', 'emoji': '🐯'},
          {'type': 'Word', 'content': 'HORSE', 'emoji': '🐴'},
        ];
        break;
      case 5:
        practiceItems = [
          {'type': 'Sentence', 'content': 'The cat is happy', 'emoji': '🐱😊'},
          {'type': 'Sentence', 'content': 'I like to play', 'emoji': '🎮'},
          {
            'type': 'Sentence',
            'content': 'The sun shines bright',
            'emoji': '☀️✨'
          },
          {'type': 'Sentence', 'content': 'We can run fast', 'emoji': '🏃💨'},
          {
            'type': 'Sentence',
            'content': 'The dog barks loud',
            'emoji': '🐶🔊'
          },
          {
            'type': 'Sentence',
            'content': 'I love to read books',
            'emoji': '📚❤️'
          },
          {
            'type': 'Sentence',
            'content': 'The bird sings sweetly',
            'emoji': '🐦🎵'
          },
          {
            'type': 'Sentence',
            'content': 'We play in the park',
            'emoji': '🎮🌳'
          },
          {
            'type': 'Sentence',
            'content': 'The fish swims in water',
            'emoji': '🐟💧'
          },
          {
            'type': 'Sentence',
            'content': 'I eat my breakfast',
            'emoji': '🍳🍽️'
          },
          {
            'type': 'Sentence',
            'content': 'The tree grows tall',
            'emoji': '🌳📏'
          },
          {'type': 'Sentence', 'content': 'We walk to school', 'emoji': '🚶🏫'},
          {
            'type': 'Sentence',
            'content': 'The flower smells nice',
            'emoji': '🌸👃'
          },
          {'type': 'Sentence', 'content': 'I draw a picture', 'emoji': '🎨🖼️'},
          {'type': 'Sentence', 'content': 'The moon is bright', 'emoji': '🌙✨'},
          {'type': 'Sentence', 'content': 'We sing a song', 'emoji': '🎤🎵'},
          {'type': 'Sentence', 'content': 'The car goes fast', 'emoji': '🚗💨'},
          {'type': 'Sentence', 'content': 'I write my name', 'emoji': '✍️📝'},
          {
            'type': 'Sentence',
            'content': 'The ball bounces high',
            'emoji': '⚽⬆️'
          },
          {'type': 'Sentence', 'content': 'We dance together', 'emoji': '💃🕺'},
        ];
        break;
      default:
        practiceItems = [
          {'type': 'Word', 'content': 'CAT', 'emoji': '🐱'},
          {'type': 'Word', 'content': 'DOG', 'emoji': '🐶'},
          {'type': 'Sentence', 'content': 'The cat is happy', 'emoji': '🐱😊'},
        ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _nextItem() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % practiceItems.length;
    });
  }

  void _markCurrentItemAsCompleted() {
    setState(() {
      _completedItems.add(_currentIndex);
      _score += 10; // Add 10 points for each completed item

      // Check if all items are completed
      if (_completedItems.length == practiceItems.length) {
        // Level completed!
        _showLevelCompletedDialog();
      }
    });
  }

  void _showLevelCompletedDialog() {
    _celebrationController.forward();
    final bool isLastLevel = widget.level == 5;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLastLevel
                    ? [
                        Colors.purple.shade100,
                        Colors.pink.shade100,
                        Colors.orange.shade100,
                      ]
                    : [
                        Colors.orange.shade100,
                        Colors.yellow.shade100,
                        Colors.pink.shade100,
                      ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated celebration icon
                AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _celebrationAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLastLevel
                                ? [Colors.purple, Colors.pink]
                                : [Colors.orange, Colors.yellow],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isLastLevel ? Colors.purple : Colors.orange).withOpacity(0.5),
                              blurRadius: 20.0,
                              spreadRadius: 5.0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isLastLevel ? Icons.emoji_events : Icons.celebration,
                          color: white,
                          size: 50.0,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),

                // Congratulations text with emoji
                TextWidget(
                  text: isLastLevel ? '🏆 AMAZING! 🏆' : '🎉 Congratulations! 🎉',
                  fontSize: 32.0,
                  color: primary,
                  isBold: true,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextWidget(
                  text: isLastLevel 
                      ? 'You completed ALL levels! You are a reading champion! 🌟'
                      : 'You completed ${widget.levelTitle}! 🌟',
                  fontSize: 22.0,
                  color: black,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Score display with stars
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [white, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: primary, width: 3.0),
                    boxShadow: [
                      BoxShadow(
                        color: grey.withOpacity(0.3),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.yellow, size: 28.0),
                      const SizedBox(width: 12.0),
                      TextWidget(
                        text: 'Score: $_score/$_totalItems ⭐',
                        fontSize: 20.0,
                        color: primary,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                // Animated stars row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              0, _bounceAnimation.value * (index + 1) * 0.3),
                          child: Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 40.0,
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 32.0),

                // Special message for last level or next level unlocked
                if (!isLastLevel) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.2),
                                Colors.green.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: Colors.green, width: 3.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open,
                                  color: Colors.green, size: 28.0),
                              const SizedBox(width: 12.0),
                              TextWidget(
                                text: 'Next level unlocked! 🔓',
                                fontSize: 18.0,
                                color: Colors.green,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Special celebration for completing all levels
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.2),
                                Colors.pink.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: Colors.purple, width: 3.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events,
                                  color: Colors.purple, size: 28.0),
                              const SizedBox(width: 12.0),
                              TextWidget(
                                text: 'Reading Champion! 🏆',
                                fontSize: 18.0,
                                color: Colors.purple,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32.0),

                // Continue button with gradient
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      
                      if (isLastLevel) {
                        // Navigate to home screen for last level
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      } else {
                        // Go back to home screen for other levels
                        Navigator.of(context).pop();
                      }
                      
                      // Call the callback to unlock next level with score
                      widget.onLevelCompletedWithScore?.call(_score, _totalItems);
                      widget.onLevelCompleted?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastLevel ? Colors.purple : primary,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 8.0,
                    ),
                    child: TextWidget(
                      text: isLastLevel ? 'Go to Home! 🏠' : 'Continue Adventure! 🚀',
                      fontSize: 20.0,
                      color: white,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = practiceItems[_currentIndex];
    final isCurrentItemCompleted = _completedItems.contains(_currentIndex);

    return Scaffold(
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom AppBar with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(25.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: grey.withOpacity(0.3),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: IconButton(
                          icon:
                              Icon(Icons.arrow_back, color: white, size: 30.0),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: SizedBox(
                          height: 80,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: TextWidget(
                                      text:
                                          widget.levelTitle ?? 'Practice Time!',
                                      fontSize: 26.0,
                                      color: white,
                                      isBold: true,
                                      fontFamily: 'Regular',
                                    ),
                                  );
                                },
                              ),
                              if (widget.levelDescription != null)
                                TextWidget(
                                  text: widget.levelDescription!,
                                  fontSize: 16.0,
                                  color: white.withOpacity(0.9),
                                  fontFamily: 'Regular',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Teacher name section
              Visibility(
                visible: widget.isTeacher!,
                child: Container(
                  margin: const EdgeInsets.only(top: 16.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade100, Colors.purple.shade200],
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.purple, width: 2.0),
                  ),
                  child: TextWidget(
                    text: '👩‍🏫 Emma Watson',
                    fontSize: 24.0,
                    color: Colors.purple.shade800,
                    isBold: true,
                  ),
                ),
              ),

              SizedBox(
                height: 1000,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated type label
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_bounceAnimation.value * 2, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primary.withOpacity(0.1),
                                    primary.withOpacity(0.2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(color: primary, width: 2.0),
                              ),
                              child: TextWidget(
                                text: currentItem['type']!,
                                fontSize: 24.0,
                                color: primary,
                                isItalize: true,
                                isBold: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32.0),

                      // Word/Sentence Card with enhanced animations
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated floating stars
                          Positioned(
                            top: -30,
                            left: 20,
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _bounceAnimation.value * 2),
                                  child: Icon(Icons.star,
                                      color: Colors.amber[400], size: 30.0),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            right: 20,
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _bounceAnimation.value * 2),
                                  child: Icon(Icons.star,
                                      color: Colors.amber[400], size: 30.0),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: -20,
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_bounceAnimation.value * 2, 0),
                                  child: Icon(Icons.favorite,
                                      color: Colors.pink[300], size: 20.0),
                                );
                              },
                            ),
                          ),

                          // Main content card
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            padding: const EdgeInsets.all(40.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCurrentItemCompleted
                                    ? [
                                        Colors.green.shade100,
                                        Colors.green.shade200
                                      ]
                                    : [white, Colors.blue.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                              boxShadow: [
                                BoxShadow(
                                  color: grey.withOpacity(0.4),
                                  blurRadius: 20.0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                  color: isCurrentItemCompleted
                                      ? Colors.green
                                      : primary,
                                  width: 4.0),
                            ),
                            child: Column(
                              children: [
                                // Emoji display
                                Text(
                                  currentItem['emoji']!,
                                  style: const TextStyle(fontSize: 50.0),
                                ),
                                const SizedBox(height: 16.0),

                                // Content text
                                TextWidget(
                                  text: currentItem['content']!,
                                  fontSize: 42.0,
                                  color: primary,
                                  isBold: true,
                                  maxLines: 3,
                                  align: TextAlign.center,
                                  fontFamily: 'Regular',
                                ),

                                if (isCurrentItemCompleted)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16.0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green,
                                          Colors.green.shade600
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: white, size: 24.0),
                                        const SizedBox(width: 8.0),
                                        TextWidget(
                                          text: 'Completed! 🎉',
                                          fontSize: 16.0,
                                          color: white,
                                          isBold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40.0),

                      // Enhanced progress indicator
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < practiceItems.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                width: 16.0,
                                height: 16.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _completedItems.contains(i)
                                      ? Colors.green
                                      : i == _currentIndex
                                          ? primary
                                          : grey.withOpacity(0.3),
                                  boxShadow: i == _currentIndex
                                      ? [
                                          BoxShadow(
                                            color: primary.withOpacity(0.5),
                                            blurRadius: 8.0,
                                            spreadRadius: 2.0,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Enhanced feedback area
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [white, Colors.blue.shade50],
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                              color: grey.withOpacity(0.3), width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: grey.withOpacity(0.2),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Icon(Icons.mic,
                                            color: primary, size: 32.0),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12.0),
                                  TextWidget(
                                    text: 'Say it loud! 🗣️',
                                    fontSize: 22.0,
                                    color: black,
                                    isBold: true,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 40.0),

                      // Practice Button with enhanced animation
                      Visibility(
                        visible: !widget.isTeacher!,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: ElevatedButton.icon(
                            onPressed: isCurrentItemCompleted
                                ? null
                                : () {
                                    _markCurrentItemAsCompleted();
                                  },
                            icon: Icon(
                                isCurrentItemCompleted
                                    ? Icons.check
                                    : Icons.mic,
                                color: white,
                                size: 32.0),
                            label: TextWidget(
                              text: isCurrentItemCompleted
                                  ? 'Completed! 🎉'
                                  : 'Practice Now! 🎤',
                              fontSize: 24.0,
                              color: white,
                              isBold: true,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentItemCompleted
                                  ? Colors.green
                                  : primary,
                              foregroundColor: white,
                              minimumSize: const Size(double.infinity, 80.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              elevation: isCurrentItemCompleted ? 0.0 : 10.0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Next Button with enhanced design
                      OutlinedButton.icon(
                        onPressed: _nextItem,
                        icon: Icon(Icons.arrow_forward,
                            color: secondary, size: 32.0),
                        label: TextWidget(
                          text: 'Next Item ➡️',
                          fontSize: 24.0,
                          color: secondary,
                          isBold: true,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondary,
                          side: BorderSide(color: secondary, width: 3.0),
                          minimumSize: const Size(double.infinity, 80.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Fun bottom decoration
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return AnimatedBuilder(
                              animation: _bounceController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0,
                                      _bounceAnimation.value *
                                          (index + 1) *
                                          0.4),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.pink[300],
                                      size: 18.0,
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
            ],
          ),
        ),
      ),
    );
  }
}
