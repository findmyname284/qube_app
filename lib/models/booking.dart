class Booking {
  final String? bookingId;
  final String commandType;
  final int computerId;
  final DateTime createdAt;
  final int workstationId;
  final DateTime start;
  final DateTime end;
  //   final Map<String, dynamic>? payload;

  Booking(
    this.bookingId,
    this.commandType,
    this.computerId,
    this.createdAt,
    this.workstationId,
    this.start,
    this.end,
  );

  factory Booking.fromJson(Map<String, dynamic> j) {
    return Booking(
      j['booking_id'] as String?,
      j['command_type'] as String,
      j['computer_id'] as int,
      DateTime.parse(j['created_at'] as String),
      j['workstation_id'] as int,
      DateTime.parse(j['start'] as String).toLocal(),
      DateTime.parse(j['end'] as String).toLocal(),
    );
  }
}
