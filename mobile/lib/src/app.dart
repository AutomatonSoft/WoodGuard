import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/app_view_controller.dart';
import 'core/app_copy.dart';
import 'core/theme.dart';
import 'screens/root_gate.dart';

class WoodGuardApp extends StatelessWidget {
  const WoodGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewController>(
      builder: (context, view, _) {
        return MaterialApp(
          title: 'WoodGuard Mobile',
          debugShowCheckedModeBanner: false,
          theme: buildWoodGuardTheme(Brightness.light),
          darkTheme: buildWoodGuardTheme(Brightness.dark),
          themeMode: view.themeMode,
          themeAnimationCurve: Curves.easeOutCubic,
          themeAnimationDuration: const Duration(milliseconds: 320),
          locale: view.locale.locale,
          supportedLocales: supportedMaterialLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RootGate(),
        );
      },
    );
  }
}
