import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/sensor_card.dart';
import '../widgets/warning_banner.dart';
import '../services/firebase_realtime.dart';
import '../utils/dialog_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();

  StreamSubscription? _sensorSubscription;
  StreamSubscription? _controlSubscription;
  StreamSubscription? _settingsSubscription;

  // Sensor data
  double gasLevel = 0.0;
  bool hasFlame = false;
  double temperature = 0.0;
  double humidity = 0.0;
  bool isEsp32Online = false;

  // Control data
  bool buzzerState = false;

  // Settings
  double gasThreshold = 200.0;

  bool alarmMuted = false;
  DateTime? lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenToFirebase();
  }

  // Load giá trị thực từ Firebase khi khởi động
  Future<void> _loadInitialData() async {
    try {
      // Lấy trạng thái control hiện tại
      final controlData = await _firebaseService.getCurrentControlState();

      // Lấy dữ liệu sensor hiện tại
      final sensorData = await _firebaseService.getCurrentSensorData();

      if (mounted) {
        setState(() {
          // Cập nhật control state
          _updateControlState(controlData);

          // Cập nhật sensor data
          gasLevel = (sensorData['mq2'] ?? 0).toDouble();
          hasFlame = (sensorData['fire'] ?? 0) == 1;
          temperature = (sensorData['temp'] ?? 0).toDouble();
          humidity = (sensorData['humi'] ?? 0).toDouble();
          lastUpdateTime = DateTime.now();
          isEsp32Online = true;
        });
      }

      print('Initial data loaded - Control: $controlData, Sensor: $sensorData');
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  // Helper method để cập nhật control state
  void _updateControlState(Map<String, dynamic> data) {
    // Xử lý buzzer
    var buzzerValue = data['buzzer'];
    if (buzzerValue is bool) {
      buzzerState = buzzerValue;
    } else if (buzzerValue is int) {
      buzzerState = buzzerValue == 1;
    } else if (buzzerValue is String) {
      buzzerState = buzzerValue == '1' || buzzerValue.toLowerCase() == 'true';
    } else {
      buzzerState = false;
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _controlSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  void _listenToFirebase() {
    // Listen to sensor data
    _sensorSubscription = _firebaseService.getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          gasLevel = (data['mq2'] ?? 0).toDouble();
          hasFlame = (data['fire'] ?? 0) == 1;
          temperature = (data['temp'] ?? 0).toDouble();
          humidity = (data['humi'] ?? 0).toDouble();
          lastUpdateTime = DateTime.now();

          // Check if device is online (data updated recently)
          isEsp32Online = true;

          // Debug log
          print('Sensor data received: $data');
          print(
            'Gas: $gasLevel, Flame: $hasFlame, Temp: $temperature, Humi: $humidity',
          );
        });
      }
    });

    // Listen to control data
    _controlSubscription = _firebaseService.getControlStream().listen((data) {
      if (mounted) {
        setState(() {
          _updateControlState(data);

          // Debug log
          print('Control data received: $data');
          print('Buzzer: $buzzerState');
        });
      }
    });

    // Listen to settings
    _settingsSubscription = _firebaseService.getSettingsStream().listen((data) {
      if (mounted) {
        setState(() {
          if (data['behavior'] != null) {
            gasThreshold = (data['behavior']['threshold'] ?? 200).toDouble();
          }
        });
      }
    });
  }

  bool get hasWarning {
    return gasLevel > gasThreshold || hasFlame || !isEsp32Online;
  }

  String getWarningMessage() {
    List<String> warnings = [];
    if (gasLevel > gasThreshold) {
      warnings.add('⚠️ Phát hiện khí Gas vượt ngưỡng!');
    }
    if (hasFlame) {
      warnings.add('🔥 Phát hiện lửa!');
    }
    if (!isEsp32Online) {
      warnings.add('📡 Mất kết nối ESP32');
    }
    return warnings.join(' • ');
  }

  Color getGasColor() {
    if (gasLevel < 100) return Colors.green;
    if (gasLevel < gasThreshold) return Colors.orange;
    return Colors.red;
  }

  Future<void> _toggleBuzzer() async {
    try {
      await _firebaseService.updateControl('buzzer', 0);
      setState(() {
        alarmMuted = true;
      });
      DialogHelper.showSuccess(context, 'Đã tắt còi cảnh báo');
    } catch (e) {
      DialogHelper.showError(context, 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  isEsp32Online ? Icons.wifi : Icons.wifi_off,
                  color: isEsp32Online ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isEsp32Online ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isEsp32Online ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data from Firebase
          await _loadInitialData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Warning Banner
              if (hasWarning)
                WarningBanner(
                  message: getWarningMessage(),
                  onDismiss: alarmMuted
                      ? null
                      : () {
                          setState(() {
                            alarmMuted = true;
                          });
                        },
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Trạng thái cảm biến
                    Row(
                      children: [
                        Icon(
                          Icons.sensors,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Trạng thái cảm biến',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sensor Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        SensorCard(
                          title: 'Khí Gas',
                          value: '${gasLevel.toInt()} ppm',
                          icon: Icons.air,
                          color: getGasColor(),
                        ),
                        SensorCard(
                          title: 'Lửa',
                          value: hasFlame ? 'Có' : 'Không',
                          icon: hasFlame ? Icons.whatshot : Icons.check_circle,
                          color: hasFlame ? Colors.red : Colors.green,
                        ),
                        SensorCard(
                          title: 'Nhiệt độ',
                          value: '${temperature.toStringAsFixed(1)}°C',
                          icon: Icons.thermostat,
                          color: Colors.blue,
                        ),
                        SensorCard(
                          title: 'Độ ẩm',
                          value: '${humidity.toInt()}%',
                          icon: Icons.water_drop,
                          color: Colors.lightBlue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Alarm Control
                    if (hasWarning)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: alarmMuted
                                ? [Colors.grey.shade300, Colors.grey.shade400]
                                : [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (alarmMuted ? Colors.grey : Colors.orange)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: alarmMuted ? null : _toggleBuzzer,
                          icon: Icon(
                            alarmMuted ? Icons.volume_off : Icons.volume_up,
                            size: 24,
                          ),
                          label: Text(
                            alarmMuted ? 'Còi đã tắt' : 'Tắt còi cảnh báo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
