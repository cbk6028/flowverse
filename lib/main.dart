import 'package:flov/data/repositories/archive/archive_repository.dart';
import 'package:flov/data/repositories/book/book_repository.dart';
import 'package:flov/ui/home/vm/dashboard_vm.dart';
import 'package:flov/ui/overlay_canvas/vm/drawing_vm.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flov/ui/tabs/widgets/tabs.dart';
import 'package:flov/ui/viewer/vm/reader_vm.dart';
import 'package:flov/ui/viewer/vm/tabs_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

// import 'theme/app_theme.dart';
import 'theme/theme.dart';

var themeType = 'light';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化window_manager
  await windowManager.ensureInitialized();

  // 配置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // 隐藏标题栏
  );

  // 应用窗口配置
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          // 提供 DashboardViewModel
          ChangeNotifierProvider<DashboardViewModel>(
            create: (_) => DashboardViewModel(bookRepository: BookRepository()),
          ),
          // ChangeNotifierProvider(create: (_) => DrawingViewModel()),
          // ChangeNotifierProvider(create: (_) => ReaderViewModel()),
          // // 添加标签页管理器
          // ChangeNotifierProvider(create: (_) => TabsViewModel()),
          // // 使用 value 构造函数共享上层的 DashboardViewModel
          // // ChangeNotifierProvider.value(value: dashboardVm),
          // ChangeNotifierProvider(
          //     create: (_) =>
          //         MarkerViewModel(archiveRepository: ArchiveRepository())),
        ],
        child: MaterialApp(
          theme:
              themeType == 'light' ? AppTheme.lightTheme : AppTheme.darkTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          home: const Tabs(),
        ));
  }
}
