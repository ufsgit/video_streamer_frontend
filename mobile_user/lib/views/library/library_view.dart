import 'package:flutter/material.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../../widgets/app_logo.dart';
import 'category_details_view.dart';

class LibraryView extends StatefulWidget {
  final LibraryViewModel? viewModel;

  const LibraryView({super.key, this.viewModel});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? LibraryViewModel();
    _viewModel.fetchCategoryVideos();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            titleSpacing: 24,
            title: const Row(
              children: [
                AppLogo(
                  size: 44,
                  iconSize: 24,
                  isSquircle: true,
                  backgroundColor: Color(0xFF5B67F6),
                ),
                SizedBox(width: 14),
                Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Pre-op Colorful Card
                  _buildColorfulCategoryCard(
                    context,
                    tag: 'PHASE 1 · PREPARATION',
                    title: 'Pre-op',
                    gradientColors: const [
                      Color(0xFF4F46E5),
                      Color(0xFF6366F1),
                      Color(0xFF7C3AED),
                    ],
                    shadowColor: const Color(0xFF4F46E5),
                    iconWidget: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CustomPaint(
                        painter: StethoscopePainter(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ),
                    onTap: () {
                      _viewModel.selectCategory('Pre-op');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailsView(
                            category: 'Pre-op',
                            viewModel: _viewModel,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // Post-op Colorful Card
                  _buildColorfulCategoryCard(
                    context,
                    tag: 'PHASE 2 · REHABILITATION',
                    title: 'Post-op',
                    gradientColors: const [
                      Color(0xFF0D9488),
                      Color(0xFF059669),
                      Color(0xFF10B981),
                    ],
                    shadowColor: const Color(0xFF0D9488),
                    iconWidget: const Icon(
                      Icons.healing_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onTap: () {
                      _viewModel.selectCategory('Post-op');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailsView(
                            category: 'Post-op',
                            viewModel: _viewModel,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorfulCategoryCard(
    BuildContext context, {
    required String tag,
    required String title,
    required List<Color> gradientColors,
    required Color shadowColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative ambient circles for premium visual depth
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 40,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Tag Pill & Icon Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Center(child: iconWidget),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Bottom Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Explore protocols',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: gradientColors.first,
                              size: 18,
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
