import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_item.dart';
import '../models/phrase_item.dart';
import 'platform_bridge.dart';

class PhraseStorage {
  static const String _kPhrasesKey = 'quickflow_phrases';
  static const String _kCategoriesKey = 'quickflow_categories';
  static const String _kBubbleSettingsKey = 'quickflow_bubble_settings';

  static final PhraseStorage instance = PhraseStorage._internal();
  PhraseStorage._internal();

  List<CategoryItem> _categories = [];
  List<PhraseItem> _phrases = [];
  Map<String, dynamic> _bubbleSettings = {
    'bubbleSize': 'Medium', // Small, Medium, Large
    'bubbleOpacity': 0.9,
    'smartDeduplication': true,
    'autoCloseOnTap': true,
  };

  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<PhraseItem> get phrases => List.unmodifiable(_phrases);
  Map<String, dynamic> get bubbleSettings => Map.unmodifiable(_bubbleSettings);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final categoriesJson = prefs.getString(_kCategoriesKey);
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      final List decoded = jsonDecode(categoriesJson);
      _categories = decoded.map((e) => CategoryItem.fromJson(e)).toList();
    } else {
      _categories = _getDefaultCategories();
      await _saveCategories(prefs);
    }

    final phrasesJson = prefs.getString(_kPhrasesKey);
    if (phrasesJson != null && phrasesJson.isNotEmpty) {
      final List decoded = jsonDecode(phrasesJson);
      _phrases = decoded.map((e) => PhraseItem.fromJson(e)).toList();
    } else {
      _phrases = _getDefaultPhrases();
      await _savePhrases(prefs);
    }

    final settingsJson = prefs.getString(_kBubbleSettingsKey);
    if (settingsJson != null) {
      _bubbleSettings = Map<String, dynamic>.from(jsonDecode(settingsJson));
    }

    await syncToNative();
  }

  List<CategoryItem> _getDefaultCategories() {
    return [
      CategoryItem(
        id: 'openers',
        name: 'Openers',
        icon: '👋',
        colorValue: 0xFF6366F1, // Indigo
        isSmartFilterEnabled: true,
      ),
      CategoryItem(
        id: 'small_talk',
        name: 'Small Talk',
        icon: '💬',
        colorValue: 0xFF0EA5E9, // Sky Blue
        isSmartFilterEnabled: true,
      ),
      CategoryItem(
        id: 'followups',
        name: 'Follow-ups',
        icon: '⏰',
        colorValue: 0xFFF59E0B, // Amber
        isSmartFilterEnabled: false,
      ),
      CategoryItem(
        id: 'quick_replies',
        name: 'Quick Replies',
        icon: '⚡',
        colorValue: 0xFF10B981, // Emerald
        isSmartFilterEnabled: false,
      ),
    ];
  }

  List<PhraseItem> _getDefaultPhrases() {
    return [
      // Openers
      PhraseItem(
        id: 'op_1',
        categoryId: 'openers',
        text: 'Hey! How are you doing today?',
      ),
      PhraseItem(
        id: 'op_2',
        categoryId: 'openers',
        text: "Hey there! Hope you're having a wonderful week.",
      ),
      PhraseItem(
        id: 'op_3',
        categoryId: 'openers',
        text: 'Hi! Long time no see, how have you been?',
      ),

      // Small Talk
      PhraseItem(
        id: 'st_1',
        categoryId: 'small_talk',
        text: 'Where are you from originally?',
      ),
      PhraseItem(
        id: 'st_2',
        categoryId: 'small_talk',
        text: 'What do you enjoy doing in your free time?',
      ),
      PhraseItem(
        id: 'st_3',
        categoryId: 'small_talk',
        text: 'What line of work are you in?',
      ),
      PhraseItem(
        id: 'st_4',
        categoryId: 'small_talk',
        text: 'Any exciting plans for the weekend?',
      ),

      // Follow-ups
      PhraseItem(
        id: 'fl_1',
        categoryId: 'followups',
        text: 'Just following up on my previous message!',
      ),
      PhraseItem(
        id: 'fl_2',
        categoryId: 'followups',
        text: 'Let me know when you get a chance to take a look.',
      ),
      PhraseItem(
        id: 'fl_3',
        categoryId: 'followups',
        text: 'Sounds great, looking forward to it!',
      ),

      // Quick Replies
      PhraseItem(
        id: 'qr_1',
        categoryId: 'quick_replies',
        text: "I'm in a quick meeting, will get back to you shortly!",
      ),
      PhraseItem(
        id: 'qr_2',
        categoryId: 'quick_replies',
        text: 'On my way now! See you in about 10 minutes.',
      ),
      PhraseItem(
        id: 'qr_3',
        categoryId: 'quick_replies',
        text: 'Could you please send over the link or details?',
      ),
      PhraseItem(
        id: 'qr_4',
        categoryId: 'quick_replies',
        text: 'Thanks a lot, really appreciate your help! 🙌',
      ),
    ];
  }

  Future<void> addPhrase(PhraseItem phrase) async {
    _phrases.insert(0, phrase);
    final prefs = await SharedPreferences.getInstance();
    await _savePhrases(prefs);
    await syncToNative();
  }

  Future<void> updatePhrase(PhraseItem phrase) async {
    final index = _phrases.indexWhere((p) => p.id == phrase.id);
    if (index != -1) {
      _phrases[index] = phrase;
      final prefs = await SharedPreferences.getInstance();
      await _savePhrases(prefs);
      await syncToNative();
    }
  }

  Future<void> deletePhrase(String id) async {
    _phrases.removeWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _savePhrases(prefs);
    await syncToNative();
  }

  Future<void> recordPhraseUsed(String id) async {
    final index = _phrases.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _phrases[index];
      _phrases[index] = current.copyWith(
        usageCount: current.usageCount + 1,
        lastUsedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final prefs = await SharedPreferences.getInstance();
      await _savePhrases(prefs);
      await syncToNative();
    }
  }

  Future<void> addCategory(CategoryItem category) async {
    _categories.add(category);
    final prefs = await SharedPreferences.getInstance();
    await _saveCategories(prefs);
    await syncToNative();
  }

  Future<void> updateCategory(CategoryItem category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      final prefs = await SharedPreferences.getInstance();
      await _saveCategories(prefs);
      await syncToNative();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _phrases.removeWhere((p) => p.categoryId == id);
    final prefs = await SharedPreferences.getInstance();
    await _saveCategories(prefs);
    await _savePhrases(prefs);
    await syncToNative();
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _bubbleSettings = {..._bubbleSettings, ...newSettings};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBubbleSettingsKey, jsonEncode(_bubbleSettings));
    await syncToNative();
  }

  Future<void> _savePhrases(SharedPreferences prefs) async {
    final encoded = jsonEncode(_phrases.map((e) => e.toJson()).toList());
    await prefs.setString(_kPhrasesKey, encoded);
  }

  Future<void> _saveCategories(SharedPreferences prefs) async {
    final encoded = jsonEncode(_categories.map((e) => e.toJson()).toList());
    await prefs.setString(_kCategoriesKey, encoded);
  }

  Future<void> syncToNative() async {
    try {
      final payload = jsonEncode({
        'categories': _categories.map((e) => e.toJson()).toList(),
        'phrases': _phrases.map((e) => e.toJson()).toList(),
        'settings': _bubbleSettings,
      });
      await PlatformBridge.instance.syncDataToNative(payload);
    } catch (e) {
      debugPrint('Sync to native error: $e');
    }
  }
}
