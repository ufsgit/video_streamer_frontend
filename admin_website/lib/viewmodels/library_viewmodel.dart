import 'package:flutter/material.dart';

class VideoLibraryViewModel extends ChangeNotifier {
  String searchQuery = "";
  int selectedCategoryIndex = 0;

  final List<String> categories = [
    "All",
    "Pre-op",
    "Post-op",
  ];

  final List<Map<String, dynamic>> allVideos = [
    {
      "title": "Pre-Operative Knee Conditioning Protocol",
      "description": "Essential exercises to build strength and improve mobility prior to knee surgery.",
      "category": "Pre-op",
      "duration": "12:45",
      "imageUrl": "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Anxiety Management Before Procedures",
      "description": "Guided breathing techniques and cognitive framing strategies to reduce pre-surgery stress.",
      "category": "Pre-op",
      "duration": "08:20",
      "imageUrl": "https://images.unsplash.com/photo-1551076805-e1869033e561?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Patient Positioning & Bed Mobility Safety",
      "description": "Comprehensive guide on safe transfers, turning techniques, and post-surgery care.",
      "category": "Post-op",
      "duration": "15:10",
      "imageUrl": "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Post-ACL Mobility & Gentle Flow",
      "description": "Guided rehabilitation routines for progressive knee recovery and flexibility.",
      "category": "Post-op",
      "duration": "14:30",
      "imageUrl": "https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Scapular Stabilization Exercises",
      "description": "Targeted shoulder blade mobility and posture stabilization drills.",
      "category": "Post-op",
      "duration": "10:15",
      "imageUrl": "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=500&q=60",
    },
  ];

  List<Map<String, dynamic>> get videos {
    return allVideos.where((video) {
      final category = video['category'].toString().toLowerCase();
      final matchesCategory = selectedCategoryIndex == 0 ||
          (selectedCategoryIndex == 1 && (category.contains('pre'))) ||
          (selectedCategoryIndex == 2 && (category.contains('post')));

      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          video['title'].toString().toLowerCase().contains(query) ||
          video['description'].toString().toLowerCase().contains(query) ||
          video['category'].toString().toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }
}
