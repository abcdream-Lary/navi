import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/website_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/website.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/icon_data.dart';
import '../../models/category.dart';
import 'package:flutter/services.dart';

/// 移动端主屏幕
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({Key? key}) : super(key: key);

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  String _selectedCategoryId = 'all';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WebsiteProvider>().preloadData();
    });
    // 确保搜索框在初始化时不会自动获取焦点
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击空白处时取消搜索框的焦点
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'N',
                  style: TextStyle(
                    color: AppTheme.black.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('我的导航'),
            ],
          ),
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: AppTheme.transparent,
          shadowColor: AppTheme.transparent,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: AppTheme.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    child: Icon(
                      Icons.tune_outlined,
                      size: 18,
                      color: AppTheme.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '搜索网站...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.black.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.smoothBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // 分类选择器
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 40,
                child: Consumer<WebsiteProvider>(
                  builder: (context, provider, child) {
                    // 过滤掉未分类
                    final categories = provider.categories
                        .where((cat) => cat.id != 'uncategorized')
                        .toList();

                    // 添加置顶排序逻辑
                    categories.sort((a, b) {
                      if (a.isPinned && !b.isPinned) return -1;
                      if (!a.isPinned && b.isPinned) return 1;
                      return 0;
                    });

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final category = isAll ? null : categories[index - 1];
                        final categoryId = isAll ? 'all' : category!.id;
                        final isSelected = _selectedCategoryId == categoryId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onLongPress: isAll
                                ? null
                                : () {
                                    if (category != null) {
                                      HapticFeedback.mediumImpact();
                                      _showCategoryMenu(category);
                                    }
                                  },
                            child: FilterChip(
                              avatar: Icon(
                                isAll
                                    ? Icons.home_outlined
                                    : getIconData(category!.icon),
                                size: 18,
                                color: isSelected
                                    ? AppTheme.white
                                    : AppTheme.black.withOpacity(0.6),
                              ),
                              label: Text(isAll ? '全部' : category!.name),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryId = categoryId;
                                });
                              },
                              backgroundColor: AppTheme.grey,
                              selectedColor: AppTheme.black,
                              checkmarkColor: AppTheme.black,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.white
                                    : AppTheme.black.withOpacity(0.6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.smoothBorderRadius,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // 网站列表
            Expanded(
              child: Consumer<WebsiteProvider>(
                builder: (context, provider, child) {
                  var websites = _selectedCategoryId == 'all'
                      ? provider.websites
                      : provider.getWebsitesByCategory(_selectedCategoryId);

                  if (_searchQuery.isNotEmpty) {
                    websites = websites.where((website) {
                      return website.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          website.url
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          (website.description
                                  ?.toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ??
                              false);
                    }).toList();
                  }

                  // 对网站列表进行排序，置顶的网站在前面
                  websites.sort((a, b) {
                    if (a.isPinned && !b.isPinned) return -1;
                    if (!a.isPinned && b.isPinned) return 1;
                    return 0;
                  });

                  if (websites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.web_outlined,
                            size: 48,
                            color: AppTheme.black.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无网站',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.black.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double cardWidth = constraints.maxWidth > 600
                          ? 600
                          : constraints.maxWidth;
                      final int crossAxisCount =
                          cardWidth < 320 ? 1 : 2; // 调整断点

                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 85,
                          ),
                          itemCount: websites.length,
                          itemBuilder: (context, index) {
                            final website = websites[index];
                            return SizedBox(
                              width: (cardWidth - 36) / 2,
                              child: _buildWebsiteCard(website),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteCard(Website website) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.grey,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.smoothBorderRadius,
      ),
      child: InkWell(
        onTap: () => _launchUrl(website.url),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showWebsiteMenu(website);
        },
        borderRadius: AppTheme.smoothBorderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          height: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 上部内容
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textPainter = TextPainter(
                              text: TextSpan(
                                text: website.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                            );
                            textPainter.layout(maxWidth: double.infinity);
                            final bool isOverflow =
                                textPainter.width > constraints.maxWidth - 32;

                            final Widget text = Text(
                              website.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                            );

                            if (isOverflow) {
                              return ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.black,
                                      AppTheme.black,
                                      AppTheme.black.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.85, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: text,
                              );
                            }
                            return text;
                          },
                        ),
                      ),
                      if (website.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 13,
                            color: AppTheme.black.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                  if (website.description != null &&
                      website.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // 简介
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: website.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.black.withOpacity(0.6),
                              height: 1.3,
                            ),
                          ),
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        );
                        textPainter.layout(maxWidth: double.infinity);
                        final bool isOverflow =
                            textPainter.width > constraints.maxWidth - 32;

                        final Widget text = Text(
                          website.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.black.withOpacity(0.6),
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        );

                        if (isOverflow) {
                          return ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppTheme.black,
                                  AppTheme.black,
                                  AppTheme.black.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.85, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: text,
                          );
                        }
                        return text;
                      },
                    ),
                  ],
                ],
              ),
              // 归属分类
              Consumer<WebsiteProvider>(
                builder: (context, provider, child) {
                  final category = provider.getCategoryById(website.categoryId);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.black.withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),
            ],
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
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radius),
                    topRight: Radius.circular(AppTheme.radius),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
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
                        minWidth: 35,
                        minHeight: 35,
                      ),
                      visualDensity: VisualDensity.compact,
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
                    color: AppTheme.transparent,
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

  /// 显示分类操作菜单
  void _showCategoryMenu(Category category) {
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
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radius),
                    topRight: Radius.circular(AppTheme.radius),
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
                    Icon(
                      getIconData(category.icon),
                      size: 18,
                      color: AppTheme.black.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
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
                        minWidth: 35,
                        minHeight: 35,
                      ),
                      visualDensity: VisualDensity.compact,
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
                    color: AppTheme.transparent,
                    child: InkWell(
                      onTap: () {
                        context
                            .read<WebsiteProvider>()
                            .toggleCategoryPin(category.id);
                        Navigator.pop(context);
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
                                category.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 18,
                                color: AppTheme.black.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category.isPinned ? '取消置顶' : '置顶',
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

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
