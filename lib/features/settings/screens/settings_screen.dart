import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/business_profile_model.dart';
import '../../../services/local_db_service.dart';
import '../../../services/app_activation_service.dart';
import '../../../services/cloud_backup_service.dart';
import '../../../shared/widgets/gold_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  BusinessProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phone1Ctrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  final String _appVersion = '1.0.0+1';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalDbService.instance.getBusinessProfile();
    _businessNameCtrl.text = profile.businessName;
    _ownerNameCtrl.text = profile.ownerName;
    _taglineCtrl.text = profile.tagline ?? '';
    _addressCtrl.text = profile.address ?? '';
    _phone1Ctrl.text = profile.phone1;
    _phone2Ctrl.text = profile.phone2 ?? '';
    _upiCtrl.text = profile.upiId ?? '';
    _emailCtrl.text = profile.email ?? '';
    _youtubeCtrl.text = profile.youtubeChannel ?? '@GopalPhotographyStudio';
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _isSaving = true);
    try {
      final updated = _profile!.copyWith(
        businessName: _businessNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim().isEmpty ? null : _taglineCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phone1: _phone1Ctrl.text.trim(),
        phone2: _phone2Ctrl.text.trim().isEmpty ? null : _phone2Ctrl.text.trim(),
        upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        youtubeChannel: _youtubeCtrl.text.trim().isEmpty ? null : _youtubeCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await LocalDbService.instance.saveBusinessProfile(updated);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Studio profile & YouTube channel saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _upiCtrl.dispose();
    _emailCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Studio Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.save_rounded, color: AppColors.gold, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/gopal_media_crest.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.gold,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gopal',
                  style: GoogleFonts.greatVibes(
                    color: AppColors.gold,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),
          const _SectionTitle('Studio Branding'),
          const SizedBox(height: 12),
          GoldTextField(controller: _businessNameCtrl, labelText: 'Business Name', prefixIcon: Icons.store_rounded),
          const SizedBox(height: 12),
          GoldTextField(controller: _ownerNameCtrl, labelText: 'Owner / Prop. Name', prefixIcon: Icons.person_rounded),
          const SizedBox(height: 12),
          GoldTextField(controller: _taglineCtrl, labelText: 'Tagline', prefixIcon: Icons.format_quote_rounded),
          const SizedBox(height: 12),
          GoldTextField(controller: _addressCtrl, labelText: 'Full Studio Address', prefixIcon: Icons.location_on_rounded, maxLines: 2),

          const SizedBox(height: 20),
          const _SectionTitle('Contact Numbers (Printed on Bills)'),
          const SizedBox(height: 12),
          GoldTextField(controller: _phone1Ctrl, labelText: 'Primary Mobile No. *', prefixIcon: Icons.phone_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          GoldTextField(controller: _phone2Ctrl, labelText: 'WhatsApp Number (Printed on Slip)', prefixIcon: Icons.chat_bubble_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          GoldTextField(controller: _emailCtrl, labelText: 'Studio Email', prefixIcon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none),

          const SizedBox(height: 20),
          const _SectionTitle('YouTube & Social Links (Printed on Slip)'),
          const SizedBox(height: 12),
          GoldTextField(
            controller: _youtubeCtrl,
            labelText: 'YouTube Channel Handle / URL (e.g. @GopalPhotographyStudio)',
            prefixIcon: Icons.play_circle_fill_rounded,
            textCapitalization: TextCapitalization.none,
          ),

          const SizedBox(height: 20),
          const _SectionTitle('Business UPI (Printed as QR on Bill)'),
          const SizedBox(height: 12),
          GoldTextField(
            controller: _upiCtrl,
            labelText: 'UPI ID (e.g. 9935006921@upi or yourname@okicici)',
            prefixIcon: Icons.qr_code_rounded,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          if (_upiCtrl.text.isNotEmpty && _upiCtrl.text.contains('@'))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: 'upi://pay?pa=${_upiCtrl.text.trim()}&pn=${Uri.encodeComponent(_businessNameCtrl.text.trim())}',
                    version: QrVersions.auto,
                    size: 160,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0D0D0D)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0D0D0D)),
                  ),
                  const SizedBox(height: 8),
                  Text(_upiCtrl.text.trim(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('Live QR Code preview rendered on Bills & Receipts', style: TextStyle(color: Colors.black54, fontSize: 11)),
                ],
              ),
            ).animate().fadeIn(),

          const SizedBox(height: 24),
          const _SectionTitle('Bill Configuration'),
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: LocalDbService.instance.getCurrentBillNumber(),
            builder: (ctx, snap) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Issued Bill Number', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('Sequential auto-incrementing', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  Text('#${snap.data ?? 0}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const _SectionTitle('App Activation & License (Firebase)'),
          const SizedBox(height: 12),
          const _ActivationCard(),

          const SizedBox(height: 24),
          const _SectionTitle('Cloud Data Backup & Restore (Firestore)'),
          const SizedBox(height: 12),
          const _CloudBackupCard(),

          const SizedBox(height: 24),
          const _SectionTitle('System & Updates'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.sync_rounded,
            title: 'Firestore Sync Status',
            trailing: const Text('Multi-App Firestore Connected', style: TextStyle(color: AppColors.success, fontSize: 12)),
          ),
          _SettingsTile(
            icon: Icons.system_update_rounded,
            title: 'App Version',
            trailing: Text(_appVersion, style: const TextStyle(color: AppColors.textMuted)),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.border, thickness: 0.5)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold, size: 20),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ActivationCard extends ConsumerStatefulWidget {
  const _ActivationCard();

  @override
  ConsumerState<_ActivationCard> createState() => _ActivationCardState();
}

class _ActivationCardState extends ConsumerState<_ActivationCard> {
  bool _isSyncing = false;

  Future<void> _syncLicense() async {
    setState(() => _isSyncing = true);
    try {
      final info = await ref
          .read(activationStateProvider.notifier)
          .checkActivation(forceOnlineCheck: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              info.isOnline
                  ? 'Firestore heartbeat verified! App is active.'
                  : 'Offline mode. Operating within 15-day grace period (${info.daysRemaining} days remaining).',
            ),
            backgroundColor: info.isOnline ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync check error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activationAsync = ref.watch(activationStateProvider);

    return activationAsync.when(
      data: (info) {
        final lastSyncStr = info.lastConnectedAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(info.lastConnectedAt!)
            : 'Pending initial sync';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: info.isActive ? AppColors.gold.withOpacity(0.4) : AppColors.error,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        info.isActive ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                        color: info.isActive ? AppColors.gold : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'License & Activation',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: info.isActive
                          ? (info.isGracePeriod
                              ? AppColors.warning.withOpacity(0.15)
                              : AppColors.success.withOpacity(0.15))
                          : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      info.isActive
                          ? (info.isGracePeriod ? 'Grace (${info.daysRemaining}d)' : 'ACTIVE')
                          : 'LOCKED',
                      style: TextStyle(
                        color: info.isActive
                            ? (info.isGracePeriod ? AppColors.warning : AppColors.success)
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('App ID:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text(
                    info.appId,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Platform:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      info.platform.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Client ID:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: info.clientId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Client ID copied to clipboard!'),
                          backgroundColor: AppColors.gold,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            info.clientId,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded, color: AppColors.gold, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Last Heartbeat:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text(lastSyncStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _syncLicense,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(_isSyncing ? 'Verifying with Firestore...' : 'Sync Heartbeat to Firestore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _CloudBackupCard extends ConsumerWidget {
  const _CloudBackupCard();

  void _confirmRestore(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text('Restore from Firestore', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Text(
          'This will download all bills, client records, and studio settings backed up for this Client ID from Firestore and merge them into your local database.\n\nDo you want to proceed?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref.read(cloudBackupStateProvider.notifier).restoreAll();
              if (context.mounted) {
                final status = ref.read(cloudBackupStateProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? status.lastSuccessMessage ?? 'Restore completed successfully!'
                        : 'Restore failed: ${status.lastError ?? "Check internet connection"}'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Restore Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupStatus = ref.watch(cloudBackupStateProvider);
    final lastBackupStr = backupStatus.lastBackupAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(backupStatus.lastBackupAt!)
        : 'Auto-sync active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Automatic Cloud Sync',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Local Bills:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text('${backupStatus.billsCount} records',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Local Clients:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text('${backupStatus.customersCount} records',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Offline Queue:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(
                backupStatus.pendingCount > 0
                    ? '${backupStatus.pendingCount} pending (syncs on reconnect)'
                    : 'All changes synced',
                style: TextStyle(
                  color: backupStatus.pendingCount > 0 ? AppColors.warning : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Auto-Sync:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(lastBackupStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    backupStatus.isOnline
                        ? 'Zero-touch continuous auto-sync is running. Every bill and client change saves automatically to Firestore.'
                        : 'Currently offline. All changes are securely queued and will automatically sync when internet returns.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: backupStatus.isSyncing ? null : () => _confirmRestore(context, ref),
              icon: backupStatus.isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                    )
                  : const Icon(Icons.cloud_download_rounded, size: 16),
              label: const Text('Restore Data from Cloud (New Device Migration)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


