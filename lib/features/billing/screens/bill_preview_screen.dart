import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
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
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final billAsync = ref.watch(billDetailProvider(widget.billId));

    return Scaffold(
      backgroundColor: const Color(0xFF15181E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1626),
        title: const Text('Cash Memo • Print & PDF Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : const Icon(Icons.share_rounded, color: AppColors.gold),
            tooltip: 'Share PDF File',
            onPressed: () async {
              final bill = billAsync.value;
              if (bill == null) return;
              setState(() => _isSharing = true);
              final profile = await LocalDbService.instance.getBusinessProfile();
              await PdfService.instance.sharePdf(bill, profile);
              if (mounted) setState(() => _isSharing = false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
            tooltip: 'Send PDF Directly to WhatsApp',
            onPressed: () async {
              final bill = billAsync.value;
              if (bill == null) return;
              final profile = await LocalDbService.instance.getBusinessProfile();
              if (context.mounted) {
                await WhatsAppService.instance.shareDirectToSystemWhatsApp(
                  context: context,
                  bill: bill,
                  business: profile,
                );
              }
            },
          ),
        ],
      ),
      body: billAsync.when(
        data: (bill) {
          if (bill == null) {
            return const Center(child: Text('Bill not found', style: TextStyle(color: Colors.white)));
          }
          return FutureBuilder(
            future: LocalDbService.instance.getBusinessProfile(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              final profile = profileSnap.data!;
              return PdfPreview(
                build: (format) => PdfService.instance.generateBillPdf(bill, profile),
                canChangePageFormat: false,
                canChangeOrientation: false,
                allowPrinting: true,
                allowSharing: true,
                maxPageWidth: 700,
                pdfFileName: 'Gopal_Studio_CashMemo_${bill.billNumber}.pdf',
                previewPageMargin: const EdgeInsets.all(16),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
