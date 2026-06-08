import 'package:flutter/material.dart';

import 'core/state/app_controller.dart';
import 'core/state/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class DegerliYuvamApp extends StatelessWidget {
  const DegerliYuvamApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DegerliYuvam',
        theme: buildAppTheme(),
        home: const MainShell(),
      ),
    );
  }
}
