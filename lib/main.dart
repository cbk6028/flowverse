import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';


import 'screens/dashboard_screen.dart';

void main() {
  // ciyueMain();
  runApp(const MyApp());
  // main();
  //   windowManager.waitUntilReadyToShow().then((_) async{
  //     await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  // });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: const CupertinoThemeData(),
      localizationsDelegates: const [
        // SelectionArea 需要
        GlobalMaterialLocalizations.delegate,
      ],
      home: DashboardScreen(),
    );
  }
}
