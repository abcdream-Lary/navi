import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/icon_data.dart';

class IconSelector extends StatefulWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;
  final bool isMobile;

  const IconSelector({
    Key? key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  late List<Widget> _preloadedIcons;

  @override
  void initState() {
    super.initState();
    // 预加载所有图标
    _preloadedIcons = iconMap.keys.map((iconName) {
      return _buildIconWidget(iconName);
    }).toList();
  }

  Widget _buildIconWidget(String iconName) {
    final isSelected = widget.selectedIcon == iconName;
    return Material(
      color: AppTheme.transparent,
      child: Container(
        width: widget.isMobile ? 44 : 36,
        height: widget.isMobile ? 44 : 36,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.black : AppTheme.transparent,
          borderRadius: AppTheme.smoothBorderRadius,
          border: Border.all(
            color: isSelected ? AppTheme.black : AppTheme.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(
          getIconData(iconName),
          size: widget.isMobile ? 26 : 22,
          color: isSelected ? AppTheme.white : AppTheme.textColor,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(IconSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的图标改变时，更新预加载的图标
    if (oldWidget.selectedIcon != widget.selectedIcon) {
      _preloadedIcons = iconMap.keys.map((iconName) {
        return _buildIconWidget(iconName);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.smoothBorderRadius,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: AppTheme.smoothBorderRadius,
          ),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 8 : 2,
              vertical: widget.isMobile ? 8 : 2,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isMobile ? 6 : 10,
              mainAxisSpacing: widget.isMobile ? 8 : 0,
              crossAxisSpacing: widget.isMobile ? 8 : 0,
              childAspectRatio: 1,
            ),
            itemCount: _preloadedIcons.length,
            itemBuilder: (context, index) {
              final iconName = iconMap.keys.elementAt(index);
              return Material(
                color: AppTheme.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: AppTheme.smoothBorderRadius,
                child: InkWell(
                  onTap: () => widget.onIconSelected(iconName),
                  child: _preloadedIcons[index],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
