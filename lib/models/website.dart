class Website {
  String id; // 网站ID
  String title; // 网站标题
  String url; // 网站地址
  String categoryId; // 所属分类ID
  String? icon; // 网站图标
  String? description; // 网站描述
  DateTime createdAt; // 创建时间
  DateTime updatedAt; // 更新时间
  bool isPinned; // 是否置顶

  Website({
    required this.id,
    required this.title,
    required this.url,
    String? categoryId,
    this.icon,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  })  : categoryId = categoryId ?? 'uncategorized',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 验证数据完整性
  bool isValid() {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        url.isNotEmpty &&
        categoryId.isNotEmpty &&
        hasValidUrl() && // 添加URL格式验证
        !createdAt.isAfter(updatedAt); // 修改时间验证逻辑
  }

  // 验证URL格式
  bool hasValidUrl() {
    try {
      final uri = Uri.parse(url);
      // 检查是否是文件路径
      if (url.startsWith('file://')) {
        return true;
      }
      // 检查是否是IP地址或localhost
      final hostPart = uri.host;
      if (hostPart == 'localhost' ||
          hostPart.startsWith('[') || // IPv6
          RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(hostPart)) {
        // IPv4
        return true;
      }
      // 检查常规URL
      return uri.hasScheme && uri.host.isNotEmpty && uri.host.contains('.');
    } catch (e) {
      return false;
    }
  }

  // 复制并修改对象
  Website copyWith({
    String? id,
    String? title,
    String? url,
    String? categoryId,
    String? icon,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Website(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  // 从JSON转换
  factory Website.fromJson(Map<String, dynamic> json) {
    try {
      final website = Website(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        categoryId: json['categoryId']?.toString() ?? 'uncategorized',
        icon: json['icon']?.toString(),
        description: json['description']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : DateTime.now(),
        isPinned: json['isPinned'] as bool? ?? false,
      );

      // 验证必要字段
      if (!website.isValid()) {
        throw FormatException('网站数据验证失败: 必要字段不完整');
      }

      return website;
    } catch (e) {
      throw FormatException('无法解析网站数据: $e, JSON: $json');
    }
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'categoryId': categoryId,
      'icon': icon,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }
}
