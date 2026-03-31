import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_card.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _db = DatabaseService.instance;
  List<Exercise> _todayExercises = [];
  int _totalBurned = 0;
  int _totalMinutes = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final exercises = await _db.getExercisesByDate(DateTime.now());
      final profile = await _db.getUserProfile();
      if (!mounted) return;
      setState(() {
        _todayExercises = exercises;
        _totalBurned = exercises.fold<int>(0, (s, e) => s + e.caloriesBurned);
        _totalMinutes = exercises.fold<int>(0, (s, e) => s + e.durationMinutes);
        _profile = profile;
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');
    }
  }

  void _showAddExercise() {
    String? selectedExercise;
    int duration = 30;
    String exerciseType = 'cardio';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final weight = _profile?.weightKg ?? 65;
          final met = selectedExercise != null
              ? AppConstants.exerciseMET[selectedExercise] ?? 5.0
              : 5.0;
          final estimatedCal =
              Exercise.calculateCalories(met, weight, duration);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Thêm bài tập',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Exercise presets
                  Text('Chọn bài tập:',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.exerciseMET.keys.map((name) {
                      final isSelected = selectedExercise == name;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(name),
                        onSelected: (_) {
                          setSheetState(() {
                            selectedExercise = name;
                            // Auto-set type
                            if (['Yoga', 'Plank'].contains(name)) {
                              exerciseType = 'flexibility';
                            } else if (['Tập tạ'].contains(name)) {
                              exerciseType = 'strength';
                            } else if ([
                              'Cầu lông',
                              'Bóng đá',
                              'Bóng rổ'
                            ].contains(name)) {
                              exerciseType = 'sports';
                            } else {
                              exerciseType = 'cardio';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Duration slider
                  Text('Thời gian: $duration phút',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$duration phút',
                    onChanged: (v) =>
                        setSheetState(() => duration = v.round()),
                  ),

                  // Estimated calories
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.exerciseGradientStart
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Ước tính đốt cháy: $estimatedCal kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: selectedExercise == null
                        ? null
                        : () async {
                            final exercise = Exercise(
                              name: selectedExercise!,
                              durationMinutes: duration,
                              caloriesBurned: estimatedCal,
                              exerciseType: exerciseType,
                              dateTime: DateTime.now(),
                            );
                            await _db.insertExercise(exercise);
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _exerciseTypeIcon(String type) {
    switch (type) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'sports':
        return Icons.sports_soccer;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vận động')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          GradientCard(
            gradientStart: AppConstants.exerciseGradientStart,
            gradientEnd: AppConstants.exerciseGradientEnd,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hôm nay',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$_totalBurned kcal',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      Text('$_totalMinutes phút tập luyện',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.directions_run,
                    size: 48, color: Colors.white54),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Bài tập hôm nay',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (_todayExercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Chưa có bài tập nào hôm nay')),
            )
          else
            ..._todayExercises.map((exercise) => Dismissible(
                  key: Key(exercise.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _db.deleteExercise(exercise.id!);
                    _loadData();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppConstants.exerciseGradientStart
                            .withValues(alpha: 0.2),
                        child: Icon(
                          _exerciseTypeIcon(exercise.exerciseType),
                          color: AppConstants.exerciseGradientEnd,
                        ),
                      ),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.exerciseTypeLabel} • ${exercise.durationMinutes} phút • '
                        '${DateFormat('HH:mm').format(exercise.dateTime)}',
                      ),
                      trailing: Text(
                        '${exercise.caloriesBurned} kcal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.exerciseGradientEnd,
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExercise,
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài tập'),
      ),
    );
  }
}
