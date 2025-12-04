import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/stat_summary.dart';
import '../widgets/chart_placeholder.dart';

enum TimeRange { day, week, month }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  TimeRange selectedRange = TimeRange.day;
  DateTime selectedDate = DateTime.now();

  // Mock data - sẽ thay thế bằng dữ liệu từ Firebase
  double maxTemp = 35.2;
  double minTemp = 22.1;
  double avgTemp = 28.5;

  double maxHumidity = 85.0;
  double minHumidity = 45.0;
  double avgHumidity = 65.0;

  double maxGas = 250.0;
  double minGas = 50.0;
  double avgGas = 120.0;

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
        // TODO: Load data from Firebase for selected date
      });
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
      // TODO: Load data from Firebase for new date
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    // TODO: Load data for new range
                  });
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
              const ChartPlaceholder(title: 'Biểu đồ nhiệt độ', height: 220),

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
              const ChartPlaceholder(title: 'Biểu đồ độ ẩm', height: 220),

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
              const ChartPlaceholder(title: 'Biểu đồ khí Gas', height: 220),

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
