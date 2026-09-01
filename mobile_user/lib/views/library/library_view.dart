import 'dart:ui';
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

  static const String preOpImageUrl =
      'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=1000&q=80';
  static const String postOpImageUrl =
      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=1000&q=80';

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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          AppLogo(
                            size: 46,
                            iconSize: 26,
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
                      // Search circular button
                      Container(
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
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Pre-op Category Card
                  _buildCategoryCard(
                    context,
                    title: 'Pre-op',
                    subtitle: 'Preparation &\nReadiness',
                    imageUrl: preOpImageUrl,
                    isStethoscope: true,
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

                  const SizedBox(height: 24),

                  // Post-op Category Card
                  _buildCategoryCard(
                    context,
                    title: 'Post-op',
                    subtitle: 'Recovery &\nRehabilitation',
                    imageUrl: postOpImageUrl,
                    isStethoscope: false,
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

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imageUrl,
    required bool isStethoscope,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 195,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF334155),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.white60,
                      size: 36,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (isStethoscope)
                              const SizedBox(
                                width: 38,
                                height: 38,
                                child: CustomPaint(
                                  painter: StethoscopePainter(
                                    color: Colors.white,
                                    strokeWidth: 2.8,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.add_home_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
