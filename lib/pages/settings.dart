import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_realtime.dart';
import '../utils/dialog_helper.dart';

enum SystemMode { auto, manual }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();

  StreamSubscription? _settingsSubscription;
  StreamSubscription? _wifiSubscription;
  StreamSubscription? _sensorSubscription;

  String deviceId = 'ESP32-001';
  bool isDeviceOnline = false;
  bool isWifiConnected = false;
  String wifiSsid = '';
  DateTime? wifiTimestamp;

  SystemMode systemMode = SystemMode.auto;
  double gasThreshold = 1000.0;
  int dataInterval = 5;

  // Sensors - phát hiện từ Firebase data
  bool hasTempSensor = false;
  bool hasHumiditySensor = false;
  bool hasGasSensor = false;
  bool hasFlameSensor = false;

  // Giá trị sensor hiện tại
  double currentTemp = 0;
  double currentHumi = 0;
  double currentGas = 0;
  int currentFire = 1;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _wifiSubscription?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  void _listenToFirebase() {
    // Listen to settings
    _settingsSubscription = _firebaseService.getSettingsStream().listen((data) {
      if (mounted) {
        setState(() {
          if (data['behavior'] != null) {
            final behavior = data['behavior'];
            systemMode = (behavior['mode'] ?? 0) == 0
                ? SystemMode.auto
                : SystemMode.manual;
            gasThreshold = (behavior['threshold'] ?? 1000).toDouble().clamp(
              0,
              5000,
            );
          }

          dataInterval = data['dataInterval'] ?? 5;

          // Check logsSettings
          if (data['logsSettings'] != null) {}
        });
      }
    });

    // Listen to WiFi config
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
            // Consider online if updated within last 30 seconds
            isDeviceOnline =
                DateTime.now().difference(wifiTimestamp!).inSeconds < 30;
          }
        });
      }
    });

    // Listen to sensor data để phát hiện sensor đang hoạt động
    _sensorSubscription = _firebaseService.getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          currentTemp = (data['temp'] ?? 0).toDouble();
          currentHumi = (data['humi'] ?? 0).toDouble();
          currentGas = (data['mq2'] ?? 0).toDouble();
          currentFire = data['fire'] ?? 1;

          // Phát hiện sensor dựa trên data hợp lệ
          // Nhiệt độ: >= -40 và <= 80 (phạm vi DHT22)
          hasTempSensor = currentTemp >= -40 && currentTemp <= 80;

          // Độ ẩm: >= 0 và <= 100
          hasHumiditySensor = currentHumi >= 0 && currentHumi <= 100;

          // Gas: >= 0 (MQ-2 luôn có giá trị >= 0)
          hasGasSensor = currentGas >= 0;

          // Fire sensor: 0 hoặc 1
          hasFlameSensor = currentFire == 0 || currentFire == 1;
        });
      }
    });
  }

  String get wifiStatus {
    if (!isWifiConnected) return 'Ngắt kết nối';
    if (!isDeviceOnline) return 'Offline';
    return 'Đã kết nối';
  }

  Color get wifiStatusColor {
    if (!isWifiConnected || !isDeviceOnline) return Colors.red;
    return Colors.green;
  }

  IconData get wifiIcon {
    if (!isWifiConnected || !isDeviceOnline) return Icons.wifi_off;
    return Icons.wifi;
  }

  Future<void> _resetWifi() async {
    try {
      await _firebaseService.resetAP();
      if (mounted) {
        Navigator.pop(context);
        DialogHelper.showSuccess(context, 'Đã gửi lệnh reset WiFi');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        DialogHelper.showError(context, 'Lỗi: $e');
      }
    }
  }

  void _showResetWifiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset WiFi'),
        content: const SingleChildScrollView(
          child: Text(
            'Bạn có chắc muốn reset cấu hình WiFi?\n\n'
            'Thiết bị sẽ khởi động lại và chuyển sang chế độ cấu hình WiFi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _resetWifi,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showGasThresholdDialog() {
    double tempThreshold = gasThreshold;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt ngưỡng Gas'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tempThreshold.toInt()} ppm',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: tempThreshold,
                  min: 0,
                  max: 5000,
                  divisions: 100,
                  label: '${tempThreshold.toInt()} ppm',
                  onChanged: (value) {
                    setDialogState(() {
                      tempThreshold = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khi Gas vượt ngưỡng này, hệ thống sẽ cảnh báo\nPhạm vi: 0-5000 ppm (cảm biến MQ)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.updateSettings({
                  'behavior/threshold': tempThreshold.toInt(),
                });
                setState(() {
                  gasThreshold = tempThreshold;
                });
                if (mounted) {
                  Navigator.pop(context);
                  DialogHelper.showSuccess(
                    context,
                    'Đã cập nhật ngưỡng: ${tempThreshold.toInt()} ppm',
                  );
                }
              } catch (e) {
                if (mounted) {
                  DialogHelper.showError(context, 'Lỗi: $e');
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // A. Thông tin thiết bị
                      _buildSectionTitle('Thông tin thiết bị', Icons.devices),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.fingerprint),
                              title: const Text('ID thiết bị'),
                              subtitle: Text(deviceId),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  DialogHelper.showSuccess(
                                    context,
                                    'Đã copy ID',
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(
                                isDeviceOnline
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: isDeviceOnline
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: const Text('Trạng thái'),
                              subtitle: Text(
                                isDeviceOnline ? 'Online' : 'Offline',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeviceOnline
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDeviceOnline ? 'Hoạt động' : 'Mất kết nối',
                                  style: TextStyle(
                                    color: isDeviceOnline
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.sensors),
                              title: const Text('Cảm biến đang dùng'),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (hasTempSensor)
                                      _buildSensorChip('Nhiệt độ'),
                                    if (hasHumiditySensor)
                                      _buildSensorChip('Độ ẩm'),
                                    if (hasGasSensor) _buildSensorChip('Gas'),
                                    if (hasFlameSensor) _buildSensorChip('Lửa'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // B. Cấu hình mạng (WiFi)
                      _buildSectionTitle('Cấu hình mạng', Icons.wifi),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(wifiIcon, color: wifiStatusColor),
                              title: const Text('Trạng thái WiFi'),
                              subtitle: Text(
                                isWifiConnected ? wifiSsid : 'Chưa kết nối',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: wifiStatusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  wifiStatus,
                                  style: TextStyle(
                                    color: wifiStatusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.restart_alt,
                                color: Colors.orange,
                              ),
                              title: const Text('Reset WiFi'),
                              subtitle: const Text(
                                'Khởi động lại và cấu hình WiFi mới',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showResetWifiDialog,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // C. Điều khiển hệ thống
                      _buildSectionTitle(
                        'Điều khiển hệ thống',
                        Icons.settings_suggest,
                      ),
                      Card(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chế độ hoạt động',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<SystemMode>(
                                    segments: const [
                                      ButtonSegment(
                                        value: SystemMode.auto,
                                        label: Text('AUTO'),
                                        icon: Icon(Icons.auto_mode),
                                      ),
                                      ButtonSegment(
                                        value: SystemMode.manual,
                                        label: Text('MANUAL'),
                                        icon: Icon(Icons.touch_app),
                                      ),
                                    ],
                                    selected: {systemMode},
                                    onSelectionChanged:
                                        (Set<SystemMode> newSelection) async {
                                          final newMode = newSelection.first;
                                          try {
                                            await _firebaseService
                                                .updateSettings({
                                                  'behavior/mode':
                                                      newMode == SystemMode.auto
                                                      ? 0
                                                      : 1,
                                                });
                                            setState(() {
                                              systemMode = newMode;
                                            });
                                            if (mounted) {
                                              DialogHelper.showSuccess(
                                                context,
                                                'Đã chuyển sang chế độ ${newMode == SystemMode.auto ? 'AUTO' : 'MANUAL'}',
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              DialogHelper.showError(
                                                context,
                                                'Lỗi: $e',
                                              );
                                            }
                                          }
                                        },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    systemMode == SystemMode.auto
                                        ? '✓ Hệ thống tự động điều khiển khi có cảnh báo'
                                        : '✓ Điều khiển thủ công qua ứng dụng',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.warning_amber),
                              title: const Text('Ngưỡng cảnh báo Gas'),
                              subtitle: Text('${gasThreshold.toInt()} ppm'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showGasThresholdDialog,
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tần suất gửi dữ liệu',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<int>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 1,
                                        label: Text('1s'),
                                      ),
                                      ButtonSegment(
                                        value: 2,
                                        label: Text('2s'),
                                      ),
                                      ButtonSegment(
                                        value: 5,
                                        label: Text('5s'),
                                      ),
                                    ],
                                    selected: {dataInterval},
                                    onSelectionChanged:
                                        (Set<int> newSelection) async {
                                          final newInterval =
                                              newSelection.first;
                                          try {
                                            await _firebaseService
                                                .updateSettings({
                                                  'dataInterval': newInterval,
                                                });
                                            setState(() {
                                              dataInterval = newInterval;
                                            });
                                            if (mounted) {
                                              DialogHelper.showSuccess(
                                                context,
                                                'Đã cập nhật: Gửi dữ liệu mỗi ${newInterval}s',
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              DialogHelper.showError(
                                                context,
                                                'Lỗi: $e',
                                              );
                                            }
                                          }
                                        },
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tần suất ESP32 gửi dữ liệu lên Firebase',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorChip(String label) {
    // L\u1ea5y gi\u00e1 tr\u1ecb th\u1ef1c t\u1ebf t\u1eeb sensor
    String value = '';
    IconData icon = Icons.check_circle;
    Color chipColor = Colors.green;

    switch (label) {
      case 'Nhi\u1ec7t \u0111\u1ed9':
        value = '${currentTemp.toStringAsFixed(1)}\u00b0C';
        icon = Icons.thermostat;
        chipColor = currentTemp >= -40 && currentTemp <= 80
            ? Colors.blue
            : Colors.grey;
        break;
      case '\u0110\u1ed9 \u1ea9m':
        value = '${currentHumi.toInt()}%';
        icon = Icons.water_drop;
        chipColor = currentHumi >= 0 && currentHumi <= 100
            ? Colors.cyan
            : Colors.grey;
        break;
      case 'Gas':
        value = '${currentGas.toInt()} ppm';
        icon = Icons.air;
        chipColor = currentGas >= 0 ? Colors.green : Colors.grey;
        break;
      case 'L\u1eeda':
        value = currentFire == 0 ? 'C\u00f3' : 'Kh\u00f4ng';
        icon = currentFire == 0 ? Icons.whatshot : Icons.check_circle;
        chipColor = currentFire == 0 ? Colors.red : Colors.green;
        break;
    }

    // Xác định màu sắc cho chip
    Color backgroundColor;
    Color textColor;

    if (chipColor == Colors.blue) {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    } else if (chipColor == Colors.cyan) {
      backgroundColor = Colors.cyan.shade50;
      textColor = Colors.cyan.shade700;
    } else if (chipColor == Colors.green) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (chipColor == Colors.red) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else {
      backgroundColor = Colors.grey.shade50;
      textColor = Colors.grey.shade700;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      avatar: Icon(icon, size: 16, color: textColor),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(
        fontSize: 12,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
