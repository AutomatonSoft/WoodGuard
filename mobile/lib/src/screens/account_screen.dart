import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.revision,
    required this.onDataChanged,
  });

  final int revision;
  final VoidCallback onDataChanged;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _apiController;
  String? _message;
  bool _isError = false;
  bool _syncing = false;
  bool _refreshingProfile = false;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(
      text: context.read<AppSessionController>().apiBaseUrl,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiController.text = context.read<AppSessionController>().apiBaseUrl;
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _saveApiUrl() async {
    final copy = context.read<AppViewController>().copy;
    try {
      await context.read<AppSessionController>().setApiBaseUrl(
        _apiController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = copy.apiBaseUrlSaved;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.message;
      });
    }
  }

  Future<void> _refreshProfile() async {
    final copy = context.read<AppViewController>().copy;
    setState(() {
      _refreshingProfile = true;
      _message = null;
      _isError = false;
    });

    try {
      final user = await context
          .read<AppSessionController>()
          .refreshCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() => _message = copy.profileRefreshed(user.username));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _refreshingProfile = false);
      }
    }
  }

  Future<void> _syncWarehub() async {
    final copy = context.read<AppViewController>().copy;
    setState(() {
      _syncing = true;
      _message = null;
      _isError = false;
    });

    try {
      final result = await context.read<AppSessionController>().syncWarehub();
      if (!mounted) {
        return;
      }
      widget.onDataChanged();
      setState(() {
        _message = copy.warehubSyncFinished(result.imported, result.updated);
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _signOut() {
    return context.read<AppSessionController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionController>();
    final view = context.watch<AppViewController>();
    final copy = view.copy;
    final user = session.currentUser;

    return Scaffold(
      body: WoodGuardSurface(
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SectionHeader(
                    eyebrow: copy.authEyebrow,
                    title: copy.accountConsoleTitle,
                    subtitle: copy.accountConsoleSubtitle,
                  ),
                ),
                const SizedBox(width: 12),
                const GlassIconBubble(icon: Icons.admin_panel_settings_rounded),
              ],
            ),
            const SizedBox(height: 18),
            const AppLanguageSwitcher(),
            const SizedBox(height: 12),
            const AppThemeModeToggle(),
            const SizedBox(height: 18),
            WoodCard(
              tint: const Color(0xFFDDE8FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2F67FF), Color(0xFF7AA3FF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          user?.fullName ?? user?.username ?? copy.unknownUser,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${copy.role}: ${copy.translateRole(user?.role)}'),
                  const SizedBox(height: 6),
                  Text('${copy.email}: ${user?.email ?? copy.unknownEmail}'),
                  const SizedBox(height: 6),
                  Text(
                    '${copy.created}: ${formatDateTime(view.locale, user?.createdAt)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            WoodCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _apiController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: copy.apiBaseUrl,
                      hintText: copy.apiHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saveApiUrl,
                      child: Text(copy.saveApiUrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.apiConnectivityNote,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WoodGuardColors.pine,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            WoodCard(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _refreshingProfile ? null : _refreshProfile,
                      child: Text(
                        _refreshingProfile
                            ? copy.refreshingProfile
                            : copy.refreshProfile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canSync(user?.role))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _syncing ? null : _syncWarehub,
                        child: Text(
                          _syncing ? copy.syncingWarehub : copy.syncWarehub,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signOut,
                      child: Text(copy.signOut),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    InlineStatusBanner(message: _message!, isError: _isError),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
