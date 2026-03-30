import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.instance.getUserProfile();
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _profile!.name.isNotEmpty
                              ? _profile!.name[0].toUpperCase()
                              : 'U',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_profile!.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${_profile!.age} tuổi • ${_profile!.gender == 'male' ? 'Nam' : 'Nữ'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BMI card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircularPercentIndicator(
                          radius: 50,
                          lineWidth: 8,
                          percent: (_profile!.bmi / 40).clamp(0.0, 1.0),
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profile!.bmi.toStringAsFixed(1),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('BMI',
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                          progressColor: _bmiColor(_profile!.bmi),
                          backgroundColor:
                              _bmiColor(_profile!.bmi).withValues(alpha: 0.2),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_profile!.bmiCategory,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _bmiColor(_profile!.bmi),
                                    fontSize: 16,
                                  )),
                              const SizedBox(height: 4),
                              Text(_profile!.bmiAdvice,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Body info
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                          icon: Icons.height,
                          label: 'Chiều cao',
                          value: '${_profile!.heightCm.round()} cm'),
                      const Divider(height: 1),
                      _InfoTile(
                          icon: Icons.monitor_weight,
                          label: 'Cân nặng',
                          value: '${_profile!.weightKg.round()} kg'),
                      const Divider(height: 1),
                      _InfoTile(
                          icon: Icons.local_fire_department,
                          label: 'Mục tiêu calo',
                          value: '${_profile!.recommendedCalories} kcal/ngày'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Theme toggle
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      themeProvider.isDark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    title: const Text('Chế độ tối'),
                    subtitle: Text(
                        themeProvider.isDark ? 'Đang bật' : 'Đang tắt'),
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
              ],
            ),
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
