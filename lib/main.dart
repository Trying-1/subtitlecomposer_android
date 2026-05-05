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

import 'services/project_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProjectService.init();
  await Hive.openBox('asset_box');
  await Hive.openBox('font_box');
  await Hive.openBox('settings_box');
  
  final fontProvider = FontProvider();
  final assetProvider = AssetProvider();
  
  await fontProvider.init();
  await assetProvider.init();

  final bool onboardingShown = Hive.box('settings_box').get('onboarding_shown', defaultValue: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => assetProvider),
        ChangeNotifierProvider(create: (_) => fontProvider),
      ],
      child: TypographyEditorApp(showOnboarding: !onboardingShown),
    ),
  );
}

class TypographyEditorApp extends StatelessWidget {
  final bool showOnboarding;
  const TypographyEditorApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Typo Edit',
      theme: ThemeConfig.theme,
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
