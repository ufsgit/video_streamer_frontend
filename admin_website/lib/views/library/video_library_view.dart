import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
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
  final TextEditingController _youtubeUrlController = TextEditingController();
  
  YoutubePlayerController? _youtubeController;
  String? _currentVideoId;
  String _currentVideoTitle = "";
  String? _errorMessage;
  bool _isPlayerInitialized = false;

  // Preset sample videos for quick testing
  final List<Map<String, String>> _sampleVideos = [
    {
      "label": "Flutter Tutorial",
      "url": "https://www.youtube.com/watch?v=fq4N0hgOWzU",
      "title": "Flutter in 100 Seconds",
    },
    {
      "label": "Knee Rehab Exercise",
      "url": "https://www.youtube.com/watch?v=2L2lnxIcNmo",
      "title": "Physical Therapy Knee Rehabilitation Routine",
    },
    {
      "label": "Guided Breathing",
      "url": "https://www.youtube.com/watch?v=5DqTuWve9t8",
      "title": "5-Minute Guided Breathing Exercise",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default initial video ID (sample medical / tech clip)
    _initPlayer('fq4N0hgOWzU');
    _youtubeUrlController.text = 'https://www.youtube.com/watch?v=fq4N0hgOWzU';
    _currentVideoTitle = 'Flutter in 100 Seconds';
  }

  void _initPlayer(String videoId) {
    _currentVideoId = videoId;
    _errorMessage = null;

    if (_youtubeController == null) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          showVideoAnnotations: false,
          enableCaption: true,
        ),
      );
      _isPlayerInitialized = true;
    } else {
      _youtubeController!.loadVideoById(videoId: videoId);
    }
  }

  String? _extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Check if input is already an 11-char YouTube ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    // Standard YouTube URL parser
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    // Try controller's built-in converter as fallback
    try {
      final converted = YoutubePlayerController.convertUrlToId(trimmed);
      if (converted != null && converted.isNotEmpty) return converted;
    } catch (_) {}

    return null;
  }

  void _testAndPlayVideo([String? customUrl]) {
    final url = customUrl ?? _youtubeUrlController.text;
    final videoId = _extractVideoId(url);

    setState(() {
      if (videoId == null) {
        _errorMessage = "Invalid YouTube URL or Video ID. Please check the link.";
        return;
      }

      _errorMessage = null;
      _currentVideoId = videoId;
      _youtubeUrlController.text = url;
      _initPlayer(videoId);
    });
  }

  void _saveCurrentVideoToLibrary() {
    if (_currentVideoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please test a valid YouTube video first.")),
      );
      return;
    }

    final title = _currentVideoTitle.isNotEmpty
        ? _currentVideoTitle
        : "YouTube Video (${_currentVideoId!})";

    final newVideo = {
      "id": "yt_${DateTime.now().millisecondsSinceEpoch}",
      "videoId": _currentVideoId,
      "title": title,
      "description": "YouTube educational streaming video: ${_youtubeUrlController.text}",
      "category": "General",
      "duration": "Stream",
      "imageUrl": "https://img.youtube.com/vi/$_currentVideoId/hqdefault.jpg",
      "youtubeUrl": _youtubeUrlController.text,
    };

    _viewModel.addVideo(newVideo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added '$title' to video library!"),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddVideoDialog(),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New Video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final videos = _viewModel.videos;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Video Library & YouTube Streamer",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Stream YouTube videos directly, test playback links, and manage rehabilitation content.",
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 1. YOUTUBE PLAYER & LINK TESTER CARD ---
                _buildYoutubeTesterCard(),
                const SizedBox(height: 28),

                // --- 2. LIBRARY REPOSITORIES SECTION ---
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

  Widget _buildYoutubeTesterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "YouTube Video Player & Stream Tester",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _currentVideoId != null
                          ? "Loaded Video ID: $_currentVideoId"
                          : "Paste any YouTube link below to stream and test",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentVideoId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Player Active",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // YouTube Link Input Field
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _youtubeUrlController,
                      decoration: InputDecoration(
                        hintText: "Enter YouTube URL (e.g. https://www.youtube.com/watch?v=...)",
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(Icons.link_rounded, color: Colors.red, size: 20),
                        suffixIcon: _youtubeUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _youtubeUrlController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                      onSubmitted: (val) => _testAndPlayVideo(),
                      onChanged: (val) => setState(() {}),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _testAndPlayVideo(),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text("Test & Play"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _currentVideoId != null ? _saveCurrentVideoToLibrary : null,
                            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            label: const Text("Save to Library"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                              side: const BorderSide(color: AppTheme.primaryBlue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _youtubeUrlController,
                          decoration: InputDecoration(
                            hintText: "Enter YouTube URL (e.g. https://www.youtube.com/watch?v=...)",
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(Icons.link_rounded, color: Colors.red, size: 20),
                            suffixIcon: _youtubeUrlController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      _youtubeUrlController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                            ),
                          ),
                          onSubmitted: (val) => _testAndPlayVideo(),
                          onChanged: (val) => setState(() {}),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _testAndPlayVideo(),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text("Test & Play"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _currentVideoId != null ? _saveCurrentVideoToLibrary : null,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text("Save to Library"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Quick Presets / Test Suggestions
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Quick Test Links:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              ..._sampleVideos.map((sample) {
                return ActionChip(
                  avatar: const Icon(Icons.play_circle_outline, size: 14, color: Colors.red),
                  label: Text(sample["label"]!),
                  labelStyle: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onPressed: () {
                    _currentVideoTitle = sample["title"]!;
                    _testAndPlayVideo(sample["url"]!);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 18),

          // Embedded YouTube Player Box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _isPlayerInitialized && _youtubeController != null
                  ? YoutubePlayer(
                      controller: _youtubeController!,
                      aspectRatio: 16 / 9,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.video_library_outlined, size: 48, color: Colors.white54),
                          SizedBox(height: 10),
                          Text(
                            "Enter a YouTube link above to load the stream player",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySectionHeader(List<Map<String, dynamic>> videos) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.video_collection_outlined, size: 20, color: AppTheme.primaryBlue),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: AppTheme.secondaryBlue,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }),
              const SizedBox(width: 8),
              if (videos.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _viewModel.toggleSelectionMode,
                  icon: const Icon(Icons.checklist, size: 16),
                  label: Text(_viewModel.isSelectionMode ? "Cancel" : "Select Videos"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
            child: const Text("Clear Selection", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
            label: Text("Assign to Patient (${_viewModel.selectedVideos.length})", style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(List<Map<String, dynamic>> videos) {
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
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_library_outlined, size: 40, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              "No videos stored in the library yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              "Paste a YouTube video link above and click 'Save to Library', or click 'Add New Video' to build your collection.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _youtubeUrlController.text = "https://www.youtube.com/watch?v=fq4N0hgOWzU";
                _currentVideoTitle = "Flutter in 100 Seconds";
                _testAndPlayVideo();
                _saveCurrentVideoToLibrary();
              },
              icon: const Icon(Icons.add_to_photos_outlined, size: 16),
              label: const Text("Add Sample YouTube Video"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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

    return InkWell(
      onTap: _viewModel.isSelectionMode
          ? () => _viewModel.toggleVideoSelection(video)
          : () {
              // Clicking a card loads it into the top YouTube player
              final ytUrl = video["youtubeUrl"] ?? (video["videoId"] != null ? "https://www.youtube.com/watch?v=${video["videoId"]}" : null);
              if (ytUrl != null) {
                _currentVideoTitle = video["title"] ?? "";
                _testAndPlayVideo(ytUrl);
              }
            },
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      video["imageUrl"] ?? "https://img.youtube.com/vi/${video["videoId"] ?? ""}/hqdefault.jpg",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.video_library_rounded, color: Colors.grey),
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
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            video["duration"] ?? "Stream",
                            style: const TextStyle(color: Colors.white, fontSize: 10),
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
                          color: isSelected ? AppTheme.primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black.withAlpha(100)),
                      onPressed: () => _viewModel.removeVideo(video),
                      tooltip: "Remove from library",
                    ),
                  ),
                ],
              ),
            ),
            // Info Area
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video["title"] ?? "Untitled Video",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video["description"] ?? "",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          video["category"] ?? "General",
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final ytUrl = video["youtubeUrl"] ?? (video["videoId"] != null ? "https://www.youtube.com/watch?v=${video["videoId"]}" : null);
                            if (ytUrl != null) {
                              _currentVideoTitle = video["title"] ?? "";
                              _testAndPlayVideo(ytUrl);
                            }
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.play_circle_fill, size: 14, color: Colors.red),
                              SizedBox(width: 3),
                              Text("Play", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
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
