import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
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

      // 定义文件类型
      final XTypeGroup jsonTypeGroup = XTypeGroup(
        label: 'JSON文件',
        extensions: ['json'],
      );

      // 让用户选择保存位置和文件名
      final FileSaveLocation? saveLocation = await getSaveLocation(
        suggestedName: defaultFileName,
        acceptedTypeGroups: [jsonTypeGroup],
        initialDirectory: downloadDir?.path,
      );

      if (saveLocation == null) {
        return null; // 用户取消了选择
      }

      // 获取文件路径
      final String outputFile = saveLocation.path;
      
      // 确保文件扩展名为 .json
      String finalOutputFile = outputFile;
      if (!finalOutputFile.toLowerCase().endsWith('.json')) {
        finalOutputFile = '$finalOutputFile.json';
      }

      // 保存备份文件 - 确保使用UTF-8编码
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(backupData);
      
      final file = File(finalOutputFile);
      await file.writeAsString(prettyJson, encoding: utf8);

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
