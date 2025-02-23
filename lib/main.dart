import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:window_manager/window_manager.dart';

import 'ui/dashboard/widgets/dashboard_screen.dart';

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
    return const CupertinoApp(
      theme: CupertinoThemeData(),
      localizationsDelegates: [
        // SelectionArea 需要
        GlobalMaterialLocalizations.delegate,
      ],
      home: DashboardScreen(),
    );
  }
}
