import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/business_profile_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static PdfService? _instance;
  static PdfService get instance => _instance ??= PdfService._();
  PdfService._();

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_IN');

  // ─── Elite Luxury Royal Navy & Gold Palette (Crisp White Memo) ───────────
  static const _navyDark = PdfColor.fromInt(0xFF0E233E);      // Royal midnight navy
  static const _navyHeader = PdfColor.fromInt(0xFF0E233E);    // Table header bar
  static const _goldAccent = PdfColor.fromInt(0xFFB88E38);    // Classic burnished gold
  static const _goldMuted = PdfColor.fromInt(0xFFCEAA5B);     // Subtle metallic gold
  static const _goldLight = PdfColor.fromInt(0xFFFAF8F5);     // Warm ivory card background
  static const _cardBorder = PdfColor.fromInt(0xFFE5DCC9);    // Gold card border hairline
  static const _textDark = PdfColor.fromInt(0xFF14171D);      // Sharp readable text
  static const _textMuted = PdfColor.fromInt(0xFF5B6270);     // Secondary muted text
  static const _greenPaid = PdfColor.fromInt(0xFF1B6E32);     // Paid green
  static const _redDue = PdfColor.fromInt(0xFFC02727);        // Balance due red
  static const _ytRed = PdfColor.fromInt(0xFFFF0000);         // YouTube Red
  static const _waGreen = PdfColor.fromInt(0xFF25D366);       // WhatsApp Green
  static const _instaPink = PdfColor.fromInt(0xFFE1306C);     // Instagram Magenta

  Future<Uint8List> generateBillPdf(Bill bill, BusinessProfile profile) async {
    final doc = pw.Document();
    final billDateStr = _dateFormat.format(bill.createdAt);
    final deliveryDateStr = bill.deliveryDate != null
        ? _dateFormat.format(bill.deliveryDate!)
        : 'Immediate / Ready';

    // ─── 1. Load Real Vector Fonts & Official Brand Assets ──────────────────
    pw.Font? scriptFont;
    pw.Font? serifFont;
    try {
      final gvData = await rootBundle.load('assets/fonts/GreatVibes-Regular.ttf');
      scriptFont = pw.Font.ttf(gvData);
    } catch (_) {}

    try {
      final cinzelData = await rootBundle.load('assets/fonts/Cinzel.ttf');
      serifFont = pw.Font.ttf(cinzelData);
    } catch (_) {}

    // Load official images
    pw.MemoryImage? crestImage;
    try {
      final crestData = await rootBundle.load('assets/images/gopal_media_crest.jpg');
      crestImage = pw.MemoryImage(crestData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? waImage;
    try {
      final waData = await rootBundle.load('assets/images/whatsapp_logo.png');
      waImage = pw.MemoryImage(waData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? ytImage;
    try {
      final ytData = await rootBundle.load('assets/images/youtube_logo.png');
      ytImage = pw.MemoryImage(ytData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? instaImage;
    try {
      final instaData = await rootBundle.load('assets/images/instagram_logo.png');
      instaImage = pw.MemoryImage(instaData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? studioLogoImage;
    try {
      final logoData = await rootBundle.load('assets/images/gopal_studio_logo.png');
      studioLogoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // Fallbacks if bundle loading has edge case
    final defaultScript = scriptFont ?? pw.Font.helveticaBold();
    final defaultSerif = serifFont ?? pw.Font.timesBold();

    // Generate UPI payload string for pure vector QR code
    final upiPayload = profile.upiId != null && profile.upiId!.isNotEmpty
        ? 'upi://pay?pa=${profile.upiId}&pn=${Uri.encodeComponent(profile.businessName)}&am=${bill.remainingBalance > 0 ? bill.remainingBalance : bill.totalAmount}&cu=INR'
        : 'https://wa.me/91${profile.phone1}';

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _goldAccent, width: 1.2),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Gold Accent Bar
                pw.Container(
                  height: 3,
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(color: _goldAccent),
                ),
                pw.SizedBox(height: 10),

                // Master Header: Pure Vector Brand Identity with 3D Media Crest & Clipped Social Icons
                _buildMasterHeader(profile, bill, defaultScript, defaultSerif, crestImage, studioLogoImage, waImage, ytImage, instaImage),
                pw.SizedBox(height: 12),

                // Client & Invoice Metadata Cards
                _buildClientAndMemoCards(bill, billDateStr, deliveryDateStr, defaultSerif),
                pw.SizedBox(height: 12),

                // High-End Items Table
                _buildLuxuryTable(bill),
                pw.SizedBox(height: 12),

                // Financial Breakdown + Vector UPI QR + Amount in Words
                _buildFinancialSection(bill, profile, upiPayload),
                pw.Spacer(),

                // Guarantee, Terms & Signatures
                _buildSignaturesAndFooter(profile, defaultSerif),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // ─── 1. Master Header: Pure Vector Typography & Emblem ─────────────────────
  pw.Widget _buildMasterHeader(
    BusinessProfile profile,
    Bill bill,
    pw.Font scriptFont,
    pw.Font serifFont,
    pw.MemoryImage? crestImage,
    pw.MemoryImage? studioLogoImage,
    pw.MemoryImage? waImage,
    pw.MemoryImage? ytImage,
    pw.MemoryImage? instaImage,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Block: Official Studio Logo or Vector Typography
        pw.Expanded(
          child: studioLogoImage != null
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(
                      studioLogoImage,
                      height: 52,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '4K VIDEO MIXING & DIGITAL LAB',
                      style: pw.TextStyle(
                        font: serifFont,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _goldAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      profile.tagline != null && profile.tagline!.isNotEmpty
                          ? profile.tagline!
                          : 'Capturing Memory, Creating Story',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: _textMuted,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCrestBadge(crestImage),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            profile.businessName,
                            style: pw.TextStyle(
                              font: scriptFont,
                              fontSize: 38,
                              color: _goldAccent,
                            ),
                          ),
                          pw.SizedBox(height: -6),
                          pw.Text(
                            'PHOTOGRAPHY STUDIO',
                            style: pw.TextStyle(
                              font: serifFont,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _navyDark,
                              letterSpacing: 2.2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '4K VIDEO MIXING & DIGITAL LAB',
                            style: pw.TextStyle(
                              font: serifFont,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _goldAccent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            profile.tagline != null && profile.tagline!.isNotEmpty
                                ? profile.tagline!
                                : 'Capturing Memory, Creating Story',
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: _textMuted,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Right Block: Cash Memo Pill + Address + Direct Contacts
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _navyDark,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _goldAccent, width: 1.0),
              ),
              child: pw.Text(
                'CASH MEMO',
                style: pw.TextStyle(
                  font: serifFont,
                  color: _goldAccent,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              profile.address ?? 'Jalesarganj Road, Lalganj Ajhara',
              style: const pw.TextStyle(color: _navyDark, fontSize: 8.5),
            ),
            pw.Text(
              'Pratapgarh, Uttar Pradesh',
              style: const pw.TextStyle(color: _navyDark, fontSize: 8.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Tel: +91 ${profile.phone1}${profile.phone2 != null ? " / ${profile.phone2}" : ""}',
              style: const pw.TextStyle(color: _textDark, fontSize: 8.5),
            ),
            // Social badges: WhatsApp, YouTube, and Instagram
            pw.SizedBox(height: 4),
            _buildWaPill(profile.phone2 ?? profile.phone1, waImage),
            pw.SizedBox(height: 3),
            _buildYtPill(profile.youtubeChannel ?? '@GopalPhotographyStudio', ytImage),
            if (profile.instagramHandle != null && profile.instagramHandle!.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _buildInstaPill(profile.instagramHandle!, instaImage),
            ],
          ],
        ),
      ],
    );
  }

  // ─── 2. Brand Crest Badge (Emblem from Uploaded High-Res Asset) ────────────
  pw.Widget _buildCrestBadge(pw.MemoryImage? crestImage) {
    if (crestImage != null) {
      return pw.Container(
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _goldAccent, width: 1.4),
        ),
        child: pw.ClipOval(
          child: pw.Image(crestImage, fit: pw.BoxFit.cover),
        ),
      );
    }
    return _buildVectorCameraBadge();
  }

  // ─── 2. Pure Vector Camera & Iris Shutter Badge ────────────────────────────
  pw.Widget _buildVectorCameraBadge() {
    return pw.Container(
      width: 58,
      height: 58,
      decoration: pw.BoxDecoration(
        color: _navyDark,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _goldAccent, width: 1.4),
      ),
      child: pw.Center(
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            // Camera Body Outline
            pw.Container(
              width: 42,
              height: 28,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _goldMuted, width: 1.2),
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
            // Viewfinder Prism Top Housing
            pw.Positioned(
              top: 10,
              child: pw.Container(
                width: 14,
                height: 5,
                decoration: pw.BoxDecoration(
                  color: _goldAccent,
                  borderRadius: pw.BorderRadius.circular(1.5),
                ),
              ),
            ),
            // Red Recording Indicator Dot
            pw.Positioned(
              top: 17,
              left: 11,
              child: pw.Container(
                width: 4,
                height: 4,
                decoration: const pw.BoxDecoration(
                  color: _redDue,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
            // Multi-ring Aperture Lens Barrel
            pw.Container(
              width: 18,
              height: 18,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: _goldAccent, width: 1.5),
              ),
              child: pw.Center(
                child: pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: _goldMuted, width: 1.0),
                  ),
                  child: pw.Center(
                    child: pw.Container(
                      width: 4,
                      height: 4,
                      decoration: const pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _goldAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. Client & Invoice Information Cards ─────────────────────────────────
  pw.Widget _buildClientAndMemoCards(
    Bill bill,
    String billDate,
    String deliveryDate,
    pw.Font serifFont,
  ) {
    return pw.Row(
      children: [
        // Left: Client Particulars
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: _cardBorder, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT / M/S DETAILS',
                  style: pw.TextStyle(
                    font: serifFont,
                    color: _goldAccent,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      const pw.TextSpan(text: 'Name: ', style: pw.TextStyle(color: _textMuted, fontSize: 9)),
                      pw.TextSpan(
                        text: bill.customerName,
                        style: const pw.TextStyle(color: _navyDark, fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      const pw.TextSpan(text: 'Mobile: ', style: pw.TextStyle(color: _textMuted, fontSize: 9)),
                      pw.TextSpan(
                        text: bill.customerMobile != null && bill.customerMobile!.isNotEmpty
                            ? '+91 ${bill.customerMobile}'
                            : 'N/A',
                        style: const pw.TextStyle(color: _navyDark, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  bill.notes != null && bill.notes!.isNotEmpty
                      ? 'Note: ${bill.notes}'
                      : 'Order Category: Studio Portrait & Lab Work',
                  style: const pw.TextStyle(color: _textMuted, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),

        // Right: Invoice Specifications
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: _cardBorder, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MEMO SPECIFICATIONS',
                  style: pw.TextStyle(
                    font: serifFont,
                    color: _goldAccent,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 4),
                _specRow('Memo Serial:', '#${bill.billNumber.toString().padLeft(3, '0')}', isBold: true),
                pw.SizedBox(height: 2),
                _specRow('Issue Date:', billDate),
                pw.SizedBox(height: 2),
                _specRow('Delivery Target:', deliveryDate, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _specRow(String label, String val, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: _textMuted, fontSize: 9)),
        pw.Text(
          val,
          style: pw.TextStyle(
            color: isBold ? _navyDark : _textDark,
            fontSize: 9.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ─── 4. Luxury Items Table ─────────────────────────────────────────────────
  pw.Widget _buildLuxuryTable(Bill bill) {
    return pw.Table(
      border: null,
      columnWidths: const {
        0: pw.FixedColumnWidth(34),
        1: pw.FlexColumnWidth(4),
        2: pw.FixedColumnWidth(42),
        3: pw.FixedColumnWidth(75),
        4: pw.FixedColumnWidth(85),
      },
      children: [
        // Royal Navy Table Header Bar
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navyHeader),
          children: [
            _th('S.N.', align: pw.Alignment.center),
            _th('PARTICULARS & SPECIFICATIONS'),
            _th('QTY', align: pw.Alignment.center),
            _th('RATE (Rs.)', align: pw.Alignment.centerRight),
            _th('AMOUNT (Rs.)', align: pw.Alignment.centerRight),
          ],
        ),
        // Item Rows
        ...bill.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isEven = idx % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : _goldLight,
              border: const pw.Border(bottom: pw.BorderSide(color: _cardBorder, width: 0.6)),
            ),
            children: [
              _td('${idx + 1}', align: pw.Alignment.center),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.particulars,
                      style: const pw.TextStyle(color: _textDark, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                    if (item.size != null && item.size!.isNotEmpty)
                      pw.Text(
                        'Size: ${item.size}  |  Studio Finished',
                        style: const pw.TextStyle(color: _textMuted, fontSize: 7.5),
                      ),
                  ],
                ),
              ),
              _td(item.quantity.toStringAsFixed(0), align: pw.Alignment.center),
              _td(_currencyFormat.format(item.rate), align: pw.Alignment.centerRight),
              _td(_currencyFormat.format(item.amount), align: pw.Alignment.centerRight, isBold: true),
            ],
          );
        }),
        // Minimum empty rows to maintain balanced proportion
        ...List.generate(
          (4 - bill.items.length).clamp(0, 4),
          (i) => pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _cardBorder, width: 0.4)),
            ),
            children: List.generate(5, (_) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 9), child: pw.Text(''))),
          ),
        ),
      ],
    );
  }

  // ─── 5. Financial Breakdown + Vector UPI QR + Amount in Words ──────────────
  pw.Widget _buildFinancialSection(Bill bill, BusinessProfile profile, String upiPayload) {
    final amountInWords = _numberToWords(bill.totalAmount.toInt());

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Vector QR Code + Amount In Words
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _cardBorder, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // High-contrast Vector Barcode QR Widget for 100% scan reliability
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _cardBorder, width: 0.8),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: upiPayload,
                    width: 58,
                    height: 58,
                    color: _navyDark,
                  ),
                ),
                pw.SizedBox(width: 10),

                // Amount in Words & Payment Instructions
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AMOUNT IN WORDS',
                        style: const pw.TextStyle(
                          color: _goldAccent,
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Rupees $amountInWords Only',
                        style: const pw.TextStyle(color: _textDark, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        profile.upiId != null ? 'Scan QR or Pay UPI: ${profile.upiId}' : 'Cash / UPI Accepted',
                        style: const pw.TextStyle(color: _textMuted, fontSize: 7.5),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Payment Mode: Cash / UPI / Digital',
                        style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),

        // Right Column: Precise Financial Ledger
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _ledgerRow('Subtotal', _currencyFormat.format(bill.totalAmount)),
              if (bill.advanceAmount > 0)
                _ledgerRow('Advance Paid', '- ${_currencyFormat.format(bill.advanceAmount)}', isGreen: true),
              if (bill.remainingBalance > 0 && bill.advanceAmount > 0)
                _ledgerRow('Balance Due', _currencyFormat.format(bill.remainingBalance), isRed: true),
              pw.Divider(color: _cardBorder, thickness: 0.8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total',
                    style: const pw.TextStyle(color: _navyDark, fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rs. ${_currencyFormat.format(bill.totalAmount)}',
                    style: const pw.TextStyle(color: _goldAccent, fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              if (bill.remainingBalance <= 0)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'FULLY PAID & SETTLED',
                    style: const pw.TextStyle(color: _greenPaid, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 6. Terms, Dual Signatures & Master Footer ─────────────────────────────
  pw.Widget _buildSignaturesAndFooter(BusinessProfile profile, pw.Font serifFont) {
    return pw.Column(
      children: [
        // Terms & Signatures Row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Left: Terms
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TERMS & CONDITIONS',
                  style: pw.TextStyle(
                    font: serifFont,
                    color: _goldAccent,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '1. Goods once prepared/delivered cannot be returned without original memo.',
                  style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                ),
                pw.Text(
                  '2. Please check your photo/album prints thoroughly at the time of delivery.',
                  style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                ),
                pw.Text(
                  '3. Balance amount must be settled on or before the final handover.',
                  style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                ),
                pw.SizedBox(height: 14),
                // Customer Sign Line
                pw.Container(width: 120, height: 0.8, color: _cardBorder),
                pw.SizedBox(height: 3),
                pw.Text('Customer Signature', style: const pw.TextStyle(color: _textMuted, fontSize: 7.5)),
              ],
            ),

            // Right: Studio Official Signature & Stamp
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 140,
                  height: 32,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _cardBorder, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'SEAL / SIGNATURE',
                      style: const pw.TextStyle(color: _cardBorder, fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'AUTHORIZED SIGNATORY',
                  style: pw.TextStyle(
                    font: serifFont,
                    color: _navyDark,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Text(
                  'Gopal Photography Studio',
                  style: const pw.TextStyle(color: _goldAccent, fontSize: 7),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Legal Baseline
        pw.Container(height: 0.6, width: double.infinity, color: _cardBorder),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gopal Photography Studio & Video Mixing Lab  |  Lalganj Ajhara, Pratapgarh, UP',
              style: const pw.TextStyle(color: _textMuted, fontSize: 7),
            ),
            pw.Text(
              'Official Computerized Cash Memo  |  Page 1 of 1',
              style: const pw.TextStyle(color: _textMuted, fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Table Cell Helpers ────────────────────────────────────────────────────
  pw.Widget _th(String label, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          label,
          style: const pw.TextStyle(color: _goldMuted, fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  pw.Widget _td(String text, {pw.Alignment align = pw.Alignment.centerLeft, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: _textDark,
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  pw.Widget _ledgerRow(String label, String value, {bool isRed = false, bool isGreen = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _textMuted, fontSize: 8.5)),
          pw.Text(
            'Rs. $value',
            style: pw.TextStyle(
              color: isRed
                  ? _redDue
                  : isGreen
                      ? _greenPaid
                      : _textDark,
              fontSize: 8.5,
              fontWeight: isRed || isGreen ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWaPill(String phone, pw.MemoryImage? waImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8F8EE'),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#C8E6C9'), width: 0.6),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (waImage != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(waImage, width: 12, height: 12),
            ),
          pw.SizedBox(width: 4),
          pw.Text(
            'WhatsApp: +91 $phone',
            style: const pw.TextStyle(
              color: _waGreen,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildYtPill(String channel, pw.MemoryImage? ytImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFEBEE'),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#FFCDD2'), width: 0.6),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (ytImage != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(ytImage, width: 14, height: 10),
            ),
          pw.SizedBox(width: 4),
          pw.Text(
            'Follow on YouTube: $channel',
            style: const pw.TextStyle(
              color: _ytRed,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInstaPill(String handle, pw.MemoryImage? instaImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FDF0F5'),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#F8BBD0'), width: 0.6),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (instaImage != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(instaImage, width: 11, height: 11),
            )
          else
            _buildVectorInstaIcon(),
          pw.SizedBox(width: 4),
          pw.Text(
            'Instagram: $handle',
            style: const pw.TextStyle(
              color: _instaPink,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVectorInstaIcon() {
    return pw.Container(
      width: 11,
      height: 11,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: _instaPink, width: 1.0),
      ),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Container(
            width: 5,
            height: 5,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _instaPink, width: 0.8),
            ),
          ),
          pw.Positioned(
            top: 1,
            right: 1.2,
            child: pw.Container(
              width: 1.2,
              height: 1.2,
              decoration: const pw.BoxDecoration(
                color: _instaPink,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';
    final ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convertLessThanThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return ones[n];
      if (n < 100) return '${tens[n ~/ 10]}${n % 10 != 0 ? " ${ones[n % 10]}" : ""}';
      return '${ones[n ~/ 100]} Hundred${n % 100 != 0 ? " and ${convertLessThanThousand(n % 100)}" : ""}';
    }

    if (number >= 10000000) {
      final crore = number ~/ 10000000;
      final rest = number % 10000000;
      return '${convertLessThanThousand(crore)} Crore${rest != 0 ? " ${_numberToWords(rest)}" : ""}';
    }
    if (number >= 100000) {
      final lakh = number ~/ 100000;
      final rest = number % 100000;
      return '${convertLessThanThousand(lakh)} Lakh${rest != 0 ? " ${_numberToWords(rest)}" : ""}';
    }
    if (number >= 1000) {
      final thousand = number ~/ 1000;
      final rest = number % 1000;
      return '${convertLessThanThousand(thousand)} Thousand${rest != 0 ? " ${convertLessThanThousand(rest)}" : ""}';
    }
    return convertLessThanThousand(number);
  }

  Future<void> printBill(Bill bill, BusinessProfile profile) async {
    final pdfBytes = await generateBillPdf(bill, profile);
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Gopal_Studio_CashMemo_${bill.billNumber}_${bill.customerName}',
    );
  }

  Future<void> sharePdf(Bill bill, BusinessProfile profile) async {
    final pdfBytes = await generateBillPdf(bill, profile);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Gopal_Studio_CashMemo_${bill.billNumber}.pdf',
    );
  }
}
