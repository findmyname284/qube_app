import 'package:flutter/material.dart';
import 'package:qube/models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;
  final bool isCancelling;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
    required this.isCancelling,
  });

  Color _statusColor() {
    switch (booking.commandType) {
      case 'book':
        return const Color(0xFF00B894);
      case 'cancel':
        return const Color(0xFFFF7676);
      default:
        return const Color(0xFFFFC048);
    }
  }

  String _title() => 'Бронь PC #${booking.computerId}';

  String _formatShort(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year % 100} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final color = _statusColor();
        final isCompact = constraints.maxWidth < 470;

        final idChip = (booking.bookingId != null)
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Text(
                  '#${booking.bookingId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              )
            : null;

        final cancelBtn = (booking.commandType != 'cancel')
            ? SizedBox(
                height: 40,
                width: isCompact ? double.infinity : null,
                child: ElevatedButton.icon(
                  onPressed: isCancelling ? null : onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7676),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: isCancelling
                        ? const SizedBox(
                            key: ValueKey('prog'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.cancel_schedule_send,
                            key: ValueKey('icon'),
                          ),
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      isCancelling ? 'Отмена...' : 'Отменить',
                      key: ValueKey(isCancelling),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              )
            : null;

        final turnOnButton = SizedBox(
          height: 40,
          width: isCompact ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement turn on computer functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 139, 14),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.power_settings_new_outlined,
              key: ValueKey('icon'),
            ),
            label: const Text(
              'Включить',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO: Implement booking details
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F2E).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // статус-иконка
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      booking.commandType == 'cancel'
                          ? Icons.cancel
                          : Icons.schedule_send,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // контент
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // верхняя строка: заголовок + (опц.) чип
                        if (!isCompact)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _title(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (idChip != null) idChip,
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (idChip != null) idChip,
                            ],
                          ),

                        const SizedBox(height: 8),

                        // дата
                        Row(
                          children: [
                            const Text(
                              'Создано:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatShort(booking.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Начало:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatShort(booking.start),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Конец:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatShort(booking.end),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // кнопка для compact
                        if (isCompact) ...[
                          const SizedBox(height: 12),
                          if (cancelBtn != null) cancelBtn,
                          const SizedBox(height: 12),
                          turnOnButton,
                        ],
                      ],
                    ),
                  ),

                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    if (cancelBtn != null) cancelBtn,
                    const SizedBox(width: 12),
                    turnOnButton,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
