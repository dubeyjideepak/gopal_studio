import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_studio_pro/services/pdf_service.dart';
import 'package:gopal_studio_pro/shared/models/bill_model.dart';
import 'package:gopal_studio_pro/shared/models/business_profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfService generates luxury Cash Memo PDF bytes with zero errors', () async {
    final bill = Bill(
      id: 'test-1',
      billNumber: 1,
      customerId: 'cust-1',
      customerName: 'ABCD',
      customerMobile: '9935006921',
      createdAt: DateTime(2026, 10, 12),
      deliveryDate: DateTime(2026, 10, 15),
      items: const [
        BillItem(
          id: 'item-1',
          particulars: 'ITEM 1',
          size: '12X18',
          quantity: 1,
          rate: 50,
          amount: 50,
        ),
        BillItem(
          id: 'item-2',
          particulars: 'ITEM2',
          size: '13X15',
          quantity: 1,
          rate: 60,
          amount: 60,
        ),
      ],
      totalAmount: 110,
      advanceAmount: 10,
      balanceAmount: 100,
      paidAmount: 10,
      status: BillStatus.partial,
      notes: 'Studio portrait prints',
    );

    final profile = BusinessProfile.defaultProfile.copyWith(
      youtubeChannel: '@GopalPhotographyStudio',
      upiId: 'gopalstudio@upi',
    );

    final pdfBytes = await PdfService.instance.generateBillPdf(bill, profile);
    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));

    final file = File('/tmp/gopal_cash_memo_sample.pdf');
    await file.writeAsBytes(pdfBytes);
  });
}
