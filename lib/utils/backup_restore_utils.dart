import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/website_provider.dart';
import '../theme/app_theme.dart';

/// 移动设备（手机和平板）的备份恢复工具类
class BackupRestoreUtils {
  /// 处理备份功能
  static Future<String?> handleBackup(
    BuildContext context,
    WebsiteProvider provider, {
    bool showUI = true,
  }) async {
    try {
      // 检查并请求存储权限（仅在 Android 设备上）
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied || status.isRestricted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            if (context.mounted && showUI) {
              // 显示权限说明对话框
              await showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: AppTheme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.smoothBorderRadius,
                  ),
                  child: Container(
                    width: 320,
                    height: 160,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.smoothBorderRadius,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  color: AppTheme.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '需要存储权限',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '应用需要存储权限来保存备份文件，请在设置中授予权限。',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.black.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(
                                  AppTheme.black.withOpacity(0.5),
                                ),
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.hovered)) {
                                      return Colors.red.withOpacity(0.1);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: AppTheme.smoothBorderRadius,
                                  ),
                                ),
                              ),
                              child: const Text('取消'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await openAppSettings();
                              },
                              style: ButtonStyle(
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.hovered)) {
                                      return Colors.red.withOpacity(0.1);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: AppTheme.smoothBorderRadius,
                                  ),
                                ),
                              ),
                              child: Text(
                                '去设置',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return null;
          }
        }
      }

      // 让用户选择保存目录
      final String? selectedDirectory = await getDirectoryPath(
        confirmButtonText: '选择这个文件夹',
      );

      if (selectedDirectory == null) {
        return null; // 用户取消了选择
      }

      // 准备备份数据
      final backupData = {
        'categories': provider.categories.map((c) => c.toJson()).toList(),
        'websites': provider.websites.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      // 生成文件名
      final fileName =
          'navi_backup_${DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '')}.json';
      final file = File('$selectedDirectory/$fileName');

      // 保存备份文件 - 确保使用UTF-8编码
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(backupData);
      await file.writeAsString(prettyJson, encoding: utf8);

      return file.path;
    } catch (e) {
      if (context.mounted && showUI) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败：$e')),
        );
      }
      return null;
    }
  }

  /// 处理恢复功能
  static Future<bool> handleRestore(
    BuildContext context,
    WebsiteProvider provider, {
    bool showUI = true,
  }) async {
    try {
      // 定义允许的文件类型
      final XTypeGroup jsonTypeGroup = XTypeGroup(
        label: 'JSON文件',
        extensions: ['json'],
      );
      
      // 选择文件
      final XFile? xfile = await openFile(
        acceptedTypeGroups: [jsonTypeGroup],
      );

      if (xfile != null) {
        // 使用File类读取文件以确保正确处理编码
        final file = File(xfile.path);
        final content = await file.readAsString(encoding: utf8);
        
        final data = jsonDecode(content);

        if (!data.containsKey('categories') || !data.containsKey('websites')) {
          throw '无效的备份文件格式';
        }

        await provider.restoreFromBackup(data);

        if (context.mounted && showUI) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('恢复成功')),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      if (context.mounted && showUI) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
      return false;
    }
  }
}
