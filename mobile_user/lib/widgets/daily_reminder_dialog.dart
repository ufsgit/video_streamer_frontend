import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'scroll_time_picker_sheet.dart';

class DailyReminderDialog extends StatefulWidget {
  const DailyReminderDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final service = NotificationService.instance;

    // Check if time has not been set yet
    final bool needsTime = !service.isTimeSet;
    if (!needsTime) {
      return;
    }

    // Mark as prompted for this session
    await service.markInitialReminderPrompted();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DailyReminderDialog(),
    );
  }

  // Alias for backward compatibility
  static Future<void> showIfFirstLaunch(BuildContext context) =>
      showIfNeeded(context);

  @override
  State<DailyReminderDialog> createState() => _DailyReminderDialogState();
}

class _DailyReminderDialogState extends State<DailyReminderDialog> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM default
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = NotificationService.instance.getReminderTime();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await ScrollTimePickerSheet.show(
      context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _enableReminder() async {
    setState(() => _isLoading = true);
    final service = NotificationService.instance;

    String summary = '';
    try {
      // Request system permission
      await service.requestPermissions();

      // Schedule reminder and persist time
      summary = await service.scheduleDailyReminder(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        persist: true,
      );
      await service.markTimeAsSet();
    } catch (e) {
      debugPrint('Error enabling reminder: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0052CC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary.isNotEmpty
                        ? 'Reminder scheduled: $summary'
                        : 'Daily reminder set for ${_formatTime(_selectedTime)}!',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _onMaybeLater() async {
    final service = NotificationService.instance;
    await service.markInitialReminderPrompted();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Illustration Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0EAFF), Color(0xFFC7D7FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF0052CC),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),

          // Title
          const Text(
            'Daily Video Reminder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Choose your preferred daily time to receive a reminder to watch your assigned health videos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Time Picker Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD0D5DD), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFF0052CC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Time',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(_selectedTime),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052CC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'You can change this or turn it off anytime in Profile Settings.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enableReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Reminder Time',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _isLoading ? null : _onMaybeLater,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
