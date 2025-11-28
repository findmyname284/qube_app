import 'package:flutter/material.dart';
import 'package:qube/screens/bookings/booking_controller.dart';
import 'package:qube/screens/bookings/widgets/booking_card.dart';
import 'package:qube/screens/bookings/widgets/skeletons/booking_list_skeleton.dart';
import 'package:qube/screens/bookings/widgets/status_views.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingController _controller = BookingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.loadBookings(showLoader: true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _cancelBooking(BookingControllerState state, int index) async {
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
          'Вы действительно хотите отменить бронь компьютера #${state.bookings[index].computerId}?',
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

    final result = await _controller.cancelBooking(index);

    if (!mounted) return;

    if (result.isSuccess) {
      AppSnack.show(
        context,
        message: 'Бронь отменена',
        type: AppSnackType.success,
      );
    } else {
      AppSnack.show(
        context,
        message: 'Ошибка отмены: ${result.error}',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: 'Мои брони',
        icon: Icons.book_online,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadBookings(showLoader: false),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _controller.loadBookings(showLoader: false),
            color: Colors.white,
            backgroundColor: const Color(0xFF6C5CE7),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildBody(state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BookingControllerState state) {
    if (state.isLoading) return const BookingListSkeleton();

    if (state.error != null) {
      return StatusView.error(
        title: 'Не удалось загрузить брони',
        description: state.error!,
        onRetry: () => _controller.loadBookings(showLoader: true),
      );
    }

    if (state.bookings.isEmpty) {
      return const StatusView.empty(
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
      itemCount: state.bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = state.bookings[index];
        final isCancelling = state.cancellingIds.contains(
          booking.bookingId ?? booking.computerId.toString(),
        );

        return BookingCard(
          key: ValueKey(
            booking.bookingId ??
                'pc-${booking.computerId}-${booking.commandType}-${booking.createdAt.microsecondsSinceEpoch}',
          ),
          booking: booking,
          isCancelling: isCancelling,
          onCancel: () => _cancelBooking(state, index),
        );
      },
    );
  }
}
