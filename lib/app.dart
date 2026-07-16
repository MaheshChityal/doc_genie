import 'package:doc_genie/config/app_config.dart';
import 'package:doc_genie/feature/auth/screen/login_screen.dart';
import 'package:doc_genie/theme/app_theme.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      navigatorKey: navigatorKey,
      home: const LoginScreen(),
    );
  }
}
