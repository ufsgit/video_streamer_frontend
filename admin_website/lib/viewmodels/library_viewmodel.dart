import 'package:flutter/material.dart';

class VideoLibraryViewModel extends ChangeNotifier {
  String searchQuery = "";
  int selectedCategoryIndex = 0;

  bool isSelectionMode = false;
  final Set<Map<String, dynamic>> selectedVideos = {};

  final List<String> categories = [
    "All",
    "Pre-op",
    "Post-op",
    "General",
  ];

  // Dynamic videos list - hardcoded videos removed
  final List<Map<String, dynamic>> allVideos = [];

  List<Map<String, dynamic>> get videos {
    return allVideos.where((video) {
      final category = (video['category'] ?? '').toString().toLowerCase();
      final matchesCategory = selectedCategoryIndex == 0 ||
          (selectedCategoryIndex == 1 && (category.contains('pre'))) ||
          (selectedCategoryIndex == 2 && (category.contains('post'))) ||
          (selectedCategoryIndex == 3 && (category.contains('gen')));

      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          (video['title'] ?? '').toString().toLowerCase().contains(query) ||
          (video['description'] ?? '').toString().toLowerCase().contains(query) ||
          (video['category'] ?? '').toString().toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void addVideo(Map<String, dynamic> video) {
    allVideos.insert(0, video);
    notifyListeners();
  }

  void removeVideo(Map<String, dynamic> video) {
    allVideos.remove(video);
    selectedVideos.remove(video);
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
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

