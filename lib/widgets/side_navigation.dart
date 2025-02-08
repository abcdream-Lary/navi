import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../constants/icon_data.dart';
import 'package:provider/provider.dart';
import '../providers/website_provider.dart';

/// 侧边栏导航组件
class SideNavigation extends StatefulWidget {
  final int selectedIndex; // 当前选中的导航项索引
  final List<Category> categories; // 分类列表
  final Function(int) onItemSelected; // 导航项选中回调
  final bool isSettingsNav; // 是否为设置页面的导航

  const SideNavigation({
    Key? key,
    required this.selectedIndex,
    required this.categories,
    required this.onItemSelected,
    this.isSettingsNav = false,
  }) : super(key: key);

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppTheme.white,
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isSettingsNav) ...[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.black,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (!widget.isSettingsNav) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                ],
                Text(
                  widget.isSettingsNav ? '设置' : '主页',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 分类列表区域（可滚动）
          Expanded(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.isSettingsNav
                      ? widget.categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          return _buildNavItem(
                            icon:
                                iconMap[category.icon] ?? Icons.folder_outlined,
                            label: category.name,
                            index: index,
                          );
                        }).toList()
                      : [
                          // 全部分类选项
                          _buildNavItem(
                            icon: Icons.home_outlined,
                            label: '全部',
                            index: 0,
                          ),
                          // 动态分类列表
                          ...widget.categories
                              .where(
                                  (category) => category.id != 'uncategorized')
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key + 1; // 索引从1开始，因为0是"全部"
                            final category = entry.value;
                            return _buildNavItem(
                              icon: iconMap[category.icon] ??
                                  Icons.folder_outlined,
                              label: category.name,
                              index: index,
                            );
                          }).toList(),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航菜单项
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;
    final category = !widget.isSettingsNav && index != 0
        ? widget.categories[index - 1]
        : null;

    return Container(
      margin: EdgeInsets.only(
        top: index == 0 ? 0 : 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.black : AppTheme.grey,
        borderRadius: AppTheme.smoothBorderRadius,
      ),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          borderRadius: AppTheme.smoothBorderRadius,
          onTap: () => widget.onItemSelected(index),
          onSecondaryTap:
              !widget.isSettingsNav ? () => _showCategoryMenu(category) : null,
          onLongPress:
              !widget.isSettingsNav ? () => _showCategoryMenu(category) : null,
          hoverColor: isSelected
              ? AppTheme.black.withOpacity(0.1)
              : AppTheme.black.withOpacity(0.03),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.white : AppTheme.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.black,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
                if (!widget.isSettingsNav && category?.isPinned == true)
                  Icon(
                    Icons.push_pin,
                    size: 14,
                    color: isSelected
                        ? AppTheme.white.withOpacity(0.5)
                        : AppTheme.black.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示分类操作菜单
  void _showCategoryMenu(Category? category) {
    if (category == null) return;

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
                        category.name,
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
                        final updatedCategory =
                            category.copyWith(isPinned: !category.isPinned);
                        Provider.of<WebsiteProvider>(context, listen: false)
                            .updateCategory(updatedCategory);
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
}
