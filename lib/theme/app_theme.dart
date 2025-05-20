import 'package:flutter/material.dart';

/// 应用主题
class AppTheme {
  // 全局颜色定义
  static const black = Color(0xFF000000); // 主要文字、图标、选中背景
  static const white = Color(0xFFFFFFFF); // 背景色、反色文字
  static const grey = Color(0xFFF2F2F2); // 次要背景、卡片背景
  static const Color errorColor = Color(0xFFE53935);

  // 扩展颜色定义
  static const transparent = Colors.transparent;
  static const success = Color(0xFF4CAF50); // 成功状态
  static const warning = Color(0xFFFFA000); // 警告状态

  // 灰度色阶
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);

  // 状态颜色的透明度变体
  static Color get errorLight => errorColor.withOpacity(0.1);
  static Color get successLight => success.withOpacity(0.1);
  static Color get warningLight => warning.withOpacity(0.1);

  // 全局圆角定义
  static const radius = 13.0; // 所有组件统一圆角
  static BorderRadius get smoothBorderRadius =>
      BorderRadius.circular(radius); // iOS风格平滑圆角

  // 功能色映射
  static const backgroundColor = white; // 页面背景
  static const sidebarColor = grey; // 侧边栏背景
  static const cardColor = grey; // 卡片背景
  static const textColor = black; // 文字颜色
  static const secondaryTextColor = black; // 次要文字颜色

  // 全局字体
  static const fontFamily = 'GenSenRounded';

  // 全局主题定义
  static final ThemeData lightTheme = ThemeData(
    primaryColor: black,
    scaffoldBackgroundColor: white,
    fontFamily: fontFamily,
    useMaterial3: true,
    // 添加对话框主题
    dialogTheme: DialogTheme(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: smoothBorderRadius,
      ),
    ),
    // 添加全局圆角主题
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: smoothBorderRadius,
      ),
    ),
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: black,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: smoothBorderRadius,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(black),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: smoothBorderRadius,
          ),
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return black.withOpacity(0.1);
            }
            if (states.contains(MaterialState.hovered)) {
              return black.withOpacity(0.05);
            }
            return Colors.transparent;
          },
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(black),
        side: MaterialStateProperty.all(
          BorderSide(color: black.withOpacity(0.2)),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: smoothBorderRadius,
          ),
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return black.withOpacity(0.1);
            }
            if (states.contains(MaterialState.hovered)) {
              return black.withOpacity(0.05);
            }
            return Colors.transparent;
          },
        ),
      ),
    ),
    // 输入框主题
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: smoothBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: smoothBorderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: smoothBorderRadius,
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: grey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    // 文字样式定义
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        // 大标题文字样式
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: black,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        // 主要文字样式
        fontSize: 14,
        color: black,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        // 次要文字样式
        fontSize: 13,
        color: black,
        fontFamily: fontFamily,
      ),
    ),
    // 图标主题
    iconTheme: const IconThemeData(
      color: black,
      size: 18,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      elevation: 0,
      iconTheme: const IconThemeData(color: black),
      titleTextStyle: const TextStyle(
        color: black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
    ),
    // 添加抽屉主题
    drawerTheme: DrawerThemeData(
      backgroundColor: white,
      scrimColor: black.withOpacity(0.3),
    ),
    // 添加页面切换动画主题
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
