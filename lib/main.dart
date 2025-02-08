import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'providers/website_provider.dart';
import 'utils/window_decoration.dart';
import 'widgets/custom_title_bar.dart';
import 'utils/shader_warmer.dart';
import 'widgets/splash_screen.dart';
import 'dart:async';
import 'services/update_service.dart';
import 'constants/app_version.dart';

// 定义设备类型枚举
enum DeviceType {
  mobile, // 手机
  tablet, // 平板
  desktop, // 桌面
}

// 获取设备类型
DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  // 先判断是否是桌面操作系统
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return DeviceType.desktop;
  }

  // 移动设备根据宽度判断是平板还是手机
  if (width >= 600) {
    // Material Design 断点
    return DeviceType.tablet;
  }

  return DeviceType.mobile;
}

// 判断是否使用桌面端UI
bool useDesktopUI(DeviceType deviceType) {
  return deviceType == DeviceType.desktop || deviceType == DeviceType.tablet;
}

// 判断是否使用移动端状态栏样式
bool useMobileStatusBar(DeviceType deviceType) {
  return deviceType == DeviceType.mobile || deviceType == DeviceType.tablet;
}

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 预热着色器
  await ShaderWarmer.warmupShaders();

  // 配置系统UI
  await _configureSystemUI();

  // 初始化更新服务
  await UpdateService.initialize();

  // 初始化版本信息
  await AppVersion.initialize();

  // 创建并预加载数据
  final websiteProvider = WebsiteProvider();
  await websiteProvider.preloadData();

  // 只在桌面平台初始化窗口管理器
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await WindowDecoration.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: websiteProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// 配置系统UI，包括状态栏和导航栏
Future<void> _configureSystemUI() async {
  // 设置应用程序支持的方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 为移动设备（手机和平板）设置状态栏样式
  if (Platform.isIOS || Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppTheme.transparent,
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool _isInitialized = false;
  final _loadingController = StreamController<double>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _loadingController.close();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    // 开始加载
    _loadingController.add(0.0);
    await Future.delayed(const Duration(milliseconds: 300));
    _loadingController.add(0.3);
    await Future.delayed(const Duration(milliseconds: 300));
    _loadingController.add(0.7);
    await Future.delayed(const Duration(milliseconds: 300));
    _loadingController.add(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final mainApp = MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Navi',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        Widget content = child ?? const SizedBox();
        final deviceType = getDeviceType(context);
        if (useDesktopUI(deviceType)) {
          if (deviceType == DeviceType.tablet) {
            final statusBarHeight = MediaQuery.of(context).padding.top;
            content = Container(
              color: AppTheme.backgroundColor,
              child: Column(
                children: [
                  SizedBox(height: statusBarHeight),
                  const CustomTitleBar(),
                  Expanded(child: content),
                ],
              ),
            );
          } else {
            content = Column(
              children: [
                const CustomTitleBar(),
                Expanded(child: content),
              ],
            );
          }
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
            padding: MediaQuery.of(context).padding,
          ),
          child: content,
        );
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const HomeScreen(),
            );
          case '/settings':
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          default:
            return null;
        }
      },
      initialRoute: '/',
    );

    if (!_isInitialized) {
      return MaterialApp(
        title: 'Navi',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          minimumDuration: const Duration(milliseconds: 1500),
          loadingProgress: _loadingController.stream,
          child: mainApp,
          onInitializationComplete: () {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          },
        ),
      );
    }

    return mainApp;
  }
}
