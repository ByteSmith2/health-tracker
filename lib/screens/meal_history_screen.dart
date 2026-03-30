import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/meal.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final meals = await DatabaseService.instance.getAllMeals();
    setState(() => _meals = meals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group meals by date
    final Map<String, List<Meal>> groupedMeals = {};
    for (final meal in _meals) {
      final key = DateFormat('dd/MM/yyyy').format(meal.dateTime);
      groupedMeals.putIfAbsent(key, () => []).add(meal);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử bữa ăn')),
      body: _meals.isEmpty
          ? const Center(child: Text('Chưa có lịch sử bữa ăn'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedMeals.length,
              itemBuilder: (ctx, i) {
                final date = groupedMeals.keys.elementAt(i);
                final meals = groupedMeals[date]!;
                final totalCal = meals.fold(0, (s, m) => s + m.calories);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            date,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text('$totalCal kcal'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    ...meals.map((meal) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.restaurant),
                            ),
                            title: Text(meal.name),
                            subtitle: Text(
                              DateFormat('HH:mm').format(meal.dateTime),
                            ),
                            trailing: Text(
                              '${meal.calories} kcal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        )),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}
