import 'package:flutter/material.dart';

class PreloadManager extends StatelessWidget {
  final Widget child;
  final List<Widget> preloadWidgets;

  const PreloadManager({
    Key? key,
    required this.child,
    required this.preloadWidgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // 使用 Offstage 预加载其他页面
        if (preloadWidgets.isNotEmpty)
          Offstage(
            offstage: true,
            child: Stack(children: preloadWidgets),
          ),
      ],
    );
  }
}
