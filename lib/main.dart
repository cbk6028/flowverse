import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
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
