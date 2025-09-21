class Computer {
  final int id;
  final int x, y;
  final String zone, status;
  final String? monitor, keyboard, mouse, headphones, cpu, gpu, ram;

  Computer(
    this.id,
    this.x,
    this.y,
    this.zone,
    this.status,
    this.monitor,
    this.keyboard,
    this.mouse,
    this.headphones,
    this.cpu,
    this.gpu,
    this.ram,
  );

  factory Computer.fromJson(Map<String, dynamic> j) {
    return Computer(
      j['id'] as int,
      j['x'] as int,
      j['y'] as int,
      j['zone'] as String,
      j['status'] as String? ?? 'free',
      j['monitor'] as String?,
      j['keyboard'] as String?,
      j['mouse'] as String?,
      j['headphones'] as String?,
      j['cpu'] as String?,
      j['gpu'] as String?,
      j['ram'] as String?,
    );
  }
}
