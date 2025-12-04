import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  Stream<DatabaseEvent> onValue(String path) {
    return _database.ref(path).onValue;
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
