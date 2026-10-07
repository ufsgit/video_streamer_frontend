import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/error_utils.dart';

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
  static const int pageSize = 15;
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
    currentPage = refresh ? 1 : page;
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
          totalVideos = _extractTotal(resData);
          rawList = _extractList(resData);
        } else if (resData is List) {
          rawList = resData;
          totalVideos = rawList.length;
        }

        allVideos = rawList
            .whereType<Map<String, dynamic>>()
            .map(_mapVideoItem)
            .toList();

        _updateTotalPages();
      }
    } catch (e) {
      debugPrint("Error fetching videos from API: $e");
      errorMessage =
          ErrorUtils.format(e, fallback: "Server error. Please try again.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _mapVideoItem(Map<String, dynamic> item) {
    final url = item['video_url']?.toString() ??
        item['url']?.toString() ??
        item['youtubeUrl']?.toString() ??
        '';
    final ytId = extractYoutubeId(url);
    final thumbUrl = _resolveThumbnail(item, ytId);

    return {
      'id': item['id']?.toString() ??
          item['_id']?.toString() ??
          'vid_${allVideos.length}',
      'videoId': ytId,
      'title': item['title']?.toString() ?? 'Untitled Video',
      'description': item['description']?.toString() ?? '',
      'category': item['category']?.toString() ?? 'Pre-op',
      'language': item['language']?.toString() ??
          item['language_name']?.toString() ??
          '',
      'language_id': item['language_id'] ?? item['languageId'],
      'duration': item['duration']?.toString() ?? 'Stream',
      'total_duration_seconds':
          item['total_duration_seconds'] ?? item['duration_seconds'],
      'youtubeUrl': url,
      'imageUrl': thumbUrl,
      'thumbnail_url': thumbUrl,
      'thumbnail': thumbUrl,
    };
  }

  String _resolveThumbnail(Map<String, dynamic> item, String? ytId) {
    final rawApiThumb = item['thumbnail_url'] ??
        item['thumbnail'] ??
        item['thumbnailUrl'] ??
        item['image_url'] ??
        item['imageUrl'] ??
        item['image'] ??
        item['thumbnail_path'];

    if (rawApiThumb != null && rawApiThumb.toString().trim().isNotEmpty) {
      return _apiService.getFullImageUrl(rawApiThumb.toString().trim());
    } else if (ytId != null && ytId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    return 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60';
  }

  int _extractTotal(Map<String, dynamic> data) {
    final total = data['total'] ??
        data['totalCount'] ??
        data['count'] ??
        (data['pagination'] is Map ? data['pagination']['total'] : null) ??
        (data['meta'] is Map ? data['meta']['total'] : null) ??
        (data['data'] is Map
            ? (data['data']['total'] ??
                data['data']['totalCount'] ??
                data['data']['count'])
            : null);
    if (total is num) return total.toInt();
    if (total is String) return int.tryParse(total) ?? 0;
    return 0;
  }

  List<dynamic> _extractList(Map<String, dynamic> data) {
    if (data['data'] is List) return data['data'] as List;
    if (data['data'] is Map && data['data']['videos'] is List) {
      return data['data']['videos'] as List;
    }
    if (data['videos'] is List) return data['videos'] as List;
    if (data['results'] is List) return data['results'] as List;
    return [];
  }

  void _updateTotalPages() {
    if (totalVideos <= 0) {
      totalVideos = (currentPage - 1) * pageSize + allVideos.length;
      totalPages =
          (allVideos.length == pageSize) ? currentPage + 1 : currentPage;
    } else {
      totalPages = (totalVideos / pageSize).ceil();
      if (totalPages < 1) totalPages = 1;
    }
  }

  List<Map<String, dynamic>> get videos => allVideos;

  void addVideo(Map<String, dynamic> video) {
    allVideos.insert(0, video);
    totalVideos++;
    _updateTotalPages();
    notifyListeners();
  }

  void removeVideo(Map<String, dynamic> video) {
    final videoId = video['id']?.toString() ?? video['_id']?.toString();
    allVideos.removeWhere(
      (v) =>
          v == video ||
          (videoId != null &&
              (v['id']?.toString() ?? v['_id']?.toString()) == videoId),
    );
    selectedVideos.removeWhere(
      (v) =>
          v == video ||
          (videoId != null &&
              (v['id']?.toString() ?? v['_id']?.toString()) == videoId),
    );
    if (totalVideos > 0) totalVideos--;
    _updateTotalPages();
    notifyListeners();
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
        removeVideo(video);
        if (allVideos.isEmpty && currentPage > 1) {
          goToPage(currentPage - 1);
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
    clearSelection();
  }
}
