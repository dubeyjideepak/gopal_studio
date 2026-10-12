import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.gold, size: 48),
                ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
                const SizedBox(height: 24),
                const Text(
                  'Gopal Studio Pro',
                  style: TextStyle(fontFamily: 'PlayfairDisplay', color: AppColors.gold, fontSize: 30, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 8),
                const Text(
                  'Capturing Memory, Creating Story',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Enter Billing Studio'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
