import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/editor_provider.dart';
import 'screens/editor_screen.dart';
import 'utils/theme_config.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => EditorProvider(),
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
