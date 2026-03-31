import 'dart:math';
import '../models/user_profile.dart';

class AIService {
  static final AIService instance = AIService._();
  AIService._();

  Map<String, dynamic> recognizeFood(String? imagePath) {
    final foods = [
      {'name': 'Phở bò', 'calories': 450, 'confidence': 0.92},
      {'name': 'Cơm tấm sườn', 'calories': 680, 'confidence': 0.88},
      {'name': 'Bánh mì thịt', 'calories': 350, 'confidence': 0.95},
      {'name': 'Bún chả', 'calories': 520, 'confidence': 0.87},
      {'name': 'Gỏi cuốn (2 cuốn)', 'calories': 180, 'confidence': 0.90},
      {'name': 'Cơm chiên dương châu', 'calories': 550, 'confidence': 0.85},
      {'name': 'Bánh cuốn', 'calories': 300, 'confidence': 0.89},
      {'name': 'Hủ tiếu', 'calories': 400, 'confidence': 0.86},
      {'name': 'Bún bò Huế', 'calories': 480, 'confidence': 0.91},
      {'name': 'Cháo gà', 'calories': 250, 'confidence': 0.93},
      {'name': 'Salad trộn', 'calories': 150, 'confidence': 0.94},
      {'name': 'Gà rán', 'calories': 420, 'confidence': 0.90},
      {'name': 'Mì xào bò', 'calories': 500, 'confidence': 0.87},
      {'name': 'Canh chua cá', 'calories': 200, 'confidence': 0.88},
      {'name': 'Cơm gà Hải Nam', 'calories': 580, 'confidence': 0.86},
      {'name': 'Bánh xèo', 'calories': 450, 'confidence': 0.84},
      {'name': 'Bún riêu cua', 'calories': 420, 'confidence': 0.89},
      {'name': 'Cơm rang thập cẩm', 'calories': 600, 'confidence': 0.87},
    ];
    return foods[Random().nextInt(foods.length)];
  }

  // Comprehensive health analysis with scoring
  Map<String, dynamic> getComprehensiveAnalysis({
    UserProfile? profile,
    required int caloriesConsumed,
    required int caloriesBurned,
    required int waterMl,
    required int waterGoal,
    double? sleepHours,
    int? sleepQuality,
    double habitsCompletedRatio = 0,
    int exerciseMinutes = 0,
  }) {
    final calorieGoal = profile?.recommendedCalories ?? 2000;
    final balance = caloriesConsumed - caloriesBurned;

    // --- Calculate individual scores (0-100) ---
    // Calorie score: closer to goal = higher score
    double calorieScore = 100;
    if (calorieGoal > 0) {
      final deviation = (caloriesConsumed - calorieGoal).abs() / calorieGoal;
      calorieScore = (100 * (1 - deviation)).clamp(0, 100);
    }

    // Water score
    double waterScore = waterGoal > 0
        ? ((waterMl / waterGoal) * 100).clamp(0, 100)
        : 0;

    // Sleep score
    double sleepScore = 50;
    if (sleepHours != null) {
      if (sleepHours >= 7 && sleepHours <= 9) {
        sleepScore = 80 + (sleepQuality ?? 3) * 4.0;
      } else if (sleepHours >= 6) {
        sleepScore = 60 + (sleepQuality ?? 3) * 4.0;
      } else {
        sleepScore = 30 + (sleepQuality ?? 3) * 4.0;
      }
      sleepScore = sleepScore.clamp(0, 100);
    }

    // Exercise score
    double exerciseScore = 0;
    if (exerciseMinutes >= 60) {
      exerciseScore = 100;
    } else if (exerciseMinutes >= 30) {
      exerciseScore = 70 + (exerciseMinutes - 30);
    } else {
      exerciseScore = exerciseMinutes * 2.3;
    }
    exerciseScore = exerciseScore.clamp(0, 100);

    // Habit score
    double habitScore = habitsCompletedRatio * 100;

    // Overall daily health score (weighted)
    final overallScore = (calorieScore * 0.30 +
            waterScore * 0.20 +
            sleepScore * 0.20 +
            exerciseScore * 0.15 +
            habitScore * 0.15)
        .round();

    // --- Generate advice ---
    String dietAdvice;
    String exerciseAdvice;
    String overallStatus;
    String statusColor;

    if (balance > 500) {
      overallStatus = 'Dư thừa calo';
      statusColor = 'red';
      dietAdvice = 'Bạn đang nạp nhiều hơn $balance calo so với mức tiêu thụ. '
          'Hãy giảm phần ăn, tăng rau xanh và protein nạc. Tránh đồ chiên rán và nước ngọt.';
      exerciseAdvice = 'Nên tập thêm 30-45 phút cardio (chạy bộ, đạp xe, bơi lội). '
          'Kết hợp HIIT để đốt cháy calo hiệu quả hơn.';
    } else if (balance > 200) {
      overallStatus = 'Hơi dư calo';
      statusColor = 'orange';
      dietAdvice = 'Lượng calo hơi cao. Hãy ăn thêm rau và protein nạc, giảm tinh bột và đường.';
      exerciseAdvice = 'Đi bộ nhanh 20-30 phút hoặc tập yoga nhẹ nhàng để cân bằng.';
    } else if (balance >= -200) {
      overallStatus = 'Cân bằng tốt';
      statusColor = 'green';
      dietAdvice = 'Chế độ ăn cân bằng tốt! Hãy duy trì và đảm bảo đủ dinh dưỡng từ các nhóm thực phẩm.';
      exerciseAdvice = 'Tiếp tục duy trì lịch tập luyện. Kết hợp cả cardio và tập sức mạnh.';
    } else {
      overallStatus = 'Thiếu calo';
      statusColor = 'blue';
      dietAdvice = 'Bạn đang thiếu ${balance.abs()} calo. Bổ sung thêm protein và carb phức hợp. '
          'Ăn thêm bữa phụ lành mạnh: hạt, sữa chua, trái cây.';
      exerciseAdvice = 'Giảm cường độ tập luyện hoặc tăng calo nạp vào. Ưu tiên tập tạ nhẹ.';
    }

    // BMI-aware adjustments
    if (profile != null) {
      if (profile.bmi > 25 && balance < 0) {
        dietAdvice += '\n\nVới BMI ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory}), '
            'việc thiếu calo nhẹ có thể chấp nhận được. Tuy nhiên không nên thiếu quá 500 calo/ngày.';
      } else if (profile.bmi < 18.5 && balance < 0) {
        dietAdvice += '\n\nVới BMI ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory}), '
            'bạn CẦN tăng lượng calo nạp vào. Ưu tiên thực phẩm giàu năng lượng.';
      }
    }

    // Sleep advice
    String? sleepAdvice;
    if (sleepHours != null) {
      if (sleepHours < 6) {
        sleepAdvice = 'Bạn ngủ quá ít! Thiếu ngủ làm tăng cảm giác thèm ăn, '
            'giảm trao đổi chất và ảnh hưởng sức khỏe. Hãy đi ngủ sớm hơn và tạo thói quen ngủ đều đặn.';
      } else if (sleepHours < 7) {
        sleepAdvice = 'Giấc ngủ hơi ít. Cố gắng ngủ đủ 7-8 tiếng để cơ thể phục hồi tốt nhất.';
      } else if (sleepHours > 9) {
        sleepAdvice = 'Ngủ quá nhiều có thể khiến cơ thể mệt mỏi. Nên duy trì 7-8 tiếng.';
      }
    }

    // Water advice
    String? waterAdvice;
    if (waterMl < waterGoal * 0.5) {
      waterAdvice = 'Bạn mới uống ${waterMl}ml, chưa đạt 50% mục tiêu! '
          'Hãy uống nước đều đặn mỗi giờ. Đặt nhắc nhở để không quên.';
    } else if (waterMl < waterGoal) {
      waterAdvice = 'Đã uống ${waterMl}ml/${waterGoal}ml. Hãy tiếp tục uống thêm trong ngày!';
    }

    return {
      'overallScore': overallScore,
      'calorieScore': calorieScore.round(),
      'waterScore': waterScore.round(),
      'sleepScore': sleepScore.round(),
      'exerciseScore': exerciseScore.round(),
      'habitScore': habitScore.round(),
      'overallStatus': overallStatus,
      'statusColor': statusColor,
      'balance': balance,
      'calorieGoal': calorieGoal,
      'dietAdvice': dietAdvice,
      'exerciseAdvice': exerciseAdvice,
      'sleepAdvice': sleepAdvice,
      'waterAdvice': waterAdvice,
    };
  }

  String getSuggestedBedtime(DateTime wakeTime) {
    final bedtime = wakeTime.subtract(const Duration(hours: 8));
    return '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> getHabitSuggestions() {
    return [
      {'name': 'Uống 2L nước', 'icon': 'water_drop'},
      {'name': 'Tập thể dục 30 phút', 'icon': 'fitness_center'},
      {'name': 'Ăn rau xanh', 'icon': 'eco'},
      {'name': 'Thiền 10 phút', 'icon': 'self_improvement'},
      {'name': 'Đi bộ 10,000 bước', 'icon': 'directions_walk'},
      {'name': 'Không ăn sau 8h tối', 'icon': 'no_meals'},
      {'name': 'Đọc sách 15 phút', 'icon': 'menu_book'},
      {'name': 'Ngủ trước 11h', 'icon': 'bedtime'},
    ];
  }
}
