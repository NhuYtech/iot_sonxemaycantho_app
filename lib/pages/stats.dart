import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../widgets/stat_summary.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/humidity_chart.dart';
import '../widgets/gas_chart.dart';
import '../services/firebase_realtime.dart';

enum TimeRange { day, week, month }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();
  StreamSubscription? _historySubscription;

  TimeRange selectedRange = TimeRange.day;
  DateTime selectedDate = DateTime.now();

  bool isLoading = true;

  // Dữ liệu thống kê
  double maxTemp = 0;
  double minTemp = 0;
  double avgTemp = 0;

  double maxHumidity = 0;
  double minHumidity = 0;
  double avgHumidity = 0;

  double maxGas = 0;
  double minGas = 0;
  double avgGas = 0;

  // Dữ liệu biểu đồ 24 giờ
  List<double> temperatureData = [];
  List<double> humidityData = [];
  List<double> gasData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  // Load dữ liệu lịch sử từ Firebase
  Future<void> _loadHistoryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Test xem có data không
      print('🔍 Testing Firebase connection...');
      final testData = await _firebaseService.getHistoryData(selectedDate);
      print('🔍 Test result: ${testData.length} entries found');

      // Lắng nghe realtime updates
      _historySubscription?.cancel();
      _historySubscription = _firebaseService
          .getHistoryStream(selectedDate)
          .listen((data) {
            print('📡 Received realtime update with ${data.length} entries');
            if (mounted) {
              _processHistoryData(data);
            }
          });
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Xử lý dữ liệu lịch sử
  void _processHistoryData(Map<String, dynamic> data) {
    print('🔄 Processing history data: ${data.length} entries');

    if (data.isEmpty) {
      print('⚠️ No history data to process');
      setState(() {
        isLoading = false;
        temperatureData = [];
        humidityData = [];
        gasData = [];
      });
      return;
    }

    print('✅ Data keys: ${data.keys.take(5).join(", ")}...');

    // Tạo mảng 24 giờ
    List<List<double>> tempByHour = List.generate(24, (_) => []);
    List<List<double>> humiByHour = List.generate(24, (_) => []);
    List<List<double>> gasByHour = List.generate(24, (_) => []);

    List<double> allTemps = [];
    List<double> allHumis = [];
    List<double> allGases = [];

    // Phân loại dữ liệu theo giờ
    int validEntries = 0;
    int invalidEntries = 0;

    data.forEach((key, value) {
      if (value is Map) {
        final timestamp = value['timestamp'];
        final temp = (value['temp'] ?? 0).toDouble();
        final humi = (value['humi'] ?? 0).toDouble();
        final gas = (value['mq2'] ?? 0).toDouble();

        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final hour = date.hour;
          validEntries++;

          // Debug first entry
          if (validEntries == 1) {
            print(
              '📝 First entry: hour=$hour, temp=$temp, humi=$humi, gas=$gas',
            );
          }

          if (temp >= -40 && temp <= 80) {
            tempByHour[hour].add(temp);
            allTemps.add(temp);
          }
          if (humi >= 0 && humi <= 100) {
            humiByHour[hour].add(humi);
            allHumis.add(humi);
          }
          if (gas >= 0) {
            gasByHour[hour].add(gas);
            allGases.add(gas);
          }
        } else {
          invalidEntries++;
        }
      }
    });

    print('📊 Valid entries: $validEntries, Invalid: $invalidEntries');
    print('📊 Temperature data points: ${allTemps.length}');

    // Debug data distribution by hour
    for (int i = 0; i < 24; i++) {
      if (tempByHour[i].isNotEmpty) {
        print('   Hour $i: ${tempByHour[i].length} entries');
      }
    }

    // Tính trung bình mỗi giờ cho biểu đồ
    List<double> tempChart = [];
    List<double> humiChart = [];
    List<double> gasChart = [];

    for (int i = 0; i < 24; i++) {
      tempChart.add(
        tempByHour[i].isEmpty
            ? (i > 0 ? tempChart[i - 1] : 0)
            : tempByHour[i].reduce((a, b) => a + b) / tempByHour[i].length,
      );

      humiChart.add(
        humiByHour[i].isEmpty
            ? (i > 0 ? humiChart[i - 1] : 0)
            : humiByHour[i].reduce((a, b) => a + b) / humiByHour[i].length,
      );

      gasChart.add(
        gasByHour[i].isEmpty
            ? (i > 0 ? gasChart[i - 1] : 0)
            : gasByHour[i].reduce((a, b) => a + b) / gasByHour[i].length,
      );
    }

    setState(() {
      // Cập nhật dữ liệu biểu đồ
      temperatureData = tempChart;
      humidityData = humiChart;
      gasData = gasChart;

      print(
        '📈 Chart data updated: temp=${tempChart.length}, humi=${humiChart.length}, gas=${gasChart.length}',
      );
      print('📈 Temp chart sample: ${tempChart.take(5).join(", ")}');

      // Cập nhật thống kê
      if (allTemps.isNotEmpty) {
        maxTemp = allTemps.reduce((a, b) => a > b ? a : b);
        minTemp = allTemps.reduce((a, b) => a < b ? a : b);
        avgTemp = allTemps.reduce((a, b) => a + b) / allTemps.length;
        print('🌡️ Temp stats: max=$maxTemp, min=$minTemp, avg=$avgTemp');
      }

      if (allHumis.isNotEmpty) {
        maxHumidity = allHumis.reduce((a, b) => a > b ? a : b);
        minHumidity = allHumis.reduce((a, b) => a < b ? a : b);
        avgHumidity = allHumis.reduce((a, b) => a + b) / allHumis.length;
        print(
          '💧 Humi stats: max=$maxHumidity, min=$minHumidity, avg=$avgHumidity',
        );
      }

      if (allGases.isNotEmpty) {
        maxGas = allGases.reduce((a, b) => a > b ? a : b);
        minGas = allGases.reduce((a, b) => a < b ? a : b);
        avgGas = allGases.reduce((a, b) => a + b) / allGases.length;
        print('💨 Gas stats: max=$maxGas, min=$minGas, avg=$avgGas');
      }

      isLoading = false;
      print('✅ Stats page update complete!');
    });
  }

  String get rangeTitle {
    switch (selectedRange) {
      case TimeRange.day:
        return 'Ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}';
      case TimeRange.week:
        final weekStart = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Tuần ${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(weekEnd)}';
      case TimeRange.month:
        return 'Tháng ${DateFormat('MM/yyyy').format(selectedDate)}';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked;

    if (selectedRange == TimeRange.day) {
      picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        locale: const Locale('vi', 'VN'),
      );
    } else if (selectedRange == TimeRange.month) {
      picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year,
      );
    } else {
      // Week picker
      picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
    }

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked!;
      });
      _loadHistoryData();
    }
  }

  void _changeDate(int days) {
    setState(() {
      if (selectedRange == TimeRange.day) {
        selectedDate = selectedDate.add(Duration(days: days));
      } else if (selectedRange == TimeRange.week) {
        selectedDate = selectedDate.add(Duration(days: days * 7));
      } else {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month + days,
          1,
        );
      }
    });
    _loadHistoryData();
  }

  // Generate test data (chỉ dùng khi debug)
  Future<void> _generateTestData() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🧪 Đang tạo test data...')));

      await _firebaseService.generateTestHistoryData(selectedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Test data đã được tạo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          // Debug button - long press để hiện
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _generateTestData,
            tooltip: 'Tạo test data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range Selector
              const Text(
                'Chế độ xem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TimeRange>(
                segments: const [
                  ButtonSegment(
                    value: TimeRange.day,
                    label: Text('Ngày'),
                    icon: Icon(Icons.calendar_today),
                  ),
                  ButtonSegment(
                    value: TimeRange.week,
                    label: Text('Tuần'),
                    icon: Icon(Icons.date_range),
                  ),
                  ButtonSegment(
                    value: TimeRange.month,
                    label: Text('Tháng'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: {selectedRange},
                onSelectionChanged: (Set<TimeRange> newSelection) {
                  setState(() {
                    selectedRange = newSelection.first;
                  });
                  _loadHistoryData();
                },
                style: ButtonStyle(visualDensity: VisualDensity.comfortable),
              ),

              const SizedBox(height: 24),

              // Date Picker
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeDate(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  rangeTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            selectedDate.isBefore(
                              DateTime.now().subtract(const Duration(days: 1)),
                            )
                            ? () => _changeDate(1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Temperature Statistics
              _buildStatSection(
                'Nhiệt độ (°C)',
                Icons.thermostat,
                Colors.blue,
                maxTemp,
                minTemp,
                avgTemp,
              ),

              const SizedBox(height: 16),

              // Temperature Chart
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                TemperatureChart(temperatureData: temperatureData),

              const SizedBox(height: 32),

              // Humidity Statistics
              _buildStatSection(
                'Độ ẩm (%)',
                Icons.water_drop,
                Colors.lightBlue,
                maxHumidity,
                minHumidity,
                avgHumidity,
              ),

              const SizedBox(height: 16),

              // Humidity Chart
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                HumidityChart(humidityData: humidityData),

              const SizedBox(height: 32),

              // Gas Statistics
              _buildStatSection(
                'Khí Gas (ppm)',
                Icons.air,
                Colors.orange,
                maxGas,
                minGas,
                avgGas,
              ),

              const SizedBox(height: 16),

              // Gas Chart
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                GasChart(gasData: gasData, threshold: 200),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(
    String title,
    IconData icon,
    Color color,
    double max,
    double min,
    double avg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StatSummary(
                    label: 'Cao nhất',
                    value: max.toStringAsFixed(1),
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StatSummary(
                    label: 'Thấp nhất',
                    value: min.toStringAsFixed(1),
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StatSummary(
                    label: 'Trung bình',
                    value: avg.toStringAsFixed(1),
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
