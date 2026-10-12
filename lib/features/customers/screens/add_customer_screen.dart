import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/local_db_service.dart';
import '../../../shared/widgets/gold_text_field.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await LocalDbService.instance.createCustomer(
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      if (mounted) context.pop();
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
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Client'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.gold.withOpacity(0.15),
                child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            GoldTextField(
              controller: _nameCtrl,
              labelText: 'Client / Party Name *',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            GoldTextField(
              controller: _mobileCtrl,
              labelText: 'Mobile / WhatsApp Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            GoldTextField(
              controller: _addressCtrl,
              labelText: 'Address / Location',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            GoldTextField(
              controller: _emailCtrl,
              labelText: 'Email Address (optional)',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.person_add_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save Client'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
