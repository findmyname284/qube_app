import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/computers/utils/booking_utils.dart';
import 'package:qube/widgets/time_picker_clock.dart';

Future<DateTime?> showTimePickerSheet(
  BuildContext context,
  Computer comp,
) async {
  try {
    final List<TimeSlot> busy = await fetchBookedIntervals(comp);

    return await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: RealtimeClockBooking(
            busy: busy,
            minuteStep: const Duration(minutes: 15),
            clockSize: 250,
            maxStartAhead: const Duration(hours: 12),
            onConfirm: (startUtc) => Navigator.of(sheetCtx).pop(startUtc),
          ),
        );
      },
    );
  } catch (e) {
    return null;
  }
}
