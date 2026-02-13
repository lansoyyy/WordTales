import 'package:flutter/material.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:word_tales/services/practice_item_service.dart';
import 'package:word_tales/utils/words.dart';
import 'dart:async';

class TeacherPracticeAdminScreen extends StatefulWidget {
  final int level;
  final String levelTitle;
  final String teacherId;

  const TeacherPracticeAdminScreen({
    required this.level,
    required this.levelTitle,
    required this.teacherId,
  });

  @override
  State<TeacherPracticeAdminScreen> createState() =>
      _TeacherPracticeAdminScreenState();
}

class _TeacherPracticeAdminScreenState
    extends State<TeacherPracticeAdminScreen> {
  final PracticeItemService _practiceItemService = PracticeItemService();
  List<Map<String, dynamic>> _practiceItems = [];
  bool _isLoading = true;
  String? _selectedItemId;
  StreamSubscription<List<Map<String, dynamic>>>? _itemsSubscription;

  void _showStatusSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPracticeItems();
  }

  List<Map<String, String>> _defaultItemsForLevel() {
    if (widget.level == 1) {
      return oneLetterWords
          .take(10)
          .map((w) => {'type': 'Word', 'content': w, 'emoji': ''})
          .toList();
    }
    if (widget.level == 2) {
      return twoLetterWords
          .take(15)
          .map((w) => {'type': 'Word', 'content': w, 'emoji': ''})
          .toList();
    }
    if (widget.level == 3) {
      return threeLetterWords
          .take(20)
          .map((w) => {'type': 'Word', 'content': w, 'emoji': ''})
          .toList();
    }
    if (widget.level == 4) {
      return fourLetterWords
          .take(25)
          .map((w) => {'type': 'Word', 'content': w, 'emoji': ''})
          .toList();
    }
    if (widget.level == 5) {
      final sentences = [
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
      ];
      return sentences
          .map((s) => {'type': 'Sentence', 'content': s, 'emoji': ''})
          .toList();
    }
    return [];
  }

  Future<void> _loadPracticeItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _practiceItemService.ensureDefaultPracticeItems(
        teacherId: widget.teacherId,
        level: widget.level,
        defaultItems: _defaultItemsForLevel(),
      );
    } catch (_) {
      // ignore
    }

    await _itemsSubscription?.cancel();
    _itemsSubscription = _practiceItemService
        .streamCustomPracticeItems(
      level: widget.level,
      teacherId: widget.teacherId,
      includeInactive: true,
    )
        .listen((items) {
      if (!mounted) return;
      setState(() {
        _practiceItems = items;
        _isLoading = false;
      });
    });
  }

  Future<void> _refreshItems() async {
    await _loadPracticeItems();
  }

  Future<void> _showAddItemDialog() async {
    final typeController = TextEditingController(text: 'Word');
    final contentController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: TextWidget(
          text: 'Add Practice Item',
          fontSize: 20.0,
          color: primary,
          isBold: true,
        ),
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: 'Type',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Word', child: Text('Word')),
                  DropdownMenuItem(value: 'Sentence', child: Text('Sentence')),
                ],
                onChanged: (value) {
                  typeController.text = value ?? 'Word';
                },
              ),
              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Content',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: contentController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Enter word or sentence',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Emoji',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: emojiController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Enter emoji (e.g., 🐱)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ],
          ),
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
              final type = typeController.text.trim();
              final content = contentController.text.trim().toUpperCase();
              final emoji = emojiController.text.trim();

              if (type.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await _practiceItemService.addCustomPracticeItem(
                teacherId: widget.teacherId,
                level: widget.level,
                type: type,
                content: content,
                emoji: emoji,
              );

              if (!success) {
                _showStatusSnackBar(
                  message: 'Failed to add item. Please check Firestore access.',
                  backgroundColor: Colors.red,
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              _showStatusSnackBar(
                message: 'Item added',
                backgroundColor: Colors.green,
              );
              await _refreshItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: TextWidget(
              text: 'Add',
              fontSize: 16.0,
              color: white,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(Map<String, dynamic> item) async {
    final typeController = TextEditingController(text: item['type'] ?? 'Word');
    final contentController =
        TextEditingController(text: item['content'] ?? '');
    final emojiController = TextEditingController(text: item['emoji'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: TextWidget(
          text: 'Edit Practice Item',
          fontSize: 20.0,
          color: primary,
          isBold: true,
        ),
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: 'Type',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Word', child: Text('Word')),
                  DropdownMenuItem(value: 'Sentence', child: Text('Sentence')),
                ],
                onChanged: (value) {
                  typeController.text = value ?? 'Word';
                },
              ),
              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Content',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: contentController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Enter word or sentence',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextWidget(
                text: 'Emoji',
                fontSize: 16.0,
                color: grey,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: emojiController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: white,
                  hintText: 'Enter emoji (e.g., 🐱)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ],
          ),
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
              final type = typeController.text.trim();
              final content = contentController.text.trim().toUpperCase();
              final emoji = emojiController.text.trim();

              if (type.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success =
                  await _practiceItemService.updateCustomPracticeItem(
                itemId: item['id'],
                type: type,
                content: content,
                emoji: emoji,
              );

              if (!success) {
                _showStatusSnackBar(
                  message:
                      'Failed to update item. Please check Firestore access.',
                  backgroundColor: Colors.red,
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              _showStatusSnackBar(
                message: 'Item updated',
                backgroundColor: Colors.green,
              );
              await _refreshItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: TextWidget(
              text: 'Update',
              fontSize: 16.0,
              color: white,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: TextWidget(
          text: 'Delete Item',
          fontSize: 20.0,
          color: Colors.red,
          isBold: true,
        ),
        content: TextWidget(
          text: 'Are you sure you want to delete "${item['content']}"?',
          fontSize: 16.0,
          color: grey,
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
              final success =
                  await _practiceItemService.deleteCustomPracticeItem(
                itemId: item['id'],
              );

              if (!success) {
                _showStatusSnackBar(
                  message:
                      'Failed to delete item. Please check Firestore access.',
                  backgroundColor: Colors.red,
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              _showStatusSnackBar(
                message: 'Item deleted',
                backgroundColor: Colors.green,
              );
              await _refreshItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        title: TextWidget(
          text: '${widget.levelTitle} - Practice Items',
          fontSize: 22.0,
          color: white,
          isBold: true,
        ),
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: const Icon(Icons.arrow_back),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: const Icon(Icons.refresh),
            ),
            onPressed: _refreshItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _practiceItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64.0, color: grey),
                      const SizedBox(height: 16.0),
                      TextWidget(
                        text: 'No practice items yet',
                        fontSize: 18.0,
                        color: grey,
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: IconTheme(
                          data: const IconThemeData(color: Colors.white),
                          child: const Icon(Icons.add),
                        ),
                        label: TextWidget(
                          text: 'Add First Item',
                          fontSize: 16.0,
                          color: white,
                          isBold: true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _practiceItems.length,
                  itemBuilder: (context, index) {
                    final item = _practiceItems[index];
                    final isActive = item['is_active'] == true;
                    final String emoji =
                        (item['emoji'] ?? '').toString().trim().isNotEmpty
                            ? item['emoji'].toString()
                            : '🔤';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      color: isActive ? white : Colors.grey[200],
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: primary,
                          radius: 20.0,
                          child: TextWidget(
                            text: emoji,
                            fontSize: 24.0,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['content'] ?? '',
                              style: TextStyle(
                                fontSize: 20.0,
                                color: isActive ? black : black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Regular',
                                decoration: isActive
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
                                decorationColor: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              children: [
                                TextWidget(
                                  text: item['type'] ?? 'Word',
                                  fontSize: 14.0,
                                  color: grey,
                                ),
                                const SizedBox(width: 8.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: TextWidget(
                                    text: isActive ? 'Active' : 'Inactive',
                                    fontSize: 12.0,
                                    color: isActive ? Colors.green : Colors.red,
                                    isBold: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: primary,
                              onPressed: () => _showEditItemDialog(item),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.toggle_on),
                              color: primary,
                              onPressed: () async {
                                final success = await _practiceItemService
                                    .toggleCustomPracticeItem(
                                  itemId: item['id'],
                                  isActive: !isActive,
                                );

                                if (!success) {
                                  _showStatusSnackBar(
                                    message:
                                        'Failed to update status. Please check Firestore access.',
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }

                                _showStatusSnackBar(
                                  message: !isActive
                                      ? 'Item activated'
                                      : 'Item deactivated',
                                  backgroundColor: Colors.green,
                                );
                                await _refreshItems();
                              },
                              tooltip: isActive ? 'Deactivate' : 'Activate',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _showDeleteConfirmDialog(item),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
