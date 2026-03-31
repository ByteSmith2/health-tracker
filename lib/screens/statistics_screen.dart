import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _weeklyCalories = [];
  int _avgCalories = 0;
  int _totalMeals = 0;
  double _avgSleep = 0;
  int _totalExerciseMin = 0;
  int _totalCalBurned = 0;
  int _avgWater = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseService.instance;
      final weeklyCalories = await db.getWeeklyCalories();
      final allMeals = await db.getAllMeals();
      final sleepRecords = await db.getSleepRecords(limit: 7);

      // Calculate averages
      final calValues = weeklyCalories
          .map((d) => d['calories'] as int)
          .where((c) => c > 0)
          .toList();
      final avgCal =
          calValues.isNotEmpty ? calValues.reduce((a, b) => a + b) ~/ calValues.length : 0;

      double avgSleep = 0;
      if (sleepRecords.isNotEmpty) {
        final totalMin =
            sleepRecords.fold<int>(0, (s, r) => s + r.duration.inMinutes);
        avgSleep = totalMin / sleepRecords.length / 60.0;
      }

      // Exercise stats for this week
      int totalExMin = 0;
      int totalBurned = 0;
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        final exercises = await db.getExercisesByDate(day);
        totalExMin += exercises.fold<int>(0, (s, e) => s + e.durationMinutes);
        totalBurned += exercises.fold<int>(0, (s, e) => s + e.caloriesBurned);
      }

      // Water stats
      int totalWater = 0;
      int waterDays = 0;
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        final w = await db.getTotalWaterByDate(day);
        if (w > 0) {
          totalWater += w;
          waterDays++;
        }
      }

      if (!mounted) return;
      setState(() {
        _weeklyCalories = weeklyCalories;
        _avgCalories = avgCal;
        _totalMeals = allMeals.length;
        _avgSleep = avgSleep;
        _totalExerciseMin = totalExMin;
        _totalCalBurned = totalBurned;
        _avgWater = waterDays > 0 ? totalWater ~/ waterDays : 0;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calo'),
            Tab(text: 'Sức khỏe'),
            Tab(text: 'Tổng hợp'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaloriesTab(theme),
          _buildHealthTab(theme),
          _buildSummaryTab(theme),
        ],
      ),
    );
  }

  Widget _buildCaloriesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Row(
          children: [
            _StatBox(
                label: 'TB Calo/ngày',
                value: '$_avgCalories',
                unit: 'kcal',
                color: Colors.orange),
            const SizedBox(width: 8),
            _StatBox(
                label: 'Tổng bữa ăn',
                value: '$_totalMeals',
                unit: 'bữa',
                color: Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        Text('Calo 7 ngày qua',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _weeklyCalories.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxCalorie() * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                          '${rod.toY.toInt()} kcal',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= _weeklyCalories.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _weeklyCalories[i]['date'] as String,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: _weeklyCalories.asMap().entries.map((e) {
                      final cal = (e.value['calories'] as int).toDouble();
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: cal,
                            gradient: const LinearGradient(
                              colors: [
                                AppConstants.calorieGradientStart,
                                AppConstants.calorieGradientEnd,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                ),
        ),
      ],
    );
  }

  Widget _buildHealthTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sleep stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime, color: Color(0xFF7E57C2)),
                    const SizedBox(width: 8),
                    Text('Giấc ngủ',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          _avgSleep > 0
                              ? '${_avgSleep.toStringAsFixed(1)}h'
                              : '--',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7E57C2),
                          ),
                        ),
                        const Text('TB/đêm'),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(
                          _avgSleep >= 7
                              ? Icons.sentiment_very_satisfied
                              : _avgSleep >= 6
                                  ? Icons.sentiment_neutral
                                  : Icons.sentiment_dissatisfied,
                          size: 36,
                          color: _avgSleep >= 7
                              ? Colors.green
                              : _avgSleep >= 6
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        Text(_avgSleep >= 7
                            ? 'Tốt'
                            : _avgSleep >= 6
                                ? 'Tạm ổn'
                                : 'Cần cải thiện'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Exercise stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text('Vận động (7 ngày)',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                        value: '$_totalExerciseMin',
                        label: 'phút',
                        color: Colors.deepOrange),
                    _StatColumn(
                        value: '$_totalCalBurned',
                        label: 'kcal đốt',
                        color: Colors.red),
                    _StatColumn(
                        value: '${_totalExerciseMin ~/ 7}',
                        label: 'phút/ngày',
                        color: Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Water stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Nước uống',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                        value: '$_avgWater',
                        label: 'ml TB/ngày',
                        color: Colors.blue),
                    _StatColumn(
                        value:
                            '${(_avgWater / AppConstants.defaultWaterGoal * 100).round()}%',
                        label: 'đạt mục tiêu',
                        color: Colors.lightBlue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng hợp tuần',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _SummaryRow(
                    icon: Icons.restaurant,
                    label: 'TB Calo nạp/ngày',
                    value: '$_avgCalories kcal',
                    color: Colors.orange),
                const Divider(),
                _SummaryRow(
                    icon: Icons.water_drop,
                    label: 'TB Nước/ngày',
                    value: '$_avgWater ml',
                    color: Colors.blue),
                const Divider(),
                _SummaryRow(
                    icon: Icons.bedtime,
                    label: 'TB Giấc ngủ',
                    value: _avgSleep > 0
                        ? '${_avgSleep.toStringAsFixed(1)} giờ'
                        : 'Chưa có',
                    color: const Color(0xFF7E57C2)),
                const Divider(),
                _SummaryRow(
                    icon: Icons.fitness_center,
                    label: 'Tổng tập luyện',
                    value: '$_totalExerciseMin phút',
                    color: Colors.deepOrange),
                const Divider(),
                _SummaryRow(
                    icon: Icons.local_fire_department,
                    label: 'Tổng calo đốt',
                    value: '$_totalCalBurned kcal',
                    color: Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getWeeklyTip(),
                    style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getWeeklyTip() {
    if (_avgCalories == 0) {
      return 'Hãy bắt đầu ghi nhận bữa ăn để nhận được phân tích chi tiết hơn!';
    }
    if (_avgSleep < 7 && _avgSleep > 0) {
      return 'Giấc ngủ TB ${_avgSleep.toStringAsFixed(1)}h/đêm hơi ít. Ngủ đủ 7-8h giúp trao đổi chất tốt hơn.';
    }
    if (_totalExerciseMin < 150) {
      return 'WHO khuyến nghị ít nhất 150 phút vận động/tuần. Bạn mới tập $_totalExerciseMin phút tuần này.';
    }
    return 'Bạn đang duy trì lối sống lành mạnh! Hãy tiếp tục phát huy.';
  }

  double _getMaxCalorie() {
    if (_weeklyCalories.isEmpty) return 2000;
    final max = _weeklyCalories
        .map((d) => (d['calories'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max < 100 ? 2000 : max;
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(unit, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
