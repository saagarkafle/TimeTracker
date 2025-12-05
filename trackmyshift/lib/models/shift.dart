class Shift {
  final DateTime? arrival;
  final DateTime? departure;
  final String? manager;

  Shift({this.arrival, this.departure, this.manager});

  Map<String, dynamic> toJson() => {
    'arrival': arrival?.toIso8601String(),
    'departure': departure?.toIso8601String(),
    'manager': manager,
  };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    arrival: json['arrival'] != null ? DateTime.parse(json['arrival']) : null,
    departure: json['departure'] != null
        ? DateTime.parse(json['departure'])
        : null,
    manager: json['manager'] != null ? json['manager'] as String : null,
  );
}
