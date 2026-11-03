enum MonitorStatus { normal, alarm }

class MonitorState {
  const MonitorState({
    required this.status,
    required this.deviceOnline,
    required this.personName,
    required this.batteryPercent,
    required this.impactG,
    required this.lastUpdated,
  });

  factory MonitorState.initial() {
    return MonitorState(
      status: MonitorStatus.normal,
      deviceOnline: false,
      personName: 'Mum',
      batteryPercent: 82,
      impactG: 1.0,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 8)),
    );
  }

  final MonitorStatus status;
  final bool deviceOnline;
  final String personName;
  final int batteryPercent;
  final double impactG;
  final DateTime lastUpdated;

  bool get hasAlarm => status == MonitorStatus.alarm;

  MonitorState copyWith({
    MonitorStatus? status,
    bool? deviceOnline,
    String? personName,
    int? batteryPercent,
    double? impactG,
    DateTime? lastUpdated,
  }) {
    return MonitorState(
      status: status ?? this.status,
      deviceOnline: deviceOnline ?? this.deviceOnline,
      personName: personName ?? this.personName,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      impactG: impactG ?? this.impactG,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
