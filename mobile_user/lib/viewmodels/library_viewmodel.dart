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

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _limit = 10;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> fetchDynamicCategoryVideos(String category, {int? languageId}) async {
    _isLoading = true;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    final videos = await _videoRepository.getVideosByCategory(
      category: category,
      languageId: languageId,
      page: _currentPage,
      limit: _limit,
    );

    if (videos.length < _limit) {
      _hasMore = false;
    }

    if (category.toLowerCase().contains('pre')) {
      _preOpVideos = videos;
    } else {
      _postOpVideos = videos;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreCategoryVideos(String category, {int? languageId}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    final videos = await _videoRepository.getVideosByCategory(
      category: category,
      languageId: languageId,
      page: _currentPage,
      limit: _limit,
    );

    if (videos.length < _limit) {
      _hasMore = false;
    }

    if (category.toLowerCase().contains('pre')) {
      _preOpVideos.addAll(videos);
    } else {
      _postOpVideos.addAll(videos);
    }

    _isLoadingMore = false;
    notifyListeners();
  }
}
