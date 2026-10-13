import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/local_db_service.dart';
import '../../../shared/models/business_profile_model.dart';
import '../../../shared/widgets/gold_text_field.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController(text: 'Gopal Photography Studio');
  final _ownerNameCtrl = TextEditingController(text: 'Gopal');
  final _phone1Ctrl = TextEditingController(text: '9935006921');
  final _phone2Ctrl = TextEditingController(text: '8115989543');
  final _addressCtrl = TextEditingController(text: 'Jalesarganj Road, Lalganj Ajhara, Pratapgarh');
  final _taglineCtrl = TextEditingController(text: 'Capturing Memory, Creating Story');
  final _upiCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final profile = BusinessProfile(
        id: 'default',
        businessName: _businessNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim().isEmpty ? null : _taglineCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phone1: _phone1Ctrl.text.trim(),
        phone2: _phone2Ctrl.text.trim().isEmpty ? null : _phone2Ctrl.text.trim(),
        upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await LocalDbService.instance.saveBusinessProfile(profile);
      await LocalDbService.instance.setFirstRunDone();
      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 12,
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
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gopal',
                      style: GoogleFonts.greatVibes(
                        color: AppColors.gold,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STUDIO SETUP',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Center(child: Text('Configure your photography studio header', style: TextStyle(color: AppColors.textMuted))),
              const SizedBox(height: 32),
              GoldTextField(controller: _businessNameCtrl, labelText: 'Business Name *', prefixIcon: Icons.store_rounded, validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 14),
              GoldTextField(controller: _ownerNameCtrl, labelText: 'Owner / Prop. *', prefixIcon: Icons.person_rounded, validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 14),
              GoldTextField(controller: _taglineCtrl, labelText: 'Tagline', prefixIcon: Icons.format_quote_rounded),
              const SizedBox(height: 14),
              GoldTextField(controller: _addressCtrl, labelText: 'Studio Address', prefixIcon: Icons.location_on_rounded, maxLines: 2),
              const SizedBox(height: 14),
              GoldTextField(controller: _phone1Ctrl, labelText: 'Primary Mobile No. *', prefixIcon: Icons.phone_rounded, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 14),
              GoldTextField(controller: _phone2Ctrl, labelText: 'Alternate Mobile No.', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 14),
              GoldTextField(controller: _upiCtrl, labelText: 'Business UPI ID (for QR receipt)', prefixIcon: Icons.qr_code_rounded, textCapitalization: TextCapitalization.none),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Configuring Studio...' : 'Start Billing'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
