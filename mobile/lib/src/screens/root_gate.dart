import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
import '../widgets/app_widgets.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSessionController, AppViewController>(
      builder: (context, session, view, _) {
        final copy = view.copy;
        late final Widget child;
        if (!session.hydrated || !view.hydrated) {
          child = Scaffold(
            key: const ValueKey('booting'),
            body: WoodGuardSurface(
              child: BusyState(label: copy.restoringSession),
            ),
          );
        } else if (!session.isAuthenticated) {
          child = const LoginScreen(key: ValueKey('login'));
        } else {
          child = const HomeShell(key: ValueKey('home'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [...previousChildren, ?currentChild],
            );
          },
          transitionBuilder: (child, animation) {
            final offset =
                Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: child,
        );
      },
    );
  }
}
