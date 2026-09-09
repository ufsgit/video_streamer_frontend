import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/video_progress_bar.dart';
import 'youtube_player_view.dart';
import '../../models/video_model.dart';

class CategoryDetailsView extends StatefulWidget {
  final String category;
  final LibraryViewModel? viewModel;

  const CategoryDetailsView({
    super.key,
    required this.category,
    this.viewModel,
  });

  @override
  State<CategoryDetailsView> createState() => _CategoryDetailsViewState();
}

class _CategoryDetailsViewState extends State<CategoryDetailsView> {
  late final LibraryViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? LibraryViewModel();
    // Fetch videos for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchDynamicCategoryVideos(widget.category);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_viewModel.isLoadingMore && _viewModel.hasMore) {
        _viewModel.loadMoreCategoryVideos(widget.category);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreOp = widget.category.toLowerCase().contains('pre');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
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

              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  if (_viewModel.isLoading && _viewModel.currentCategoryVideos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    );
                  }

                  final videos = _viewModel.currentCategoryVideos;

                  if (videos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Text(
                          'No videos found for this category.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: videos.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final bool isDone = video.status == VideoStatus.completed;
                          final bool inProgress = video.status == VideoStatus.inProgress;

                          String effectiveImageUrl = video.imageUrl;
                          if (effectiveImageUrl.isEmpty && video.link != null && video.link!.isNotEmpty) {
                            final videoId = YoutubePlayerController.convertUrlToId(video.link!);
                            if (videoId != null && videoId.isNotEmpty) {
                              effectiveImageUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                            }
                          }
                          if (effectiveImageUrl.isEmpty) {
                            effectiveImageUrl = 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80';
                          }

                          return GestureDetector(
                            onTap: () {
                              if (video.link != null && video.link!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => YoutubePlayerView(
                                      videoUrl: video.link!,
                                      title: video.title,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Video link is not available')),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: inProgress ? const Color(0xFF0052CC) : Colors.transparent,
                                  width: inProgress ? 2.0 : 0.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: inProgress 
                                        ? const Color(0xFF0052CC).withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.04),
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
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Image.network(
                                              effectiveImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          if (inProgress)
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
                                          if (isDone)
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 14.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF101828),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        VideoProgressBar(
                                          videoKey: video.link ?? video.id.toString(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_viewModel.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF0052CC),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
