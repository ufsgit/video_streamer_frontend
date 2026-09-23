import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/tutorial/app_tour_controller.dart';
import '../views/navigation/main_navigation_view.dart';

class AppTutorialDialog extends StatefulWidget {
  final bool isManual;

  const AppTutorialDialog({super.key, this.isManual = false});

  /// Shows the dialog first if the user hasn't seen it yet.
  /// Once completed, it starts the interactive tour on the real screens.
  static Future<bool> showIfNeeded(BuildContext context) async {
    final bool shouldShow =
        await AppTourController.instance.shouldShowOnStartup();
    if (!shouldShow) return false;
    if (!context.mounted) return false;

    await show(context, isManual: false);
    return true;
  }

  /// Displays the tutorial modal dialog (can be triggered manually anytime from Profile).
  static Future<void> show(BuildContext context, {bool isManual = true}) async {
    await showDialog(
      context: context,
      barrierDismissible: isManual,
      builder: (context) => AppTutorialDialog(isManual: isManual),
    );
  }

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialStep> _steps = const [
    _TutorialStep(
      badge: 'Step 1 of 4',
      badgeColor: AppColors.primary,
      icon: Icons.health_and_safety_rounded,
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      title: 'Welcome to Meridian Health',
      subtitle: 'Your dedicated recovery & wellness guide',
      highlights: [
        _HighlightItem(
          icon: Icons.video_library_rounded,
          title: 'Curated Video Care',
          description:
              'Videos assigned by your doctor, Only watch inside the app.',
        ),
        _HighlightItem(
          icon: Icons.translate_rounded,
          title: 'Multilingual Content',
          description:
              'Watch all instructions in your preferred language anytime.',
        ),
      ],
    ),
    _TutorialStep(
      badge: 'Step 2 of 4',
      badgeColor: Color(0xFFEA580C),
      icon: Icons.lock_clock_rounded,
      gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
      title: 'Watch Without Skipping',
      subtitle: 'Ensuring you never miss vital medical steps',
      highlights: [
        _HighlightItem(
          icon: Icons.shield_rounded,
          title: 'Full Guidance Required',
          description:
              'Fast-forwarding is restricted so critical recovery instructions are never missed.',
        ),
        _HighlightItem(
          icon: Icons.history_rounded,
          title: 'Auto-Resume Playback',
          description:
              'Pause anytime! The app automatically remembers your second and resumes right where you stopped.',
        ),
      ],
    ),
    _TutorialStep(
      badge: 'Step 3 of 4',
      badgeColor: Color(0xFF059669),
      icon: Icons.insights_rounded,
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      title: 'Track Your Daily Progress',
      subtitle: 'Synced live with your healthcare team',
      highlights: [
        _HighlightItem(
          icon: Icons.cloud_done_rounded,
          title: 'Live Server Sync',
          description:
              'Your watch history and percentages are recorded safely on your device and shared with your doctor.',
        ),
        _HighlightItem(
          icon: Icons.local_fire_department_rounded,
          title: 'Streaks',
          description:
              'Build consistent daily habits and keep your recovery streak alive every day you complete a video.',
        ),
      ],
    ),
    _TutorialStep(
      badge: 'Step 4 of 4',
      badgeColor: Color(0xFF7C3AED),
      icon: Icons.notifications_active_rounded,
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      title: 'Reminders & Profile',
      subtitle: 'Stay on track every day with gentle alerts',
      highlights: [
        _HighlightItem(
          icon: Icons.alarm_rounded,
          title: 'Daily Reminders',
          description:
              'Set a personalized notification time that fits seamlessly into your daily routine.',
        ),
      ],
    ),
  ];

  Future<void> _completeTutorial() async {
    if (mounted) {
      Navigator.of(context).pop();
    }

    // If triggered manually from Profile, redirect to Library to start from Step 1
    if (widget.isManual && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationView(initialIndex: 0),
        ),
        (route) => false,
      );
    }

    // Launch the interactive guided tour across the real screens!
    AppTourController.instance.startTour(isManual: widget.isManual);
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _steps.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row (Badge + Skip)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _steps[_currentPage].badgeColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _steps[_currentPage].badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _steps[_currentPage].badgeColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _completeTutorial,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView Content
                SizedBox(
                  height: 380,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                    },
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Glowing Hero Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: step.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: step.gradientColors.first.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                step.icon,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title & Subtitle
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Two Feature Highlight Cards
                            ...step.highlights.map(
                              (h) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        h.icon,
                                        size: 18,
                                        color: step.gradientColors.first,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            h.description,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Dots + Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Smooth Dot Indicators
                      Row(
                        children: List.generate(_steps.length, (index) {
                          final bool isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            height: 6,
                            width: isSelected ? 22 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _steps[_currentPage].badgeColor
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      // Navigation Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentPage > 0)
                            IconButton(
                              onPressed: _prevPage,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              tooltip: 'Previous',
                              splashRadius: 20,
                            ),
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _steps[_currentPage].badgeColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isLastPage ? 20 : 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLastPage ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isLastPage
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final List<_HighlightItem> highlights;

  const _TutorialStep({
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.highlights,
  });
}

class _HighlightItem {
  final IconData icon;
  final String title;
  final String description;

  const _HighlightItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
