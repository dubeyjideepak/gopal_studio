import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/business_profile_model.dart';
import 'pdf_service.dart';

class WhatsAppService {
  static WhatsAppService? _instance;
  static WhatsAppService get instance => _instance ??= WhatsAppService._();
  WhatsAppService._();

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // ─── Modal Sheet for Sharing (PDF vs Quick Text) ───────────────────────────
  Future<void> showShareOptionsModal({
    required BuildContext context,
    required Bill bill,
    required BusinessProfile business,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.whatsapp.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsapp, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Bill #${bill.billNumber}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '${bill.customerName}${bill.customerMobile != null ? ' • +91 ${bill.customerMobile}' : ''}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Option 1: Share PDF directly
              _ShareOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.gold,
                title: 'Share PDF Document (WhatsApp / Native)',
                subtitle: 'Sends decorated Cash Memo PDF file with brand crest, items table & QR',
                badge: 'Recommended',
                onTap: () async {
                  Navigator.pop(ctx);
                  await shareBillPdf(bill: bill, business: business);
                },
              ),
              const SizedBox(height: 10),
              // Option 2: Save to Downloads & Open WhatsApp (Ideal for macOS Desktop)
              _ShareOptionTile(
                icon: Icons.download_done_rounded,
                iconColor: AppColors.info,
                title: 'Save PDF to Downloads & Open WhatsApp',
                subtitle: 'Saves PDF in Downloads, reveals in Finder & opens customer chat',
                badge: Platform.isMacOS ? 'Best on Mac' : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await savePdfAndOpenWhatsApp(bill: bill, business: business);
                  if (file != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceLight,
                        content: Text('📄 Saved ${file.path.split("/").last} to Downloads! Ready to send.'),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: AppColors.gold,
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              // Option 3: Quick Text Summary
              _ShareOptionTile(
                icon: Icons.chat_outlined,
                iconColor: AppColors.whatsapp,
                title: 'Send WhatsApp Text Summary',
                subtitle: 'Opens WhatsApp chat with quick itemized price breakdown',
                onTap: () async {
                  Navigator.pop(ctx);
                  await shareBill(bill: bill, business: business, isPartial: !bill.isFullyPaid);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Direct Share to System WhatsApp (One-Click) ──────────────────────────
  Future<bool> shareDirectToSystemWhatsApp({
    required BuildContext context,
    required Bill bill,
    required BusinessProfile business,
  }) async {
    try {
      final pdfBytes = await PdfService.instance.generateBillPdf(bill, business);
      final cleanCustName = bill.customerName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'Gopal_Studio_CashMemo_${bill.billNumber}_$cleanCustName.pdf';
      final file = await _writePdfFile(pdfBytes, fileName);

      if (Platform.isMacOS) {
        // 1. Reveal official PDF document in Finder (ready to drag-and-drop into WhatsApp or attach)
        try {
          await Process.run('open', ['-R', file.path]);
        } catch (_) {}

        // 2. Put file onto macOS clipboard via AppleScript
        try {
          await Process.run('osascript', [
            '-e',
            'tell application "Finder" to set the clipboard to (POSIX file "${file.path}")'
          ]);
        } catch (_) {}

        // 3. Short hint caption about the attached PDF bill
        final message = '🙏 Namaste ${bill.customerName} Ji! Please find your bill receipt #${bill.billNumber} from ${business.businessName} attached below.';
        final encoded = Uri.encodeComponent(message);

        // 4. Open WhatsApp chat directly with text pre-filled
        if (bill.customerMobile != null && bill.customerMobile!.isNotEmpty) {
          final cleaned = bill.customerMobile!.replaceAll(RegExp(r'[^0-9]'), '');
          final phone = cleaned.startsWith('91') ? cleaned : '91$cleaned';
          final waUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
          final webUrl = Uri.parse('https://web.whatsapp.com/send?phone=$phone&text=$encoded');
          try {
            if (await canLaunchUrl(waUrl)) {
              await launchUrl(waUrl);
            } else if (await canLaunchUrl(webUrl)) {
              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        } else {
          try {
            await Process.run('open', ['-a', '/Applications/WhatsApp.app']);
          } catch (_) {
            try {
              await Process.run('open', ['-a', 'WhatsApp']);
            } catch (_) {}
          }
        }

        // 5. Trigger macOS native share sheet for direct PDF file sharing (AirDrop, WhatsApp, Mail, etc.)
        try {
          await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        } catch (_) {}

        if (context.mounted) {
          final displayFileName = file.path.split(RegExp(r'[/\\]')).last;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gold, width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  SizedBox(width: 10),
                  Text('PDF Ready for WhatsApp!', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Customer WhatsApp chat is opening with bill details pre-typed.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2. PDF file "$displayFileName" is highlighted in Finder right now.',
                    style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: AppColors.gold, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Drag the highlighted PDF from Finder directly into the WhatsApp chat window!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tip: In WhatsApp for Mac, dragging files directly into the chat or clicking the (+) attach button is the standard way to send documents.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK, Got it!', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return true;
      } else if (Platform.isWindows) {
        // Windows Desktop
        // 1. Reveal PDF in Windows Explorer
        try {
          await Process.run('explorer.exe', ['/select,', file.path]);
        } catch (_) {}

        // 2. Programmatically put the actual PDF file onto the Windows Clipboard
        // This allows pressing Ctrl+V in WhatsApp Desktop/Web to instantly attach the PDF!
        try {
          await Process.run('powershell', [
            '-NoProfile',
            '-Command',
            'Set-Clipboard -LiteralPath "${file.path}"'
          ]);
        } catch (_) {}

        // 3. Short hint caption about the attached PDF bill
        final message = '🙏 Namaste ${bill.customerName} Ji! Please find your bill receipt #${bill.billNumber} from ${business.businessName} attached below.';
        final encoded = Uri.encodeComponent(message);

        // 4. Open WhatsApp chat directly with message pre-typed
        if (bill.customerMobile != null && bill.customerMobile!.isNotEmpty) {
          final cleaned = bill.customerMobile!.replaceAll(RegExp(r'[^0-9]'), '');
          final phone = cleaned.startsWith('91') ? cleaned : '91$cleaned';
          final waUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
          final webUrl = Uri.parse('https://web.whatsapp.com/send?phone=$phone&text=$encoded');
          try {
            if (await canLaunchUrl(waUrl)) {
              await launchUrl(waUrl);
            } else if (await canLaunchUrl(webUrl)) {
              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        } else {
          try {
            final waUrl = Uri.parse('whatsapp://');
            if (await canLaunchUrl(waUrl)) {
              await launchUrl(waUrl);
            }
          } catch (_) {}
        }

        if (context.mounted) {
          final displayFileName = file.path.split(RegExp(r'[/\\]')).last;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gold, width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  SizedBox(width: 10),
                  Text('PDF Copied to Clipboard!', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Customer WhatsApp chat is opening with bill details pre-typed.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2. PDF file "$displayFileName" is on your clipboard.',
                    style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.keyboard_rounded, color: AppColors.gold, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Press Ctrl+V in WhatsApp to attach the PDF document!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tip: You can also drag the highlighted PDF from the folder into WhatsApp.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK, Got it!', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return true;
      } else {
        // Mobile / Android / iOS
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
          text: 'Gopal Photography Studio - Cash Memo #${bill.billNumber} for ${bill.customerName}',
          subject: 'Cash Memo #${bill.billNumber}',
        );
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
      return false;
    }
  }

  // ─── Share PDF Document Directly ───────────────────────────────────────────
  Future<void> shareBillPdf({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    final pdfBytes = await PdfService.instance.generateBillPdf(bill, business);
    final cleanCustName = bill.customerName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = 'Gopal_Studio_CashMemo_${bill.billNumber}_$cleanCustName.pdf';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // On desktop platforms (macOS, Windows, Linux), use Printing.sharePdf
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } else {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
          text: 'Gopal Photography Studio - Cash Memo #${bill.billNumber} for ${bill.customerName}',
          subject: 'Cash Memo #${bill.billNumber}',
        );
      }
    } catch (_) {
      // Fallback to Printing share
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    }
  }

  // ─── Save PDF & Open WhatsApp (Optimal for macOS / Windows Desktop) ────────
  Future<File?> savePdfAndOpenWhatsApp({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    final pdfBytes = await PdfService.instance.generateBillPdf(bill, business);
    final cleanCustName = bill.customerName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = 'Gopal_Studio_CashMemo_${bill.billNumber}_$cleanCustName.pdf';
    final file = await _writePdfFile(pdfBytes, fileName);

    // On macOS: reveal in Finder; on Windows: reveal in File Explorer
    if (Platform.isMacOS) {
      try {
        await Process.run('open', ['-R', file.path]);
      } catch (_) {}
    } else if (Platform.isWindows) {
      try {
        await Process.run('explorer.exe', ['/select,', file.path]);
      } catch (_) {}
    }

    // Open WhatsApp chat directly with the customer
    if (bill.customerMobile != null && bill.customerMobile!.isNotEmpty) {
      final cleaned = bill.customerMobile!.replaceAll(RegExp(r'[^0-9]'), '');
      final phone = cleaned.startsWith('91') ? cleaned : '91$cleaned';
      final text = Uri.encodeComponent(
        '🙏 Namaste ${bill.customerName} Ji!\n\nPlease find your official Cash Memo #${bill.billNumber} attached above.\n\nTotal: ₹${bill.totalAmount.toStringAsFixed(0)}\n${bill.advanceAmount > 0 ? "Advance: ₹${bill.advanceAmount.toStringAsFixed(0)}\n" : ""}Balance: ₹${bill.remainingBalance.toStringAsFixed(0)}\n\nThank you for choosing ${business.businessName}!',
      );
      final waUrl = Uri.parse('https://wa.me/$phone?text=$text');
      try {
        if (await canLaunchUrl(waUrl)) {
          await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    return file;
  }

  // ─── Send Simple WhatsApp Text Message ─────────────────────────────────────
  Future<bool> sendMessage(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$number?text=$encoded');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── Payment Reminder (Text) ───────────────────────────────────────────────
  Future<bool> sendPaymentReminder({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;
    
    final balance = _currencyFormat.format(bill.remainingBalance);
    final billDate = DateFormat('dd MMM yyyy').format(bill.createdAt);
    
    final message = '''
🙏 *${business.businessName}*

Namaste ${bill.customerName} Ji! 🌸

Your bill payment reminder:

📋 *Bill No:* #${bill.billNumber}
📅 *Date:* $billDate
💰 *Total Amount:* ${_currencyFormat.format(bill.totalAmount)}
✅ *Paid:* ${_currencyFormat.format(bill.paidAmount)}
⚠️ *Balance Due:* *$balance*

Please clear your dues at your earliest convenience.

Payment Options:
${business.upiId != null ? '📱 UPI: ${business.upiId}' : ''}

📞 Contact: ${business.phone1}${business.phone2 != null ? ' / ${business.phone2}' : ''}

_${business.tagline ?? 'Thank you for your business!'}_
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }

  // ─── Text Summary of Bill ──────────────────────────────────────────────────
  Future<bool> shareBill({
    required Bill bill,
    required BusinessProfile business,
    bool isPartial = false,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;

    final billDate = DateFormat('dd MMM yyyy').format(bill.createdAt);
    final itemsList = bill.items.map((item) =>
      '  • ${item.particulars}${item.size != null ? ' (${item.size})' : ''} × ${item.quantity.toStringAsFixed(0)} = ${_currencyFormat.format(item.amount)}'
    ).join('\n');

    String statusNote = '';
    if (isPartial) {
      statusNote = '\n⚠️ *Balance Due:* ${_currencyFormat.format(bill.remainingBalance)}';
    } else if (bill.isFullyPaid) {
      statusNote = '\n✅ *FULLY PAID — Thank You!*';
    }

    final message = '''
🎞️ *${business.businessName}*
${business.address ?? ''}
📞 ${business.phone1}${business.phone2 != null ? ' | ${business.phone2}' : ''}
━━━━━━━━━━━━━━━━━━━━
📋 *BILL RECEIPT #${bill.billNumber}*
📅 Date: $billDate
👤 Customer: ${bill.customerName}
━━━━━━━━━━━━━━━━━━━━
*Items:*
$itemsList
━━━━━━━━━━━━━━━━━━━━
💰 *Total:* ${_currencyFormat.format(bill.totalAmount)}
${bill.advanceAmount > 0 ? '💵 *Advance:* ${_currencyFormat.format(bill.advanceAmount)}\n' : ''}⚖️ *Balance:* ${_currencyFormat.format(bill.balanceAmount)}$statusNote
━━━━━━━━━━━━━━━━━━━━
${business.upiId != null ? '📱 Pay via UPI: ${business.upiId}' : ''}

_${business.tagline ?? 'Thank you!'}_\n\n(Official PDF receipt also available from studio)
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }

  // ─── Delivery Reminder ─────────────────────────────────────────────────────
  Future<bool> sendDeliveryReminder({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;
    if (bill.deliveryDate == null) return false;

    final deliveryDate = DateFormat('dd MMM yyyy').format(bill.deliveryDate!);
    
    final message = '''
🎉 *${business.businessName}*

Namaste ${bill.customerName} Ji!

Your order (Bill #${bill.billNumber}) is ready for delivery!

📅 *Delivery Date:* $deliveryDate

Please visit us to collect your order.

📍 ${business.address ?? ''}
📞 ${business.phone1}

_${business.tagline ?? 'Thank you!'}_
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }

  // ─── Resilient PDF File Writer ───────────────────────────────────────────
  Future<File> _writePdfFile(Uint8List bytes, String fileName) async {
    final candidates = <Directory?>[];

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        candidates.add(Directory('$home/Downloads'));
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        candidates.add(Directory('$userProfile\\Downloads'));
      }
    }

    try {
      candidates.add(await getDownloadsDirectory());
    } catch (_) {}

    try {
      candidates.add(await getApplicationDocumentsDirectory());
    } catch (_) {}

    try {
      candidates.add(await getTemporaryDirectory());
    } catch (_) {}

    for (final dir in candidates) {
      if (dir == null) continue;
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } catch (_) {
        // Fallback to next candidate if sandbox or permission blocks
      }
    }

    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

// ─── Modal Tile Helper ───────────────────────────────────────────────────────
class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
