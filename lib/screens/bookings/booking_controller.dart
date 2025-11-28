import 'package:flutter/material.dart';
import 'package:qube/models/booking.dart';
import 'package:qube/services/api_service.dart';

final api = ApiService.instance;

class BookingControllerState {
  final List<Booking> bookings;
  final Set<String> cancellingIds;
  final bool isLoading;
  final String? error;

  const BookingControllerState({
    required this.bookings,
    required this.cancellingIds,
    required this.isLoading,
    this.error,
  });

  BookingControllerState copyWith({
    List<Booking>? bookings,
    Set<String>? cancellingIds,
    bool? isLoading,
    String? error,
  }) {
    return BookingControllerState(
      bookings: bookings ?? this.bookings,
      cancellingIds: cancellingIds ?? this.cancellingIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CancelBookingResult {
  final bool isSuccess;
  final String? error;

  const CancelBookingResult({required this.isSuccess, this.error});
}

class BookingController extends ChangeNotifier {
  BookingControllerState _state = const BookingControllerState(
    bookings: [],
    cancellingIds: {},
    isLoading: true,
  );

  BookingControllerState get state => _state;

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> loadBookings({bool showLoader = true}) async {
    if (showLoader) {
      _updateState(_state.copyWith(isLoading: true, error: null));
    }

    try {
      final bookings = await api.fetchBookings();
      _updateState(
        _state.copyWith(
          bookings: bookings,
          cancellingIds: {},
          error: null,
          isLoading: false,
        ),
      );
    } catch (e) {
      _updateState(_state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<CancelBookingResult> cancelBooking(int index) async {
    if (index < 0 || index >= _state.bookings.length) {
      return const CancelBookingResult(
        isSuccess: false,
        error: 'Invalid booking index',
      );
    }

    final booking = _state.bookings[index];
    if (booking.commandType == 'cancel') {
      return const CancelBookingResult(
        isSuccess: false,
        error: 'Booking already cancelled',
      );
    }

    final cancelKey = booking.bookingId ?? booking.computerId.toString();

    // Add to cancelling set
    final newCancellingIds = Set<String>.from(_state.cancellingIds);
    newCancellingIds.add(cancelKey);
    _updateState(_state.copyWith(cancellingIds: newCancellingIds));

    // If bookingId is missing
    if (booking.bookingId == null) {
      final errorResult = CancelBookingResult(
        isSuccess: false,
        error: 'Невозможно отменить — отсутствует идентификатор брони.',
      );

      // Remove from cancelling set
      final updatedCancellingIds = Set<String>.from(newCancellingIds);
      updatedCancellingIds.remove(cancelKey);
      _updateState(_state.copyWith(cancellingIds: updatedCancellingIds));

      return errorResult;
    }

    try {
      await api.cancelBookingById(
        computerId: booking.computerId,
        bookingId: booking.bookingId!,
      );

      // Remove from cancelling set and reload
      final updatedCancellingIds = Set<String>.from(newCancellingIds);
      updatedCancellingIds.remove(cancelKey);
      _updateState(_state.copyWith(cancellingIds: updatedCancellingIds));

      // Reload bookings to get updated list
      await loadBookings(showLoader: false);

      return const CancelBookingResult(isSuccess: true);
    } catch (e) {
      // Remove from cancelling set on error
      final updatedCancellingIds = Set<String>.from(newCancellingIds);
      updatedCancellingIds.remove(cancelKey);
      _updateState(_state.copyWith(cancellingIds: updatedCancellingIds));

      return CancelBookingResult(isSuccess: false, error: e.toString());
    }
  }

  void _updateState(BookingControllerState newState) {
    _state = newState;
    notifyListeners();
  }
}
