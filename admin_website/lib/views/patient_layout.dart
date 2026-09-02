import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'dashboard/dashboard_view.dart';
import 'library/video_library_view.dart';
import 'patient/patient_profile_view.dart';
import 'patient/patients_list_view.dart';

class PatientLayout extends StatefulWidget {
  final int initialIndex;

  const PatientLayout({super.key, this.initialIndex = 0});

  @override
  State<PatientLayout> createState() => _PatientLayoutState();
}

class _PatientLayoutState extends State<PatientLayout> {
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
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
          Expanded(
            child: _views[_selectedIndex],
          )
        ],
      ),
    );
  }
}
