import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_item.dart';
import '../services/phrase_storage.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _commonIcons = ['👋', '💬', '⏰', '⚡', '❤️', '💼', '📍', '🔥', '🎯', '✨', '☕', '📝'];
  final List<int> _colorPalette = [
    0xFF6366F1, // Indigo
    0xFF0EA5E9, // Sky Blue
    0xFF10B981, // Emerald
    0xFFF59E0B, // Amber
    0xFFEC4899, // Pink
    0xFF8B5CF6, // Purple
    0xFFEF4444, // Red
  ];

  void _showAddEditDialog([CategoryItem? category]) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? '💬';
    int selectedColor = category?.colorValue ?? 0xFF6366F1;
    bool smartFilter = category?.isSmartFilterEnabled ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1F2E),
          title: Text(
            isEditing ? 'Edit Category' : 'New Category',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Dating Openers, Work, Questions',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: const Color(0xFF26283B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _commonIcons.map((ic) {
                    final isSel = selectedIcon == ic;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIcon = ic),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF6366F1).withOpacity(0.3) : const Color(0xFF26283B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? const Color(0xFF6366F1) : Colors.transparent),
                        ),
                        child: Text(ic, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _colorPalette.map((col) {
                    final isSel = selectedColor == col;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = col),
                      shape: const CircleBorder(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(col),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Smart Conversation Filter',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Hide this category in the same chat once used',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  value: smartFilter,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) => setDialogState(() => smartFilter = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                if (isEditing) {
                  final updated = category.copyWith(
                    name: name,
                    icon: selectedIcon,
                    colorValue: selectedColor,
                    isSmartFilterEnabled: smartFilter,
                  );
                  await PhraseStorage.instance.updateCategory(updated);
                } else {
                  final newCat = CategoryItem(
                    id: const Uuid().v4(),
                    name: name,
                    icon: selectedIcon,
                    colorValue: selectedColor,
                    isSmartFilterEnabled: smartFilter,
                  );
                  await PhraseStorage.instance.addCategory(newCat);
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = PhraseStorage.instance.categories;
    final phrases = PhraseStorage.instance.phrases;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        title: const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final count = phrases.where((p) => p.categoryId == cat.id).length;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(cat.colorValue).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$count phrases', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          if (cat.isSmartFilterEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Smart Memory Active',
                                style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                  onPressed: () => _showAddEditDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1F2E),
                        title: const Text('Delete Category?', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Deleting "${cat.name}" will also remove all its $count phrases.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await PhraseStorage.instance.deleteCategory(cat.id);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
