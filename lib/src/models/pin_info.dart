class PinInfo {
  final int number;
  final String name;
  final String function;
  final String mode; // INPUT/OUTPUT/ANALOG_IN/ANALOG_OUT
  final String pull; // NONE/PULLUP/PULLDOWN
  final bool? active; // true: bağlı/aktif, false: pasif, null: bilinmiyor

  PinInfo({
    required this.number,
    required this.name,
    required this.function,
    required this.mode,
    required this.pull,
    this.active,
  });

  factory PinInfo.fromJson(Map<String, dynamic> json) => PinInfo(
        number: json['number'],
        name: json['name'],
        function: json['function'],
        mode: json['mode'],
        pull: json['pull'],
        active: _parseActive(json),
      );

  static bool? _parseActive(Map<String, dynamic> json) {
    final v = json['active'] ?? json['state'] ?? json['value'] ?? json['level'];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return null;
  }
}
