import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/device_type.dart';

/// 响应式布局管理器
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget desktopLayout;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    required this.desktopLayout,
  }) : super(key: key);

  /// 获取设备类型
  static DeviceType getDeviceType(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return DeviceType.mobile;
    }
    return DeviceType.desktop;
  }

  /// 判断是否为移动设备
  static bool isMobile(BuildContext context) {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 判断是否为平板设备
  static bool isTablet(BuildContext context) {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 判断是否为桌面设备
  static bool isDesktop(BuildContext context) {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 判断是否使用桌面端UI
  static bool useDesktopUI(BuildContext context) {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return mobileLayout;
    }
    return desktopLayout;
  }
}
