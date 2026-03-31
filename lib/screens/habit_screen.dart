import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final _db = DatabaseService.instance;
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _db.getHabits();
      if (!mounted) return;
      setState(() => _habits = habits);
    } catch (e) {
      debugPrint('Error loading habits: $e');
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'eco':
        return Icons.eco;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'no_meals':
        return Icons.no_meals;
      case 'menu_book':
        return Icons.menu_book;
      case 'bedtime':
        return Icons.bedtime;
      default:
        return Icons.check_circle;
    }
  }

  Future<void> _addHabit() async {
    final nameController = TextEditingController();
    String selectedIcon = 'check_circle';
    final suggestions = AIService.instance.getHabitSuggestions();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thêm thói quen',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên thói quen',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getIconData(selectedIcon)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI gợi ý thói quen lành mạnh:',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Colors.green,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions.map((s) {
                    return ActionChip(
                      avatar: Icon(_getIconData(s['icon']!), size: 18),
                      label: Text(s['name']!),
                      onPressed: () {
                        setSheetState(() {
                          nameController.text = s['name']!;
                          selectedIcon = s['icon']!;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final habit = Habit(
                      name: name,
                      icon: selectedIcon,
                      createdAt: DateTime.now(),
                    );
                    await _db.insertHabit(habit);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadHabits();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _habits.where((h) => h.isCompletedToday).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thói quen'),
        actions: [
          if (_habits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('$completedCount/${_habits.length}'),
                avatar: const Icon(Icons.check, size: 16),
              ),
            ),
        ],
      ),
      body: _habits.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.track_changes,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thói quen nào',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _addHabit,
                    child: const Text('Thêm thói quen đầu tiên'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _habits.length,
              itemBuilder: (ctx, i) {
                final habit = _habits[i];
                return Dismissible(
                  key: Key(habit.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _db.deleteHabit(habit.id!);
                    _loadHabits();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: habit.isCompletedToday
                        ? theme.colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: habit.isCompletedToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _getIconData(habit.icon),
                          color: habit.isCompletedToday
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        habit.name,
                        style: TextStyle(
                          decoration: habit.isCompletedToday
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text('Chuỗi: ${habit.currentStreak} ngày'),
                      trailing: Checkbox(
                        value: habit.isCompletedToday,
                        onChanged: (_) async {
                          await _db.toggleHabitCompletion(
                            habit.id!,
                            DateTime.now(),
                          );
                          _loadHabits();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabit,
        icon: const Icon(Icons.add),
        label: const Text('Thêm thói quen'),
      ),
    );
  }
}
