import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard/dashboard_view.dart';
import 'library/video_library_view.dart';
import 'patient/patients_list_view.dart';
import 'mobile/dashboard/mobile_dashboard_view.dart';
import 'mobile/library/mobile_library_view.dart';
import 'mobile/patient/mobile_patients_view.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  static const List<String> _routes = [
    '/dashboard',
    '/library',
    '/patients',
  ];

  final List<Widget> _desktopViews = [
    const DashboardView(),
    const VideoLibraryView(),
    const PatientsListView(),
  ];

  final List<Widget> _mobileViews = const [
    MobileDashboardView(),
    MobileLibraryView(),
    MobilePatientsView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _resolveInitialIndex();
    if (_selectedIndex >= _routes.length) {
      _selectedIndex = 0;
    }
  }

  int _resolveInitialIndex() {
    if (kIsWeb) {
      final fragment = Uri.base.fragment.toLowerCase();
      final path = Uri.base.path.toLowerCase();

      if (fragment.contains('library') || path.contains('library')) return 1;
      if (fragment.contains('patient') || path.contains('patient')) return 2;
      if (fragment.contains('dashboard') || path.contains('dashboard')) {
        return 0;
      }
    }

    return widget.initialIndex < _routes.length ? widget.initialIndex : 0;
  }

  void _onItemSelected(int index) {
    if (index >= _routes.length || _selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });

    final targetRoute = _routes[index];
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _mobileViews),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: const Border(
              top: BorderSide(color: AppTheme.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              _onItemSelected(index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(
                  Icons.dashboard_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(
                  Icons.video_library_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Patients',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
          Expanded(child: _desktopViews[_selectedIndex]),
        ],
      ),
    );
  }
}
