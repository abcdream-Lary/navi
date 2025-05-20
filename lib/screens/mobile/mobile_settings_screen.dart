import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/website_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/website.dart';
import '../../models/category.dart';
import '../../utils/backup_restore_utils.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/icon_selector.dart';
import '../../constants/icon_data.dart';
import '../../services/update_service.dart';
import '../../constants/app_version.dart';

/// 移动端设置屏幕
class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  final List<SettingItem> _settingItems = [
    SettingItem(
      id: 'website_management',
      title: '网站管理',
      icon: Icons.language_outlined,
    ),
    SettingItem(
      id: 'category_management',
      title: '分类管理',
      icon: Icons.category_outlined,
    ),
    SettingItem(
      id: 'backup_restore',
      title: '备份与恢复',
      icon: Icons.backup_outlined,
    ),
    SettingItem(
      id: 'about',
      title: '关于',
      icon: Icons.info_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          itemCount: _settingItems.length,
          itemBuilder: (context, index) {
            final item = _settingItems[index];
            return _buildSettingItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildSettingItem(SettingItem item) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: () => _navigateToSettingDetail(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.black.withOpacity(0.05),
                  borderRadius: AppTheme.smoothBorderRadius,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: AppTheme.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSettingDetail(SettingItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingDetailScreen(item: item),
      ),
    );
  }
}

class SettingDetailScreen extends StatefulWidget {
  final SettingItem item;

  const SettingDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<SettingDetailScreen> createState() => _SettingDetailScreenState();
}

class _SettingDetailScreenState extends State<SettingDetailScreen> {
  final TextEditingController _websiteTitleController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _websiteDescController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  String? _selectedCategoryId;
  bool _isValidTitle = true;
  bool _isValidUrl = true;
  bool _isValidCategoryName = true;

  @override
  void dispose() {
    _websiteTitleController.dispose();
    _websiteUrlController.dispose();
    _websiteDescController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppTheme.transparent,
        shadowColor: AppTheme.transparent,
        actions: _buildActions(),
      ),
      body: _buildBody(),
    );
  }

  List<Widget> _buildActions() {
    if (widget.item.id == 'website_management' ||
        widget.item.id == 'category_management') {
      return [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            if (widget.item.id == 'website_management') {
              _showAddWebsiteDialog();
            } else {
              _showAddCategoryDialog();
            }
          },
        ),
      ];
    }
    return [];
  }

  Widget _buildBody() {
    switch (widget.item.id) {
      case 'website_management':
        return _buildWebsiteList();
      case 'category_management':
        return _buildCategoryList();
      case 'backup_restore':
        return _buildBackupRestore();
      case 'about':
        return _buildAbout();
      default:
        return const SizedBox();
    }
  }

  // 网站列表
  Widget _buildWebsiteList() {
    return Consumer<WebsiteProvider>(
      builder: (context, provider, child) {
        final websites = provider.websites;
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
            final double cardWidth =
                constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            final int crossAxisCount = cardWidth < 320 ? 1 : 2; // 调整断点

            // 缓存网格布局代理
            final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 108,
            );

            return ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: GridView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16,
                ),
                gridDelegate: gridDelegate,
                itemCount: websites.length,
                cacheExtent: 500, // 增加缓存范围
                itemBuilder: (context, index) {
                  final website = websites[index];
                  return SizedBox(
                    width: (cardWidth - 36) / 2,
                    child: _buildWebsiteItem(website),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // 分类列表
  Widget _buildCategoryList() {
    return Consumer<WebsiteProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: AppTheme.black.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无分类',
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
            final double cardWidth =
                constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            final int crossAxisCount = cardWidth < 320 ? 1 : 2; // 调整断点

            return ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: GridView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 45,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return SizedBox(
                    width: (cardWidth - 36) / 2,
                    child: _buildCategoryItem(category),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // 备份与恢复
  Widget _buildBackupRestore() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16,
        ),
        children: [
          _buildBackupRestoreItem(
            icon: Icons.backup_outlined,
            title: '备份数据',
            subtitle: '将所有数据保存到本地文件',
            onTap: () => _handleBackup(context),
          ),
          const SizedBox(height: 12),
          _buildBackupRestoreItem(
            icon: Icons.restore_outlined,
            title: '恢复数据',
            subtitle: '从备份文件恢复数据',
            onTap: () => _handleRestore(context),
          ),
        ],
      ),
    );
  }

  // 关于页面
  Widget _buildAbout() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16,
        ),
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
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppTheme.black),
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
                            Flexible(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Text(
                                  '检查更新失败：${e.toString().contains('403') ? '请求次数过多，请一小时后再尝试' : e}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textColor,
                                  ),
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
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states
                                            .contains(MaterialState.hovered)) {
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
    );
  }

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

  Widget _buildWebsiteItem(Website website) {
    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: InkWell(
          onTap: () {
            _showEditWebsiteDialog(website);
          },
          onLongPress: () {
            _showDeleteWebsiteDialog(website);
          },
          borderRadius: AppTheme.smoothBorderRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: AppTheme.grey,
              borderRadius: AppTheme.smoothBorderRadius,
            ),
            child: Stack(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  height: 108,
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
                                    // 缓存文本绘制
                                    final titleStyle = const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    );
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: website.title,
                                        style: titleStyle,
                                      ),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: double.infinity);
                                    final bool isOverflow = textPainter.width >
                                        constraints.maxWidth - 32;

                                    final Widget text = Text(
                                      website.title,
                                      style: titleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      softWrap: false,
                                    );

                                    if (isOverflow) {
                                      // 缓存渐变遮罩
                                      final gradient = LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          AppTheme.black,
                                          AppTheme.black,
                                          AppTheme.black.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.85, 1.0],
                                      );

                                      return ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return gradient.createShader(bounds);
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
                          const SizedBox(height: 4),
                          // 网址
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // 缓存文本绘制
                              final urlStyle = TextStyle(
                                fontSize: 11,
                                color: AppTheme.black.withOpacity(0.6),
                                height: 1.3,
                              );
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: website.url,
                                  style: urlStyle,
                                ),
                                maxLines: 1,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: double.infinity);
                              final bool isOverflow =
                                  textPainter.width > constraints.maxWidth - 32;

                              final Widget text = Text(
                                website.url,
                                style: urlStyle,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                              );

                              if (isOverflow) {
                                // 缓存渐变遮罩
                                final gradient = LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppTheme.black,
                                    AppTheme.black,
                                    AppTheme.black.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.85, 1.0],
                                );

                                return ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return gradient.createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: text,
                                );
                              }
                              return text;
                            },
                          ),
                          if (website.description != null &&
                              website.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            // 简介
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // 缓存文本绘制
                                final descStyle = TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.black.withOpacity(0.6),
                                  height: 1.3,
                                );
                                final textPainter = TextPainter(
                                  text: TextSpan(
                                    text: website.description!,
                                    style: descStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: double.infinity);
                                final bool isOverflow = textPainter.width >
                                    constraints.maxWidth - 32;

                                final Widget text = Text(
                                  website.description!,
                                  style: descStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                );

                                if (isOverflow) {
                                  // 缓存渐变遮罩
                                  final gradient = LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.black,
                                      AppTheme.black,
                                      AppTheme.black.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.85, 1.0],
                                  );

                                  return ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return gradient.createShader(bounds);
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
                          final category =
                              provider.getCategoryById(website.categoryId);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category) {
    final isUncategorized = category.id == 'uncategorized';
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.smoothBorderRadius,
      ),
      child: InkWell(
        onTap: () {
          if (!isUncategorized) {
            _showEditCategoryDialog(category);
          }
        },
        onLongPress: () {
          if (!isUncategorized) {
            _showDeleteCategoryDialog(category);
          }
        },
        borderRadius: AppTheme.smoothBorderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.grey,
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  getIconData(category.icon),
                  size: 16,
                  color: AppTheme.black.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: category.name,
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
                        category.name,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupRestoreItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.smoothBorderRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.smoothBorderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
        ),
      ),
    );
  }

  // 验证网站标题
  bool _validateTitle(String title, {String? currentWebsiteId}) {
    if (title.trim().isEmpty) return true;
    final provider = context.read<WebsiteProvider>();
    return !provider.websites.any((site) =>
        site.title.toLowerCase() == title.trim().toLowerCase() &&
        (currentWebsiteId == null || site.id != currentWebsiteId));
  }

  // 验证网站URL
  bool _validateUrl(String url) {
    if (url.trim().isEmpty) return true;
    final urlPattern = RegExp(
      r'^(http:\/\/|https:\/\/)?'
      r'([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}'
      r'(\/[^\s]*)?$',
    );
    return urlPattern.hasMatch(url.trim());
  }

  // 获取标题验证错误信息
  String? _getTitleErrorText(String title, {String? currentWebsiteId}) {
    if (title.trim().isEmpty) return null;
    if (!_validateTitle(title, currentWebsiteId: currentWebsiteId)) {
      return '网站名称已存在';
    }
    return null;
  }

  // 获取URL验证错误信息
  String? _getUrlErrorText(String url) {
    if (url.trim().isEmpty) return null;
    if (!_validateUrl(url)) {
      return '请输入有效的网址';
    }
    return null;
  }

  // 显示验证失败弹窗
  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 320,
            height: 160,
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ButtonStyle(
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
      ),
    );
  }

  // 添加网站对话框
  void _showAddWebsiteDialog() {
    _websiteTitleController.clear();
    _websiteUrlController.clear();
    _websiteDescController.clear();
    _selectedCategoryId = 'uncategorized';
    _isValidTitle = true;
    _isValidUrl = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.51,
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 8,
            ),
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
                            autofocus: false,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                            onChanged: (value) {
                              setState(() {
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
                              errorText: _getTitleErrorText(
                                  _websiteTitleController.text),
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
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
                              errorText:
                                  _getUrlErrorText(_websiteUrlController.text),
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
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
                            builder: (context, provider, child) {
                              return CategorySelector(
                                categories: provider.categories,
                                selectedCategoryId: _selectedCategoryId!,
                                onCategorySelected: (categoryId) {
                                  setState(() {
                                    _selectedCategoryId = categoryId;
                                  });
                                },
                              );
                            },
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
                        if (_validateAndSaveWebsite(null)) {
                          Navigator.pop(context);
                        }
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

  // 编辑网站对话框
  void _showEditWebsiteDialog(Website website) {
    _websiteTitleController.text = website.title;
    _websiteUrlController.text = website.url;
    _websiteDescController.text = website.description ?? '';
    _selectedCategoryId = website.categoryId;
    _isValidTitle = true;
    _isValidUrl = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 8,
            ),
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
                            autofocus: false,
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
                              errorText: _getTitleErrorText(
                                  _websiteTitleController.text,
                                  currentWebsiteId: website.id),
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
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
                              errorText:
                                  _getUrlErrorText(_websiteUrlController.text),
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
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
                            builder: (context, provider, child) {
                              return CategorySelector(
                                categories: provider.categories,
                                selectedCategoryId: _selectedCategoryId!,
                                onCategorySelected: (categoryId) {
                                  setState(() {
                                    _selectedCategoryId = categoryId;
                                  });
                                },
                              );
                            },
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_validateAndSaveWebsite(website)) {
                          Navigator.pop(context);
                        }
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
                            horizontal: 16,
                            vertical: 8,
                          ),
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

  // 删除网站对话框
  void _showDeleteWebsiteDialog(Website website) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 320,
            height: 160,
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          '删除网站',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '确定要删除"${website.title}"吗？',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
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
                        context
                            .read<WebsiteProvider>()
                            .deleteWebsite(website.id);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
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
                      child: Text(
                        '删除',
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
      ),
    );
  }

  // 添加分类对话框
  void _showAddCategoryDialog() {
    _categoryNameController.clear();
    _isValidCategoryName = true;
    String selectedIcon = 'folder'; // 默认图标

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加分类',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryNameController,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '分类名称',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                      borderSide: BorderSide(
                        color: AppTheme.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isValidCategoryName = _validateCategoryName(value);
                    });
                  },
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
                      isMobile: true, // 使用移动端布局
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_validateAndSaveCategory(null,
                            selectedIcon: selectedIcon)) {
                          Navigator.pop(context);
                        }
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
                            horizontal: 16,
                            vertical: 8,
                          ),
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

  // 编辑分类对话框
  void _showEditCategoryDialog(Category category) {
    _categoryNameController.text = category.name;
    _isValidCategoryName = true;
    String selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑分类',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryNameController,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '分类名称',
                    hintStyle: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                      borderSide: BorderSide(
                        color: AppTheme.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isValidCategoryName = _validateCategoryName(
                        value,
                        currentCategoryId: category.id,
                      );
                    });
                  },
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
                      isMobile: true, // 使用移动端布局
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (_validateAndSaveCategory(category,
                            selectedIcon: selectedIcon)) {
                          Navigator.pop(context);
                        }
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
                            horizontal: 16,
                            vertical: 8,
                          ),
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

  // 删除分类对话框
  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      '删除分类',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '确定要删除"${category.name}"吗？',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 24),
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
                        context
                            .read<WebsiteProvider>()
                            .deleteCategory(category.id);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
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
                      child: Text(
                        '删除',
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
      ),
    );
  }

  // 验证并保存网站
  bool _validateAndSaveWebsite(Website? existingWebsite) {
    final title = _websiteTitleController.text.trim();
    final url = _websiteUrlController.text.trim();
    final description = _websiteDescController.text.trim();
    bool hasError = false;
    String errorMessage = '';

    // 验证标题
    if (title.isEmpty) {
      hasError = true;
      errorMessage = '请输入网站名称';
    } else if (!_isValidTitle) {
      hasError = true;
      errorMessage = '网站名称已存在';
    }

    // 验证URL
    if (!hasError) {
      if (url.isEmpty) {
        hasError = true;
        errorMessage = '请输入网站地址';
      } else if (!_isValidUrl) {
        hasError = true;
        errorMessage = '请输入有效的网址';
      }
    }

    if (hasError) {
      _showValidationDialog(errorMessage);
      return false;
    }

    // 验证通过，直接保存
    final website = Website(
      id: existingWebsite?.id ?? const Uuid().v4(),
      title: title,
      url: _formatUrl(url),
      categoryId: _selectedCategoryId!,
      description: description.isEmpty ? null : description,
      createdAt: existingWebsite?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<WebsiteProvider>();
    if (existingWebsite != null) {
      provider.updateWebsite(website);
    } else {
      provider.addWebsite(website);
    }

    return true;
  }

  // 验证并保存分类
  bool _validateAndSaveCategory(Category? existingCategory,
      {String selectedIcon = 'folder'}) {
    final name = _categoryNameController.text.trim();
    bool hasError = false;
    String errorMessage = '';

    // 验证分类名称
    if (name.isEmpty) {
      hasError = true;
      errorMessage = '请输入分类名称';
    } else if (!_isValidCategoryName) {
      hasError = true;
      errorMessage = '分类名称已存在';
    }

    if (hasError) {
      _showValidationDialog(errorMessage);
      return false;
    }

    // 验证通过，直接保存
    final category = Category(
      id: existingCategory?.id ?? const Uuid().v4(),
      name: name,
      icon: selectedIcon,
      order: existingCategory?.order ??
          context.read<WebsiteProvider>().categories.length,
    );

    final provider = context.read<WebsiteProvider>();
    if (existingCategory != null) {
      provider.updateCategory(category);
    } else {
      provider.addCategory(category);
    }

    return true;
  }

  // 格式化URL
  String _formatUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  // 验证分类名称
  bool _validateCategoryName(String name, {String? currentCategoryId}) {
    if (name.isEmpty) return false;
    final provider = context.read<WebsiteProvider>();
    return !provider.categories.any((cat) =>
        cat.name == name &&
        (currentCategoryId == null || cat.id != currentCategoryId));
  }

  // 处理备份功能
  Future<void> _handleBackup(BuildContext context) async {
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final filePath = await BackupRestoreUtils.handleBackup(context, provider);

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已保存到：$filePath')),
      );
    }
  }

  // 处理恢复功能
  Future<void> _handleRestore(BuildContext context) async {
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    await BackupRestoreUtils.handleRestore(context, provider);
  }
}

class SettingItem {
  final String id;
  final String title;
  final IconData icon;

  SettingItem({
    required this.id,
    required this.title,
    required this.icon,
  });
}
