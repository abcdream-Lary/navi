import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_info.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  static const String _owner = 'abcdream-Lary'; // GitHub 用户名
  static const String _repo = 'navi'; // 仓库名称
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';
  static const String _releaseUrl =
      'https://github.com/$_owner/$_repo/releases/latest';

  static PackageInfo? _packageInfo;
  static DateTime? _lastCheckTime;
  static VersionInfo? _cachedVersionInfo;

  // 初始化
  static Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('初始化版本信息失败: $e');
    }
  }

  // 检查更新并显示对话框
  static Future<void> checkUpdateAndShowDialog(BuildContext context) async {
    try {
      final (hasUpdate, versionInfo) = await checkUpdate();
      if (hasUpdate && versionInfo != null && context.mounted) {
        // 显示更新对话框
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => UpdateDialog(
            currentVersion: _packageInfo?.version ?? '0.0.0',
            newVersion: versionInfo.version,
            updateContent: versionInfo.releaseNotes,
            onUpdate: () async {
              final url = Uri.parse(
                  versionInfo.downloadUrls['releaseUrl'] ?? _releaseUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            onCancel: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  // 检查更新
  static Future<(bool hasUpdate, VersionInfo? versionInfo)>
      checkUpdate() async {
    try {
      // 确保已初始化
      if (_packageInfo == null) {
        await initialize();
      }

      // 获取当前版本
      final currentVersion = _packageInfo?.version ?? '0.0.0';
      debugPrint('当前版本: $currentVersion');

      // 检查缓存
      final now = DateTime.now();
      if (_lastCheckTime != null &&
          _cachedVersionInfo != null &&
          now.difference(_lastCheckTime!) < const Duration(minutes: 20)) {
        debugPrint('使用缓存的版本信息');
        final hasUpdate =
            _compareVersions(currentVersion, _cachedVersionInfo!.version);
        return (hasUpdate, hasUpdate ? _cachedVersionInfo : null);
      }

      // 获取最新版本信息
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Navi-App',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('获取版本信息失败: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);
      final latestVersion = VersionInfo.fromJson(json);
      debugPrint('最新版本: ${latestVersion.version}');

      // 比较版本号
      final hasUpdate = _compareVersions(currentVersion, latestVersion.version);
      debugPrint('是否有更新: $hasUpdate');

      // 更新缓存
      _cachedVersionInfo = latestVersion;
      _lastCheckTime = now;

      return (hasUpdate, hasUpdate ? latestVersion : null);
    } catch (e) {
      throw Exception('检查更新失败: $e');
    }
  }

  // 比较版本号
  static bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> latest = latestVersion.split('.').map(int.parse).toList();

      debugPrint('版本比较: $current vs $latest');

      // 确保两个列表长度相同
      while (current.length < latest.length) current.add(0);
      while (latest.length < current.length) latest.add(0);

      // 逐位比较
      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('版本比较出错: $e');
      return false;
    }
  }

  // 获取平台
  static String getPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    throw Exception('不支持的平台');
  }

  // 获取下载链接
  static String? getDownloadUrl(VersionInfo versionInfo) {
    final platform = getPlatform();
    return versionInfo.downloadUrls[platform];
  }

  // 获取 Release 页面 URL
  static String getReleaseUrl() {
    return _releaseUrl;
  }
}
