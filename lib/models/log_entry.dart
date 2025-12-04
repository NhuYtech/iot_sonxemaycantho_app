class LogEntry {
  final String id;
  final DateTime timestamp;
  final String message;
  final String level;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.level,
    this.metadata,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      message: json['message'] ?? '',
      level: json['level'] ?? 'info',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'level': level,
      'metadata': metadata,
    };
  }
}
