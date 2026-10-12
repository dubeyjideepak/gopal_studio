import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/business_profile_model.dart';
import '../../../services/local_db_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import 'bill_detail_screen.dart' show billDetailProvider;

class BillPreviewScreen extends ConsumerStatefulWidget {
  final String billId;
  const BillPreviewScreen({super.key, required this.billId});

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  BusinessProfile? _profile;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await LocalDbService.instance.getBusinessProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final billAsync = ref.watch(billDetailProvider(widget.billId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Slip Preview & Hardcopy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.print_rounded, color: AppColors.gold),
            onPressed: _isPrinting
                ? null
                : () async {
                    if (billAsync.value == null || _profile == null) return;
                    setState(() => _isPrinting = true);
                    await PdfService.instance.printBill(billAsync.value!, _profile!);
                    if (mounted) setState(() => _isPrinting = false);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.gold),
            onPressed: () async {
              if (billAsync.value == null || _profile == null) return;
              await PdfService.instance.sharePdf(billAsync.value!, _profile!);
            },
          ),
        ],
      ),
      body: billAsync.when(
        data: (bill) {
          if (bill == null || _profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _BillReceiptView(bill: bill, profile: _profile!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: billAsync.maybeWhen(
        data: (bill) {
          if (bill == null) return null;
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (_profile == null) return;
                      await WhatsAppService.instance.shareBill(
                        bill: bill,
                        business: _profile!,
                        isPartial: !bill.isFullyPaid,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsapp),
                    label: const Text('WhatsApp Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : () async {
                      if (_profile == null) return;
                      setState(() => _isPrinting = true);
                      await PdfService.instance.printBill(bill, _profile!);
                      if (mounted) setState(() => _isPrinting = false);
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Slip'),
                  ),
                ),
              ],
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _BillReceiptView extends StatelessWidget {
  final Bill bill;
  final BusinessProfile profile;
  const _BillReceiptView({required this.bill, required this.profile});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(bill.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded, color: Color(0xFFC9A84C), size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          profile.businessName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFC9A84C),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (profile.tagline != null) ...[
                    const SizedBox(height: 2),
                    Text(profile.tagline!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 8),
                  if (profile.address != null)
                    Text(profile.address!, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                  Text('Mob.: ${profile.phone1}${profile.phone2 != null ? " / ${profile.phone2}" : ""}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CASH MEMO', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                          Text('Bill No: #${bill.billNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF9B7B2C))),
                        ],
                      ),
                      Text('Date: $dateStr', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  const Divider(height: 24, thickness: 1),

                  Text('M/s: ${bill.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  if (bill.customerMobile != null)
                    Text('Mob: ${bill.customerMobile}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                  if (bill.deliveryDate != null)
                    Text('Delivery Date: ${DateFormat('dd MMM yyyy').format(bill.deliveryDate!)}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 14),

                  Table(
                    border: TableBorder.all(color: Colors.grey.shade400),
                    columnWidths: const {
                      0: FixedColumnWidth(34),
                      1: FlexColumnWidth(3),
                      2: FixedColumnWidth(44),
                      3: FixedColumnWidth(60),
                      4: FixedColumnWidth(70),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                        children: [
                          _th('S.No'),
                          _th('Particulars / Size'),
                          _th('Qty'),
                          _th('Rate'),
                          _th('Amount'),
                        ],
                      ),
                      ...bill.items.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        return TableRow(
                          decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey.shade100),
                          children: [
                            _td('${i + 1}', center: true),
                            _tdMulti(item.particulars, item.size),
                            _td(item.quantity.toStringAsFixed(0), center: true),
                            _td(item.rate.toStringAsFixed(0), center: true),
                            _td(item.amount.toStringAsFixed(0), right: true),
                          ],
                        );
                      }),
                      ...List.generate(
                        (4 - bill.items.length).clamp(0, 4),
                        (_) => TableRow(children: List.generate(5, (_) => _td(''))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 220,
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade400),
                        children: [
                          _totalRow('Total', bill.totalAmount, bold: true),
                          if (bill.advanceAmount > 0) _totalRow('Advance', bill.advanceAmount),
                          _totalRow('Balance Due', bill.remainingBalance, highlight: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (profile.upiId != null && profile.upiId!.contains('@'))
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QrImageView(
                              data: 'upi://pay?pa=${profile.upiId}&pn=${Uri.encodeComponent(profile.businessName)}',
                              version: QrVersions.auto,
                              size: 110,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Scan & Pay via any UPI App (GPay, PhonePe, Paytm)', style: TextStyle(fontSize: 10, color: Colors.black87)),
                          Text(profile.upiId!, style: const TextStyle(fontSize: 11, color: Color(0xFF9B7B2C), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 30),
                          Container(width: 110, height: 1, color: Colors.black54),
                          const Text('Customer Signature', style: TextStyle(fontSize: 10, color: Colors.black87)),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 30),
                          Container(width: 110, height: 1, color: Colors.black54),
                          const Text('Authorized Signature', style: TextStyle(fontSize: 10, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: Text(text, style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  );

  Widget _td(String text, {bool center = false, bool right = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 11), textAlign: right ? TextAlign.right : center ? TextAlign.center : TextAlign.left),
  );

  Widget _tdMulti(String main, String? sub) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(main, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
        if (sub != null) Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 9)),
      ],
    ),
  );

  TableRow _totalRow(String label, double amount, {bool bold = false, bool highlight = false}) {
    final style = TextStyle(
      color: highlight ? const Color(0xFF9B7B2C) : Colors.black87,
      fontWeight: bold || highlight ? FontWeight.bold : FontWeight.normal,
      fontSize: 12,
    );
    return TableRow(
      decoration: highlight ? const BoxDecoration(color: Color(0xFFFFF9EC)) : null,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Text(label, style: style)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Text('₹${amount.toStringAsFixed(0)}', style: style, textAlign: TextAlign.right)),
      ],
    );
  }
}
