import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../theme/app_theme.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return const SizedBox.shrink();

    return Container(
      height: 32,
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          // 应用名称
          const SizedBox(width: 16),
          Text(
            'Navi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          // 标题栏按钮（最小化、最大化、关闭）
          Expanded(
            child: WindowCaption(
              brightness: Brightness.light,
              backgroundColor: AppTheme.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
