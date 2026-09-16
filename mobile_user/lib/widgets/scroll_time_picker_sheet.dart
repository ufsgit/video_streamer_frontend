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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
  late FixedExtentScrollController _periodController;

  @override
  void initState() {
    super.initState();
    _hour12 = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _minute = widget.initialTime.minute;
    _period = widget.initialTime.period;

    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _periodController = FixedExtentScrollController(
      initialItem: _period == DayPeriod.am ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  TimeOfDay _getResultTime() {
    int hour24 = _hour12 % 12;
    if (_period == DayPeriod.pm) {
      hour24 += 12;
    }
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 290,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
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
                      ),
                    ),
                  ),
                  const Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _getResultTime()),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF0052CC),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours Wheel (1-12)
                      SizedBox(
                        width: 70,
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
                            return Center(
                              child: Text(
                                h.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _hour12 == h
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Minutes Wheel (00-59)
                      SizedBox(
                        width: 70,
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
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _minute == index
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // AM / PM Wheel (independent - will NOT flip when scrolling hours)
                      SizedBox(
                        width: 70,
                        child: CupertinoPicker(
                          scrollController: _periodController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _period =
                                  index == 0 ? DayPeriod.am : DayPeriod.pm;
                            });
                          },
                          children: [
                            Center(
                              child: Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _period == DayPeriod.am
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                'PM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _period == DayPeriod.pm
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
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
