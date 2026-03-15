import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _apiController;
  String? _message;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSessionController>();
    _usernameController = TextEditingController(text: 'admin');
    _passwordController = TextEditingController(text: 'woodguard123');
    _apiController = TextEditingController(text: session.apiBaseUrl);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final session = context.read<AppSessionController>();
    FocusScope.of(context).unfocus();
    setState(() => _message = null);

    try {
      await session.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        apiBaseUrl: _apiController.text,
      );
    } on ApiException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Sign-in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppSessionController>(
        builder: (context, session, _) {
          return WoodGuardSurface(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'WoodGuard Mobile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Field dossier access rebuilt on Flutter for the current '
                    'FastAPI workspace.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: WoodGuardColors.pine,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const WoodCard(
                    tint: Color(0xFFDDE9E0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Built for the live API contract',
                          style: TextStyle(
                            color: WoodGuardColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This client keeps JWT login, refresh rotation, '
                          'dashboard metrics, invoice queue, dossier editing, '
                          'geolocation, evidence upload and Warehub sync.',
                          style: TextStyle(
                            color: WoodGuardColors.forest,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  WoodCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _apiController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'API Base URL',
                            hintText: 'http://192.168.x.x:8000/api/v1',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _usernameController,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Username or Email',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _message!,
                            style: const TextStyle(
                              color: WoodGuardColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: session.signingIn ? null : _handleSignIn,
                            child: Text(
                              session.signingIn ? 'Signing in...' : 'Sign In',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Android emulator: `http://10.0.2.2:8000/api/v1`\n'
                          'iOS simulator: `http://127.0.0.1:8000/api/v1`\n'
                          'Physical device: use your LAN IP instead of localhost.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: WoodGuardColors.pine),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
