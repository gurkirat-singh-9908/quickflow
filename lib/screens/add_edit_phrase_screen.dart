import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_item.dart';
import '../models/phrase_item.dart';
import '../services/phrase_storage.dart';

class AddEditPhraseScreen extends StatefulWidget {
  final PhraseItem? phraseToEdit;
  final String? initialCategoryId;

  const AddEditPhraseScreen({
    super.key,
    this.phraseToEdit,
    this.initialCategoryId,
  });

  @override
  State<AddEditPhraseScreen> createState() => _AddEditPhraseScreenState();
}

class _AddEditPhraseScreenState extends State<AddEditPhraseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _tagController;
  late String _selectedCategoryId;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    final categories = PhraseStorage.instance.categories;
    final defaultCatId = categories.isNotEmpty ? categories.first.id : 'general';

    if (widget.phraseToEdit != null) {
      _textController = TextEditingController(text: widget.phraseToEdit!.text);
      _selectedCategoryId = widget.phraseToEdit!.categoryId;
      _tags = List.from(widget.phraseToEdit!.tags);
    } else {
      _textController = TextEditingController();
      _selectedCategoryId = widget.initialCategoryId ?? defaultCatId;
    }
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final text = _textController.text.trim();
    if (widget.phraseToEdit != null) {
      final updated = widget.phraseToEdit!.copyWith(
        text: text,
        categoryId: _selectedCategoryId,
        tags: _tags,
      );
      await PhraseStorage.instance.updatePhrase(updated);
    } else {
      final newPhrase = PhraseItem(
        id: const Uuid().v4(),
        text: text,
        categoryId: _selectedCategoryId,
        tags: _tags,
      );
      await PhraseStorage.instance.addPhrase(newPhrase);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = PhraseStorage.instance.categories;
    final isEditing = widget.phraseToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Phrase' : 'Add New Phrase',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phrase or Message Text',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter phrase text';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. "Where are you from originally?" or "Hey! How are you doing today?"',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: const Color(0xFF1E1F2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Category',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text('${cat.icon} ${cat.name}'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF1E1F2E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = cat.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tags / Keywords (Optional)',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add keyword (e.g. friendly, greeting)',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: const Color(0xFF1E1F2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.filled(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addTag,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((t) {
                    return Chip(
                      label: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: const Color(0xFF2B2D42),
                      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white54),
                      onDeleted: () {
                        setState(() => _tags.remove(t));
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
