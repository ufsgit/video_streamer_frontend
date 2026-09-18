import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../widgets/scroll_time_picker_sheet.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final NotificationService _notificationService = NotificationService.instance;

  late bool _isReminderEnabled;
  late TimeOfDay _reminderTime;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isReminderEnabled = _notificationService.isReminderEnabled;
    _reminderTime = _notificationService.getReminderTime();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _toggleReminder(bool value) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _isReminderEnabled = value;
    });

    try {
      if (value) {
        // If time was not explicitly chosen yet, prompt user with the time picker
        if (!_notificationService.isTimeSet) {
          final picked = await ScrollTimePickerSheet.show(
            context,
            initialTime: _reminderTime,
          );
          if (picked != null) {
            _reminderTime = picked;
          }
        }

        await _notificationService.requestPermissions();
        await _notificationService.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          persist: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0052CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                'Daily reminders enabled for ${_formatTime(_reminderTime)}',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          );
        }
      } else {
        await _notificationService.cancelDailyReminder(persist: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF667085),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              content: Text(
                'Daily reminders turned off',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling reminder: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await ScrollTimePickerSheet.show(
      context,
      initialTime: _reminderTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
      });

      if (_isReminderEnabled) {
        await _notificationService.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
          persist: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0052CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                'Reminder time updated to ${_formatTime(picked)}',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF101828),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEAECF0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'VIDEO REMINDERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF667085),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Main Settings Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Toggle Switch Tile (clickable entire row)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleReminder(!_isReminderEnabled),
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(20),
                        bottom: Radius.circular(_isReminderEnabled ? 0 : 20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0052CC,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Color(0xFF0052CC),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Reminders',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF101828),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Receive a daily prompt to watch videos',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isReminderEnabled,
                              activeTrackColor: const Color(0xFF0052CC),
                              activeThumbColor: Colors.white,
                              onChanged: _toggleReminder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_isReminderEnabled) ...[
                    const Divider(height: 1, color: Color(0xFFF2F4F7)),
                    // Time Picker Tile
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5B67F6,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFF5B67F6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reminder Time',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tap to change reminder time',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF667085),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0052CC,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(_reminderTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0052CC),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: Color(0xFF0052CC),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tip / Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF0052CC),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Daily reminders help you build a habit of completing assigned physical therapy and educational videos consistently.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test Notification Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _notificationService.showTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF12B76A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: const Text(
                          'Test notification sent! Check your notification tray.',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0052CC),
                  side: const BorderSide(color: Color(0xFF0052CC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text(
                  'Send Test Notification',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
