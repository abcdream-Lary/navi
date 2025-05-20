import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
  // 使用多个CDN源
  static const List<String> _apiUrls = [
    // 国内优先镜像
    'https://github.91chi.fun/https://raw.githubusercontent.com/$_owner/$_repo/main/version.json',
    'https://ghproxy.com/https://raw.githubusercontent.com/$_owner/$_repo/main/version.json',
    'https://mirror.ghproxy.com/https://raw.githubusercontent.com/$_owner/$_repo/main/version.json',
    'https://raw.kgithub.com/$_owner/$_repo/main/version.json',
    'https://raw.fastgit.org/$_owner/$_repo/main/version.json',
    // CDN源
    'https://cdn.jsdelivr.net/gh/$_owner/$_repo/version.json',
    'https://fastly.jsdelivr.net/gh/$_owner/$_repo/version.json',
    'https://gcore.jsdelivr.net/gh/$_owner/$_repo/version.json',
    // 原始地址(最后尝试)
    'https://raw.githubusercontent.com/$_owner/$_repo/main/version.json'
  ];
  
  // 简单版本文本文件源
  static const List<String> _versionTxtUrls = [
    // 国内优先镜像
    'https://github.91chi.fun/https://raw.githubusercontent.com/$_owner/$_repo/main/version.txt',
    'https://ghproxy.com/https://raw.githubusercontent.com/$_owner/$_repo/main/version.txt',
    'https://mirror.ghproxy.com/https://raw.githubusercontent.com/$_owner/$_repo/main/version.txt',
    'https://raw.kgithub.com/$_owner/$_repo/main/version.txt',
    'https://raw.fastgit.org/$_owner/$_repo/main/version.txt',
    // CDN源
    'https://cdn.jsdelivr.net/gh/$_owner/$_repo/version.txt',
    'https://fastly.jsdelivr.net/gh/$_owner/$_repo/version.txt',
    'https://gcore.jsdelivr.net/gh/$_owner/$_repo/version.txt',
    // 原始地址(最后尝试)
    'https://raw.githubusercontent.com/$_owner/$_repo/main/version.txt'
  ];
  
  static const String _releaseUrl =
      'https://github.com/$_owner/$_repo/releases/latest';

  static PackageInfo? _packageInfo;
  static int _currentApiIndex = 0;
  static Map<String, DateTime> _apiLastUsedTime = {};

  // 获取下一个可用的API URL
  static String _getNextApiUrl() {
    final now = DateTime.now();
    String? selectedUrl;

    // 尝试所有URL直到找到一个可用的
    for (int i = 0; i < _apiUrls.length; i++) {
      final url = _apiUrls[(_currentApiIndex + i) % _apiUrls.length];
      final lastUsed = _apiLastUsedTime[url];

      // 如果这个URL从未使用过或者距离上次使用已经超过5秒
      if (lastUsed == null || now.difference(lastUsed).inSeconds >= 5) {
        selectedUrl = url;
        _currentApiIndex = (_currentApiIndex + i + 1) % _apiUrls.length;
        _apiLastUsedTime[url] = now;
        break;
      }
    }

    // 如果所有URL都在冷却中，使用等待时间最长的那个
    if (selectedUrl == null) {
      selectedUrl = _apiUrls[_currentApiIndex];
      _apiLastUsedTime[selectedUrl] = now;
      _currentApiIndex = (_currentApiIndex + 1) % _apiUrls.length;
    }

    return selectedUrl;
  }

  // 初始化
  static Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _apiLastUsedTime.clear();
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

  // 从简单文本文件获取版本号
  static Future<String?> _fetchVersionNumberOnly() async {
    for (final url in _versionTxtUrls) {
      try {
        debugPrint('尝试从简单文本文件获取版本: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final version = response.body.trim();
          debugPrint('成功从文本文件获取版本: $version');
          return version;
        }
      } catch (e) {
        debugPrint('从文本文件获取版本失败: $e');
        continue;
      }
    }
    return null;
  }

  // 检查更新
  static Future<(bool hasUpdate, VersionInfo? versionInfo)>
      checkUpdate() async {
    try {
      // 确保已初始化
      if (_packageInfo == null) {
        debugPrint('PackageInfo 未初始化，正在初始化...');
        await initialize();
      }

      // 获取当前版本
      final currentVersion = _packageInfo?.version ?? '0.0.0';
      debugPrint('当前版本: $currentVersion');

      // 尝试获取更新信息
      Exception? lastError;
      final maxRetries = _apiUrls.length * 2; // 最多尝试次数
      int retryCount = 0;
      VersionInfo? latestVersionInfo;
      DateTime? latestTimestamp;

      while (retryCount < maxRetries) {
        try {
          final apiUrl = _getNextApiUrl();
          debugPrint('正在尝试从 $apiUrl 获取更新信息...');

          final response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Navi-App',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          ).timeout(
            const Duration(seconds: 5), // 缩短超时时间
            onTimeout: () {
              debugPrint('请求超时: $apiUrl');
              throw TimeoutException('网络请求超时，尝试其他源');
            },
          );

          debugPrint('响应状态码: ${response.statusCode}');

          if (response.statusCode == 200) {
            debugPrint('成功获取响应数据: ${response.body}');
            try {
              final json = jsonDecode(response.body);
              final versionInfo = VersionInfo.fromJson(json);
              debugPrint('解析的版本信息: $versionInfo');

              // 检查时间戳，保留时间戳最新的版本信息
              if (latestTimestamp == null ||
                  versionInfo.timestamp.isAfter(latestTimestamp)) {
                latestTimestamp = versionInfo.timestamp;
                latestVersionInfo = versionInfo;
                debugPrint('发现更新的版本信息，时间戳: ${versionInfo.timestamp}');
              }

              // 如果已经尝试了所有源，使用最新的版本信息进行比较
              if (retryCount >= _apiUrls.length - 1 &&
                  latestVersionInfo != null) {
                final hasUpdate =
                    _compareVersions(currentVersion, latestVersionInfo.version);
                debugPrint('版本比较结果: $hasUpdate');
                return (hasUpdate, hasUpdate ? latestVersionInfo : null);
              }
            } catch (e) {
              debugPrint('解析响应数据失败: $e');
              throw Exception('解析版本信息失败: $e');
            }
          } else if (response.statusCode == 403) {
            debugPrint('API 请求限制，等待后重试: $apiUrl');
            debugPrint('响应内容: ${response.body}');
            await Future.delayed(const Duration(seconds: 2));
            lastError = Exception('API 请求过于频繁，请稍后再试');
          } else {
            debugPrint('API请求失败，状态码: ${response.statusCode}');
            debugPrint('响应内容: ${response.body}');
            lastError = Exception('API返回错误: HTTP ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('请求失败: $e');
          if (e is SocketException) {
            debugPrint('网络错误详情: ${e.message}');
            debugPrint('地址: ${e.address}');
            debugPrint('端口: ${e.port}');
            debugPrint('操作系统错误码: ${e.osError}');
          }
          lastError = e is Exception ? e : Exception(e.toString());
        }

        retryCount++;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 如果JSON方式全部失败，尝试使用简单文本方式
      debugPrint('JSON方式检查更新失败，尝试简单文本方式...');
      final latestVersionText = await _fetchVersionNumberOnly();
      
      if (latestVersionText != null) {
        final hasUpdate = _compareVersions(currentVersion, latestVersionText);
        debugPrint('简单文本版本比较结果: $hasUpdate');
        
        if (hasUpdate) {
          // 创建一个简单的VersionInfo对象
          final simpleVersionInfo = VersionInfo(
            version: latestVersionText,
            releaseNotes: '有新版本可用: $latestVersionText',
            downloadUrls: {'releaseUrl': _releaseUrl},
            timestamp: DateTime.now(),
          );
          return (true, simpleVersionInfo);
        }
        return (false, null);
      }

      throw lastError ?? Exception('所有更新源都无法访问');
    } catch (e) {
      debugPrint('检查更新时发生错误: $e');
      if (e is SocketException) {
        throw Exception('网络连接失败，请检查网络设置或者尝试使用代理\n错误详情: ${e.message}');
      } else if (e is TimeoutException) {
        throw Exception('检查更新超时，请稍后重试\n错误详情: ${e.message}');
      } else {
        throw Exception('检查更新失败: ${e.toString()}');
      }
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
    if (Platform.isWindows) return 'windows_portable'; // 默认使用便携版，用户也可以在UI中选择安装版
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
