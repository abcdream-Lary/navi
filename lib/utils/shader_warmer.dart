import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

/// 着色器预热管理器
class ShaderWarmer {
  /// 预热着色器
  static Future<void> warmupShaders() async {
    try {
      // 对于 Impeller，我们不需要预编译的着色器缓存
      // 相反，我们可以预热一些常用的渲染操作
      await _warmupCommonOperations();
      debugPrint('着色器预热完成');
    } catch (e) {
      debugPrint('着色器预热失败: $e');
    }
  }

  /// 预热常用的渲染操作
  static Future<void> _warmupCommonOperations() async {
    // 创建一个离屏的画布来预热常用的渲染操作
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 预热基本形状绘制
    final paint = Paint()
      ..color = AppTheme.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // 矩形
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);

    // 圆形
    canvas.drawCircle(const Offset(50, 50), 25, paint);

    // 路径
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(100, 100)
      ..close();
    canvas.drawPath(path, paint);

    // 添加阴影效果
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);

    // 渐变
    final gradient = LinearGradient(
      colors: [AppTheme.black, AppTheme.errorColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), gradientPaint);

    // 完成记录
    final picture = recorder.endRecording();
    await picture.toImage(100, 100);
  }

  /// 收集着色器（仅在开发时使用）
  static Future<void> collectShaders() async {
    // 注意：这个方法只在开发时使用
    // 使用 Flutter 命令收集着色器：
    // flutter run --profile --cache-sksl
    // 然后触发所有动画和转换效果
    // 最后按 M 键保存着色器缓存
    debugPrint('请按照以下步骤收集着色器：');
    debugPrint('1. 使用命令：flutter run --profile --cache-sksl');
    debugPrint('2. 在应用中触发所有动画和转换效果');
    debugPrint('3. 在控制台按 M 键保存着色器缓存');
    debugPrint(
        '4. 将生成的 flutter_01.sksl.json 文件复制到 assets/shaders/ 目录下并重命名为 shader_cache.json');
  }
}
