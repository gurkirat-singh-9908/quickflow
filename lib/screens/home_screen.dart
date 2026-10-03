import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_item.dart';
import '../models/phrase_item.dart';
import '../services/phrase_storage.dart';
import '../services/platform_bridge.dart';
import 'add_edit_phrase_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sandboxController = TextEditingController();

  bool _isAccessibilityEnabled = false;
  bool _isOverlayGranted = false;
  bool _isBubbleActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _sandboxController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    await PhraseStorage.instance.init();
    await _checkPermissions();
    setState(() => _isLoading = false);
  }

  Future<void> _checkPermissions() async {
    final acc = await PlatformBridge.instance.isAccessibilityServiceEnabled();
    final overlay = await PlatformBridge.instance.isOverlayPermissionGranted();
    final bubbleRunning = await PlatformBridge.instance.isFloatingBubbleRunning();
    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = acc;
        _isOverlayGranted = overlay;
        _isBubbleActive = bubbleRunning;
      });
    }
  }

  Future<void> _toggleBubble(bool value) async {
    if (value && (!_isAccessibilityEnabled || !_isOverlayGranted)) {
      _showPermissionSheet();
      return;
    }
    final success = await PlatformBridge.instance.toggleFloatingBubble(value);
    setState(() {
      _isBubbleActive = success ? value : false;
    });
  }

  void _showPermissionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Permissions Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'QuickFlow needs two permissions to float as a bubble and inject text directly into your chat boxes:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              title: '1. Display Over Other Apps',
              description: 'Allows the floating bubble & palette to appear above WhatsApp, Instagram, etc.',
              isGranted: _isOverlayGranted,
              onTap: () => PlatformBridge.instance.openOverlaySettings(),
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              title: '2. Accessibility Service',
              description: 'Allows direct 1-tap typing into the active chat field (no manual pasting needed).',
              isGranted: _isAccessibilityEnabled,
              onTap: () => PlatformBridge.instance.openAccessibilitySettings(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _checkPermissions();
                },
                child: const Text('Done / Re-check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B3D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? Colors.green.withOpacity(0.4) : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isGranted ? Icons.check_circle : Icons.error_outline,
                      color: isGranted ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isGranted ? Colors.white10 : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Text(isGranted ? 'Enabled' : 'Grant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF13131A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    final categories = PhraseStorage.instance.categories;
    final phrases = PhraseStorage.instance.phrases;

    final filteredPhrases = phrases.where((p) {
      final matchesCategory = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          p.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    final allPermissionsGranted = _isAccessibilityEnabled && _isOverlayGranted;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuickFlow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                Text(
                  'Floating Text Palette',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Category Manager',
            icon: const Icon(Icons.category_outlined, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
              setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkPermissions,
        color: const Color(0xFF6366F1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bubble Quick Switcher Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isBubbleActive
                        ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                        : [const Color(0xFF232433), const Color(0xFF1C1D2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    if (_isBubbleActive)
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isBubbleActive ? Icons.bubble_chart : Icons.bubble_chart_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isBubbleActive ? 'Floating Bubble is ON' : 'Floating Bubble is OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isBubbleActive
                                ? 'Tap the bubble anywhere to paste text'
                                : 'Enable to float over your messaging apps',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isBubbleActive,
                      onChanged: _toggleBubble,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              // Permissions warning if not granted
              if (!allPermissionsGranted) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showPermissionSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Permissions required for floating overlay & direct typing.',
                            style: TextStyle(color: Color(0xFFFBBF24), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'Setup',
                          style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Icon(Icons.chevron_right, color: Color(0xFFFBBF24), size: 18),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Interactive Text Sandbox / Testing Area
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_fields, color: Colors.white54, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Test Input Box (Type or paste test here)',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sandboxController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tap here, then tap any phrase below to test instant insertion...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF242638),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _sandboxController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                                onPressed: () {
                                  setState(() => _sandboxController.clear());
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search quick phrases...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E1F2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 14),

              // Category Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryFilterChip(
                      id: 'all',
                      label: 'All (${phrases.length})',
                      isSelected: _selectedCategoryId == 'all',
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) {
                      final count = phrases.where((p) => p.categoryId == cat.id).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryFilterChip(
                          id: cat.id,
                          label: '${cat.icon} ${cat.name} ($count)',
                          isSelected: _selectedCategoryId == cat.id,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Phrases (${filteredPhrases.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Tap to insert or copy',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Phrase List
              if (filteredPhrases.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No phrases matching "$_searchQuery"' : 'No phrases in this category',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPhrases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final phrase = filteredPhrases[index];
                    final category = categories.firstWhere(
                      (c) => c.id == phrase.categoryId,
                      orElse: () => CategoryItem(id: 'unknown', name: 'General', icon: '📝'),
                    );
                    return _buildPhraseCard(phrase, category);
                  },
                ),

              const SizedBox(height: 80), // Fab spacing
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Phrase', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditPhraseScreen(
                initialCategoryId: _selectedCategoryId != 'all' ? _selectedCategoryId : null,
              ),
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedCategoryId = id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPhraseCard(PhraseItem phrase, CategoryItem category) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Insert into sandbox or copy
            _sandboxController.text = phrase.text;
            Clipboard.setData(ClipboardData(text: phrase.text));
            PhraseStorage.instance.recordPhraseUsed(phrase.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Inserted into sandbox & copied: "${phrase.text}"'),
                duration: const Duration(milliseconds: 1400),
                backgroundColor: const Color(0xFF6366F1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        phrase.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action popup menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                      color: const Color(0xFF252636),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditPhraseScreen(phraseToEdit: phrase),
                            ),
                          );
                          setState(() {});
                        } else if (val == 'copy') {
                          Clipboard.setData(ClipboardData(text: phrase.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        } else if (val == 'delete') {
                          await PhraseStorage.instance.deletePhrase(phrase.id);
                          setState(() {});
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 18, color: Colors.white70),
                              SizedBox(width: 10),
                              Text('Copy', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(category.colorValue).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${category.icon} ${category.name}',
                        style: TextStyle(
                          color: Color(category.colorValue),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (phrase.usageCount > 0)
                      Text(
                        'Used ${phrase.usageCount}x',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
