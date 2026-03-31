import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal.dart';
import '../models/sleep_record.dart';
import '../models/habit.dart';
import '../models/water_intake.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  bool get _isAuthenticated => FirebaseAuth.instance.currentUser != null;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.uid;
  }

  CollectionReference _col(String name) =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection(name);

  DocumentReference get _profileDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isAuthenticated) return;
    await _profileDoc.set({'profile': profile.toMap()}, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile() async {
    if (!_isAuthenticated) return null;
    final doc = await _profileDoc.get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['profile'] == null) return null;
    return UserProfile.fromMap(data['profile'] as Map<String, dynamic>);
  }

  Future<bool> hasProfile() async {
    if (!_isAuthenticated) return false;
    final doc = await _profileDoc.get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    return data != null && data['profile'] != null;
  }

  // --- Meals ---
  Future<String> insertMeal(Meal meal) async {
    if (!_isAuthenticated) return '';
    final doc = await _col('meals').add(meal.toMap());
    return doc.id;
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    if (!_isAuthenticated) return [];
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _col('meals')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  Future<List<Meal>> getAllMeals() async {
    if (!_isAuthenticated) return [];
    final snapshot =
        await _col('meals').orderBy('dateTime', descending: true).get();
    return snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  Future<void> deleteMeal(String id) async {
    if (!_isAuthenticated) return;
    await _col('meals').doc(id).delete();
  }

  Future<int> getTotalCaloriesByDate(DateTime date) async {
    final meals = await getMealsByDate(date);
    return meals.fold<int>(0, (total, meal) => total + meal.calories);
  }

  Future<List<Map<String, dynamic>>> getWeeklyCalories() async {
    final now = DateTime.now();
    if (!_isAuthenticated) {
      final Map<String, int> dailyCalories = {};
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        dailyCalories['${day.day}/${day.month}'] = 0;
      }
      return dailyCalories.entries
          .map((e) => {'date': e.key, 'calories': e.value})
          .toList();
    }
    final weekAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final snapshot = await _col('meals')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .orderBy('dateTime')
        .get();
    final meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();

    final Map<String, int> dailyCalories = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      dailyCalories['${day.day}/${day.month}'] = 0;
    }
    for (final meal in meals) {
      final key = '${meal.dateTime.day}/${meal.dateTime.month}';
      if (dailyCalories.containsKey(key)) {
        dailyCalories[key] = dailyCalories[key]! + meal.calories;
      }
    }
    return dailyCalories.entries
        .map((e) => {'date': e.key, 'calories': e.value})
        .toList();
  }

  // --- Water ---
  Future<String> insertWaterIntake(WaterIntake water) async {
    if (!_isAuthenticated) return '';
    final doc = await _col('water').add(water.toMap());
    return doc.id;
  }

  Future<List<WaterIntake>> getWaterIntakeByDate(DateTime date) async {
    if (!_isAuthenticated) return [];
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _col('water')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) =>
            WaterIntake.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  Future<int> getTotalWaterByDate(DateTime date) async {
    final list = await getWaterIntakeByDate(date);
    return list.fold<int>(0, (total, w) => total + w.amount);
  }

  Future<void> deleteWaterIntake(String id) async {
    if (!_isAuthenticated) return;
    await _col('water').doc(id).delete();
  }

  // --- Exercise ---
  Future<String> insertExercise(Exercise exercise) async {
    if (!_isAuthenticated) return '';
    final doc = await _col('exercises').add(exercise.toMap());
    return doc.id;
  }

  Future<List<Exercise>> getExercisesByDate(DateTime date) async {
    if (!_isAuthenticated) return [];
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _col('exercises')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) =>
            Exercise.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  Future<int> getTotalCaloriesBurnedByDate(DateTime date) async {
    final list = await getExercisesByDate(date);
    return list.fold<int>(0, (total, e) => total + e.caloriesBurned);
  }

  Future<void> deleteExercise(String id) async {
    if (!_isAuthenticated) return;
    await _col('exercises').doc(id).delete();
  }

  // --- Sleep ---
  Future<String> insertSleepRecord(SleepRecord record) async {
    if (!_isAuthenticated) return '';
    final doc = await _col('sleep_records').add(record.toMap());
    return doc.id;
  }

  Future<List<SleepRecord>> getSleepRecords({int limit = 30}) async {
    if (!_isAuthenticated) return [];
    final snapshot = await _col('sleep_records')
        .orderBy('bedTime', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) =>
            SleepRecord.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  Future<SleepRecord?> getLatestSleepRecord() async {
    final records = await getSleepRecords(limit: 1);
    return records.isNotEmpty ? records.first : null;
  }

  Future<void> deleteSleepRecord(String id) async {
    if (!_isAuthenticated) return;
    await _col('sleep_records').doc(id).delete();
  }

  // --- Habits ---
  Future<String> insertHabit(Habit habit) async {
    if (!_isAuthenticated) return '';
    final doc = await _col('habits').add(habit.toMap());
    return doc.id;
  }

  Future<List<Habit>> getHabits() async {
    if (!_isAuthenticated) return [];
    final habitsSnap =
        await _col('habits').orderBy('createdAt').get();
    final completionsSnap = await _col('habit_completions').get();

    final completionsMap = <String, List<DateTime>>{};
    for (final doc in completionsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final habitId = data['habitId'] as String;
      final date = (data['completedDate'] is Timestamp)
          ? (data['completedDate'] as Timestamp).toDate()
          : DateTime.parse(data['completedDate'] as String);
      completionsMap.putIfAbsent(habitId, () => []).add(date);
    }

    return habitsSnap.docs.map((doc) {
      return Habit.fromMap(
        doc.data() as Map<String, dynamic>,
        id: doc.id,
        completedDates: completionsMap[doc.id] ?? [],
      );
    }).toList();
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    if (!_isAuthenticated) return;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snapshot = await _col('habit_completions')
        .where('habitId', isEqualTo: habitId)
        .where('completedDate', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();

    if (snapshot.docs.isEmpty) {
      await _col('habit_completions').add({
        'habitId': habitId,
        'completedDate': Timestamp.fromDate(dateOnly),
      });
    } else {
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    if (!_isAuthenticated) return;
    // Delete completions for this habit
    final completions = await _col('habit_completions')
        .where('habitId', isEqualTo: id)
        .get();
    for (final doc in completions.docs) {
      await doc.reference.delete();
    }
    await _col('habits').doc(id).delete();
  }
}
