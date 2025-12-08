import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_realtime.dart';
import 'dart:async';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();

  StreamSubscription? _wifiSubscription;
  StreamSubscription? _sensorSubscription;

  String deviceId = 'ESP32-001';
  String wifiSsid = '';
  bool isWifiConnected = false;
  bool isDeviceOnline = false;
  DateTime? wifiTimestamp;
  DateTime? lastSensorUpdate;

  // Sensor data for display
  double temperature = 0.0;
  double humidity = 0.0;
  double gasLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _listenToWifi();
    _listenToSensors();
  }

  @override
  void dispose() {
    _wifiSubscription?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  void _listenToWifi() {
    _wifiSubscription = _firebaseService.getWifiConfigStream().listen((data) {
      if (mounted) {
        setState(() {
          wifiSsid = data['ssid'] ?? '';
          isWifiConnected =
              data['ssid'] != null && data['ssid'].toString().isNotEmpty;

          if (data['timestamp'] != null) {
            wifiTimestamp = DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(data['timestamp'].toString()) ?? 0,
            );
            isDeviceOnline =
                DateTime.now().difference(wifiTimestamp!).inSeconds < 30;
          }
        });
      }
    });
  }

  void _listenToSensors() {
    _sensorSubscription = _firebaseService.getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          temperature = (data['temp'] ?? 0).toDouble();
          humidity = (data['humi'] ?? 0).toDouble();
          gasLevel = (data['mq2'] ?? 0).toDouble();
          lastSensorUpdate = DateTime.now();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thiết bị & Kết nối')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Device Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.inversePrimary, Colors.white],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    // Device Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDeviceOnline ? Colors.green : Colors.grey,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.memory,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Device Name
                    Text(
                      deviceId,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Connection Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDeviceOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDeviceOnline ? 'Đang kết nối' : 'Ngoại tuyến',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Device Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin thiết bị',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.device_hub,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Mã thiết bị'),
                          subtitle: Text(deviceId),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.wifi,
                            color: isWifiConnected ? Colors.green : Colors.grey,
                          ),
                          title: const Text('WiFi'),
                          subtitle: Text(
                            isWifiConnected ? wifiSsid : 'Chưa kết nối',
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.access_time,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Cập nhật lần cuối'),
                          subtitle: Text(
                            wifiTimestamp != null
                                ? DateFormat(
                                    'dd/MM/yyyy HH:mm:ss',
                                  ).format(wifiTimestamp!)
                                : 'Chưa có dữ liệu',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sensor Data
                  const Text(
                    'Dữ liệu cảm biến',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.thermostat,
                            color: Colors.orange,
                          ),
                          title: const Text('Nhiệt độ'),
                          subtitle: Text('${temperature.toStringAsFixed(1)}°C'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                          ),
                          title: const Text('Độ ẩm'),
                          subtitle: Text('${humidity.toStringAsFixed(1)}%'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.air, color: Colors.purple),
                          title: const Text('Khí gas'),
                          subtitle: Text(gasLevel.toStringAsFixed(0)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.update,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Cập nhật cảm biến'),
                          subtitle: Text(
                            lastSensorUpdate != null
                                ? DateFormat(
                                    'HH:mm:ss',
                                  ).format(lastSensorUpdate!)
                                : 'Chưa có dữ liệu',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'IoT Sơn Xe Máy Cần Thơ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kết nối trực tiếp với ESP32',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
