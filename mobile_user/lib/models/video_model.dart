// API MENTION: Video and Program models for Meridian Health app.
// Update these models when backend video streaming/progress API schema is provided.

enum VideoStatus { completed, inProgress, notStarted }

class VideoModel {
  final String id;
  final String title;
  final String programName;
  final int stepNumber;
  final int totalSteps;
  final int progressPercent;
  final String durationLeft;
  final String imageUrl; // Used only in library pre-op & post-op
  final VideoStatus status;
  final String? link;
  final String? folder;
  final String? language;
  final int? languageId;

  VideoModel({
    required this.id,
    required this.title,
    required this.programName,
    required this.stepNumber,
    required this.totalSteps,
    required this.progressPercent,
    required this.durationLeft,
    required this.imageUrl,
    required this.status,
    this.link,
    this.folder,
    this.language,
    this.languageId,
  });

  // API MENTION: Implement factory fromJson when Video List API endpoint is ready.
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    int? parsedLangId;
    if (json['language_id'] != null) {
      parsedLangId = int.tryParse(json['language_id'].toString());
    } else if (json['languageId'] != null) {
      parsedLangId = int.tryParse(json['languageId'].toString());
    }

    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      programName: json['programName'] ?? '',
      stepNumber: json['stepNumber'] ?? 1,
      totalSteps: json['totalSteps'] ?? 1,
      progressPercent: json['progressPercent'] ?? 0,
      durationLeft: json['durationLeft'] ?? '',
      imageUrl: json['imageUrl'] ?? json['thumbnail_url'] ?? json['thumbnail'] ?? '',
      link: json['link'] ?? json['video_url'] ?? json['youtube_link'] ?? json['youtubeUrl'],
      folder: json['folder'] ?? json['folder_name'] ?? json['category'],
      language: json['language']?.toString() ?? json['language_name']?.toString(),
      languageId: parsedLangId,
      status: VideoStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VideoStatus.notStarted,
      ),
    );
  }

  // API MENTION: Implement toJson for updating video watch progress via API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'programName': programName,
      'stepNumber': stepNumber,
      'totalSteps': totalSteps,
      'progressPercent': progressPercent,
      'durationLeft': durationLeft,
      'imageUrl': imageUrl,
      'status': status.name,
      'link': link,
      'folder': folder,
      'language': language,
      'language_id': languageId,
    };
  }
}
