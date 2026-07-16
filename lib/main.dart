import 'package:doc_genie/app.dart';
import 'package:doc_genie/common/app_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppClient.instance.init();
  runApp(const ProviderScope(child: App()));
}
