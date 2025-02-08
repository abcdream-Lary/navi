import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/side_navigation.dart';
import '../theme/app_theme.dart';
import '../providers/website_provider.dart';
import '../models/website.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/search_service.dart';
import '../utils/responsive_layout.dart';
import 'mobile/mobile_home_screen.dart';

/// 主页面
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: const MobileHomeScreen(),
      desktopLayout: const DesktopHomeScreen(),
    );
  }
}

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({Key? key}) : super(key: key);

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 只在数据未预加载时加载数据
    Future.microtask(() {
      final provider = context.read<WebsiteProvider>();
      if (!provider.isPreloaded) {
        provider.preloadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 左侧导航栏
              Consumer<WebsiteProvider>(
                builder: (context, provider, child) {
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(
                      bottom: 76,
                    ),
                    child: SideNavigation(
                      selectedIndex: _selectedIndex,
                      categories: provider.categories,
                      onItemSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
              // 主内容区域
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: AppTheme.backgroundColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Consumer<WebsiteProvider>(
                              builder: (context, provider, child) {
                                // 获取非"未分类"的分类列表
                                final displayCategories = provider.categories
                                    .where((category) =>
                                        category.id != 'uncategorized')
                                    .toList();

                                // 检查选中的索引是否有效
                                Widget titleText;
                                if (_selectedIndex > displayCategories.length) {
                                  titleText = const Text(
                                    '全部',
                                    style: TextStyle(
                                      color: AppTheme.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                  );
                                } else {
                                  final categoryName = _selectedIndex == 0
                                      ? '全部'
                                      : displayCategories[_selectedIndex - 1]
                                          .name;
                                  titleText = Text(
                                    categoryName,
                                    style: const TextStyle(
                                      color: AppTheme.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                  );
                                }

                                return ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        AppTheme.black,
                                        AppTheme.black,
                                        AppTheme.black.withOpacity(0),
                                      ],
                                      stops: const [0.0, 0.8, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: titleText,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 搜索框
                          Container(
                            width: 213,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: AppTheme.smoothBorderRadius,
                              border: Border.all(
                                color: AppTheme.black.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                              },
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: '搜索网站...',
                                counterText: '',
                                hintStyle: TextStyle(
                                  color: AppTheme.black.withOpacity(0.3),
                                  fontSize: 14,
                                ),
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.search,
                                    color: AppTheme.black.withOpacity(0.3),
                                    size: 20,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 36,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.only(right: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 内容网格区域
                    Expanded(
                      child: Consumer<WebsiteProvider>(
                        builder: (context, provider, child) {
                          // 获取非"未分类"的分类列表
                          final displayCategories = provider.categories
                              .where(
                                  (category) => category.id != 'uncategorized')
                              .toList();

                          // 检查选中的索引是否有效
                          if (_selectedIndex > displayCategories.length) {
                            // 如果选中的索引无效，显示所有网站
                            return _buildWebsitesGrid(provider.websites);
                          }

                          final websites = _selectedIndex == 0
                              ? provider.websites
                              : provider.getWebsitesByCategory(
                                  displayCategories[_selectedIndex - 1].id);

                          final filteredWebsites = SearchService.filterWebsites(
                              websites, _searchQuery);

                          return _buildWebsitesGrid(filteredWebsites);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 左下角工具栏
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: AppTheme.smoothBorderRadius,
              ),
              child: _buildIconButton(Icons.settings_outlined),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网站网格
  Widget _buildWebsitesGrid(List<Website> websites) {
    // 对网站列表进行排序，置顶的网站在前面
    final sortedWebsites = [...websites]..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: websites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.web_outlined,
                    size: 32,
                    color: AppTheme.black.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
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
                double fontSize = 14.0;
                const double cardHeight = 104.0;
                const double cardWidth = 240.0;

                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: cardWidth,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: cardHeight,
                    ),
                    itemCount: sortedWebsites.length,
                    itemBuilder: (context, index) {
                      return _buildWebsiteItem(
                        sortedWebsites[index],
                        fontSize,
                        4,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  /// 构建网站项
  Widget _buildWebsiteItem(
      Website website, double fontSize, int crossAxisCount) {
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
            onTap: () => _launchUrl(website.url),
            onSecondaryTap: () => _showWebsiteMenu(website),
            onLongPress: () => _showWebsiteMenu(website),
            splashColor: AppTheme.black.withOpacity(0.1),
            highlightColor: AppTheme.black.withOpacity(0.1),
            hoverColor: AppTheme.black.withOpacity(0.03),
            child: Stack(
              children: [
                // 主要内容
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 14,
                    right: 16,
                    bottom: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              website.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                          if (website.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: AppTheme.black.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (website.description?.isNotEmpty == true)
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
                // 分类（左下角）
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      Provider.of<WebsiteProvider>(context, listen: false)
                          .getCategoryById(website.categoryId)
                          .name,
                      style: TextStyle(
                        fontSize: fontSize - 3,
                        color: AppTheme.black.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示网站操作菜单
  void _showWebsiteMenu(Website website) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        website.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.black.withOpacity(0.5),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按钮
              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radius),
                  bottomRight: Radius.circular(AppTheme.radius),
                ),
                child: Container(
                  color: AppTheme.cardColor,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final provider = context.read<WebsiteProvider>();
                        final updatedWebsite =
                            website.copyWith(isPinned: !website.isPinned);
                        provider.updateWebsite(updatedWebsite);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.black.withOpacity(0.05),
                                borderRadius: AppTheme.smoothBorderRadius,
                              ),
                              child: Icon(
                                website.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 18,
                                color: AppTheme.black.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              website.isPinned ? '取消置顶' : '置顶',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.black.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 打开URL
  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  /// 构建图标按钮
  Widget _buildIconButton(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.smoothBorderRadius,
        onTap: () => Navigator.pushNamed(context, '/settings'),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.black.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
