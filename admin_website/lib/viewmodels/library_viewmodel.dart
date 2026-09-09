import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VideoLibraryViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String searchQuery = "";
  int selectedCategoryIndex = 0;

  bool isSelectionMode = false;
  final Set<Map<String, dynamic>> selectedVideos = {};

  final List<String> categories = ["All", "Pre-op", "Post-op"];

  List<Map<String, dynamic>> allVideos = [];
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  static const int pageSize = 12;
  int totalVideos = 0;
  int totalPages = 1;

  Timer? _searchDebounce;

  VideoLibraryViewModel() {
    fetchVideos();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  static String? extractYoutubeId(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) return match.group(1);
    return null;
  }

  void goToPage(int page) {
    if (page < 1 ||
        (totalPages > 0 && page > totalPages) ||
        page == currentPage ||
        isLoading) {
      return;
    }
    fetchVideos(page: page);
  }

  void nextPage() {
    if (hasNextPage && !isLoading) {
      goToPage(currentPage + 1);
    }
  }

  void previousPage() {
    if (hasPreviousPage && !isLoading) {
      goToPage(currentPage - 1);
    }
  }

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage =>
      currentPage < totalPages ||
      (totalVideos > 0 && currentPage * pageSize < totalVideos) ||
      (totalVideos == 0 && allVideos.length == pageSize);

  Future<void> fetchVideos({int page = 1, bool refresh = false}) async {
    isLoading = true;
    errorMessage = null;
    if (refresh) {
      currentPage = 1;
    } else {
      currentPage = page;
    }
    notifyListeners();

    try {
      final selectedCategory = categories[selectedCategoryIndex];
      final categoryParam = selectedCategory.toLowerCase() == "all"
          ? null
          : selectedCategory.toLowerCase();

      final response = await _apiService.listVideos(
        page: currentPage,
        limit: pageSize,
        search: searchQuery.trim().isNotEmpty ? searchQuery.trim() : null,
        category: categoryParam,
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        List<dynamic> rawList = [];

        if (resData is Map<String, dynamic>) {
          totalVideos =
              resData['total'] ??
              resData['totalCount'] ??
              resData['count'] ??
              (resData['pagination'] is Map
                  ? resData['pagination']['total']
                  : null) ??
              (resData['meta'] is Map ? resData['meta']['total'] : null) ??
              (resData['data'] is Map
                  ? (resData['data']['total'] ??
                        resData['data']['totalCount'] ??
                        resData['data']['count'])
                  : null) ??
              0;

          if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['data'] is Map &&
              resData['data']['videos'] is List) {
            rawList = resData['data']['videos'];
          } else if (resData['videos'] is List) {
            rawList = resData['videos'];
          } else if (resData['results'] is List) {
            rawList = resData['results'];
          }
        } else if (resData is List) {
          rawList = resData;
          totalVideos = rawList.length;
        }

        final List<Map<String, dynamic>> parsedVideos = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            final url =
                item['video_url']?.toString() ??
                item['url']?.toString() ??
                item['youtubeUrl']?.toString() ??
                '';
            final ytId = extractYoutubeId(url);

            String thumbUrl = '';
            final rawApiThumb =
                item['thumbnail_url'] ??
                item['thumbnail'] ??
                item['thumbnailUrl'] ??
                item['image_url'] ??
                item['imageUrl'] ??
                item['image'] ??
                item['thumbnail_path'];

            if (rawApiThumb != null &&
                rawApiThumb.toString().trim().isNotEmpty) {
              thumbUrl = _apiService.getFullImageUrl(
                rawApiThumb.toString().trim(),
              );
            } else if (ytId != null && ytId.isNotEmpty) {
              thumbUrl = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
            } else {
              thumbUrl =
                  'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60';
            }

            parsedVideos.add({
              'id':
                  item['id']?.toString() ??
                  item['_id']?.toString() ??
                  'vid_${parsedVideos.length}',
              'videoId': ytId,
              'title': item['title']?.toString() ?? 'Untitled Video',
              'description': item['description']?.toString() ?? '',
              'category': item['category']?.toString() ?? 'Pre-op',
              'language':
                  item['language']?.toString() ??
                  item['language_name']?.toString() ??
                  '',
              'duration': item['duration']?.toString() ?? 'Stream',
              'youtubeUrl': url,
              'imageUrl': thumbUrl,
              'thumbnail_url': thumbUrl,
              'thumbnail': thumbUrl,
            });
          }
        }

        allVideos = parsedVideos;

        if (totalVideos <= 0) {
          totalVideos = (currentPage - 1) * pageSize + allVideos.length;
          totalPages =
              (allVideos.length == pageSize) ? currentPage + 1 : currentPage;
        } else {
          totalPages = (totalVideos / pageSize).ceil();
          if (totalPages < 1) totalPages = 1;
        }
      }
    } catch (e) {
      debugPrint("Error fetching videos from API: $e");
      errorMessage = "Failed to load videos from server.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get videos {
    return allVideos;
  }

  void addVideo(Map<String, dynamic> video) {
    allVideos.insert(0, video);
    totalVideos++;
    totalPages = (totalVideos / pageSize).ceil();
    if (totalPages < 1) totalPages = 1;
    notifyListeners();
  }

  void removeVideo(Map<String, dynamic> video) {
    allVideos.remove(video);
    selectedVideos.remove(video);
    if (totalVideos > 0) totalVideos--;
    totalPages = (totalVideos / pageSize).ceil();
    if (totalPages < 1) totalPages = 1;
    notifyListeners();
  }

  Future<bool> updateVideo(
    String id, {
    required String title,
    required String category,
    required String videoUrl,
    String? description,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
  }) async {
    try {
      final response = await _apiService.editVideo(
        id,
        title: title,
        category: category,
        videoUrl: videoUrl,
        description: description,
        thumbnailBytes: thumbnailBytes,
        thumbnailFilename: thumbnailFilename,
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        await fetchVideos(page: currentPage, refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating video in ViewModel: $e");
      rethrow;
    }
  }

  Future<bool> deleteVideo(Map<String, dynamic> video) async {
    final videoId = video['id']?.toString() ?? video['_id']?.toString() ?? '';
    if (videoId.isEmpty || videoId.startsWith('vid_')) {
      removeVideo(video);
      return true;
    }

    try {
      final response = await _apiService.deleteVideo(videoId);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        allVideos.removeWhere(
          (v) => (v['id']?.toString() ?? v['_id']?.toString()) == videoId,
        );
        selectedVideos.removeWhere(
          (v) => (v['id']?.toString() ?? v['_id']?.toString()) == videoId,
        );
        if (totalVideos > 0) totalVideos--;
        totalPages = (totalVideos / pageSize).ceil();
        if (totalPages < 1) totalPages = 1;

        if (allVideos.isEmpty && currentPage > 1) {
          goToPage(currentPage - 1);
        } else {
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error calling deleteVideo API: $e");
      rethrow;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchVideos(page: 1, refresh: true);
    });
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    fetchVideos(page: 1, refresh: true);
  }

  void toggleSelectionMode() {
    isSelectionMode = !isSelectionMode;
    if (!isSelectionMode) {
      selectedVideos.clear();
    }
    notifyListeners();
  }

  void toggleVideoSelection(Map<String, dynamic> video) {
    if (selectedVideos.contains(video)) {
      selectedVideos.remove(video);
    } else {
      selectedVideos.add(video);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedVideos.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    isSelectionMode = false;
    selectedVideos.clear();
    notifyListeners();
  }
}
