import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/water_intake.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/water_wave_widget.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _db = DatabaseService.instance;
  List<WaterIntake> _todayIntakes = [];
  int _totalMl = 0;
  final int _goal = AppConstants.defaultWaterGoal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final intakes = await _db.getWaterIntakeByDate(DateTime.now());
      final total = await _db.getTotalWaterByDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _todayIntakes = intakes;
        _totalMl = total;
      });
    } catch (e) {
      debugPrint('Error loading water data: $e');
    }
  }

  Future<void> _addWater(int ml) async {
    try {
      await _db.insertWaterIntake(
        WaterIntake(amount: ml, dateTime: DateTime.now()),
      );
      _loadData();
    } catch (e) {
      debugPrint('Error adding water: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _totalMl / _goal;

    return Scaffold(
      appBar: AppBar(title: const Text('Nước uống')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Water wave animation
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                WaterWaveWidget(
                  progress: progress.clamp(0.0, 1.0),
                  size: 200,
                  color: AppConstants.waterGradientStart,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_totalMl',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.waterGradientEnd,
                      ),
                    ),
                    Text(
                      '/ $_goal ml',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              progress >= 1.0
                  ? 'Đã đạt mục tiêu!'
                  : 'Còn ${_goal - _totalMl} ml nữa',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: progress >= 1.0
                    ? Colors.green
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    progress >= 1.0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick add buttons
          Text('Thêm nhanh',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _WaterButton(ml: 150, icon: Icons.local_cafe, onTap: () => _addWater(150)),
              const SizedBox(width: 8),
              _WaterButton(ml: 250, icon: Icons.water_drop, onTap: () => _addWater(250)),
              const SizedBox(width: 8),
              _WaterButton(ml: 350, icon: Icons.local_drink, onTap: () => _addWater(350)),
              const SizedBox(width: 8),
              _WaterButton(ml: 500, icon: Icons.water, onTap: () => _addWater(500)),
            ],
          ),
          const SizedBox(height: 24),

          // Today's log
          Text('Hôm nay',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_todayIntakes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Chưa uống nước hôm nay')),
            )
          else
            ..._todayIntakes.map((intake) => Dismissible(
                  key: Key(intake.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _db.deleteWaterIntake(intake.id!);
                    _loadData();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppConstants.waterGradientStart.withValues(alpha: 0.2),
                        child: const Icon(Icons.water_drop, color: Colors.blue),
                      ),
                      title: Text('${intake.amount} ml'),
                      trailing:
                          Text(DateFormat('HH:mm').format(intake.dateTime)),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final int ml;
  final IconData icon;
  final VoidCallback onTap;

  const _WaterButton({
    required this.ml,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppConstants.waterGradientStart.withValues(alpha: 0.4)),
            color: AppConstants.waterGradientStart.withValues(alpha: 0.08),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppConstants.waterGradientStart),
              const SizedBox(height: 4),
              Text(
                '${ml}ml',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.waterGradientEnd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
