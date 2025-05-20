class Category {
  String id; // 分类ID
  String name; // 分类名称
  String icon; // 分类图标
  int order; // 排序顺序
  bool isPinned; // 是否置顶

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
    this.isPinned = false,
  });

  // 验证数据完整性
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        icon.isNotEmpty &&
        order >= -1; // -1 是未分类的特殊值
  }

  // 是否是系统预设分类
  bool get isSystemCategory => id == 'uncategorized';

  // 复制并修改对象
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? order,
    bool? isPinned,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  // 从JSON转换
  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      final category = Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? 'folder',
        order: json['order'] is int ? json['order'] as int : 0,
        isPinned: json['isPinned'] as bool? ?? false,
      );

      // 验证必要字段
      if (!category.isValid()) {
        throw FormatException('分类数据验证失败: 必要字段不完整');
      }

      return category;
    } catch (e) {
      throw FormatException('无法解析分类数据: $e, JSON: $json');
    }
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'order': order,
      'isPinned': isPinned,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          order == other.order &&
          isPinned == other.isPinned;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      order.hashCode ^
      isPinned.hashCode;
}
