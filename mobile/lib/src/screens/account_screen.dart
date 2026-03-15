import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
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
    try {
      await context.read<AppSessionController>().setApiBaseUrl(
        _apiController.text,
      );
      setState(() {
        _message =
            'API base URL saved. If you changed backend host, sign in again if needed.';
      });
    } on ApiException catch (error) {
      setState(() => _message = error.message);
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _refreshingProfile = true;
      _message = null;
    });

    try {
      final user = await context
          .read<AppSessionController>()
          .refreshCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() => _message = 'Profile refreshed for ${user.username}.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _refreshingProfile = false);
      }
    }
  }

  Future<void> _syncWarehub() async {
    setState(() {
      _syncing = true;
      _message = null;
    });

    try {
      final result = await context.read<AppSessionController>().syncWarehub();
      if (!mounted) {
        return;
      }
      widget.onDataChanged();
      setState(() {
        _message =
            'Warehub sync finished. ${result.imported} imported, ${result.updated} updated.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
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
    final user = session.currentUser;

    return Scaffold(
      body: WoodGuardSurface(
        child: ListView(
          children: [
            const SectionHeader(
              title: 'Mobile Operator Console',
              subtitle:
                  'Keep API connectivity, session state and sync actions in one place.',
            ),
            const SizedBox(height: 18),
            WoodCard(
              tint: const Color(0xFFE3EDE6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? user?.username ?? 'Unknown user',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text('Role: ${translateRole(user?.role ?? 'viewer')}'),
                  const SizedBox(height: 6),
                  Text('Email: ${user?.email ?? 'Unknown'}'),
                  const SizedBox(height: 6),
                  Text('Created: ${formatDateTime(user?.createdAt)}'),
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
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.x.x:8000/api/v1',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saveApiUrl,
                      child: const Text('Save API URL'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Native mobile requests bypass browser CORS, so this talks '
                    'directly to the same FastAPI backend as the web app.',
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
                            ? 'Refreshing profile...'
                            : 'Refresh Profile',
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
                          _syncing ? 'Syncing Warehub...' : 'Sync Warehub',
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signOut,
                      child: const Text('Sign Out'),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            _message!.toLowerCase().contains('failed') ||
                                _message!.toLowerCase().contains('error')
                            ? WoodGuardColors.danger
                            : WoodGuardColors.ember,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
