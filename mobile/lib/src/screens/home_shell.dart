import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_view_controller.dart';
import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _revision = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    setState(() => _revision += 1);
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.watch<AppViewController>().copy;
    final pages = <Widget>[
      DashboardScreen(revision: _revision),
      InvoicesScreen(revision: _revision, onDataChanged: _notifyDataChanged),
      AccountScreen(revision: _revision, onDataChanged: _notifyDataChanged),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        animationDuration: const Duration(milliseconds: 380),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) {
            return;
          }
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: copy.overviewTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_rounded),
            selectedIcon: const Icon(Icons.inventory_rounded),
            label: copy.invoices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: copy.account,
          ),
        ],
      ),
    );
  }
}
