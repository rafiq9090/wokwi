import 'package:flutter/material.dart';

import 'views/monitor_page.dart';

class FamilyMonitorApp extends StatelessWidget {
  const FamilyMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF12212B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Care Circle',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6B67),
          brightness: Brightness.light,
        ).copyWith(surface: const Color(0xFFFCFAF5), onSurface: ink),
      ),
      home: const MonitorPage(),
    );
  }
}
