import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import 'auth_screen.dart';

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
    try {
      final profile = await DatabaseService.instance.getUserProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: Text(AuthService.instance.isAnonymous
            ? 'Bạn đang dùng tài khoản tạm. Đăng xuất sẽ mất toàn bộ dữ liệu. Bạn có chắc?'
            : 'Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _showLinkAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscurePass = true;
    bool obscureConfirm = true;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tạo tài khoản'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Liên kết email để giữ dữ liệu và đăng nhập trên thiết bị khác.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (errorMsg != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMsg!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nhập email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setDialogState(() => obscurePass = !obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                      if (v.length < 6) return 'Cần ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isLoading = true;
                        errorMsg = null;
                      });
                      try {
                        await AuthService.instance.linkWithEmail(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {}); // refresh UI to hide the banner
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tạo tài khoản thành công! Dữ liệu đã được liên kết.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() {
                          errorMsg = AuthService.getErrorMessage(e);
                          isLoading = false;
                        });
                      } catch (e) {
                        setDialogState(() {
                          errorMsg = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
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

                // Anonymous account banner
                if (AuthService.instance.isAnonymous) ...[
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: theme.colorScheme.onTertiaryContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bạn đang dùng tài khoản tạm thời. Tạo tài khoản để giữ dữ liệu an toàn.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onTertiaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _showLinkAccountDialog,
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('Tạo tài khoản'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                const SizedBox(height: 16),

                // Account info
                Card(
                  child: ListTile(
                    leading: Icon(
                      AuthService.instance.isAnonymous
                          ? Icons.person_off_outlined
                          : Icons.email_outlined,
                    ),
                    title: Text(AuthService.instance.isAnonymous
                        ? 'Tài khoản tạm thời'
                        : 'Tài khoản'),
                    subtitle: Text(AuthService.instance.isAnonymous
                        ? 'Chưa liên kết email'
                        : AuthService.instance.currentUser?.email ?? ''),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
