import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<String> _notes = [
    'Quick reminder: Taply overlay requires SYSTEM_ALERT_WINDOW permission on Android 10+.',
    'Phase 2 tasks: Native Accessibility Service, PackageManager integration, and floating WindowManager.',
  ];

  final TextEditingController _textController = TextEditingController();

  void _addNote() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _notes.insert(0, _textController.text.trim());
      _textController.clear();
    });
    Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Quick Note'),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter your note here...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(onPressed: _addNote, child: const Text('Save Note')),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddDialog,
            tooltip: 'Add note',
          ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(
              child: Text(
                'No notes yet. Tap + to create one.',
                style: context.textTheme.bodySmall,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(
                            top: 6,
                            right: AppSpacing.md,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _notes[index],
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() => _notes.removeAt(index));
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
