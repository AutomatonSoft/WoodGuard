import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../widgets/app_widgets.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSessionController>(
      builder: (context, session, _) {
        if (!session.hydrated) {
          return const Scaffold(
            body: WoodGuardSurface(
              child: BusyState(label: 'Restoring secure mobile session...'),
            ),
          );
        }

        if (!session.isAuthenticated) {
          return const LoginScreen();
        }

        return const HomeShell();
      },
    );
  }
}
