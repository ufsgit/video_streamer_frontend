// API MENTION: User model structure for Meridian Health app.
// Update these fields when the backend API user schema is finalized.

class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? registeredDate;
  final bool isVerified;
  final int totalTimeOnPlatformSeconds;
  final int totalVideoDone;
  final int currentStreak;
  final String? doctorName;
  final List<String>? languages;
  final String? dateOfBirth;
  final int? age;
  final String? sex;
  final String? phoneNumber;
  final int? languageId;
  final String? languageName;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.registeredDate,
    this.isVerified = true,
    this.totalTimeOnPlatformSeconds = 0,
    this.totalVideoDone = 0,
    this.currentStreak = 0,
    this.doctorName,
    this.languages,
    this.dateOfBirth,
    this.age,
    this.sex,
    this.phoneNumber,
    this.languageId,
    this.languageName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawLangId = json['language_id'] ?? json['languageId'];
    final int? parsedLangId = rawLangId != null ? int.tryParse(rawLangId.toString()) : null;

    String? parsedLangName;
    if (json['language_name'] != null) {
      parsedLangName = json['language_name'].toString();
    } else if (json['languageName'] != null) {
      parsedLangName = json['languageName'].toString();
    } else if (json['language'] is String) {
      parsedLangName = json['language'];
    } else if (json['language'] is Map) {
      parsedLangName = (json['language']['name'] ??
              json['language']['language_name'] ??
              json['language']['title'])
          ?.toString();
    }
    if (parsedLangName != null) {
      final s = parsedLangName.trim();
      if (s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'none') {
        parsedLangName = null;
      }
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      registeredDate: json['registered_date'],
      totalTimeOnPlatformSeconds: json['total_time_on_platform_seconds'] ?? 0,
      totalVideoDone: json['total_video_done'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      doctorName: json['doctor_name'],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      sex: json['sex'],
      phoneNumber: json['phone_number'],
      languageId: parsedLangId,
      languageName: parsedLangName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'registered_date': registeredDate,
      'is_verified': isVerified,
      'total_time_on_platform_seconds': totalTimeOnPlatformSeconds,
      'total_video_done': totalVideoDone,
      'current_streak': currentStreak,
      'doctor_name': doctorName,
      'languages': languages,
      'date_of_birth': dateOfBirth,
      'age': age,
      'sex': sex,
      'phone_number': phoneNumber,
      'language_id': languageId,
      'language_name': languageName,
    };
  }
}
