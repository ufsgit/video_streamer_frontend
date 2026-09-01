import 'package:flutter/material.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../../widgets/app_logo.dart';

class CategoryDetailsView extends StatelessWidget {
  final String category;
  final LibraryViewModel? viewModel;

  const CategoryDetailsView({
    super.key,
    required this.category,
    this.viewModel,
  });

  static const String exercise1Url =
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80';
  static const String exercise2Url =
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=800&q=80';

  @override
  Widget build(BuildContext context) {
    final bool isPreOp = category.toLowerCase().contains('pre');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        color: const Color(0xFF152C5B),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const AppLogo(size: 38, iconSize: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF152C5B),
                        ),
                      ),
                    ],
                  ),
                  // Search Icon Button
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
                      Icons.search_rounded,
                      color: Color(0xFF152C5B),
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Category Title Badge
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: const Color(0xFF5B67F6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    isPreOp ? 'Pre Op' : 'Post Op',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B67F6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Video Item 1 (Done / Completed)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                exercise1Url,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFF12B76A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Post-ACL Mobility Flow',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 18,
                                color: Color(0xFF12B76A),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF12B76A),
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

              const SizedBox(height: 20),

              // Video Item 2 (In Progress)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0052CC),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                exercise2Url,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052CC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'IN PROGRESS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Scapular Stabilization',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                          ),
                          Text(
                            '20%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0052CC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
