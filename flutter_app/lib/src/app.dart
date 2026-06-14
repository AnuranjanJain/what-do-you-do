import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'shell.dart';
import 'theme.dart';

class WhatDoYouDoApp extends StatefulWidget {
  const WhatDoYouDoApp({super.key});

  @override
  State<WhatDoYouDoApp> createState() => _WhatDoYouDoAppState();
}

class _WhatDoYouDoAppState extends State<WhatDoYouDoApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'What Do You Do',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: AppShell(controller: controller),
        );
      },
    );
  }
}
