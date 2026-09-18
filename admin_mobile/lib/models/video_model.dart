class VideoModel {
  final String id;
  final String? videoId;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String youtubeUrl;
  final String imageUrl;

  VideoModel({
    required this.id,
    this.videoId,
    required this.title,
    this.description = '',
    this.category = 'Pre-op',
    this.duration = 'Stream',
    required this.youtubeUrl,
    required this.imageUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json, {String? defaultImageUrl}) {
    final url = json['video_url']?.toString() ??
        json['url']?.toString() ??
        json['youtubeUrl']?.toString() ??
        '';

    return VideoModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      videoId: json['videoId']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Pre-op',
      duration: json['duration']?.toString() ?? 'Stream',
      youtubeUrl: url,
      imageUrl: json['imageUrl']?.toString() ??
          json['thumbnail_url']?.toString() ??
          json['thumbnail']?.toString() ??
          defaultImageUrl ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'video_url': youtubeUrl,
      'youtubeUrl': youtubeUrl,
      'thumbnail_url': imageUrl,
      'imageUrl': imageUrl,
    };
  }
}
