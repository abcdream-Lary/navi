import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/website_provider.dart';
import '../models/category.dart';
import '../models/website.dart';
import 'package:uuid/uuid.dart';
import '../widgets/category_selector.dart';
import '../widgets/icon_selector.dart';
import '../constants/icon_data.dart';
import '../widgets/side_navigation.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/responsive_layout.dart';
import 'mobile/mobile_settings_screen.dart';
import '../utils/desktop_backup_restore_utils.dart';
import '../services/update_service.dart';
import '../constants/app_version.dart';

// 在类外部定义扩展
extension WebsiteProviderExtension on WebsiteProvider {
  Category getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      // 如果找不到分类，返回未分类
      return Category(
        id: 'uncategorized',
        name: '未分类',
        icon: 'folder',
        order: -1,
      );
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: const MobileSettingsScreen(),
      desktopLayout: const DesktopSettingsScreen(),
    );
  }
}

class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({Key? key}) : super(key: key);

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final TextEditingController _websiteTitleController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _websiteDescController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  String? _selectedCategoryId;
  bool _isValidTitle = true;
  bool _isValidUrl = true;
  bool _isValidCategoryName = true;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();

    // 延迟加载数据，让动画先播放
    Future.microtask(() => _initializeSettings());
  }

  Future<void> _initializeSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<WebsiteProvider>(context, listen: false);
      if (!provider.isPreloaded) {
        await provider.preloadData();
      }
    } catch (e) {
      debugPrint('设置页面初始化失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 修改URL验证正则表达式
  final RegExp _urlRegExp = RegExp(
    r'^(http:\/\/|https:\/\/|ftp:\/\/|file:\/\/|ws:\/\/|wss:\/\/)?' // 支持更多协议（可选）
    r'('
    r'localhost|' // localhost
    r'(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|' // IPv4地址
    r'\[(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\]|' // IPv6地址
    r'(?:[a-zA-Z0-9\u4e00-\u9fa5][a-zA-Z0-9\u4e00-\u9fa5-]{0,62}\.)*' // 支持中文域名和多级子域名
    r'[a-zA-Z0-9\u4e00-\u9fa5][a-zA-Z0-9\u4e00-\u9fa5-]{0,62}' // 域名主体部分
    r'\.[a-zA-Z\u4e00-\u9fa5]{2,}' // 顶级域名，支持中文
    r')'
    r'(:[0-9]{1,5})?' // 端口号（可选）
    r'(\/[^\s]*)?$', // 路径部分（可选）
    caseSensitive: false,
  );

  // 修改IP地址验证正则表达式
  final RegExp _ipRegExp = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  // 验证URL的方法
  bool _validateUrl(String url) {
    if (url.isEmpty) return false;

    // 如果是文件路径格式，直接返回true
    if (url.startsWith('file://')) return true;

    // 移除协议部分和端口号后验证IP地址
    String urlWithoutProtocol = url.replaceFirst(
      RegExp(r'^(http:\/\/|https:\/\/|ftp:\/\/|file:\/\/|ws:\/\/|wss:\/\/)'),
      '',
    );
    String hostPart = urlWithoutProtocol.split(':')[0].split('/')[0];

    // 如果是IP地址格式，返回true
    if (_ipRegExp.hasMatch(hostPart)) return true;

    // 如果是localhost或以点号开头的本地域名，返回true
    if (hostPart == 'localhost' || hostPart.startsWith('.')) return true;

    // 如果是纯IP格式（包括IPv6），返回true
    if (hostPart.startsWith('[') && hostPart.endsWith(']')) return true;

    // 验证完整URL格式
    return _urlRegExp.hasMatch(url);
  }

  // 处理URL格式化
  String _formatUrl(String url) {
    // 如果已经有协议前缀，直接返回
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('ftp://') ||
        url.startsWith('file://') ||
        url.startsWith('ws://') ||
        url.startsWith('wss://')) {
      return url;
    }

    // 获取主机部分
    String hostPart = url.split(':')[0].split('/')[0];

    // 如果是IP地址或localhost，添加http://
    if (_ipRegExp.hasMatch(hostPart) ||
        hostPart == 'localhost' ||
        hostPart.startsWith('[') ||
        hostPart.startsWith('.')) {
      return 'http://$url';
    }

    // 其他情况添加https://
    return 'https://$url';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _websiteUrlController.dispose();
    _websiteTitleController.dispose();
    _websiteDescController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  Widget _buildSkeletonItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.grey300,
      highlightColor: AppTheme.grey100,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: AppTheme.smoothBorderRadius,
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildWebsiteList();
      case 1:
        return _buildCategoryList();
      case 2:
        return _buildBackupRestorePage();
      case 3:
        return _buildAboutPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildContentArea() {
    final List<Category> settingsNavItems = [
      Category(
        id: 'website_management',
        name: '网站管理',
        icon: 'language',
        order: 0,
      ),
      Category(
        id: 'category_management',
        name: '分类管理',
        icon: 'category',
        order: 1,
      ),
      Category(
        id: 'backup_restore',
        name: '备份与恢复',
        icon: 'cloud-backup',
        order: 2,
      ),
      Category(
        id: 'about',
        name: '关于',
        icon: 'info',
        order: 3,
      ),
    ];

    return Row(
      children: [
        Container(
          width: 200,
          child: SideNavigation(
            selectedIndex: _selectedIndex,
            categories: settingsNavItems,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            isSettingsNav: true,
          ),
        ),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppTheme.backgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settingsNavItems[_selectedIndex].name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedIndex < 2)
                        ElevatedButton(
                          onPressed: _selectedIndex == 0
                              ? _showAddWebsiteDialog
                              : _showAddCategoryDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.black,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(_selectedIndex == 0 ? '添加网站' : '添加分类'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _isLoading
                        ? ListView.builder(
                            itemCount: 5,
                            itemBuilder: (context, index) =>
                                _buildSkeletonItem(),
                          )
                        : _buildSettingsContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContentArea(),
    );
  }

  // 构建网站列表
  Widget _buildWebsiteList() {
    return Consumer<WebsiteProvider>(
      builder: (context, provider, child) {
        // 获取所有网站
        final websites = provider.websites;

        // 对网站进行排序
        final sortedWebsites = [...websites]..sort((a, b) {
            // 首先按照是否为未分类排序
            if (a.categoryId == 'uncategorized' &&
                b.categoryId != 'uncategorized') {
              return -1;
            }
            if (a.categoryId != 'uncategorized' &&
                b.categoryId == 'uncategorized') {
              return 1;
            }

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

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: sortedWebsites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.web_outlined,
                        size: 32,
                        color: AppTheme.black.withOpacity(0.2),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '暂无网站',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.black.withOpacity(0.2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // 设置卡片的固定尺寸
                    const double cardHeight = 117.0; // 增加卡片高度
                    const double cardWidth = 240.0; // 与主页一致

                    return GridView.builder(
                      padding: EdgeInsets.zero, // 添加这行
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: cardWidth,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: cardHeight,
                      ),
                      itemCount: sortedWebsites.length,
                      itemBuilder: (context, index) {
                        final website = sortedWebsites[index];
                        final category =
                            provider.getCategoryById(website.categoryId);
                        final categoryName = category.name;
                        final formattedDate = _formatDate(website.createdAt);

                        return _buildWebsiteCard(
                          website: website,
                          categoryName: categoryName,
                          formattedDate: formattedDate,
                          fontSize: 14.0, // 使用固定字体大小
                          cardWidth: cardWidth,
                          crossAxisCount: 4,
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildWebsiteCard({
    required Website website,
    required String categoryName,
    required String formattedDate,
    required double fontSize,
    required double cardWidth,
    required int crossAxisCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.grey,
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppTheme.smoothBorderRadius,
            onTap: () => _showEditWebsiteDialog(website),
            splashColor: AppTheme.black.withOpacity(0.1),
            highlightColor: AppTheme.black.withOpacity(0.1),
            hoverColor: AppTheme.black.withOpacity(0.03),
            child: Stack(
              children: [
                // 主要内容
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 10,
                    right: 12,
                    bottom: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和操作按钮行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              website.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                          // 编辑和删除按钮
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: AppTheme.smoothBorderRadius,
                                  onTap: () => _showEditWebsiteDialog(website),
                                  hoverColor: AppTheme.black.withOpacity(0.03),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: AppTheme.smoothBorderRadius,
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppTheme.black.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: AppTheme.smoothBorderRadius,
                                  onTap: () =>
                                      _showDeleteWebsiteDialog(website),
                                  splashColor:
                                      AppTheme.errorColor.withOpacity(0.1),
                                  highlightColor:
                                      AppTheme.errorColor.withOpacity(0.1),
                                  hoverColor:
                                      AppTheme.errorColor.withOpacity(0.1),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: AppTheme.smoothBorderRadius,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: AppTheme.black.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 网址
                      Text(
                        website.url,
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: AppTheme.black.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      const SizedBox(height: 1),
                      // 描述
                      if (website.description != null &&
                          website.description!.isNotEmpty)
                        Text(
                          website.description!,
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: AppTheme.black.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                    ],
                  ),
                ),
                // 分类和时间（左下角）
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      // 分类
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: fontSize - 3,
                            color: AppTheme.black.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 创建时间
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: fontSize - 3,
                          color: AppTheme.black.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建分类列表
  Widget _buildCategoryList() {
    return Consumer<WebsiteProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;

        // 对分类进行排序，未分类固定在最后面
        final sortedCategories = [...categories]..sort((a, b) {
            // 未分类固定在最后面
            if (a.id == 'uncategorized') return 1;
            if (b.id == 'uncategorized') return -1;
            // 其他分类按照 order 排序
            return a.order.compareTo(b.order);
          });

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 32,
                        color: AppTheme.black.withOpacity(0.2),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '暂无分类',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.black.withOpacity(0.2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const double cardWidth = 240.0;
                    const double cardHeight = 48.0;

                    return GridView.builder(
                      padding: EdgeInsets.zero, // 添加这行
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: cardWidth,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: cardHeight,
                      ),
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryItem(
                          sortedCategories[index],
                          14.0,
                          cardWidth,
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  // 构建分类项
  Widget _buildCategoryItem(
      Category category, double fontSize, double cardWidth) {
    final isUncategorized = category.id == 'uncategorized';
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.grey,
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUncategorized
                ? null
                : () => _showEditCategoryDialog(category),
            onLongPress: isUncategorized
                ? null
                : () => _showDeleteCategoryDialog(category),
            splashColor: AppTheme.black.withOpacity(0.1),
            highlightColor: AppTheme.black.withOpacity(0.1),
            hoverColor: AppTheme.black.withOpacity(0.03),
            borderRadius: AppTheme.smoothBorderRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    iconMap[category.icon] ?? Icons.folder_outlined,
                    size: 20,
                    color: AppTheme.black.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.black,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                  if (!isUncategorized)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppTheme.smoothBorderRadius,
                            onTap: () => _showEditCategoryDialog(category),
                            splashColor: AppTheme.black.withOpacity(0.1),
                            highlightColor: AppTheme.black.withOpacity(0.1),
                            hoverColor: AppTheme.black.withOpacity(0.03),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: AppTheme.smoothBorderRadius,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: AppTheme.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppTheme.smoothBorderRadius,
                            onTap: () => _showDeleteCategoryDialog(category),
                            splashColor: AppTheme.errorColor.withOpacity(0.1),
                            highlightColor:
                                AppTheme.errorColor.withOpacity(0.1),
                            hoverColor: AppTheme.errorColor.withOpacity(0.1),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: AppTheme.smoothBorderRadius,
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppTheme.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 验证分类名称的方法
  bool _validateCategoryName(String name, {String? currentCategoryId}) {
    if (name.isEmpty) return false;

    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    // 检查是否存在重名（排除当前编辑的分类）
    return !provider.categories.any((cat) =>
        cat.name == name &&
        (currentCategoryId == null || cat.id != currentCategoryId));
  }

  // 显示添加网站对话框
  void _showAddWebsiteDialog() {
    _websiteTitleController.clear();
    _websiteUrlController.clear();
    _websiteDescController.text = '';

    // 确保有未分类选项
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    if (!provider.categories.any((cat) => cat.id == 'uncategorized')) {
      provider.addCategory(Category(
        id: 'uncategorized',
        name: '未分类',
        icon: 'folder',
        order: -1,
      ));
    }
    setState(() {
      _selectedCategoryId = 'uncategorized';
      _isValidTitle = true;
      _isValidUrl = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 480,
            height: 528,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加网站',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _websiteTitleController,
                            autofocus: true,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _isValidTitle = _validateTitle(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: '请输入网站标题',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              errorText: !_isValidTitle &&
                                      _websiteTitleController.text.isNotEmpty
                                  ? '网站名称已存在'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _websiteUrlController,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _isValidUrl = _validateUrl(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'https://example.com',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              errorText: !_isValidUrl &&
                                      _websiteUrlController.text.isNotEmpty
                                  ? '请输入有效的网址'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _websiteDescController,
                            maxLines: 3,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: '请输入网站描述（可选）',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '归属分类',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Consumer<WebsiteProvider>(
                            builder: (context, provider, child) =>
                                CategorySelector(
                              categories: provider.categories,
                              selectedCategoryId: _selectedCategoryId!,
                              onCategorySelected: (categoryId) {
                                setDialogState(() {
                                  _selectedCategoryId = categoryId;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          AppTheme.textColor.withOpacity(0.5),
                        ),
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_websiteTitleController.text.isEmpty) {
                          _showErrorDialog(dialogContext, '请输入网站名称');
                          return;
                        }
                        if (!_isValidTitle) {
                          _showErrorDialog(dialogContext, '网站名称已存在');
                          return;
                        }
                        if (_websiteUrlController.text.isEmpty) {
                          _showErrorDialog(dialogContext, '请输入网站地址');
                          return;
                        }
                        if (!_isValidUrl) {
                          _showErrorDialog(dialogContext, '请输入有效的网址');
                          return;
                        }

                        final website = Website(
                          id: const Uuid().v4(),
                          title: _websiteTitleController.text,
                          url: _formatUrl(_websiteUrlController.text),
                          categoryId: _selectedCategoryId!,
                          description: _websiteDescController.text,
                        );
                        provider.addWebsite(website);
                        Navigator.pop(dialogContext);
                      },
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return AppTheme.black.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
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

  // 显示编辑网站对话框
  void _showEditWebsiteDialog(Website website) {
    _websiteTitleController.text = website.title;
    _websiteUrlController.text = website.url;
    _websiteDescController.text = website.description ?? '';
    _selectedCategoryId = website.categoryId;
    _isValidTitle = true; // 初始化为 true，因为当前标题是有效的

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 480,
            height: 528,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑网站',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _websiteTitleController,
                            autofocus: true,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isValidTitle = _validateTitle(value,
                                    currentWebsiteId: website.id);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: '请输入网站标题',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              errorText: !_isValidTitle &&
                                      _websiteTitleController.text.isNotEmpty
                                  ? '网站名称已存在'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _websiteUrlController,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isValidUrl = _validateUrl(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'https://example.com',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              errorText: !_isValidUrl &&
                                      _websiteUrlController.text.isNotEmpty
                                  ? '请输入有效的网址'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _websiteDescController,
                            maxLines: 3,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: '请输入网站描述（可选）',
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '归属分类',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Consumer<WebsiteProvider>(
                            builder: (context, provider, child) =>
                                CategorySelector(
                              categories: provider.categories,
                              selectedCategoryId: _selectedCategoryId!,
                              onCategorySelected: (categoryId) {
                                setState(() {
                                  _selectedCategoryId = categoryId;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          AppTheme.textColor.withOpacity(0.5),
                        ),
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_websiteTitleController.text.isEmpty) {
                          _showErrorDialog(context, '请输入网站名称');
                          return;
                        }
                        if (!_isValidTitle) {
                          _showErrorDialog(context, '网站名称已存在');
                          return;
                        }
                        if (_websiteUrlController.text.isEmpty) {
                          _showErrorDialog(context, '请输入网站地址');
                          return;
                        }
                        if (!_isValidUrl) {
                          _showErrorDialog(context, '请输入有效的网址');
                          return;
                        }

                        final updatedWebsite = Website(
                          id: website.id,
                          title: _websiteTitleController.text,
                          url: _formatUrl(_websiteUrlController.text),
                          categoryId: _selectedCategoryId!,
                          description: _websiteDescController.text,
                          createdAt: website.createdAt,
                        );
                        context
                            .read<WebsiteProvider>()
                            .updateWebsite(updatedWebsite);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return AppTheme.black.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
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

  // 验证网站名称的方法
  bool _validateTitle(String title, {String? currentWebsiteId}) {
    if (title.isEmpty) return false;

    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    // 检查是否存在重名（排除当前编辑的网站）
    return !provider.websites.any((site) =>
        site.title == title &&
        (currentWebsiteId == null || site.id != currentWebsiteId));
  }

  // 显示添加分类对话框
  void _showAddCategoryDialog() {
    _categoryNameController.clear();
    String selectedIcon = 'folder'; // 默认图标
    _isValidCategoryName = true; // 重置验证状态

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 480,
            height: 520,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加分类',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryNameController,
                  autofocus: true,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isValidCategoryName = _validateCategoryName(value);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '请输入分类名称',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    errorText: !_isValidCategoryName &&
                            _categoryNameController.text.isNotEmpty
                        ? '分类名称已存在'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: AppTheme.smoothBorderRadius,
                    ),
                    child: IconSelector(
                      selectedIcon: selectedIcon,
                      onIconSelected: (icon) {
                        setState(() {
                          selectedIcon = icon;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          AppTheme.textColor.withOpacity(0.5),
                        ),
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_categoryNameController.text.isEmpty) {
                          _showErrorDialog(context, '请输入分类名称');
                          return;
                        }
                        if (!_isValidCategoryName) {
                          _showErrorDialog(context, '分类名称已存在');
                          return;
                        }

                        final category = Category(
                          id: const Uuid().v4(),
                          name: _categoryNameController.text,
                          icon: selectedIcon,
                          order:
                              context.read<WebsiteProvider>().categories.length,
                        );
                        context.read<WebsiteProvider>().addCategory(category);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return AppTheme.black.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
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

  // 显示编辑分类对话框
  void _showEditCategoryDialog(Category category) {
    _categoryNameController.text = category.name;
    String selectedIcon = category.icon;
    _isValidCategoryName = true; // 初始化为 true，因为当前名称是有效的

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 480,
            height: 520,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑分类',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryNameController,
                  autofocus: true,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isValidCategoryName = _validateCategoryName(value,
                          currentCategoryId: category.id);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '请输入分类名称',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.smoothBorderRadius,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    errorText: !_isValidCategoryName &&
                            _categoryNameController.text.isNotEmpty
                        ? '分类名称已存在'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: AppTheme.smoothBorderRadius,
                    ),
                    child: IconSelector(
                      selectedIcon: selectedIcon,
                      onIconSelected: (icon) {
                        setState(() {
                          selectedIcon = icon;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          AppTheme.textColor.withOpacity(0.5),
                        ),
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.red.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_categoryNameController.text.isEmpty) {
                          _showErrorDialog(context, '请输入分类名称');
                          return;
                        }
                        if (!_isValidCategoryName) {
                          _showErrorDialog(context, '分类名称已存在');
                          return;
                        }

                        final updatedCategory = Category(
                          id: category.id,
                          name: _categoryNameController.text,
                          icon: selectedIcon,
                          order: category.order,
                        );
                        context
                            .read<WebsiteProvider>()
                            .updateCategory(updatedCategory);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return AppTheme.black.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
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

  // 显示删除分类确认对话框
  void _showDeleteCategoryDialog(Category category) {
    final FocusNode focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) => RawKeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            context.read<WebsiteProvider>().deleteCategory(category.id);
            Navigator.pop(context);
          }
        },
        child: Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 计算对话框尺寸
              final screenSize = MediaQuery.of(context).size;
              // 删除对话框：屏幕宽度的25%，但不小于280px，不大于360px
              final dialogWidth = screenSize.width *
                  0.25.clamp(280.0, 360.0); // 限制最小280px，最大360px
              final dialogHeight = 160.0; // 减小固定高度

              return Container(
                width: dialogWidth,
                height: dialogHeight,
                constraints: BoxConstraints(
                  minWidth: 280,
                  maxWidth: 360,
                  minHeight: 160,
                  maxHeight: 160,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '删除分类',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Text(
                        '确认要删除"${category.name}"吗？',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(
                              AppTheme.textColor.withOpacity(0.5),
                            ),
                            overlayColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.red.withOpacity(0.1);
                                }
                                return Colors.transparent;
                              },
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context
                                .read<WebsiteProvider>()
                                .deleteCategory(category.id);
                            Navigator.pop(context);
                          },
                          child: Text(
                            '确定',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 显示删除网站确认对话框
  void _showDeleteWebsiteDialog(Website website) {
    final FocusNode focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) => RawKeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            context.read<WebsiteProvider>().deleteWebsite(website.id);
            Navigator.pop(context);
          }
        },
        child: Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 计算对话框尺寸
              final screenSize = MediaQuery.of(context).size;
              // 删除对话框：屏幕宽度的25%，但不小于280px，不大于360px
              final dialogWidth = screenSize.width *
                  0.25.clamp(280.0, 360.0); // 限制最小280px，最大360px
              final dialogHeight = 160.0; // 减小固定高度

              return Container(
                width: dialogWidth,
                height: dialogHeight,
                constraints: BoxConstraints(
                  minWidth: 280,
                  maxWidth: 360,
                  minHeight: 160,
                  maxHeight: 160,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '删除网站',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Text(
                        '确认要删除"${website.title}"吗？',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(
                              AppTheme.textColor.withOpacity(0.5),
                            ),
                            overlayColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.red.withOpacity(0.1);
                                }
                                return Colors.transparent;
                              },
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context
                                .read<WebsiteProvider>()
                                .deleteWebsite(website.id);
                            Navigator.pop(context);
                          },
                          child: Text(
                            '确定',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 添加备份与恢复页面
  Widget _buildBackupRestorePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 备份卡片
            Container(
              height: 104.5,
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: AppTheme.smoothBorderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 备份标题栏
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.backup_outlined,
                          size: 24,
                          color: AppTheme.black.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '备份数据',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 备份内容
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '将所有网站和分类数据保存到本地文件',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.black.withOpacity(0.7),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _handleBackup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.black,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              minimumSize: const Size(120, 44),
                            ),
                            child: Text('开始备份'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            // 恢复卡片
            Container(
              height: 104.5,
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: AppTheme.smoothBorderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 恢复标题栏
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restore_outlined,
                          size: 24,
                          color: AppTheme.black.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '恢复数据',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 恢复内容
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '从本地备份文件恢复数据（将覆盖当前数据）',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.black.withOpacity(0.7),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _handleRestore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.black,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              minimumSize: const Size(120, 44),
                            ),
                            child: Text('开始恢复'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建功能项（通用）
  Widget _buildFeatureItem({
    required String text,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.black.withOpacity(0.05),
              borderRadius: AppTheme.smoothBorderRadius,
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 处理备份功能
  Future<void> _handleBackup() async {
    try {
      final provider = Provider.of<WebsiteProvider>(context, listen: false);
      final filePath = await DesktopBackupRestoreUtils.handleBackup(
        context,
        provider,
      );

      if (filePath != null && mounted) {
        _showSuccessDialog('备份成功', '文件已保存到：', filePath);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  // 处理恢复功能
  Future<void> _handleRestore() async {
    try {
      final provider = Provider.of<WebsiteProvider>(context, listen: false);
      final success = await DesktopBackupRestoreUtils.handleRestore(
        context,
        provider,
      );

      if (success && mounted) {
        _showSuccessDialog('恢复成功', '数据已成功恢复', null);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  // 显示成功对话框
  void _showSuccessDialog(String title, String message, String? path) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.black.withOpacity(0.7),
                ),
              ),
              if (path != null) ...[
                const SizedBox(height: 4),
                Text(
                  path,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.black,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建关于页面
  Widget _buildAboutPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部区域
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.05),
                    borderRadius: AppTheme.smoothBorderRadius,
                  ),
                  child: ClipRRect(
                    borderRadius: AppTheme.smoothBorderRadius,
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navi 导航',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '简洁、高效的网站导航工具',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 版本信息
            InkWell(
              onTap: () async {
                try {
                  // 显示加载对话框
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Dialog(
                      backgroundColor: AppTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.smoothBorderRadius,
                      ),
                      child: Container(
                        width: 280,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.black),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '正在检查更新...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  final (hasUpdate, _) = await UpdateService.checkUpdate();

                  // 关闭加载对话框
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  // 如果没有更新，显示提示
                  if (!hasUpdate && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.smoothBorderRadius,
                        ),
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 36,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '已是最新版本',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (hasUpdate && context.mounted) {
                    await UpdateService.checkUpdateAndShowDialog(context);
                  }
                } catch (e) {
                  // 关闭加载对话框
                  if (context.mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.smoothBorderRadius,
                        ),
                        child: Container(
                          width: 320,
                          constraints: BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '提示',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Scrollbar(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        '检查更新失败：${e.toString().contains('403') ? '请求次数过多，请一小时后再尝试' : e}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ButtonStyle(
                                      overlayColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.hovered)) {
                                            return Colors.red.withOpacity(0.1);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      padding: MaterialStateProperty.all(
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '确定',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
              borderRadius: AppTheme.smoothBorderRadius,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: AppTheme.smoothBorderRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.black.withOpacity(1),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '当前版本：${AppVersion.getVersionNumber()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.black,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppTheme.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 主要功能
            Text(
              '主要功能',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              text: '网站管理',
              description: '支持添加、编辑和删除网站',
              icon: Icons.language_outlined,
            ),
            _buildFeatureItem(
              text: '分类管理',
              description: '支持创建和管理网站分类',
              icon: Icons.category_outlined,
            ),
            _buildFeatureItem(
              text: '数据备份',
              description: '支持数据备份和恢复',
              icon: Icons.backup_outlined,
            ),
            _buildFeatureItem(
              text: '跨平台支持',
              description: '支持 Windows 和 Android 平台',
              icon: Icons.devices_outlined,
            ),
            const SizedBox(height: 32),

            // 版权信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: AppTheme.smoothBorderRadius,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copyright_outlined,
                        size: 16,
                        color: AppTheme.black.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '2024 Navi',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用 Flutter 构建，采用 MIT 开源协议',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 显示错误提示的方法
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '提示',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
