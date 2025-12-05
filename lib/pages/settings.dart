import 'package:flutter/material.dart';
import '../widgets/switch_tile.dart';

enum SystemMode { auto, manual }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock data - sẽ được load từ Firebase
  String deviceId = 'ESP32-001';
  bool isDeviceOnline = true;
  bool isWifiConnected = true;
  String wifiSsid = 'IoT_Network';
  int wifiSignalStrength = -45; // dBm

  SystemMode systemMode = SystemMode.auto;
  double gasThreshold = 200.0;
  int dataInterval = 2; // seconds

  // Sensors
  bool hasTempSensor = true;
  bool hasHumiditySensor = true;
  bool hasGasSensor = true;
  bool hasFlameSensor = true;

  String get wifiStatus {
    if (!isWifiConnected) return 'Ngắt kết nối';
    if (wifiSignalStrength > -50) return 'Tốt';
    if (wifiSignalStrength > -70) return 'Trung bình';
    return 'Yếu';
  }

  Color get wifiStatusColor {
    if (!isWifiConnected) return Colors.red;
    if (wifiSignalStrength > -50) return Colors.green;
    if (wifiSignalStrength > -70) return Colors.orange;
    return Colors.red;
  }

  IconData get wifiIcon {
    if (!isWifiConnected) return Icons.wifi_off;
    if (wifiSignalStrength > -50) return Icons.wifi;
    if (wifiSignalStrength > -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  void _resetWifi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset WiFi'),
        content: const Text(
          'Bạn có chắc muốn reset cấu hình WiFi?\n\n'
          'Thiết bị sẽ khởi động lại và chuyển sang chế độ cấu hình WiFi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send reset command to Firebase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi lệnh reset WiFi')),
              );
            },
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
        content: StatefulBuilder(
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
                min: 50,
                max: 500,
                divisions: 45,
                label: '${tempThreshold.toInt()} ppm',
                onChanged: (value) {
                  setDialogState(() {
                    tempThreshold = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi Gas vượt ngưỡng này, hệ thống sẽ cảnh báo',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                gasThreshold = tempThreshold;
              });
              // TODO: Send to Firebase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã cập nhật ngưỡng: ${tempThreshold.toInt()} ppm',
                  ),
                ),
              );
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
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã copy ID')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isDeviceOnline ? Icons.check_circle : Icons.error,
                    color: isDeviceOnline ? Colors.green : Colors.red,
                  ),
                  title: const Text('Trạng thái'),
                  subtitle: Text(isDeviceOnline ? 'Online' : 'Offline'),
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
                        color: isDeviceOnline ? Colors.green : Colors.red,
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
                        if (hasTempSensor) _buildSensorChip('Nhiệt độ'),
                        if (hasHumiditySensor) _buildSensorChip('Độ ẩm'),
                        if (hasGasSensor) _buildSensorChip('Gas'),
                        if (hasFlameSensor) _buildSensorChip('Lửa'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // B. Cấu hình mạng (WiFi)
          _buildSectionTitle('Cấu hình mạng', Icons.wifi),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(wifiIcon, color: wifiStatusColor),
                  title: const Text('Trạng thái WiFi'),
                  subtitle: Text(isWifiConnected ? wifiSsid : 'Chưa kết nối'),
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
                  leading: const Icon(Icons.restart_alt, color: Colors.orange),
                  title: const Text('Reset WiFi'),
                  subtitle: const Text('Khởi động lại và cấu hình WiFi mới'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _resetWifi,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // C. Điều khiển hệ thống
          _buildSectionTitle('Điều khiển hệ thống', Icons.settings_suggest),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        onSelectionChanged: (Set<SystemMode> newSelection) {
                          setState(() {
                            systemMode = newSelection.first;
                          });
                          // TODO: Send to Firebase
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
                  padding: const EdgeInsets.all(16.0),
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
                          ButtonSegment(value: 1, label: Text('1s')),
                          ButtonSegment(value: 2, label: Text('2s')),
                          ButtonSegment(value: 5, label: Text('5s')),
                        ],
                        selected: {dataInterval},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            dataInterval = newSelection.first;
                          });
                          // TODO: Send to Firebase
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã cập nhật: Gửi dữ liệu mỗi ${dataInterval}s',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tần suất ESP32 gửi dữ liệu lên Firebase',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.check_circle, size: 16),
      backgroundColor: Colors.green.shade50,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Colors.green,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
