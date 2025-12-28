import 'package:flutter/material.dart';
import 'package:word_tales/screens/practice_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:word_tales/widgets/audio_player_widget.dart';
import 'package:word_tales/services/student_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:word_tales/utils/words.dart';

class TeacherHomeScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String teacherSection;

  const TeacherHomeScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.teacherSection,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Section list - matching teacher sections
  final List<String> _sections = [
    'Apple',
    'Atis',
    'Chico',
    'Durian',
    'Grapes',
    'Guava',
    'Lemon',
    'Makopa',
    'Mango',
    'Melon',
    'Orange',
    'Pear',
    'Pomelo',
    'Strawberry',
    'Tambis',
  ];

  final StudentService _studentService = StudentService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 97.0) {
      return Colors.green;
    } else if (percentage >= 90.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  int _getPerformanceBandOrder(double? percentage, bool isCompleted) {
    // Lower value = higher priority in sorting
    if (!isCompleted || percentage == null) {
      return 3; // Not started / no score
    }
    if (percentage <= 89.0) {
      return 0; // Frustration (red)
    } else if (percentage <= 96.0) {
      return 1; // Instructional (orange)
    } else {
      return 2; // Independent (green)
    }
  }

  // Level data with descriptions and content
  final List<Map<String, dynamic>> levels = [
    {
      'level': 1,
      'title': 'Level 1',
      'description': '1 Letter Words',
      'icon': Icons.abc,
      'color': Colors.red,
      'totalItems': 10,
      'content': oneLetterWords
          .take(10)
          .map((w) => {'type': 'Word', 'content': w})
          .toList(),
    },
    {
      'level': 2,
      'title': 'Level 2',
      'description': '2 Letter Words',
      'icon': Icons.text_fields,
      'color': Colors.orange,
      'totalItems': 15,
      'content': twoLetterWords
          .take(15)
          .map((w) => {'type': 'Word', 'content': w})
          .toList(),
    },
    {
      'level': 3,
      'title': 'Level 3',
      'description': '3 Letter Words',
      'icon': Icons.text_format,
      'color': Colors.yellow,
      'totalItems': 20,
      'content': threeLetterWords
          .take(20)
          .map((w) => {'type': 'Word', 'content': w})
          .toList(),
    },
    {
      'level': 4,
      'title': 'Level 4',
      'description': '4 Letter Words',
      'icon': Icons.text_snippet,
      'color': Colors.green,
      'totalItems': 25,
      'content': fourLetterWords
          .take(25)
          .map((w) => {'type': 'Word', 'content': w})
          .toList(),
    },
    {
      'level': 5,
      'title': 'Level 5',
      'description': 'Sentences',
      'icon': Icons.article,
      'color': Colors.blue,
      'totalItems': 20,
      'content': [
        ['THE', 'CAT', 'IS', 'HAPPY'].join(' '),
        ['I', 'CAN', 'SEE', 'THE', 'SUN'].join(' '),
        ['WE', 'PLAY', 'WITH', 'THE', 'BALL'].join(' '),
        ['THE', 'DOG', 'RUNS', 'FAST'].join(' '),
        ['I', 'LIKE', 'TO', 'READ', 'BOOKS'].join(' '),
        ['THE', 'BIRD', 'SINGS', 'NICE'].join(' '),
        ['WE', 'CAN', 'JUMP', 'HIGH'].join(' '),
        ['THE', 'FISH', 'SWIMS', 'IN', 'WATER'].join(' '),
        ['I', 'LOVE', 'MY', 'FAMILY'].join(' '),
        ['THE', 'TREE', 'IS', 'TALL'].join(' '),
        ['WE', 'WALK', 'TO', 'SCHOOL'].join(' '),
        ['THE', 'MOON', 'SHINES', 'BRIGHT'].join(' '),
        ['I', 'DRAW', 'A', 'PICTURE'].join(' '),
        ['THE', 'CAR', 'GOES', 'FAST'].join(' '),
        ['WE', 'SING', 'A', 'SONG'].join(' '),
        ['THE', 'BABY', 'IS', 'CUTE'].join(' '),
        ['I', 'EAT', 'MY', 'FOOD'].join(' '),
        ['THE', 'STAR', 'IS', 'BRIGHT'].join(' '),
        ['WE', 'DANCE', 'TOGETHER'].join(' '),
        ['THE', 'RAIN', 'FALLS', 'DOWN'].join(' '),
      ].map((s) => {'type': 'Sentence', 'content': s}).toList(),
    },
  ];

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
    _loadStudents();
  }

  // Load students from Firebase
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students =
          await _studentService.getStudentsByTeacher(widget.teacherId);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: 'Error loading students',
        backgroundColor: Colors.red,
        textColor: white,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get emoji for each fruit section
  String _getSectionEmoji(String section) {
    if (!_sections.contains(section)) {
      return '🏫';
    }
    switch (section) {
      case 'Apple':
        return '🍎';
      case 'Atis':
        return '🍈';
      case 'Chico':
        return '🥝';
      case 'Durian':
        return '🥭';
      case 'Grapes':
        return '🍇';
      case 'Guava':
        return '🍐';
      case 'Lemon':
        return '🍋';
      case 'Makopa':
        return '🍑';
      case 'Mango':
        return '🥭';
      case 'Melon':
        return '🍈';
      case 'Orange':
        return '🍊';
      case 'Pear':
        return '🍐';
      case 'Pomelo':
        return '🍊';
      case 'Strawberry':
        return '🍓';
      case 'Tambis':
        return '🍒';
      default:
        return '🍎';
    }
  }

  // Get filtered students based on search query and section filter
  List<Map<String, dynamic>> get filteredStudents {
    var filtered = _students;

    filtered = filtered
        .where((student) => student['section'] == widget.teacherSection)
        .toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((student) => student['name']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  // Add new student
  Future<void> addStudent() async {
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: TextWidget(
            text: 'Add New Student',
            fontSize: 20.0,
            color: primary,
            isBold: true,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Student Name',
                  prefixIcon: Icon(Icons.person, color: primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 14.0),
                decoration: BoxDecoration(
                  border: Border.all(color: grey.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.class_, color: primary),
                    const SizedBox(width: 10),
                    Text(
                      _getSectionEmoji(widget.teacherSection),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextWidget(
                        text: widget.teacherSection,
                        fontSize: 14.0,
                        color: black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: TextWidget(
                text: 'Cancel',
                fontSize: 16.0,
                color: grey,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  try {
                    await _studentService.createStudent(
                      name: nameController.text.trim(),
                      teacherId: widget.teacherId,
                      section: widget.teacherSection,
                    );
                    Navigator.pop(context);
                    _loadStudents();
                    Fluttertoast.showToast(
                      msg: 'Student added successfully',
                      backgroundColor: Colors.green,
                      textColor: white,
                    );
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: 'Error adding student',
                      backgroundColor: Colors.red,
                      textColor: white,
                    );
                  }
                } else {
                  Fluttertoast.showToast(
                    msg: 'Please fill all fields',
                    backgroundColor: Colors.red,
                    textColor: white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
              child: TextWidget(
                text: 'Add',
                fontSize: 16.0,
                color: white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get level statistics for a specific level
  Map<String, dynamic> getLevelStats(int levelNumber) {
    int totalStudents = _students.length;
    int completedStudents = 0;
    double totalScore = 0;

    for (var student in _students) {
      final levelProgress = student['levelProgress'];
      if (levelProgress != null && levelProgress['$levelNumber'] != null) {
        final levelData = levelProgress['$levelNumber'];
        if (levelData['completed'] == true) {
          completedStudents++;
          totalScore += (levelData['score'] ?? 0).toDouble();
        }
      }
    }

    return {
      'totalStudents': totalStudents,
      'completedStudents': completedStudents,
      'averageScore':
          completedStudents > 0 ? totalScore / completedStudents : 0.0,
    };
  }

  int _getExpectedTotalItemsForLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > levels.length) {
      return 0;
    }
    final dynamic expected = levels[levelNumber - 1]['totalItems'];
    return expected is num ? expected.toInt() : 0;
  }

  int _getDisplayTotalItems(dynamic storedTotalItems, int expectedTotalItems) {
    final int loaded =
        storedTotalItems is num ? storedTotalItems.toInt() : expectedTotalItems;

    if (expectedTotalItems > 0 && loaded > 0 && loaded < expectedTotalItems) {
      return expectedTotalItems;
    }

    return loaded;
  }

  void exportProgress() {
    // Placeholder for export action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(
            text: 'Exporting progress report...', fontSize: 16.0, color: white),
        backgroundColor: primary,
      ),
    );
  }

  void _showStudentLevelHistory(String studentId, String studentName,
      int levelNumber, Map<String, dynamic> levelData) {
    // Extract per-item results (which items were completed or failed)
    final dynamic results = levelData['results'];
    final Set<int> completedItems = <int>{};
    final Set<int> failedItems = <int>{};

    final int expectedTotalItems = _getExpectedTotalItemsForLevel(levelNumber);
    final int displayTotalItems = _getDisplayTotalItems(
      levelData['totalItems'],
      expectedTotalItems,
    );

    if (results is Map) {
      final dynamic completed = results['completedItems'];
      final dynamic failed = results['failedItems'];

      if (completed is List) {
        completedItems.addAll(completed.map<int>((e) => (e as num).toInt()));
      }
      if (failed is List) {
        failedItems.addAll(failed.map<int>((e) => (e as num).toInt()));
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: levels[levelNumber - 1]['color'],
                    child: TextWidget(
                      text: studentName[0],
                      fontSize: 18.0,
                      color: white,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: studentName,
                          fontSize: 20.0,
                          color: black,
                          isBold: true,
                        ),
                        TextWidget(
                          text:
                              '${levels[levelNumber - 1]['title']} - ${levels[levelNumber - 1]['description']}',
                          fontSize: 16.0,
                          color: levels[levelNumber - 1]['color'],
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: grey),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // Level completion status
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: levelData['completed']
                      ? levels[levelNumber - 1]['color'].withOpacity(0.1)
                      : grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: levelData['completed']
                        ? levels[levelNumber - 1]['color']
                        : grey,
                    width: 2.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      levelData['completed'] ? Icons.check_circle : Icons.lock,
                      color: levelData['completed']
                          ? levels[levelNumber - 1]['color']
                          : grey,
                      size: 30.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: levelData['completed']
                                ? 'Level Completed'
                                : 'Level Not Started',
                            fontSize: 18.0,
                            color: levelData['completed']
                                ? levels[levelNumber - 1]['color']
                                : grey,
                            isBold: true,
                          ),
                          if (levelData['completed']) ...[
                            const SizedBox(height: 8.0),
                            TextWidget(
                              text:
                                  'Score: ${levelData['score']}/$displayTotalItems',
                              fontSize: 16.0,
                              color: primary,
                              isBold: true,
                            ),
                            const SizedBox(height: 4.0),
                            TextWidget(
                              text: 'Completed on: ${levelData['date']}',
                              fontSize: 14.0,
                              color: grey,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Level content preview
              TextWidget(
                text: 'Level Content',
                fontSize: 18.0,
                color: black,
                isBold: true,
              ),
              const SizedBox(height: 12.0),
              Expanded(
                child: ListView.builder(
                  itemCount: levels[levelNumber - 1]['content'].length,
                  itemBuilder: (context, index) {
                    final item = levels[levelNumber - 1]['content'][index];
                    final bool isItemCompleted = completedItems.contains(index);
                    final bool isItemFailed = failedItems.contains(index);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isItemFailed
                            ? Colors.red.withOpacity(0.05)
                            : isItemCompleted
                                ? Colors.green.withOpacity(0.05)
                                : white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isItemFailed
                              ? Colors.red
                              : isItemCompleted
                                  ? Colors.green
                                  : levels[levelNumber - 1]['color'],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item['type'] == 'Word'
                                    ? Icons.text_fields
                                    : Icons.short_text,
                                color: levels[levelNumber - 1]['color'],
                                size: 20.0,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: TextWidget(
                                  text: item['content'],
                                  fontSize: 16.0,
                                  color: isItemFailed
                                      ? Colors.red
                                      : isItemCompleted
                                          ? Colors.green
                                          : black,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: levels[levelNumber - 1]['color']
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: TextWidget(
                                  text: item['type'],
                                  fontSize: 12.0,
                                  color: levels[levelNumber - 1]['color'],
                                  isBold: true,
                                ),
                              ),
                            ],
                          ),
                          // Audio recording player
                          if (levelData['audioRecordings'] != null &&
                              levelData['audioRecordings'][index] != null) ...[
                            const SizedBox(height: 8.0),
                            AudioPlayerWidget(
                              audioUrl: levelData['audioRecordings'][index],
                              title: 'Recording for ${item['content']}',
                              width: double.infinity,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PracticeScreen(
                              level: levelNumber,
                              levelTitle: 'Level $levelNumber',
                              levelDescription: levels[levelNumber - 1]
                                  ['description'],
                              isTeacher: true,
                              teacherName: widget.teacherName,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.play_arrow,
                          color: levels[levelNumber - 1]['color']),
                      label: TextWidget(
                        text: 'Practice',
                        fontSize: 14.0,
                        color: levels[levelNumber - 1]['color'],
                        isBold: true,
                      ),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: levels[levelNumber - 1]['color']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            title: TextWidget(
                              text: 'Reset Score',
                              fontSize: 20.0,
                              color: Colors.red,
                              isBold: true,
                            ),
                            content: TextWidget(
                              text:
                                  'Are you sure you want to reset ${studentName}\'s progress for Level $levelNumber? This action cannot be undone.',
                              fontSize: 16.0,
                              color: grey,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: TextWidget(
                                  text: 'Cancel',
                                  fontSize: 16.0,
                                  color: grey,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: TextWidget(
                                  text: 'Reset',
                                  fontSize: 16.0,
                                  color: white,
                                  isBold: true,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await _studentService.resetStudentProgress(
                                studentId,
                                level: levelNumber);
                            Navigator.pop(context);
                            _loadStudents(); // Reload to reflect changes
                            Fluttertoast.showToast(
                              msg: 'Score reset successfully',
                              backgroundColor: Colors.green,
                              textColor: white,
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: 'Error resetting score',
                              backgroundColor: Colors.red,
                              textColor: white,
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.refresh, color: white, size: 18),
                      label: TextWidget(
                        text: 'Reset',
                        fontSize: 14.0,
                        color: white,
                        isBold: true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: white, size: 18),
                      label: TextWidget(
                        text: 'Close',
                        fontSize: 14.0,
                        color: white,
                        isBold: true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteStudentDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 30.0),
            const SizedBox(width: 12.0),
            TextWidget(
              text: 'Delete Student',
              fontSize: 20.0,
              color: Colors.red,
              isBold: true,
            ),
          ],
        ),
        content: TextWidget(
          text: 'Are you sure you want to delete ${student['name']}? This action cannot be undone.',
          fontSize: 16.0,
          color: grey,
          align: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 16.0,
              color: grey,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _studentService.deleteStudent(student['id']);
                _loadStudents();
                Fluttertoast.showToast(
                  msg: '${student['name']} deleted successfully',
                  backgroundColor: Colors.green,
                  textColor: white,
                );
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Error deleting student: ${e.toString()}',
                  backgroundColor: Colors.red,
                  textColor: white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: TextWidget(
              text: 'Delete',
              fontSize: 16.0,
              color: white,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelStudentList(int levelIndex) {
    final level = levels[levelIndex];
    final levelStats = getLevelStats(level['level']);

    final int expectedTotalItems =
        _getExpectedTotalItemsForLevel(level['level'] as int);

    // Build a locally sorted copy of students by performance band for this level
    final List<Map<String, dynamic>> sortedStudents = List.from(_students);
    sortedStudents.sort((a, b) {
      final dynamic aLevelProgress = a['levelProgress'];
      final dynamic bLevelProgress = b['levelProgress'];

      final dynamic aLevelData = aLevelProgress is Map
          ? (aLevelProgress[level['level']] ??
              aLevelProgress['${level['level']}'])
          : null;
      final dynamic bLevelData = bLevelProgress is Map
          ? (bLevelProgress[level['level']] ??
              bLevelProgress['${level['level']}'])
          : null;

      final bool aCompleted =
          aLevelData != null && (aLevelData['completed'] == true);
      final bool bCompleted =
          bLevelData != null && (bLevelData['completed'] == true);

      final double? aPercent = aCompleted
          ? ((_getDisplayTotalItems(
                      aLevelData['totalItems'], expectedTotalItems)) >
                  0
              ? (aLevelData['score'] ?? 0) *
                  100.0 /
                  (_getDisplayTotalItems(
                      aLevelData['totalItems'], expectedTotalItems))
              : null)
          : null;
      final double? bPercent = bCompleted
          ? ((_getDisplayTotalItems(
                      bLevelData['totalItems'], expectedTotalItems)) >
                  0
              ? (bLevelData['score'] ?? 0) *
                  100.0 /
                  (_getDisplayTotalItems(
                      bLevelData['totalItems'], expectedTotalItems))
              : null)
          : null;

      final int aBand = _getPerformanceBandOrder(aPercent, aCompleted);
      final int bBand = _getPerformanceBandOrder(bPercent, bCompleted);

      if (aBand != bBand) {
        return aBand.compareTo(bBand);
      }

      // Within same band, sort by percentage descending, then name
      if ((aPercent ?? -1) != (bPercent ?? -1)) {
        return (bPercent ?? -1).compareTo(aPercent ?? -1);
      }

      return (a['name'] as String).compareTo(b['name'] as String);
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    level['icon'],
                    color: level['color'],
                    size: 30.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: '${level['title']} - ${level['description']}',
                          fontSize: 20.0,
                          color: level['color'],
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Student Progress',
                          fontSize: 16.0,
                          color: grey,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: grey),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // Level statistics
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: level['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: level['color'], width: 2.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        TextWidget(
                          text: '${levelStats['completedStudents']}',
                          fontSize: 24.0,
                          color: level['color'],
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Completed',
                          fontSize: 14.0,
                          color: grey,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: '${levelStats['totalStudents']}',
                          fontSize: 24.0,
                          color: level['color'],
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Total',
                          fontSize: 14.0,
                          color: grey,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: levelStats['completedStudents'] > 0
                              ? '${levelStats['averageScore'].toStringAsFixed(0)}'
                              : '0',
                          fontSize: 24.0,
                          color: level['color'],
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Avg Score',
                          fontSize: 14.0,
                          color: grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Student list header
              Row(
                children: [
                  TextWidget(
                    text: 'Students',
                    fontSize: 18.0,
                    color: black,
                    isBold: true,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: level['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextWidget(
                      text: '${level['totalItems']} items',
                      fontSize: 12.0,
                      color: level['color'],
                      isBold: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Student list
              Expanded(
                child: ListView.builder(
                  itemCount: sortedStudents.length,
                  itemBuilder: (context, index) {
                    final student = sortedStudents[index];
                    final dynamic levelProgress = student['levelProgress'];
                    final dynamic levelData = levelProgress is Map
                        ? (levelProgress[level['level']] ??
                            levelProgress['${level['level']}'])
                        : null;
                    final bool isCompleted =
                        levelData != null && levelData['completed'] == true;

                    double? percentage;
                    Color? performanceColor;
                    final int displayTotalItems = _getDisplayTotalItems(
                      levelData is Map ? levelData['totalItems'] : null,
                      expectedTotalItems,
                    );
                    if (isCompleted && displayTotalItems > 0) {
                      percentage =
                          (levelData['score'] ?? 0) * 100.0 / displayTotalItems;
                      performanceColor = _getPerformanceColor(percentage!);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isCompleted
                              ? level['color']
                              : grey.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Student avatar
                          CircleAvatar(
                            backgroundColor:
                                isCompleted ? level['color'] : grey,
                            radius: 20.0,
                            child: TextWidget(
                              text: student['name'][0],
                              fontSize: 16.0,
                              color: white,
                              isBold: true,
                            ),
                          ),
                          const SizedBox(width: 12.0),

                          // Student info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: student['name'],
                                  fontSize: 16.0,
                                  color: black,
                                  isBold: true,
                                ),
                                if (isCompleted) ...[
                                  const SizedBox(height: 4.0),
                                  TextWidget(
                                    text: percentage != null
                                        ? 'Score: ${levelData['score']}/$displayTotalItems (${percentage.toStringAsFixed(0)}%) • ${levelData['date']}'
                                        : 'Score: ${levelData['score']}/$displayTotalItems • ${levelData['date']}',
                                    fontSize: 14.0,
                                    color: performanceColor ?? grey,
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4.0),
                                  TextWidget(
                                    text: 'Not started',
                                    fontSize: 14.0,
                                    color: grey,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? level['color'].withOpacity(0.1)
                                  : grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted ? Icons.check_circle : Icons.lock,
                                  color: isCompleted ? level['color'] : grey,
                                  size: 16.0,
                                ),
                                const SizedBox(width: 4.0),
                                TextWidget(
                                  text: isCompleted ? 'Completed' : 'Locked',
                                  fontSize: 12.0,
                                  color: isCompleted ? level['color'] : grey,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: white),
                      label: TextWidget(
                        text: 'Close',
                        fontSize: 16.0,
                        color: white,
                        isBold: true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate summary stats based on actual completed levels
    final int totalStudents = _students.length;
    int completedLevels = 0;
    final int totalLevelSlots = totalStudents * levels.length;

    for (final student in _students) {
      final dynamic levelProgress = student['levelProgress'];
      if (levelProgress is Map) {
        for (int levelNumber = 1; levelNumber <= levels.length; levelNumber++) {
          final dynamic levelData =
              levelProgress[levelNumber] ?? levelProgress['$levelNumber'];
          if (levelData is Map && levelData['completed'] == true) {
            completedLevels++;
          }
        }
      }
    }

    final double averageAccuracy =
        totalLevelSlots > 0 ? (completedLevels * 100.0) / totalLevelSlots : 0.0;

    return Scaffold(
      backgroundColor: Colors.amber[100],
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16.0),
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
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40.0,
                      width: 40.0,
                    ),
                    const SizedBox(width: 12.0),
                    TextWidget(
                      text: 'Teacher Dashboard',
                      fontSize: 26.0,
                      color: white,
                      isBold: true,
                      fontFamily: 'Regular',
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.book, color: white, size: 28.0),
                      onPressed: () {},
                      tooltip: 'Test Practice',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              // Progress Summary
              Container(
                padding: const EdgeInsets.all(16.0),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        TextWidget(
                          text: '$totalStudents',
                          fontSize: 24.0,
                          color: primary,
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Students',
                          fontSize: 16.0,
                          color: grey,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: '$completedLevels',
                          fontSize: 24.0,
                          color: primary,
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Levels Completed',
                          fontSize: 16.0,
                          color: grey,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: '${averageAccuracy.toStringAsFixed(1)}%',
                          fontSize: 24.0,
                          color: primary,
                          isBold: true,
                        ),
                        TextWidget(
                          text: 'Progress',
                          fontSize: 16.0,
                          color: grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              // Levels Overview
              TextWidget(
                text: 'Learning Levels',
                fontSize: 24.0,
                color: black,
                isBold: true,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 280.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final levelStats = getLevelStats(level['level']);

                    return ScaleTransition(
                      scale: _cardAnimation,
                      child: GestureDetector(
                        onTap: () => _showLevelStudentList(index),
                        child: Container(
                          width: 180.0,
                          margin: const EdgeInsets.only(right: 16.0),
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: level['color'].withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20.0),
                            border:
                                Border.all(color: level['color'], width: 2.0),
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
                              Icon(
                                level['icon'],
                                size: 40.0,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8.0),
                              TextWidget(
                                text: level['title'],
                                fontSize: 20.0,
                                color: Colors.white,
                                isBold: true,
                                fontFamily: 'Regular',
                              ),
                              const SizedBox(height: 4.0),
                              TextWidget(
                                text: level['description'],
                                fontSize: 14.0,
                                color: Colors.white,
                                fontFamily: 'Regular',
                                align: TextAlign.center,
                              ),
                              const SizedBox(height: 8.0),
                              TextWidget(
                                text: '${level['totalItems']} items',
                                fontSize: 12.0,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Regular',
                              ),
                              const SizedBox(height: 8.0),
                              // Score statistics
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  children: [
                                    TextWidget(
                                      text:
                                          '${levelStats['completedStudents']}/${levelStats['totalStudents']}',
                                      fontSize: 14.0,
                                      color: Colors.white,
                                      isBold: true,
                                    ),
                                    TextWidget(
                                      text: 'completed',
                                      fontSize: 10.0,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                              if (levelStats['completedStudents'] > 0) ...[
                                const SizedBox(height: 4.0),
                                TextWidget(
                                  text:
                                      'Avg: ${levelStats['averageScore'].toStringAsFixed(0)}',
                                  fontSize: 12.0,
                                  color: Colors.white,
                                  isBold: true,
                                ),
                              ],
                              const SizedBox(height: 8.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32.0),
              TextWidget(
                text: 'Students Progress',
                fontSize: 24.0,
                color: black,
                isBold: true,
                fontFamily: 'Regular',
              ),
              const SizedBox(height: 16.0),
              // Search Bar and Section Filter Row
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: secondary, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: grey.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle:
                              TextStyle(color: grey, fontFamily: 'Regular'),
                          prefixIcon: Icon(Icons.search, color: primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Section Filter Dropdown
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: secondary, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: grey.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.class_, color: primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _getSectionEmoji(widget.teacherSection),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextWidget(
                              text: widget.teacherSection,
                              fontSize: 14.0,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Student List with Level Progress
              _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: primary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        int completedLevels = 0;
                        final dynamic levelProgress = student['levelProgress'];
                        if (levelProgress is Map) {
                          for (int levelNumber = 1;
                              levelNumber <= levels.length;
                              levelNumber++) {
                            final dynamic levelData =
                                levelProgress[levelNumber] ??
                                    levelProgress['$levelNumber'];
                            if (levelData is Map &&
                                levelData['completed'] == true) {
                              completedLevels++;
                            }
                          }
                        }
    
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
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
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: primary,
                              child: TextWidget(
                                text: student['name'][0],
                                fontSize: 18.0,
                                color: white,
                                isBold: true,
                              ),
                            ),
                            title: TextWidget(
                              text: student['name'],
                              fontSize: 20.0,
                              color: black,
                              isBold: true,
                              fontFamily: 'Regular',
                            ),
                            subtitle: TextWidget(
                              text: '$completedLevels/5 levels completed',
                              fontSize: 14.0,
                              color: grey,
                              fontFamily: 'Regular',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: 24.0),
                              onPressed: () {
                                _showDeleteStudentDialog(student);
                              },
                              tooltip: 'Delete Student',
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    // Level progress bars
                                    ...List.generate(5, (levelIndex) {
                                      final levelNumber = levelIndex + 1;
                                      final dynamic levelProgress =
                                          student['levelProgress'];
                                      final dynamic levelData =
                                          levelProgress is Map
                                              ? (levelProgress[levelNumber] ??
                                                  levelProgress['$levelNumber'])
                                              : null;
                                      final bool isCompleted =
                                          levelData != null &&
                                              levelData['completed'] == true;

                                      return GestureDetector(
                                        onTap: () {
                                          _showStudentLevelHistory(
                                            student['id'],
                                            student['name'],
                                            levelNumber,
                                            levelData ??
                                                {
                                                  'completed': false,
                                                  'score': 0,
                                                  'totalItems':
                                                      levels[levelIndex]
                                                          ['totalItems'],
                                                  'date': null,
                                                },
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 12.0),
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? levels[levelIndex]['color']
                                                    .withOpacity(0.1)
                                                : grey.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            border: Border.all(
                                              color: isCompleted
                                                  ? levels[levelIndex]['color']
                                                  : grey,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCompleted
                                                    ? Icons.check_circle
                                                    : Icons.lock,
                                                color: isCompleted
                                                    ? levels[levelIndex]
                                                        ['color']
                                                    : grey,
                                                size: 24.0,
                                              ),
                                              const SizedBox(width: 12.0),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextWidget(
                                                      text:
                                                          'Level $levelNumber - ${levels[levelIndex]['description']}',
                                                      fontSize: 16.0,
                                                      color: isCompleted
                                                          ? levels[levelIndex]
                                                              ['color']
                                                          : grey,
                                                      isBold: true,
                                                    ),
                                                    if (isCompleted &&
                                                        levelData != null) ...[
                                                      const SizedBox(
                                                          height: 4.0),
                                                      TextWidget(
                                                        text:
                                                            'Score: ${levelData['score']}/${levelData['totalItems']} • ${levelData['date'] ?? 'Unknown'}',
                                                        fontSize: 14.0,
                                                        color: grey,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: isCompleted
                                                    ? levels[levelIndex]
                                                        ['color']
                                                    : grey,
                                                size: 16.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
