import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

class WindowUtils {
  /// 获取当前显示器的缩放比例
  static double getScreenScaleFactor(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// 根据当前显示器缩放比例调整窗口大小
  static Future<void> adjustWindowSize(BuildContext context) async {
    if (!Platform.isWindows) return;

    final screenSize = MediaQuery.of(context).size;
    final scaleFactor = getScreenScaleFactor(context);

    // 计算理想的窗口大小（屏幕的80%）
    Size targetSize = Size(
      screenSize.width * 0.8,
      screenSize.height * 0.8,
    );

    // 确保窗口大小在合理范围内
    targetSize = Size(
      targetSize.width.clamp(640.0, screenSize.width),
      targetSize.height.clamp(360.0, screenSize.height),
    );

    // 应用DPI缩放
    final scaledSize = Size(
      targetSize.width / scaleFactor,
      targetSize.height / scaleFactor,
    );

    // 计算窗口居中位置
    final left = (screenSize.width - scaledSize.width) / 2;
    final top = (screenSize.height - scaledSize.height) / 2;

    // 一次性设置窗口的大小和位置，避免多次调整
    await windowManager.setBounds(
      Rect.fromLTWH(left, top, scaledSize.width, scaledSize.height),
      animate: true,
    );
  }

  /// 监听窗口大小变化
  static void addWindowListener(WindowListener listener) {
    if (Platform.isWindows) {
      windowManager.addListener(listener);
    }
  }

  /// 移除窗口监听
  static void removeWindowListener(WindowListener listener) {
    if (Platform.isWindows) {
      windowManager.removeListener(listener);
    }
  }
}
