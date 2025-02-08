import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/website_provider.dart';

/// 桌面端的备份恢复工具类
class DesktopBackupRestoreUtils {
  /// 处理备份功能
  static Future<String?> handleBackup(
    BuildContext context,
    WebsiteProvider provider,
  ) async {
    try {
      // 准备备份数据
      final backupData = {
        'categories': provider.categories.map((c) => c.toJson()).toList(),
        'websites': provider.websites.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      // 获取下载目录
      final downloadDir = await getDownloadsDirectory();

      // 生成默认文件名
      final defaultFileName =
          'navi_backup_${DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '')}.json';

      // 让用户选择保存位置和文件名
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '选择备份文件保存位置',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        lockParentWindow: true,
        initialDirectory: downloadDir?.path,
      );

      if (outputFile == null) {
        return null; // 用户取消了选择
      }

      // 确保文件扩展名为 .json
      if (!outputFile.toLowerCase().endsWith('.json')) {
        outputFile = '$outputFile.json';
      }

      // 保存备份文件
      final file = File(outputFile);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(backupData);
      await file.writeAsString(prettyJson);

      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// 处理恢复功能
  static Future<bool> handleRestore(
    BuildContext context,
    WebsiteProvider provider,
  ) async {
    try {
      // 获取下载目录
      final downloadDir = await getDownloadsDirectory();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择要恢复的备份文件',
        lockParentWindow: true,
        initialDirectory: downloadDir?.path,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        // 验证备份文件格式
        if (!data.containsKey('categories') || !data.containsKey('websites')) {
          throw '无效的备份文件格式';
        }

        // 验证版本兼容性
        if (data.containsKey('version') && data['version'] != '1.0.0') {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('版本不匹配'),
              content: const Text('备份文件版本与当前应用版本不匹配，继续恢复可能会导致数据不完整。是否继续？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('继续'),
                ),
              ],
            ),
          );
          if (shouldProceed != true) {
            return false;
          }
        }

        await provider.restoreFromBackup(data);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
