import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../services/local_db_service.dart';
import '../../../services/whatsapp_service.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  final String billId;
  const SettlementScreen({super.key, required this.billId});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  final _uuid = const Uuid();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  PaymentType _paymentType = PaymentType.cash;
  bool _isSaving = false;
  Bill? _bill;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    final bill = await LocalDbService.instance.getBillById(widget.billId);
    if (mounted) setState(() => _bill = bill);
  }

  Future<void> _recordPayment() async {
    if (_bill == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (amount > _bill!.remainingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds outstanding balance')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payment = PaymentEntry(
        id: _uuid.v4(),
        amount: amount,
        type: _paymentType,
        date: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      final newPaid = _bill!.paidAmount + amount;
      final newBalance = _bill!.totalAmount - newPaid;
      final newStatus = newBalance <= 0 ? BillStatus.paid : BillStatus.partial;

      final updatedBill = _bill!.copyWith(
        paidAmount: newPaid,
        balanceAmount: newBalance < 0 ? 0 : newBalance,
        status: newStatus,
        paymentHistory: [..._bill!.paymentHistory, payment],
      );

      await LocalDbService.instance.saveBill(updatedBill);
      await LocalDbService.instance
          .recalculateCustomerBalance(_bill!.customerId);

      if (mounted) {
        final sendWA = await _showWhatsAppDialog(updatedBill, amount);
        if (sendWA == true) {
          final profile = await LocalDbService.instance.getBusinessProfile();
          await WhatsAppService.instance.shareBill(
            bill: updatedBill,
            business: profile,
            isPartial: !updatedBill.isFullyPaid,
          );
        }
        if (mounted) {
          context.pop();
          context.pop();
          context.push('/bill/${updatedBill.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showWhatsAppDialog(Bill bill, double amount) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) {
      return false;
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Share Receipt?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Share updated receipt on WhatsApp with ${bill.customerName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsapp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _bill == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bill #${_bill!.billNumber}',
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(_bill!.customerName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _BillSummaryItem(
                                label: 'Total',
                                value:
                                    '₹${_bill!.totalAmount.toStringAsFixed(0)}',
                                color: AppColors.textPrimary),
                            _BillSummaryItem(
                                label: 'Paid',
                                value:
                                    '₹${_bill!.paidAmount.toStringAsFixed(0)}',
                                color: AppColors.success),
                            _BillSummaryItem(
                                label: 'Balance',
                                value:
                                    '₹${_bill!.remainingBalance.toStringAsFixed(0)}',
                                color: AppColors.warning),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  const Text('Payment Amount',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _QuickAmountBtn(
                        label: 'Full Balance',
                        amount: _bill!.remainingBalance,
                        onTap: () => setState(() => _amountCtrl.text =
                            _bill!.remainingBalance.toStringAsFixed(0)),
                      ),
                      const SizedBox(width: 8),
                      _QuickAmountBtn(
                        label: 'Half',
                        amount: _bill!.remainingBalance / 2,
                        onTap: () => setState(() => _amountCtrl.text =
                            (_bill!.remainingBalance / 2).toStringAsFixed(0)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _amountCtrl,
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                      hintText: '0',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 28),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    onChanged: (_) => setState(() {}),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 20),

                  const Text('Payment Method',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),

                  Row(
                    children: PaymentType.values.map((type) {
                      final selected = _paymentType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.gold.withOpacity(0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.gold
                                    : AppColors.border,
                                width: selected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type == PaymentType.cash
                                      ? Icons.money_rounded
                                      : type == PaymentType.upi
                                          ? Icons.qr_code_rounded
                                          : Icons.payment_rounded,
                                  color: selected
                                      ? AppColors.gold
                                      : AppColors.textMuted,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  const Text('Note (Optional)',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. UPI Ref / GPay Ref ID...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.5),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _recordPayment,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                          _isSaving ? 'Recording...' : 'Record Payment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _BillSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BillSummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

class _QuickAmountBtn extends StatelessWidget {
  final String label;
  final double amount;
  final VoidCallback onTap;
  const _QuickAmountBtn(
      {required this.label, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
