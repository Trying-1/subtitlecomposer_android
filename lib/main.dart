import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/editor_provider.dart';
import 'screens/editor_screen.dart';
import 'utils/theme_config.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'providers/asset_provider.dart';
import 'providers/font_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('project_box');
  await Hive.openBox('asset_box');
  await Hive.openBox('font_box');
  
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
      debugShowCheckedModeBanner: false,
      title: 'Typography Editor',
      theme: ThemeConfig.theme,
      home: const EditorScreen(),
    );
  }
}
