import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/editor_provider.dart';
import 'screens/editor_screen.dart';
import 'utils/theme_config.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'providers/asset_provider.dart';
import 'providers/font_provider.dart';

import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

import 'services/project_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProjectService.init();
  await Hive.openBox('asset_box');
  await Hive.openBox('font_box');
  await Hive.openBox('settings_box');
  await Hive.openBox('project_box');
  
  final fontProvider = FontProvider();
  final assetProvider = AssetProvider();
  
  await fontProvider.init();
  await assetProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => assetProvider),
        ChangeNotifierProvider(create: (_) => fontProvider),
      ],
      child: const TypographyEditorApp(),
    ),
  );
}

class TypographyEditorApp extends StatelessWidget {
  const TypographyEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Typo Edit',
      theme: ThemeConfig.theme,
      home: const SplashScreen(),
    );
  }
}
