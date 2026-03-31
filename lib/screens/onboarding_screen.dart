import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // User data
  final _nameController = TextEditingController();
  String _gender = 'male';
  double _height = 165;
  double _weight = 60;
  int _birthYear = 2000;
  String _activityLevel = 'light';
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  UserProfile _buildProfile() {
    return UserProfile(
      name: _nameController.text.trim().isEmpty
          ? 'Người dùng'
          : _nameController.text.trim(),
      gender: _gender,
      heightCm: _height,
      weightKg: _weight,
      birthYear: _birthYear,
      activityLevel: _activityLevel,
    );
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final profile = _buildProfile();
    try {
      await DatabaseService.instance.saveUserProfile(profile)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Save profile error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(theme),
                  _buildPersonalInfoPage(theme),
                  _buildBodyMetricsPage(theme),
                  _buildSummaryPage(theme),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Quay lại'),
                    ),
                  const Spacer(),
                  if (_currentPage < 3)
                    FilledButton.icon(
                      onPressed: _nextPage,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Tiếp tục'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _finish,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Đang lưu...' : 'Bắt đầu'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryGradientStart,
                  AppConstants.primaryGradientEnd,
                ],
              ),
            ),
            child: const Icon(Icons.favorite, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            'Theo Dõi Sức Khỏe',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Ứng dụng giúp bạn theo dõi calo, nước uống, giấc ngủ, '
            'vận động và xây dựng thói quen lành mạnh mỗi ngày.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin cá nhân',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Giúp chúng tôi cá nhân hóa cho bạn',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên của bạn',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          Text('Giới tính', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SelectionCard(
                  icon: Icons.male,
                  label: 'Nam',
                  isSelected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectionCard(
                  icon: Icons.female,
                  label: 'Nữ',
                  isSelected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Năm sinh', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _birthYear,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.cake),
            ),
            items: List.generate(60, (i) {
              final year = DateTime.now().year - 10 - i;
              return DropdownMenuItem(value: year, child: Text('$year'));
            }),
            onChanged: (v) => setState(() => _birthYear = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chỉ số cơ thể',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Chiều cao: ${_height.round()} cm',
              style: theme.textTheme.titleMedium),
          Slider(
            value: _height,
            min: 100,
            max: 220,
            divisions: 120,
            label: '${_height.round()} cm',
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),
          Text('Cân nặng: ${_weight.round()} kg',
              style: theme.textTheme.titleMedium),
          Slider(
            value: _weight,
            min: 30,
            max: 150,
            divisions: 120,
            label: '${_weight.round()} kg',
            onChanged: (v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 16),
          Text('Mức độ vận động', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _activityLevel,
            onChanged: (v) => setState(() => _activityLevel = v!),
            child: Column(
              children: [
                ('sedentary', 'Ít vận động', 'Ngồi văn phòng cả ngày'),
                ('light', 'Vận động nhẹ', 'Tập 1-3 lần/tuần'),
                ('moderate', 'Vận động vừa', 'Tập 3-5 lần/tuần'),
                ('active', 'Vận động nhiều', 'Tập 6-7 lần/tuần'),
              ].map((item) => RadioListTile<String>(
                    value: item.$1,
                    title: Text(item.$2),
                    subtitle: Text(item.$3),
                    contentPadding: EdgeInsets.zero,
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage(ThemeData theme) {
    final profile = _buildProfile();
    final bmiColor = profile.bmi < 18.5
        ? Colors.blue
        : profile.bmi < 25
            ? Colors.green
            : profile.bmi < 30
                ? Colors.orange
                : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Tổng kết',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Chỉ số sức khỏe của bạn',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: (profile.bmi / 40).clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.bmi.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                Text('BMI', style: theme.textTheme.labelLarge),
              ],
            ),
            progressColor: bmiColor,
            backgroundColor: bmiColor.withValues(alpha: 0.2),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(profile.bmiCategory),
            backgroundColor: bmiColor.withValues(alpha: 0.15),
            labelStyle: TextStyle(color: bmiColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bmiAdvice,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'Mục tiêu calo/ngày',
                      value: '${profile.recommendedCalories} kcal'),
                  const Divider(),
                  _SummaryRow(
                      label: 'Mục tiêu nước/ngày',
                      value: '${AppConstants.defaultWaterGoal} ml'),
                  const Divider(),
                  _SummaryRow(
                      label: 'Mục tiêu giấc ngủ',
                      value: '${AppConstants.defaultSleepGoal.round()} giờ'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
