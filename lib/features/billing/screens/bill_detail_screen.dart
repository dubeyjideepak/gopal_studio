import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../services/local_db_service.dart';
import '../../../services/whatsapp_service.dart';

final billDetailProvider = FutureProvider.family<Bill?, String>((ref, id) {
  return LocalDbService.instance.getBillById(id);
});

class BillDetailScreen extends ConsumerWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(billDetailProvider(billId));

    return billAsync.when(
      data: (bill) {
        if (bill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bill')),
            body: const Center(child: Text('Bill not found')),
          );
        }
        return _BillDetailContent(bill: bill);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _BillDetailContent extends ConsumerStatefulWidget {
  final Bill bill;
  const _BillDetailContent({required this.bill});

  @override
  ConsumerState<_BillDetailContent> createState() => _BillDetailContentState();
}

class _BillDetailContentState extends ConsumerState<_BillDetailContent> {
  final bool _isPrinting = false;

  void _printBill() {
    context.push('/bill/${widget.bill.id}/preview');
  }

  Future<void> _shareBillWhatsApp() async {
    final profile = await LocalDbService.instance.getBusinessProfile();
    if (!mounted) return;
    await WhatsAppService.instance.shareDirectToSystemWhatsApp(
      context: context,
      bill: widget.bill,
      business: profile,
    );
  }

  Future<void> _sendReminder() async {
    final profile = await LocalDbService.instance.getBusinessProfile();
    final sent = await WhatsAppService.instance.sendPaymentReminder(bill: widget.bill, business: profile);
    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number found for this customer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final dateStr = DateFormat('dd MMM yyyy').format(bill.createdAt);
    final statusColor = _statusColor(bill.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bill #${bill.billNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.print_rounded, color: AppColors.gold),
            onPressed: _isPrinting ? null : _printBill,
            tooltip: 'Print Bill',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: AppColors.elevated,
            onSelected: (value) {
              switch (value) {
                case 'share': _shareBillWhatsApp();
                case 'reminder': _sendReminder();
                case 'settle': context.push('/bill/${bill.id}/settle');
                case 'preview': context.push('/bill/${bill.id}/preview');
              }
            },
            itemBuilder: (_) => [
              _popupItem('preview', Icons.visibility_rounded, 'Preview Receipt'),
              _popupItem('share', Icons.share_rounded, 'Share on WhatsApp'),
              _popupItem('reminder', Icons.notifications_active_rounded, 'Send Reminder'),
              if (!bill.isFullyPaid) _popupItem('settle', Icons.payments_rounded, 'Add Payment'),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(bill.status), color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(_statusText(bill.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  if (!bill.isFullyPaid)
                    GestureDetector(
                      onTap: () => context.push('/bill/${bill.id}/settle'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Add Payment', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Customer Card
            _SectionCard(
              title: 'Customer',
              child: Column(
                children: [
                  _InfoRow(Icons.person_rounded, 'Name', bill.customerName),
                  if (bill.customerMobile != null)
                    _InfoRow(Icons.phone_rounded, 'Mobile', bill.customerMobile!),
                  _InfoRow(Icons.calendar_today_rounded, 'Bill Date', dateStr),
                  if (bill.deliveryDate != null)
                    _InfoRow(Icons.local_shipping_rounded, 'Delivery',
                        DateFormat('dd MMM yyyy').format(bill.deliveryDate!)),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Items Card
            _SectionCard(
              title: 'Items',
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Particulars', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700))),
                        Expanded(child: Text('Qty', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                        Expanded(child: Text('Rate', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                        Expanded(child: Text('Amt', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ...bill.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.particulars, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                if (item.size != null)
                                  Text(item.size!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Expanded(child: Text('${item.quantity.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center)),
                          Expanded(child: Text('\u20b9${item.rate.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center)),
                          Expanded(child: Text('\u20b9${item.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 12),

            // Totals Card
            _SectionCard(
              title: 'Payment Summary',
              child: Column(
                children: [
                  _AmountRow('Total Amount', bill.totalAmount, color: AppColors.textPrimary, bold: true),
                  if (bill.advanceAmount > 0) _AmountRow('Advance Paid', bill.advanceAmount, color: AppColors.success),
                  _AmountRow('Total Paid', bill.paidAmount, color: AppColors.success),
                  const Divider(color: AppColors.border),
                  _AmountRow('Balance Due', bill.remainingBalance,
                      color: bill.isFullyPaid ? AppColors.success : AppColors.warning, bold: true),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            // Payment History
            if (bill.paymentHistory.isNotEmpty) ...
              [
                _SectionCard(
                  title: 'Payment History',
                  child: Column(
                    children: bill.paymentHistory.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                p.type == PaymentType.upi ? Icons.qr_code_rounded : Icons.money_rounded,
                                color: AppColors.success, size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.note ?? 'Payment received', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\u20b9${p.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p.type.name.toUpperCase(), style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 12),
              ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printBill,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareBillWhatsApp(),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),

            if (!bill.isFullyPaid) ...
              [
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/bill/${bill.id}/settle'),
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Record Payment'),
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BillStatus s) {
    switch (s) {
      case BillStatus.paid: return AppColors.success;
      case BillStatus.partial: return AppColors.warning;
      case BillStatus.pending: return AppColors.error;
      case BillStatus.cancelled: return AppColors.textMuted;
    }
  }

  IconData _statusIcon(BillStatus s) {
    switch (s) {
      case BillStatus.paid: return Icons.check_circle_rounded;
      case BillStatus.partial: return Icons.hourglass_top_rounded;
      case BillStatus.pending: return Icons.warning_rounded;
      case BillStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  String _statusText(BillStatus s) {
    switch (s) {
      case BillStatus.paid: return 'Fully Paid';
      case BillStatus.partial: return 'Partially Paid';
      case BillStatus.pending: return 'Payment Pending';
      case BillStatus.cancelled: return 'Cancelled';
    }
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  const _AmountRow(this.label, this.amount, {required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: bold ? 15 : 14)),
          Text('\u20b9${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: bold ? 17 : 15)),
        ],
      ),
    );
  }
}
