import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/controllers/app_session_controller.dart';
import 'src/controllers/app_view_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppSessionController()..hydrate(),
        ),
        ChangeNotifierProvider(create: (_) => AppViewController()..hydrate()),
      ],
      child: const WoodGuardApp(),
    ),
  );
}
