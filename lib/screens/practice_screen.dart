import 'package:flutter/material.dart';
import 'package:word_tales/screens/home_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:word_tales/services/filipino_pronunciation_service.dart';
import 'package:word_tales/utils/words.dart';
import 'package:word_tales/services/student_service.dart';
import 'package:word_tales/services/auth_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class PracticeScreen extends StatefulWidget {
  bool? isTeacher;
  int? level;
  String? levelTitle;
  String? levelDescription;
  String? studentId;
  String? studentName;
  VoidCallback? onLevelCompleted;
  Function(int score, int totalItems)? onLevelCompletedWithScore;

  PracticeScreen({
    this.isTeacher = false,
    this.level,
    this.levelTitle,
    this.levelDescription,
    this.studentId,
    this.studentName,
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
  Set<int> _failedItems = {};
  int _score = 0;
  int _totalItems = 0;
  bool _isReviewMode = false;

  // Speech to Text state
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  double _confidence = 0.0;
  double _soundLevel = 0.0;
  String? _selectedLocaleId;

  // Incorrect pronunciation tracking
  int _incorrectAttempts = 0;
  bool _showIncorrectFeedback = false;
  Timer? _incorrectFeedbackTimer;
  List<String> _characterFeedback = [];

  // Services
  final StudentService _studentService = StudentService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasListenedCurrentItem = false;

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

    _loadExistingProgress();
    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  void _initializePracticeItems() {
    // Initialize practice items based on level using words from words.dart
    practiceItems = [];

    switch (widget.level) {
      case 1:
        // Use 1-letter words
        for (int i = 0; i < oneLetterWords.length && i < 10; i++) {
          practiceItems.add({
            'type': 'Word',
            'content': oneLetterWords[i],
            'emoji': _getEmojiForLetter(oneLetterWords[i]),
          });
        }
        break;
      case 2:
        // Use 2-letter words
        for (int i = 0; i < twoLetterWords.length && i < 15; i++) {
          practiceItems.add({
            'type': 'Word',
            'content': twoLetterWords[i],
            'emoji': _getEmojiForWord(twoLetterWords[i]),
          });
        }
        break;
      case 3:
        // Use 3-letter words
        for (int i = 0; i < threeLetterWords.length && i < 20; i++) {
          practiceItems.add({
            'type': 'Word',
            'content': threeLetterWords[i],
            'emoji': _getEmojiForWord(threeLetterWords[i]),
          });
        }
        break;
      case 4:
        // Use 4-letter words
        for (int i = 0; i < fourLetterWords.length && i < 25; i++) {
          practiceItems.add({
            'type': 'Word',
            'content': fourLetterWords[i],
            'emoji': _getEmojiForWord(fourLetterWords[i]),
          });
        }
        break;
      case 5:
        // For level 5, we'll create simple sentences using the words
        practiceItems = _createSimpleSentences();
        break;
      default:
        // Default to some common words
        practiceItems = [
          {'type': 'Word', 'content': 'CAT', 'emoji': '🐱'},
          {'type': 'Word', 'content': 'DOG', 'emoji': '🐶'},
          {'type': 'Word', 'content': 'SUN', 'emoji': '☀️'},
        ];
    }
  }

  String _getEmojiForLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return '🍎';
      case 'B':
        return '🐝';
      case 'C':
        return '🌙';
      case 'D':
        return '🦋';
      case 'E':
        return '🥚';
      case 'F':
        return '🌺';
      case 'G':
        return '🍇';
      case 'H':
        return '🏠';
      case 'I':
        return '🧊';
      case 'J':
        return '🪨';
      case 'K':
        return '🔑';
      case 'L':
        return '🍃';
      case 'M':
        return '🌙';
      case 'N':
        return '🌰';
      case 'O':
        return '⭕';
      case 'P':
        return '🌻';
      case 'Q':
        return '👑';
      case 'R':
        return '🌹';
      case 'S':
        return '☀️';
      case 'T':
        return '🌳';
      case 'U':
        return '☂️';
      case 'V':
        return '🦅';
      case 'W':
        return '💧';
      case 'X':
        return '❌';
      case 'Y':
        return '🧵';
      case 'Z':
        return '⚡';
      default:
        return '🔤';
    }
  }

  String _getEmojiForWord(String word) {
    // Common word to emoji mappings
    switch (word.toUpperCase()) {
      // Animals
      case 'CAT':
        return '🐱';
      case 'DOG':
        return '🐶';
      case 'BIRD':
        return '🐦';
      case 'FISH':
        return '🐟';
      case 'FROG':
        return '🐸';
      case 'DUCK':
        return '🦆';
      case 'BEAR':
        return '🐻';
      case 'LION':
        return '🦁';
      case 'TIGER':
        return '🐯';
      case 'HORSE':
        return '🐴';

      // Nature
      case 'SUN':
        return '☀️';
      case 'TREE':
        return '🌳';
      case 'MOON':
        return '🌙';
      case 'STAR':
        return '⭐';
      case 'RAIN':
        return '🌧️';
      case 'SNOW':
        return '❄️';
      case 'WIND':
        return '💨';
      case 'FIRE':
        return '🔥';
      case 'WATER':
        return '💧';
      case 'FLOWER':
        return '🌸';

      // Colors
      case 'RED':
        return '🔴';
      case 'BLUE':
        return '🔵';
      case 'GREEN':
        return '🟢';
      case 'YELLOW':
        return '🟡';
      case 'BLACK':
        return '⚫';
      case 'WHITE':
        return '⚪';
      case 'PINK':
        return '🩷';
      case 'PURPLE':
        return '🟣';
      case 'ORANGE':
        return '🟠';
      case 'BROWN':
        return '🟤';

      // Food
      case 'APPLE':
        return '🍎';
      case 'BANANA':
        return '🍌';
      case 'BREAD':
        return '🍞';
      case 'CAKE':
        return '🎂';
      case 'MILK':
        return '🥛';
      case 'EGG':
        return '🥚';
      case 'FISH':
        return '🐟';
      case 'RICE':
        return '🍚';
      case 'SOUP':
        return '🍲';
      case 'TEA':
        return '🍵';

      // Objects
      case 'BOOK':
        return '📚';
      case 'BALL':
        return '⚽';
      case 'CAR':
        return '🚗';
      case 'DOOR':
        return '🚪';
      case 'KEY':
        return '🔑';
      case 'PEN':
        return '🖊️';
      case 'PHONE':
        return '📱';
      case 'TABLE':
        return '🪑';
      case 'TOY':
        return '🧸';
      case 'WATCH':
        return '⌚';

      // Actions
      case 'RUN':
        return '🏃';
      case 'WALK':
        return '🚶';
      case 'JUMP':
        return '🦘';
      case 'SWIM':
        return '🏊';
      case 'PLAY':
        return '🎮';
      case 'SING':
        return '🎤';
      case 'DANCE':
        return '💃';
      case 'READ':
        return '📖';
      case 'WRITE':
        return '✍️';
      case 'DRAW':
        return '🎨';
      case 'SLEEP':
        return '😴';
      case 'EAT':
        return '🍽️';
      case 'DRINK':
        return '🥤';
      case 'TALK':
        return '💬';

      // Feelings
      case 'HAPPY':
        return '😊';
      case 'SAD':
        return '😢';
      case 'ANGRY':
        return '😠';
      case 'LOVE':
        return '❤️';
      case 'FUN':
        return '🎉';
      case 'GOOD':
        return '👍';
      case 'BAD':
        return '👎';
      case 'BIG':
        return '🐘';
      case 'SMALL':
        return '🐁';
      case 'HOT':
        return '🔥';
      case 'COLD':
        return '❄️';
      case 'NEW':
        return '🆕';
      case 'OLD':
        return '👴';

      default:
        return '📝'; // Default emoji for words
    }
  }

  List<Map<String, String>> _createSimpleSentences() {
    // Create simple sentences using words from our word lists
    final List<Map<String, String>> sentences = [];

    // Simple sentence patterns
    final List<List<String>> sentencePatterns = [
      ['THE', 'CAT', 'IS', 'HAPPY'],
      ['I', 'CAN', 'SEE', 'THE', 'SUN'],
      ['WE', 'PLAY', 'WITH', 'THE', 'BALL'],
      ['THE', 'DOG', 'RUNS', 'FAST'],
      ['I', 'LIKE', 'TO', 'READ', 'BOOKS'],
      ['THE', 'BIRD', 'SINGS', 'NICE'],
      ['WE', 'CAN', 'JUMP', 'HIGH'],
      ['THE', 'FISH', 'SWIMS', 'IN', 'WATER'],
      ['I', 'LOVE', 'MY', 'FAMILY'],
      ['THE', 'TREE', 'IS', 'TALL'],
      ['WE', 'WALK', 'TO', 'SCHOOL'],
      ['THE', 'MOON', 'SHINES', 'BRIGHT'],
      ['I', 'DRAW', 'A', 'PICTURE'],
      ['THE', 'CAR', 'GOES', 'FAST'],
      ['WE', 'SING', 'A', 'SONG'],
      ['THE', 'BABY', 'IS', 'CUTE'],
      ['I', 'EAT', 'MY', 'FOOD'],
      ['THE', 'STAR', 'IS', 'BRIGHT'],
      ['WE', 'DANCE', 'TOGETHER'],
      ['THE', 'RAIN', 'FALLS', 'DOWN'],
    ];

    // Create sentences with emojis
    final List<String> emojis = [
      '🐱😊',
      '☀️👀',
      '⚽🎮',
      '🐶💨',
      '📚❤️',
      '🐦🎵',
      '🦘⬆️',
      '🐟💧',
      '❤️👨‍👩‍👧‍👦',
      '🌳📏',
      '🚶🏫',
      '🌙✨',
      '🎨🖼️',
      '🚗💨',
      '🎤🎵',
      '👶😊',
      '🍽️😋',
      '⭐✨',
      '💃🕺',
      '🌧️⬇️'
    ];

    for (int i = 0; i < sentencePatterns.length && i < emojis.length; i++) {
      sentences.add({
        'type': 'Sentence',
        'content': sentencePatterns[i].join(' '),
        'emoji': emojis[i],
      });
    }

    return sentences;
  }

  Future<void> _initSpeech() async {
    try {
      _speech = stt.SpeechToText();

      // Initialize the speech engine first
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint('Speech error: $error');
          // Show user-friendly error for Filipino children
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Hindi ma-recognize ang speech. Subukan ulit! (Speech not recognized. Try again!)',
                  style: TextStyle(fontFamily: 'Regular'),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        finalTimeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _speechAvailable = false;
        });
        return;
      }

      // Only fetch locales after successful initialization
      List<stt.LocaleName> locales = [];
      try {
        locales = await _speech.locales();
        debugPrint(
            'Available locales: ${locales.map((l) => l.localeId).toList()}');
      } catch (e) {
        debugPrint('Error fetching locales: $e');
      }

      String? selectedLocale;
      if (locales.isNotEmpty) {
        try {
          selectedLocale = locales
              .firstWhere(
                (locale) =>
                    locale.localeId.startsWith('fil') ||
                    locale.localeId.startsWith('tl'),
                orElse: () => locales.firstWhere(
                  (locale) => locale.localeId.startsWith('en'),
                ),
              )
              .localeId;
        } catch (e) {
          debugPrint('Error finding locale: $e');
          selectedLocale = locales.first.localeId;
        }
      }

      debugPrint('Selected locale: $selectedLocale');

      if (mounted) {
        setState(() {
          _selectedLocaleId = selectedLocale;
          _speechAvailable = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech engine: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      if (status == 'notListening') {
        _isListening = false;
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Speech not available. Please check microphone permission or try again.'),
            ),
          );
        }
        return;
      }
    }
    setState(() {
      _recognizedText = '';
      _confidence = 0.0;
      _isListening = true;
      _soundLevel = 0.0;
    });
    await _speech.listen(
      onResult: _onSpeechResult,
      partialResults: true,
      // Use confirmation mode and shorter timeouts for clearer short-word capture
      listenMode: stt.ListenMode.confirmation,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      localeId: _selectedLocaleId,
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  void _toggleListening() {
    // Students must listen to the word first before practicing
    if (!(widget.isTeacher ?? false) && !_hasListenedCurrentItem) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please tap Listen to hear the word first.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _recognizedText = result.recognizedWords;
      _confidence = result.confidence;
    });

    final target = practiceItems[_currentIndex]['content']!;
    final type = practiceItems[_currentIndex]['type'];

    // Always update character-by-character feedback for the latest speech
    _generateCharacterFeedback(target, _recognizedText);

    // For single-word items, allow early acceptance even on partial results
    final isMatch = _matchesTarget(target, _recognizedText);
    if (type == 'Word' && isMatch) {
      _stopListening();
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsCompleted();
      }
      return;
    }

    // Only treat FINAL results as full attempts
    if (!result.finalResult) {
      return;
    }

    if (isMatch) {
      _stopListening();
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsCompleted();
      }
    } else if (_recognizedText.isNotEmpty) {
      // Check if the speech contains both correct and incorrect parts
      final hasCorrectParts = _hasCorrectComponents(target, _recognizedText);
      final hasIncorrectParts =
          _hasIncorrectComponents(target, _recognizedText);

      if (hasCorrectParts && hasIncorrectParts) {
        // Mixed pronunciation - provide specific feedback
        _showMixedFeedbackMessage();
      } else {
        // Show incorrect feedback
        _showIncorrectFeedbackMessage();
      }

      // If this is the 3rd incorrect attempt for this item, mark it as failed
      if (_incorrectAttempts >= 3 &&
          !_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _stopListening();
        setState(() {
          _failedItems.add(_currentIndex);
        });
        _checkLevelCompletion();
      }
    }
  }

  void _generateCharacterFeedback(String target, String spoken) {
    final targetChars = target.toUpperCase().split('');
    final spokenChars = spoken.toUpperCase().split('');
    final feedback = <String>[];

    for (int i = 0; i < targetChars.length; i++) {
      if (i < spokenChars.length && targetChars[i] == spokenChars[i]) {
        feedback.add('correct');
      } else if (i < spokenChars.length) {
        feedback.add('incorrect');
      } else {
        feedback.add('missing');
      }
    }

    setState(() {
      _characterFeedback = feedback;
    });
  }

  double _calculateAccuracyPercentage() {
    if (_characterFeedback.isEmpty) return 0.0;
    final int correctCount =
        _characterFeedback.where((status) => status == 'correct').length;
    return 100.0 * correctCount / _characterFeedback.length;
  }

  void _showIncorrectFeedbackMessage() {
    setState(() {
      _incorrectAttempts++;
      _showIncorrectFeedback = true;
    });

    // After 2 incorrect attempts, allow students to move to the next item via popup
    if (!(widget.isTeacher ?? false) && _incorrectAttempts == 2) {
      _showNextItemPopup();
    }

    // Clear previous timer if exists
    _incorrectFeedbackTimer?.cancel();

    // Hide feedback after 3 seconds
    _incorrectFeedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showIncorrectFeedback = false;
        });
      }
    });
  }

  bool _hasCorrectComponents(String target, String spoken) {
    final targetWords = target.toUpperCase().split(' ');
    final spokenWords = spoken.toUpperCase().split(' ');

    // Check if any target words are present in spoken text
    for (final targetWord in targetWords) {
      for (final spokenWord in spokenWords) {
        if (spokenWord.contains(targetWord) ||
            targetWord.contains(spokenWord)) {
          return true;
        }
      }
    }

    // Check character-level matches
    final targetChars = target.toUpperCase().replaceAll(' ', '').split('');
    final spokenChars = spoken.toUpperCase().replaceAll(' ', '').split('');

    int correctChars = 0;
    for (int i = 0; i < targetChars.length && i < spokenChars.length; i++) {
      if (targetChars[i] == spokenChars[i]) {
        correctChars++;
      }
    }

    // If more than 50% of characters are correct, consider it has correct parts
    return correctChars > targetChars.length * 0.5;
  }

  bool _hasIncorrectComponents(String target, String spoken) {
    final targetWords = target.toUpperCase().split(' ');
    final spokenWords = spoken.toUpperCase().split(' ');

    // Check if there are spoken words not in target
    for (final spokenWord in spokenWords) {
      bool foundInTarget = false;
      for (final targetWord in targetWords) {
        if (spokenWord.contains(targetWord) ||
            targetWord.contains(spokenWord)) {
          foundInTarget = true;
          break;
        }
      }
      if (!foundInTarget && spokenWord.isNotEmpty) {
        return true;
      }
    }

    // Check character-level mismatches
    final targetChars = target.toUpperCase().replaceAll(' ', '').split('');
    final spokenChars = spoken.toUpperCase().replaceAll(' ', '').split('');

    int incorrectChars = 0;
    for (int i = 0; i < targetChars.length && i < spokenChars.length; i++) {
      if (targetChars[i] != spokenChars[i]) {
        incorrectChars++;
      }
    }

    // If more than 30% of characters are incorrect, consider it has incorrect parts
    return incorrectChars > targetChars.length * 0.3;
  }

  void _showMixedFeedbackMessage() {
    setState(() {
      _incorrectAttempts++;
      _showIncorrectFeedback = true;
    });

    // Clear previous timer if exists
    _incorrectFeedbackTimer?.cancel();

    // Hide feedback after 4 seconds (longer for mixed feedback)
    _incorrectFeedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showIncorrectFeedback = false;
        });
      }
    });
  }

  String _getEncouragingMessage() {
    final messages = [
      'Almost there! Try again! 🌟',
      'Good try! Keep practicing! 💪',
      'You\'re getting closer! 🎯',
      'Don\'t give up! You can do it! 🚀',
      'Practice makes perfect! 📚',
      'Nice effort! Try once more! 👍',
    ];

    return messages[_incorrectAttempts % messages.length];
  }

  String _getMixedFeedbackMessage() {
    final messages = [
      'Good start! Some letters are right, keep trying! 🌈',
      'You\'re close! Check the red letters and try again! 🎯',
      'Nice try! Focus on the highlighted letters! 💡',
      'Almost there! Some parts are perfect! ⭐',
      'Good effort! Look at the green letters and fix the red ones! 🔍',
      'You\'re learning! Try to say the red letters correctly! 📚',
    ];

    return messages[_incorrectAttempts % messages.length];
  }

  String _normalizeText(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _wordMatchRatio(String t, String h) {
    final tWords = t.split(' ').where((w) => w.isNotEmpty).toList();
    if (tWords.isEmpty) return 0.0;
    final matches = tWords.where((w) => h.contains(w)).length;
    return matches / tWords.length;
  }

  bool _matchesTarget(String target, String hyp) {
    final t = _normalizeText(target);
    final h = _normalizeText(hyp);
    if (t.isEmpty || h.isEmpty) return false;

    // Use Filipino pronunciation service for matching
    final similarity =
        FilipinoPronunciationService.calculateFilipinoSimilarity(t, h);

    // Additional character-level check (ignoring spaces) for short words
    final tChars = t.replaceAll(' ', '').split('');
    final hChars = h.replaceAll(' ', '').split('');
    int correctChars = 0;
    int mismatchChars = 0;
    for (int i = 0; i < tChars.length && i < hChars.length; i++) {
      if (tChars[i] == hChars[i]) {
        correctChars++;
      } else {
        mismatchChars++;
      }
    }
    final double charMatchRatio =
        tChars.isNotEmpty ? correctChars / tChars.length : 0.0;
    final bool hasExactCharPrefix =
        tChars.isNotEmpty && mismatchChars == 0 && hChars.length >= tChars.length;

    debugPrint(
        'Target: "$t", Hypothesis: "$h", Similarity: $similarity, CharMatch: $charMatchRatio, ExactPrefix: $hasExactCharPrefix');

    final type = practiceItems[_currentIndex]['type'];
    if (type == 'Word') {
      // Special handling for very short words (single letters in Level 1)
      final bool isSingleLetter = t.replaceAll(' ', '').length == 1;
      if (isSingleLetter) {
        // For single letters, only accept short utterances so that saying the
        // picture word (e.g., "grape" for G) is NOT treated as correct, but
        // short letter-name forms like "see" (for C) are still allowed.
        final String hNoSpace = h.replaceAll(' ', '');
        if (hNoSpace.length > 3) {
          // Too long to be just a letter sound, treat as incorrect.
          return false;
        }

        double letterThreshold = 0.5;
        if (_incorrectAttempts >= 1) {
          letterThreshold = 0.4;
        }

        final words = h.split(' ').where((w) => w.isNotEmpty).toList();
        return similarity >= letterThreshold ||
            t == h ||
            words.contains(t);
      }

      // For normal words, use a moderate threshold and relax slightly
      // after several incorrect attempts.
      double wordThreshold = 0.7;
      if (_incorrectAttempts >= 2) {
        wordThreshold = 0.6;
      }

      return similarity >= wordThreshold ||
          t == h ||
          h.split(' ').contains(t) ||
          // If all characters match in order as a prefix (e.g., "ACT" vs "A C T" or "ARE" vs "ARE YOU OKAY"), accept as correct
          hasExactCharPrefix;
    } else {
      // For sentences, use a moderate threshold
      return similarity >= 0.75 ||
          h.contains(t) ||
          _wordMatchRatio(t, h) >= 0.8;
    }
  }

  // Save progress to Firestore
  Future<void> _saveProgressToFirestore() async {
    if (widget.isTeacher! || widget.studentId == null) return;

    try {
      await _studentService.updateLevelProgress(
        studentId: widget.studentId!,
        level: widget.level!,
        score: _score,
        totalItems: _totalItems,
        completedItems: _completedItems.toList(),
        failedItems: _failedItems.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Progress saved successfully! 🎉',
              style: TextStyle(fontFamily: 'Regular'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving progress. Please try again.',
              style: TextStyle(fontFamily: 'Regular'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _savePartialProgress() async {
    if (widget.isTeacher! || widget.studentId == null || _isReviewMode) return;

    // If level is already finished, don't overwrite completed progress
    if (_completedItems.length + _failedItems.length == practiceItems.length) {
      return;
    }

    try {
      await _studentService.updateLevelPartialProgress(
        studentId: widget.studentId!,
        level: widget.level!,
        score: _score,
        totalItems: _totalItems,
        currentIndex: _currentIndex,
        completedItems: _completedItems.toList(),
        failedItems: _failedItems.toList(),
        incorrectAttempts: _incorrectAttempts,
      );
    } catch (e) {
      debugPrint('Error saving partial progress: $e');
    }
  }

  Future<void> _loadExistingProgress() async {
    if (widget.isTeacher! || widget.studentId == null || widget.level == null) {
      return;
    }

    try {
      final student = await _studentService.getStudent(widget.studentId!);
      final levelProgress = student?['levelProgress'];
      if (levelProgress == null) return;

      final levelData = levelProgress['${widget.level}'];
      if (levelData == null) return;

      final bool completed = levelData['completed'] == true;
      final int storedScore = (levelData['score'] ?? 0) as int;

      // Use the current number of practice items as the source of truth
      // for totalItems. If older saved data has a smaller total (e.g., 5
      // when the level now has 10 items), prefer the actual count so
      // the score denominator is correct.
      final int actualTotal = practiceItems.length;
      final int storedTotalRaw =
          (levelData['totalItems'] ?? _totalItems) as int;

      int effectiveTotal = storedTotalRaw;
      if (actualTotal > 0 &&
          (storedTotalRaw <= 0 || storedTotalRaw != actualTotal)) {
        effectiveTotal = actualTotal;
      }

      if (!mounted) return;

      setState(() {
        _score = storedScore;
        _totalItems = effectiveTotal;
      });

      if (!completed) {
        final inProgress = levelData['inProgress'];
        if (inProgress != null && inProgress is Map) {
          final dynamic idx = inProgress['currentIndex'];
          final dynamic completedItems = inProgress['completedItems'];
          final dynamic failedItems = inProgress['failedItems'];
          final dynamic incorrectAttempts = inProgress['incorrectAttempts'];

          setState(() {
            if (idx is int && idx >= 0 && idx < practiceItems.length) {
              _currentIndex = idx;
            }
            if (completedItems is List) {
              _completedItems =
                  completedItems.map<int>((e) => (e as num).toInt()).toSet();
            }
            if (failedItems is List) {
              _failedItems =
                  failedItems.map<int>((e) => (e as num).toInt()).toSet();
            }
            _incorrectAttempts =
                incorrectAttempts is int ? incorrectAttempts : 0;
          });
        }
      } else {
        // If level already completed, try to restore per-item results
        final results = levelData['results'];
        if (results != null && results is Map) {
          final dynamic completedItems = results['completedItems'];
          final dynamic failedItems = results['failedItems'];

          setState(() {
            _isReviewMode = true;

            if (completedItems is List) {
              _completedItems = completedItems
                  .map<int>((e) => (e as num).toInt())
                  .toSet();
            } else {
              _completedItems =
                  Set<int>.from(List.generate(practiceItems.length, (i) => i));
            }

            if (failedItems is List) {
              _failedItems = failedItems
                  .map<int>((e) => (e as num).toInt())
                  .toSet();
            }
          });
        } else {
          // Backwards compatibility: if no detailed results, mark all as completed
          setState(() {
            _isReviewMode = true;
            _completedItems =
                Set<int>.from(List.generate(practiceItems.length, (i) => i));
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading existing progress: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _incorrectFeedbackTimer?.cancel();
    _flutterTts.stop();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _nextItem() {
    setState(() {
      // If the current item hasn't been marked correct or failed yet,
      // treat it as failed so the level can still be finished.
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _failedItems.add(_currentIndex);
      }

      _currentIndex = (_currentIndex + 1) % practiceItems.length;

      // Reset state for the next item
      _characterFeedback = [];
      _showIncorrectFeedback = false;
      _incorrectAttempts = 0;
      _recognizedText = '';
      _confidence = 0.0;
      _hasListenedCurrentItem = false;
    });

    // Stop listening if still active
    if (_isListening) {
      _stopListening();
    }

    // After potentially marking a failed item, re-check if the level is done
    _checkLevelCompletion();
  }

  Future<void> _listenCurrentItem() async {
    final current = practiceItems[_currentIndex];
    final text = current['content'];
    if (text == null || text.isEmpty) return;

    if (_isListening) {
      await _stopListening();
    }

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
      if (mounted) {
        setState(() {
          _hasListenedCurrentItem = true;
        });
      }
    } catch (e) {
      debugPrint('Error during TTS speak: $e');
    }
  }

  void _markCurrentItemAsCompleted() {
    setState(() {
      _failedItems.remove(_currentIndex);
      _completedItems.add(_currentIndex);
      _score += 1;
      _showIncorrectFeedback = false;
      _incorrectAttempts = 0;
    });
    _checkLevelCompletion();

    // For students, show a Next Item pop-up if there are more items
    if (!(widget.isTeacher ?? false) &&
        _completedItems.length < practiceItems.length) {
      _showNextItemPopup();
    }
  }

  void _checkLevelCompletion() {
    if (_completedItems.length + _failedItems.length ==
        practiceItems.length) {
      _saveProgressToFirestore();
      _showLevelCompletedDialog();
    }
  }

  void _showNextItemPopup() {
    if (!(mounted)) return;
    if (widget.isTeacher ?? false) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: 'Great job practicing! 🎉',
                  fontSize: 20.0,
                  color: primary,
                  isBold: true,
                  fontFamily: 'Regular',
                  align: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                TextWidget(
                  text: 'Tap NEXT to continue to the next item.',
                  fontSize: 16.0,
                  color: black,
                  fontFamily: 'Regular',
                  align: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _nextItem();
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: TextWidget(
                      text: 'Next Item ➡️',
                      fontSize: 18.0,
                      color: Colors.white,
                      isBold: true,
                      fontFamily: 'Regular',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
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
                              color:
                                  (isLastLevel ? Colors.purple : Colors.orange)
                                      .withOpacity(0.5),
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
                  text:
                      isLastLevel ? '🏆 AMAZING! 🏆' : '🎉 Congratulations! 🎉',
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
                            border:
                                Border.all(color: Colors.purple, width: 3.0),
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
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      } else {
                        // Go back to home screen for other levels
                        Navigator.of(context).pop();
                      }

                      // Call the callback to unlock next level with score
                      widget.onLevelCompletedWithScore
                          ?.call(_score, _totalItems);
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
                      text: isLastLevel
                          ? 'Go to Home! 🏠'
                          : 'Continue Adventure! 🚀',
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
    final bool isTeacherMode = widget.isTeacher ?? false;
    final bool canGoNext = isTeacherMode ||
        isCurrentItemCompleted ||
        (!isTeacherMode && _incorrectAttempts >= 2);

    return WillPopScope(
      onWillPop: () async {
        await _savePartialProgress();
        return true;
      },
      child: Scaffold(
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
                          onPressed: () async {
                            await _savePartialProgress();
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
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: IconButton(
                          tooltip: _isListening
                              ? 'Stop listening'
                              : 'Start speaking',
                          icon: Transform.scale(
                            scale: _isListening
                                ? (1.0 + (_soundLevel.clamp(0, 60) / 120))
                                : 1.0,
                            child: Icon(
                              _isListening ? Icons.hearing : Icons.mic,
                              color: white,
                              size: 30.0,
                            ),
                          ),
                          onPressed: _speechAvailable ? _toggleListening : null,
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

                                // Content text with character feedback
                                if (_characterFeedback.isEmpty)
                                  TextWidget(
                                    text: currentItem['content']!,
                                    fontSize: 42.0,
                                    color: primary,
                                    isBold: true,
                                    maxLines: 3,
                                    align: TextAlign.center,
                                    fontFamily: 'Regular',
                                  )
                                else if (currentItem['type'] == 'Sentence')
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    runSpacing: 4.0,
                                    children: List.generate(
                                      currentItem['content']!.length,
                                      (index) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                          vertical: 4.0,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1.0,
                                          vertical: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index <
                                                  _characterFeedback.length
                                              ? (_characterFeedback[index] ==
                                                      'correct'
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red
                                                      .withOpacity(0.3))
                                              : Colors.grey.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(6.0),
                                          border: Border.all(
                                            color: index <
                                                    _characterFeedback.length
                                                ? (_characterFeedback[index] ==
                                                        'correct'
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.grey,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: TextWidget(
                                          text: currentItem['content']![index],
                                          fontSize: 30.0,
                                          color: index <
                                                  _characterFeedback.length
                                              ? (_characterFeedback[index] ==
                                                      'correct'
                                                  ? Colors.green
                                                  : Colors.red)
                                              : primary,
                                          isBold: true,
                                          fontFamily: 'Regular',
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      currentItem['content']!.length,
                                      (index) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                          vertical: 8.0,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index <
                                                  _characterFeedback.length
                                              ? (_characterFeedback[index] ==
                                                      'correct'
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red
                                                      .withOpacity(0.3))
                                              : Colors.grey.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                            color: index <
                                                    _characterFeedback.length
                                                ? (_characterFeedback[index] ==
                                                        'correct'
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.grey,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: TextWidget(
                                          text: currentItem['content']![index],
                                          fontSize: 42.0,
                                          color: index <
                                                  _characterFeedback.length
                                              ? (_characterFeedback[index] ==
                                                      'correct'
                                                  ? Colors.green
                                                  : Colors.red)
                                              : primary,
                                          isBold: true,
                                          fontFamily: 'Regular',
                                        ),
                                      ),
                                    ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isListening
                                          ? _pulseAnimation.value
                                          : 1.0,
                                      child: Icon(
                                        _isListening
                                            ? Icons.hearing
                                            : Icons.mic,
                                        color: primary,
                                        size: 32.0,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12.0),
                                TextWidget(
                                  text: _isListening
                                      ? 'Listening... 🧏'
                                      : 'Tap Practice to speak 🗣️',
                                  fontSize: 22.0,
                                  color: black,
                                  isBold: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            TextWidget(
                              text: _recognizedText.isNotEmpty
                                  ? 'Heard: ' + _recognizedText
                                  : 'Heard:',
                              fontSize: 18.0,
                              color: black,
                              fontFamily: 'Regular',
                            ),

                            // Incorrect pronunciation feedback
                            if (_showIncorrectFeedback) ...[
                              const SizedBox(height: 12.0),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _characterFeedback
                                                .contains('correct') &&
                                            _characterFeedback
                                                .contains('incorrect')
                                        ? [
                                            Colors.amber.shade100,
                                            Colors.yellow.shade100,
                                          ]
                                        : [
                                            Colors.red.shade100,
                                            Colors.orange.shade100,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _characterFeedback
                                                .contains('correct') &&
                                            _characterFeedback
                                                .contains('incorrect')
                                        ? Colors.amber.shade300
                                        : Colors.red.shade300,
                                    width: 2.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _characterFeedback.contains('correct') &&
                                              _characterFeedback
                                                  .contains('incorrect')
                                          ? Icons.lightbulb_outline
                                          : Icons.error_outline,
                                      color: _characterFeedback.contains(
                                                  'correct') &&
                                              _characterFeedback
                                                  .contains('incorrect')
                                          ? Colors.amber.shade600
                                          : Colors.red.shade600,
                                      size: 24.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Flexible(
                                      child: TextWidget(
                                        text: _characterFeedback.contains(
                                                    'correct') &&
                                                _characterFeedback
                                                    .contains('incorrect')
                                            ? _getMixedFeedbackMessage()
                                            : _getEncouragingMessage(),
                                        fontSize: 16.0,
                                        color: _characterFeedback.contains(
                                                    'correct') &&
                                                _characterFeedback
                                                    .contains('incorrect')
                                            ? Colors.amber.shade800
                                            : Colors.red.shade800,
                                        isBold: true,
                                        align: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_characterFeedback.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextWidget(
                                  text: 'Accuracy: ' +
                                      _calculateAccuracyPercentage()
                                          .toStringAsFixed(0) +
                                      '%',
                                  fontSize: 14.0,
                                  color: grey,
                                  align: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // Listen button (student must listen before practicing)
                      Visibility(
                        visible: !(widget.isTeacher ?? false),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _listenCurrentItem,
                              icon: Icon(Icons.volume_up,
                                  color: primary, size: 28.0),
                              label: TextWidget(
                                text: 'Listen to the word ',
                                fontSize: 18.0,
                                color: white,
                                isBold: true,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondary,
                                foregroundColor: white,
                                minimumSize:
                                    const Size(double.infinity, 56.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      ),

                      // Practice Button with enhanced animation
                      Visibility(
                        visible: !widget.isTeacher!,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: ElevatedButton.icon(
                            onPressed: (isCurrentItemCompleted ||
                                    !_hasListenedCurrentItem)
                                ? null
                                : () {
                                    if (_isListening) {
                                      _stopListening();
                                    } else {
                                      _startListening();
                                    }
                                  },
                            icon: Icon(
                                isCurrentItemCompleted
                                    ? Icons.check
                                    : (_isListening
                                        ? Icons.stop
                                        : Icons.mic),
                                color: white,
                                size: 32.0),
                            label: TextWidget(
                              text: isCurrentItemCompleted
                                  ? 'Completed! '
                                  : (!_hasListenedCurrentItem
                                      ? 'Tap Listen first '
                                      : (_isListening
                                          ? 'Listening... Tap to stop'
                                          : (_incorrectAttempts >= 3
                                              ? 'Try again! You can do it! '
                                              : 'Practice Now! '))),
                              fontSize: 24.0,
                              color: white,
                              isBold: true,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentItemCompleted
                                  ? Colors.green
                                  : (_hasListenedCurrentItem
                                      ? primary
                                      : primary.withOpacity(0.6)),
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

                      // Next Button with enhanced design (teachers only)
                      Visibility(
                        visible: widget.isTeacher ?? false,
                        child: OutlinedButton.icon(
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 16.0),
                          ),
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
    ));
  }
}
