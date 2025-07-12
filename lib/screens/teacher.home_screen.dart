import 'package:flutter/material.dart';
import 'package:word_tales/screens/practice_screen.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Level data with descriptions and content
  final List<Map<String, dynamic>> levels = [
    {
      'level': 1,
      'title': 'Level 1',
      'description': '1 Letter Words',
      'icon': Icons.abc,
      'color': Colors.red,
      'totalItems': 5,
      'content': [
        {'type': 'Word', 'content': 'A'},
        {'type': 'Word', 'content': 'I'},
        {'type': 'Word', 'content': 'O'},
        {'type': 'Word', 'content': 'U'},
        {'type': 'Word', 'content': 'E'},
      ],
    },
    {
      'level': 2,
      'title': 'Level 2',
      'description': '2 Letter Words',
      'icon': Icons.text_fields,
      'color': Colors.orange,
      'totalItems': 10,
      'content': [
        {'type': 'Word', 'content': 'AT'},
        {'type': 'Word', 'content': 'IT'},
        {'type': 'Word', 'content': 'ON'},
        {'type': 'Word', 'content': 'UP'},
        {'type': 'Word', 'content': 'IN'},
        {'type': 'Word', 'content': 'GO'},
        {'type': 'Word', 'content': 'TO'},
        {'type': 'Word', 'content': 'DO'},
        {'type': 'Word', 'content': 'NO'},
        {'type': 'Word', 'content': 'SO'},
      ],
    },
    {
      'level': 3,
      'title': 'Level 3',
      'description': '3 Letter Words',
      'icon': Icons.text_format,
      'color': Colors.yellow,
      'totalItems': 15,
      'content': [
        {'type': 'Word', 'content': 'CAT'},
        {'type': 'Word', 'content': 'DOG'},
        {'type': 'Word', 'content': 'SUN'},
        {'type': 'Word', 'content': 'RUN'},
        {'type': 'Word', 'content': 'BIG'},
        {'type': 'Word', 'content': 'RED'},
        {'type': 'Word', 'content': 'BLUE'},
        {'type': 'Word', 'content': 'HOT'},
        {'type': 'Word', 'content': 'COLD'},
        {'type': 'Word', 'content': 'NEW'},
        {'type': 'Word', 'content': 'OLD'},
        {'type': 'Word', 'content': 'BAD'},
        {'type': 'Word', 'content': 'GOOD'},
        {'type': 'Word', 'content': 'FUN'},
        {'type': 'Word', 'content': 'SAD'},
      ],
    },
    {
      'level': 4,
      'title': 'Level 4',
      'description': '4 Letter Words',
      'icon': Icons.text_snippet,
      'color': Colors.green,
      'totalItems': 20,
      'content': [
        {'type': 'Word', 'content': 'TREE'},
        {'type': 'Word', 'content': 'BOOK'},
        {'type': 'Word', 'content': 'PLAY'},
        {'type': 'Word', 'content': 'JUMP'},
        {'type': 'Word', 'content': 'WALK'},
        {'type': 'Word', 'content': 'TALK'},
        {'type': 'Word', 'content': 'READ'},
        {'type': 'Word', 'content': 'WRITE'},
        {'type': 'Word', 'content': 'DRAW'},
        {'type': 'Word', 'content': 'SING'},
        {'type': 'Word', 'content': 'DANCE'},
        {'type': 'Word', 'content': 'SWIM'},
        {'type': 'Word', 'content': 'FISH'},
        {'type': 'Word', 'content': 'BIRD'},
        {'type': 'Word', 'content': 'FROG'},
        {'type': 'Word', 'content': 'DUCK'},
        {'type': 'Word', 'content': 'BEAR'},
        {'type': 'Word', 'content': 'LION'},
        {'type': 'Word', 'content': 'TIGER'},
        {'type': 'Word', 'content': 'HORSE'},
      ],
    },
    {
      'level': 5,
      'title': 'Level 5',
      'description': 'Sentences',
      'icon': Icons.article,
      'color': Colors.blue,
      'totalItems': 20,
      'content': [
        {'type': 'Sentence', 'content': 'The cat is happy'},
        {'type': 'Sentence', 'content': 'I like to play'},
        {'type': 'Sentence', 'content': 'The sun shines bright'},
        {'type': 'Sentence', 'content': 'We can run fast'},
        {'type': 'Sentence', 'content': 'The dog barks loud'},
        {'type': 'Sentence', 'content': 'I love to read books'},
        {'type': 'Sentence', 'content': 'The bird sings sweetly'},
        {'type': 'Sentence', 'content': 'We play in the park'},
        {'type': 'Sentence', 'content': 'The fish swims in water'},
        {'type': 'Sentence', 'content': 'I eat my breakfast'},
        {'type': 'Sentence', 'content': 'The tree grows tall'},
        {'type': 'Sentence', 'content': 'We walk to school'},
        {'type': 'Sentence', 'content': 'The flower smells nice'},
        {'type': 'Sentence', 'content': 'I draw a picture'},
        {'type': 'Sentence', 'content': 'The moon is bright'},
        {'type': 'Sentence', 'content': 'We sing a song'},
        {'type': 'Sentence', 'content': 'The car goes fast'},
        {'type': 'Sentence', 'content': 'I write my name'},
        {'type': 'Sentence', 'content': 'The ball bounces high'},
        {'type': 'Sentence', 'content': 'We dance together'},
      ],
    },
  ];

  // Placeholder data for students and their level progress
  final List<Map<String, dynamic>> students = [
    {
      'name': 'Emma',
      'levelProgress': {
        1: {
          'completed': true,
          'score': 50,
          'totalItems': 5,
          'date': '2025-07-07'
        },
        2: {
          'completed': true,
          'score': 90,
          'totalItems': 10,
          'date': '2025-07-08'
        },
        3: {'completed': false, 'score': 0, 'totalItems': 15, 'date': null},
        4: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
        5: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
      },
    },
    {
      'name': 'Liam',
      'levelProgress': {
        1: {
          'completed': true,
          'score': 50,
          'totalItems': 5,
          'date': '2025-07-06'
        },
        2: {
          'completed': true,
          'score': 80,
          'totalItems': 10,
          'date': '2025-07-07'
        },
        3: {
          'completed': true,
          'score': 120,
          'totalItems': 15,
          'date': '2025-07-08'
        },
        4: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
        5: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
      },
    },
    {
      'name': 'Max',
      'levelProgress': {
        1: {
          'completed': true,
          'score': 50,
          'totalItems': 5,
          'date': '2025-07-05'
        },
        2: {'completed': false, 'score': 0, 'totalItems': 10, 'date': null},
        3: {'completed': false, 'score': 0, 'totalItems': 15, 'date': null},
        4: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
        5: {'completed': false, 'score': 0, 'totalItems': 20, 'date': null},
      },
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get filtered students based on search query
  List<Map<String, dynamic>> get filteredStudents {
    if (_searchQuery.isEmpty) {
      return students;
    }
    return students
        .where((student) =>
            student['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Get level statistics for a specific level
  Map<String, dynamic> getLevelStats(int levelNumber) {
    int totalStudents = students.length;
    int completedStudents = 0;
    int totalScore = 0;
    double averageScore = 0.0;

    for (var student in students) {
      final levelData = student['levelProgress'][levelNumber];
      if (levelData != null && levelData['completed']) {
        completedStudents++;
        totalScore += 5;
      }
    }

    if (completedStudents > 0) {
      averageScore = totalScore / completedStudents;
    }

    return {
      'totalStudents': totalStudents,
      'completedStudents': completedStudents,
      'averageScore': averageScore,
      'completionRate':
          totalStudents > 0 ? (completedStudents / totalStudents) * 100 : 0.0,
    };
  }

  void _addItemToLevel(int levelIndex) {
    final TextEditingController contentController = TextEditingController();
    String selectedType = levels[levelIndex]['content'][0]
        ['type']; // Default to first type in level

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Add Item to ${levels[levelIndex]['title']}',
          fontSize: 20.0,
          color: black,
          isBold: true,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16.0),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                hintText: 'Enter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(text: 'Cancel', fontSize: 16.0, color: primary),
          ),
          TextButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                setState(() {
                  levels[levelIndex]['content'].add({
                    'type': selectedType,
                    'content': contentController.text,
                  });
                  levels[levelIndex]['totalItems'] =
                      levels[levelIndex]['content'].length;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text:
                          'Added $selectedType to ${levels[levelIndex]['title']}',
                      fontSize: 16.0,
                      color: white,
                    ),
                    backgroundColor: primary,
                  ),
                );
              }
            },
            child: TextWidget(text: 'Add', fontSize: 16.0, color: primary),
          ),
        ],
      ),
    );
  }

  void _editItemInLevel(int levelIndex, int itemIndex) {
    final item = levels[levelIndex]['content'][itemIndex];
    final TextEditingController contentController =
        TextEditingController(text: item['content']);
    String selectedType = item['type'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Edit Item in ${levels[levelIndex]['title']}',
          fontSize: 20.0,
          color: black,
          isBold: true,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16.0),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                hintText: 'Enter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(text: 'Cancel', fontSize: 16.0, color: primary),
          ),
          TextButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                setState(() {
                  levels[levelIndex]['content'][itemIndex] = {
                    'type': selectedType,
                    'content': contentController.text,
                  };
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Updated item in ${levels[levelIndex]['title']}',
                      fontSize: 16.0,
                      color: white,
                    ),
                    backgroundColor: primary,
                  ),
                );
              }
            },
            child: TextWidget(text: 'Update', fontSize: 16.0, color: primary),
          ),
        ],
      ),
    );
  }

  void _deleteItemFromLevel(int levelIndex, int itemIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Delete Item',
          fontSize: 20.0,
          color: black,
          isBold: true,
        ),
        content: TextWidget(
          text:
              'Are you sure you want to delete "${levels[levelIndex]['content'][itemIndex]['content']}" from ${levels[levelIndex]['title']}?',
          fontSize: 16.0,
          color: grey,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(text: 'Cancel', fontSize: 16.0, color: primary),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                levels[levelIndex]['content'].removeAt(itemIndex);
                levels[levelIndex]['totalItems'] =
                    levels[levelIndex]['content'].length;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                    text: 'Item deleted from ${levels[levelIndex]['title']}',
                    fontSize: 16.0,
                    color: white,
                  ),
                  backgroundColor: primary,
                ),
              );
            },
            child:
                TextWidget(text: 'Delete', fontSize: 16.0, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _manageLevelContent(int levelIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    levels[levelIndex]['icon'],
                    color: levels[levelIndex]['color'],
                    size: 30.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextWidget(
                      text:
                          '${levels[levelIndex]['title']} - ${levels[levelIndex]['description']}',
                      fontSize: 20.0,
                      color: levels[levelIndex]['color'],
                      isBold: true,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: grey),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addItemToLevel(levelIndex),
                    icon: Icon(Icons.add, color: white, size: 20.0),
                    label: TextWidget(
                      text: 'Add Item',
                      fontSize: 16.0,
                      color: white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: levels[levelIndex]['color'],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  itemCount: levels[levelIndex]['content'].length,
                  itemBuilder: (context, itemIndex) {
                    final item = levels[levelIndex]['content'][itemIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: levels[levelIndex]['color']),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['type'] == 'Word'
                                ? Icons.text_fields
                                : Icons.short_text,
                            color: levels[levelIndex]['color'],
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: TextWidget(
                              text: item['content'],
                              fontSize: 16.0,
                              color: black,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _editItemInLevel(levelIndex, itemIndex),
                            icon: Icon(Icons.edit, color: primary, size: 20.0),
                          ),
                          IconButton(
                            onPressed: () =>
                                _deleteItemFromLevel(levelIndex, itemIndex),
                            icon: Icon(Icons.delete,
                                color: Colors.red, size: 20.0),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportProgress() {
    // Placeholder for export action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(
            text: 'Exporting progress report...', fontSize: 16.0, color: white),
        backgroundColor: primary,
      ),
    );
  }

  void _showStudentLevelHistory(
      String studentName, int levelNumber, Map<String, dynamic> levelData) {
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
                                  'Score: ${levelData['score']}/${levelData['totalItems']}',
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(8.0),
                        border:
                            Border.all(color: levels[levelNumber - 1]['color']),
                      ),
                      child: Row(
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
                              color: black,
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
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.play_arrow,
                          color: levels[levelNumber - 1]['color']),
                      label: TextWidget(
                        text: 'Practice Level',
                        fontSize: 16.0,
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
                  const SizedBox(width: 12.0),
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

  void _showLevelStudentList(int levelIndex) {
    final level = levels[levelIndex];
    final levelStats = getLevelStats(level['level']);

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
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final levelData = student['levelProgress'][level['level']];
                    final isCompleted =
                        levelData != null && levelData['completed'];

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
                                    text:
                                        'Score: ${levelData['score']}/${levelData['totalItems']} • ${levelData['date']}',
                                    fontSize: 14.0,
                                    color: grey,
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _manageLevelContent(levelIndex);
                      },
                      icon: Icon(Icons.settings, color: level['color']),
                      label: TextWidget(
                        text: 'Manage Level',
                        fontSize: 16.0,
                        color: level['color'],
                        isBold: true,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: level['color']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
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
    // Calculate summary stats
    int totalStudents = students.length;
    int totalCompletedLevels = students.fold(0, (sum, student) {
      return sum + 5;
    });
    double averageAccuracy = students.isNotEmpty
        ? (totalCompletedLevels * 100.0) / (students.length * 5)
        : 0.0;

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
                          text: '$totalCompletedLevels',
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
                              ElevatedButton.icon(
                                onPressed: () => _manageLevelContent(index),
                                icon: Icon(Icons.settings,
                                    color: level['color'], size: 16.0),
                                label: TextWidget(
                                  text: 'Manage',
                                  fontSize: 14.0,
                                  color: level['color'],
                                  fontFamily: 'Regular',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: level['color'],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  elevation: 2.0,
                                ),
                              ),
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
              // Search Bar
              Container(
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
                    hintStyle: TextStyle(color: grey, fontFamily: 'Regular'),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Student List with Level Progress
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final completedLevels = 1;

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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Level progress bars
                              ...List.generate(5, (levelIndex) {
                                final levelNumber = levelIndex + 1;
                                final levelData =
                                    student['levelProgress'][levelNumber];
                                final isCompleted = levelData != null &&
                                    levelData['completed'] == true;

                                return GestureDetector(
                                  onTap: () {
                                    _showStudentLevelHistory(
                                      student['name'],
                                      levelNumber,
                                      levelData,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? levels[levelIndex]['color']
                                              .withOpacity(0.1)
                                          : grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.0),
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
                                              ? levels[levelIndex]['color']
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
                                                const SizedBox(height: 4.0),
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
                                              ? levels[levelIndex]['color']
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
