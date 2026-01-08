import 'package:flutter/material.dart';
import 'package:word_tales/utils/colors.dart';
import 'package:word_tales/widgets/text_widget.dart';
import 'package:word_tales/widgets/button_widget.dart';
import 'package:word_tales/services/practice_item_service.dart';

class TeacherPracticeAdminScreen extends StatefulWidget {
  final int level;
  final String levelTitle;

  const TeacherPracticeAdminScreen({
    required this.level,
    required this.levelTitle,
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

  @override
  void initState() {
    super.initState();
    _loadPracticeItems();
  }

  Future<void> _loadPracticeItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _practiceItemService.getCustomPracticeItems(
      level: widget.level,
      studentId: 'admin', // Admin can see all items
    );

    setState(() {
      _practiceItems = items;
      _isLoading = false;
    });
  }

  Future<void> _refreshItems() async {
    await _loadPracticeItems();
  }

  Future<void> _showAddItemDialog() async {
    final typeController = TextEditingController();
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
                value: 'Word',
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
              final content = contentController.text.trim();
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

              await _practiceItemService.addCustomPracticeItem(
                teacherId: 'admin',
                level: widget.level,
                type: type,
                content: content,
                emoji: emoji,
              );

              Navigator.pop(context);
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
              final content = contentController.text.trim();
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

              await _practiceItemService.updateCustomPracticeItem(
                itemId: item['id'],
                type: type,
                content: content,
                emoji: emoji,
              );

              Navigator.pop(context);
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
              await _practiceItemService.deleteCustomPracticeItem(
                itemId: item['id'],
              );

              Navigator.pop(context);
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
                            text: item['emoji'] ?? '',
                            fontSize: 24.0,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: item['content'] ?? '',
                              fontSize: 20.0,
                              color: isActive ? black : grey,
                              isBold: true,
                              maxLines: 2,
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
                                await _practiceItemService
                                    .toggleCustomPracticeItem(
                                  itemId: item['id'],
                                  isActive: !isActive,
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
