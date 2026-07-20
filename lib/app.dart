import 'package:doc_genie/config/app_config.dart';
import 'package:doc_genie/feature/auth/screen/login_screen.dart';
import 'package:doc_genie/services/session_manager.dart';
import 'package:doc_genie/theme/app_theme.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the tab/app returns to the foreground (e.g. after a browser
    // freeze/restore), re-check whether the session has expired in real time.
    if (state == AppLifecycleState.resumed) {
      SessionManager.instance.resumeCheck();
    }
  }

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
