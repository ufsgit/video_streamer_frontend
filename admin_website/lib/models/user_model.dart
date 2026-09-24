class UserModel {
  final String id;
  final String username;
  final String name;
  final int age;
  final String gender;
  final String dob;
  final String phone;
  final String email;
  final String status;
  final String date;
  final String streak;
  final String imageUrl;
  final String note;
  final String language;
  final int isNotificationEnabled;
  final String notificationStatus;
  final String notificationTime;

  UserModel({
    required this.id,
    this.username = '',
    required this.name,
    required this.age,
    required this.gender,
    this.dob = '',
    required this.phone,
    required this.email,
    required this.status,
    required this.date,
    required this.streak,
    required this.imageUrl,
    this.note = '',
    this.language = '',
    this.isNotificationEnabled = 0,
    this.notificationStatus = 'OFF',
    this.notificationTime = '',
  });

  bool get isNotificationActive =>
      isNotificationEnabled == 1 ||
      notificationStatus.trim().toUpperCase() == 'ON';

  String get formattedNotificationTime {
    if (notificationTime.trim().isEmpty) return 'Not set';
    try {
      final parts = notificationTime.trim().split(':');
      if (parts.isNotEmpty) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        final minuteStr = minute.toString().padLeft(2, '0');
        final hourStr = displayHour.toString().padLeft(2, '0');
        return '$hourStr:$minuteStr $period';
      }
    } catch (_) {}
    return notificationTime;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse age safely whether int or string
    int parsedAge = 0;
    if (json['age'] is int) {
      parsedAge = json['age'];
    } else if (json['age'] != null) {
      parsedAge = int.tryParse(json['age'].toString()) ?? 0;
    }

    // Parse notification fields safely
    int parsedNotificationEnabled = 0;
    if (json['is_notification_enabled'] is int) {
      parsedNotificationEnabled = json['is_notification_enabled'];
    } else if (json['is_notification_enabled'] is bool) {
      parsedNotificationEnabled = json['is_notification_enabled'] == true
          ? 1
          : 0;
    } else if (json['is_notification_enabled'] != null) {
      parsedNotificationEnabled =
          int.tryParse(json['is_notification_enabled'].toString()) ?? 0;
    }

    String parsedNotificationStatus =
        json['notification_status']?.toString().trim() ??
        (parsedNotificationEnabled == 1 ? 'ON' : 'OFF');
    if (parsedNotificationStatus.isEmpty) {
      parsedNotificationStatus = parsedNotificationEnabled == 1 ? 'ON' : 'OFF';
    }

    String parsedNotificationTime =
        json['notification_time']?.toString().trim() ??
        json['reminder_time']?.toString().trim() ??
        '';

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Patient',
      age: parsedAge,
      gender:
          json['sex']?.toString() ??
          json['gender']?.toString() ??
          'Not specified',
      dob: json['dob']?.toString() ?? '',
      phone:
          json['phone_number']?.toString() ??
          json['phone']?.toString() ??
          'N/A',
      email: json['email']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'Active',
      date:
          json['registered_date']?.toString() ??
          json['registration_date']?.toString() ??
          json['date']?.toString() ??
          '',
      streak: json['current_streak'] != null
          ? '${json['current_streak']} days'
          : (json['streak']?.toString() ??
                (json['streakDays'] != null
                    ? '${json['streakDays']} days'
                    : null) ??
                '0 days'),
      imageUrl:
          json['photo_url']?.toString() ??
          json['photo']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      note: json['note']?.toString() ?? '',
      language:
          json['language_name']?.toString() ??
          json['language']?.toString() ??
          json['languageName']?.toString() ??
          '',
      isNotificationEnabled: parsedNotificationEnabled,
      notificationStatus: parsedNotificationStatus,
      notificationTime: parsedNotificationTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'age': age,
      'sex': gender,
      'dob': dob,
      'phone_number': phone,
      'email': email,
      'status': status,
      'date': date,
      'streak': streak,
      'photo': imageUrl,
      'note': note,
      'language_name': language,
      'is_notification_enabled': isNotificationEnabled,
      'notification_status': notificationStatus,
      'notification_time': notificationTime,
    };
  }
}
