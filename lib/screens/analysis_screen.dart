import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _db = DatabaseService.instance;
  final _ai = AIService.instance;
  int _todayCalories = 0;
  int _todayBurned = 0;
  int _todayWater = 0;
  double? _lastSleepHours;
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final calories = await _db.getTotalCaloriesByDate(DateTime.now());
      final burned = await _db.getTotalCaloriesBurnedByDate(DateTime.now());
      final water = await _db.getTotalWaterByDate(DateTime.now());
      final sleep = await _db.getLatestSleepRecord();
      final exercises = await _db.getExercisesByDate(DateTime.now());
      final habits = await _db.getHabits();
      final weeklyData = await _db.getWeeklyCalories();
      final profile = await _db.getUserProfile();

      final sleepHours = sleep?.duration.inMinutes != null
          ? sleep!.duration.inMinutes / 60.0
          : null;
      final totalHabits = habits.length;
      final completedHabits = habits.where((h) => h.isCompletedToday).length;
      final habitRatio = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

      final analysis = _ai.getComprehensiveAnalysis(
        profile: profile,
        caloriesConsumed: calories,
        caloriesBurned: burned > 0 ? burned : 1800,
        waterMl: water,
        waterGoal: AppConstants.defaultWaterGoal,
        sleepHours: sleepHours,
        sleepQuality: sleep?.qualityRating,
        habitsCompletedRatio: habitRatio,
        exerciseMinutes: exercises.fold<int>(0, (s, e) => s + e.durationMinutes),
      );

      if (!mounted) return;
      setState(() {
        _todayCalories = calories;
        _todayBurned = burned > 0 ? burned : 1800;
        _todayWater = water;
        _lastSleepHours = sleepHours;
        _weeklyData = weeklyData;
        _analysis = analysis;
      });
    } catch (e) {
      debugPrint('Error loading analysis data: $e');
    }
  }

  Color _getStatusColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallScore = _analysis?['overallScore'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Phân tích AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Score
          Center(
            child: CircularPercentIndicator(
              radius: 70,
              lineWidth: 12,
              percent: (overallScore / 100).clamp(0.0, 1.0),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$overallScore',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(overallScore),
                    ),
                  ),
                  Text('Điểm sức khỏe',
                      style: theme.textTheme.labelSmall),
                ],
              ),
              progressColor: _scoreColor(overallScore),
              backgroundColor: _scoreColor(overallScore).withValues(alpha: 0.2),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1200,
            ),
          ),
          const SizedBox(height: 16),

          // Score breakdown
          if (_analysis != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniScore(
                    label: 'Calo',
                    score: _analysis!['calorieScore'] as int,
                    icon: Icons.restaurant),
                _MiniScore(
                    label: 'Nước',
                    score: _analysis!['waterScore'] as int,
                    icon: Icons.water_drop),
                _MiniScore(
                    label: 'Ngủ',
                    score: _analysis!['sleepScore'] as int,
                    icon: Icons.bedtime),
                _MiniScore(
                    label: 'Tập',
                    score: _analysis!['exerciseScore'] as int,
                    icon: Icons.fitness_center),
                _MiniScore(
                    label: 'T.quen',
                    score: _analysis!['habitScore'] as int,
                    icon: Icons.checklist),
              ],
            ),
          const SizedBox(height: 20),

          // Status card
          if (_analysis != null)
            Card(
              color: _getStatusColor(_analysis!['statusColor'])
                  .withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _analysis!['statusColor'] == 'green'
                          ? Icons.check_circle
                          : Icons.info,
                      color: _getStatusColor(_analysis!['statusColor']),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _analysis!['overallStatus'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(
                                  _analysis!['statusColor']),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Nạp: $_todayCalories | Tiêu thụ: $_todayBurned | '
                            'Chênh lệch: ${_analysis!['balance']}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Summary row
          Row(
            children: [
              _SummaryCard(
                  icon: Icons.restaurant,
                  label: 'Nạp vào',
                  value: '$_todayCalories',
                  unit: 'kcal',
                  color: Colors.orange),
              const SizedBox(width: 6),
              _SummaryCard(
                  icon: Icons.local_fire_department,
                  label: 'Tiêu thụ',
                  value: '$_todayBurned',
                  unit: 'kcal',
                  color: Colors.red),
              const SizedBox(width: 6),
              _SummaryCard(
                  icon: Icons.water_drop,
                  label: 'Nước',
                  value: '$_todayWater',
                  unit: 'ml',
                  color: Colors.blue),
              const SizedBox(width: 6),
              _SummaryCard(
                  icon: Icons.bedtime,
                  label: 'Giấc ngủ',
                  value: _lastSleepHours?.toStringAsFixed(1) ?? '--',
                  unit: 'giờ',
                  color: Colors.indigo),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly chart
          Text('Calo 7 ngày qua',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _weeklyData.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxCalorie() * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} kcal',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= _weeklyData.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _weeklyData[i]['date'] as String,
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
                      barGroups: _weeklyData.asMap().entries.map((entry) {
                        final cal =
                            (entry.value['calories'] as int).toDouble();
                        final goal =
                            (_analysis?['calorieGoal'] as int? ?? 2000)
                                .toDouble();
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: cal,
                              color: cal > goal
                                  ? Colors.red.shade400
                                  : theme.colorScheme.primary,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 500),
                    swapAnimationCurve: Curves.easeInOut,
                  ),
          ),
          const SizedBox(height: 24),

          // AI Advice
          if (_analysis != null) ...[
            _AdviceCard(
              icon: Icons.restaurant_menu,
              title: 'Gợi ý chế độ ăn',
              content: _analysis!['dietAdvice'] as String,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            _AdviceCard(
              icon: Icons.fitness_center,
              title: 'Gợi ý luyện tập',
              content: _analysis!['exerciseAdvice'] as String,
              color: Colors.orange,
            ),
            if (_analysis!['sleepAdvice'] != null) ...[
              const SizedBox(height: 10),
              _AdviceCard(
                icon: Icons.bedtime,
                title: 'Gợi ý giấc ngủ',
                content: _analysis!['sleepAdvice'] as String,
                color: Colors.indigo,
              ),
            ],
            if (_analysis!['waterAdvice'] != null) ...[
              const SizedBox(height: 10),
              _AdviceCard(
                icon: Icons.water_drop,
                title: 'Gợi ý nước uống',
                content: _analysis!['waterAdvice'] as String,
                color: Colors.blue,
              ),
            ],
          ],
        ],
      ),
    );
  }

  double _getMaxCalorie() {
    if (_weeklyData.isEmpty) return 2000;
    final max = _weeklyData
        .map((d) => (d['calories'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max < 100 ? 2000 : max;
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;

  const _MiniScore({
    required this.label,
    required this.score,
    required this.icon,
  });

  Color get _color {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 22,
          lineWidth: 4,
          percent: (score / 100).clamp(0.0, 1.0),
          center: Icon(icon, size: 16, color: _color),
          progressColor: _color,
          backgroundColor: _color.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 4),
        Text('$score', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 12, color: _color)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({
    required this.icon,
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
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10)),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              Text(unit, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _AdviceCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
