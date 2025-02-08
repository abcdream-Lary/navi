import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/website_provider.dart';

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
                builder: (context) => AlertDialog(
                  title: const Text('需要存储权限'),
                  content: const Text('应用需要存储权限来保存备份文件。请在设置中授予权限。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                      },
                      child: const Text('去设置'),
                    ),
                  ],
                ),
              );
            }
            return null;
          }
        }
      }

      // 让用户选择保存目录
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择备份文件保存位置',
        lockParentWindow: true,
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

      // 保存备份文件
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(backupData);
      await file.writeAsString(prettyJson);

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
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
