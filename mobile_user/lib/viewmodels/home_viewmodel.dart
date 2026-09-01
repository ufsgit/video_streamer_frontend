import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../repositories/video_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final VideoRepository _videoRepository;

  HomeViewModel({VideoRepository? videoRepository})
      : _videoRepository = videoRepository ?? VideoRepositoryImpl();

  bool _isLoading = false;
  String _searchQuery = '';
  VideoModel? _continueWatchingVideo;
  List<VideoModel> _completedVideos = [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  VideoModel? get continueWatchingVideo => _continueWatchingVideo;
  List<VideoModel> get completedVideos => _completedVideos;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    final continueVideo = await _videoRepository.getContinueWatchingVideo();
    final completed = await _videoRepository.getCompletedVideos();

    _continueWatchingVideo = continueVideo;
    _completedVideos = completed;
    _isLoading = false;
    notifyListeners();
  }
}
