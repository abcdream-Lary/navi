import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../constants/icon_data.dart';

class CategorySelector extends StatefulWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final Function(String) onCategorySelected;

  const CategorySelector({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _isExpanded = false;

  // 创建垂直圆角
  BorderRadius get _verticalBorderRadius => BorderRadius.vertical(
        top: Radius.circular(AppTheme.radius),
        bottom: Radius.circular(AppTheme.radius),
      );

  // 创建顶部圆角
  BorderRadius get _topBorderRadius => BorderRadius.vertical(
        top: Radius.circular(AppTheme.radius),
      );

  // 创建底部圆角
  BorderRadius get _bottomBorderRadius => BorderRadius.vertical(
        bottom: Radius.circular(AppTheme.radius),
      );

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere(
      (cat) => cat.id == widget.selectedCategoryId,
      orElse: () => Category(
        id: 'uncategorized',
        name: '未分类',
        icon: 'folder',
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主输入框
        Material(
          color: AppTheme.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: _isExpanded ? _topBorderRadius : _verticalBorderRadius,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius:
                    _isExpanded ? _topBorderRadius : _verticalBorderRadius,
              ),
              child: TextField(
                controller: TextEditingController(
                  text: selectedCategory.name,
                ),
                readOnly: true,
                enabled: false,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius:
                        _isExpanded ? _topBorderRadius : _verticalBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        _isExpanded ? _topBorderRadius : _verticalBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        _isExpanded ? _topBorderRadius : _verticalBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius:
                        _isExpanded ? _topBorderRadius : _verticalBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  prefixIcon: Icon(
                    getIconData(selectedCategory.icon),
                    size: 20,
                    color: AppTheme.textColor,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        // 渐变遮罩
                        Container(
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppTheme.cardColor.withOpacity(0),
                                AppTheme.cardColor,
                              ],
                            ),
                          ),
                        ),
                        // 箭头图标
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textColor.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 展开的下拉列表
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, _isExpanded ? -4 : -8, 0),
          height: _isExpanded ? 140 : 0,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: _bottomBorderRadius,
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: SingleChildScrollView(
              physics: _isExpanded
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: widget.categories.map((category) {
                    final isSelected = category.id == widget.selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      child: Material(
                        color: AppTheme.transparent,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: _verticalBorderRadius,
                        child: InkWell(
                          onTap: () {
                            widget.onCategorySelected(category.id);
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.transparent,
                              borderRadius: _verticalBorderRadius,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  getIconData(category.icon),
                                  size: 20,
                                  color: AppTheme.black,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ShaderMask(
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
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          color: AppTheme.black,
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
