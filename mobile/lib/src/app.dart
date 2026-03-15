import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/root_gate.dart';

class WoodGuardApp extends StatelessWidget {
  const WoodGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodGuard Mobile',
      debugShowCheckedModeBanner: false,
      theme: buildWoodGuardTheme(),
      home: const RootGate(),
    );
  }
}
