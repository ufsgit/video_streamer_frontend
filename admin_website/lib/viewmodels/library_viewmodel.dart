import 'package:flutter/material.dart';

class VideoLibraryViewModel extends ChangeNotifier {
  String searchQuery = "";
  int selectedCategoryIndex = 0;

  final List<String> categories = [
    "Preparation & Readiness",
    "Recovery & Rehabilitation",
  ];

  final List<Map<String, dynamic>> videos = [
    {
      "title": "Pre-Operative Knee Conditioning Protocol",
      "description": "Essential exercises to build strength and improve mobility prior to knee...",
      "category": "Orthopedics",
      "duration": "12:45",
      "imageUrl": "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Anxiety Management Before Procedures",
      "description": "Guided breathing techniques and cognitive framing strategies to redu...",
      "category": "Wellness",
      "duration": "08:20",
      "imageUrl": "https://images.unsplash.com/photo-1551076805-e1869033e561?auto=format&fit=crop&w=500&q=60",
    },
    {
      "title": "Patient Positioning & Bed Mobility Safety",
      "description": "Comprehensive guide for caregivers on safe transfers, turning technique...",
      "category": "Caregiver Guide",
      "duration": "15:10",
      "imageUrl": "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=500&q=60",
    }
  ];

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }
}
