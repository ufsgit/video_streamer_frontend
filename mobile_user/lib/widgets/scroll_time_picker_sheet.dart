import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const ScrollTimePickerSheet({super.key, required this.initialTime});

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ScrollTimePickerSheet(initialTime: initialTime),
    );
  }

  @override
  State<ScrollTimePickerSheet> createState() => _ScrollTimePickerSheetState();
}

class _ScrollTimePickerSheetState extends State<ScrollTimePickerSheet> {
  late int _hour12;
  late int _minute;
  late DayPeriod _period;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    // 12-hour format: 1 through 12
    _hour12 = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _minute = widget.initialTime.minute;
    _period = widget.initialTime.period;

    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// Converts the 12-hour + AM/PM selection into a 24-hour TimeOfDay (0-23)
  TimeOfDay _getResultTime() {
    int hour24;
    if (_period == DayPeriod.am) {
      // 12 AM is 00:xx, 1 AM - 11 AM is 01:xx - 11:xx
      hour24 = (_hour12 == 12) ? 0 : _hour12;
    } else {
      // 12 PM is 12:xx, 1 PM - 11 PM is 13:xx - 23:xx
      hour24 = (_hour12 == 12) ? 12 : _hour12 + 12;
    }
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  String get _formattedPreview {
    final periodStr = _period == DayPeriod.am ? 'AM' : 'PM';
    return '${_hour12.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $periodStr';
  }

  Widget _buildPeriodButton(DayPeriod period, String label) {
    final isSelected = _period == period;
    return InkWell(
      onTap: () {
        if (_period != period) {
          setState(() {
            _period = period;
          });
        }
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0052CC).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            // Header with Cancel, Live Time Badge, and Done button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formattedPreview,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0052CC),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _getResultTime()),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF0052CC),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Wheels & AM/PM Selector
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center selection highlight band
                  Container(
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours Wheel (01 - 12)
                      SizedBox(
                        width: 72,
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _hour12 = (index % 12) + 1;
                            });
                          },
                          children: List.generate(12, (index) {
                            final h = index + 1;
                            final isCur = _hour12 == h;
                            return Center(
                              child: Text(
                                h.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: isCur
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),

                      // Minutes Wheel (00 - 59)
                      SizedBox(
                        width: 72,
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _minute = index % 60;
                            });
                          },
                          children: List.generate(60, (index) {
                            final isCur = _minute == index;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: isCur
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(width: 18),

                      // AM / PM Segmented Selector
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPeriodButton(DayPeriod.am, 'AM'),
                            const SizedBox(height: 3),
                            _buildPeriodButton(DayPeriod.pm, 'PM'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
