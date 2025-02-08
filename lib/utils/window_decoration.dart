import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'dart:ui';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/website_provider.dart';

// 全局 Navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WindowDecoration {
  static Future<void> initialize() async {
    if (!Platform.isWindows) return;

    await windowManager.ensureInitialized();

    // 获取屏幕尺寸
    final screenSize = PlatformDispatcher.instance.views.first.physicalSize;
    final devicePixelRatio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    // 将物理像素转换为逻辑像素
    final logicalScreenSize = Size(
      screenSize.width / devicePixelRatio,
      screenSize.height / devicePixelRatio,
    );

    // 计算窗口尺寸（屏幕宽度的70%，保持3:2比例）
    final windowWidth = logicalScreenSize.width * 0.7;

    // 确保窗口尺寸在合理范围内
    final double finalWidth = windowWidth.clamp(900.0, 1200.0);
    final double finalHeight = (finalWidth * 2 / 3).clamp(600.0, 800.0);

    // 设置窗口属性
    await windowManager.setSize(Size(finalWidth, finalHeight));
    await windowManager.setMinimumSize(const Size(600, 400));
    await windowManager.setBackgroundColor(AppTheme.transparent);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setPreventClose(true);
    await windowManager.setHasShadow(true);
    await windowManager.center();

    // 添加窗口事件监听
    windowManager.addListener(WindowHandler());
  }

  // 在布局完成后调用此方法显示窗口
  static Future<void> showWindow(BuildContext context) async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('Error showing window: $e');
    }
  }

  // 显示退出确认对话框
  static Future<bool?> showExitConfirmDialog() async {
    if (navigatorKey.currentContext == null) return false;

    return showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false, // 防止点击外部关闭对话框
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        title: Text(
          '确认退出',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        content: Text(
          '确定要退出应用程序吗？',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textColor.withOpacity(0.5),
            ),
            child: Text(
              '取消',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textColor,
            ),
            child: Text(
              '确定',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowHandler extends WindowListener {
  bool _isExiting = false;

  @override
  void onWindowClose() async {
    // 防止重复触发退出流程
    if (_isExiting) return;
    _isExiting = true;

    try {
      bool? shouldClose = await WindowDecoration.showExitConfirmDialog();
      if (shouldClose == true) {
        // 立即隐藏窗口，提供更好的视觉反馈
        await windowManager.hide();

        // 在后台执行资源清理
        Future.wait<void>([
          _cleanupResources(),
        ]).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('清理超时，继续退出');
            return <void>[];
          },
        ).then((_) {
          // 清理完成后销毁窗口
          windowManager.destroy();
        }).catchError((e) {
          debugPrint('后台清理时发生错误: $e');
          windowManager.destroy();
        });
      } else {
        _isExiting = false;
      }
    } catch (e) {
      debugPrint('退出处理时发生错误: $e');
      await windowManager.destroy();
    }
  }

  Future<void> _cleanupResources() async {
    if (navigatorKey.currentContext == null) return;

    try {
      // 获取 WebsiteProvider 实例
      final websiteProvider = Provider.of<WebsiteProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      // 保存数据（如果需要）
      await websiteProvider.saveData();

      // 移除监听器
      windowManager.removeListener(this);
    } catch (e) {
      debugPrint('资源清理时发生错误: $e');
    }
  }
}
