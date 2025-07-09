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
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = 'Word';
  String _selectedCategory = 'Animals';
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;

  // Placeholder data for students and their practice history
  final List<Map<String, dynamic>> students = [
    {
      'name': 'Emma',
      'history': [
        {
          'content': 'Dog',
          'correct': true,
          'date': '2025-07-07',
          'category': 'Animals'
        },
        {
          'content': 'The sun shines',
          'correct': false,
          'date': '2025-07-07',
          'category': 'Nature'
        },
      ],
    },
    {
      'name': 'Liam',
      'history': [
        {
          'content': 'Tree',
          'correct': true,
          'date': '2025-07-06',
          'category': 'Nature'
        },
        {
          'content': 'I like to play',
          'correct': true,
          'date': '2025-07-06',
          'category': 'Daily Life'
        },
      ],
    },
    {
      'name': 'Max',
      'history': [
        {
          'content': 'Apple',
          'correct': true,
          'date': '2025-07-06',
          'category': 'Food'
        },
        {
          'content': 'The cat runs',
          'correct': false,
          'date': '2025-07-06',
          'category': 'Animals'
        },
      ],
    },
  ];

  // Placeholder data for existing words/sentences
  final List<Map<String, String>> wordSentenceList = [
    {'type': 'Word', 'content': 'Dog', 'category': 'Animals'},
    {'type': 'Sentence', 'content': 'The sun shines', 'category': 'Nature'},
    {'type': 'Word', 'content': 'Apple', 'category': 'Food'},
    {'type': 'Sentence', 'content': 'I like to play', 'category': 'Daily Life'},
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
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_contentController.text.isNotEmpty) {
      setState(() {
        wordSentenceList.add({
          'type': _selectedType,
          'content': _contentController.text,
          'category': _selectedCategory,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text:
                'Added $_selectedType: ${_contentController.text} ($_selectedCategory)',
            fontSize: 16.0,
            color: white,
          ),
          backgroundColor: primary,
        ),
      );
      _contentController.clear();
    }
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
            text: 'Delete Item', fontSize: 20.0, color: black, isBold: true),
        content: TextWidget(
          text:
              'Are you sure you want to delete "${wordSentenceList[index]['content']}"?',
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
                wordSentenceList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                      text: 'Item deleted', fontSize: 16.0, color: white),
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

  @override
  Widget build(BuildContext context) {
    // Calculate summary stats
    int totalStudents = students.length;
    int totalPracticed = students.fold(0, (sum, student) => 6);
    double accuracyRate = students.isNotEmpty ? 75 : 0.0;

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
                        'assets/images/logo.png', // Replace with actual mascot image
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
                            text: '$totalPracticed',
                            fontSize: 24.0,
                            color: primary,
                            isBold: true,
                          ),
                          TextWidget(
                            text: 'Practiced',
                            fontSize: 16.0,
                            color: grey,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          TextWidget(
                            text: '$accuracyRate%',
                            fontSize: 24.0,
                            color: primary,
                            isBold: true,
                          ),
                          TextWidget(
                            text: 'Accuracy',
                            fontSize: 16.0,
                            color: grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                // Add Word/Sentence Form
                TextWidget(
                  text: 'Add New Word or Sentence',
                  fontSize: 24.0,
                  color: black,
                  isBold: true,
                  fontFamily: 'Regular',
                ),
                const SizedBox(height: 16.0),
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
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: ['Word', 'Sentence'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: TextWidget(
                              text: value,
                              fontSize: 18.0,
                              color: primary,
                              fontFamily: 'Regular',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        underline: Container(height: 2, color: secondary),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          hintText: 'Enter $_selectedType',
                          hintStyle:
                              TextStyle(color: grey, fontFamily: 'Regular'),
                          prefixIcon: Icon(
                            _selectedType == 'Word'
                                ? Icons.text_fields
                                : Icons.short_text,
                            color: primary,
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
                      ScaleTransition(
                        scale: _cardAnimation,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon:
                              Icon(Icons.add_circle, color: white, size: 24.0),
                          label: TextWidget(
                            text: 'Add $_selectedType',
                            fontSize: 18.0,
                            color: white,
                            isBold: true,
                            fontFamily: 'Regular',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: white,
                            minimumSize: const Size(double.infinity, 50.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 6.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),
                // Manage Words/Sentences
                TextWidget(
                  text: 'Manage Words & Sentences',
                  fontSize: 24.0,
                  color: black,
                  isBold: true,
                  fontFamily: 'Regular',
                ),
                const SizedBox(height: 16.0),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: wordSentenceList.length,
                  itemBuilder: (context, index) {
                    final item = wordSentenceList[index];
                    return ScaleTransition(
                      scale: _cardAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextWidget(
                              text: item['type']!,
                              fontSize: 18.0,
                              color: grey,
                              isItalize: true,
                            ),
                            TextWidget(
                              text: item['content']!,
                              fontSize: 24.0,
                              color: primary,
                              isBold: true,
                              maxLines: 2,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red, size: 35.0),
                              onPressed: () => _deleteItem(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16.0),
                // Export Button
                ScaleTransition(
                  scale: _cardAnimation,
                  child: ElevatedButton.icon(
                    onPressed: _exportProgress,
                    icon: Icon(Icons.download, color: white, size: 24.0),
                    label: TextWidget(
                      text: 'Export Progress Report',
                      fontSize: 18.0,
                      color: white,
                      isBold: true,
                      fontFamily: 'Regular',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: white,
                      minimumSize: const Size(double.infinity, 50.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 6.0,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                TextWidget(
                  text: 'Students',
                  fontSize: 24.0,
                  color: black,
                  isBold: true,
                  fontFamily: 'Regular',
                ),
                // Student List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ExpansionTile(
                      leading: Icon(Icons.person, color: primary, size: 30.0),
                      title: TextWidget(
                        text: student['name'],
                        fontSize: 20.0,
                        color: black,
                        isBold: true,
                        fontFamily: 'Regular',
                      ),
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: student['history'].length,
                            itemBuilder: (context, historyIndex) {
                              final item = student['history'][historyIndex];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PracticeScreen(
                                              isTeacher: true,
                                            )),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                        color: secondary, width: 2.0),
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
                                      Icon(
                                        item['correct']
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: item['correct']
                                            ? Colors.green
                                            : Colors.red,
                                        size: 28.0,
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: item['content'],
                                              fontSize: 22.0,
                                              color: black,
                                              isBold: true,
                                              fontFamily: 'Regular',
                                            ),
                                            TextWidget(
                                              text:
                                                  'Practiced on: ${item['date']}',
                                              fontSize: 14.0,
                                              color: grey,
                                              fontFamily: 'Regular',
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
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
