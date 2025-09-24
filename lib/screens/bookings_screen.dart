import 'package:flutter/material.dart';
import 'package:qube/models/booking.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final List<Booking> _bookings = [];
  final Set<String> _cancellingIds = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {}

    try {
      final bookings = await api.fetchBookings();
      if (!mounted) return;
      setState(() {
        _bookings
          ..clear()
          ..addAll(bookings);
        _error = null;
        _cancellingIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    if (booking.command_type == 'cancel') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7676),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Отменить бронь?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Вы действительно хотите отменить бронь компьютера #${booking.computer_id}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final cancelKey = booking.booking_id ?? booking.computer_id.toString();
    setState(() => _cancellingIds.add(cancelKey));

    try {
      await api.booking(booking.computer_id, 'release');
      if (!mounted) return;
      AppSnack.show(
        context,
        message: 'Бронь отменена',
        type: AppSnackType.success,
      );
      await _loadBookings(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: 'Ошибка отмены: $e',
        type: AppSnackType.error,
      );
      setState(() => _cancellingIds.remove(cancelKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: 'Мои брони',
        icon: Icons.book_online,
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(2.5),
        //   child: AnimatedContainer(
        //     duration: const Duration(milliseconds: 250),
        //     height: _isRefreshing ? 2.5 : 0,
        //     child: _isRefreshing
        //         ? const LinearProgressIndicator(
        //             backgroundColor: Colors.transparent, minHeight: 2.5)
        //         : const SizedBox.shrink(),
        //   ),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBookings(showLoader: false),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // единый фон в стиле всего приложения
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _loadBookings(showLoader: false),
            color: Colors.white,
            backgroundColor: const Color(0xFF6C5CE7),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const _ListSkeleton();

    if (_error != null) {
      return _StatusView.error(
        title: 'Не удалось загрузить брони',
        description: _error!,
        onRetry: () => _loadBookings(showLoader: true),
      );
    }

    if (_bookings.isEmpty) {
      return const _StatusView.empty(
        title: 'У вас пока нет броней',
        description: 'Бронируйте компьютеры, чтобы видеть их здесь.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + kBottomNavigationBarHeight,
      ),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final cancelKey = booking.booking_id ?? booking.computer_id.toString();
        return _BookingCard(
          key: ValueKey(
            booking.booking_id ??
                'pc-${booking.computer_id}-${booking.command_type}-${booking.created_at.microsecondsSinceEpoch}',
          ),
          booking: booking,
          isCancelling: _cancellingIds.contains(cancelKey),
          onCancel: () => _cancelBooking(booking),
        );
      },
    );
  }
}

// ======== STATES (loading/empty/error) ========

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const _StatusView._({
    required this.icon,
    required this.title,
    this.description,
    this.onRetry,
  });

  const _StatusView.empty({required String title, String? description})
    : this._(icon: Icons.event_busy, title: title, description: description);

  const _StatusView.error({
    required String title,
    String? description,
    VoidCallback? onRetry,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         description: description,
         onRetry: onRetry,
       );

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F2E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 56, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
              if (icon == Icons.hourglass_bottom) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: Colors.white70),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ======== LIST SKELETON (первичная загрузка) ========

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => const _BookingCardSkeleton(),
    );
  }
}

class _BookingCardSkeleton extends StatelessWidget {
  const _BookingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _skelLine(0.7, 16),
                const SizedBox(height: 8),
                _skelLine(0.4, 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _skelPill(56, 24),
        ],
      ),
    );
  }

  Widget _skelLine(double widthFactor, double height) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  Widget _skelPill(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

// ======== BOOKING CARD ========

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;
  final bool isCancelling;

  const _BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
    required this.isCancelling,
  });

  Color _statusColor() {
    switch (booking.command_type) {
      case 'book':
        return const Color(0xFF00B894); // зелёный
      case 'cancel':
        return const Color(0xFFFF7676); // красный
      default:
        return const Color(0xFFFFC048); // янтарный
    }
  }

  String _title() => 'Бронь PC #${booking.computer_id}';
  String _createdShort() {
    final d = booking.created_at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    // короткий формат: 24.09.25 13:42
    return '${two(d.day)}.${two(d.month)}.${d.year % 100} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final color = _statusColor();
        final isCompact = c.maxWidth < 360; // переключатель компоновки

        final idChip = (booking.booking_id != null)
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20), // 0.08 * 255 ≈ 20
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                  ), // 0.08 * 255 ≈ 20
                ),
                child: Text(
                  '#${booking.booking_id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              )
            : null;

        final cancelBtn = (booking.command_type != 'cancel')
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
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
                      booking.command_type == 'cancel'
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

                        // дата одной строкой
                        Row(
                          children: [
                            Text(
                              'Создано:',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _createdShort(),
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

                        // кнопка
                        if (isCompact) ...[
                          const SizedBox(height: 12),
                          cancelBtn ?? const SizedBox.shrink(),
                        ],
                      ],
                    ),
                  ),

                  // кнопка справа — только если хватает места
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    cancelBtn ?? const SizedBox.shrink(),
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
