import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard/dashboard_view.dart';
import 'library/video_library_view.dart';
import 'profile/patient_profile_view.dart';
import 'patient/patients_list_view.dart';

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
    '/profile',
  ];

  final List<Widget> _views = [
    const DashboardView(),
    const VideoLibraryView(),
    const PatientsListView(),
    const PatientProfileView(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Video Library',
    'Patients',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _resolveInitialIndex();
  }

  int _resolveInitialIndex() {
    final fragment = Uri.base.fragment.toLowerCase();
    final path = Uri.base.path.toLowerCase();

    if (fragment.contains('library') || path.contains('library')) return 1;
    if (fragment.contains('patient') || path.contains('patient')) return 2;
    if (fragment.contains('profile') || path.contains('profile')) return 3;
    if (fragment.contains('dashboard') || path.contains('dashboard')) return 0;

    return widget.initialIndex;
  }

  void _onItemSelected(int index) {
    if (_selectedIndex == index) return;
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        ),
        drawer: Drawer(
          child: Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              Navigator.pop(context); // Close drawer
              _onItemSelected(index);
            },
          ),
        ),
        body: _views[_selectedIndex],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }
}
