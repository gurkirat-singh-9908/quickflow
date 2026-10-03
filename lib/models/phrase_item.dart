class PhraseItem {
  final String id;
  final String text;
  final String categoryId;
  final int usageCount;
  final int lastUsedTimestamp;
  final List<String> tags;

  PhraseItem({
    required this.id,
    required this.text,
    required this.categoryId,
    this.usageCount = 0,
    this.lastUsedTimestamp = 0,
    this.tags = const [],
  });

  PhraseItem copyWith({
    String? id,
    String? text,
    String? categoryId,
    int? usageCount,
    int? lastUsedTimestamp,
    List<String>? tags,
  }) {
    return PhraseItem(
      id: id ?? this.id,
      text: text ?? this.text,
      categoryId: categoryId ?? this.categoryId,
      usageCount: usageCount ?? this.usageCount,
      lastUsedTimestamp: lastUsedTimestamp ?? this.lastUsedTimestamp,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'categoryId': categoryId,
      'usageCount': usageCount,
      'lastUsedTimestamp': lastUsedTimestamp,
      'tags': tags,
    };
  }

  factory PhraseItem.fromJson(Map<String, dynamic> json) {
    return PhraseItem(
      id: json['id'] as String,
      text: json['text'] as String,
      categoryId: json['categoryId'] as String? ?? 'general',
      usageCount: json['usageCount'] as int? ?? 0,
      lastUsedTimestamp: json['lastUsedTimestamp'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
