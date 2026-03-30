import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Theo Dõi Sức Khỏe';
  static const int defaultCalorieGoal = 2000;
  static const int defaultWaterGoal = 2000; // ml
  static const double defaultSleepGoal = 8.0; // hours

  // Gradient colors
  static const Color primaryGradientStart = Color(0xFF4CAF50);
  static const Color primaryGradientEnd = Color(0xFF00897B);
  static const Color calorieGradientStart = Color(0xFFFF8A65);
  static const Color calorieGradientEnd = Color(0xFFE53935);
  static const Color waterGradientStart = Color(0xFF42A5F5);
  static const Color waterGradientEnd = Color(0xFF1565C0);
  static const Color sleepGradientStart = Color(0xFF7E57C2);
  static const Color sleepGradientEnd = Color(0xFF311B92);
  static const Color exerciseGradientStart = Color(0xFFFF7043);
  static const Color exerciseGradientEnd = Color(0xFFD84315);
  static const Color habitGradientStart = Color(0xFF66BB6A);
  static const Color habitGradientEnd = Color(0xFF2E7D32);

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // MET values for exercises
  static const Map<String, double> exerciseMET = {
    'Chạy bộ': 9.8,
    'Đi bộ': 3.5,
    'Đạp xe': 7.5,
    'Bơi lội': 8.0,
    'Yoga': 3.0,
    'Tập tạ': 6.0,
    'Nhảy dây': 12.3,
    'Aerobic': 7.0,
    'Plank': 4.0,
    'Cầu lông': 5.5,
    'Bóng đá': 7.0,
    'Bóng rổ': 6.5,
    'Leo cầu thang': 8.0,
    'Khiêu vũ': 4.5,
  };
}
