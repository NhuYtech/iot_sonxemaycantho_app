class DeviceState {
  final String deviceId;
  final bool isOnline;
  final Map<String, dynamic> sensorData;
  final DateTime lastUpdated;

  DeviceState({
    required this.deviceId,
    required this.isOnline,
    required this.sensorData,
    required this.lastUpdated,
  });

  factory DeviceState.fromJson(Map<String, dynamic> json) {
    return DeviceState(
      deviceId: json['deviceId'] ?? '',
      isOnline: json['isOnline'] ?? false,
      sensorData: json['sensorData'] ?? {},
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'isOnline': isOnline,
      'sensorData': sensorData,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  DeviceState copyWith({
    String? deviceId,
    bool? isOnline,
    Map<String, dynamic>? sensorData,
    DateTime? lastUpdated,
  }) {
    return DeviceState(
      deviceId: deviceId ?? this.deviceId,
      isOnline: isOnline ?? this.isOnline,
      sensorData: sensorData ?? this.sensorData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
