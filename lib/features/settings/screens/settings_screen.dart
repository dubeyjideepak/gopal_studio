import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/business_profile_model.dart';
import '../../../services/local_db_service.dart';
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
        updatedAt: DateTime.now(),
      );
      await LocalDbService.instance.saveBusinessProfile(updated);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Studio profile & UPI details saved!'),
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
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.1),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.gold, size: 40),
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
          GoldTextField(controller: _phone2Ctrl, labelText: 'Secondary / Alternate No.', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          GoldTextField(controller: _emailCtrl, labelText: 'Studio Email', prefixIcon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none),

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
          const _SectionTitle('System & Updates'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.sync_rounded,
            title: 'Firestore Sync Status',
            trailing: const Text('Offline Ready (Local Cache)', style: TextStyle(color: AppColors.success, fontSize: 12)),
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
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap});

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
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
