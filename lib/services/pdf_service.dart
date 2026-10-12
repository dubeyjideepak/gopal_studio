import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/business_profile_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static PdfService? _instance;
  static PdfService get instance => _instance ??= PdfService._();
  PdfService._();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_IN');

  // Gold color for PDF
  static const _gold = PdfColor.fromInt(0xFFC9A84C);
  static const _dark = PdfColor.fromInt(0xFF1A1A1A);
  static const _darkBg = PdfColor.fromInt(0xFF0D0D0D);
  static const _textDark = PdfColor.fromInt(0xFF1A1A1A);
  static const _textGrey = PdfColor.fromInt(0xFF666666);
  static const _success = PdfColor.fromInt(0xFF4CAF50);
  static const _warning = PdfColor.fromInt(0xFFFF9800);

  Future<Uint8List> generateBillPdf(Bill bill, BusinessProfile profile) async {
    final doc = pw.Document();
    final dateStr = _dateFormat.format(bill.createdAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(profile, bill, dateStr),
              pw.SizedBox(height: 20),
              // Customer Info
              _buildCustomerSection(bill),
              pw.SizedBox(height: 16),
              // Items Table
              _buildItemsTable(bill),
              pw.SizedBox(height: 16),
              // Totals
              _buildTotals(bill),
              pw.SizedBox(height: 20),
              // UPI QR + Footer
              _buildFooter(profile, bill),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(BusinessProfile profile, Bill bill, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _dark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.businessName,
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (profile.tagline != null)
                pw.Text(
                  profile.tagline!,
                  style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              pw.SizedBox(height: 4),
              if (profile.address != null)
                pw.Text(profile.address!, style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
              pw.Text('Tel: ${profile.phone1}${profile.phone2 != null ? " | ${profile.phone2}" : ""}',
                  style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _gold,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('CASH MEMO',
                    style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Bill No: #${bill.billNumber}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: $dateStr', style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
              if (bill.deliveryDate != null)
                pw.Text('Delivery: ${_dateFormat.format(bill.deliveryDate!)}',
                    style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerSection(Bill bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Customer / M/s', style: pw.TextStyle(color: _textGrey, fontSize: 10)),
                pw.Text(bill.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (bill.customerMobile != null)
                  pw.Text('Mob: ${bill.customerMobile}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Bill bill) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _dark),
          children: [
            _tableCell('S.No', isHeader: true),
            _tableCell('Particulars / Size', isHeader: true),
            _tableCell('Qty', isHeader: true, align: pw.Alignment.center),
            _tableCell('Rate (\u20b9)', isHeader: true, align: pw.Alignment.centerRight),
            _tableCell('Amount (\u20b9)', isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        // Item rows
        ...bill.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColor.fromHex('#F9F9F9'),
            ),
            children: [
              _tableCell('${i + 1}', align: pw.Alignment.center),
              _tableCell('${item.particulars}${item.size != null ? "\n${item.size}" : ""}'),
              _tableCell('${item.quantity.toStringAsFixed(0)}', align: pw.Alignment.center),
              _tableCell(_currencyFormat.format(item.rate), align: pw.Alignment.centerRight),
              _tableCell(_currencyFormat.format(item.amount), align: pw.Alignment.centerRight),
            ],
          );
        }),
        // Empty rows for spacing if < 5 items
        ...List.generate(
          (5 - bill.items.length).clamp(0, 5),
          (_) => pw.TableRow(
            children: List.generate(5, (_) => _tableCell('')),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotals(Bill bill) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Spacer(),
        pw.Container(
          width: 220,
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              _totalRow('Total', _currencyFormat.format(bill.totalAmount), bold: true),
              if (bill.advanceAmount > 0)
                _totalRow('Advance', _currencyFormat.format(bill.advanceAmount)),
              _totalRow('Balance', _currencyFormat.format(bill.remainingBalance), highlight: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(BusinessProfile profile, Bill bill) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // UPI QR Code
        if (profile.upiId != null) ...
          [
            pw.Column(
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text('UPI QR', style: pw.TextStyle(color: _gold, fontSize: 10)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Scan to Pay', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(profile.upiId!, style: pw.TextStyle(fontSize: 8, color: _textGrey)),
              ],
            ),
            pw.SizedBox(width: 20),
          ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Thank you for your business!',
                  style: pw.TextStyle(color: _textGrey, fontSize: 11, fontStyle: pw.FontStyle.italic)),
              if (bill.notes != null) ...
                [
                  pw.SizedBox(height: 4),
                  pw.Text('Note: ${bill.notes}', style: const pw.TextStyle(fontSize: 10)),
                ],
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 100, height: 1, decoration: const pw.BoxDecoration(color: PdfColors.grey)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 100, height: 1, decoration: const pw.BoxDecoration(color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: isHeader ? _gold : _textDark,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isHeader ? 10 : 11,
          ),
        ),
      ),
    );
  }

  pw.TableRow _totalRow(String label, String value, {bool bold = false, bool highlight = false}) {
    return pw.TableRow(
      decoration: highlight ? pw.BoxDecoration(color: PdfColor.fromHex('#FFF9EC')) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: bold || highlight ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 11, color: highlight ? _gold : _textDark)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: bold || highlight ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 11, color: highlight ? _gold : _textDark), textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  Future<void> printBill(Bill bill, BusinessProfile profile) async {
    final pdfBytes = await generateBillPdf(bill, profile);
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Bill_${bill.billNumber}_${bill.customerName}',
    );
  }

  Future<void> sharePdf(Bill bill, BusinessProfile profile) async {
    final pdfBytes = await generateBillPdf(bill, profile);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Gopal_Studio_Bill_${bill.billNumber}.pdf',
    );
  }
}
