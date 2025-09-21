import 'package:flutter/material.dart';
import 'package:qube/models/booking.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final List<Booking> _bookings = [];
  final Set<int> _cancellingIds = {};

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
    }

    try {
      final bookings = await api.fetchBookings();
      if (!mounted) return;
      setState(() {
        _bookings
          ..clear()
          ..addAll(bookings);
        _error = null;
        _isLoading = false;
        _cancellingIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    if (booking.command_type == 'cancel') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить бронь?'),
        content: Text(
          'Вы действительно хотите отменить бронь компьютера #${booking.computer_id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final cancelKey = booking.booking_id ?? booking.computer_id;
    setState(() => _cancellingIds.add(cancelKey));

    try {
      await api.booking(booking.computer_id, 'release');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Бронь отменена')));
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка отмены: $e')));
      setState(() => _cancellingIds.remove(cancelKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QubeAppBar(title: 'Мои брони', icon: Icons.book_online),
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: () => _loadBookings(showLoader: false),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _StatusView.loading();
    }

    if (_error != null) {
      return _StatusView.error(
        title: 'Не удалось загрузить брони',
        description: _error!,
        onRetry: _loadBookings,
      );
    }

    if (_bookings.isEmpty) {
      return _StatusView.empty(
        title: 'У вас пока нет броней',
        description: 'Бронируйте компьютеры, чтобы видеть их здесь.',
        center: true,
      );
    }

    return Scrollbar(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          final cancelKey = booking.booking_id ?? booking.computer_id;
          return _BookingCard(
            booking: booking,
            isCancelling: _cancellingIds.contains(cancelKey),
            onCancel: () => _cancelBooking(booking),
          );
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final bool center;

  const _StatusView._({
    required this.icon,
    required this.title,
    this.description,
    this.onRetry,
    this.center = false,
  });

  factory _StatusView.loading() =>
      const _StatusView._(icon: Icons.hourglass_bottom, title: 'Загрузка...');

  factory _StatusView.empty({
    required String title,
    String? description,
    bool center = false,
  }) => _StatusView._(
    icon: Icons.event_busy,
    title: title,
    description: description,
    center: center,
  );

  factory _StatusView.error({
    required String title,
    String? description,
    VoidCallback? onRetry,
  }) => _StatusView._(
    icon: Icons.error_outline,
    title: title,
    description: description,
    onRetry: onRetry,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = [
      Icon(icon, size: 56, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      Text(
        title,
        style: theme.textTheme.titleLarge,
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
      if (description?.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Text(
          description!,
          style: theme.textTheme.bodyMedium,
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ],
      if (onRetry != null) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Повторить'),
        ),
      ],
      if (icon == Icons.hourglass_bottom) ...[
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator.adaptive()),
      ],
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        if (center)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: content,
          )
        else
          ...content,
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;
  final bool isCancelling;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.isCancelling,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCancel = _shouldShowCancel(booking);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TypeIcon(type: booking.command_type),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Бронь PC #${booking.computer_id}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (booking.booking_id != null)
                  _Chip(text: '#${booking.booking_id}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Создано', value: _formatDate(booking.created_at)),
            if (showCancel) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_schedule_send),
                    label: Text(isCancelling ? 'Отмена...' : 'Отменить бронь'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _shouldShowCancel(Booking booking) =>
      booking.command_type != 'cancel';

  static String _formatDate(DateTime dateTime) {
    final d = dateTime.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final (IconData, Color, Color) data;
    switch (type) {
      case 'book':
        data = (
          Icons.schedule_send,
          scheme.primary,
          scheme.errorContainer.withAlpha(64), // 0.25 * 255 ≈ 64
        );
        break;
      case 'cancel':
        data = (
          Icons.cancel,
          scheme.error,
          scheme.errorContainer.withAlpha(64), // 0.25 * 255 ≈ 64
        );
        break;
      default:
        data = (
          Icons.info_outline,
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
        );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: data.$3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(data.$1, color: data.$2),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withAlpha(102)),
      ),
      child: Text(text, style: theme.textTheme.labelMedium),
    );
  }
}
