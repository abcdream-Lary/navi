import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static PackageInfo? _packageInfo;

  // 初始化
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  // 获取版本号
  static String getVersionNumber() {
    return _packageInfo?.version ?? '0.1.5'; // 如果未初始化，返回默认版本
  }

  // 获取构建号
  static String getBuildNumber() {
    return _packageInfo?.buildNumber ?? '2'; // 如果未初始化，返回默认构建号
  }

  // 获取应用名称
  static String getAppName() {
    return _packageInfo?.appName ?? 'Navi';
  }

  // 获取包名
  static String getPackageName() {
    return _packageInfo?.packageName ?? 'com.navi.app';
  }
}
