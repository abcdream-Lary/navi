import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/website.dart';
import '../models/category.dart';
import '../constants/icon_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WebsiteProvider with ChangeNotifier {
  List<Website> _websites = [];
  List<Category> _categories = [];
  bool _isInitialized = false;
  Timer? _saveDebouncer;

  // 缓存
  Map<String, List<Website>> _categoryWebsitesCache = {};
  List<Website>? _sortedWebsitesCache;
  DateTime? _lastCacheUpdate;

  // 预加载标志
  bool _isPreloaded = false;
  bool get isPreloaded => _isPreloaded;

  // 预加载所有数据
  Future<void> preloadData() async {
    try {
      debugPrint('开始预加载数据...');

      // 重置状态
      _isPreloaded = false;
      _isInitialized = false;
      _clearCache();

      // 加载基础数据
      await loadData();
      debugPrint('基础数据加载完成');

      // 预加载并缓存所有数据
      _preloadAllData();
      debugPrint('数据预加载完成');

      // 设置状态
      _isPreloaded = true;
      _isInitialized = true;
      debugPrint('状态设置完成，准备通知UI更新');

      // 立即通知一次
      notifyListeners();

      // 确保在下一帧也通知更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('触发延迟的UI更新');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('预加载数据失败: $e');
      // 确保至少有未分类存在
      _ensureDefaultCategories();
      _isPreloaded = true;
      _isInitialized = true;

      // 立即通知一次
      notifyListeners();

      // 确保在下一帧也通知更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // 预加载所有数据的私有方法
  void _preloadAllData() {
    // 预加载并缓存排序后的网站列表
    if (_sortedWebsitesCache == null) {
      final sortedWebsites = List<Website>.from(_websites);
      sortedWebsites.sort((a, b) {
        // 获取标题的小写形式用于比较
        final titleA = a.title.toLowerCase();
        final titleB = b.title.toLowerCase();

        // 如果都是数字开头，按数字大小排序
        final numA = RegExp(r'^\d+').firstMatch(titleA)?.group(0);
        final numB = RegExp(r'^\d+').firstMatch(titleB)?.group(0);

        if (numA != null && numB != null) {
          final numCompare = int.parse(numA).compareTo(int.parse(numB));
          if (numCompare != 0) return numCompare;
        }

        // 如果一个是数字开头，一个是字母开头，数字优先
        if (numA != null && numB == null) return -1;
        if (numA == null && numB != null) return 1;

        // 其他情况按字母顺序排序
        return titleA.compareTo(titleB);
      });
      _sortedWebsitesCache = sortedWebsites;
      _lastCacheUpdate = DateTime.now();
    }

    // 预加载并缓存每个分类的网站列表
    for (var category in _categories) {
      if (!_categoryWebsitesCache.containsKey(category.id)) {
        final websites =
            _websites.where((site) => site.categoryId == category.id).toList();
        websites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _categoryWebsitesCache[category.id] = websites;
      }
    }

    // 预加载未分类的网站
    if (!_categoryWebsitesCache.containsKey('uncategorized')) {
      final uncategorizedWebsites = _websites
          .where((site) => site.categoryId == 'uncategorized')
          .toList();
      uncategorizedWebsites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _categoryWebsitesCache['uncategorized'] = uncategorizedWebsites;
    }
  }

  // 获取所有网站（带缓存）
  List<Website> get websites {
    if (_sortedWebsitesCache != null && _lastCacheUpdate != null) {
      final now = DateTime.now();
      if (now.difference(_lastCacheUpdate!) < const Duration(seconds: 5)) {
        return List<Website>.from(_sortedWebsitesCache!);
      }
    }

    // 重新排序网站列表
    final sortedWebsites = List<Website>.from(_websites);
    sortedWebsites.sort((a, b) {
      // 先按更新时间排序
      final timeCompare = b.updatedAt.compareTo(a.updatedAt);
      if (timeCompare != 0) return timeCompare;

      // 如果更新时间相同，按标题排序
      final titleA = a.title.toLowerCase();
      final titleB = b.title.toLowerCase();

      // 如果都是数字开头，按数字大小排序
      final numA = RegExp(r'^\d+').firstMatch(titleA)?.group(0);
      final numB = RegExp(r'^\d+').firstMatch(titleB)?.group(0);

      if (numA != null && numB != null) {
        final numCompare = int.parse(numA).compareTo(int.parse(numB));
        if (numCompare != 0) return numCompare;
      }

      // 如果一个是数字开头，一个是字母开头，数字优先
      if (numA != null && numB == null) return -1;
      if (numA == null && numB != null) return 1;

      // 其他情况按字母顺序排序
      return titleA.compareTo(titleB);
    });

    _sortedWebsitesCache = sortedWebsites;
    _lastCacheUpdate = DateTime.now();
    return List<Website>.from(_sortedWebsitesCache!);
  }

  // 获取所有分类
  List<Category> get categories => _categories;

  // 获取初始化状态
  bool get isInitialized => _isInitialized;

  // 创建默认分类
  Category _createDefaultCategory(String id) {
    return Category(
      id: id,
      name: id == 'uncategorized' ? '未分类' : id,
      icon: defaultCategoryIcons[id] ?? 'folder',
      order: id == 'uncategorized' ? -1 : _categories.length,
    );
  }

  // 确保默认分类存在
  void _ensureDefaultCategories() {
    // 确保未分类存在
    if (!_categories.any((cat) => cat.id == 'uncategorized')) {
      _categories.add(_createDefaultCategory('uncategorized'));
    }
  }

  // 根据分类获取网站（带缓存）
  List<Website> getWebsitesByCategory(String categoryId) {
    // 检查缓存
    if (_categoryWebsitesCache.containsKey(categoryId) &&
        _lastCacheUpdate != null) {
      final now = DateTime.now();
      if (now.difference(_lastCacheUpdate!) < const Duration(seconds: 5)) {
        return _categoryWebsitesCache[categoryId]!;
      }
    }

    // 获取分类下的网站并排序
    final websites =
        _websites.where((site) => site.categoryId == categoryId).toList();
    websites.sort((a, b) {
      // 获取标题的小写形式用于比较
      final titleA = a.title.toLowerCase();
      final titleB = b.title.toLowerCase();

      // 如果都是数字开头，按数字大小排序
      final numA = RegExp(r'^\d+').firstMatch(titleA)?.group(0);
      final numB = RegExp(r'^\d+').firstMatch(titleB)?.group(0);

      if (numA != null && numB != null) {
        final numCompare = int.parse(numA).compareTo(int.parse(numB));
        if (numCompare != 0) return numCompare;
      }

      // 如果一个是数字开头，一个是字母开头，数字优先
      if (numA != null && numB == null) return -1;
      if (numA == null && numB != null) return 1;

      // 其他情况按字母顺序排序
      return titleA.compareTo(titleB);
    });

    _categoryWebsitesCache[categoryId] = websites;
    return websites;
  }

  // 根据ID获取分类
  Category getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      debugPrint('获取分类失败: $e, categoryId: $categoryId');
      return _createDefaultCategory('uncategorized');
    }
  }

  // 添加网站时清除缓存
  Future<void> addWebsite(Website website) async {
    if (_websites.any((site) => site.title == website.title)) {
      debugPrint('网站名称已存在');
      return;
    }

    if (!_categories.any((cat) => cat.id == website.categoryId)) {
      website = website.copyWith(categoryId: 'uncategorized');
    }

    if (!website.isValid()) {
      debugPrint('网站数据验证失败');
      return;
    }

    _websites.add(website);
    _clearCache();
    await saveData();
    notifyListeners();
  }

  // 更新网站时清除缓存
  Future<void> updateWebsite(Website website) async {
    final index = _websites.indexWhere((site) => site.id == website.id);
    if (index != -1) {
      _websites[index] = website;
      _clearCache();
      await saveData();
      notifyListeners();
    }
  }

  // 删除网站时清除缓存
  Future<void> deleteWebsite(String websiteId) async {
    _websites.removeWhere((site) => site.id == websiteId);
    _clearCache();
    await saveData();
    notifyListeners();
  }

  // 切换分类置顶状态
  Future<void> toggleCategoryPin(String categoryId) async {
    final index = _categories.indexWhere((cat) => cat.id == categoryId);
    if (index != -1) {
      final category = _categories[index];
      _categories[index] = category.copyWith(isPinned: !category.isPinned);
      _clearCache();
      await saveData();
      notifyListeners();
    }
  }

  // 添加分类
  Future<void> addCategory(Category category) async {
    _categories.add(category);
    await saveData();
    notifyListeners();
  }

  // 更新分类
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((cat) => cat.id == category.id);
    if (index != -1) {
      _categories[index] = category;

      // 重新排序分类列表
      _categories.sort((a, b) {
        // 未分类永远在最后
        if (a.id == 'uncategorized') return 1;
        if (b.id == 'uncategorized') return -1;

        // 置顶的分类在前面
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // 最后按order排序
        return a.order.compareTo(b.order);
      });

      await saveData();
      notifyListeners();
    }
  }

  // 删除分类
  Future<void> deleteCategory(String categoryId) async {
    // 不允许删除未分类
    if (categoryId == 'uncategorized') {
      debugPrint('不能删除未分类分类');
      return;
    }

    // 删除分类时，将该分类下的网站移到"未分类"
    final websitesInCategory =
        _websites.where((site) => site.categoryId == categoryId);
    for (var website in websitesInCategory) {
      final updatedWebsite = Website(
        id: website.id,
        title: website.title,
        url: website.url,
        categoryId: 'uncategorized',
        description: website.description,
        createdAt: website.createdAt,
        updatedAt: DateTime.now(),
      );
      final index = _websites.indexWhere((site) => site.id == website.id);
      if (index != -1) {
        _websites[index] = updatedWebsite;
      }
    }

    _categories.removeWhere((cat) => cat.id == categoryId);
    await saveData();
    notifyListeners();
  }

  // 获取数据文件路径
  Future<String> get _dataFilePath async {
    try {
      if (Platform.isWindows) {
        // Windows平台优先使用程序安装目录
        try {
          final exePath = Platform.resolvedExecutable;
          final exeDir = path.dirname(exePath);
          final dataDir = Directory(path.join(exeDir, 'data'));

          // 如果目录不存在，创建它
          if (!await dataDir.exists()) {
            await dataDir.create(recursive: true);
          }

          // 检查是否有写入权限
          final testFile = File(path.join(dataDir.path, 'test.tmp'));
          await testFile.writeAsString('test');
          await testFile.delete();

          debugPrint('使用程序安装目录: ${dataDir.path}');
          return path.join(dataDir.path, 'navi_data.json');
        } catch (e) {
          debugPrint('无法使用程序安装目录，切换到用户文档目录: $e');
          // 如果无法使用程序安装目录，回退到用户文档目录
          final directory = await getApplicationDocumentsDirectory();
          final dataDir = Directory(path.join(directory.path, 'Navi', 'data'));

          if (!await dataDir.exists()) {
            await dataDir.create(recursive: true);
          }

          debugPrint('使用用户文档目录: ${dataDir.path}');
          return path.join(dataDir.path, 'navi_data.json');
        }
      } else {
        // 移动端使用应用数据目录下的 data 文件夹
        final directory = await getApplicationDocumentsDirectory();
        final dataDir = Directory(path.join(directory.path, 'data'));

        if (!await dataDir.exists()) {
          await dataDir.create(recursive: true);
        }

        debugPrint('使用应用数据目录: ${dataDir.path}');
        return path.join(dataDir.path, 'navi_data.json');
      }
    } catch (e) {
      debugPrint('获取数据存储路径失败: $e');
      rethrow;
    }
  }

  // 加载数据
  Future<void> loadData() async {
    try {
      _clearCache();
      final filePath = await _dataFilePath;
      final file = File(filePath);

      debugPrint('正在从文件加载数据: $filePath');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        debugPrint('成功读取数据文件');

        final data = json.decode(jsonString);
        debugPrint('成功解析JSON数据');

        // 加载分类
        if (data['categories'] != null) {
          _categories = (data['categories'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
          debugPrint('成功加载分类数据: ${_categories.length}个分类');
        }

        // 加载网站
        if (data['websites'] != null) {
          _websites = (data['websites'] as List)
              .map((item) => Website.fromJson(item))
              .toList();
          debugPrint('成功加载网站数据: ${_websites.length}个网站');
        }

        // 立即通知一次数据加载完成
        notifyListeners();
      } else {
        debugPrint('数据文件不存在，将创建新的数据文件');
      }

      // 确保默认分类存在
      _ensureDefaultCategories();

      // 重新预加载数据
      _preloadAllData();
      debugPrint('数据预加载完成');

      _isInitialized = true;

      // 立即通知一次
      notifyListeners();

      // 确保在下一帧也通知更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('触发延迟的UI更新');
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('加载数据失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      // 确保默认分类存在
      _ensureDefaultCategories();
      _isInitialized = true;

      // 立即通知一次
      notifyListeners();

      // 确保在下一帧也通知更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // 保存数据
  Future<void> saveData() async {
    if (_saveDebouncer?.isActive ?? false) {
      _saveDebouncer!.cancel();
    }

    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final filePath = await _dataFilePath;
        final file = File(filePath);

        final data = {
          'categories': _categories.map((cat) => cat.toJson()).toList(),
          'websites': _websites.map((site) => site.toJson()).toList(),
        };

        // 使用 JsonEncoder.withIndent 来格式化 JSON 数据
        const encoder = JsonEncoder.withIndent('  ');
        final prettyJson = encoder.convert(data);
        await file.writeAsString(prettyJson);
      } catch (e) {
        debugPrint('保存数据失败: $e');
      }
    });
  }

  /// 从备份数据恢复
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      // 重置所有状态
      _categories.clear();
      _websites.clear();
      _clearCache();
      _isInitialized = false;
      _isPreloaded = false;

      // 恢复分类数据
      final List<dynamic> categoriesData = backupData['categories'];
      _categories.addAll(
        categoriesData
            .map((data) => Category.fromJson(data as Map<String, dynamic>)),
      );

      // 确保默认分类存在
      _ensureDefaultCategories();

      // 按置顶和order排序
      _categories.sort((a, b) {
        // 未分类永远在最后
        if (a.id == 'uncategorized') return 1;
        if (b.id == 'uncategorized') return -1;

        // 置顶的分类在前面
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // 最后按order排序
        return a.order.compareTo(b.order);
      });

      // 恢复网站数据
      final List<dynamic> websitesData = backupData['websites'];
      _websites.addAll(
        websitesData
            .map((data) => Website.fromJson(data as Map<String, dynamic>)),
      );

      // 重新初始化所有状态
      _isInitialized = true;

      // 预加载所有数据
      _preloadAllData();
      _isPreloaded = true;

      // 保存到本地
      await saveData();

      // 通知监听器数据已更新
      notifyListeners();
    } catch (e) {
      throw '恢复数据失败: ${e.toString()}';
    }
  }

  // 清除缓存
  void _clearCache() {
    _categoryWebsitesCache.clear();
    _sortedWebsitesCache = null;
    _lastCacheUpdate = null;
  }
}
