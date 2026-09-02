import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../viewmodels/library_viewmodel.dart';

class VideoLibraryView extends StatefulWidget {
  const VideoLibraryView({super.key});

  @override
  State<VideoLibraryView> createState() => _VideoLibraryViewState();
}

class _VideoLibraryViewState extends State<VideoLibraryView> {
  final VideoLibraryViewModel _viewModel = VideoLibraryViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Video Library",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "Educational resources for patient care and rehabilitation.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search conditions, exercises, or guidelines...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _viewModel.updateSearchQuery,
            ),
            const SizedBox(height: 12),
            // Category Chips
            Row(
              children: List.generate(_viewModel.categories.length, (index) {
                final isSelected = _viewModel.selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_viewModel.categories[index]),
                    selected: isSelected,
                    onSelected: (selected) => _viewModel.selectCategory(index),
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: AppTheme.secondaryBlue,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Video Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _viewModel.videos.length,
                itemBuilder: (context, index) {
                  final video = _viewModel.videos[index];
                  return _buildVideoCard(video);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (using container to simulate image from design)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(video["imageUrl"], fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(video["duration"], style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video["title"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  video["description"],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Text(video["category"], style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 11)),
                      ],
                    ),
                    const Icon(Icons.bookmark_border, size: 18, color: AppTheme.textSecondary),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
