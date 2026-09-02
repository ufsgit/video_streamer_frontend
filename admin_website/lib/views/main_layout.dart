import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'dashboard/dashboard_view.dart';
import 'library/video_library_view.dart';
import 'patient/patient_profile_view.dart';
import 'patient/patients_list_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const DashboardView(),
    const VideoLibraryView(),
    const PatientsListView(),
    const PatientProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: _views[_selectedIndex],
          )
        ],
      ),
    );
  }
}
