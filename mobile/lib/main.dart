import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/controllers/app_session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSessionController()..hydrate(),
      child: const WoodGuardApp(),
    ),
  );
}
