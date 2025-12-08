import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeService {
  static final FirebaseRealtimeService _instance =
      FirebaseRealtimeService._internal();
  factory FirebaseRealtimeService() => _instance;
  FirebaseRealtimeService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  Stream<DatabaseEvent> onValue(String path) {
    return _database.ref(path).onValue;
  }

  // Lắng nghe sensor data
  Stream<Map<String, dynamic>> getSensorStream() {
    return _database.ref('sensor').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  // Lắng nghe control data
  Stream<Map<String, dynamic>> getControlStream() {
    return _database.ref('control').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  // Lắng nghe settings
  Stream<Map<String, dynamic>> getSettingsStream() {
    return _database.ref('settings').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  // Lắng nghe wifi config
  Stream<Map<String, dynamic>> getWifiConfigStream() {
    return _database.ref('wifiConfig').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  // Update control
  Future<void> updateControl(String key, dynamic value) async {
    try {
      await _database.ref('control/$key').set(value);
    } catch (e) {
      throw Exception('Failed to update control: $e');
    }
  }

  // Reset AP
  Future<void> resetAP() async {
    try {
      await _database.ref('commands/resetAP').set({
        'requested': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to reset AP: $e');
    }
  }

  // Update settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _database.ref('settings').update(settings);
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    try {
      await _database.ref(path).set(data);
    } catch (e) {
      throw Exception('Failed to set data: $e');
    }
  }

  Future<void> updateData(String path, Map<String, dynamic> updates) async {
    try {
      await _database.ref(path).update(updates);
    } catch (e) {
      throw Exception('Failed to update data: $e');
    }
  }

  Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final snapshot = await _database.ref(path).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get data: $e');
    }
  }

  Future<void> deleteData(String path) async {
    try {
      await _database.ref(path).remove();
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  // Lấy giá trị control hiện tại (giá trị thực từ Firebase)
  Future<Map<String, dynamic>> getCurrentControlState() async {
    try {
      final snapshot = await _database.ref('control').get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {'buzzer': 0};
    } catch (e) {
      throw Exception('Failed to get control state: $e');
    }
  }

  // Lấy giá trị sensor hiện tại
  Future<Map<String, dynamic>> getCurrentSensorData() async {
    try {
      final snapshot = await _database.ref('sensor').get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {'mq2': 0, 'fire': 0, 'temp': 0, 'humi': 0};
    } catch (e) {
      throw Exception('Failed to get sensor data: $e');
    }
  }

  // Lấy dữ liệu lịch sử theo ngày cho biểu đồ
  Future<Map<String, dynamic>> getHistoryData(DateTime date) async {
    try {
      // Format: history/YYYY-MM-DD
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final snapshot = await _database.ref('history/$dateKey').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;

        // Chuyển đổi dữ liệu từ Firebase
        Map<String, dynamic> result = {};
        data.forEach((key, value) {
          if (value is Map) {
            result[key] = Map<String, dynamic>.from(value);
          }
        });

        return result;
      }
      return {};
    } catch (e) {
      print('Error getting history data: $e');
      return {};
    }
  }

  // Lắng nghe dữ liệu lịch sử realtime
  Stream<Map<String, dynamic>> getHistoryStream(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    print('📊 Listening to history path: history/$dateKey');

    return _database.ref('history/$dateKey').onValue.map((event) {
      print('📊 History data received: ${event.snapshot.value != null}');

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        Map<String, dynamic> result = {};

        data.forEach((key, value) {
          if (value is Map) {
            result[key] = Map<String, dynamic>.from(value);
          }
        });

        print('📊 Processed ${result.length} history entries');
        return result;
      }
      print('📊 No history data found');
      return {};
    });
  }

  // Ghi dữ liệu lịch sử
  Future<void> saveHistoryData(Map<String, dynamic> sensorData) async {
    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeKey = now.millisecondsSinceEpoch.toString();

      await _database.ref('history/$dateKey/$timeKey').set({
        'temp': sensorData['temp'] ?? 0,
        'humi': sensorData['humi'] ?? 0,
        'mq2': sensorData['mq2'] ?? 0,
        'fire': sensorData['fire'] ?? 1,
        'timestamp': now.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to save history data: $e');
    }
  }

  // Tạo test data cho 24 giờ (chỉ dùng để test)
  Future<void> generateTestHistoryData(DateTime date) async {
    try {
      print('🧪 Generating test history data for ${date.toString()}...');

      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Tạo data cho 24 giờ
      for (int hour = 0; hour < 24; hour++) {
        // Mỗi giờ tạo 3-5 entries
        final entriesPerHour = 3 + (hour % 3);

        for (int i = 0; i < entriesPerHour; i++) {
          final timestamp =
              date.millisecondsSinceEpoch +
              (hour * 60 * 60 * 1000) +
              (i * 15 * 60 * 1000); // Mỗi 15 phút

          // Random data với pattern realistic
          final temp =
              25 +
              (5 * (1 - (hour - 12).abs() / 12)) +
              (2 * (i / entriesPerHour - 0.5));
          final humi =
              65 + (10 * (hour / 24 - 0.5)) + (3 * (i / entriesPerHour - 0.5));
          final gas = 100 + (hour * 2) + (i * 5);

          await _database.ref('history/$dateKey/$timestamp').set({
            'temp': double.parse(temp.toStringAsFixed(1)),
            'humi': double.parse(humi.toStringAsFixed(1)),
            'mq2': gas.toInt(),
            'fire': 1,
            'timestamp': timestamp,
          });
        }
      }

      print('✅ Test data generated successfully!');
    } catch (e) {
      print('❌ Error generating test data: $e');
      throw Exception('Failed to generate test data: $e');
    }
  }
}
