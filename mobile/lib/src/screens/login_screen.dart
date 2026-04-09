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
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<AppSessionController>(
        builder: (context, session, _) {
          return WoodGuardSurface(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;

                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1220),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: WoodGuardColors.appSurface,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.26),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x42111F46),
                              blurRadius: 54,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: isWide ? 11 : 0,
                              child: _ShowcasePanel(
                                minHeight: isWide ? 680 : 420,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 14 : 0,
                              height: isWide ? 0 : 14,
                            ),
                            Expanded(
                              flex: isWide ? 9 : 0,
                              child: _LoginPanel(
                                session: session,
                                message: _message,
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                apiController: _apiController,
                                onSubmit: _handleSignIn,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ShowcasePanel extends StatelessWidget {
  const _ShowcasePanel({required this.minHeight});

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = const [
      ('Invoices', '270+'),
      ('Coverage Avg', '98%'),
      ('High Risk', '12'),
    ];

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF789AE1), Color(0xFF3456A4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Text(
                'DUE DILIGENCE INDEX',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38060C18),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x7AFFD699), Color(0x5278451C)],
              ),
            ),
            child: Center(
              child: Text(
                'WG',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Woodguard',
            style: theme.textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Mobile access to the same compliance workspace, visual hierarchy, and field workflow used on the frontend.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Risk review, evidence upload, and live API session handling stay aligned with the web app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stats
                .map(
                  (item) => _ShowcaseStatCard(label: item.$1, value: item.$2),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseStatCard extends StatelessWidget {
  const _ShowcaseStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.session,
    required this.message,
    required this.usernameController,
    required this.passwordController,
    required this.apiController,
    required this.onSubmit,
    required this.theme,
  });

  final AppSessionController session;
  final String? message;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController apiController;
  final Future<void> Function() onSubmit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return WoodCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WoodGuardColors.ember.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2F67FF), Color(0xFF234FCA)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'WG',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTH ACCESS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: WoodGuardColors.ember,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to the mobile workspace',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Same backend contract, same operator session, adapted for handheld review.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: apiController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://10.0.2.2:8000/api/v1',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: usernameController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (message != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: WoodGuardColors.danger.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: WoodGuardColors.danger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: WoodGuardColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x382A50A8),
                          blurRadius: 30,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: session.signingIn ? null : onSubmit,
                      child: Text(
                        session.signingIn ? 'Signing in...' : 'Sign In',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Default admin credentials are prefilled for local workspace testing.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: WoodGuardColors.pine,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WoodGuardColors.panelAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: WoodGuardColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIMULATOR NOTES',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Android emulator: http://10.0.2.2:8000/api/v1\n'
                        'iOS simulator: http://127.0.0.1:8000/api/v1\n\n'
                        'If ADB returns a null value, reconnect the device once by cable and re-enable wireless debugging.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
