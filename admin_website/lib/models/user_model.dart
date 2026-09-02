class UserModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String status;
  final String date;
  final String streak;
  final String imageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    required this.status,
    required this.date,
    required this.streak,
    required this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Inactive',
      date: json['date'] ?? '',
      streak: json['streak'] ?? '0 days',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'status': status,
      'date': date,
      'streak': streak,
      'imageUrl': imageUrl,
    };
  }
}
