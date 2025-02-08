import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  final Duration minimumDuration;
  final VoidCallback? onInitializationComplete;
  final Stream<double>? loadingProgress;

  const SplashScreen({
    Key? key,
    required this.child,
    this.minimumDuration = const Duration(seconds: 2),
    this.onInitializationComplete,
    this.loadingProgress,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _controller;
  double _progress = 0.5;
  bool _minDurationCompleted = false;
  bool _loadingCompleted = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  void _checkCompletion() async {
    if (_minDurationCompleted && _loadingCompleted && mounted) {
      // 开始淡出动画
      await _fadeController.animateTo(0.0,
          duration: const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onInitializationComplete?.call();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      value: 0.5,
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      value: 1.0,
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // 监听加载进度
    widget.loadingProgress?.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = 0.5 + (progress * 0.5);
        });
        _controller.animateTo(_progress);

        if (progress >= 1.0) {
          _loadingCompleted = true;
          _checkCompletion();
        }
      }
    });

    // 最小持续时间
    Future.delayed(widget.minimumDuration, () {
      if (mounted) {
        _minDurationCompleted = true;
        _checkCompletion();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Stack(
        children: [
          // 主页面始终在底部
          widget.child,
          // 启动页面在顶部，随着加载完成逐渐消失
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: AppTheme.backgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: _controller,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return widget.child;
  }
}
