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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse age safely whether int or string
    int parsedAge = 0;
    if (json['age'] is int) {
      parsedAge = json['age'];
    } else if (json['age'] != null) {
      parsedAge = int.tryParse(json['age'].toString()) ?? 0;
    }

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Patient',
      age: parsedAge,
      gender: json['sex']?.toString() ??
          json['gender']?.toString() ??
          'Not specified',
      dob: json['dob']?.toString() ?? '',
      phone: json['phone_number']?.toString() ??
          json['phone']?.toString() ??
          'N/A',
      email: json['email']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'Active',
      date: json['date']?.toString() ??
          json['memberSince']?.toString() ??
          json['createdAt']?.toString() ??
          json['registeredAt']?.toString() ??
          '',
      streak: json['streak']?.toString() ??
          (json['streakDays'] != null ? '${json['streakDays']} days' : null) ??
          '0 days',
      imageUrl: json['photo']?.toString() ??
          json['imageUrl']?.toString() ??
          json['avatar']?.toString() ??
          '',
      note: json['note']?.toString() ?? '',
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
    };
  }
}
