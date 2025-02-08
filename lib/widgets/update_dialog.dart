import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final String updateContent;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.updateContent,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onCancel();
        return true;
      },
      child: Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.smoothBorderRadius,
        ),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和版本信息
              Row(
                children: [
                  Icon(
                    TablerIcons.arrow_big_up_lines,
                    size: 24,
                    color: AppTheme.black.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '发现新版本',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentVersion → $newVersion',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 更新内容
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: AppTheme.smoothBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '更新内容',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 160,
                      ),
                      child: ShaderMask(
                        shaderCallback: (Rect rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.black,
                              AppTheme.black,
                              AppTheme.black.withOpacity(0.1),
                            ],
                            stops: const [0.0, 0.85, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              updateContent,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: AppTheme.black.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(const Size(0, 36)),
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
                      overlayColor: MaterialStateProperty.all(
                        AppTheme.black.withOpacity(0.05),
                      ),
                    ),
                    child: Text(
                      '稍后再说',
                      style: TextStyle(
                        color: AppTheme.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onUpdate,
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(const Size(0, 36)),
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
                      overlayColor: MaterialStateProperty.all(
                        AppTheme.black.withOpacity(0.05),
                      ),
                    ),
                    icon: Icon(
                      TablerIcons.external_link,
                      size: 18,
                      color: AppTheme.black,
                    ),
                    label: Text(
                      '前往下载',
                      style: TextStyle(
                        color: AppTheme.black,
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
}
