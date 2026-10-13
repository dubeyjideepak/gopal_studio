import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/app_activation_service.dart';

class AppActivationLockScreen extends ConsumerStatefulWidget {
  const AppActivationLockScreen({super.key});

  @override
  ConsumerState<AppActivationLockScreen> createState() => _AppActivationLockScreenState();
}

class _AppActivationLockScreenState extends ConsumerState<AppActivationLockScreen> {
  bool _isChecking = false;

  Future<void> _verifyNow() async {
    setState(() => _isChecking = true);
    try {
      final info = await ref
          .read(activationStateProvider.notifier)
          .checkActivation(forceOnlineCheck: true);

      if (mounted) {
        if (info.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App successfully activated! Welcome back.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                info.deactivationReason ??
                    'App is still inactive in Firebase. Please request activation from admin.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e. Please check internet connection.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _contactAdmin(String clientId, String platform) async {
    final message = Uri.encodeComponent(
      'Hello Admin, please activate StudioBill Pro.\n\n'
      'App ID: studiobill_pro\n'
      'Client ID: $clientId\n'
      'Platform: ${platform.toUpperCase()}\n\n'
      'Please toggle is_active = true in Firebase console.',
    );
    final url = Uri.parse('https://wa.me/919935006921?text=$message');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client ID copied to clipboard!'),
        backgroundColor: AppColors.gold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activationAsync = ref.watch(activationStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: activationAsync.when(
                data: (info) => _buildLockContent(context, info),
                loading: () => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.gold),
                    SizedBox(height: 16),
                    Text(
                      'Checking Activation Status...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                error: (e, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error checking license: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _verifyNow,
                      child: const Text('Retry Verification'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockContent(BuildContext context, ActivationInfo info) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Lock Icon with Gold/Red accent glow
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withOpacity(0.12),
            border: Border.all(color: AppColors.error.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            color: AppColors.error,
            size: 48,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        // Title
        const Text(
          'Activation Required',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 8),

        // Subtitle / Reason
        Text(
          info.deactivationReason ??
              'This installation is currently not active. Please contact the administrator or verify your network connection to re-activate.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 28),

        // Client & App Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App ID Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'App ID',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      info.appId,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),

              // Platform Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Platform',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      info.platform.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),

              // Client ID Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Identifier',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      Text(
                        'Share this ID with Admin',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(info.clientId),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            info.clientId,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, color: AppColors.gold, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: AppColors.border, height: 24),

              // Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_rounded, color: AppColors.error, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'INACTIVE / LOCKED',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (info.daysDisconnected > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Days Offline',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    Text(
                      '${info.daysDisconnected} days (Limit: 15)',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

        const SizedBox(height: 28),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isChecking ? null : _verifyNow,
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(_isChecking ? 'Verifying with Firebase...' : 'Verify & Activate Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactAdmin(info.clientId, info.platform),
            icon: const Icon(Icons.chat_rounded, color: AppColors.whatsapp),
            label: const Text('Contact Admin via WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.whatsapp.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ).animate().fadeIn(delay: 450.ms),

        const SizedBox(height: 24),

        const Text(
          'Note: App requires an active Firestore heartbeat at least once every 15 days to remain valid.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
