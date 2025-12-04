class AppSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;
  final int refreshInterval;

  AppSettings({
    required this.notificationsEnabled,
    required this.darkMode,
    required this.language,
    required this.refreshInterval,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      notificationsEnabled: true,
      darkMode: false,
      language: 'vi',
      refreshInterval: 5,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
      language: json['language'] ?? 'vi',
      refreshInterval: json['refreshInterval'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'language': language,
      'refreshInterval': refreshInterval,
    };
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    String? language,
    int? refreshInterval,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}
