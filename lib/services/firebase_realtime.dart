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
}
