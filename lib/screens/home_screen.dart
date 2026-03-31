import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_card.dart';
import '../widgets/animated_counter.dart';
import 'meal_screen.dart';
import 'water_screen.dart';
import 'exercise_screen.dart';
import 'sleep_screen.dart';
import 'habit_screen.dart';
import 'analysis_screen.dart';
import 'meal_history_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _todayCalories = 0;
  int _calorieGoal = 2000;
  int _todayWater = 0;
  int _todayBurned = 0;
  double? _lastSleepHours;
  int _habitsCompleted = 0;
  int _totalHabits = 0;
  int _exerciseMinutes = 0;
  UserProfile? _profile;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = DatabaseService.instance;
      final calories = await db.getTotalCaloriesByDate(DateTime.now());
      final water = await db.getTotalWaterByDate(DateTime.now());
      final burned = await db.getTotalCaloriesBurnedByDate(DateTime.now());
      final sleep = await db.getLatestSleepRecord();
      final habits = await db.getHabits();
      final exercises = await db.getExercisesByDate(DateTime.now());
      final profile = await db.getUserProfile();

      if (!mounted) return;
      setState(() {
        _todayCalories = calories;
        _todayWater = water;
        _todayBurned = burned;
        _lastSleepHours = sleep?.duration.inMinutes != null
            ? sleep!.duration.inMinutes / 60.0
            : null;
        _totalHabits = habits.length;
        _habitsCompleted = habits.where((h) => h.isCompletedToday).length;
        _exerciseMinutes =
            exercises.fold<int>(0, (s, e) => s + e.durationMinutes);
        _profile = profile;
        _calorieGoal = profile?.recommendedCalories ?? 2000;
      });
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboard(),
      const MealScreen(),
      const WaterScreen(),
      const ExerciseScreen(),
      _buildMoreScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadDashboardData();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Bữa ăn',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Nước',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Vận động',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Thêm',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final theme = Theme.of(context);
    final calorieProgress =
        _calorieGoal > 0 ? (_todayCalories / _calorieGoal).clamp(0.0, 1.5) : 0.0;
    final waterProgress = (AppConstants.defaultWaterGoal > 0
            ? _todayWater / AppConstants.defaultWaterGoal
            : 0.0)
        .clamp(0.0, 1.5);

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.getGreeting(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _profile?.name ?? 'Người dùng',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      if (!mounted) return;
                      _loadDashboardData();
                    },
                    icon: CircleAvatar(
                      child: Text(
                        _profile?.name.isNotEmpty == true
                            ? _profile!.name[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Calorie card with circular progress
              GradientCard(
                gradientStart: AppConstants.calorieGradientStart,
                gradientEnd: AppConstants.calorieGradientEnd,
                onTap: () => setState(() => _currentIndex = 1),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 45,
                      lineWidth: 8,
                      percent: calorieProgress.clamp(0.0, 1.0),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(calorieProgress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      progressColor: Colors.white,
                      backgroundColor: Colors.white30,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Calo hôm nay',
                              style: TextStyle(color: Colors.white70)),
                          AnimatedCounter(
                            value: _todayCalories,
                            suffix: ' / $_calorieGoal kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_todayBurned > 0)
                            Text(
                              'Đã đốt cháy: $_todayBurned kcal',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Water + Exercise row
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      gradientStart: AppConstants.waterGradientStart,
                      gradientEnd: AppConstants.waterGradientEnd,
                      onTap: () => setState(() => _currentIndex = 2),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.water_drop,
                              color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          const Text('Nước',
                              style: TextStyle(color: Colors.white70)),
                          AnimatedCounter(
                            value: _todayWater,
                            suffix: ' ml',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: waterProgress.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradientStart: AppConstants.exerciseGradientStart,
                      gradientEnd: AppConstants.exerciseGradientEnd,
                      onTap: () => setState(() => _currentIndex = 3),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.fitness_center,
                              color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          const Text('Vận động',
                              style: TextStyle(color: Colors.white70)),
                          AnimatedCounter(
                            value: _exerciseMinutes,
                            suffix: ' phút',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_todayBurned kcal đốt cháy',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sleep + Habits row
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      gradientStart: AppConstants.sleepGradientStart,
                      gradientEnd: AppConstants.sleepGradientEnd,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SleepScreen())),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bedtime,
                              color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          const Text('Giấc ngủ',
                              style: TextStyle(color: Colors.white70)),
                          Text(
                            _lastSleepHours != null
                                ? '${_lastSleepHours!.toStringAsFixed(1)} giờ'
                                : 'Chưa có',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradientStart: AppConstants.habitGradientStart,
                      gradientEnd: AppConstants.habitGradientEnd,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HabitScreen())),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.checklist,
                              color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          const Text('Thói quen',
                              style: TextStyle(color: Colors.white70)),
                          Text(
                            '$_habitsCompleted / $_totalHabits',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick actions
              Text('Thao tác nhanh',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.analytics,
                    label: 'Phân tích AI',
                    color: Colors.green,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AnalysisScreen())),
                  ),
                  const SizedBox(width: 8),
                  _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'Thống kê',
                    color: Colors.blue,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const StatisticsScreen())),
                  ),
                  const SizedBox(width: 8),
                  _QuickAction(
                    icon: Icons.history,
                    label: 'Lịch sử',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MealHistoryScreen())),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x207E57C2),
              child: Icon(Icons.bedtime, color: Color(0xFF7E57C2)),
            ),
            title: const Text('Giấc ngủ'),
            subtitle: const Text('Theo dõi và phân tích giấc ngủ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SleepScreen())),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  AppConstants.habitGradientStart.withValues(alpha: 0.2),
              child:
                  Icon(Icons.checklist, color: AppConstants.habitGradientEnd),
            ),
            title: const Text('Thói quen'),
            subtitle: const Text('Xây dựng thói quen lành mạnh'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HabitScreen())),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x204CAF50),
              child: Icon(Icons.analytics, color: Color(0xFF4CAF50)),
            ),
            title: const Text('Phân tích AI'),
            subtitle: const Text('Đánh giá sức khỏe thông minh'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalysisScreen())),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x2042A5F5),
              child: Icon(Icons.bar_chart, color: Color(0xFF42A5F5)),
            ),
            title: const Text('Thống kê'),
            subtitle: const Text('Xem thống kê tuần/tháng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen())),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x20FF8A65),
              child: Icon(Icons.history, color: Color(0xFFFF8A65)),
            ),
            title: const Text('Lịch sử bữa ăn'),
            subtitle: const Text('Xem lịch sử bữa ăn bằng hình ảnh'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MealHistoryScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: const Text('Hồ sơ'),
            subtitle: const Text('Thông tin cá nhân & cài đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              if (!mounted) return;
              _loadDashboardData();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            color: color.withValues(alpha: 0.08),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
