import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final _db = DatabaseService.instance;
  final _ai = AIService.instance;
  List<Meal> _todayMeals = [];
  int _totalCalories = 0;

  // Store picked image bytes for web display
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      final meals = await _db.getMealsByDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _todayMeals = meals;
        _totalCalories = meals.fold(0, (sum, m) => sum + m.calories);
      });
    } catch (e) {
      debugPrint('Error loading meals: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    // Read bytes for cross-platform display
    final bytes = await image.readAsBytes();
    final imageName = 'meal_${DateTime.now().millisecondsSinceEpoch}';
    _imageCache[imageName] = bytes;

    // AI recognition (simulated)
    final result = _ai.recognizeFood(image.path);

    if (!mounted) return;
    _showAddMealDialog(
      initialName: result['name'] as String,
      initialCalories: result['calories'] as int,
      confidence: result['confidence'] as double,
      imageName: imageName,
      imageBytes: bytes,
    );
  }

  void _addMealManually() {
    _showAddMealDialog();
  }

  void _showAddMealDialog({
    String? initialName,
    int? initialCalories,
    double? confidence,
    String? imageName,
    Uint8List? imageBytes,
  }) {
    final nameController = TextEditingController(text: initialName ?? '');
    final caloriesController =
        TextEditingController(text: initialCalories?.toString() ?? '');
    String selectedType = 'lunch';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
              Text(
                'Thêm bữa ăn',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (confidence != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI nhận diện: ${(confidence * 100).toInt()}% chính xác',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (imageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calo (kcal)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDropdownState) {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại bữa ăn',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                      DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                      DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                      DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                    ],
                    onChanged: (v) => setDropdownState(() => selectedType = v!),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final calories = int.tryParse(caloriesController.text) ?? 0;
                  if (name.isEmpty || calories <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                    );
                    return;
                  }
                  final meal = Meal(
                    name: name,
                    calories: calories,
                    imagePath: imageName,
                    dateTime: DateTime.now(),
                    mealType: selectedType,
                  );
                  await _db.insertMeal(meal);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadMeals();
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealImage(String? imagePath) {
    if (imagePath == null) return const SizedBox.shrink();
    final bytes = _imageCache[imagePath];
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover),
      );
    }
    // On web, if image not in cache, show icon placeholder
    if (kIsWeb) {
      return const CircleAvatar(child: Icon(Icons.image));
    }
    // On mobile, try loading from file path
    return const CircleAvatar(child: Icon(Icons.image));
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return type;
    }
  }

  IconData _mealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bữa ăn hôm nay'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.local_fire_department, size: 18),
              label: Text('$_totalCalories kcal'),
            ),
          ),
        ],
      ),
      body: _todayMeals.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bữa ăn nào hôm nay',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb
                        ? 'Chọn ảnh hoặc nhập thủ công để bắt đầu!'
                        : 'Chụp ảnh món ăn để bắt đầu!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _todayMeals.length,
              itemBuilder: (ctx, i) {
                final meal = _todayMeals[i];
                return Dismissible(
                  key: Key(meal.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _db.deleteMeal(meal.id!);
                    _loadMeals();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: meal.imagePath != null
                          ? _buildMealImage(meal.imagePath)
                          : CircleAvatar(
                              child: Icon(_mealTypeIcon(meal.mealType)),
                            ),
                      title: Text(meal.name),
                      subtitle: Text(
                        '${_mealTypeLabel(meal.mealType)} • ${DateFormat('HH:mm').format(meal.dateTime)}',
                      ),
                      trailing: Text(
                        '${meal.calories} kcal',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'manual',
            onPressed: _addMealManually,
            child: const Icon(Icons.edit),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'camera',
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
            ),
          ],
        ],
      ),
    );
  }
}
