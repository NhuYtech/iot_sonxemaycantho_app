import 'package:flutter/material.dart';
import '../widgets/sensor_card.dart';
import '../widgets/warning_banner.dart';
import '../widgets/switch_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mock data - sẽ được thay thế bằng dữ liệu từ Firebase
  double gasLevel = 150.0; // ppm
  bool hasFlame = false;
  double temperature = 28.5; // °C
  double humidity = 65.0; // %
  bool isEsp32Online = true;

  bool relay1State = false;
  bool relay2State = false;
  bool alarmMuted = false;

  // Ngưỡng cảnh báo
  final double gasThreshold = 200.0;

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
    if (gasLevel < 200) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          // TODO: Refresh data from Firebase
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
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
                    const Text(
                      'Trạng thái cảm biến',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sensor Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
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

                    const SizedBox(height: 32),

                    // Section: Điều khiển
                    const Text(
                      'Điều khiển thiết bị',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Control Switches
                    Card(
                      child: Column(
                        children: [
                          SwitchTile(
                            title: 'Relay 1',
                            subtitle: relay1State ? 'Đang bật' : 'Đang tắt',
                            value: relay1State,
                            icon: Icons.power,
                            onChanged: (value) {
                              setState(() {
                                relay1State = value;
                              });
                              // TODO: Send command to Firebase
                            },
                          ),
                          const Divider(height: 1),
                          SwitchTile(
                            title: 'Relay 2',
                            subtitle: relay2State ? 'Đang bật' : 'Đang tắt',
                            value: relay2State,
                            icon: Icons.power_settings_new,
                            onChanged: (value) {
                              setState(() {
                                relay2State = value;
                              });
                              // TODO: Send command to Firebase
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alarm Control
                    if (hasWarning)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: alarmMuted
                              ? null
                              : () {
                                  setState(() {
                                    alarmMuted = true;
                                  });
                                  // TODO: Send mute command to Firebase
                                },
                          icon: Icon(
                            alarmMuted ? Icons.volume_off : Icons.volume_up,
                          ),
                          label: Text(
                            alarmMuted ? 'Còi đã tắt' : 'Tắt còi cảnh báo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alarmMuted
                                ? Colors.grey
                                : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
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
