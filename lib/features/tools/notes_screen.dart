import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  static const String _storageKey = 'taply_notes';
  List<String> _notes = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final storage = ref.read(storageServiceProvider);
    final saved = storage.getStringList(_storageKey);
    if (saved != null && saved.isNotEmpty) {
      _notes = List<String>.from(saved);
    } else {
      _notes = [
        'Quick reminder: Taply overlay requires Display Over Other Apps permission.',
        'Taply features: Quick system controls, customizable floating button gestures, and instant app launcher.',
      ];
    }
  }

  Future<void> _saveNotes() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setStringList(_storageKey, _notes);
  }

  void _addOrEditNote({int? index}) {
    if (index != null) {
      _textController.text = _notes[index];
    } else {
      _textController.clear();
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index != null ? 'Edit Note' : 'Add Quick Note'),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your note or scratchpad idea here...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    if (index != null) {
                      _notes[index] = text;
                    } else {
                      _notes.insert(0, text);
                    }
                  });
                  await _saveNotes();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.showSnackBar(
                    index != null ? 'Note updated' : 'Note saved',
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(int index) async {
    _notes.removeAt(index);
    setState(() {});
    await _saveNotes();
    if (mounted) {
      context.showSnackBar('Note deleted');
    }
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
            onPressed: () => _addOrEditNote(),
            tooltip: 'Add Note',
          ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 64,
                      color: context.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No notes yet',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap the button below to add your first quick note or clipboard clip.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () => _addOrEditNote(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Note'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Dismissible(
                  key: ValueKey('note_${index}_${note.hashCode}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => _deleteNote(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                  note,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy note',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: note));
                                  context.showSnackBar(
                                    'Note copied to clipboard',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit note',
                                onPressed: () => _addOrEditNote(index: index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                tooltip: 'Delete note',
                                onPressed: () => _deleteNote(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        tooltip: 'Add note',
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
