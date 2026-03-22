import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
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
    final copy = context.read<AppViewController>().copy;
    FocusScope.of(context).unfocus();
    setState(() => _message = null);

    try {
      await session.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        apiBaseUrl: _apiController.text,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _message = copy.signInFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.watch<AppViewController>().copy;
    final session = context.watch<AppSessionController>();

    return Scaffold(
      body: WoodGuardSurface(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MotionReveal(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppLanguageSwitcher(),
                ),
              ),
              const SizedBox(height: 12),
              const MotionReveal(
                delay: Duration(milliseconds: 60),
                child: AppThemeModeToggle(),
              ),
              const SizedBox(height: 28),
              MotionReveal(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  children: [
                    const GlassIconBubble(icon: Icons.forest_rounded, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'WoodGuard Mobile',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              MotionReveal(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  copy.authTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              MotionReveal(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  copy.authDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const MotionReveal(
                delay: Duration(milliseconds: 280),
                child: WoodCard(
                  tint: Color(0x26FFFFFF),
                  child: _LoginFeatureCard(),
                ),
              ),
              const SizedBox(height: 22),
              MotionReveal(
                delay: const Duration(milliseconds: 360),
                child: WoodCard(
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _apiController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: copy.apiBaseUrl,
                            hintText: copy.apiHint,
                            prefixIcon: const Icon(Icons.cloud_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _usernameController,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: copy.usernameOrEmail,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSignIn(),
                          decoration: InputDecoration(
                            labelText: copy.password,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _message == null
                              ? const SizedBox.shrink()
                              : InlineStatusBanner(
                                  key: ValueKey(_message),
                                  message: _message!,
                                  isError: true,
                                ),
                        ),
                        if (_message != null) const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: session.signingIn ? null : _handleSignIn,
                            child: Text(
                              session.signingIn ? copy.signingIn : copy.signIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: WoodGuardColors.sand.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            copy.defaultAdminNote,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: WoodGuardColors.pine,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '${copy.androidHint}\n${copy.iosHint}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: WoodGuardColors.pine),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginFeatureCard extends StatelessWidget {
  const _LoginFeatureCard();

  @override
  Widget build(BuildContext context) {
    final copy = context.watch<AppViewController>().copy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const GlassIconBubble(icon: Icons.bolt_rounded, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                copy.indexEyebrow,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          copy.apiConnectivityNote,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LoginTag(
              icon: Icons.dashboard_customize_rounded,
              label: copy.overviewTab,
            ),
            _LoginTag(icon: Icons.attach_file_rounded, label: copy.evidenceTab),
            _LoginTag(icon: Icons.analytics_rounded, label: copy.analyticsTab),
          ],
        ),
      ],
    );
  }
}

class _LoginTag extends StatelessWidget {
  const _LoginTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
