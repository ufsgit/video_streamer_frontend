class BroadcastNotification {
  final int? id;
  final int? adminId;
  final String title;
  final String message;
  final String scheduleTime;
  final int isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BroadcastNotification({
    this.id,
    this.adminId,
    required this.title,
    required this.message,
    required this.scheduleTime,
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory BroadcastNotification.fromJson(Map<String, dynamic> json) {
    return BroadcastNotification(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? ''),
      adminId: json['admin_id'] is num
          ? (json['admin_id'] as num).toInt()
          : int.tryParse(json['admin_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      scheduleTime: json['schedule_time']?.toString() ?? '',
      isActive: json['is_active'] is num
          ? (json['is_active'] as num).toInt()
          : (json['is_active'] == true ? 1 : 0),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'schedule_time': scheduleTime,
      };

  String get formattedScheduleTime {
    if (scheduleTime.trim().isEmpty) return 'Not scheduled';
    final parts = scheduleTime.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
    return scheduleTime;
  }
}
