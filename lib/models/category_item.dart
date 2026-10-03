class CategoryItem {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final bool isSmartFilterEnabled;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.colorValue = 0xFF6366F1, // Indigo default
    this.isSmartFilterEnabled = true,
  });

  CategoryItem copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    bool? isSmartFilterEnabled,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isSmartFilterEnabled: isSmartFilterEnabled ?? this.isSmartFilterEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'isSmartFilterEnabled': isSmartFilterEnabled,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '💬',
      colorValue: json['colorValue'] as int? ?? 0xFF6366F1,
      isSmartFilterEnabled: json['isSmartFilterEnabled'] as bool? ?? true,
    );
  }
}
