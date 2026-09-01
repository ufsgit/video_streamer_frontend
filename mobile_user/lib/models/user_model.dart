// API MENTION: User model structure for Meridian Health app.
// Update these fields when the backend API user schema is finalized.

class UserModel {
  final String id;
  final String name;
  final String email;
  final String memberSince;
  final bool isVerified;
  final String platformTime;
  final int videosDone;
  final int streakDays;
  final DoctorModel doctor;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.memberSince,
    required this.isVerified,
    required this.platformTime,
    required this.videosDone,
    required this.streakDays,
    required this.doctor,
  });

  // API MENTION: Implement factory fromJson when User API endpoint is ready.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      memberSince: json['memberSince'] ?? '',
      isVerified: json['isVerified'] ?? false,
      platformTime: json['platformTime'] ?? '',
      videosDone: json['videosDone'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      doctor: DoctorModel.fromJson(json['doctor'] ?? {}),
    );
  }

  // API MENTION: Implement toJson for updating user profile via API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'memberSince': memberSince,
      'isVerified': isVerified,
      'platformTime': platformTime,
      'videosDone': videosDone,
      'streakDays': streakDays,
      'doctor': doctor.toJson(),
    };
  }
}

class DoctorModel {
  final String id;
  final String name;
  final String title;

  DoctorModel({
    required this.id,
    required this.name,
    required this.title,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
    };
  }
}
