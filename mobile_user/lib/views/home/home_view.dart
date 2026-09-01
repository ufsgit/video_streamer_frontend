import 'package:flutter/material.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/video_container_no_image.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel? viewModel;

  const HomeView({super.key, this.viewModel});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HomeViewModel();
    _viewModel.fetchDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          AppLogo(size: 38, iconSize: 20),
                          SizedBox(width: 10),
                          Text(
                            'Meridian Health',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF152C5B),
                            ),
                          ),
                        ],
                      ),
                      // Notification icon with badge
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF152C5B),
                              size: 22,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF04438),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _viewModel.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search exercises, protocols...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF98A2B3),
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Continue watching
                  const Text(
                    'Continue watching',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Continue watching Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VideoContainerNoImage(
                          height: 185,
                          badgeText: '12 min left',
                          customGradient: LinearGradient(
                            colors: [Color(0xFF3B4371), Color(0xFFF3A183)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tag Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F3FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'STEP 2 OF 4 · POST-ACL PROGRAM',
                                  style: TextStyle(
                                    color: Color(0xFF5B61F6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Progress Text
                              Row(
                                children: [
                                  Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    size: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '20% complete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  value: 0.20,
                                  minHeight: 6,
                                  backgroundColor: Color(0xFFEAECF0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF5B61F6),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Resume Video Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Video playback API integration pending.',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B61F6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Resume video',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section: Completed
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Completed Items Row
                  Row(
                    children: [
                      // Completed Card 1
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VideoContainerNoImage(
                                height: 110,
                                showCheckmark: true,
                                customGradient: LinearGradient(
                                  colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        color: Color(0xFF12B76A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Step 1: Post-ACL Mobility Flow',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF101828),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Completed Card 2
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VideoContainerNoImage(
                                height: 110,
                                showCheckmark: true,
                                customGradient: LinearGradient(
                                  colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        color: Color(0xFF12B76A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Initial Assessment & Goals',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF101828),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
