import 'dart:convert';

class UserProfile {
  final String name;
  final String gender; // male, female
  final double heightCm;
  final double weightKg;
  final int birthYear;
  final String activityLevel; // sedentary, light, moderate, active
  final int? customCalorieGoal;

  UserProfile({
    required this.name,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.birthYear,
    this.activityLevel = 'light',
    this.customCalorieGoal,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  String get bmiAdvice {
    if (bmi < 18.5) return 'Bạn nên tăng cường dinh dưỡng và ăn nhiều hơn.';
    if (bmi < 25) return 'Chỉ số BMI lý tưởng! Hãy duy trì chế độ hiện tại.';
    if (bmi < 30) return 'Nên giảm calo và tăng cường vận động.';
    return 'Nên tham khảo ý kiến bác sĩ về chế độ ăn uống.';
  }

  int get age => DateTime.now().year - birthYear;

  // Mifflin-St Jeor equation
  int get recommendedCalories {
    if (customCalorieGoal != null) return customCalorieGoal!;
    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
      case 'light':
        multiplier = 1.375;
      case 'moderate':
        multiplier = 1.55;
      case 'active':
        multiplier = 1.725;
      default:
        multiplier = 1.375;
    }
    return (bmr * multiplier).round();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'birthYear': birthYear,
        'activityLevel': activityLevel,
        'customCalorieGoal': customCalorieGoal,
      };

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] as String,
        gender: map['gender'] as String,
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        birthYear: map['birthYear'] as int,
        activityLevel: map['activityLevel'] as String? ?? 'light',
        customCalorieGoal: map['customCalorieGoal'] as int?,
      );

  factory UserProfile.fromJson(String json) =>
      UserProfile.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
