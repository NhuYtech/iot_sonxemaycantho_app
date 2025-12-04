import 'firebase_realtime.dart';

class DeviceControlService {
  final FirebaseRealtimeService _realtimeService = FirebaseRealtimeService();

  Future<void> setDeviceState(String deviceId, bool state) async {
    try {
      await _realtimeService.updateData('devices/$deviceId', {
        'state': state,
        'lastControlled': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to control device: $e');
    }
  }

  Future<bool?> getDeviceState(String deviceId) async {
    try {
      final data = await _realtimeService.getData('devices/$deviceId');
      return data?['state'] as bool?;
    } catch (e) {
      throw Exception('Failed to get device state: $e');
    }
  }

  Stream<bool> listenToDeviceState(String deviceId) {
    return _realtimeService.onValue('devices/$deviceId/state').map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  Future<void> setDeviceConfig(
    String deviceId,
    Map<String, dynamic> config,
  ) async {
    try {
      await _realtimeService.updateData('devices/$deviceId/config', config);
    } catch (e) {
      throw Exception('Failed to set device config: $e');
    }
  }

  Future<Map<String, dynamic>?> getAllDevices() async {
    try {
      return await _realtimeService.getData('devices');
    } catch (e) {
      throw Exception('Failed to get devices: $e');
    }
  }

  Future<void> addDevice(
    String deviceId,
    Map<String, dynamic> deviceData,
  ) async {
    try {
      await _realtimeService.setData('devices/$deviceId', {
        ...deviceData,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add device: $e');
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      await _realtimeService.deleteData('devices/$deviceId');
    } catch (e) {
      throw Exception('Failed to remove device: $e');
    }
  }
}
