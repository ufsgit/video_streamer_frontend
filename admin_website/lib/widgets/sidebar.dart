import 'package:flutter/material.dart';
import '../core/theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({super.key, required this.selectedIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppTheme.secondaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  radius: 14,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Admin Portal",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Central Hospital Staff",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildNavItem(0, "Dashboard", Icons.dashboard_outlined),
          _buildNavItem(1, "Library", Icons.video_library_outlined),
          _buildNavItem(2, "Patients", Icons.people_outline),
          _buildNavItem(3, "Profile", Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.white.withAlpha(128) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            )
          ],
        ),
      ),
    );
  }
}
