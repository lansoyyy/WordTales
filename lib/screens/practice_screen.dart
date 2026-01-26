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
import 'package:word_tales/services/audio_service.dart';
import 'package:word_tales/services/practice_item_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PracticeScreen extends StatefulWidget {
  final bool? isTeacher;
  final int? level;
  final String? levelTitle;
  final String? levelDescription;
  final String? studentId;
  final String? studentName;
  final String? teacherName;
  final String? teacherId;
  final VoidCallback? onLevelCompleted;
  final Function(int score, int totalItems)? onLevelCompletedWithScore;

  PracticeScreen({
    this.isTeacher = false,
    this.level,
    this.levelTitle,
    this.levelDescription,
    this.studentId,
    this.studentName,
    this.teacherName,
    this.teacherId,
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
  Timer? _listeningWatchdogTimer;
  DateTime? _lastSpeechHeardAt;
  bool _isStartingListening = false;
  bool _shouldAutoRestartListening = false;
  Future<void>? _speechInitFuture;
  bool _didWarmUpSpeech = false;
  bool _isWarmingUpSpeech = false;

  // Incorrect pronunciation tracking
  int _incorrectAttempts = 0;
  bool _showIncorrectFeedback = false;
  Timer? _incorrectFeedbackTimer;
  List<String> _characterFeedback = [];

  // Speech recognition error tracking
  bool _hasSpeechError = false;
  bool _micPermissionGranted = true;
  bool _micPermissionPermanentlyDenied = false;
  bool _hasShownMicPermissionDialog = false;

  // Services
  final StudentService _studentService = StudentService();
  final PracticeItemService _practiceItemService = PracticeItemService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasListenedCurrentItem = false;
  StreamSubscription<List<Map<String, dynamic>>>? _practiceItemsSubscription;
  bool _hasStartedPracticeSession = false;

  // Audio recording
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool _isLevel5SentenceSessionActive = false;
  DateTime? _level5SentenceSessionStartedAt;
  String _level5SentenceAccumulatedText = '';
  bool _isRestartingLevel5SentenceListening = false;

  String _normalizedItemType(dynamic raw) {
    return (raw ?? '').toString().trim().toLowerCase();
  }

  String _mergeSentenceText(String a, String b) {
    final aa = a.trim();
    final bb = b.trim();
    if (aa.isEmpty) return bb;
    if (bb.isEmpty) return aa;
    if (bb.startsWith(aa)) return bb;
    if (aa.startsWith(bb)) return aa;
    return ('$aa $bb').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _restartListeningForLevel5SentenceIfNeeded() async {
    if (!_isLevel5SentenceSessionActive) return;
    if (_isRestartingLevel5SentenceListening) return;

    final startedAt = _level5SentenceSessionStartedAt;
    if (startedAt == null) return;
    if (DateTime.now().difference(startedAt) > const Duration(seconds: 300)) {
      return;
    }

    _isRestartingLevel5SentenceListening = true;
    try {
      await _initSpeech();
      if (!_speechAvailable) return;

      try {
        await _speech.cancel();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_isLevel5SentenceSessionActive) return;

      _lastSpeechHeardAt = DateTime.now();

      await _speech.listen(
        onResult: _onSpeechResult,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 180),
        pauseFor: const Duration(seconds: 30),
        localeId: _selectedLocaleId,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          if (level > 0.5) {
            _lastSpeechHeardAt = DateTime.now();
          }
          if (_isListening && level > 0.5) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
      );

      if (!mounted || !_isLevel5SentenceSessionActive) return;
      setState(() {
        _isListening = true;
      });
      _startListeningWatchdog();
    } finally {
      _isRestartingLevel5SentenceListening = false;
    }
  }

  Future<void> _uploadAndSaveRecording(
    String recordingPath,
    int itemIndex,
  ) async {
    if (widget.studentId == null || widget.level == null) return;

    try {
      final audioUrl = await AudioService.uploadAudio(
        filePath: recordingPath,
        studentId: widget.studentId!,
        level: widget.level!,
        itemIndex: itemIndex,
      );

      if (audioUrl != null) {
        await _studentService.saveAudioRecording(
          studentId: widget.studentId!,
          level: widget.level!,
          itemIndex: itemIndex,
          audioUrl: audioUrl,
        );
        debugPrint('Audio recording saved for item $itemIndex');
      }
    } catch (e) {
      debugPrint('Error saving audio recording: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePracticeItems();

    _speech = stt.SpeechToText();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

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
    Future.microtask(() async {
      await _ensureMicPermission();
      if (!mounted) return;
      if (!Platform.isAndroid || _micPermissionGranted) {
        await _initSpeech();
      }
    });
    _initTts();
  }

  Future<void> _ensureMicPermission() async {
    if (!Platform.isAndroid) {
      if (mounted) {
        setState(() {
          _micPermissionGranted = true;
          _micPermissionPermanentlyDenied = false;
        });
      }
      return;
    }

    final status = await Permission.microphone.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _micPermissionGranted = true;
          _micPermissionPermanentlyDenied = false;
          _hasShownMicPermissionDialog = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _micPermissionGranted = false;
        _micPermissionPermanentlyDenied = status.isPermanentlyDenied;
      });
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted) {
      if (mounted) {
        setState(() {
          _micPermissionGranted = true;
          _micPermissionPermanentlyDenied = false;
          _hasShownMicPermissionDialog = false;
        });
      }

      await _initSpeech();
      return;
    }

    if (!mounted) return;
    setState(() {
      _micPermissionGranted = false;
      _micPermissionPermanentlyDenied = requested.isPermanentlyDenied;
    });

    if (!_hasShownMicPermissionDialog) {
      _hasShownMicPermissionDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showMicPermissionDialog(
          permanentlyDenied: _micPermissionPermanentlyDenied,
        );
      });
    }
  }

  Widget _buildMicPermissionGate() {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_off, color: Colors.red, size: 90),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Microphone Permission Required',
                fontSize: 22.0,
                color: primary,
                isBold: true,
                align: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextWidget(
                text:
                    'This app needs microphone access to hear the student and check pronunciation.',
                fontSize: 16.0,
                color: grey,
                align: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _ensureMicPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: TextWidget(
                    text: 'Allow Microphone',
                    fontSize: 18.0,
                    color: white,
                    isBold: true,
                  ),
                ),
              ),
              if (_micPermissionPermanentlyDenied) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary, width: 2),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: TextWidget(
                      text: 'Open Settings',
                      fontSize: 18.0,
                      color: primary,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMicPermissionDialog({required bool permanentlyDenied}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: TextWidget(
          text: 'Microphone Permission Required',
          fontSize: 20.0,
          color: primary,
          isBold: true,
          align: TextAlign.center,
        ),
        content: TextWidget(
          text: permanentlyDenied
              ? 'Microphone permission is permanently denied. Please enable it in Settings to use speech practice.'
              : 'Please allow microphone access so the app can hear the student and check pronunciation.',
          fontSize: 16.0,
          color: grey,
          align: TextAlign.center,
        ),
        actions: [
          if (permanentlyDenied)
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: TextWidget(
                text: 'Open Settings',
                fontSize: 16.0,
                color: primary,
                isBold: true,
              ),
            ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _ensureMicPermission();
            },
            child: TextWidget(
              text: 'Retry',
              fontSize: 16.0,
              color: primary,
              isBold: true,
            ),
          ),
        ],
      ),
    );
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

  void _initializePracticeItems() async {
    // Initialize practice items based on level using words from words.dart
    practiceItems = [];

    // Get default items based on level
    List<Map<String, String>> defaultItems = [];

    switch (widget.level) {
      case 1:
        // Use 1-letter words
        for (int i = 0; i < oneLetterWords.length && i < 10; i++) {
          defaultItems.add({
            'type': 'Word',
            'content': oneLetterWords[i],
            'emoji': _getEmojiForLetter(oneLetterWords[i]),
          });
        }
        break;
      case 2:
        // Use 2-letter words
        for (int i = 0; i < twoLetterWords.length && i < 15; i++) {
          defaultItems.add({
            'type': 'Word',
            'content': twoLetterWords[i],
            'emoji': _getEmojiForWord(twoLetterWords[i]),
          });
        }
        break;
      case 3:
        // Use 3-letter words
        for (int i = 0; i < threeLetterWords.length && i < 20; i++) {
          defaultItems.add({
            'type': 'Word',
            'content': threeLetterWords[i],
            'emoji': _getEmojiForWord(threeLetterWords[i]),
          });
        }
        break;
      case 4:
        // Use 4-letter words
        for (int i = 0; i < fourLetterWords.length && i < 25; i++) {
          defaultItems.add({
            'type': 'Word',
            'content': fourLetterWords[i],
            'emoji': _getEmojiForWord(fourLetterWords[i]),
          });
        }
        break;
      case 5:
        // For level 5, we'll create simple sentences using the words
        defaultItems = _createSimpleSentences();
        break;
      default:
        // Default to some common words
        defaultItems = [
          {'type': 'Word', 'content': 'CAT', 'emoji': '🐱'},
          {'type': 'Word', 'content': 'DOG', 'emoji': '🐶'},
          {'type': 'Word', 'content': 'SUN', 'emoji': '☀️'},
        ];
    }

    // Default immediately (UI shouldn't wait on network)
    practiceItems = defaultItems;

    // Update total items after loading
    if (mounted) {
      setState(() {
        _totalItems = practiceItems.length;
      });
    }

    // Subscribe to teacher-level practice items so teacher edits are reflected.
    if (widget.level == null) return;
    final String? teacherId = widget.teacherId;
    if (teacherId == null || teacherId.trim().isEmpty) return;

    try {
      await _practiceItemService.ensureDefaultPracticeItems(
        teacherId: teacherId,
        level: widget.level!,
        defaultItems: defaultItems,
      );
    } catch (e) {
      debugPrint('Error ensuring default practice items: $e');
    }

    await _practiceItemsSubscription?.cancel();
    _practiceItemsSubscription = _practiceItemService
        .streamCustomPracticeItems(
      level: widget.level!,
      teacherId: teacherId,
    )
        .listen((items) {
      if (!mounted) return;

      final formatted = items.map((item) {
        final String type = (item['type'] ?? 'Word').toString();
        final String content = (item['content'] ?? '').toString();
        final String emojiRaw = (item['emoji'] ?? '').toString();
        final String emoji = emojiRaw.trim().isNotEmpty
            ? emojiRaw
            : _getEmojiForPracticeItem(type: type, content: content);
        return {
          'type': type,
          'content': content,
          'emoji': emoji,
        };
      }).toList();

      setState(() {
        practiceItems = formatted.isNotEmpty ? formatted : defaultItems;
        _totalItems = practiceItems.length;
        if (_currentIndex >= practiceItems.length) {
          _currentIndex = 0;
        }
      });
    });
  }

  String _getEmojiForPracticeItem(
      {required String type, required String content}) {
    final String normalized = content.trim();
    if (type == 'Word' && normalized.length == 1) {
      return _getEmojiForLetter(normalized);
    }
    if (type == 'Word') {
      return _getEmojiForWord(normalized);
    }
    return '📝';
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

  Future<void> _initSpeech() {
    _speechInitFuture ??= _initSpeechInternal();
    return _speechInitFuture!;
  }

  Future<void> _initSpeechInternal() async {
    try {
      // Initialize the speech engine first
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint(
              'Speech error: ${error.errorMsg} (permanent: ${error.permanent})');
          if (!mounted) return;

          // Don't auto-restart on errors - let user manually retry
          setState(() {
            _isListening = false;
            _hasSpeechError = true;
          });
        },
        finalTimeout: const Duration(seconds: 30),
      );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _speechAvailable = false;
        });
        _speechInitFuture = null;
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
                (locale) => locale.localeId.startsWith('en'),
                orElse: () => locales.firstWhere(
                  (locale) =>
                      locale.localeId.startsWith('fil') ||
                      locale.localeId.startsWith('tl'),
                  orElse: () => locales.first,
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
      _speechInitFuture = null;
      if (mounted) {
        setState(() {
          _speechAvailable = false;
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (_isWarmingUpSpeech) {
      if (status == 'notListening' || status == 'done') {
        _isWarmingUpSpeech = false;
      }
      return;
    }
    final bool stopped = status == 'notListening' || status == 'done';
    setState(() {
      if (status == 'listening') {
        _isListening = true;
        _hasSpeechError = false; // Reset error when speech starts successfully
      }
      if (stopped) {
        _isListening = false;
        _soundLevel = 0.0;
      }
    });

    if (status == 'listening') {
      _startListeningWatchdog();
    }
    if (stopped) {
      _listeningWatchdogTimer?.cancel();
      // Don't auto-restart listening - let user manually click Practice button
      _shouldAutoRestartListening = false;

      if (_isLevel5SentenceSessionActive && widget.level == 5) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (!_isLevel5SentenceSessionActive) return;
          _restartListeningForLevel5SentenceIfNeeded();
        });
      }
    }
  }

  void _startListeningWatchdog() {
    _listeningWatchdogTimer?.cancel();
    _listeningWatchdogTimer =
        Timer.periodic(const Duration(seconds: 4), (Timer timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_isListening) {
        timer.cancel();
        return;
      }

      final last = _lastSpeechHeardAt;
      if (last == null) {
        return;
      }

      final bool isLevel5SentenceSession =
          _isLevel5SentenceSessionActive && widget.level == 5;
      final Duration allowedSilence = isLevel5SentenceSession
          ? const Duration(seconds: 15)
          : const Duration(seconds: 3);

      if (DateTime.now().difference(last) > allowedSilence) {
        if (isLevel5SentenceSession) {
          return;
        }

        // Restart faster - don't wait 6 seconds
        timer.cancel();
        // Don't auto-restart - let user manually click Practice button
        _shouldAutoRestartListening = false;
      }
    });
  }

  Future<void> _ensureSpeechWarmUpIfNeeded() async {
    // Skip warm-up - it was interfering with speech recognition
    return;
  }

  Future<void> _startListening() async {
    if (!_hasStartedPracticeSession) {
      _hasStartedPracticeSession = true;
      await _practiceItemsSubscription?.cancel();
      _practiceItemsSubscription = null;
    }

    if (Platform.isAndroid && !_micPermissionGranted) {
      await _ensureMicPermission();
      if (!_micPermissionGranted) {
        return;
      }
    }
    if (_isStartingListening) return;
    _isStartingListening = true;
    await _initSpeech();
    if (!_speechAvailable) {
      _isStartingListening = false;
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
    try {
      _shouldAutoRestartListening = false;
      await _flutterTts.stop();

      // Skip warm-up - it was interfering with speech recognition

      // Stop any existing recording before starting speech recognition to avoid microphone conflict
      if (_isRecording && _currentRecordingPath != null) {
        await AudioService.stopRecording();
        // Add small delay to ensure microphone is properly released
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _isRecording = false;
            _currentRecordingPath = null;
          });
        }
      }

      // Don't start audio recording during speech recognition to avoid microphone conflict
      // Recording will be handled after speech completes

      try {
        await _speech.cancel();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      setState(() {
        _recognizedText = '';
        _confidence = 0.0;
        _isListening = false;
        _soundLevel = 0.0;
        _hasSpeechError = false; // Reset error flag when starting listening
      });

      _lastSpeechHeardAt = DateTime.now();

      final type = _normalizedItemType(practiceItems[_currentIndex]['type']);
      final bool isLevel5Sentence = widget.level == 5 && type == 'sentence';
      if (isLevel5Sentence) {
        _isLevel5SentenceSessionActive = true;
        _level5SentenceSessionStartedAt = DateTime.now();
        _level5SentenceAccumulatedText = '';
      }

      // Simplified speech listening - no retries, just start once
      await _speech.listen(
        onResult: _onSpeechResult,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        listenFor: isLevel5Sentence
            ? const Duration(seconds: 180)
            : (type == 'sentence'
                ? const Duration(seconds: 30)
                : const Duration(seconds: 25)),
        pauseFor: isLevel5Sentence
            ? const Duration(seconds: 30)
            : (type == 'sentence'
                ? const Duration(seconds: 5)
                : const Duration(seconds: 4)),
        localeId: _selectedLocaleId,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          if (level > 0.5) {
            _lastSpeechHeardAt = DateTime.now();
          }
          // Update sound level when listening and detecting speech
          // Lowered threshold from 2.0 to 0.5 to be more permissive
          if (_isListening && level > 0.5) {
            if (mounted) {
              setState(() {
                _soundLevel = level;
              });
            }
          }
        },
      );

      // Wait a bit to check if listening started
      await Future.delayed(const Duration(milliseconds: 500));

      bool started = _speech.isListening || _isListening;
      if (!started) {
        _shouldAutoRestartListening = false;
        if (_isRecording && _currentRecordingPath != null) {
          await AudioService.stopRecording();
          if (mounted) {
            setState(() {
              _isRecording = false;
              _currentRecordingPath = null;
            });
          }
        }
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
            _hasSpeechError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone not ready. Please tap Practice button again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      _startListeningWatchdog();
    } catch (e) {
      debugPrint('Error starting speech listening: $e');
      _shouldAutoRestartListening = false;
      if (_isRecording && _currentRecordingPath != null) {
        await AudioService.stopRecording();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _currentRecordingPath = null;
          });
        }
      }
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
          _hasSpeechError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not responding. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> _stopListening() async {
    _listeningWatchdogTimer?.cancel();
    _shouldAutoRestartListening = false;
    _isLevel5SentenceSessionActive = false;
    _level5SentenceSessionStartedAt = null;
    _level5SentenceAccumulatedText = '';
    final int itemIndex = _currentIndex;
    await _speech.stop();

    // Stop audio recording when speech stops
    if (_isRecording && _currentRecordingPath != null) {
      final recordingPath = await AudioService.stopRecording();
      if (recordingPath != null && widget.studentId != null) {
        // Upload recording and save URL
        _uploadAndSaveRecording(recordingPath, itemIndex);
      }
      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
      });
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  void _toggleListening() {
    // Students must listen to the word first before practicing
    if (Platform.isAndroid && !_micPermissionGranted) {
      _ensureMicPermission();
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
    final type = _normalizedItemType(practiceItems[_currentIndex]['type']);
    final bool isLevel5Sentence = widget.level == 5 && type == 'sentence';

    final String mergedText = isLevel5Sentence
        ? _mergeSentenceText(
            _level5SentenceAccumulatedText, result.recognizedWords)
        : result.recognizedWords;

    setState(() {
      _recognizedText = mergedText;
      _confidence = result.confidence;
    });

    if (result.recognizedWords.trim().isNotEmpty) {
      _lastSpeechHeardAt = DateTime.now();
    }

    final target = practiceItems[_currentIndex]['content']!;

    // Always update character-by-character feedback for the latest speech
    _generateCharacterFeedback(target, _recognizedText);

    // Evaluate how well the speech matches the target
    final bool baseMatch = _matchesTarget(target, _recognizedText);
    final double accuracy =
        _characterFeedback.isNotEmpty ? _calculateAccuracyPercentage() : 0.0;

    // Apply additional accuracy gating so that low-accuracy attempts
    // are not counted as correct, even if the similarity function is
    // generous.
    bool isMatch = baseMatch;
    if (type == 'sentence') {
      // For sentences, trust the similarity + word-overlap check.
      // Character-perfect accuracy is too strict and leads to false negatives.
      isMatch = baseMatch;
    } else if (type == 'word') {
      // For multi-letter words, require reasonable character accuracy.
      // BUT if baseMatch (sophisticated check) already passed, trust it!
      // The accuracy check is prone to failure on short words due to alignment issues
      // (e.g. "HIS" vs "IS" gives 0% accuracy due to position, but baseMatch finds it).
      final bool isSingleLetterTarget =
          target.replaceAll(' ', '').trim().length == 1;
      final bool isShortWord = target.replaceAll(' ', '').trim().length <= 3;

      if (!isSingleLetterTarget &&
          !isShortWord &&
          accuracy < 45.0 &&
          !baseMatch) {
        // Only block if baseMatch failed AND accuracy is low
        isMatch = false;
      }
      // If baseMatch is true, we keep isMatch = true regardless of accuracy
      // because _matchesTarget handles the "contains" logic better.
    }

    // For single-word items, allow early acceptance even on partial results
    if (type == 'word' && isMatch) {
      _stopListening();
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsCorrect();
      }
      return;
    }

    if (isLevel5Sentence) {
      if (!result.finalResult) {
        return;
      }

      _level5SentenceAccumulatedText = mergedText;

      if (isMatch) {
        _stopListening();
        if (!_completedItems.contains(_currentIndex) &&
            !_failedItems.contains(_currentIndex)) {
          _markCurrentItemAsCorrect();
        }
        return;
      }

      final startedAt = _level5SentenceSessionStartedAt;
      if (startedAt != null &&
          DateTime.now().difference(startedAt) > const Duration(seconds: 300)) {
        _stopListening();
        if (_recognizedText.isNotEmpty &&
            !_completedItems.contains(_currentIndex) &&
            !_failedItems.contains(_currentIndex)) {
          _showIncorrectFeedbackMessage();
        }
        return;
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (!_isLevel5SentenceSessionActive) return;
        _restartListeningForLevel5SentenceIfNeeded();
      });
      return;
    }

    // Only treat FINAL results as full attempts
    if (!result.finalResult) {
      return;
    }

    _stopListening();

    if (isMatch) {
      // Correct answer - add to score and proceed
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsCorrect();
      }
    } else if (_recognizedText.isNotEmpty) {
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _showIncorrectFeedbackMessage();
      }
    }
  }

  void _generateCharacterFeedback(String target, String spoken) {
    final type = _normalizedItemType(practiceItems[_currentIndex]['type']);

    // For sentences, provide feedback at the word level so that only the
    // misread words are highlighted (e.g., only "eat" turns red in
    // "I eat my food" when that word is mispronounced).
    if (type == 'sentence') {
      final bool isLevel5SentenceSession =
          widget.level == 5 && _isLevel5SentenceSessionActive;
      final targetWords = target.toUpperCase().trim().split(RegExp(r'\s+'));
      final spokenWords = spoken.toUpperCase().trim().split(RegExp(r'\s+'));

      final feedback = <String>[];
      for (int i = 0; i < targetWords.length; i++) {
        final targetWord = targetWords[i];

        if (targetWord.isEmpty) {
          feedback.add('missing');
          continue;
        }

        if (i < spokenWords.length) {
          final spokenWord = spokenWords[i];
          if (spokenWord == targetWord) {
            feedback.add('correct');
          } else {
            feedback.add(isLevel5SentenceSession ? 'missing' : 'incorrect');
          }
        } else {
          feedback.add('missing');
        }
      }

      setState(() {
        _characterFeedback = feedback;
      });
      return;
    }

    // For letters and words, keep character-level feedback.
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

    if (!(widget.isTeacher ?? false) && _incorrectAttempts >= 2) {
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsIncorrect();
      }
      return;
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

    if (!(widget.isTeacher ?? false) && _incorrectAttempts >= 2) {
      if (!_completedItems.contains(_currentIndex) &&
          !_failedItems.contains(_currentIndex)) {
        _markCurrentItemAsIncorrect();
      }
      return;
    }

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
    final matches = tWords.where((w) => h.contains(w)).length;
    return matches / tWords.length;
  }

  bool _matchesTarget(String target, String hypothesis) {
    final t = _normalizeText(target);
    final h = _normalizeText(hypothesis);
    if (t.isEmpty || h.isEmpty) return false;

    // Use Filipino pronunciation service for matching
    final similarity =
        FilipinoPronunciationService.calculateFilipinoSimilarity(t, h);

    // Additional character-level check (ignoring spaces) for short words
    final tChars = t.replaceAll(' ', '').split('');
    final hChars = h.replaceAll(' ', '').split('');
    int correctChars = 0;
    for (int i = 0; i < tChars.length && i < hChars.length; i++) {
      if (tChars[i] == hChars[i]) {
        correctChars++;
      }
    }
    final double charMatchRatio =
        tChars.isNotEmpty ? correctChars / tChars.length : 0.0;
    final int tLen = tChars.length;
    final int hLen = hChars.length;

    debugPrint(
        'Target: "$t", Hypothesis: "$h", Similarity: $similarity, CharMatch: $charMatchRatio');

    final type = practiceItems[_currentIndex]['type'];
    if (type == 'Word') {
      // Special handling for very short words (single letters in Level 1)
      final bool isSingleLetter = t.replaceAll(' ', '').length == 1;
      if (isSingleLetter) {
        // For single letters, only accept short utterances so that saying the
        // picture word (e.g., "grape" for G) is NOT treated as correct, but
        // short letter-name forms like "see" (for C) are still allowed.
        double letterThreshold = 0.5;
        if (_incorrectAttempts >= 1) {
          letterThreshold = 0.4;
        }

        final words = h.split(' ').where((w) => w.isNotEmpty).toList();
        return similarity >= letterThreshold || t == h || words.contains(t);
      }

      // For normal words (2+ letters), be stricter but allow
      // the target word to be found within the hypothesis (e.g. "UH AT" for "AT").
      final hWords = h.split(' ');
      if (hWords.contains(t)) {
        return true;
      }

      // For very short words/syllables (2-3 letters), relaxed length check.
      // Was: if (tLen <= 3 && hLen != tLen) return false;
      // Now: Allow slightly longer hypothesis to account for noise (e.g. "H AT").
      if (tLen <= 3 && hLen > tLen + 2) {
        return false;
      }

      // For longer words, do not allow a long extra tail
      // (e.g., target "ACT" vs hypothesis "ACTIVITY").
      if (tLen > 3 && hLen > tLen + 2) {
        return false;
      }

      // Use a moderate similarity threshold and relax slightly
      // after several incorrect attempts.
      double wordThreshold = 0.75;

      // For very short words (2 letters), start more leniently (0.60)
      // to allow close matches like "HAT"/"AT" (similarity ~0.66) to pass.
      if (tLen <= 2) {
        wordThreshold = 0.60;
      }

      if (_incorrectAttempts >= 1) {
        // After failure, be very forgiving for short words (0.50)
        wordThreshold = tLen <= 2 ? 0.50 : 0.65;
      }
      if (_incorrectAttempts >= 3) {
        wordThreshold = 0.45;
      }

      // Also require good character-level agreement for words.
      // Lowered from 0.8 to 0.6 to allow for minor spelling variations
      // if phonetic similarity is high.
      if (charMatchRatio < 0.6) {
        return false;
      }

      return similarity >= wordThreshold || t == h;
    } else {
      // Stricter handling for sentences so that misread sentences
      // (e.g., saying a different last word) are not treated as
      // correct just because overall similarity is moderately high.

      final tWords =
          t.split(' ').where((w) => w.isNotEmpty).toList(growable: false);
      final hWords =
          h.split(' ').where((w) => w.isNotEmpty).toList(growable: false);
      final double wordRatio = _wordMatchRatio(t, h);

      // If the hypothesis is much shorter or much longer than the
      // target sentence, treat it as incorrect.
      if (hWords.length < (tWords.length * 0.6) ||
          hWords.length > (tWords.length * 1.4)) {
        return false;
      }

      // Require reasonably high similarity and word overlap.
      // Too strict thresholds cause false negatives and user frustration.
      double sentenceThreshold = 0.75;
      if (_incorrectAttempts >= 1) {
        sentenceThreshold = 0.70;
      }
      if (_incorrectAttempts >= 2) {
        sentenceThreshold = 0.65;
      }

      // Short sentences (up to 4 words) should be strict-ish but not perfect;
      // longer ones can be more lenient.
      double minWordRatio = tWords.length <= 4 ? 0.85 : 0.75;
      if (_incorrectAttempts >= 2) {
        minWordRatio = tWords.length <= 4 ? 0.80 : 0.70;
      }

      return similarity >= sentenceThreshold && wordRatio >= minWordRatio;
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
              _completedItems =
                  completedItems.map<int>((e) => (e as num).toInt()).toSet();
            } else {
              _completedItems =
                  Set<int>.from(List.generate(practiceItems.length, (i) => i));
            }

            if (failedItems is List) {
              _failedItems =
                  failedItems.map<int>((e) => (e as num).toInt()).toSet();
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
    _listeningWatchdogTimer?.cancel();
    _practiceItemsSubscription?.cancel();
    _flutterTts.stop();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _nextItem() async {
    // Always stop/reset speech service to ensure it's ready for next item
    // This is important after speech errors where _isListening may be false but service needs reset
    _listeningWatchdogTimer?.cancel();
    _shouldAutoRestartListening = false;
    if (_isListening || _isRecording) {
      await _stopListening();
    } else {
      try {
        await _speech.stop();
      } catch (_) {}
    }

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
      _hasSpeechError = false;
      _incorrectAttempts = 0;
      _recognizedText = '';
      _confidence = 0.0;
      _hasListenedCurrentItem = false;
      _isListening = false;
      _soundLevel = 0.0;
    });

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

  // Mark current item as correct - add score and auto-proceed
  void _markCurrentItemAsCorrect() {
    setState(() {
      _failedItems.remove(_currentIndex);
      _completedItems.add(_currentIndex);
      _score += 1;
      _showIncorrectFeedback = false;
      _incorrectAttempts = 0;
    });

    // Show brief correct feedback then auto-proceed
    _showResultAndProceed(isCorrect: true);
  }

  // Mark current item as incorrect - no score, auto-proceed
  void _markCurrentItemAsIncorrect() {
    setState(() {
      _completedItems.remove(_currentIndex);
      _failedItems.add(_currentIndex);
      _showIncorrectFeedback = true;
    });

    // Show brief incorrect feedback then auto-proceed
    _showResultAndProceed(isCorrect: false);
  }

  // Show result feedback dialog and auto-proceed to next item
  void _showResultAndProceed({required bool isCorrect}) {
    if (!mounted) return;
    if (widget.isTeacher ?? false) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Auto-dismiss after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 80.0,
                ),
                const SizedBox(height: 16.0),
                TextWidget(
                  text: isCorrect ? 'Correct! 🎉' : 'Incorrect 😔',
                  fontSize: 28.0,
                  color: isCorrect ? Colors.green : Colors.red,
                  isBold: true,
                  fontFamily: 'Regular',
                  align: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                TextWidget(
                  text: isCorrect ? '+1 Point!' : 'Keep practicing!',
                  fontSize: 18.0,
                  color: grey,
                  fontFamily: 'Regular',
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) async {
      // After dialog closes, check level completion or proceed to next
      _checkLevelCompletion();
      if (_completedItems.length + _failedItems.length < practiceItems.length) {
        await _proceedToNextItem();
      }
    });
  }

  // Proceed to next item without marking current as failed
  Future<void> _proceedToNextItem() async {
    _listeningWatchdogTimer?.cancel();
    _shouldAutoRestartListening = false;
    if (_isListening || _isRecording) {
      await _stopListening();
    } else {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    setState(() {
      _currentIndex = (_currentIndex + 1) % practiceItems.length;
      _characterFeedback = [];
      _showIncorrectFeedback = false;
      _hasSpeechError = false;
      _incorrectAttempts = 0;
      _recognizedText = '';
      _confidence = 0.0;
      _hasListenedCurrentItem = false;
      _isListening = false;
      _soundLevel = 0.0;
    });
  }

  void _checkLevelCompletion() {
    if (_completedItems.length + _failedItems.length == practiceItems.length) {
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
                const SizedBox(height: 8.0),
                if (_characterFeedback.isNotEmpty)
                  TextWidget(
                    text: 'Accuracy: ' +
                        _calculateAccuracyPercentage().toStringAsFixed(0) +
                        '%',
                    fontSize: 16.0,
                    color: grey,
                    fontFamily: 'Regular',
                    align: TextAlign.center,
                  ),
                const SizedBox(height: 8.0),
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
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
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
    if (Platform.isAndroid && !_micPermissionGranted) {
      return _buildMicPermissionGate();
    }
    final currentItem = practiceItems[_currentIndex];
    final String currentItemType = _normalizedItemType(currentItem['type']);
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
                              icon: Icon(Icons.arrow_back,
                                  color: white, size: 30.0),
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
                                          text: widget.levelTitle ??
                                              'Practice Time!',
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
                          Visibility(
                            visible: widget.isTeacher ?? false,
                            child: Container(
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
                                onPressed:
                                    _speechAvailable ? _toggleListening : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Teacher name section (only in teacher practice mode)
                  Visibility(
                    visible: widget.isTeacher ?? false,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade100,
                            Colors.purple.shade200
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.purple, width: 2.0),
                      ),
                      child: TextWidget(
                        text: '👩‍🏫 ${widget.teacherName ?? 'Teacher'}',
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
                                    border:
                                        Border.all(color: primary, width: 2.0),
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
                                      offset:
                                          Offset(0, _bounceAnimation.value * 2),
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
                                      offset:
                                          Offset(0, _bounceAnimation.value * 2),
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
                                      offset:
                                          Offset(_bounceAnimation.value * 2, 0),
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
                                    else if (currentItemType == 'sentence')
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        runSpacing: 4.0,
                                        spacing: 4.0,
                                        children: () {
                                          final words = currentItem['content']!
                                              .split(RegExp(r'\\s+'));
                                          return List.generate(words.length,
                                              (index) {
                                            final word = words[index];
                                            final String status = index <
                                                    _characterFeedback.length
                                                ? _characterFeedback[index]
                                                : 'missing';

                                            Color bgColor;
                                            Color borderColor;
                                            Color textColor;

                                            if (status == 'correct') {
                                              bgColor =
                                                  Colors.green.withOpacity(0.2);
                                              borderColor = Colors.green;
                                              textColor = Colors.green.shade800;
                                            } else if (status == 'incorrect') {
                                              bgColor =
                                                  Colors.red.withOpacity(0.2);
                                              borderColor = Colors.red;
                                              textColor = Colors.red.shade800;
                                            } else {
                                              bgColor =
                                                  Colors.grey.withOpacity(0.1);
                                              borderColor = Colors.grey;
                                              textColor = primary;
                                            }

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6.0,
                                                vertical: 4.0,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 1.0,
                                                vertical: 2.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius:
                                                    BorderRadius.circular(6.0),
                                                border: Border.all(
                                                  color: borderColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: TextWidget(
                                                text: word,
                                                fontSize: 26.0,
                                                color: textColor,
                                                isBold: true,
                                                fontFamily: 'Regular',
                                              ),
                                            );
                                          });
                                        }(),
                                      )
                                    else if (widget.level == 1)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                  ? (_characterFeedback[
                                                              index] ==
                                                          'correct'
                                                      ? Colors.green
                                                          .withOpacity(0.3)
                                                      : Colors.red
                                                          .withOpacity(0.3))
                                                  : Colors.grey
                                                      .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              border: Border.all(
                                                color: index <
                                                        _characterFeedback
                                                            .length
                                                    ? (_characterFeedback[
                                                                index] ==
                                                            'correct'
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Colors.grey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: TextWidget(
                                              text: currentItem['content']![
                                                  index],
                                              fontSize: 42.0,
                                              color: index <
                                                      _characterFeedback.length
                                                  ? (_characterFeedback[
                                                              index] ==
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
                                      TextWidget(
                                        text: currentItem['content']!,
                                        fontSize: 42.0,
                                        color: _characterFeedback
                                                .every((c) => c == 'correct')
                                            ? Colors.green
                                            : Colors.red,
                                        isBold: true,
                                        maxLines: 3,
                                        align: TextAlign.center,
                                        fontFamily: 'Regular',
                                      ),

                                    if (isCurrentItemCompleted)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 16.0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green,
                                              Colors.green.shade600
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20.0),
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
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
                                          _characterFeedback
                                                      .contains('correct') &&
                                                  _characterFeedback
                                                      .contains('incorrect')
                                              ? Icons.lightbulb_outline
                                              : Icons.error_outline,
                                          color: _characterFeedback
                                                      .contains('correct') &&
                                                  _characterFeedback
                                                      .contains('incorrect')
                                              ? Colors.amber.shade600
                                              : Colors.red.shade600,
                                          size: 24.0,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Flexible(
                                          child: TextWidget(
                                            text: _characterFeedback
                                                        .contains('correct') &&
                                                    _characterFeedback
                                                        .contains('incorrect')
                                                ? _getMixedFeedbackMessage()
                                                : _getEncouragingMessage(),
                                            fontSize: 16.0,
                                            color: _characterFeedback
                                                        .contains('correct') &&
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
                          const SizedBox(height: 20.0),

                          // Skip button - only visible when speech recognition error occurs
                          if (_hasSpeechError && !isCurrentItemCompleted)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20.0),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _nextItem();
                                },
                                icon: Icon(Icons.skip_next,
                                    color: white, size: 28.0),
                                label: TextWidget(
                                  text: 'Skip Item ⏭️',
                                  fontSize: 20.0,
                                  color: white,
                                  isBold: true,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: white,
                                  minimumSize:
                                      const Size(double.infinity, 60.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  elevation: 6.0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                ),
                              ),
                            ),

                          // Listen button (commented out - not required before practicing)
                          // Visibility(
                          //   visible: !(widget.isTeacher ?? false),
                          //   child: Column(
                          //     children: [
                          //       ElevatedButton.icon(
                          //         onPressed: _listenCurrentItem,
                          //         icon: Icon(Icons.volume_up,
                          //             color: white, size: 28.0),
                          //         label: TextWidget(
                          //           text: 'Listen to the word 🔊',
                          //           fontSize: 18.0,
                          //           color: white,
                          //           isBold: true,
                          //         ),
                          //         style: ElevatedButton.styleFrom(
                          //           backgroundColor: secondary,
                          //           foregroundColor: white,
                          //           minimumSize:
                          //               const Size(double.infinity, 56.0),
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(16.0),
                          //           ),
                          //         ),
                          //       ),
                          //       const SizedBox(height: 16.0),
                          //     ],
                          //   ),
                          // ),

                          // Practice Button with enhanced animation
                          Visibility(
                            visible: !widget.isTeacher!,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: ElevatedButton.icon(
                                onPressed: isCurrentItemCompleted
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
                                      : (_isListening
                                          ? 'Listening... Tap to stop'
                                          : (_incorrectAttempts >= 1
                                              ? 'Try again! You can do it! '
                                              : 'Practice Now! ')),
                                  fontSize: 24.0,
                                  color: white,
                                  isBold: true,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrentItemCompleted
                                      ? Colors.green
                                      : primary,
                                  foregroundColor: white,
                                  minimumSize:
                                      const Size(double.infinity, 80.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  elevation:
                                      isCurrentItemCompleted ? 0.0 : 10.0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
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
