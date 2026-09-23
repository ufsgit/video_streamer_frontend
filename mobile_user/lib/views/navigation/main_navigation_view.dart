import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tutorial/app_tour_controller.dart';
import '../../widgets/app_tutorial_dialog.dart';
import '../../widgets/daily_reminder_dialog.dart';
import '../library/library_view.dart';
import '../profile/profile_view.dart';

class MainNavigationView extends StatefulWidget {
  final int initialIndex;

  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _currentIndex;

  final List<Widget> _screens = const [LibraryView(), ProfileView()];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    AppTourController.instance.addListener(_onTourStateChanged);

    // One-time tutorial for first time logins, followed by daily video reminder
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final bool startedTour = await AppTutorialDialog.showIfNeeded(context);
      if (!startedTour && mounted) {
        DailyReminderDialog.showIfNeeded(context);
      }
    });
  }

  void _onTourStateChanged() {
    if (!AppTourController.instance.isActive && mounted) {
      DailyReminderDialog.showIfNeeded(context);
    }
  }

  @override
  void dispose() {
    AppTourController.instance.removeListener(_onTourStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: AppColors.subtleShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.article_outlined,
                  label: 'Library',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
