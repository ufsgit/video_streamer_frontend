import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../repositories/video_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final VideoRepository _videoRepository;

  LibraryViewModel({VideoRepository? videoRepository})
      : _videoRepository = videoRepository ?? VideoRepositoryImpl();

  bool _isLoading = false;
  String _selectedCategory = 'Pre-op';
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<VideoModel> _preOpVideos = [];
  List<VideoModel> _postOpVideos = [];

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  List<VideoModel> get preOpVideos => _preOpVideos;
  List<VideoModel> get postOpVideos => _postOpVideos;

  List<VideoModel> get currentCategoryVideos =>
      _selectedCategory == 'Pre-op' ? _preOpVideos : _postOpVideos;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchCategoryVideos() async {
    _isLoading = true;
    notifyListeners();

    final preOp = await _videoRepository.getPreOpLibraryVideos();
    final postOp = await _videoRepository.getPostOpLibraryVideos();

    _preOpVideos = preOp;
    _postOpVideos = postOp;
    _isLoading = false;
    notifyListeners();
  }
}
