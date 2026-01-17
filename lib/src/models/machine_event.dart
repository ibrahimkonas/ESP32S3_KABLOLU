class MachineEvent {
  final DateTime time;
  final String type;
  final String reason;

  MachineEvent({required this.time, required this.type, required this.reason});

  String get timeString =>
      '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}.${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class ProductionReport {
  final int count;
  final DateTime time;

  ProductionReport({required this.count, required this.time});

  String get timeString =>
      '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}.${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
