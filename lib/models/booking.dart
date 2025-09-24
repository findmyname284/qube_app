class Booking {
  final String? booking_id;
  final String command_type;
  final int computer_id;
  final DateTime created_at;
  final int workstation_id;
  //   final Map<String, dynamic>? payload;

  Booking(
    this.booking_id,
    this.command_type,
    this.computer_id,
    this.created_at,
    this.workstation_id,
  );

  factory Booking.fromJson(Map<String, dynamic> j) {
    return Booking(
      j['booking_id'] as String?,
      j['command_type'] as String,
      j['computer_id'] as int,
      DateTime.parse(j['created_at'] as String),
      j['workstation_id'] as int,
    );
  }
}
