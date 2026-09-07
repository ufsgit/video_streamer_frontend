import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../viewmodels/library_viewmodel.dart';
import 'assign_videos_dialog.dart';
import 'add_video_dialog.dart';

class VideoLibraryView extends StatefulWidget {
  const VideoLibraryView({super.key});

  @override
  State<VideoLibraryView> createState() => _VideoLibraryViewState();
}

class _VideoLibraryViewState extends State<VideoLibraryView> {
  final VideoLibraryViewModel _viewModel = VideoLibraryViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _playVideoInDialog(Map<String, dynamic> video) {
    final ytUrl =
        video["youtubeUrl"] ??
        video["video_url"] ??
        video["url"] ??
        video["link"] ??
        (video["videoId"] != null
            ? "https://www.youtube.com/watch?v=${video["videoId"]}"
            : null);
    final rawYtId = video["videoId"]?.toString();
    final videoId = (ytUrl != null ? VideoLibraryViewModel.extractYoutubeId(ytUrl.toString()) : null) ??
        (rawYtId != null && rawYtId.isNotEmpty ? VideoLibraryViewModel.extractYoutubeId(rawYtId) ?? rawYtId : null);

    if (videoId == null || videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No playable YouTube ID found for this video."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        showVideoAnnotations: false,
        enableCaption: true,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => PopScope(
        onPopInvokedWithResult: (didPop, result) {
          controller.close();
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 560),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['title'] ?? 'Video Playback',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (video['category'] != null)
                              Text(
                                video['category'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.secondaryBlue,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        tooltip: "Close",
                        onPressed: () {
                          controller.close();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddVideoDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVideoDialog(
        onVideoAdded: (newVideo) {
          _viewModel.addVideo(newVideo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Added '${newVideo['title']}' to video library!"),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteVideo(Map<String, dynamic> video) async {
    final title = video["title"] ?? "this video";
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Video", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$title' from the library?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await _viewModel.deleteVideo(video);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Video '$title' deleted successfully."),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete video: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final videos = _viewModel.videos;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLibrarySectionHeader(videos),
                const SizedBox(height: 14),

                // Search & Filter Bar
                _buildSearchAndFilters(videos),
                const SizedBox(height: 14),

                // Selection Mode Actions Bar
                if (_viewModel.isSelectionMode) ...[
                  _buildSelectionBar(),
                  const SizedBox(height: 14),
                ],

                // Video Grid / Empty State
                _buildVideoGrid(videos),
                const SizedBox(height: 60),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLibrarySectionHeader(List<Map<String, dynamic>> videos) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.video_collection_outlined,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            const Text(
              "Saved Library Videos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${videos.length} Videos",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _openAddVideoDialog,
          icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryBlue),
          label: const Text(
            "Add Video",
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(List<Map<String, dynamic>> videos) {
    return Column(
      children: [
        // Search Input
        TextField(
          decoration: InputDecoration(
            hintText: "Search titles or categories...",
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          onChanged: _viewModel.updateSearchQuery,
        ),
        const SizedBox(height: 10),
        // Category Selector & Selection Mode
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(_viewModel.categories.length, (index) {
                final isSelected = _viewModel.selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_viewModel.categories[index]),
                    selected: isSelected,
                    onSelected: (selected) => _viewModel.selectCategory(index),
                    selectedColor: AppTheme.categorySelectorColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: AppTheme.secondaryBlue,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              if (videos.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _viewModel.toggleSelectionMode,
                  icon: const Icon(Icons.checklist, size: 16),
                  label: Text(
                    _viewModel.isSelectionMode ? "Cancel" : "Select Videos",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              "${_viewModel.selectedVideos.length}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Videos Selected",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _viewModel.clearSelection,
            child: const Text(
              "Clear Selection",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _viewModel.selectedVideos.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AssignVideosDialog(
                        selectedVideos: _viewModel.selectedVideos.toList(),
                        onAssigned: () {
                          _viewModel.exitSelectionMode();
                        },
                      ),
                    );
                  },
            icon: const Icon(Icons.check, size: 16),
            label: Text(
              "Assign to Patient (${_viewModel.selectedVideos.length})",
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(List<Map<String, dynamic>> videos) {
    if (_viewModel.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(60),
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Loading videos from server...",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.secondaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage != null
                  ? _viewModel.errorMessage!
                  : "No videos stored in the library yet",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _viewModel.errorMessage != null
                  ? "Could not reach the video server. Click retry to load again."
                  : "Paste a YouTube video link above and click 'Save to Library', or click 'Add New Video' to build your collection.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_viewModel.errorMessage != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _viewModel.fetchVideos(refresh: true),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Retry"),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  onPressed: _openAddVideoDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text("Add New Video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _buildVideoCard(video);
          },
        );
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final isSelected = _viewModel.selectedVideos.contains(video);
    final rawUrl = video["youtubeUrl"]?.toString() ??
        video["video_url"]?.toString() ??
        video["url"]?.toString() ??
        "";
    final ytId = (video["videoId"] != null && video["videoId"].toString().isNotEmpty)
        ? video["videoId"].toString()
        : VideoLibraryViewModel.extractYoutubeId(rawUrl);

    final rawApiThumb = video["thumbnail_url"] ??
        video["thumbnail"] ??
        video["thumbnailUrl"] ??
        video["imageUrl"] ??
        video["image_url"] ??
        video["image"] ??
        video["thumbnail_path"];

    String thumbUrl = '';
    if (rawApiThumb != null && rawApiThumb.toString().trim().isNotEmpty) {
      thumbUrl = ApiService().getFullImageUrl(rawApiThumb.toString().trim());
    } else if (ytId != null && ytId.isNotEmpty) {
      thumbUrl = "https://img.youtube.com/vi/$ytId/hqdefault.jpg";
    } else {
      thumbUrl =
          "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60";
    }

    return InkWell(
      onTap: _viewModel.isSelectionMode
          ? () => _viewModel.toggleVideoSelection(video)
          : () => _playVideoInDialog(video),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area
            Expanded(
              flex: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.video_library_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Play overlay on hover or default
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.live_tv_rounded,
                            color: Colors.redAccent,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            video["duration"] ?? "Stream",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_viewModel.isSelectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withAlpha(100),
                      ),
                      onPressed: () => _confirmDeleteVideo(video),
                      tooltip: "Delete from library",
                    ),
                  ),
                ],
              ),
            ),
            // Info Area
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video["title"] ?? "Untitled Video",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video["description"] ?? "",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          video["category"] ?? "Pre-Op",
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () => _playVideoInDialog(video),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.play_circle_fill,
                                size: 14,
                                color: Colors.red,
                              ),
                              SizedBox(width: 3),
                              Text(
                                "Play",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
